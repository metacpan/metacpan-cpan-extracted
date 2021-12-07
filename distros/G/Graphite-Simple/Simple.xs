// PERL_NO_GET_CONTEXT is not used here, so it's OK to define it after inculding these files
#include "EXTERN.h"
#include "perl.h"

// There are a lot of macro about threads: USE_ITHREADS, USE_5005THREADS, I_PTHREAD, I_MACH_CTHREADS, OLD_PTHREADS_API
// This symbol, if defined, indicates that Perl should be built to use the interpreter-based threading implementation.
#ifndef USE_ITHREADS
#   define PERL_NO_GET_CONTEXT
#endif

#include "XSUB.h"

#ifdef I_PTHREAD
#   include "pthread.h"
#endif

#ifdef I_MACH_CTHREADS
#   include "mach/cthreads.h"
#endif

#include <string>
#include <string_view>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <time.h>
#include <fcntl.h>

using namespace std;

struct xs_state {
    uint32_t invalid_key_counter;
    HV* bulk_hv;
    HV* avg_hv;
    HV *invalid_hv;
    REGEXP* block_re;
    SV* hostname;
    SV* global_prefix;
    SV* sender_name;
    uint32_t port;
    int sockfd;
    sockaddr_in server_addr;
    bool is_connected;
    bool use_global_storage;
    bool store_invalid_metrics;
};

typedef struct xs_state GraphiteXS_Object;

static SV *sv_store_invalid_metrics_key;
static SV *sv_use_global_storage_key;
static SV *sv_sender_key;
static SV *sv_block_re_key;
static SV* host_key;
static SV* port_key;
static SV* enabled_key;
static SV* prefix_key;
static uint32_t MAX_CHUNK_SIZE;

inline void increment_hash_value_by ( HV* hv, SV* key, NV value ) {

    HE *ent = hv_fetch_ent( hv, key, 0, 0 );

    if (ent == NULL) // adding the new key
        hv_store_ent( hv, move( key ), move( newSVnv( value ) ), 0 );
    else { // updating the existed key

        SV* he_value = HeVAL(ent);
        NV  nv_value = SvNV( he_value ) + (double) value;

        if (!SvREADONLY( he_value ))
            sv_setnv( he_value, move( nv_value ) );
        else
            hv_store_ent( hv, move(key), move( newSVnv( nv_value ) ), move( HeHASH(ent) ) );
    }
}

inline bool is_metric_blocked_ (GraphiteXS_Object* graphite, SV* key) {
    bool is_blocked = false;
    if ( NULL != graphite->block_re ) {
        char* ckey = SvPVX(key);
        if ( pregexec( graphite->block_re, ckey, SvEND(key), move(ckey), 1, move(key), 1 ) )
            is_blocked = true;
    }
    return is_blocked;
}

static inline bool is_valid_key_ (GraphiteXS_Object* graphite, SV* key) {

    // https://www.linux.org.ru/forum/development/5908806
    // pregcomp pregexec pregfree pregfree2 (man perlapi)

    bool is_valid = true;
    static REGEXP* key_re;

    if ( key_re == NULL ) {
        const char* pattern = "[^a-zA-Z0-9_\\.-]";
        SV* svpat = sv_2mortal(newSVpv(pattern, strlen(pattern)));
        key_re = pregcomp(move(svpat), 0);
    }

    // if (! defined($key) || "${key}" eq '' || !utf8::valid($key) || $key =~ m#[^a-zA-Z0-9\-_\.]#) {
    if ( SVt_NULL == SvTYPE(key) )
        is_valid = false;
    else {
        char* ckey = SvPVX(key);
        if ( 0 == strlen(ckey) || ! SvPOK_only_UTF8(key) || pregexec( key_re, ckey, SvEND(key), move(ckey), 1, move(key), 1 ) )
            is_valid = false;
    }

    if ( ! is_valid )
        graphite->invalid_key_counter++;

    return is_valid;
}

