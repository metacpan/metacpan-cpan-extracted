typedef struct {
    /* Set on creation */
    SV *self; /* (unused, but whatever) */
    fupg_conn *conn; /* has a refcnt on conn->self */
    UV cookie;
    char *query;
    SV **bind;
    int nbind;
    int stflags;

    /* Set during prepare */
    int prepared;
    char name[32];
    fupg_prep *prep;
    double preptime;
    PGresult *describe; /* shared with prep->describe if prep is set */

    /* Set during execute */
    int nfields;
    const char **param_values; /* Points into conn->buf or st->bind SVs, may be invalid after exec */
    int *param_lengths;
    int *param_formats;
    double exectime;
    fupg_tio send;
    fupg_tio *recv;
    PGresult *result;
} fupg_st;


static void fupg_tracecb(pTHX_ fupg_st *st) {
    if (!st->conn->trace) return;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    mXPUSHs(sv_bless(newRV_inc(st->self), gv_stashpv("FU::Pg::st", GV_ADD)));
    PUTBACK;

    call_sv(st->conn->trace, G_DISCARD);
    FREETMPS;
    LEAVE;
}

static SV *fupg_exec(pTHX_ fupg_conn *c, const char *sql) {
    struct timespec t_start;
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    PGresult *r = PQexec(c->conn, sql);
    struct timespec t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_end);

    if (!r) fupg_conn_croak(c, "exec");
    switch (PQresultStatus(r)) {
        case PGRES_EMPTY_QUERY:
        case PGRES_COMMAND_OK:
        case PGRES_TUPLES_OK: break;
        default: fupg_result_croak(r, "exec", sql);
    }

    SV *ret = fupg_exec_result(aTHX_ r);
    if (c->trace) {
        fupg_st *st = safecalloc(1, sizeof(*st));
        st->conn = c;
        SvREFCNT_inc(c->self);
        st->cookie = c->cookie;
        st->query = savepv(sql);
        st->stflags = c->stflags;
        st->result = r;
        st->exectime = fu_timediff(&t_end, &t_start);
        fu_selfobj(st, "FU::Pg::st");
        fupg_tracecb(aTHX_ st);
    } else {
        PQclear(r);
    }
    return ret;
}

static SV *fupg_sql(pTHX_ fupg_conn *c, int stflags, const char *query, I32 ax, I32 argc) {
    fupg_st *st = safecalloc(1, sizeof(fupg_st));
    st->conn = c;
    st->cookie = c->cookie;
    st->stflags = stflags;
    SvREFCNT_inc(c->self);

    st->query = savepv(query);
    if (argc > 2) {
        st->bind = safemalloc((argc-2) * sizeof(SV *));
        I32 i;
        for (i=2; i < argc; i++) {
            st->bind[st->nbind] = newSV(0);
            sv_setsv(st->bind[st->nbind], ST(i));
            st->nbind++;
        }
    }

    return fu_selfobj(st, "FU::Pg::st");
}

static void fupg_st_destroy(pTHX_ fupg_st *st) {
    int i;

    if (st->prep) {
        fupg_prepared_unref(st->conn, st->prep);
    } else if (st->prepared) {
        PQclear(st->describe);
        PQclear(PQclosePrepared(st->conn->conn, st->name));
    }

    safefree(st->query);
    for (i=0; i < st->nbind; i++) SvREFCNT_dec(st->bind[i]);
    safefree(st->bind);
    safefree(st->param_values);
    safefree(st->param_lengths);
    safefree(st->param_formats);
    if (st->recv) for (i=0; i<st->nfields; i++) fupg_tio_free(st->recv + i);
    fupg_tio_free(&st->send);
    safefree(st->recv);
    PQclear(st->result);
    SvREFCNT_dec(st->conn->self);
    safefree(st);
}

