#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mysql.h>

#ifndef hv_deletes
# define hv_deletes(hv, key, flags) \
    hv_delete((hv), ("" key ""), (sizeof(key)-1), (flags))
#endif

#define prepare_new_result_accumulator(maria) STMT_START { \
    maria->query_results ? SvREFCNT_dec(maria->query_results) : NULL; \
    maria->query_results = MUTABLE_SV(newAV()); \
} STMT_END

/* newer connector-c releases just have MARIADB_PACKAGE_VERSION_ID which we can use. Yay
 * Otherwise we need to define it. Anti-yay.
 * */
#ifndef MARIADB_PACKAGE_VERSION_ID
#  if defined SERVER_STATUS_IN_TRANS_READONLY
#    define MARIADB_PACKAGE_VERSION_ID 30004
#  elif defined MARIADB_BASE_VERSION
#    define MARIADB_PACKAGE_VERSION_ID 30003
#  elif defined TLS_LIBRARY_VERSION
#    define MARIADB_PACKAGE_VERSION_ID 30002
#  elif defined MYSQL_CLIENT_reserved22
#    define MARIADB_PACKAGE_VERSION_ID 30000
# endif
#endif

#ifdef MARIADB_PACKAGE_VERSION_ID
#  if MARIADB_PACKAGE_VERSION_ID >= 30002
#    define HAVE_SSL_ENFORCE
#  endif
#endif

typedef struct sql_config {
    /* passed to mysql_real_connect(_start) */
    const char* username;
    const char* hostname;
    const char* unix_socket;
    const char* database;
    unsigned int  port;
    unsigned long client_opts;

    /* We may temporarily hold a pointer to the SV that holds the
     * password.
     * If we have auto-reconnect enabled, then this will hold
     * a real SV that we have ownership to, but that is not
     * yet implemented, since it seems like a bad idea to me.
     *
     * Instead, this should never be assigned to normally;
     * rather, it should be temporarily given values via
     * one of Perl's save-and-restore-at-end-of-scope values.
     * Also note that we'll go through some lengths to
     * not needlessly copy the password out of the SV, but more
     * on that later.
     */
    SV* password_temp;

    const char* charset_name;

    /* SSL */
    const char* ssl_key;
    const char* ssl_cert;
    const char* ssl_ca;
    const char* ssl_capath;
    const char* ssl_cipher;
} sql_config;

typedef struct MariaDB_client {
    MYSQL*     mysql;
    MYSQL_RES* res;

    sql_config* config;

    SV* query_results;
    SV* query_sv;

    /* conveniences */
    int socket_fd;
    unsigned long thread_id;

    /* For the state machine */
    bool is_cont;   /* next operation must be a _cont */
    bool run_query;
    int current_state;
    int last_status;

    /* Should we buffer the entire resultset once the query is done,
     * or fetch it row-by-row?
     */
    bool store_query_result;

    /* Ugh... */
    bool want_hashrefs;

    /* DESTROY has been called, we already freed the memory we allocated */
    bool destroyed;
} MariaDB_client;

#define dMARIA MariaDB_client* maria; STMT_START { \
    {\
        MAGIC *mg;\
        if (sv_isobject(self) && SvTYPE(SvRV(self)) == SVt_PVHV && \
            (mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &maria_vtable)) != 0) \
        { maria = (MariaDB_client*) mg->mg_ptr; }\
        else { \
            croak("%"SVf" is not a valid Maria::NonBlocking object", self); \
        } \
    } \
} STMT_END

/* Stolen from http://stackoverflow.com/a/37277144 */
#define NAMES C(DISCONNECTED)C(STANDBY)C(CONNECT)C(QUERY)C(ROW_FETCH)C(FREE_RESULT)C(PING)C(STORE_RESULT)
#define C(x) STATE_##x,
enum color { NAMES STATE_END };
#undef C
#define C(x) #x,
const char * const state_to_name[] = { NAMES };
#undef C

const char* const cont_to_name[] = { "cont", "run_query_cont", "ping_cont", "connect_cont" };

void
THX_free_our_config_items(pTHX_ sql_config* config)
#define free_our_config_items(c) THX_free_our_config_items(aTHX_ c)
{
    Safefree(config->username);
    Safefree(config->hostname);
    Safefree(config->unix_socket);
    Safefree(config->database);
    Safefree(config->charset_name);
    Safefree(config->ssl_key);
    Safefree(config->ssl_cert);
    Safefree(config->ssl_ca);
    Safefree(config->ssl_capath);
    Safefree(config->ssl_cipher);
    return;
}

void
THX_disconnect_generic(pTHX_ MariaDB_client* maria)
#define disconnect_generic(maria) THX_disconnect_generic(aTHX_ maria)
{
    if ( maria->run_query ) {
        SvREFCNT_dec(maria->query_sv);
        maria->query_sv  = NULL;
        maria->run_query = FALSE;
    }

    if ( maria->res ) {
        /* do a best attempt... */
        int status = mysql_free_result_start(maria->res);
        maria->res = NULL; /* memory might leak here if status != 0 */
        if ( status ) {
            /* Damn.  Would've blocked trying to free the result.  Not much we can do */
            croak("Could not free statement handle without blocking.");
        }
    }

    if ( maria->mysql ) {
        mysql_close(maria->mysql);
        Safefree(maria->mysql);
        maria->mysql = NULL;
    }

    maria->is_cont       = FALSE;
    maria->current_state = STATE_DISCONNECTED;

    maria->socket_fd     = -1;

    return;
}

static int
free_mariadb_handle(pTHX_ SV* sv, MAGIC *mg)
{
    MariaDB_client* maria = (MariaDB_client*)mg->mg_ptr;
    sql_config *config;

    if ( !maria || maria->destroyed ) {
        return 0;
    }

    config = maria->config;

    maria->destroyed = 1;

    disconnect_generic(maria);

    /* Free all the config items we may have allocated */
    free_our_config_items(config);

    Safefree(maria->config); /* free the memory we Newxz'd before */
    maria->config = NULL;
    Safefree(maria); /* free the memory we Newxz'd before */
    /* mg will be freed by our caller */
    mg->mg_ptr = NULL;

    return 0;
}

static MGVTBL maria_vtable = { .svt_free = free_mariadb_handle };