static inline void increment_metric_ (GraphiteXS_Object* graphite, SV* key, NV value) {
    bool is_valid = is_valid_key_(graphite, key);
    if ( is_valid && ! is_metric_blocked_(graphite, key) ) {
        increment_hash_value_by( move(graphite->bulk_hv), key, move(value) );
        static string key_matcher ('\0', 128);
        key_matcher.assign(SvPVX( key ));
        if ( 0 == key_matcher.find( "avg." ) )
            increment_hash_value_by( move(graphite->avg_hv), move(key), 1 );
    } else if (! is_valid && graphite->store_invalid_metrics) {
        increment_hash_value_by( graphite->invalid_hv, move(key), move(value) );
    }
}

inline void clear_bulk_(GraphiteXS_Object* graphite) {
    if (graphite->store_invalid_metrics)
        hv_clear(graphite->invalid_hv);
    hv_clear(graphite->bulk_hv);
    hv_clear(graphite->avg_hv);
    graphite->invalid_key_counter = 0;
}

inline void set_blocked_metrics_re_ (GraphiteXS_Object* graphite, SV* block_re) {
    if (!block_re || SVt_NULL == SvTYPE(block_re)) {
        if (graphite->block_re) // pregfree(graphite->block_re)
            SvREFCNT_dec_NN(graphite->block_re);
        graphite->block_re = NULL;
    }
    else {
        // if (SvREADONLY(block_re)) // can be set via perl call of Internals::SvREADONLY($var => 1);

        if (graphite->block_re) // pregfree
            SvREFCNT_dec_NN(graphite->block_re);

        char* pattern = SvPV_nolen(block_re);
        SV* svpat = sv_2mortal(newSVpv(pattern, strlen(pattern)));
        graphite->block_re = pregcomp(move(svpat), 0);
        // sv_dump((SV *) graphite->block_re);
        // graphite->block_re = SvRX(block_re); // "NULL" will be returned if a REGEXP* is not found.
    }
}

inline void calculate_result_metrics_ (GraphiteXS_Object* graphite, HV* res_hv) {

    HE* bulk_entry = NULL;

    hv_iterinit(graphite->bulk_hv);

    while (bulk_entry = hv_iternext(graphite->bulk_hv)) {

        SV* sv_bulk_key = hv_iterkeysv(bulk_entry);
        SV* sv_bulk_value = hv_iterval(graphite->bulk_hv, move(bulk_entry));
        HE* avg_entry = hv_fetch_ent(graphite->avg_hv, sv_bulk_key, NULL, 0);
        HE* res_entry = hv_fetch_ent(res_hv, move(sv_bulk_key), NULL, 0);
        SV* sv_result_value;

        if (avg_entry) {
            SV* sv_avg_value = hv_iterval(graphite->avg_hv, move(avg_entry));
            sv_result_value = sv_2mortal(newSV(0));
            sv_setnv( sv_result_value, SvNV(sv_bulk_value) / SvNV(sv_avg_value) );
        }
        else
            sv_result_value = sv_mortalcopy(move(sv_bulk_value));

        SvREFCNT_inc_simple_void_NN(sv_result_value);
        // HeHASH(res_entry) wasn't calcualted previuously due to it's an empty hash
        hv_store_ent(res_hv, move(sv_bulk_key), move(sv_result_value), 0);
    }
}

void calculate_result_metrics_ (GraphiteXS_Object* graphite) {

    HE* avg_entry = NULL;

    hv_iterinit(graphite->avg_hv);

    while (avg_entry = hv_iternext(graphite->avg_hv)) {

        SV* sv_avg_key = hv_iterkeysv(avg_entry);
        SV* sv_avg_value = hv_iterval(graphite->bulk_hv, move(avg_entry));
        HE* bulk_entry = hv_fetch_ent(graphite->bulk_hv, sv_avg_key, NULL, 0);

        if (!bulk_entry)
            croak("No bulk entry found for key '%s'", SvPV_nolen(sv_avg_key));

        SV* sv_bulk_value = hv_iterval(graphite->bulk_hv, move(bulk_entry));
        sv_setnv( sv_bulk_value, SvNV(sv_bulk_value) / SvNV(sv_avg_value) );

        SvREFCNT_inc_simple_void_NN(sv_bulk_value);
        hv_store_ent(graphite->bulk_hv, move(sv_avg_key), move(sv_bulk_value), move(HeHASH(bulk_entry)));
    }
}