static void fupg_st_prepare(pTHX_ fupg_st *st) {
    if (st->describe) return;
    if (st->prepared) fu_confess("invalid attempt to re-prepare invalid statement");
    if (st->result) fu_confess("invalid attempt to prepare already executed statement");

    if (st->stflags & FUPG_CACHE)
        st->prep = fupg_prepared_ref(aTHX_ st->conn, st->query);
    if (st->prep && st->prep->describe) {
        snprintf(st->name, sizeof(st->name), "fupg%"UVuf, st->prep->name);
        st->describe = st->prep->describe;
        st->prepared = 1;
        return;
    }

    st->conn->prep_counter++;
    if (st->prep) st->prep->name = st->conn->prep_counter;
    snprintf(st->name, sizeof(st->name), "fupg%"UVuf, st->conn->prep_counter);

    struct timespec t_start;
    clock_gettime(CLOCK_MONOTONIC, &t_start);

    /* Send prepare + describe in a pipeline to avoid a double round-trip with the server */
    PQenterPipelineMode(st->conn->conn);
    PQsendPrepare(st->conn->conn, st->name, st->query, 0, NULL);
    PQsendDescribePrepared(st->conn->conn, st->name);
    PQpipelineSync(st->conn->conn);
    PGresult *prep = PQgetResult(st->conn->conn); PQgetResult(st->conn->conn); /* NULL */
    PGresult *desc = PQgetResult(st->conn->conn); PQgetResult(st->conn->conn); /* NULL */
    PGresult *sync = PQgetResult(st->conn->conn);
    PQexitPipelineMode(st->conn->conn);

    if (!prep) {
        PQclear(desc); PQclear(sync);
        fupg_conn_croak(st->conn , "prepare");
    }
    if (PQresultStatus(prep) != PGRES_COMMAND_OK) {
        PQclear(desc); PQclear(sync);
        fupg_result_croak(prep, "prepare", st->query);
    }
    PQclear(prep);
    st->prepared = 1;

    struct timespec t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_end);
    st->preptime = fu_timediff(&t_end, &t_start);

    if (!desc) {
        PQclear(sync);
        fupg_conn_croak(st->conn , "prepare");
    }
    if (PQresultStatus(desc) != PGRES_COMMAND_OK) {
        PQclear(sync);
        fupg_result_croak(desc, "prepare", st->query);
    }
    if (st->prep) st->prep->describe = desc;
    st->describe = desc;

    if (!sync) fupg_conn_croak(st->conn , "prepare");
    if (PQresultStatus(sync) != PGRES_PIPELINE_SYNC)
        fupg_result_croak(sync, "prepare", st->query);
    PQclear(sync);
}

static SV *fupg_st_param_types(pTHX_ fupg_st *st) {
    if (st->result && !st->describe)
        return sv_2mortal(newRV_noinc((SV *)newAV()));
    fupg_st_prepare(aTHX_ st);
    int i, nparams = PQnparams(st->describe);
    AV *av = nparams == 0 ? newAV() : newAV_alloc_x(nparams);
    for (i=0; i<nparams; i++)
        av_push_simple(av, newSViv(PQparamtype(st->describe, i)));
    return sv_2mortal(newRV_noinc((SV *)av));
}

static SV *fupg_st_param_values(pTHX_ fupg_st *st) {
    int i;
    AV *av = st->nbind == 0 ? newAV() : newAV_alloc_x(st->nbind);
    for (i=0; i<st->nbind; i++)
        av_push_simple(av, SvREFCNT_inc(st->bind[i]));
    return sv_2mortal(newRV_noinc((SV *)av));
}

static SV *fupg_st_columns(pTHX_ fupg_st *st) {
    PGresult *r = st->result;
    if (!r) {
        fupg_st_prepare(aTHX_ st);
        r = st->describe;
    }
    int i, nfields = PQnfields(r);
    AV *av = nfields == 0 ? newAV() : newAV_alloc_x(nfields);
    for (i=0; i<nfields; i++) {
        HV *hv = newHV();
        const char *name = PQfname(r, i);
        hv_stores(hv, "name", newSVpvn_utf8(name, strlen(name), 1));
        hv_stores(hv, "oid", newSViv(PQftype(r, i)));
        int tmod = PQfmod(r, i);
        if (tmod >= 0) hv_stores(hv, "typemod", newSViv(tmod));
        av_push_simple(av, newRV_noinc((SV *)hv));
    }
    return sv_2mortal(newRV_noinc((SV *)av));
}

