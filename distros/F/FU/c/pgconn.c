#define FUPG_CACHE        1
#define FUPG_TEXT_PARAMS  2
#define FUPG_TEXT_RESULTS 4
#define FUPG_TEXT         (FUPG_TEXT_PARAMS|FUPG_TEXT_RESULTS)

KHASHL_MAP_INIT(KH_LOCAL, fupg_records, fupg_records, Oid, fupg_record *, kh_hash_uint32, kh_eq_generic);

typedef struct fupg_prep fupg_prep;
struct fupg_prep {
    khint_t hash; /* Cached kh_hash_str() of the query */
    int ref; /* How many active $st objects are using this */
    UV name;
    fupg_prep *next, *prev; /* FIFO list for the LRU, only if ref=0 */
    char *query;
    PGresult *describe;
};

#define fupg_prep_hash(p) ((p)->hash)
#define fupg_prep_eq(a, b) ((a)->hash == (b)->hash && strcmp((a)->query, (b)->query) == 0)
KHASHL_SET_INIT(KH_LOCAL, fupg_prepared, fupg_prepared, fupg_prep *, fupg_prep_hash, fupg_prep_eq);

static void fupg_prep_destroy(fupg_prep *p) {
    PQclear(p->describe);
    safefree(p->query);
    safefree(p);
}

typedef struct {
    const fupg_type *send, *recv;
    SV *sendcb, *recvcb;
} fupg_override;

#define fupg_name_hash(v) kh_hash_str((v).n)
#define fupg_name_eq(a,b) kh_eq_str((a).n, (b).n)
KHASHL_MAP_INIT(KH_LOCAL, fupg_oid_overrides, fupg_oid_overrides, Oid, fupg_override, kh_hash_uint32, kh_eq_generic);
KHASHL_MAP_INIT(KH_LOCAL, fupg_name_overrides, fupg_name_overrides, fupg_name, fupg_override, fupg_name_hash, fupg_name_eq);


typedef struct {
    SV *self;
    PGconn *conn;
    SV *trace;
    UV prep_counter;
    UV cookie_counter;
    UV cookie; /* currently active transaction object; 0 = none active */
    int stflags;
    int ntypes;
    unsigned int prep_max;
    unsigned int prep_cur; /* Number of prepared statements not associated with an active $st object */
    fupg_type *types;
    fupg_oid_overrides *oidtypes;
    fupg_name_overrides *nametypes;
    fupg_records *records;
    fupg_prepared *prep_map;
    fupg_prep *prep_head, *prep_tail; /* Inserted into head, removed at tail */
    fustr buf; /* Scratch space for query params */
} fupg_conn;


typedef struct fupg_txn fupg_txn;
struct fupg_txn {
    SV *self;
    fupg_txn *parent;
    fupg_conn *conn;
    UV cookie; /* 0 means done */
    int stflags;
    char rollback_cmd[64];
};




/*  Utilities */

static SV *fupg_conn_errsv(PGconn *conn, const char *action) {
    dTHX;
    HV *hv = newHV();
    hv_stores(hv, "action", newSVpv(action, 0));
    hv_stores(hv, "severity", newSVpvs("FATAL")); /* Connection-related errors are always fatal */
    hv_stores(hv, "message", newSVpv(PQerrorMessage(conn), 0));
    return fu_croak_hv(hv, "FU::Pg::error", "FATAL: %s", PQerrorMessage(conn));
}

__attribute__((noreturn))
static void fupg_conn_croak(fupg_conn *c, const char *action) {
    dTHX;
    croak_sv(fupg_conn_errsv(c->conn, action));
}