inline void parse_constructor_options_ (GraphiteXS_Object* graphite, HV* opts) {

    HE* entry = hv_fetch_ent(opts, sv_store_invalid_metrics_key, NULL, 0);

    if (entry)
        graphite->store_invalid_metrics = SvIVx(hv_iterval(opts, entry)) ? true : false;

    entry = hv_fetch_ent(opts, sv_sender_key, NULL, 0);

    if (entry) {
        graphite->sender_name = move(HeVAL(entry));

        if ( !graphite->sender_name )
            croak("Sender sub name can't be undefined. Specify its name with package. Example: My::Package::my_sub");

        // Let's check that the sub exists
        if (!(CV *) get_cv(SvPVX(graphite->sender_name), 0))
            croak("Can't find sender sub: %s", SvPVX(graphite->sender_name));

        SvREFCNT_inc_simple_void_NN(graphite->sender_name);
    }

    entry = hv_fetch_ent(opts, sv_use_global_storage_key, NULL, 0);

    if (entry) {
        graphite->use_global_storage = SvIVx(hv_iterval(opts, entry)) ? true : false;
    }

    if (graphite->use_global_storage) {
        graphite->bulk_hv    = get_hv("Graphite::Simple::bulk", GV_ADD);
        graphite->avg_hv     = get_hv("Graphite::Simple::avg_counters", GV_ADD);
        graphite->invalid_hv = get_hv("Graphite::Simple::invalid", GV_ADD);
    } else {
        graphite->bulk_hv    = newHV();
        graphite->avg_hv     = newHV();
        graphite->invalid_hv = newHV();
    }

    entry = hv_fetch_ent(opts, sv_block_re_key, NULL, 0);

    if (entry)
           set_blocked_metrics_re_(graphite, hv_iterval(opts, entry));

    bool is_enabled = 0;

    if ((entry = hv_fetch_ent(opts, enabled_key, NULL, 0)) != NULL)
        is_enabled = SvNVx(hv_iterval(opts, entry)) ? 1 : 0; // by default: "enabled" => 0

    if (!is_enabled) // do nothing
        return(void());

    STRLEN prefix_len = 0;

    if ((entry = hv_fetch_ent(opts, prefix_key, NULL, 0)) != NULL) {
        graphite->global_prefix = move(HeVAL(entry));
        const char *prefix = SvPVX(graphite->global_prefix);

        if ((prefix_len = SvCUR(graphite->global_prefix)) > 0) {
            if (prefix[prefix_len - 1] != '.')
                sv_catpvn(graphite->global_prefix, ".", 1);
            SvREFCNT_inc_simple_void_NN(graphite->global_prefix);
        }
    }

    if (!prefix_len)
        croak("You have to setup project name (global prefix)");

    // Initially we treat hostname as host, and only in case of failure we treat it as IP
    in_addr_t addr = 0;
    char *hostname = nullptr;

    if ((entry = hv_fetch_ent(opts, host_key, NULL, 0)) != NULL) {
        struct hostent *host;

        graphite->hostname = move(HeVAL(entry));
        hostname = SvPVX(graphite->hostname);

        SvREFCNT_inc_simple_void_NN(graphite->hostname);

        if ((host = gethostbyname(hostname)) != NULL)
            addr = *(long *)(host->h_addr_list[0]);
        else if ( (addr = inet_addr(hostname)) < 0)
            croak("Invalid hostname '%s' was given", hostname);
    }

    if (addr <= 0)
        croak("Neither host nor ip was given");

    uint32_t port;

    if ((entry = hv_fetch_ent(opts, port_key, NULL, 0)) != NULL)
        port = (uint32_t) SvIVx(hv_iterval(opts, entry));

    if (!port)
        croak("No port number was given");

    graphite->server_addr.sin_addr.s_addr = addr; //*(long *)(host->h_addr_list[0]);
    graphite->server_addr.sin_port = htons(port);
    graphite->server_addr.sin_family = AF_INET;

    graphite->port = move(port);
}


inline void disconnect_ (GraphiteXS_Object* graphite) {
    if (graphite->is_connected)
        close(graphite->sockfd);
}