static void fupg_params_setup(pTHX_ fupg_st *st, int *refresh_done) {
    int i;
    st->param_values = safecalloc(st->nbind, sizeof(*st->param_values));
    if (st->stflags & FUPG_TEXT_PARAMS) {
        for (i=0; i<st->nbind; i++)
            st->param_values[i] = !SvOK(st->bind[i]) ? NULL : SvPVutf8_nolen(st->bind[i]);
        return;
    }

    fustr *buf = &st->conn->buf;
    buf->cur = fustr_start(buf);
    st->param_lengths = safecalloc(st->nbind, sizeof(*st->param_lengths));
    st->param_formats = safecalloc(st->nbind, sizeof(*st->param_formats));
    size_t off = 0;
    for (i=0; i<st->nbind; i++) {
        if (!SvOK(st->bind[i])) {
            st->param_values[i] = NULL;
            continue;
        }
        fupg_tio_setup(aTHX_ st->conn, &st->send,
                FUPGT_SEND | (st->stflags & FUPG_TEXT_PARAMS ? FUPGT_TEXT : 0),
                PQparamtype(st->describe, i), refresh_done);
        off = fustr_len(buf);
        st->send.send(aTHX_ &st->send, st->bind[i], buf);
        fupg_tio_free(&st->send);
        memset(&st->send, 0, sizeof(st->send));

        st->param_lengths[i] = fustr_len(buf) - off;
        st->param_formats[i] = 1;
        st->param_values[i] = "";
        /* Don't write param_values here, the buffer may be invalidated when writing the next param */
    }
    off = 0;
    buf->cur = fustr_start(buf);
    for (i=0; i<st->nbind; i++) {
        if (st->param_values[i]) {
            st->param_values[i] = buf->cur + off;
            off += st->param_lengths[i];
        }
    }
}

static void fupg_st_execute(pTHX_ fupg_st *st) {
    /* Disallow fetching the results more than once. I don't see a reason why
     * someone would need that and disallowing it leaves room for fetching the
     * results in a streaming fashion without breaking API compat. */
    if (st->result) fu_confess("Invalid attempt to execute statement multiple times");

    /* Whether we can do a direct call or need to prepare first */
    int direct = !st->describe && (st->nbind == 0 || st->stflags & FUPG_TEXT_PARAMS) && !(st->stflags & FUPG_CACHE);
    if (!direct) {
        fupg_st_prepare(aTHX_ st);
        if (PQnparams(st->describe) != st->nbind)
            fu_confess("Statement expects %d bind parameters but %d were given", PQnparams(st->describe), st->nbind);
    }
    int refresh_done = 0;
    fupg_params_setup(aTHX_ st, &refresh_done);

    /* I'm not super fond of this approach. Storing the full query results in a
     * PGresult involves unnecessary parsing, memory allocation and copying.
     * The wire protocol is sufficiently simple that I could parse the query
     * results directly from the network buffers without much additional code,
     * and that would be much more efficient. Alas, libpq doesn't let me do
     * that.
     * There is the option of fetching results in chunked mode, but from what I
     * gather that just saves a bit of memory in exchange for more and smaller
     * malloc()/free()'s. Performance-wise, it probably won't be much of an
     * improvement */
    struct timespec t_start;
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    PGresult *r = direct ? PQexecParams(st->conn->conn,
            st->query, st->nbind, NULL,
            (const char * const *)st->param_values,
            st->param_lengths, st->param_formats,
            st->stflags & FUPG_TEXT_RESULTS ? 0 : 1
        ) : PQexecPrepared(st->conn->conn,
            st->name, st->nbind,
            (const char * const *)st->param_values,
            st->param_lengths, st->param_formats,
            st->stflags & FUPG_TEXT_RESULTS ? 0 : 1
        );
    struct timespec t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_end);
    st->exectime = fu_timediff(&t_end, &t_start);

    if (!r) fupg_conn_croak(st->conn , "exec");
    switch (PQresultStatus(r)) {
        case PGRES_COMMAND_OK:
        case PGRES_TUPLES_OK: break;
        default: fupg_result_croak(r, "exec", st->query);
    }
    st->result = r;

    st->nfields = PQnfields(r);
    st->recv = safecalloc(st->nfields, sizeof(*st->recv));
    int i;
    for (i=0; i<st->nfields; i++)
        fupg_tio_setup(aTHX_ st->conn, st->recv + i,
                FUPGT_RECV | (st->stflags & FUPG_TEXT_RESULTS ? FUPGT_TEXT : 0),
                PQftype(st->result, i), &refresh_done);

    fupg_tracecb(aTHX_ st);
}