/* Takes ownership of the PGresult and croaks. */
__attribute__((noreturn))
static void fupg_result_croak(PGresult *r, const char *action, const char *query) {
    dTHX;
    HV *hv = newHV();
    hv_stores(hv, "action", newSVpv(action, 0));
    char *s = PQresultErrorField(r, PG_DIAG_SEVERITY_NONLOCALIZED);
    hv_stores(hv, "severity", newSVpv(s ? s : "FATAL", 0));
    if (query) hv_stores(hv, "query", newSVpv(query, 0));

    /* If the PGresult is not an error, assume it's an unexpected resultStatus */
    s = PQresultErrorField(r, PG_DIAG_MESSAGE_PRIMARY);
    hv_stores(hv, "message", s ? newSVpv(s, 0) : newSVpvf("unexpected status code '%s'", PQresStatus(PQresultStatus(r))));

    /* I like the verbose error messages. Doesn't include anything that's not
     * also fetched below, but saves me from having to do the formatting
     * manually. */
    char *verbose = NULL;
    if (s) {
        verbose = PQresultVerboseErrorMessage(r, PQERRORS_VERBOSE, PQSHOW_CONTEXT_ERRORS);
        if (s) {
            hv_stores(hv, "verbose_message", newSVpv(verbose, 0));
            PQfreemem(verbose);
        }
    }

    if ((s = PQresultErrorField(r, PG_DIAG_MESSAGE_DETAIL))) hv_stores(hv, "detail", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_MESSAGE_HINT))) hv_stores(hv, "hint", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_STATEMENT_POSITION))) hv_stores(hv, "statement_position", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_INTERNAL_POSITION))) hv_stores(hv, "internal_position", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_INTERNAL_QUERY))) hv_stores(hv, "internal_query", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_CONTEXT))) hv_stores(hv, "context", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_SCHEMA_NAME))) hv_stores(hv, "schema_name", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_TABLE_NAME))) hv_stores(hv, "table_name", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_COLUMN_NAME))) hv_stores(hv, "column_name", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_DATATYPE_NAME))) hv_stores(hv, "datatype_name", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_CONSTRAINT_NAME))) hv_stores(hv, "constraint_name", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_SOURCE_FILE))) hv_stores(hv, "source_file", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_SOURCE_LINE))) hv_stores(hv, "source_line", newSVpv(s, 0));
    if ((s = PQresultErrorField(r, PG_DIAG_SOURCE_FUNCTION))) hv_stores(hv, "source_function", newSVpv(s, 0));

    PQclear(r);
    croak_sv(verbose
        ? fu_croak_hv(hv, "FU::Pg::error", "%s", SvPV_nolen(*hv_fetchs(hv, "verbose_message", 0)))
        : fu_croak_hv(hv, "FU::Pg::error", "%s: %s",
            SvPV_nolen(*hv_fetchs(hv, "severity", 0)),
            SvPV_nolen(*hv_fetchs(hv, "message", 0))
        )
    );
}

static SV *fupg_exec_result(pTHX_ PGresult *r) {
    SV *ret = &PL_sv_undef;
    char *tup = PQcmdTuples(r);
    if (tup && *tup) {
        ret = sv_2mortal(newSVpv(tup, 0));
        SvIV(ret);
        SvIOK_only(ret);
    }
    return ret;
}

static void fupg_exec_ok(fupg_conn *c, const char *sql) {
    PGresult *r = PQexec(c->conn, sql);
    if (!r) fupg_conn_croak(c, "exec");
    if (PQresultStatus(r) != PGRES_COMMAND_OK) fupg_result_croak(r, "exec", sql);
    PQclear(r);
}




/* Connection & transaction handling */