MODULE = Graphite::Simple		PACKAGE = Graphite::Simple

PROTOTYPES: DISABLE

BOOT:
{
    sv_store_invalid_metrics_key = move(newSVpv("store_invalid_metrics", strlen("store_invalid_metrics")));
    sv_use_global_storage_key = move(newSVpv("use_common_storage", strlen("use_global_storage")));
    sv_sender_key   = move(newSVpv("sender_name", strlen("sender_name")));
    sv_block_re_key = move(newSVpv("block_metrics_re", strlen("block_metrics_re")));
    host_key = move(newSVpv("host", strlen("host")));
    port_key = move(newSVpv("port", strlen("port")));
    enabled_key = move(newSVpv("enabled", strlen("enabled")));
    prefix_key = move(newSVpv("project", strlen("project")));
    MAX_CHUNK_SIZE = 1460;
}

GraphiteXS_Object* new (char* class_name, HV* opts)
CODE:

    GraphiteXS_Object *self = (GraphiteXS_Object *) safemalloc(sizeof(GraphiteXS_Object));

    self->invalid_key_counter = 0;
    self->bulk_hv = nullptr;
    self->avg_hv  = nullptr;
    self->invalid_hv = nullptr;
    self->block_re = NULL;
    self->is_connected = false;
    self->use_global_storage = false;
    self->store_invalid_metrics = false;
    self->global_prefix = nullptr;
    self->sender_name = nullptr;
    self->hostname = nullptr;
    self->port = 0;
    self->sockfd = 0;

    memset(&self->server_addr, 0, sizeof(sockaddr_in));
    parse_constructor_options_(self, opts);

    RETVAL = self;
OUTPUT:
    RETVAL


void connect (GraphiteXS_Object *self)
PPCODE:

    if (self->hostname && self->port) {

        self->sockfd = socket(AF_INET, SOCK_DGRAM, 0);

        if (fcntl(self->sockfd, F_SETFL, O_NONBLOCK | O_ASYNC | O_CLOEXEC) == -1)
            croak("Error: can't set O_NONBLOCK flag");

        if(connect(self->sockfd, (struct sockaddr *) &self->server_addr, sizeof(self->server_addr)) < 0)
            croak("Error: connection is failed to %s:%i\n", SvPVX(self->hostname), self->port);

        self->is_connected = true;
    }

    mXPUSHi(self->is_connected ? 1 : 0);
    XSRETURN(1);


void disconnect (GraphiteXS_Object *self)
PPCODE:
    disconnect_(self);
    XSRETURN_EMPTY;


HV* get_bulk_metrics (GraphiteXS_Object *self)
CODE:
    //ST(0) = sv_mortalcopy((SV *) self->bulk_hv); // mXPUSHs((SV *) self->bulk_hv );
    //ST(0) = sv_2mortal(newRV_noinc( (SV *) self->bulk_hv ));
    //XSRETURN(1);
    RETVAL = self->bulk_hv;
OUTPUT:
    RETVAL


HV* get_invalid_metrics (GraphiteXS_Object *self)
CODE:
    RETVAL = self->invalid_hv;
OUTPUT:
    RETVAL


SV* send_bulk (GraphiteXS_Object* self)
PPCODE:

    IV is_success = 1;

    if (self->is_connected) {

        SSize_t keys_cnt = hv_iterinit(self->bulk_hv);

        if (keys_cnt) {

            // writes results into self->bulk_hv
            calculate_result_metrics_(self);

            STRLEN len, key_len = 0;
            const char *prefix = SvPVX(self->global_prefix);
            HE *entry = NULL;

            static string_view suffix;
            static string data ("");
            static bool is_first_time = true;
            static int send_flags = MSG_NOSIGNAL; // we don't set MSG_DONTWAIT flag because O_NONBLOCK is already set via fcntl

            if (is_first_time) {
                data.reserve(MAX_CHUNK_SIZE + 100);
                is_first_time = false;
            }

            suffix = move( string_view(move( " " + to_string(time(NULL)).append("\n") )) );

            while (entry = hv_iternext(self->bulk_hv)) {

                data.append(prefix);
                data.append(move(HePV(entry, key_len)));
                data.append(" ");
                data.append(move(SvPV_nolen(HeVAL(entry))));
                data.append(suffix);

                if (( len = data.length() ) >= MAX_CHUNK_SIZE) {
                    //warn("data:\n%s", data.c_str());
                    if (send(self->sockfd, data.c_str(), move(len), send_flags) == -1)
                        is_success = 0;
                    data.clear();
                }
            }

            if ((len = data.length()) > 0) { // if we have only one key, then "len" iz zero here
                //warn("data:\n%s", data.c_str());
                if (send(self->sockfd, data.c_str(), move(len), send_flags) == -1)
                    is_success = 0;
                data.clear();
            }
        }
    }
    else
        warn("Client is not connected to server");

    clear_bulk_(self);
    mXPUSHi(move(is_success));
    XSRETURN(1);