static SV *fupg_st_getval(pTHX_ fupg_st *st, int row, int col) {
    PGresult *r = st->result;
    if (PQgetisnull(r, row, col)) return newSV(0);
    const fupg_tio *ctx = st->recv+col;
    return ctx->recv(aTHX_ ctx, PQgetvalue(r, row, col), PQgetlength(r, row, col));
}

static void fupg_st_check_dupcols(pTHX_ fupg_st *st, int start) {
    PGresult *r = st->result;
    HV *hv = newHV();
    sv_2mortal((SV *)hv);
    int i, nfields = PQnfields(r);
    for (i=start; i<nfields; i++) {
        const char *key = PQfname(r, i);
        int len = -strlen(key);
        if (hv_exists(hv, key, len))
            fu_confess("Query returns multiple columns with the same name ('%s')", key);
        hv_store(hv, key, len, &PL_sv_yes, 0);
    }
}




/* Result fetching */

static SV *fupg_st_exec(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    return fupg_exec_result(aTHX_ st->result);
}

static SV *fupg_st_val(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    if (st->nfields > 1) fu_confess("Invalid use of $st->val() on query returning more than one column");
    if (st->nfields == 0) fu_confess("Invalid use of $st->val() on query returning no data");
    if (PQntuples(st->result) > 1) fu_confess("Invalid use of $st->val() on query returning more than one row");
    SV *sv = PQntuples(st->result) == 0 ? newSV(0) : fupg_st_getval(aTHX_ st, 0, 0);
    return sv_2mortal(sv);
}

static I32 fupg_st_rowl(pTHX_ fupg_st *st, I32 ax) {
    dSP;
    fupg_st_execute(aTHX_ st);
    if (PQntuples(st->result) > 1) fu_confess("Invalid use of $st->rowl() on query returning more than one row");
    int nfields = PQntuples(st->result) == 0 ? 0 : st->nfields;
    if (GIMME_V != G_LIST) {
        ST(0) = sv_2mortal(newSViv(nfields));
        return 1;
    }
    (void)POPs;
    EXTEND(SP, nfields);
    int i;
    for (i=0; i<nfields; i++) mPUSHs(fupg_st_getval(aTHX_ st, 0, i));
    return nfields;
}

static SV *fupg_st_rowa(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    if (PQntuples(st->result) > 1) fu_confess("Invalid use of $st->rowl() on query returning more than one row");
    if (PQntuples(st->result) == 0) return &PL_sv_undef;
    AV *av = st->nfields == 0 ? newAV() : newAV_alloc_x(st->nfields);
    SV *sv = sv_2mortal(newRV_noinc((SV *)av));
    int i;
    for (i=0; i<st->nfields; i++) av_push_simple(av, fupg_st_getval(aTHX_ st, 0, i));
    return sv;
}