static SV *fupg_connect(pTHX_ const char *str) {
    if (!PQconnectdb) fupg_load();
    PGconn *conn = PQconnectdb(str);
    if (PQstatus(conn) != CONNECTION_OK) {
        SV *sv = fupg_conn_errsv(conn, "connect");
        PQfinish(conn);
        croak_sv(sv);
    }

    fupg_conn *c = safemalloc(sizeof(fupg_conn));
    c->conn = conn;
    c->trace = NULL;
    c->prep_counter = c->cookie_counter = c->cookie = 0;
    c->stflags = FUPG_CACHE;
    c->ntypes = 0;
    c->types = NULL;
    c->records = fupg_records_init();
    c->oidtypes = fupg_oid_overrides_init();
    c->nametypes = fupg_name_overrides_init();
    c->prep_cur = 0;
    c->prep_max = 256;
    c->prep_map = fupg_prepared_init();
    c->prep_head = c->prep_tail = NULL;
    fustr_init(&c->buf, NULL, SIZE_MAX);
    return fu_selfobj(c, "FU::Pg::conn");
}

static const char *fupg_conn_status(fupg_conn *c) {
    if (PQstatus(c->conn) == CONNECTION_BAD) return "bad";
    switch (PQtransactionStatus(c->conn)) {
        case PQTRANS_IDLE: return c->cookie ? "txn_done" : "idle";
        case PQTRANS_ACTIVE: return "active"; /* can't happen, we don't do async */
        case PQTRANS_INTRANS: return "txn_idle";
        case PQTRANS_INERROR: return "txn_error";
        default: return "unknown";
    }
}

static void fupg_conn_disconnect(fupg_conn *c) {
    PQfinish(c->conn);
    c->conn = NULL;
    /* We don't have an API to reconnect with the same $conn object, so no need
     * to clean up the prepared statement cache at this point. */
}

static void fupg_conn_destroy(pTHX_ fupg_conn *c) {
    PQfinish(c->conn);
    if (c->buf.sv) SvREFCNT_dec(c->buf.sv);
    safefree(c->types);
    khint_t k;

    kh_foreach(c->oidtypes, k) {
        SvREFCNT_dec(kh_val(c->oidtypes, k).sendcb);
        SvREFCNT_dec(kh_val(c->oidtypes, k).recvcb);
    }
    fupg_oid_overrides_destroy(c->oidtypes);

    kh_foreach(c->nametypes, k) {
        SvREFCNT_dec(kh_val(c->nametypes, k).sendcb);
        SvREFCNT_dec(kh_val(c->nametypes, k).recvcb);
    }
    fupg_name_overrides_destroy(c->nametypes);

    kh_foreach(c->records, k) safefree(kh_val(c->records, k));
    fupg_records_destroy(c->records);

    kh_foreach(c->prep_map, k) fupg_prep_destroy(kh_key(c->prep_map, k));
    fupg_prepared_destroy(c->prep_map);

    safefree(c);
}

static SV *fupg_conn_txn(pTHX_ fupg_conn *c) {
    fupg_exec_ok(c, "BEGIN");
    fupg_txn *t = safecalloc(1, sizeof(fupg_txn));
    t->conn = c;
    t->cookie = c->cookie = ++c->cookie_counter;
    t->stflags = c->stflags;
    strcpy(t->rollback_cmd, "ROLLBACK");
    SvREFCNT_inc(c->self);
    return fu_selfobj(t, "FU::Pg::txn");
}

static SV *fupg_txn_txn(pTHX_ fupg_txn *t) {
    char cmd[64];
    UV cookie = ++t->conn->cookie_counter;
    snprintf(cmd, sizeof(cmd), "SAVEPOINT fupg_%"UVuf, cookie);
    fupg_exec_ok(t->conn, cmd);

    fupg_txn *n = safecalloc(1, sizeof(fupg_txn));
    n->conn = t->conn;
    n->parent = t;
    n->cookie = t->conn->cookie = cookie;
    n->stflags = t->stflags;
    snprintf(n->rollback_cmd, sizeof(n->rollback_cmd), "ROLLBACK TO SAVEPOINT fupg_%"UVuf, cookie);
    SvREFCNT_inc(t->self);
    return fu_selfobj(n, "FU::Pg::txn");
}

