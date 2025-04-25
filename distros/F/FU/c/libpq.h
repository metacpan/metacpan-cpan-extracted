/* libpq is not being linked directly and there's no build-time dependency on it.
 * This means we need to manually copy over some definitions from libpq-fe.h
 */

typedef struct PGconn PGconn;
typedef struct PGresult PGresult;
typedef unsigned int Oid;

typedef enum {
    PGRES_EMPTY_QUERY = 0, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_COPY_OUT, PGRES_COPY_IN,
    PGRES_BAD_RESPONSE, PGRES_NONFATAL_ERROR, PGRES_FATAL_ERROR,  PGRES_COPY_BOTH,
    PGRES_SINGLE_TUPLE, PGRES_PIPELINE_SYNC, PGRES_PIPELINE_ABORTED, PGRES_TUPLES_CHUNK
} ExecStatusType;
typedef enum { PQERRORS_TERSE, PQERRORS_DEFAULT, PQERRORS_VERBOSE, PQERRORS_SQLSTATE } PGVerbosity;
typedef enum { PQSHOW_CONTEXT_NEVER, PQSHOW_CONTEXT_ERRORS, PQSHOW_CONTEXT_ALWAYS } PGContextVisibility;
typedef enum { CONNECTION_OK, CONNECTION_BAD } ConnStatusType; /* There's more, but they're irrelevant to us */
typedef enum { PQTRANS_IDLE, PQTRANS_ACTIVE, PQTRANS_INTRANS, PQTRANS_INERROR, PQTRANS_UNKNOWN } PGTransactionStatusType;

#define PG_DIAG_SEVERITY        'S'
#define PG_DIAG_SEVERITY_NONLOCALIZED 'V'
#define PG_DIAG_SQLSTATE        'C'
#define PG_DIAG_MESSAGE_PRIMARY 'M'
#define PG_DIAG_MESSAGE_DETAIL  'D'
#define PG_DIAG_MESSAGE_HINT    'H'
#define PG_DIAG_STATEMENT_POSITION 'P'
#define PG_DIAG_INTERNAL_POSITION 'p'
#define PG_DIAG_INTERNAL_QUERY  'q'
#define PG_DIAG_CONTEXT         'W'
#define PG_DIAG_SCHEMA_NAME     's'
#define PG_DIAG_TABLE_NAME      't'
#define PG_DIAG_COLUMN_NAME     'c'
#define PG_DIAG_DATATYPE_NAME   'd'
#define PG_DIAG_CONSTRAINT_NAME 'n'
#define PG_DIAG_SOURCE_FILE     'F'
#define PG_DIAG_SOURCE_LINE     'L'
#define PG_DIAG_SOURCE_FUNCTION 'R'

#define PG_FUNCS \
    X(PQbinaryTuples, int, const PGresult *) \
    X(PQclear, void, PGresult *) \
    X(PQclosePrepared, PGresult *, PGconn *, const char *) \
    X(PQcmdTuples, char *, PGresult *) \
    X(PQconnectdb, PGconn *, const char *) \
    X(PQenterPipelineMode, int, PGconn *) \
    X(PQerrorMessage, char *, const PGconn *) \
    X(PQescapeIdentifier, char *, PGconn *, const char *, size_t) \
    X(PQescapeLiteral, char *, PGconn *, const char *, size_t) \
    X(PQexec, PGresult *, PGconn *, const char *) \
    X(PQexecParams, PGresult *, PGconn *, const char *, int, const Oid *, const char * const *, const int *, const int *, int) \
    X(PQexecPrepared, PGresult *, PGconn *, const char *, int, const char * const *, const int *, const int *, int) \
    X(PQexitPipelineMode, int, PGconn *conn) \
    X(PQfinish, void, PGconn *) \
    X(PQfmod, int, const PGresult *, int) \
    X(PQfname, char *, const PGresult *, int) \
    X(PQfreemem, void, void *) \
    X(PQftype, Oid, const PGresult *, int) \
    X(PQgetCopyData, int, PGconn *, char **, int) \
    X(PQgetResult, PGresult *, PGconn *) \
    X(PQgetisnull, int, const PGresult *, int, int) \
    X(PQgetlength, int, const PGresult *, int, int) \
    X(PQgetvalue, char *, const PGresult *, int, int) \
    X(PQlibVersion, int, void) \
    X(PQnfields, int, const PGresult *) \
    X(PQnparams, int, const PGresult *) \
    X(PQntuples, int, const PGresult *) \
    X(PQparamtype, Oid, const PGresult *, int) \
    X(PQpipelineSync, int, PGconn *) \
    X(PQputCopyData, int, PGconn *, const char *, int) \
    X(PQputCopyEnd, int, PGconn *, const char *) \
    X(PQresStatus, char *, ExecStatusType) \
    X(PQresultErrorField, char *, const PGresult *, int) \
    X(PQresultErrorMessage, char *, const PGresult *) \
    X(PQresultStatus, ExecStatusType, const PGresult *) \
    X(PQresultVerboseErrorMessage, char *, const PGresult *, PGVerbosity, PGContextVisibility) \
    X(PQsendDescribePrepared, int, PGconn *, const char *) \
    X(PQsendPrepare, int, PGconn *, const char *, const char *, int, const Oid *) \
    X(PQserverVersion, int, const PGconn *) \
    X(PQstatus, ConnStatusType, const PGconn *) \
    X(PQtrace, void, PGconn *, FILE *) \
    X(PQtransactionStatus, PGTransactionStatusType, const PGconn *) \
    X(PQuntrace, void, PGconn *)

#define X(n, r, ...) static r (*n)(__VA_ARGS__);
PG_FUNCS
#undef X

static void fupg_load() {
    void *handle = dlopen("libpq.so", RTLD_LAZY);
    if (!handle) croak("Unable to load libpq: %s", dlerror());
#define X(n, ...) if (!(n = dlsym(handle, #n))) croak("Unable to load libpq: %s", dlerror());
PG_FUNCS
#undef X
}

#undef PG_FUNCS