const char*
THX_fetch_pv_try_not_to_copy_buffer(pTHX_ SV* password_sv)
#define fetch_pv_try_not_to_copy_buffer(a) \
    THX_fetch_pv_try_not_to_copy_buffer(aTHX_ a)
{
    const char* password = NULL;

    if ( !password_sv || !SvOK(password_sv) ) {
        return NULL;
    }

    if ( SvPOK(password_sv) && !SvGMAGICAL(password_sv) ) {
        /* Er... this is probably a bad assumption on my part.
         * Basically, I'm guessing that SvPOK means we are good
         * to just access the pv buffer directly.
         * This is the ideal situation!
         */
        password = SvPVX_const(password_sv);
    }
    else {
        /* magic and/or weird shit */
        password = SvPV_nolen(password_sv);
    }

    return password;
}

const char*
THX_fetch_password_try_not_to_copy_buffer(pTHX_ MariaDB_client *maria)
#define fetch_password_try_not_to_copy_buffer(a) \
    THX_fetch_password_try_not_to_copy_buffer(aTHX_ a)
{
    return fetch_pv_try_not_to_copy_buffer(maria->config->password_temp);
}

/* Stolen wholesame from DBD::mysql */

enum perl_type {
  PERL_TYPE_UNDEF,
  PERL_TYPE_INTEGER,
  PERL_TYPE_NUMERIC,
  PERL_TYPE_BINARY,
  PERL_TYPE_STRING
};

static enum perl_type mysql_to_perl_type(enum enum_field_types type)
{
    switch (type) {
        case MYSQL_TYPE_NULL:
            return PERL_TYPE_UNDEF;

        case MYSQL_TYPE_TINY:
        case MYSQL_TYPE_SHORT:
        case MYSQL_TYPE_INT24:
        case MYSQL_TYPE_LONG:
#if IVSIZE >= 8
        case MYSQL_TYPE_LONGLONG:
#endif
        case MYSQL_TYPE_YEAR:
            return PERL_TYPE_INTEGER;

        case MYSQL_TYPE_FLOAT:
        #if NVSIZE >= 8
        case MYSQL_TYPE_DOUBLE:
        #endif
            return PERL_TYPE_NUMERIC;

        #if MYSQL_VERSION_ID > NEW_DATATYPE_VERSION
        case MYSQL_TYPE_BIT:
        #endif
        #if MYSQL_VERSION_ID > GEO_DATATYPE_VERSION
        case MYSQL_TYPE_GEOMETRY:
        #endif
        case MYSQL_TYPE_TINY_BLOB:
        case MYSQL_TYPE_BLOB:
        case MYSQL_TYPE_MEDIUM_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
            return PERL_TYPE_BINARY;

        default:
            return PERL_TYPE_STRING;
    }
}

int
THX_add_row_to_results(pTHX_ MariaDB_client *maria, MYSQL_ROW row, bool want_hashref, int field_count, unsigned long *lengths, MYSQL_FIELD *fields)
#define add_row_to_results(a,b,c) THX_add_row_to_results(aTHX_ a,b,c,0,NULL,NULL)
#define add_row_to_results_heavy(a,b,c,d,e,f) THX_add_row_to_results(aTHX_ a,b,c,d,e,f)
{
    AV *query_results;
    SV *row_results;
    SSize_t i = 0;

    if (!maria->query_results) {
        /* we can reach this code if the results are requested
         * whilst we are still gathering rows from the server.
         */
        maria->query_results = MUTABLE_SV(newAV());
    }

    query_results = MUTABLE_AV(maria->query_results);

    if ( !field_count )
        field_count   = mysql_field_count(maria->mysql);

    if ( !fields )
        fields        = mysql_fetch_fields(maria->res);

    if ( !lengths )
        lengths       = mysql_fetch_lengths(maria->res);

    /* we know how many columns the row has, so pre-extend row_results */
    if ( want_hashref ) {
        row_results = MUTABLE_SV(newHV());
    }
    else {
        row_results = MUTABLE_SV(newAV());
        av_extend(MUTABLE_AV(row_results), field_count);
    }

    /* do the push now, in case somehow the av_push inside the loop dies
     * since that way we will avoid leaking the row_results AV
     */
    av_push(query_results, newRV_noinc(row_results));

    for ( i = 0; i < field_count; i++ ) {
        SV *col_data;

        if ( !row[i] ) {
            if ( !want_hashref ) {
                /* if the col is a NULL, then that will already be there,
                 * since we pre-extended the array before.  So avoid doing
                 * that store entirely
                 */
                continue;
            }
            else {
                hv_store(
                    MUTABLE_HV(row_results),
                    fields[i].name,
                    fields[i].name_length,
                    /* CANNOT use &PL_sv_no here!
                     * it leads to errors like:
                     * Modification of non-creatable hash value attempted
                     */
                    newSVsv(&PL_sv_undef),
                    0
                );
                continue;
            }
        }

        col_data = newSVpvn(row[i], (STRLEN)lengths[i]);

        switch (mysql_to_perl_type(fields[i].type)) {
            case PERL_TYPE_NUMERIC:
                if (!(fields[i].flags & ZEROFILL_FLAG)) {
                    /* Coerce to dobule and set scalar as NV */
                    (void)SvNV(col_data);
                    SvNOK_only(col_data);
                }
                break;

            case PERL_TYPE_INTEGER:
                if (!(fields[i].flags & ZEROFILL_FLAG)) {
                    /* Coerce to integer and set scalar as UV resp. IV */
                    if (fields[i].flags & UNSIGNED_FLAG) {
                        (void)SvUV(col_data);
                        SvIOK_only_UV(col_data);
                    }
                    else {
                        (void)SvIV(col_data);
                        SvIOK_only(col_data);
                    }
                }
                break;

            case PERL_TYPE_UNDEF:
                /* Field is NULL, return undef */
                (void)SvOK_off(col_data);
                break;

            default:
                break;
        }

        /* ownership of the col_data refcount goes to row_results */
        if ( want_hashref ) {
            hv_store(
                MUTABLE_HV(row_results),
                fields[i].name,
                fields[i].name_length,
                col_data,
                0
            );
        }
        else {
            av_store(MUTABLE_AV(row_results), i, col_data);
        }
    }

    return 1;
}