static SV *fupg_st_rowh(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    fupg_st_check_dupcols(aTHX_ st, 0);
    if (PQntuples(st->result) > 1) fu_confess("Invalid use of $st->rowh() on query returning more than one row");
    if (PQntuples(st->result) == 0) return &PL_sv_undef;
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *)hv));
    int i;
    for (i=0; i<st->nfields; i++) {
        const char *key = PQfname(st->result, i);
        hv_store(hv, key, -strlen(key), fupg_st_getval(aTHX_ st, 0, i), 0);
    }
    return sv;
}

static SV *fupg_st_alla(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    int i, j, nrows = PQntuples(st->result);
    AV *av = nrows == 0 ? newAV() : newAV_alloc_x(nrows);
    SV *sv = sv_2mortal(newRV_noinc((SV *)av));
    for (i=0; i<nrows; i++) {
        AV *row = st->nfields == 0 ? newAV() : newAV_alloc_x(st->nfields);
        av_push_simple(av, newRV_noinc((SV *)row));
        for (j=0; j<st->nfields; j++)
            av_push_simple(row, fupg_st_getval(aTHX_ st, i, j));
    }
    return sv;
}

static SV *fupg_st_allh(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    fupg_st_check_dupcols(aTHX_ st, 0);
    int i, j, nrows = PQntuples(st->result);
    AV *av = nrows == 0 ? newAV() : newAV_alloc_x(nrows);
    SV *sv = sv_2mortal(newRV_noinc((SV *)av));
    for (i=0; i<nrows; i++) {
        HV *row = newHV();
        av_push_simple(av, newRV_noinc((SV *)row));
        for (j=0; j<st->nfields; j++) {
            const char *key = PQfname(st->result, j);
            hv_store(row, key, -strlen(key), fupg_st_getval(aTHX_ st, i, j), 0);
        }
    }
    return sv;
}

static SV *fupg_st_flat(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    int i, j, nrows = PQntuples(st->result);
    AV *av = nrows == 0 || st->nfields == 0 ? newAV() : newAV_alloc_x(nrows * st->nfields);
    SV *sv = sv_2mortal(newRV_noinc((SV *)av));
    for (i=0; i<nrows; i++) {
        for (j=0; j<st->nfields; j++)
            av_push_simple(av, fupg_st_getval(aTHX_ st, i, j));
    }
    return sv;
}

static SV *fupg_st_kvv(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    if (st->nfields > 2) fu_confess("Invalid use of $st->kvv() on query returning more than two columns");
    if (st->nfields == 0) fu_confess("Invalid use of $st->kvv() on query returning no data");
    int i, nrows = PQntuples(st->result);
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *)hv));
    for (i=0; i<nrows; i++) {
        SAVETMPS;
        SV *key = sv_2mortal(fupg_st_getval(aTHX_ st, i, 0));
        if (hv_exists_ent(hv, key, 0)) fu_confess("Key '%s' is duplicated in $st->kvv() query results", SvPV_nolen(key));
        hv_store_ent(hv, key, st->nfields == 1 ? newSV_true() : fupg_st_getval(aTHX_ st, i, 1), 0);
        FREETMPS;
    }
    return sv;
}

static SV *fupg_st_kva(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    if (st->nfields == 0) fu_confess("Invalid use of $st->kva() on query returning no data");
    int i, j, nrows = PQntuples(st->result);
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *)hv));
    for (i=0; i<nrows; i++) {
        SAVETMPS;
        SV *key = sv_2mortal(fupg_st_getval(aTHX_ st, i, 0));
        if (hv_exists_ent(hv, key, 0)) fu_confess("Key '%s' is duplicated in $st->kva() query results", SvPV_nolen(key));
        AV *row = st->nfields == 1 ? newAV() : newAV_alloc_x(st->nfields-1);
        hv_store_ent(hv, key, newRV_noinc((SV *)row), 0);
        FREETMPS;
        for (j=1; j<st->nfields; j++)
            av_push_simple(row, fupg_st_getval(aTHX_ st, i, j));
    }
    return sv;
}

