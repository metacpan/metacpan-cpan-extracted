#include <stdio.h>
#include <errno.h>
#include <time.h> /* struct timespec & clock_gettime() */
#include <string.h> /* strerror() */
#include <arpa/inet.h> /* inet_ntop(), inet_ntoa() */
#include <sys/socket.h> /* fd passing */
#include <sys/un.h> /* fd passing */
#include <dlfcn.h> /* dlopen() etc */


#undef PERL_IMPLICIT_SYS
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef av_push_simple
#define av_push_simple av_push
#endif
#ifndef BOOL_INTERNALS_sv_isbool_true
#define BOOL_INTERNALS_sv_isbool_true(x) SvTRUEx(x)
#endif
#ifndef newSV_true
#define newSV_true() newSVsv(&PL_sv_yes)
#endif
#ifndef newSV_false
#define newSV_false() newSVsv(&PL_sv_no)
#endif

/* Disable key/value struct packing in khashl, so we can safely take a pointer
 * to values inside the hash table. */
#define kh_packed

#include "c/khashl.h"
#include "c/common.c"

#include "c/compress.c"
#include "c/fcgi.c"
#include "c/fdpass.c"
#include "c/jsonfmt.c"
#include "c/jsonparse.c"
#include "c/xmlwr.c"

#include "c/libpq.h"
#include "c/pgtypes.c"
#include "c/pgconn.c"
#include "c/pgst.c"


#define FUPG_CONN_COOKIE \
    if (c->cookie) fu_confess("Invalid operation on the top-level connection while a transaction object exists")

#define FUPG_TXN_COOKIE \
    if (!t->cookie) fu_confess("Invalid operation on a transaction that has already been marked as done"); \
    if (t->cookie != t->conn->cookie) fu_confess("Invalid operation on transaction while a subtransaction object exists")

#define FUPG_ST_COOKIE \
    if (st->cookie != st->conn->cookie) fu_confess("Invalid cross-transaction operation on statement object")

#define FUPG_STFLAGS do {\
        if (!ix) ix = FUPG_CACHE;\
        if (items == 1 || SvTRUE(ST(1))) x->stflags |= ix; \
        else x->stflags &= ~ix; \
    } while(0)

MODULE = FU

PROTOTYPES: DISABLE


TYPEMAP: <<EOT
TYPEMAP
fufcgi *      FUFCGI
fuxmlwr *     FUXMLWR
fupg_conn *   FUPG_CONN
fupg_txn *    FUPG_TXN
fupg_st *     FUPG_ST
fupg_copy *   FUPG_COPY