static const char *fupg_txn_status(fupg_txn *t) {
    if (PQstatus(t->conn->conn) == CONNECTION_BAD) return "bad";
    if (!t->cookie) return "done";
    int a = t->cookie == t->conn->cookie;
    switch (PQtransactionStatus(t->conn->conn)) {
        case PQTRANS_IDLE: return "done";
        case PQTRANS_ACTIVE: return "active";
        case PQTRANS_INTRANS: return a ? "idle" : "txn_idle";
        case PQTRANS_INERROR: return a ? "error" : "txn_error";
        default: return "unknown";
    }
}

static void fupg_txn_commit(fupg_txn *t) {
    char cmd[64];
    if (t->parent) snprintf(cmd, sizeof(cmd), "RELEASE SAVEPOINT fupg_%"UVuf, t->cookie);
    else strcpy(cmd, "COMMIT");
    t->cookie = 0;
    fupg_exec_ok(t->conn, cmd);
}

static void fupg_txn_rollback(fupg_txn *t) {
    t->cookie = 0;
    fupg_exec_ok(t->conn, t->rollback_cmd);
}

static void fupg_txn_destroy(pTHX_ fupg_txn *t) {
    if (t->cookie) {
        PGresult *r = PQexec(t->conn->conn, t->rollback_cmd);
        /* Can't really throw an error in DESTROY. If a rollback command fails,
         * we're sufficiently screwed that the only sensible recourse is to
         * disconnect and let any further operations throw an error. */
        if (!r || PQresultStatus(r) != PGRES_COMMAND_OK)
            fupg_conn_disconnect(t->conn);
        PQclear(r);
    }
    if (t->parent) {
        t->conn->cookie = t->parent->cookie;
        SvREFCNT_dec(t->parent->self);
    } else {
        t->conn->cookie = 0;
        SvREFCNT_dec(t->conn->self);
    }
    safefree(t);
}




/* Prepared statement caching */

static void fupg_prepared_list_remove(fupg_conn *c, fupg_prep *p) {
    if (p->next) p->next->prev = p->prev;
    if (p->prev) p->prev->next = p->next;
    if (c->prep_head == p) c->prep_head = p->next;
    if (c->prep_tail == p) c->prep_tail = p->prev;
    c->prep_cur--;
}

static void fupg_prepared_list_unshift(fupg_conn *c, fupg_prep *p) {
    p->next = c->prep_head;
    p->prev = NULL;
    c->prep_head = p;
    if (p->next) p->next->prev = p;
    else c->prep_tail = p;
    c->prep_cur++;
}

static void fupg_prepared_prune(fupg_conn *c) {
    while (c->prep_cur > c->prep_max) {
        fupg_prep *p = c->prep_tail;
        fupg_prepared_list_remove(c, p);
        assert(p->ref == 0);

        khint_t k = fupg_prepared_get(c->prep_map, p);
        assert(k != kh_end(c->prep_map));
        fupg_prepared_del(c->prep_map, k);

        char name[64];
        snprintf(name, sizeof(name), "fupg%"UVuf, p->name);
        PQclear(PQclosePrepared(c->conn, name));
        fupg_prep_destroy(p);
    }
}

/* Fetch and ref a prepared statement, returns a new object if nothing was cached */
static fupg_prep *fupg_prepared_ref(pTHX_ fupg_conn *c, const char *query) {
    fupg_prep prep;
    prep.hash = kh_hash_str(query);
    prep.query = (char *)query;
    khint_t k = fupg_prepared_get(c->prep_map, &prep);
    fupg_prep *p;

    if (k == kh_end(c->prep_map)) {
        p = safecalloc(1, sizeof(*p));
        p->hash = prep.hash;
        p->query = savepv(query);
        p->ref = 1;
        int i;
        fupg_prepared_put(c->prep_map, p, &i);

    } else {
        p = kh_key(c->prep_map, k);
        if (!p->ref++) fupg_prepared_list_remove(c, p);
    }
    return p;
}