#define store_in_self(pv, sv) hv_stores(MUTABLE_HV(SvRV(self)),pv,sv)

void
THX_usual_post_connect_shenanigans(pTHX_ SV* self)
#define usual_post_connect_shenanigans(s) \
    THX_usual_post_connect_shenanigans(aTHX_ s)
{
    dMARIA;

    maria->is_cont         = FALSE;
    maria->current_state   = STATE_STANDBY;

    /* Grab socket_fd outside. */
    maria->thread_id = mysql_thread_id(maria->mysql);
    (void)store_in_self(
        "mysql_thread_id",
        newSVnv(maria->thread_id)
    );

    return;
}

#define maybe_init_mysql_connection(mysql) STMT_START {           \
    if ( !mysql ) {                                               \
        my_bool reconnect = 0;                                    \
        Newxz(mysql, 1, MYSQL);                                   \
        mysql_init(mysql);                                        \
        mysql_options(mysql, MYSQL_OPT_NONBLOCK, 0);              \
        mysql_options(mysql, MYSQL_OPT_RECONNECT, &reconnect);    \
    }                                                             \
} STMT_END


int
THX_do_work(pTHX_ SV* self, IV event)
#define do_work(self, event) THX_do_work(aTHX_ self, event)
{
    dMARIA;
    int err             = 0;
    int status          = 0;
    int state           = maria->current_state;
    int state_for_error = STATE_STANDBY; /* query errors */
    sql_config *config   = maria->config;
    const char* errstring = NULL;

#define have_password_in_memory(maria) (maria && maria->config && maria->config->password_temp && SvOK(maria->config->password_temp))

    while ( 1 ) {
        if ( err )
            break;

        if ( status )
            break;

        if ( state == STATE_STANDBY && !maria->run_query )
            break;

        if ( state == STATE_DISCONNECTED && !have_password_in_memory(maria) ) {
            break;
        }

        /*warn("<%d><%s><%d>\n", maria->socket_fd, state_to_name[maria->current_state], maria->is_cont);*/
        switch ( state ) {
            case STATE_STANDBY:
                if ( maria->run_query ) {
                    /* we have a query sv saved, so go ahead and run it! */
                    state = STATE_QUERY;
                }
                /* Otherwise, the loop will just end */
                break;
            case STATE_DISCONNECTED:
                /* If we still have the password around, then we can try
                 * connecting -- otherwise, time to end this suffering.
                 */
                if ( have_password_in_memory(maria) ) {
                    state = STATE_CONNECT;
                }
                else {
                    if ( maria->run_query ) {
                        err       = 1;
                        errstring = "Disconnected and no password in memory to reconnect, nothing to do!";
                    }
                }
                break;
            case STATE_CONNECT:
            {
                MYSQL *mysql_ret = 0;
                if ( !maria->is_cont ) {
                    const char *password =
                        fetch_password_try_not_to_copy_buffer(maria);

                    if ( !password ) {
                        err       = 1;
                        errstring = "No password in memory during ->connect! If check that the password was passed in and was defined.";
                        break;
                    }

                    status = mysql_real_connect_start(
                                 &mysql_ret,
                                 maria->mysql,
                                 maria->config->hostname,
                                 maria->config->username,
                                 password,
                                 maria->config->database,
                                 maria->config->port,
                                 maria->config->unix_socket,
                                 /* XXX TODO: CLIENT_REMEMBER_OPTIONS
                                  * without it, a connect_cont following
                                  * an error -- like a bad password --
                                  * will cause segfaults, presumably because
                                  * the connection won't have the async
                                  * context set.
                                  */
                                 CLIENT_REMEMBER_OPTIONS
                                    |
                                 maria->config->client_opts
                            );
                    maria->socket_fd = mysql_get_socket(maria->mysql);
                    (void)store_in_self(
                        "mysql_socket_fd",
                        newSViv(maria->socket_fd)
                    );
                }
                else {
                    status = mysql_real_connect_cont(
                                &mysql_ret,
                                maria->mysql,
                                event
                             );
                    event = 0;
                }

                if (mysql_errno(maria->mysql) > 0) {
                    maria->is_cont  = FALSE;
                    err             = 1;
                    errstring       = mysql_error(maria->mysql);
                    state_for_error = STATE_DISCONNECTED;
                    break;
                }

                if ( status ) {
                    /* need to wait and call _cont */
                    /* TODO mysql_errno here? */
                    maria->is_cont = TRUE;
                }
                else {
                    /* connected! */
                    usual_post_connect_shenanigans(self);
                    state = STATE_STANDBY;
                }
                break;
            }
            case STATE_QUERY:
                if ( maria->is_cont ) {
                    status = mysql_real_query_cont(&err, maria->mysql, event);
                    event = 0;
                }
                else {
                    STRLEN query_len;
                    char* query_pv = SvPV(maria->query_sv, query_len);
                    status = mysql_real_query_start(
                                &err,
                                maria->mysql,
                                query_pv,
                                query_len
                             );
                }

                if ( err ) {
                    /* Probably should do more here, like resetting the state */
                    maria->is_cont = FALSE;
                    state          = STATE_STANDBY;

                    maria->run_query = FALSE;

                    errstring = mysql_error(maria->mysql);
                }
                else if ( status ) {
                    maria->is_cont = TRUE; /* need to wait on the socket */
                }
                else {
                    /* query finished */
                    maria->is_cont = FALSE; /* hooray! */

                    /* finally, release the query string */
                    maria->run_query = FALSE;

                    if ( maria->store_query_result ) {
                        state = STATE_STORE_RESULT;
                    }
                    else {
                        maria->res     = mysql_use_result(maria->mysql);

                        if ( maria->res ) {
                            /* query returned and we have results,
                             * start fetching!
                             */
                            state = STATE_ROW_FETCH;
                        }
                        else if ( mysql_field_count(maria->mysql) == 0 ) {
                            /* query succeeded but returned no data */
                            /* TODO might want to store affected rows? */
                            /*rows = mysql_affected_rows(maria->mysql);*/
                            /*prepare_new_result_accumulator(maria);*/ /* empty results */
                            state = STATE_STANDBY;
                        }
                        else {
                            /* Error! */
                            err       = 1;
                            errstring = mysql_error(maria->mysql);
                            /* maria->res is NULL if we get here, so no need
                             * to go and free that
                             */
                            state  = STATE_STANDBY;
                        }
                    }
                }
                break;
            case STATE_STORE_RESULT:
                if ( maria->is_cont ) {
                    status = mysql_store_result_cont(&(maria->res), maria->mysql, event);
                    event  = 0;
                }
                else {
                    status = mysql_store_result_start(&(maria->res), maria->mysql);
                }

                if ( status ) {
                    maria->is_cont = TRUE;
                }
                else {
                    /* we are done getting the results! */
                    maria->is_cont = FALSE;
                    if ( mysql_errno(maria->mysql) > 0 ) {
                        err       = 1;
                        errstring = mysql_error(maria->mysql);
                    }
                    else {
                        if ( !maria->res ) {
                            /* query was successful but returned nothing */
                            /* if mysql_affected_rows(maria->mysql) returns
                               something interesting, that's our output
                             */
                            UV affected_rows = mysql_affected_rows(maria->mysql);
                            if ( affected_rows ) {
                                if (!maria->query_results) {
                                    maria->query_results = MUTABLE_SV(newAV());
                                }
                                av_push(MUTABLE_AV(maria->query_results), newSVuv( affected_rows ));
                            }
                        }
                        else if ( mysql_field_count(maria->mysql) == 0 ) {
                            /* same */
                        }
                        else {
                            /* query was successful and we have all the results in memory.  Put them in perl! */
                            MYSQL_FIELD *fields
                                = mysql_fetch_fields(maria->res);

                            int field_count
                                = mysql_field_count(maria->mysql);

                            unsigned long *lengths
                                = mysql_fetch_lengths(maria->res);

                            while (1) {
                                /* this will never block */
                                MYSQL_ROW row = mysql_fetch_row(maria->res);
                                if ( !row )
                                    break;

                                add_row_to_results_heavy(
                                    maria,
                                    row,
                                    maria->want_hashrefs,
                                    field_count,
                                    lengths,
                                    fields
                                );
                            }
                        }
                    }
                    maria->want_hashrefs = FALSE;
                    state = STATE_FREE_RESULT;
                }

                break;
            case STATE_FREE_RESULT:
                if ( maria->is_cont ) {
                    status = mysql_free_result_cont(maria->res, event);
                    event = 0;
                }
                else {
                    status = mysql_free_result_start(maria->res);
                }

                if (!status) {
                    /* freed the result */
                    maria->res     = NULL;
                    maria->is_cont = FALSE;
                    state = STATE_STANDBY; /* back to standby! */
                }
                else {
                    maria->is_cont = TRUE;
                }
                break;
            case STATE_ROW_FETCH:
            {
                MYSQL_ROW row = 0;
                if ( maria->is_cont ) {
                    status = mysql_fetch_row_cont(&row, maria->res, event);
                    event  = 0;
                    if (!status) {
                        if ( row ) {
                            add_row_to_results(maria, row, maria->want_hashrefs);
                        }
                        else {
                            if ( mysql_errno(maria->mysql) > 0 ) {
                                err       = 1;
                                errstring = mysql_error(maria->mysql);
                            }
                            state = STATE_FREE_RESULT;
                        }
                        maria->is_cont = FALSE;
                    }
                }
                else {
                    do {
			            row    = 0;
                        status = mysql_fetch_row_start(&row, maria->res);
                        if (!status) {
                            if ( row ) {
                                add_row_to_results(maria, row, maria->want_hashrefs);
                            }
                            else if ( mysql_errno(maria->mysql) > 0 ) {
                                /* Damn... We got an error while fetching
                                 * the rows.  Need to free the resultset
                                 */
                                err       = 1;
                                errstring = mysql_error(maria->mysql);
                                state     = STATE_FREE_RESULT;
                            }
                        }
                    } while (!status && row);

                    if ( status ) {
                        /* TODO: can mysql_errno() be > 0 here? Do we need to check? */
                        maria->is_cont = TRUE; /* need to wait on the socket */
                    }
                    else if (!row) {
                        /* all rows read, so free the result
                         * docs say we could use mysql_free_result
                         * and it should not block, but I'm having none of it.
                         */
                        maria->want_hashrefs = FALSE;
                        state = STATE_FREE_RESULT;
                    }
                    /*
                        else, strangely enough, we need to call ourselves again
                    */
                }
                break;
            }
            case STATE_PING:
            {
                int ret;
                if ( maria->is_cont ) {
                    status = mysql_ping_cont(&ret, maria->mysql, event);
                    event  = 0;
                }
                else {
                    status = mysql_ping_start(&ret, maria->mysql);
                }

                if ( status ) {
                    maria->is_cont = TRUE;
                }
                else {
                    /* Ping finished! */
                    maria->is_cont       = FALSE;
                    state                = STATE_STANDBY;

                    if ( ret ) {
                        const char* ping_error = mysql_error(maria->mysql);
                        maria->query_results = newSVpvn( ping_error, strlen(ping_error) );
                    }
                    else {
                        maria->query_results = &PL_sv_no;
                    }
                }
                break;
            }
            default:
                err       = 1;
                errstring = "Should never happen! Invalid state";
        } /* end of switch (state) */
    }

    /*
     * We croak outside of the while, to give it a chance
     * to free the result
     */

    if ( err ) {
        maria->is_cont       = FALSE;
        maria->current_state = state_for_error;
        maria->last_status   = 0;

        if ( maria->run_query ) {
            maria->run_query = FALSE;
        }

        if (!errstring)
            errstring = "Unknown MySQL error";
        croak("%s", errstring);
    }

    maria->current_state = state;
    maria->last_status   = status;

    return status;
}