INPUT
FUFCGI
    if (sv_derived_from($arg, \"FU::fcgi\")) $var = (fufcgi *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid FastCGI object\");

FUXMLWR
    if (sv_derived_from($arg, \"FU::XMLWriter\")) $var = (fuxmlwr *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid FU::XMLWriter object\");

FUPG_CONN
    if (sv_derived_from($arg, \"FU::Pg::conn\")) $var = (fupg_conn *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid connection object\");

FUPG_TXN
    if (sv_derived_from($arg, \"FU::Pg::txn\")) $var = (fupg_txn *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid transaction object\");

FUPG_ST
    if (sv_derived_from($arg, \"FU::Pg::st\")) $var = (fupg_st *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid statement object\");

FUPG_COPY
    if (sv_derived_from($arg, \"FU::Pg::copy\")) $var = (fupg_copy *)SvIVX(SvRV($arg));
    else fu_confess(\"invalid COPY object\");
#"
EOT


MODULE = FU   PACKAGE = FU::Util

void to_bool(SV *val)
  PROTOTYPE: $
  CODE:
    SvGETMAGIC(val);
    int r = fu_2bool(aTHX_ val);
    ST(0) = r < 0 ? &PL_sv_undef : r ? &PL_sv_yes : &PL_sv_no;

void json_format(SV *val, ...)
  CODE:
    ST(0) = fujson_fmt_xs(aTHX_ ax, items, val);

void json_parse(SV *val, ...)
  CODE:
    ST(0) = fujson_parse_xs(aTHX_ ax, items, val);

void gzip_lib()
  PROTOTYPE:
  CODE:
    ST(0) = sv_2mortal(newSVpv(fugz_lib(), 0));

void gzip_compress(IV level, SV *in)
  CODE:
    ST(0) = fugz_compress(aTHX_ level, in);

void brotli_compress(IV level, SV *in)
  CODE:
    ST(0) = fubr_compress(aTHX_ level, in);

void fdpass_send(int socket, int fd, SV *data)
  CODE:
    STRLEN buflen;
    const char *buf = SvPVbyte(data, buflen);
    ST(0) = sv_2mortal(newSViv(fufdpass_send(socket, fd, buf, buflen)));

void fdpass_recv(int socket, UV len)
  CODE:
    XSRETURN(fufdpass_recv(aTHX_ ax, socket, len));



MODULE = FU   PACKAGE = FU::fcgi

void new(int fd, int maxproc)
  CODE:
    fufcgi *ctx = safemalloc(sizeof(*ctx));
    ctx->fd = fd;
    ctx->maxproc = maxproc;
    ctx->reqid = ctx->keepconn = ctx->len = ctx->off = 0;
    ST(0) = fu_selfobj(ctx, "FU::fcgi");

void read_req(fufcgi *ctx, SV *headers, SV *params)
  CODE:
    ST(0) = sv_2mortal(newSViv(fufcgi_read_req(aTHX_ ctx, headers, params)));
    ctx->off = ctx->len = 0;

void keepalive(fufcgi *ctx)
  CODE:
    ST(0) = ctx->keepconn ? &PL_sv_yes : &PL_sv_no;

void print(fufcgi *ctx, SV *sv)
  CODE:
    STRLEN len;
    const char *buf = SvPVbyte(sv, len);
    fufcgi_print(ctx, buf, len);

void flush(fufcgi *ctx)
  CODE:
    fufcgi_done(ctx);

void DESTROY(fufcgi *ctx)
  CODE:
    safefree(ctx);



MODULE = FU   PACKAGE = FU::Pg

void _load_libpq()
  CODE:
    if (!PQconnectdb) fupg_load();

void lib_version()
  CODE:
    XSRETURN_IV(PQlibVersion());

void connect(const char *pkg, const char *conninfo)
  CODE:
    (void)pkg;
    ST(0) = fupg_connect(aTHX_ conninfo);



MODULE = FU   PACKAGE = FU::Pg::conn

void server_version(fupg_conn *c)
  CODE:
    XSRETURN_IV(PQserverVersion(c->conn));

void _debug_trace(fupg_conn *c, bool on)
  CODE:
    if (on) PQtrace(c->conn, stderr);
    else PQuntrace(c->conn);
    ST(0) = c->self;

void query_trace(fupg_conn *c, SV *cb)
  CODE:
    if (c->trace) SvREFCNT_dec(c->trace);
    SvGETMAGIC(cb);
    c->trace = SvOK(cb) ? SvREFCNT_inc(cb) : NULL;

void conn(fupg_conn *c)
  CODE:
    ST(0) = sv_newmortal();
    sv_setrv_inc(ST(0), c->self);
    sv_bless(ST(0), gv_stashpv("FU::Pg::conn", 0));

void status(fupg_conn *c)
  CODE:
    ST(0) = sv_2mortal(newSVpv(fupg_conn_status(c), 0));

void escape_literal(fupg_conn *c, SV *v)
  CODE:
    STRLEN len;
    const char *str = SvPVutf8(v, len);
    char *r = PQescapeLiteral(c->conn, str, len);
    if (!r) fupg_conn_croak(c, "escapeLiteral");
    ST(0) = newSVpvn_flags(r, strlen(r), SVf_UTF8|SVs_TEMP);
    PQfreemem(r);

void escape_identifier(fupg_conn *c, SV *v)
  CODE:
    STRLEN len;
    const char *str = SvPVutf8(v, len);
    char *r = PQescapeIdentifier(c->conn, str, len);
    if (!r) fupg_conn_croak(c, "escapeIdentifier");
    ST(0) = newSVpvn_flags(r, strlen(r), SVf_UTF8|SVs_TEMP);
    PQfreemem(r);

void cache(fupg_conn *x, ...)
  ALIAS:
    FU::Pg::conn::text_params  = FUPG_TEXT_PARAMS
    FU::Pg::conn::text_results = FUPG_TEXT_RESULTS
    FU::Pg::conn::text         = FUPG_TEXT
  CODE:
    FUPG_STFLAGS;

void cache_size(fupg_conn *c, unsigned int n)
  CODE:
    c->prep_max = n;
    fupg_prepared_prune(c);
    XSRETURN(1);

void disconnect(fupg_conn *c)
  CODE:
    fupg_conn_disconnect(c);

void DESTROY(fupg_conn *c)
  CODE:
    fupg_conn_destroy(aTHX_ c);

void txn(fupg_conn *c)
  CODE:
    FUPG_CONN_COOKIE;
    ST(0) = fupg_conn_txn(aTHX_ c);

void exec(fupg_conn *c, SV *sv)
  CODE:
    FUPG_CONN_COOKIE;
    ST(0) = fupg_exec(aTHX_ c, SvPVutf8_nolen(sv));

void q(fupg_conn *c, SV *sv, ...)
  CODE:
    FUPG_CONN_COOKIE;
    ST(0) = fupg_q(aTHX_ c, c->stflags, SvPVutf8_nolen(sv), ax, items);

void copy(fupg_conn *c, SV *sv)
  CODE:
    FUPG_CONN_COOKIE;
    ST(0) = fupg_copy_exec(aTHX_ c, SvPVutf8_nolen(sv));

void _set_type(fupg_conn *c, SV *name, SV *sendsv, SV *recvsv)
  CODE:
    fupg_set_type(aTHX_ c, name, sendsv, recvsv);
    XSRETURN(1);

void perl2bin(fupg_conn *c, int oid, SV *sv)
  CODE:
    ST(0) = fupg_perl2bin(aTHX_ c, oid, sv);

void bin2perl(fupg_conn *c, int oid, SV *sv)
  CODE:
    ST(0) = fupg_bin2perl(aTHX_ c, oid, sv);

void bin2text(fupg_conn *c, ...)
  CODE:
    XSRETURN(fupg_bintext(aTHX_ c, 0, ax, items));

void text2bin(fupg_conn *c, ...)
  CODE:
    XSRETURN(fupg_bintext(aTHX_ c, 1, ax, items));


MODULE = FU   PACKAGE = FU::Pg::txn

void DESTROY(fupg_txn *t)
  CODE:
    fupg_txn_destroy(aTHX_ t);

void cache(fupg_txn *x, ...)
  ALIAS:
    FU::Pg::txn::text_params  = FUPG_TEXT_PARAMS
    FU::Pg::txn::text_results = FUPG_TEXT_RESULTS
    FU::Pg::txn::text         = FUPG_TEXT
  CODE:
    FUPG_STFLAGS;

void conn(fupg_txn *t)
  CODE:
    ST(0) = sv_newmortal();
    sv_setrv_inc(ST(0), t->conn->self);
    sv_bless(ST(0), gv_stashpv("FU::Pg::conn", 0));

void status(fupg_txn *t)
  CODE:
    ST(0) = sv_2mortal(newSVpv(fupg_txn_status(t), 0));

void txn(fupg_txn *t)
  CODE:
    FUPG_TXN_COOKIE;
    ST(0) = fupg_txn_txn(aTHX_ t);

void commit(fupg_txn *t)
  CODE:
    FUPG_TXN_COOKIE;
    fupg_txn_commit(t);

void rollback(fupg_txn *t)
  CODE:
    FUPG_TXN_COOKIE;
    fupg_txn_rollback(t);

void exec(fupg_txn *t, SV *sv)
  CODE:
    FUPG_TXN_COOKIE;
    ST(0) = fupg_exec(aTHX_ t->conn, SvPVutf8_nolen(sv));

void q(fupg_txn *t, SV *sv, ...)
  CODE:
    FUPG_TXN_COOKIE;
    ST(0) = fupg_q(aTHX_ t->conn, t->stflags, SvPVutf8_nolen(sv), ax, items);

# XXX: The copy object should probably keep a ref on the transaction
void copy(fupg_txn *t, SV *sv)
  CODE:
    FUPG_TXN_COOKIE;
    ST(0) = fupg_copy_exec(aTHX_ t->conn, SvPVutf8_nolen(sv));



MODULE = FU   PACKAGE = FU::Pg::st

void cache(fupg_st *x, ...)
  ALIAS:
    FU::Pg::st::text_params  = FUPG_TEXT_PARAMS
    FU::Pg::st::text_results = FUPG_TEXT_RESULTS
    FU::Pg::st::text         = FUPG_TEXT
  CODE:
    if (ix == 0 && x->prepared) fu_confess("Invalid attempt to change statement configuration after it has already been prepared or executed");
    FUPG_STFLAGS;
    XSRETURN(1);

void exec(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_exec(aTHX_ st);

void val(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_val(aTHX_ st);

void rowl(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    XSRETURN(fupg_st_rowl(aTHX_ st, ax));

void rowa(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_rowa(aTHX_ st);

void rowh(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_rowh(aTHX_ st);

void alla(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_alla(aTHX_ st);

void allh(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_allh(aTHX_ st);

void flat(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_flat(aTHX_ st);

void kvv(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_kvv(aTHX_ st);

void kva(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_kva(aTHX_ st);

void kvh(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_kvh(aTHX_ st);

void param_types(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_param_types(aTHX_ st);

void param_values(fupg_st *st);
  CODE:
    ST(0) = fupg_st_param_values(aTHX_ st);

void columns(fupg_st *st)
  CODE:
    FUPG_ST_COOKIE;
    ST(0) = fupg_st_columns(aTHX_ st);

void nrows(fupg_st *st)
  CODE:
    ST(0) = st->result ? sv_2mortal(newSViv(PQntuples(st->result))) : &PL_sv_undef;

void query(fupg_st *st)
  CODE:
    ST(0) = newSVpvn_flags(st->query, strlen(st->query), SVs_TEMP|SVf_UTF8);

void exec_time(fupg_st *st)
  CODE:
    ST(0) = st->exectime <= 0 ? &PL_sv_undef : sv_2mortal(newSVnv(st->exectime));

void prepare_time(fupg_st *st)
  CODE:
    ST(0) = !st->prepared ? &PL_sv_undef : sv_2mortal(newSVnv(st->preptime));

void get_cache(fupg_st *st)
  ALIAS:
    FU::Pg::st::get_text_params  = FUPG_TEXT_PARAMS
    FU::Pg::st::get_text_results = FUPG_TEXT_RESULTS
  CODE:
    if (!ix) ix = FUPG_CACHE;
    ST(0) = st->stflags & ix ? &PL_sv_yes : &PL_sv_no;

void DESTROY(fupg_st *st)
  CODE:
    fupg_st_destroy(aTHX_ st);


MODULE = FU   PACKAGE = FU::Pg::copy

void write(fupg_copy *c, SV *sv)
  CODE:
    fupg_copy_write(aTHX_ c, sv);

void read(fupg_copy *c)
  CODE:
    ST(0) = fupg_copy_read(aTHX_ c, 0);

void is_binary(fupg_copy *c)
  CODE:
    ST(0) = c->bin ? &PL_sv_yes : &PL_sv_no;

void close(fupg_copy *c)
  CODE:
    fupg_copy_close(aTHX_ c, 0);

void DESTROY(fupg_copy *c)
  CODE:
    fupg_copy_destroy(aTHX_ c);


MODULE = FU   PACKAGE = FU::XMLWriter

void _new()
  CODE:
    ST(0) = fuxmlwr_new(aTHX);

void _done(fuxmlwr *wr)
  CODE:
    ST(0) = sv_2mortal(fustr_done(&wr->out));
    fustr_init(&wr->out, NULL, SIZE_MAX);

void lit_(SV *sv)
  CODE:
    if (!fuxmlwr_tail) fu_confess("No active FU::XMLWriter instance");
    STRLEN len;
    const char *buf = SvPVutf8(sv, len);
    fustr_write(&fuxmlwr_tail->out, buf, len);

void txt_(SV *sv)
  CODE:
    if (!fuxmlwr_tail) fu_confess("No active FU::XMLWriter instance");
    fuxmlwr_escape(aTHX_ fuxmlwr_tail, sv);

void tag_(SV *sv, ...)
  CODE:
    if (!fuxmlwr_tail) fu_confess("No active FU::XMLWriter instance");
    STRLEN len;
    const char *tagname = SvPV(sv, len);
    fuxmlwr_isname(tagname);
    fuxmlwr_tag(aTHX_ fuxmlwr_tail, ax, 1, items, 0, tagname, len);

INCLUDE_COMMAND: $^X -e '$FU::XMLWriter::XSPRINT=1; require "./FU/XMLWriter.pm"'

void DESTROY(fuxmlwr *wr)
  CODE:
    fuxmlwr_destroy(aTHX_ wr);