static void fupg_prepared_unref(fupg_conn *c, fupg_prep *p) {
    assert(p->ref > 0);
    if (!--p->ref) {
        fupg_prepared_list_unshift(c, p);
        fupg_prepared_prune(c);
    }
}




/* Type handling */

static const fupg_type *fupg_resolve_builtin(pTHX_ SV *name, SV **cb) {
    SvGETMAGIC(name);
    *cb = NULL;
    if (!SvOK(name)) return NULL;

    if (SvROK(name)) {
        SV *rv = SvRV(name);
        if (SvTYPE(rv) == SVt_PVCV) {
            *cb = SvREFCNT_inc(name);
            return &fupg_type_perlcb;
        }
    }

    UV uv;
    const char *pv = SvPV_nomg_nolen(name);
    const fupg_type *t = grok_atoUV(pv, &uv, NULL) && uv <= (UV)UINT_MAX
        ? fupg_builtin_byoid((Oid)uv)
        : fupg_builtin_byname(pv);
    if (!t) fu_confess("No builtin type found with oid or name '%s'", pv);
    return t;
}

static void fupg_set_type(pTHX_ fupg_conn *c, SV *name, SV *sendsv, SV *recvsv) {
    fupg_override o;
    o.send = fupg_resolve_builtin(aTHX_ sendsv, &o.sendcb);
    o.recv = fupg_resolve_builtin(aTHX_ recvsv, &o.recvcb);
    if ((o.send && o.send->send == fupg_send_array) || (o.recv && o.recv->recv == fupg_recv_array))
        fu_confess("Cannot set a type to array, override the underlying element type instead");
    /* Can't currently happen since we have no records in the builtin type
     * list, but catch this just in case that changes. */
    if ((o.send && o.send->send == fupg_send_record) || (o.recv && o.recv->recv == fupg_recv_record))
        fu_confess("Cannot set a type to record");

    UV uv;
    STRLEN len;
    const char *pv = SvPV(name, len);
    int k, absent;
    fupg_override *so = NULL;
    if (grok_atoUV(pv, &uv, NULL) && uv <= (UV)UINT_MAX) {
        k = fupg_oid_overrides_put(c->oidtypes, (Oid)uv, &absent);
        so = &kh_val(c->oidtypes, k);
    } else if (len < sizeof(fupg_name)) {
        fupg_name n;
        strcpy(n.n, pv);
        k = fupg_name_overrides_put(c->nametypes, n, &absent);
        so = &kh_val(c->nametypes, k);
    } else {
        fu_confess("Invalid type oid or name '%s'", pv);
    }
    if (!absent) {
        SvREFCNT_dec(so->sendcb);
        SvREFCNT_dec(so->recvcb);
    }
    *so = o;
}


/* XXX: It feels a bit wasteful to load *all* types; even on an empty database
 * that's ~55k of data, but it's easier and (potentially) faster than fetching
 * each type seperately as we encounter them.
 * Perhaps an easier optimization is to filter out all table-based composites
 * and their array types by default, I've never seen anyone use those types for
 * I/O and that would shrink the data by nearly a factor 5.
 */