static SV *fupg_st_kvh(pTHX_ fupg_st *st) {
    fupg_st_execute(aTHX_ st);
    fupg_st_check_dupcols(aTHX_ st, 1);
    if (st->nfields == 0) fu_confess("Invalid use of $st->kvh() on query returning no data");
    int i, j, nrows = PQntuples(st->result);
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *)hv));
    for (i=0; i<nrows; i++) {
        SAVETMPS;
        SV *key = sv_2mortal(fupg_st_getval(aTHX_ st, i, 0));
        if (hv_exists_ent(hv, key, 0)) fu_confess("Key '%s' is duplicated in $st->kvh() query results", SvPV_nolen(key));
        HV *row = newHV();
        hv_store_ent(hv, key, newRV_noinc((SV *)row), 0);
        FREETMPS;
        for (j=1; j<st->nfields; j++) {
            const char *key = PQfname(st->result, j);
            hv_store(row, key, -strlen(key), fupg_st_getval(aTHX_ st, i, j), 0);
        }
    }
    return sv;
}




/* COPY support */

typedef struct {
    SV *self;
    fupg_conn *conn;
    char in;
    char bin;
    char rddone;
    char closed;
} fupg_copy;

static SV *fupg_copy_exec(pTHX_ fupg_conn *c, const char *sql) {
    PGresult *r = PQexec(c->conn, sql);

    if (!r) fupg_conn_croak(c, "exec");
    int s = PQresultStatus(r);
    switch (s) {
        case PGRES_COPY_OUT:
        case PGRES_COPY_IN:
            break;
        default: fupg_result_croak(r, "exec", sql);
    }

    fupg_copy *copy = safecalloc(1, sizeof(fupg_copy));
    copy->conn = c;
    SvREFCNT_inc(c->self);
    copy->bin = !!PQbinaryTuples(r);
    copy->in = s == PGRES_COPY_IN;
    PQclear(r);
    return fu_selfobj(copy, "FU::Pg::copy");
}

static void fupg_copy_write(pTHX_ fupg_copy *c, SV *data) {
    STRLEN len;
    const char *buf = c->bin ? SvPVbyte(data, len) : SvPVutf8(data, len);
    if (PQputCopyData(c->conn->conn, buf, len) < 0) fupg_conn_croak(c->conn, "copy");
}

static SV *fupg_copy_read(pTHX_ fupg_copy *c, int discard) {
    char *buf = NULL;
    int len = PQgetCopyData(c->conn->conn, &buf, 0);
    if (len == -1) {
        c->rddone = 1;
        return &PL_sv_undef;
    } else if (len < 0) {
        if (discard) c->rddone = 1;
        else fupg_conn_croak(c->conn, "copy");
    }
    SV *r = discard ? &PL_sv_undef : newSVpvn_flags(buf, len, SVs_TEMP | (c->bin ? 0 : SVf_UTF8));
    PQfreemem(buf);
    return r;
}

static void fupg_copy_close(pTHX_ fupg_copy *c, int ignerror) {
    if (c->closed) return;
    c->closed = 1; /* Mark as closed even on error, a second attempt won't help anyway */

    if (c->in && PQputCopyEnd(c->conn->conn, NULL) < 0 && !ignerror)
        fupg_conn_croak(c->conn, "copyEnd");

    while (!c->in && !c->rddone) fupg_copy_read(aTHX_ c, 1);

    PGresult *r = PQgetResult(c->conn->conn);
    if (!ignerror && !r) fupg_conn_croak(c->conn, "copyEnd");
    if (!ignerror && PQresultStatus(r) != PGRES_COMMAND_OK) fupg_result_croak(r, "copy", "");
    PQclear(r);

    while ((r = PQgetResult(c->conn->conn))) PQclear(r);
}

static void fupg_copy_destroy(pTHX_ fupg_copy *c) {
    fupg_copy_close(aTHX_ c, 1);
    SvREFCNT_dec(c->conn->self);
    safefree(c);
}