SV*
THX_quote_sv(pTHX_ MariaDB_client* maria, SV* to_be_quoted)
#define quote_sv(to_be_quoted) THX_quote_sv(aTHX_ maria, to_be_quoted)
{
    UV new_length;
    STRLEN new_len_needed;
    STRLEN to_be_quoted_len;
    char * escaped_buffer;
    const char* to_be_quoted_pv;
    SV *quoted_sv;

    if ( !SvOK(to_be_quoted) ) {
        return newSVpvs("NULL");
    }

    to_be_quoted_pv = SvPV(to_be_quoted, to_be_quoted_len);

    if ( to_be_quoted_len == 0 ) {
        return newSVpvs("\"\""); /* "", not '', not sure why */
    }

    if ( (to_be_quoted_len+3) > (MEM_SIZE_MAX/2) ) {
        croak("Cannot quote absurdly long string, would cause an overflow");
    }

    /* mysql_real_escape_string needs len of string*2 plus one byte for the null */
    /* we mimick DBI behavior and return this with quotes */
    new_len_needed = to_be_quoted_len * 2 + 3;

    quoted_sv      = newSV(new_len_needed);
    escaped_buffer = SvPVX_mutable(quoted_sv);
    escaped_buffer[0] = '\'';

    SvPOK_on(quoted_sv);

    new_length = mysql_real_escape_string(
        maria->mysql,
        escaped_buffer+1,
        to_be_quoted_pv,
        to_be_quoted_len
    );
    escaped_buffer[new_length+1] = '\'';

    escaped_buffer[new_length+2] = '\0';
    SvCUR_set(quoted_sv, (STRLEN)new_length + 2);
    if ( SvUTF8(to_be_quoted) )
        SvUTF8_on(quoted_sv);

    return quoted_sv;
}