SV* send_bulk_delegate (GraphiteXS_Object *self)
PPCODE:

    const char *sender = SvPVX(self->sender_name);

    if (!sender)
        croak("No sender was specified");

    calculate_result_metrics_(self);

    // see "man perlcall" for details

    IV status = 0;

    dSP; // Declares a local copy of perl's stack pointer for the XSUB, available via the "SP" macro.  See "SP".
    I32 ax;
    I32 count;

    ENTER;         // Opening bracket on a callback.  See "LEAVE" and perlcall.
    SAVETMPS;      // pening bracket for temporaries on a callback.  See "FREETMPS" and perlcall.
    PUSHMARK(SP);  // Opening bracket for arguments on a callback.  See "PUTBACK" and perlcall.
    EXTEND(SP, 1); // We are going to pass only one argument
    PUSHs(sv_2mortal(newRV( (SV *) self->bulk_hv ))); // Push into outgoing stack an argument
    PUTBACK;       // Closing bracket for XSUB arguments.  This is usually handled by "xsubpp".  See "PUSHMARK" and perlcall for other uses.

    count = call_pv(sender, G_SCALAR);

    SPAGAIN;      // Refetch the stack pointer.  Used after a callback.  See perlcall.
    SP -= count;
    ax = (SP - PL_stack_base) + 1;

    if (count != 1)
        croak("Unexpected size of returned stack from sender\n");

    uint32_t type = SvTYPE(ST(0));

    if (SVt_IV == type || SVt_NV == type)
        status = SvIV(ST(0)); // round the value
    else
        warn("The sender must return a number type of status. Using 0 as sender status now.");

    PUTBACK;  // Closing bracket for XSUB arguments.  This is usually handled by "xsubpp".  See "PUSHMARK" and perlcall for other uses.
    FREETMPS; // Closing bracket for temporaries on a callback.  See "SAVETMPS" and perlcall.
    LEAVE;    // Closing bracket on a callback.  See "ENTER" and perlcall.

    // warn("status: %d\n", status);
    clear_bulk_(self);
    mXPUSHi(status);
    XSRETURN(1);


HV* get_metrics (GraphiteXS_Object *self)
CODE:
    HV* res_hv = (HV *) sv_2mortal((SV*) newHV());
    calculate_result_metrics_(self, res_hv);
    RETVAL = move(res_hv);
OUTPUT:
    RETVAL


HV* get_average_counters (GraphiteXS_Object *self)
CODE:
    RETVAL = self->avg_hv;
OUTPUT:
    RETVAL


void clear_bulk (GraphiteXS_Object *self)
PPCODE:
    clear_bulk_(self);
    XSRETURN_EMPTY;


void incr_bulk (GraphiteXS_Object *self, SV* key, NV value = 1)
PPCODE:
    bool is_ok = false;
    if (key != &PL_sv_undef) {
        uint32_t key_type = SvTYPE(key);
        if (key_type == SVt_PVLV || key_type == SVt_PVMG) {
            // SVt_PVLV can be returned from substr
            // SVt_PVMG can be returned from RegExp
            STRLEN key_len;
            char *ch = SvPVx(move(key), key_len);
            key = newSVpv(move(ch), move(key_len));
        }
        if (SvTYPE(key) == SVt_PV) {
            is_ok = true;
            increment_metric_( self, move(key), move(value) );
        }
    }

    if (!is_ok)
        croak("key must be a string");

    XSRETURN_EMPTY;