static void fupg_refresh_types(pTHX_ fupg_conn *c) {
    safefree(c->types);
    c->types = 0;
    c->ntypes = 0;

    const char *sql =
        "SELECT oid, typname, typtype"
             ", CASE WHEN typtype = 'd' THEN typbasetype"
                   " WHEN typtype = 'c' THEN typrelid"
                   " WHEN typcategory = 'A' THEN typelem"
                   " ELSE 0 END"
        " FROM pg_type"
       " ORDER BY oid";
    PGresult *r = PQexecParams(c->conn, sql, 0, NULL, NULL, NULL, NULL, 1);
    if (!r) fupg_conn_croak(c, "exec");
    if (PQresultStatus(r) != PGRES_TUPLES_OK) fupg_result_croak(r, "exec", sql);

    c->ntypes = PQntuples(r);
    c->types = safecalloc(c->ntypes, sizeof(*c->types));
    int i;
    for (i=0; i<c->ntypes; i++) {
        fupg_type *t = c->types + i;
        t->oid = fu_frombeU(32, PQgetvalue(r, i, 0));
        snprintf(t->name.n, sizeof(t->name.n), "%s", PQgetvalue(r, i, 1));
        char typ = *PQgetvalue(r, i, 2);
        t->elemoid = fu_frombeU(32, PQgetvalue(r, i, 3));

        if (t->elemoid) {
            if (typ == 'd') { /* domain */
                t->send = fupg_send_domain;
                t->recv = fupg_recv_domain;
            } else if (typ == 'c') { /* composite type */
                t->send = fupg_send_record;
                t->recv = fupg_recv_record;
            } else { /* array */
                t->send = fupg_send_array;
                t->recv = fupg_recv_array;
            }
        } else if (typ == 'e') {
            /* enum, can use text send/recv */
            t->send = fupg_send_text;
            t->recv = fupg_recv_text;
        } else {
            /* TODO: (multi)ranges, custom overrides, by-name lookup for dynamic-oid types */
            const fupg_type *builtin = fupg_builtin_byoid(t->oid);
            if (builtin) {
                t->send = builtin->send;
                t->recv = builtin->recv;
            }
        }
    }
    PQclear(r);
}

static const fupg_type *fupg_lookup_type(pTHX_ fupg_conn *c, int *refresh_done, Oid oid) {
    if (oid == 0) return NULL;
    const fupg_type *t = NULL;
    if (c->types && (t = fupg_type_byoid(c->types, c->ntypes, oid))) return t;
    if ((t = fupg_builtin_byoid(oid))) return t;
    if (*refresh_done) return NULL;
    *refresh_done = 1;
    fupg_refresh_types(aTHX_ c);
    return fupg_type_byoid(c->types, c->ntypes, oid);
}


static const fupg_record *fupg_lookup_record(fupg_conn *c, Oid oid) {
    khint_t k = fupg_records_get(c->records, oid);
    if (k != kh_end(c->records)) return kh_val(c->records, k);

    const char *sql =
        "SELECT atttypid, attname"
         " FROM pg_attribute"
        " WHERE NOT attisdropped AND attnum > 0 AND attrelid = $1"
        " ORDER BY attnum";
    char buf[4];
    fu_tobeU(32, buf, oid);
    const char *abuf = buf;
    int len = 4;
    int format = 1;
    PGresult *r = PQexecParams(c->conn, sql, 1, NULL, &abuf, &len, &format, 1);
    if (!r) fupg_conn_croak(c, "exec");
    if (PQresultStatus(r) != PGRES_TUPLES_OK) fupg_result_croak(r, "exec", sql);

    fupg_record *record = safemalloc(sizeof(*record) + PQntuples(r) * sizeof(*record->attrs));
    record->nattrs = PQntuples(r);
    int i;
    for (i=0; i<record->nattrs; i++) {
        record->attrs[i].oid = fu_frombeU(32, PQgetvalue(r, i, 0));
        snprintf(record->attrs[i].name.n, sizeof(record->attrs->name.n), "%s", PQgetvalue(r, i, 1));
    }
    k = fupg_records_put(c->records, oid, &i);
    kh_val(c->records, k) = record;
    PQclear(r);
    return record;
}


#define FUPGT_TEXT 1
#define FUPGT_SEND 2
#define FUPGT_RECV 4