const char*
THX_easy_arg_fetch(pTHX_ HV *hv, char * pv, STRLEN pv_len, bool required)
#define easy_arg_fetch(hv, s, b) THX_easy_arg_fetch(aTHX_ hv, s, sizeof(s)-1, b)
{
    SV** svp;
    const char *res = NULL;

    if ((svp = hv_fetch(hv, pv, pv_len, FALSE))) {
        if ( SvOK(*svp) ) {
            STRLEN len;
            res = SvPV_const(*svp, len);
        }
        /* it can stay NULL for undef */
    }
    else if ( required ) {
        croak("No %s given to ->connect / ->connect_start!", pv);
    }
    return res;
}

/* TODO should be called positive integer */
void
THX_mysql_opt_integer(pTHX_ MariaDB_client* maria, HV* hv, const char* str, STRLEN str_len, enum mysql_option option )
#define mysql_opt_integer(m, h, s, o) \
    THX_mysql_opt_integer(aTHX_ m, h, s, sizeof(s)-1, o)
{
    int value;
    SV** svp = hv_fetch(hv, str, str_len, FALSE);

    if ( !svp || !*svp || !SvOK(*svp) )
        return;

    value = SvIV(*svp);
    if ( value ) /* huh... */
        mysql_options(
            maria->mysql,
            option,
            (const char*)&value
        );

    return;
}

void
THX_unpack_config_from_hashref(pTHX_ SV* self, HV* args)
#define unpack_config_from_hashref(a,b) THX_unpack_config_from_hashref(aTHX_ a,b)
{
    SV** svp;
    dMARIA;
    sql_config *config = maria->config;

    /*
        With this code:
            $maria->connect({user => "foo"});
            $maria->disconnect;
            $maria->connect({user => "bar"});
        If we don't clear config items, we could end up
        with a mix of both configs.  And if we don't free
        them, we leak memory.
    */
    free_our_config_items(config);

    config->hostname     = savepv(easy_arg_fetch(args, "host",        TRUE));
    config->username     = savepv(easy_arg_fetch(args, "user",        TRUE));
    config->database     = savepv(easy_arg_fetch(args, "database",    FALSE));
    config->unix_socket  = savepv(easy_arg_fetch(args, "unix_socket", FALSE));

    config->charset_name = savepv(easy_arg_fetch(args, "charset", FALSE));

#define FETCH_FROM_HV(s) \
    ((svp = hv_fetch(args, s, sizeof(s)-1, FALSE)) && *svp && SvOK(*svp))

    config->port = FETCH_FROM_HV("port") ? SvIV(*svp) : 0;

    maria->store_query_result = FETCH_FROM_HV("mysql_use_results")
                                    ? cBOOL(SvTRUE(*svp) ? FALSE : TRUE)
                                    : TRUE;

    /* TODO: DBD::mysql compat mysql_enable_utf8 / mysql_enable_utf8mb4 */
    if ( config->charset_name && strlen(config->charset_name) )
        mysql_options(
            maria->mysql,
            MYSQL_SET_CHARSET_NAME,
            config->charset_name
        );

    if ( config->unix_socket && strlen(config->unix_socket) ) {
        const int xxx = MYSQL_PROTOCOL_SOCKET;
        mysql_options(
            maria->mysql,
            MYSQL_OPT_PROTOCOL,
            &xxx
        );
    }

    /* Going to follow DBD::mysql's naming scheme for these */

    if ( FETCH_FROM_HV("mysql_init_command") && SvTRUE(*svp) ) {
        const char* init_command = SvPV_nolen_const(*svp);
        mysql_options(
            maria->mysql,
            MYSQL_INIT_COMMAND,
            init_command
        );
    }

    if ( FETCH_FROM_HV("mysql_compression") ) {
        mysql_options(
            maria->mysql,
            MYSQL_OPT_COMPRESS,
            NULL /* unused */
        );
    }


#define my_mysql_opt_integer(a,b) mysql_opt_integer(maria, args, a, b)

    my_mysql_opt_integer("mysql_connect_timeout", MYSQL_OPT_CONNECT_TIMEOUT);
    my_mysql_opt_integer("mysql_write_timeout", MYSQL_OPT_WRITE_TIMEOUT);
    my_mysql_opt_integer("mysql_read_timeout", MYSQL_OPT_READ_TIMEOUT);

#undef my_mysql_opt_integer

    if ( FETCH_FROM_HV("ssl") ) {
        my_bool ssl_verify  = 0;
        my_bool ssl_enforce = 1;
        bool use_default_ciphers    = TRUE;
        HV *ssl;

        if ( !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV ) {
            /* TODO != SVt_PVHV? Do you even magic?? */
            croak("ssl argument should point to a hashref");
        }
        else {
            ssl = MUTABLE_HV(SvRV(*svp));
        }

#define ssl_config_set(s) STMT_START {                           \
    const char *tmp = easy_arg_fetch(ssl, #s, FALSE);            \
    config->ssl_##s = tmp ? savepv(tmp) : NULL;    \
} STMT_END

        ssl_config_set(key);
        ssl_config_set(cert);
        ssl_config_set(ca);
        ssl_config_set(capath);
        ssl_config_set(cipher);

        if ( config->ssl_cipher && strlen(config->ssl_cipher) ) {
            use_default_ciphers = FALSE;
        }

        if ( (svp = hv_fetchs(ssl, "optional", FALSE)) && *svp )
            ssl_enforce = !SvTRUE(*svp);

        if ((svp = hv_fetchs(ssl, "verify_server_cert", FALSE)) && *svp) {
            ssl_verify = SvTRUE(*svp);
        }

#ifdef HAVE_SSL_ENFORCE
        if (mysql_options(maria->mysql, MYSQL_OPT_SSL_ENFORCE, &ssl_enforce) != 0) {
            croak("Enforcing SSL encryption is not supported");
        }
#else
        /* Try this instead... */
        ssl_verify = 1;
#endif

        if ( ssl_verify && mysql_options(maria->mysql, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &ssl_verify) != 0 ) {
            croak("verify_server_cert=1 (or optional=0 in a version without MYSQL_OPT_SSL_ENFORCE) is not supported");
        }

        mysql_ssl_set(
            maria->mysql,
            config->ssl_key,
            config->ssl_cert,
            config->ssl_ca,
            config->ssl_capath,
            use_default_ciphers ? NULL : config->ssl_cipher
        );
    }

#undef FETCH_FROM_HV

}