void append_bulk (GraphiteXS_Object *self, HV* hv, SV* prefix = &PL_sv_undef)
PPCODE:

    if (SvTIED_mg((SV *) hv, PERL_MAGIC_tied))
        croak("Tied hashes are not supported");

    bool use_prefix = false;

    if (prefix && prefix != &PL_sv_undef) {

        uint32_t type = SvTYPE(prefix);

        use_prefix = type == SVt_PV || type == SVt_PVLV;

        if (!use_prefix && type != SVt_NULL)
            croak("prefix must be a string or undefined");
    }

    HE* entry = NULL;
    static string sprefix ('\0', 128); // preallocate 128 byte

    if (use_prefix) {
        sprefix.assign( SvPVX(prefix) );
        if (sprefix.back() != '.')
            sprefix.append(".");
    }

    hv_iterinit(hv);

    while (entry = hv_iternext(hv)) {

        SV* key = hv_iterkeysv(entry);
        SV* value = hv_iterval(hv, move(entry));
        uint32_t value_type = SvTYPE(value);

        if (
                SvROK(value) ||
                (
                    // value_type < SVt_IV || value_type > SVt_PVNV
                    SVt_IV != value_type &&
                    SVt_NV != value_type &&
                    SVt_PV != value_type &&
                    SVt_PVNV != value_type &&
                    SVt_PVIV != value_type
                )
           ) {
            warn("Value type of key '%s' is not a number", SvPVX(key));
            continue;
        }

        if (use_prefix)
            sv_setpv(key, ( sprefix + SvPVX(key) ).c_str());

        increment_metric_( self, move(key), move(SvNVx(value)) );
    }

    XSRETURN_EMPTY;


SV* is_valid_key (GraphiteXS_Object *self, SV* key)
PPCODE:
    bool is_valid = is_valid_key_(self, move(key));
    mXPUSHi( move(is_valid ? 1 : 0) );
    XSRETURN(1);


IV get_invalid_key_counter (GraphiteXS_Object *self)
PPCODE:
    mXPUSHi( self->invalid_key_counter );
    XSRETURN(1);


void check_and_bump_invalid_metric (GraphiteXS_Object *self, SV* key)
PPCODE:
    if ( SVt_NULL != SvTYPE(key) ) {
        uint32_t counter = move(self->invalid_key_counter);
        self->invalid_key_counter = 0;
        increment_hash_value_by( self->bulk_hv, move(key), move(counter) );
    }
    XSRETURN_EMPTY;


IV is_metric_blocked (GraphiteXS_Object *self, SV* key)
PPCODE:
    bool is_blocked = false;
    if ( is_valid_key_(self, key) )
        is_blocked = is_metric_blocked_(self, move(key));
    mXPUSHi( move(is_blocked ? 1 : 0) );
    XSRETURN(1);


void set_blocked_metrics_re (GraphiteXS_Object *self, SV* block_re = &PL_sv_undef)
PPCODE:
    set_blocked_metrics_re_(self, block_re);
    XSRETURN_EMPTY;


void DESTROY (...)
PPCODE:
    GraphiteXS_Object *self = (GraphiteXS_Object *) SvUV(SvRV(ST(0)));
    if (PL_dirty) // global destruction
        return;
    if (self->sender_name) // sv_clear
        SvREFCNT_dec_NN(self->sender_name);
    if (self->global_prefix) // sv_clear
        SvREFCNT_dec_NN(self->global_prefix);
    if (self->hostname) // sv_clear
        SvREFCNT_dec_NN(self->hostname);
    while (self->block_re && SvREFCNT(self->block_re))
        SvREFCNT_dec_NN(self->block_re);
    if (!self->use_global_storage) {
        if (self->bulk_hv) // hv_undef
            SvREFCNT_dec_NN(self->bulk_hv);
        if (self->avg_hv) // hv_undef
            SvREFCNT_dec_NN(self->avg_hv);
        if (self->invalid_hv) // hv_undef
            SvREFCNT_dec_NN(self->invalid_hv);
    }
    disconnect_(self);
    //dump_all();
    safefree(move(self));
    XSRETURN_EMPTY;