static const fupg_type *fupg_override_get(fupg_conn *c, int flags, Oid oid, const fupg_name *name, SV **cb) {
    khint_t k;
    fupg_override *o;
    if (name == NULL) {
        k = fupg_oid_overrides_get(c->oidtypes, oid);
        o = k == kh_end(c->oidtypes) ? NULL : &kh_val(c->oidtypes, k);
    } else {
        k = fupg_name_overrides_get(c->nametypes, *name);
        o = k == kh_end(c->nametypes) ? NULL : &kh_val(c->nametypes, k);
    }
    if (!o) return NULL;
    *cb = flags & FUPGT_SEND ? o->sendcb : o->recvcb;
    return flags & FUPGT_SEND ? o->send : o->recv;
}

static void fupg_tio_setup(pTHX_ fupg_conn *conn, fupg_tio *tio, int flags, Oid oid, int *refresh_done) {
    tio->oid = oid;
    if (flags & FUPGT_TEXT) {
        tio->name = "{textfmt}";
        tio->send = fupg_send_text;
        tio->recv = fupg_recv_text;
        return;
    }

    /* Minor wart? When the type is overridden by oid, the name & oid in error
     * messages will be that of the builtin type.  When overridden by name, the
     * name will be correct but the oid is still of the builtin type.
     * Some send/recv functions have slightly different behavior based on oid,
     * in those cases this behavior is useful. */

    SV *cb = NULL;
    const fupg_type *e, *t;
    e = t = fupg_override_get(conn, flags, oid, NULL, &cb);
    if (!t) t = fupg_lookup_type(aTHX_ conn, refresh_done, oid);
    if (!t) fu_confess("No type found with oid %u", oid);
    tio->name = t->name.n;
    if (!e && (e = fupg_override_get(conn, flags, 0, &t->name, &cb))) t = e;

    if (flags & FUPGT_SEND && !t->send) fu_confess("Unable to send type '%s' (oid %u)", tio->name, oid);
    if (flags & FUPGT_RECV && !t->recv) fu_confess("Unable to receive type '%s' (oid %u)", tio->name, oid);

    if (flags & FUPGT_SEND ? t->send == fupg_send_domain : t->recv == fupg_recv_domain) {
        e = fupg_lookup_type(aTHX_ conn, refresh_done, t->elemoid);
        if (!e) fu_confess("Base type %u not found for domain '%s' (oid %u)", t->elemoid, tio->name, t->oid);
        t = e;
    }

    tio->send = t->send;
    tio->recv = t->recv;

    if (flags & FUPGT_SEND ? tio->send == fupg_send_perlcb : tio->recv == fupg_recv_perlcb) {
        tio->cb = cb;

    } else if (flags & FUPGT_SEND ? tio->send == fupg_send_array : tio->recv == fupg_recv_array) {
        tio->arrayelem = safecalloc(1, sizeof(*tio->arrayelem));
        fupg_tio_setup(aTHX_ conn, tio->arrayelem, flags, t->elemoid, refresh_done);

    } else if (flags & FUPGT_SEND ? tio->send == fupg_send_record : tio->recv == fupg_recv_record) {
        tio->record.info = fupg_lookup_record(conn, t->elemoid);
        if (!tio->record.info) fu_confess("Unable to find attributes for record type '%s' (oid %u, relid %u)", tio->name, t->oid, t->elemoid);
        tio->record.tio = safecalloc(tio->record.info->nattrs, sizeof(*tio->record.tio));
        int i;
        for (i=0; i<tio->record.info->nattrs; i++)
            fupg_tio_setup(aTHX_ conn, tio->record.tio+i, flags, tio->record.info->attrs[i].oid, refresh_done);
    }
}

static void fupg_tio_free(fupg_tio *tio) {
    if (!tio) return;
    /* XXX: This assumes send/recv are the same types, at least for arrays & records */
    if (tio->send == fupg_send_array) {
        fupg_tio_free(tio->arrayelem);
        safefree(tio->arrayelem);
    } else if (tio->send == fupg_send_record) {
        int i;
        for (i=0; i<tio->record.info->nattrs; i++)
            fupg_tio_free(tio->record.tio+i);
        safefree(tio->record.tio);
    }
}