MODULE = MariaDB::NonBlocking PACKAGE = MariaDB::NonBlocking

PROTOTYPES: DISABLE

BOOT:
{
    /* On boot, let's create a couple of constants for
     * perl to use
     */
    HV *stash = gv_stashpvs("MariaDB::NonBlocking", GV_ADD);

    CV *wait_read_cv    = newCONSTSUB(stash, "MYSQL_WAIT_READ", newSViv(MYSQL_WAIT_READ));

    CV *wait_write_cv   = newCONSTSUB(stash, "MYSQL_WAIT_WRITE", newSViv(MYSQL_WAIT_WRITE));

    CV *wait_except_cv  = newCONSTSUB(stash, "MYSQL_WAIT_EXCEPT", newSViv(MYSQL_WAIT_EXCEPT));

    CV *wait_timeout_cv = newCONSTSUB(stash, "MYSQL_WAIT_TIMEOUT", newSViv(MYSQL_WAIT_TIMEOUT));

    PERL_UNUSED_VAR(wait_read_cv);
    PERL_UNUSED_VAR(wait_write_cv);
    PERL_UNUSED_VAR(wait_except_cv);
    PERL_UNUSED_VAR(wait_timeout_cv);
}

SV*
init(SV* classname)
CODE:
{
    SV* self;

    MariaDB_client *maria;
    sql_config *config;
    Newxz(maria, 1, MariaDB_client);
    Newxz(config, 1, sql_config);

    maria->config        = config;
    maria->query_results = NULL;
    maria->current_state = STATE_DISCONNECTED;
    maria->socket_fd     = -1;
    maria->thread_id     = -1;
    maria->store_query_result = TRUE;
    maria->query_sv      = newSV(0);
    SvUPGRADE(maria->query_sv, SVt_PV);
    SvPOK_on(maria->query_sv);

    maybe_init_mysql_connection(maria->mysql);

    /* create a reference to a hash, bless into $classname, then add the
     * magic we need
     */
    RETVAL = newRV_noinc(MUTABLE_SV(newHV()));
    sv_bless(RETVAL, gv_stashsv(classname, GV_ADD));
    sv_magicext(
        SvRV(RETVAL),
        SvRV(RETVAL),
        PERL_MAGIC_ext,
        &maria_vtable,
        (char*) maria,
        0
    );
}
OUTPUT: RETVAL

int
mysql_socket_fd(SV* self)
CODE:
    dMARIA;
    RETVAL = maria->socket_fd;
OUTPUT: RETVAL

IV
mysql_warning_count(SV* self)
CODE:
    dMARIA;
    RETVAL = mysql_warning_count(maria->mysql);
OUTPUT: RETVAL

IV
connect_start(SV* self, HV* args)
CODE:
{
    HV *inner_self  = MUTABLE_HV(SvRV(self));
    SV **svp        = hv_fetchs(args, "password", FALSE);

    dMARIA;

	if (!svp || !*svp)
	    croak("No password given to ->connect_start");

    if ( maria->current_state != STATE_DISCONNECTED )
        croak("Cannot call connect_start because the current internal state says we are on %s but we need to be in %s", state_to_name[maria->current_state], state_to_name[STATE_DISCONNECTED]);

    /* might be uninitialized due to a previous disconnect */
    maybe_init_mysql_connection(maria->mysql);
    unpack_config_from_hashref(self, args);

    /*
       What follows is the equivalent of
         local $self->{config}{password} = $args->{password};
       We do this so that the password PV is never copied anywhere;
       we later get it out of the string with SvPVX (if possible)
       and pass that directly to MySQL.
    */

    SAVEGENERICSV(maria->config->password_temp);
    maria->config->password_temp = SvREFCNT_inc(*svp);

    RETVAL = do_work(self, 0);
}
OUTPUT: RETVAL

IV
ping_start(SV* self)
CODE:
{
    dMARIA;

    RETVAL = 0;
    if ( maria->current_state == STATE_DISCONNECTED ) {
        maria->query_results = newSVpvs("Not connected to MySQL, automatically failed ping");
    }
    else if ( maria->current_state != STATE_STANDBY || maria->is_cont ) {
        croak("Cannot ping an active connection!!"); /* TODO moar info */
    }
    else if ( maria->run_query ) {
        croak("Cannot ping when we have a query queued to be run");
    }
    else {
        maria->current_state = STATE_PING;
        RETVAL = do_work(self, 0);
    }
}
OUTPUT: RETVAL

SV*
ping_result(SV* self)
CODE:
{
    dMARIA;
    if ( maria->is_cont )
        croak("Cannot get the results of the ping, because we are still waiting on the server to respond!");

    RETVAL               = maria->query_results;
    maria->query_results = NULL;
}
OUTPUT: RETVAL

IV
run_query_start(SV* self, SV * query, ...)
CODE:
{
    dMARIA;

    /* TODO would be pretty simple to implement a pipeline here... */
    if ( maria->run_query )
        croak("Attempted to start a query when this connection already has a query in flight");

    if ( !SvOK(query) )
        croak("Query was empty");

    if ( maria->current_state == STATE_QUERY ) {
        /*
         * How we get here:
         *  $maria->run_query_start("select 1");
         *  $maria->run_query_start("select 2");
         * This is a no-go, and usually happens when a
         * handle is used from multiple places.
         */
        croak("Cannot start running a second query while we are still completing the first!");
    }

    if (
        maria->current_state == STATE_DISCONNECTED
            &&
        !have_password_in_memory(maria)
    ) {
        croak("Cannot start query; not connected");
    }

    maria->want_hashrefs = FALSE;
    if ( items > 2 && SvOK(ST(2)) ) {
        /* we were given arguments */
        SV *arg = ST(2);
        SV **svp;
        if ( !SvROK(arg) || SvTYPE(SvRV(ST(2))) != SVt_PVHV ) {
            croak("Invalid (non-hash, non-undef) argument given to run_query");
        }
        svp  = hv_fetchs(MUTABLE_HV(SvRV(arg)), "want_hashrefs", FALSE);
        if ( svp && *svp ) {
            maria->want_hashrefs = cBOOL(SvTRUE(*svp));
        }
    }

    if ( !maria->query_sv ) {
        maria->query_sv = newSV(0);
        SvUPGRADE(maria->query_sv, SVt_PV);
        SvPOK_on(maria->query_sv);
    }

    /* TODO implement prepared statements, then check if we have one here */
    if ( items > 3 && SvOK(ST(3)) ) {
        /* we were given query params.  Hm. Need to copy the query sv,
         * then replace all the placeholders
         */
        SV* bind = ST(3);
        AV* bind_av;
        bool escaped;
        SV* query_with_params = maria->query_sv;
        bool need_utf8_on               = cBOOL(SvUTF8(query));
        STRLEN max_size_of_query_string;
        const char* query_pv            = SvPV(query, max_size_of_query_string);
        char *d = NULL;
        IV num_bind_params;

        if ( max_size_of_query_string == 0 )
            croak("Query was empty");

        if ( !SvROK(bind) || SvTYPE(SvRV(bind)) != SVt_PVAV ) {
            croak("Query bind values should be passed in an arrayref!");
        }
        bind_av = MUTABLE_AV(SvRV(bind));
        num_bind_params = av_len(bind_av) + 1;

        IV i = 0;
        for ( ; i < num_bind_params; i++ ) {
            SV* query_param = *av_fetch(bind_av, i, FALSE);

            if ( !SvOK(query_param) ) {
                /* will add a NULL, so +4 */
                max_size_of_query_string += 4;
                continue;
            }

            if ( SvGMAGICAL(query_param) ) /* get GET magic */
                mg_get(query_param);

            if ( SvUTF8(query_param) )
                need_utf8_on = TRUE;

            /* need to account for the increase due to quoting */
            max_size_of_query_string += sv_len(query_param)*2+1; /* should be +2, but we are replacing a question mark so */
        }

        SvGROW(query_with_params, max_size_of_query_string);
        if ( need_utf8_on ) {
            SvUTF8_on(query_with_params);
        }
        else {
            SvUTF8_off(query_with_params);
        }

        d = SvPVX(query_with_params);
        i = 0; /* back to the start */
        while ( *query_pv ) {
            if ( *query_pv == '?' && !escaped ) {
                UV new_length = 0;
                STRLEN to_be_quoted_len;
                const char* to_be_quoted_pv;
                SV *to_be_quoted;
                bool upgraded = FALSE;

                query_pv++;

                if ( i >= num_bind_params )
                    croak("Not enough bind params given to run_query");

                to_be_quoted = *av_fetch(bind_av, i++, FALSE);

                if ( !SvOK(to_be_quoted) ) {
                    *d++ = 'N';
                    *d++ = 'U';
                    *d++ = 'L';
                    *d++ = 'L';
                    continue;
                }

                if ( need_utf8_on && !SvUTF8(to_be_quoted) ) {
                    /* temporarily upgrade to utf8 -- we will downgrade later */
                    sv_utf8_upgrade_nomg(to_be_quoted);
                    upgraded = TRUE;
                }

                to_be_quoted_pv = SvPV(to_be_quoted, to_be_quoted_len);

                if ( to_be_quoted_len == 0 ) {
                    *d++ = '"';
                    *d++ = '"';
                    continue;
                }

                *d++ = '\'';
                new_length = mysql_real_escape_string(
                    maria->mysql,
                    d,
                    to_be_quoted_pv,
                    to_be_quoted_len
                );
                d += new_length;
                *d++ = '\'';

                if ( upgraded ) {
                    sv_utf8_downgrade(to_be_quoted, 1); /* 1=FAIL_OK */
                }
            }
            else if ( *query_pv == '\\' && !escaped ) {
                escaped = TRUE;
                query_pv++;
            }
            else {
                escaped = FALSE;
                *d++ = *query_pv++;
            }
        }

        SvCUR_set(
            query_with_params,
            (STRLEN)(d - SvPVX(query_with_params))
        );

        *d++ = '\0'; /* never hurts to have a NUL terminated string */

        if ( i != num_bind_params ) {
            croak("Too many bind params given for query! Got %"IVdf", query needed %"IVdf, num_bind_params, i);
        }
    }
    else {
        /* we MUST copy this, because mysql_real_query will not -- it will
         * hold on to the pointer until it is done sending the query
         * */
        sv_setsv(maria->query_sv, query);
    }
    maria->run_query = TRUE;

    if ( maria->is_cont ) {
        /*
         * Easy way to get here:
         *      $maria->connect_start(...);
         *      $maria->run_query_start(...);
         * So we started connecting, and immediately queued up
         * a query.  That's fine.
         * However, we really should not go into the state machine,
         * because it will be called with event=0, meaning it will
         * do a poll() on the socket, waiting for the
         * response of the connect, which unless we are connecting
         * to localhost, it's just not going to happen.
         * So avoid all of that and return immediately, and tell
         * our caller to wait on what connect_start returned before.
         */
        RETVAL = maria->last_status;
    }
    else {
        RETVAL = do_work(self, 0);
    }
}
OUTPUT: RETVAL

const char*
current_state(SV* self)
CODE:
{
    dMARIA;
    RETVAL = state_to_name[maria->current_state];
}
OUTPUT: RETVAL

IV
cont(SV* self, ...)
ALIAS:
    run_query_cont = 1
    ping_cont      = 2
    connect_cont   = 3
CODE:
{
    dMARIA;
    IV event = 0;

    if ( !maria->is_cont ) {
        croak("Calling ->%s, but we are not currently waiting for the server. Current state is %s", cont_to_name[ix], state_to_name[maria->current_state]);
    }

    /*
     * If we have more than one item, it should be the event(s) that
     * happened since we were last called -- e.g. the read event on
     * the socket.  If not passed in, the library will poll() on
     * the socket.
     */
    if ( items > 1 ) {
        if ( ST(1) == self )
            croak("Called $self->%s($self), that is just wrong", cont_to_name[ix]);
        event = SvIV(ST(1));
    }

    RETVAL = do_work(self, event);
}
OUTPUT: RETVAL

SV*
query_results(SV* self)
CODE:
    dMARIA;
    RETVAL = newRV_noinc(maria->query_results ? maria->query_results : MUTABLE_SV(newAV())); /* newRV_noinc will take ownership of the refcount */
    maria->query_results = NULL;
OUTPUT: RETVAL

UV
get_timeout_value_ms(SV* self)
CODE:
    dMARIA;
    RETVAL = mysql_get_timeout_value_ms(maria->mysql);
OUTPUT: RETVAL

NV
insert_id(SV* self)
CODE:
    dMARIA;
    RETVAL = mysql_insert_id(maria->mysql);
OUTPUT: RETVAL

SV*
quote(SV* self, SV* to_be_quoted)
CODE:
{
    dMARIA;
    RETVAL = quote_sv(to_be_quoted);
}
OUTPUT: RETVAL

#define SQL_IDENTIFIER_QUOTE_CHAR '`'

SV*
quote_identifier(SV *self, ...)
CODE:
{
    IV utf8_sv_count         = 0;
    STRLEN retval_actual_len = 0;
    STRLEN max_retval_len    = 0;
    char *d        = NULL; /* dESTINATION */
    IV i           = 0;
    IV items_start = 1; /* 0 is $self */
    IV items_end   = items;

    /* TODO ansiquotes */

    if ( items > 3 && SvROK(ST(items)) ) {
        /* final item is an attr, ignore it */
        items_end--;
    }

    /* We will do two passes -- one to find out how large a
     * RETVAL we need to allocate, and then the second where we fill it.
     */

    for (i = items_start; i < items_end; i++ ) {
        SV *identifier = ST(i);

        if ( SvGMAGICAL(identifier) ) /* get GET magic */
            mg_get(identifier);

        if ( SvOK(identifier) ) {
            max_retval_len += sv_len(identifier) + 2;

            if ( SvUTF8(identifier) ) {
                utf8_sv_count++;
            }
        }
    }

    if ( utf8_sv_count != 0 && utf8_sv_count != items ) {
        /* Worst possible situation: we have a mix of UTF8 and non-UTF8
         * identifiers; e.g. something like ("abc", "dèf", "ネ")
         * So we need to assume the worst case scenario, where we
         * must upgrade everything from latin1 to UTF-8, doubling
         * the max_retval_len
         */
         max_retval_len = max_retval_len * 2;
    }

    /* Now we have to assume that the entire string will be quoted */
    /* overflow check etc */
    /* ``\0 is the smallest, so +3 -- and we need a connecting . per item
     */
     /* TODO off by one, should be items-2, but items can be 1 if
      * $self->quote_identifier is called and I don't feel like adding the
      * if, instead I am writing this comment which is far more work.
      */
    max_retval_len = (max_retval_len*2) + 3 + items-1;

    RETVAL = newSV(max_retval_len);
    SvUPGRADE(RETVAL, SVt_PV);
    SvPOK_on(RETVAL);

    if ( utf8_sv_count )
        SvUTF8_on(RETVAL);

    d = SvPVX(RETVAL);

    for ( i = items_start; i < items_end; i++ ) {
        SV *identifier = ST(i);
        STRLEN identifier_len;
        const char * identifier_pv;
        bool upgraded = FALSE;

        if ( !SvOK(identifier) ) {
            /* undef! */
            continue;
        }

        if ( utf8_sv_count && !SvUTF8(identifier) ) {
            sv_utf8_upgrade_nomg(identifier);
            upgraded = TRUE;
        }

        /* _nomg since we already did the mg_get() before */
        identifier_pv = SvPV_nomg(identifier, identifier_len);

        retval_actual_len = retval_actual_len + identifier_len;

        *d++ = SQL_IDENTIFIER_QUOTE_CHAR;
	    while ( identifier_len-- ) {
		    if ( *identifier_pv == SQL_IDENTIFIER_QUOTE_CHAR ) {
		        retval_actual_len++;
		        *d++ = SQL_IDENTIFIER_QUOTE_CHAR;
		    }
		    *d++ = *identifier_pv++;
	    }
        *d++ = SQL_IDENTIFIER_QUOTE_CHAR;
		retval_actual_len += 2;

        if ( (i+1) != items_end ) {
            /* not the last elem */
            *d++ = '.';
		    retval_actual_len++;
        }

        if ( upgraded ) {
            sv_utf8_downgrade(identifier, 1); /* 1=FAIL_OK */
        }
    }

    if ( d == SvPVX(RETVAL) ) { /* no identifiers provided */
        *d++ = SQL_IDENTIFIER_QUOTE_CHAR;
        *d++ = SQL_IDENTIFIER_QUOTE_CHAR;
        retval_actual_len += 2;
    }
    *d++ = '\0';
    SvCUR_set(RETVAL, (STRLEN)retval_actual_len);
}
OUTPUT: RETVAL

void
disconnect(SV* self)
CODE:
    dMARIA;
    disconnect_generic(maria);

