package Hypersonic::UA;

use strict;
use warnings;
use 5.010;
use Carp;

our $VERSION = '0.12';

use XS::JIT::Builder;

use constant MAX_CONNECTIONS => 65536;
use constant UA_MAX_INSTANCES => 256;

# Object slots (array-based for O(1) access)
use constant {
    SLOT_ID              => 0,
    SLOT_TIMEOUT         => 1,
    SLOT_CONNECT_TIMEOUT => 2,
    SLOT_HEADERS         => 3,
    SLOT_BASE_URL        => 4,
    SLOT_MAX_REDIRECTS   => 5,
    SLOT_KEEP_ALIVE      => 6,
};

# JIT compilation state
our $COMPILED = 0;
our %FEATURES;  # Track which features were compiled
my $MODULE_NAME;

#############################################################################
# Compilation
#############################################################################

sub compile {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    require XS::JIT;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_cache/ua';
    $MODULE_NAME = 'Hypersonic::UA::XS_' . $$;

    # Feature analysis - default to minimal (blocking-only)
    my %analysis = (
        needs_async       => $opts{async} || $opts{parallel} || $opts{full} || 0,
        needs_parallel    => $opts{parallel} || $opts{full} || 0,
        needs_tls         => $opts{tls} || $opts{full} || 0,
        needs_http2       => $opts{http2} || $opts{full} || 0,
        needs_compression => $opts{compression} || $opts{full} || 0,
        needs_cookie_jar  => $opts{cookie_jar} || $opts{full} || 0,
        needs_redirects   => $opts{redirects} || $opts{full} || 0,
    );

    # Store for runtime checks
    %FEATURES = %analysis;

    my $builder = XS::JIT::Builder->new;

    # Generate core UA code (always)
    $class->generate_c_code($builder, \%opts, \%analysis);

    # Collect core functions
    my %functions = %{ $class->get_xs_functions(\%analysis) };

    # Include Async module (conditional)
    if ($analysis{needs_async}) {
        require Hypersonic::UA::Async;
        Hypersonic::UA::Async->generate_c_code($builder, \%opts);
        %functions = (%functions, %{ Hypersonic::UA::Async->get_xs_functions });
    }

    # Include Future module for parallel/race (conditional)
    if ($analysis{needs_parallel}) {
        require Hypersonic::Future;
        Hypersonic::Future->compile(cache_dir => $cache_dir)
            unless $Hypersonic::Future::COMPILED;
    }

    my $code = $builder->code;

    XS::JIT->compile(
        code      => $code,
        name      => $MODULE_NAME,
        cache_dir => $cache_dir,
        functions => \%functions,
    );

    $COMPILED = 1;
    return 1;
}

sub generate_c_code {
    my ($class, $builder, $opts, $analysis) = @_;

    my $max = $opts->{max_connections} // MAX_CONNECTIONS;

    # Add required includes for networking (needed by UA registry and HTTP methods)
    $builder->line('#include <sys/types.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <arpa/inet.h>')
      ->line('#include <netdb.h>')
      ->line('#include <unistd.h>')
      ->line('#include <string.h>')
      ->line('#include <time.h>')
      ->line('#include <errno.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <ctype.h>')
      ->blank
      ->comment('Portable strcasestr implementation (GNU extension not available everywhere)')
      ->line('#ifndef HAVE_STRCASESTR')
      ->line('static char *hs_strcasestr(const char *haystack, const char *needle) {')
      ->line('    size_t needle_len;')
      ->line('    if (!needle || !*needle) return (char *)haystack;')
      ->line('    needle_len = strlen(needle);')
      ->line('    while (*haystack) {')
      ->line('        if (strncasecmp(haystack, needle, needle_len) == 0)')
      ->line('            return (char *)haystack;')
      ->line('        haystack++;')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->line('#define strcasestr hs_strcasestr')
      ->line('#endif')
      ->blank;

    # UA registry (always)
    $class->gen_ua_registry($builder, $max);

    # Core URL/request building (always)
    $class->gen_xs_parse_url($builder);
    $class->gen_xs_build_request($builder);

    # Constructor/destructor (always)
    $class->gen_xs_new($builder);
    $class->gen_xs_destroy($builder);

    # Blocking/callback methods (always - core functionality)
    $class->gen_xs_get($builder);
    $class->gen_xs_post($builder);
    $class->gen_xs_put($builder);
    $class->gen_xs_patch($builder);
    $class->gen_xs_delete($builder);
    $class->gen_xs_head($builder);
    $class->gen_xs_options($builder);
    $class->gen_xs_request($builder);

    # Async/Future methods (conditional - requires async => 1)
    if ($analysis->{needs_async}) {
        $builder->comment('JIT: Async methods enabled (async => 1)');
        $class->gen_xs_get_async($builder);
        $class->gen_xs_post_async($builder);
        $class->gen_xs_put_async($builder);
        $class->gen_xs_delete_async($builder);
        $class->gen_xs_request_async($builder);

        # Run/poll (requires async) - tick is generated in Async.pm after headers
        $class->gen_xs_run($builder);
        $class->gen_xs_run_one($builder);
        # gen_xs_tick moved to Async.pm to be after kqueue headers
        $class->gen_xs_pending($builder);
    } else {
        $builder->comment('JIT: Async methods SKIPPED (compile with async => 1 to enable)');
    }

    # Parallel/race helpers (conditional - requires parallel => 1)
    if ($analysis->{needs_parallel}) {
        $builder->comment('JIT: Parallel helpers enabled (parallel => 1)');
        $class->gen_xs_parallel($builder);
        $class->gen_xs_race($builder);
    } else {
        $builder->comment('JIT: Parallel helpers SKIPPED (compile with parallel => 1 to enable)');
    }
}

sub get_xs_functions {
    my ($class, $analysis) = @_;
    $analysis //= {};

    # Core functions (always registered)
    my %functions = (
        # Constructor/destructor
        'Hypersonic::UA::new'           => { source => 'xs_ua_new', is_xs_native => 1 },
        'Hypersonic::UA::DESTROY'       => { source => 'xs_ua_destroy', is_xs_native => 1 },

        # URL/request utilities
        'Hypersonic::UA::parse_url'     => { source => 'xs_ua_parse_url', is_xs_native => 1 },
        'Hypersonic::UA::build_request' => { source => 'xs_ua_build_request', is_xs_native => 1 },

        # Blocking (sync) HTTP methods - always available
        'Hypersonic::UA::get'           => { source => 'xs_ua_get', is_xs_native => 1 },
        'Hypersonic::UA::post'          => { source => 'xs_ua_post', is_xs_native => 1 },
        'Hypersonic::UA::put'           => { source => 'xs_ua_put', is_xs_native => 1 },
        'Hypersonic::UA::patch'         => { source => 'xs_ua_patch', is_xs_native => 1 },
        'Hypersonic::UA::delete'        => { source => 'xs_ua_delete', is_xs_native => 1 },
        'Hypersonic::UA::head'          => { source => 'xs_ua_head', is_xs_native => 1 },
        'Hypersonic::UA::options'       => { source => 'xs_ua_options', is_xs_native => 1 },
        'Hypersonic::UA::request'       => { source => 'xs_ua_request', is_xs_native => 1 },
    );

    # Async functions (conditional - requires async => 1)
    if ($analysis->{needs_async}) {
        %functions = (%functions,
            # Future-based async methods
            'Hypersonic::UA::get_async'     => { source => 'xs_ua_get_async', is_xs_native => 1 },
            'Hypersonic::UA::post_async'    => { source => 'xs_ua_post_async', is_xs_native => 1 },
            'Hypersonic::UA::put_async'     => { source => 'xs_ua_put_async', is_xs_native => 1 },
            'Hypersonic::UA::delete_async'  => { source => 'xs_ua_delete_async', is_xs_native => 1 },
            'Hypersonic::UA::request_async' => { source => 'xs_ua_request_async', is_xs_native => 1 },

            # Run/poll methods
            'Hypersonic::UA::run'           => { source => 'xs_ua_run', is_xs_native => 1 },
            'Hypersonic::UA::run_one'       => { source => 'xs_ua_run_one', is_xs_native => 1 },
            'Hypersonic::UA::tick'          => { source => 'xs_ua_tick', is_xs_native => 1 },
            'Hypersonic::UA::pending'       => { source => 'xs_ua_pending', is_xs_native => 1 },
        );
    }

    # Parallel/race helpers (conditional - requires parallel => 1)
    if ($analysis->{needs_parallel}) {
        %functions = (%functions,
            'Hypersonic::UA::parallel'      => { source => 'xs_ua_parallel', is_xs_native => 1 },
            'Hypersonic::UA::race'          => { source => 'xs_ua_race', is_xs_native => 1 },
        );
    }

    return \%functions;
}

sub gen_ua_registry {
    my ($class, $builder, $max) = @_;
    $max //= MAX_CONNECTIONS;

    $builder->line("#define UA_MAX_CONNECTIONS $max")
      ->line("#define UA_MAX_INSTANCES 256")
      ->line("#define DNS_CACHE_SIZE 64")
      ->line("#define CONN_POOL_SIZE 32")
      ->blank
      ->comment('Connection pool entry for keep-alive')
      ->line('typedef struct {')
      ->line('    int fd;')
      ->line('    char host[256];')
      ->line('    int port;')
      ->line('    time_t expires;')
      ->line('} PooledConn;')
      ->blank
      ->line("static PooledConn conn_pool[CONN_POOL_SIZE];")
      ->blank
      ->comment('Get a pooled connection if available')
      ->line('static int pool_get(const char *host, int port) {')
      ->line('    int i;')
      ->line('    time_t now = time(NULL);')
      ->line('    for (i = 0; i < CONN_POOL_SIZE; i++) {')
      ->line('        if (conn_pool[i].fd > 0 && conn_pool[i].port == port &&')
      ->line('            strcmp(conn_pool[i].host, host) == 0 && conn_pool[i].expires > now) {')
      ->line('            int fd = conn_pool[i].fd;')
      ->line('            conn_pool[i].fd = 0;')
      ->line('            return fd;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank
      ->comment('Return connection to pool (15 second keep-alive)')
      ->line('static void pool_put(int fd, const char *host, int port) {')
      ->line('    int i;')
      ->line('    time_t now = time(NULL);')
      ->line('    /* Find empty slot or expired entry */')
      ->line('    for (i = 0; i < CONN_POOL_SIZE; i++) {')
      ->line('        if (conn_pool[i].fd <= 0 || conn_pool[i].expires <= now) {')
      ->line('            if (conn_pool[i].fd > 0) close(conn_pool[i].fd);')
      ->line('            conn_pool[i].fd = fd;')
      ->line('            strncpy(conn_pool[i].host, host, 255);')
      ->line('            conn_pool[i].host[255] = 0;')
      ->line('            conn_pool[i].port = port;')
      ->line('            conn_pool[i].expires = now + 15;')
      ->line('            return;')
      ->line('        }')
      ->line('    }')
      ->line('    /* Pool full, just close */')
      ->line('    close(fd);')
      ->line('}')
      ->blank
      ->line('typedef struct {')
      ->line('    int fd;')
      ->line('    int tls;')
      ->line('    int state;')
      ->line('    char* host;')
      ->line('    int port;')
      ->line('    int timeout_ms;')
      ->line('    int connect_timeout_ms;')
      ->line('} UAConnection;')
      ->blank
      ->line("static UAConnection g_ua_connections[UA_MAX_CONNECTIONS];")
      ->blank
      ->comment('DNS cache entry')
      ->line('typedef struct {')
      ->line('    char host[256];')
      ->line('    struct in_addr addr;')
      ->line('    time_t expires;')
      ->line('} DNSCacheEntry;')
      ->blank
      ->line("static DNSCacheEntry dns_cache[DNS_CACHE_SIZE];")
      ->line("static int dns_cache_next = 0;")
      ->blank
      ->comment('Lookup DNS with caching (60 second TTL)')
      ->line('static int dns_lookup_cached(const char *host, struct in_addr *addr_out) {')
      ->line('    int i;')
      ->line('    int slot;')
      ->line('    struct hostent *he;')
      ->line('    time_t now = time(NULL);')
      ->line('    /* Check cache */')
      ->line('    for (i = 0; i < DNS_CACHE_SIZE; i++) {')
      ->line('        if (dns_cache[i].host[0] && strcmp(dns_cache[i].host, host) == 0 && dns_cache[i].expires > now) {')
      ->line('            *addr_out = dns_cache[i].addr;')
      ->line('            return 1;')
      ->line('        }')
      ->line('    }')
      ->line('    /* Cache miss - do lookup */')
      ->line('    he = gethostbyname(host);')
      ->line('    if (!he) return 0;')
      ->line('    memcpy(addr_out, he->h_addr_list[0], sizeof(struct in_addr));')
      ->line('    /* Store in cache */')
      ->line('    slot = dns_cache_next++ % DNS_CACHE_SIZE;')
      ->line('    strncpy(dns_cache[slot].host, host, 255);')
      ->line('    dns_cache[slot].host[255] = 0;')
      ->line('    dns_cache[slot].addr = *addr_out;')
      ->line('    dns_cache[slot].expires = now + 60;')
      ->line('    return 1;')
      ->line('}')
      ->blank
      ->line('typedef struct {')
      ->line('    int in_use;')
      ->line('    int timeout_ms;')
      ->line('    int connect_timeout_ms;')
      ->line('    int max_redirects;')
      ->line('    int keep_alive;')
      ->line('    SV *default_headers;')
      ->line('    char *base_url;')
      ->line('} UAContext;')
      ->blank
      ->line("static UAContext ua_registry[UA_MAX_INSTANCES];")
      ->blank
      ->line('static int ua_alloc_slot(void) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_INSTANCES; i++) {')
      ->line('        if (!ua_registry[i].in_use) {')
      ->line('            memset(&ua_registry[i], 0, sizeof(UAContext));')
      ->line('            ua_registry[i].in_use = 1;')
      ->line('            return i;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank
      ->line('static void ua_free_slot(int slot) {')
      ->line('    if (slot >= 0 && slot < UA_MAX_INSTANCES) {')
      ->line('        ua_registry[slot].in_use = 0;')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->comment('Constructor: new() or new({ timeout => 30000, ... })')
      ->xs_function('xs_ua_new')
      ->xs_preamble
      ->line('HV *opts;')
      ->line('SV **val;')
      ->line('STRLEN len;')
      ->line('const char *url;')
      ->line('int slot;')
      ->line('UAContext *ctx;')
      ->line('AV *self;')
      ->line('SV *self_ref;')
      ->blank
      ->line('if (items < 1) croak("Usage: Hypersonic::UA->new([$opts])");')
      ->blank
      ->line('slot = ua_alloc_slot();')
      ->line('if (slot < 0) croak("Too many UA instances");')
      ->blank
      ->line('ctx = &ua_registry[slot];')
      ->blank
      ->comment('Defaults')
      ->line('ctx->timeout_ms = 30000;')
      ->line('ctx->connect_timeout_ms = 5000;')
      ->line('ctx->max_redirects = 5;')
      ->line('ctx->keep_alive = 1;')
      ->line('ctx->default_headers = NULL;')
      ->line('ctx->base_url = NULL;')
      ->blank
      ->comment('Parse options hash if provided')
      ->if('items >= 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV')
        ->line('opts = (HV *)SvRV(ST(1));')
        ->blank
        ->line('if ((val = hv_fetchs(opts, "timeout", 0)) && SvOK(*val)) ctx->timeout_ms = SvIV(*val);')
        ->line('if ((val = hv_fetchs(opts, "connect_timeout", 0)) && SvOK(*val)) ctx->connect_timeout_ms = SvIV(*val);')
        ->line('if ((val = hv_fetchs(opts, "max_redirects", 0)) && SvOK(*val)) ctx->max_redirects = SvIV(*val);')
        ->line('if ((val = hv_fetchs(opts, "keep_alive", 0)) && SvOK(*val)) ctx->keep_alive = SvTRUE(*val) ? 1 : 0;')
        ->line('if ((val = hv_fetchs(opts, "headers", 0)) && SvROK(*val)) ctx->default_headers = SvREFCNT_inc(*val);')
        ->if('(val = hv_fetchs(opts, "base_url", 0)) && SvOK(*val)')
          ->line('url = SvPV(*val, len);')
          ->line('ctx->base_url = (char *)malloc(len + 1);')
          ->line('memcpy(ctx->base_url, url, len + 1);')
        ->endif
      ->endif
      ->blank
      ->comment('Build array-based object')
      ->line('self = newAV();')
      ->line('av_extend(self, 6);')
      ->line('av_store(self, 0, newSViv(slot));')
      ->line('av_store(self, 1, newSViv(ctx->timeout_ms));')
      ->line('av_store(self, 2, newSViv(ctx->connect_timeout_ms));')
      ->line('av_store(self, 3, ctx->default_headers ? SvREFCNT_inc(ctx->default_headers) : newRV_noinc((SV *)newHV()));')
      ->line('av_store(self, 4, ctx->base_url ? newSVpv(ctx->base_url, 0) : &PL_sv_undef);')
      ->line('av_store(self, 5, newSViv(ctx->max_redirects));')
      ->line('av_store(self, 6, newSViv(ctx->keep_alive));')
      ->blank
      ->line('self_ref = newRV_noinc((SV *)self);')
      ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::UA", GV_ADD));')
      ->blank
      ->line('ST(0) = sv_2mortal(self_ref);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_destroy {
    my ($class, $builder) = @_;

    $builder->comment('Destructor')
      ->xs_function('xs_ua_destroy')
      ->xs_preamble
      ->line('if (items != 1 || !SvROK(ST(0))) XSRETURN_EMPTY;')
      ->blank
      ->line('AV *self = (AV *)SvRV(ST(0));')
      ->line('SV **slot_sv = av_fetch(self, 0, 0);')
      ->line('if (!slot_sv || !SvOK(*slot_sv)) XSRETURN_EMPTY;')
      ->blank
      ->line('int slot = SvIV(*slot_sv);')
      ->line('if (slot < 0 || slot >= UA_MAX_INSTANCES) XSRETURN_EMPTY;')
      ->blank
      ->line('UAContext *ctx = &ua_registry[slot];')
      ->blank
      ->comment('Free UA resources')
      ->if('ctx->default_headers')
        ->line('SvREFCNT_dec(ctx->default_headers);')
        ->line('ctx->default_headers = NULL;')
      ->endif
      ->if('ctx->base_url')
        ->line('free(ctx->base_url);')
        ->line('ctx->base_url = NULL;')
      ->endif
      ->blank
      ->line('ua_free_slot(slot);')
      ->xs_return('0')
      ->xs_end
      ->blank;
}

sub gen_xs_parse_url {
    my ($class, $builder) = @_;

    $builder->comment('Parse URL into components: (scheme, host, port, path, query)')
      ->xs_function('xs_ua_parse_url')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: parse_url(url)");')
      ->blank
      ->line('STRLEN url_len;')
      ->line('const char* url = SvPV(ST(0), url_len);')
      ->blank
      ->comment('Parse scheme')
      ->line('const char* p = url;')
      ->line('const char* scheme_end = strstr(p, "://");')
      ->if('!scheme_end')
        ->line('croak("Invalid URL: missing scheme");')
      ->endif
      ->blank
      ->line('int is_https = (scheme_end - p == 5 && memcmp(p, "https", 5) == 0);')
      ->line('int is_http = (scheme_end - p == 4 && memcmp(p, "http", 4) == 0);')
      ->if('!is_https && !is_http')
        ->line('croak("Invalid URL: unsupported scheme");')
      ->endif
      ->blank
      ->line('p = scheme_end + 3;')
      ->blank
      ->comment('Parse host and port')
      ->line('const char* host_start = p;')
      ->line('const char* host_end = p;')
      ->line('int port = is_https ? 443 : 80;')
      ->blank
      ->line('while (*host_end && *host_end != \':\' && *host_end != \'/\' && *host_end != \'?\') host_end++;')
      ->blank
      ->if('*host_end == \':\'')
        ->line('port = 0;')
        ->line('const char* port_start = host_end + 1;')
        ->line('while (*port_start >= \'0\' && *port_start <= \'9\') {')
        ->line('    port = port * 10 + (*port_start - \'0\');')
        ->line('    port_start++;')
        ->line('}')
        ->line('p = port_start;')
      ->else
        ->line('p = host_end;')
      ->endif
      ->blank
      ->comment('Parse path')
      ->line('const char* path_start = (*p == \'/\') ? p : "/";')
      ->line('const char* path_end = path_start;')
      ->line('while (*path_end && *path_end != \'?\') path_end++;')
      ->blank
      ->comment('Parse query')
      ->line('const char* query = (*path_end == \'?\') ? path_end + 1 : "";')
      ->blank
      ->comment('Build result array: [scheme, host, port, path, query]')
      ->line('AV* result = newAV();')
      ->line('av_push(result, newSVpv(is_https ? "https" : "http", 0));')
      ->line('av_push(result, newSVpvn(host_start, host_end - host_start));')
      ->line('av_push(result, newSViv(port));')
      ->line('av_push(result, newSVpvn(path_start, path_end - path_start));')
      ->line('av_push(result, newSVpv(query, 0));')
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)result));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_build_request {
    my ($class, $builder) = @_;

    $builder->comment('Build HTTP/1.1 request string')
      ->xs_function('xs_ua_build_request')
      ->xs_preamble
      ->line('if (items < 4) croak("Usage: build_request(method, path, host, headers_hv, [body])");')
      ->blank
      ->line('STRLEN method_len, path_len, host_len;')
      ->line('const char* method = SvPV(ST(0), method_len);')
      ->line('const char* path = SvPV(ST(1), path_len);')
      ->line('const char* host = SvPV(ST(2), host_len);')
      ->line('HV* headers = (HV*)SvRV(ST(3));')
      ->line('SV* body_sv = (items > 4) ? ST(4) : NULL;')
      ->blank
      ->comment('Calculate request size')
      ->line('size_t request_size = method_len + 1 + path_len + 12;')
      ->line('request_size += 6 + host_len + 2;')
      ->blank
      ->comment('Add header sizes')
      ->line('hv_iterinit(headers);')
      ->line('HE* entry;')
      ->line('while ((entry = hv_iternext(headers)) != NULL) {')
      ->line('    SV* key_sv = hv_iterkeysv(entry);')
      ->line('    SV* val_sv = hv_iterval(headers, entry);')
      ->line('    STRLEN key_len, val_len;')
      ->line('    SvPV(key_sv, key_len);')
      ->line('    SvPV(val_sv, val_len);')
      ->line('    request_size += key_len + 2 + val_len + 2;')
      ->line('}')
      ->blank
      ->line('STRLEN body_len = 0;')
      ->if('body_sv && SvOK(body_sv)')
        ->line('SvPV(body_sv, body_len);')
        ->line('request_size += 20 + body_len;')
      ->endif
      ->blank
      ->line('request_size += 2;')
      ->blank
      ->comment('Allocate and build request')
      ->line('SV* request = newSV(request_size);')
      ->line('SvPOK_on(request);')
      ->line('char* rp = SvPVX(request);')
      ->blank
      ->comment('Request line')
      ->line('memcpy(rp, method, method_len); rp += method_len;')
      ->line('*rp++ = \' \';')
      ->line('memcpy(rp, path, path_len); rp += path_len;')
      ->line('memcpy(rp, " HTTP/1.1\\r\\n", 11); rp += 11;')
      ->blank
      ->comment('Host header')
      ->line('memcpy(rp, "Host: ", 6); rp += 6;')
      ->line('memcpy(rp, host, host_len); rp += host_len;')
      ->line('*rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->blank
      ->comment('Other headers')
      ->line('hv_iterinit(headers);')
      ->line('while ((entry = hv_iternext(headers)) != NULL) {')
      ->line('    SV* key_sv = hv_iterkeysv(entry);')
      ->line('    SV* val_sv = hv_iterval(headers, entry);')
      ->line('    STRLEN key_len, val_len;')
      ->line('    const char* key = SvPV(key_sv, key_len);')
      ->line('    const char* val = SvPV(val_sv, val_len);')
      ->line('    memcpy(rp, key, key_len); rp += key_len;')
      ->line('    *rp++ = \':\'; *rp++ = \' \';')
      ->line('    memcpy(rp, val, val_len); rp += val_len;')
      ->line('    *rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->line('}')
      ->blank
      ->comment('Content-Length and body if present')
      ->if('body_len > 0')
        ->line('rp += sprintf(rp, "Content-Length: %zu\\r\\n", body_len);')
      ->endif
      ->blank
      ->comment('End of headers')
      ->line('*rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->blank
      ->comment('Body')
      ->if('body_len > 0')
        ->line('const char* body = SvPV_nolen(body_sv);')
        ->line('memcpy(rp, body, body_len); rp += body_len;')
      ->endif
      ->blank
      ->line('SvCUR_set(request, rp - SvPVX(request));')
      ->line('ST(0) = sv_2mortal(request);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get {
    my ($class, $builder) = @_;

    # Inlined HTTP GET with connection pooling and keep-alive
    $builder->comment('GET request - with keep-alive connection pooling')
      ->comment('Usage: $ua->get($url) or $ua->get($url, sub { ... })')
      ->xs_function('xs_ua_get')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->get($url, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *cb = (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) ? ST(2) : NULL;')
      ->blank
      ->comment('Parse URL')
      ->line('STRLEN url_len;')
      ->line('const char *url = SvPV(url_sv, url_len);')
      ->blank
      ->line('const char *scheme_end = strstr(url, "://");')
      ->line('if (!scheme_end) croak("Invalid URL");')
      ->blank
      ->line('int is_https = (scheme_end - url == 5 && memcmp(url, "https", 5) == 0);')
      ->line('const char *host_start = scheme_end + 3;')
      ->line('const char *host_end = host_start;')
      ->line('int port = is_https ? 443 : 80;')
      ->blank
      ->line('while (*host_end && *host_end != \':\' && *host_end != \'/\' && *host_end != \'?\') host_end++;')
      ->blank
      ->line('const char *p = host_end;')
      ->if('*host_end == \':\'')
        ->line('port = atoi(host_end + 1);')
        ->line('while (*p && *p != \'/\' && *p != \'?\') p++;')
      ->endif
      ->blank
      ->line('const char *path = (*p == \'/\') ? p : "/";')
      ->blank
      ->line('char host_buf[256];')
      ->line('int host_len = host_end - host_start;')
      ->line('if (host_len > 255) host_len = 255;')
      ->line('memcpy(host_buf, host_start, host_len);')
      ->line('host_buf[host_len] = 0;')
      ->blank
      ->comment('Try to get pooled connection first')
      ->line('int fd = pool_get(host_buf, port);')
      ->line('int pooled = (fd > 0);')
      ->blank
      ->if('fd <= 0')
        ->comment('No pooled connection, create new one')
        ->line('fd = socket(AF_INET, SOCK_STREAM, 0);')
        ->line('if (fd < 0) croak("socket() failed");')
        ->blank
        ->line('struct sockaddr_in addr;')
        ->line('memset(&addr, 0, sizeof(addr));')
        ->line('addr.sin_family = AF_INET;')
        ->line('addr.sin_port = htons(port);')
        ->if('!dns_lookup_cached(host_buf, &addr.sin_addr)')
          ->line('close(fd);')
          ->line('croak("DNS resolution failed for %s", host_buf);')
        ->endif
        ->blank
        ->if('connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0')
          ->line('close(fd);')
          ->line('croak("connect() failed");')
        ->endif
      ->endif
      ->blank
      ->comment('Build HTTP GET request with keep-alive')
      ->line('char req_buf[4096];')
      ->line('int req_len = snprintf(req_buf, sizeof(req_buf),')
      ->line('    "GET %s HTTP/1.1\\r\\n"')
      ->line('    "Host: %s\\r\\n"')
      ->line('    "Connection: keep-alive\\r\\n"')
      ->line('    "User-Agent: Hypersonic/1.0\\r\\n"')
      ->line('    "\\r\\n",')
      ->line('    path, host_buf);')
      ->blank
      ->comment('Send request')
      ->line('if (send(fd, req_buf, req_len, 0) < 0) {')
      ->line('    close(fd);')
      ->line('    croak("send() failed");')
      ->line('}')
      ->blank
      ->comment('Receive response - need to parse Content-Length for keep-alive')
      ->line('char resp_buf[65536];')
      ->line('int resp_len = 0;')
      ->line('int headers_end = 0;')
      ->line('int content_length = -1;')
      ->line('int n;')
      ->blank
      ->comment('Read until we have headers')
      ->line('while (!headers_end && resp_len < (int)sizeof(resp_buf) - 1) {')
      ->line('    n = recv(fd, resp_buf + resp_len, sizeof(resp_buf) - resp_len - 1, 0);')
      ->line('    if (n <= 0) break;')
      ->line('    resp_len += n;')
      ->line('    resp_buf[resp_len] = 0;')
      ->line('    char *hdr_end = strstr(resp_buf, "\\r\\n\\r\\n");')
      ->line('    if (hdr_end) {')
      ->line('        headers_end = hdr_end - resp_buf + 4;')
      ->line('        /* Parse Content-Length */')
      ->line('        char *cl = strcasestr(resp_buf, "Content-Length:");')
      ->line('        if (cl && cl < hdr_end) content_length = atoi(cl + 15);')
      ->line('    }')
      ->line('}')
      ->blank
      ->comment('Read remaining body based on Content-Length')
      ->if('content_length > 0')
        ->line('int body_received = resp_len - headers_end;')
        ->line('while (body_received < content_length && resp_len < (int)sizeof(resp_buf) - 1) {')
        ->line('    n = recv(fd, resp_buf + resp_len, sizeof(resp_buf) - resp_len - 1, 0);')
        ->line('    if (n <= 0) break;')
        ->line('    resp_len += n;')
        ->line('    body_received += n;')
        ->line('}')
      ->endif
      ->line('resp_buf[resp_len] = 0;')
      ->blank
      ->comment('Return connection to pool if keep-alive')
      ->line('char *conn_hdr = strcasestr(resp_buf, "Connection:");')
      ->line('int keep_alive = 1;')
      ->if('conn_hdr && headers_end > 0 && conn_hdr < resp_buf + headers_end')
        ->line('if (strncasecmp(conn_hdr + 11, " close", 6) == 0) keep_alive = 0;')
      ->endif
      ->blank
      ->if('keep_alive && content_length >= 0')
        ->line('pool_put(fd, host_buf, port);')
      ->else
        ->line('close(fd);')
      ->endif
      ->blank
      ->comment('Parse response')
      ->line('HV *result = newHV();')
      ->blank
      ->comment('Extract status code')
      ->line('int status = 0;')
      ->line('if (resp_len > 12 && memcmp(resp_buf, "HTTP/1.", 7) == 0) {')
      ->line('    status = atoi(resp_buf + 9);')
      ->line('}')
      ->line('hv_stores(result, "status", newSViv(status));')
      ->blank
      ->comment('Find body')
      ->line('const char *body_start = strstr(resp_buf, "\\r\\n\\r\\n");')
      ->if('body_start')
        ->line('body_start += 4;')
        ->line('hv_stores(result, "body", newSVpv(body_start, resp_len - (body_start - resp_buf)));')
      ->else
        ->line('hv_stores(result, "body", newSVpvs(""));')
      ->endif
      ->blank
      ->comment('Store headers')
      ->line('HV *headers = newHV();')
      ->line('hv_stores(result, "headers", newRV_noinc((SV *)headers));')
      ->blank
      ->comment('If callback provided, call it')
      ->if('cb')
        ->line('SPAGAIN;')
        ->line('ENTER; SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV *)result)));')
        ->line('PUTBACK;')
        ->line('call_sv(cb, G_DISCARD);')
        ->line('FREETMPS; LEAVE;')
        ->line('XSRETURN_EMPTY;')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV *)result));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_post {
    my ($class, $builder) = @_;

    $builder->comment('POST request - blocking or callback')
      ->comment('Usage: $ua->post($url, $body) or $ua->post($url, $body, sub { ... })')
      ->xs_function('xs_ua_post')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->post($url, $body, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->line('SV *cb = (items >= 4 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVCV) ? ST(3) : NULL;')
      ->blank
      ->comment('Build args for request')
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("POST")));')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_put {
    my ($class, $builder) = @_;

    $builder->comment('PUT request - blocking or callback')
      ->xs_function('xs_ua_put')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->put($url, $body, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->line('SV *cb = (items >= 4 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVCV) ? ST(3) : NULL;')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("PUT")));')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_patch {
    my ($class, $builder) = @_;

    $builder->comment('PATCH request - blocking or callback')
      ->xs_function('xs_ua_patch')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->patch($url, $body, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->line('SV *cb = (items >= 4 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVCV) ? ST(3) : NULL;')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("PATCH")));')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_delete {
    my ($class, $builder) = @_;

    $builder->comment('DELETE request - blocking or callback')
      ->xs_function('xs_ua_delete')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->delete($url, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *cb = (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) ? ST(2) : NULL;')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("DELETE")));')
      ->line('XPUSHs(url_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_head {
    my ($class, $builder) = @_;

    $builder->comment('HEAD request - blocking or callback')
      ->xs_function('xs_ua_head')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->head($url, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *cb = (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) ? ST(2) : NULL;')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("HEAD")));')
      ->line('XPUSHs(url_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_options {
    my ($class, $builder) = @_;

    $builder->comment('OPTIONS request - blocking or callback')
      ->xs_function('xs_ua_options')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->options($url, [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *cb = (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) ? ST(2) : NULL;')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("OPTIONS")));')
      ->line('XPUSHs(url_sv);')
      ->if('cb')
        ->line('XPUSHs(cb);')
      ->endif
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_request {
    my ($class, $builder) = @_;

    $builder->comment('General request - blocking or callback')
      ->comment('Usage: $ua->request($method, $url, [$body], [$cb])')
      ->xs_function('xs_ua_request')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->request($method, $url, [$body], [$cb])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *method_sv = ST(1);')
      ->line('SV *url_sv = ST(2);')
      ->line('SV *body_sv = NULL;')
      ->line('SV *cb = NULL;')
      ->blank
      ->comment('Determine if 4th arg is body or callback')
      ->if('items >= 4')
        ->if('SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVCV')
          ->line('cb = ST(3);')
        ->else
          ->line('body_sv = ST(3);')
          ->if('items >= 5 && SvROK(ST(4)) && SvTYPE(SvRV(ST(4))) == SVt_PVCV')
            ->line('cb = ST(4);')
          ->endif
        ->endif
      ->endif
      ->blank
      ->comment('Get UA slot and context')
      ->line('AV *self = (AV *)SvRV(self_sv);')
      ->line('SV **slot_sv = av_fetch(self, 0, 0);')
      ->line('if (!slot_sv || !SvOK(*slot_sv)) croak("Invalid UA object");')
      ->line('int slot = SvIV(*slot_sv);')
      ->line('UAContext *ctx = &ua_registry[slot];')
      ->blank
      ->comment('Parse URL')
      ->line('STRLEN url_len;')
      ->line('const char *url = SvPV(url_sv, url_len);')
      ->blank
      ->line('const char *scheme_end = strstr(url, "://");')
      ->line('if (!scheme_end) croak("Invalid URL");')
      ->blank
      ->line('int is_https = (scheme_end - url == 5 && memcmp(url, "https", 5) == 0);')
      ->line('const char *host_start = scheme_end + 3;')
      ->line('const char *host_end = host_start;')
      ->line('int port = is_https ? 443 : 80;')
      ->blank
      ->line('while (*host_end && *host_end != \':\' && *host_end != \'/\' && *host_end != \'?\') host_end++;')
      ->blank
      ->line('const char *p = host_end;')
      ->if('*host_end == \':\'')
        ->line('port = atoi(host_end + 1);')
        ->line('while (*p && *p != \'/\' && *p != \'?\') p++;')
      ->endif
      ->blank
      ->line('const char *path = (*p == \'/\') ? p : "/";')
      ->blank
      ->comment('Build request')
      ->line('STRLEN method_len;')
      ->line('const char *method = SvPV(method_sv, method_len);')
      ->blank
      ->line('char host_buf[256];')
      ->line('int host_len = host_end - host_start;')
      ->line('if (host_len > 255) host_len = 255;')
      ->line('memcpy(host_buf, host_start, host_len);')
      ->line('host_buf[host_len] = 0;')
      ->blank
      ->comment('Create socket and connect with cached DNS')
      ->line('int fd = socket(AF_INET, SOCK_STREAM, 0);')
      ->line('if (fd < 0) croak("socket() failed");')
      ->blank
      ->line('struct sockaddr_in addr;')
      ->line('memset(&addr, 0, sizeof(addr));')
      ->line('addr.sin_family = AF_INET;')
      ->line('addr.sin_port = htons(port);')
      ->if('!dns_lookup_cached(host_buf, &addr.sin_addr)')
        ->line('close(fd);')
        ->line('croak("DNS resolution failed for %s", host_buf);')
      ->endif
      ->blank
      ->if('connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0')
        ->line('close(fd);')
        ->line('croak("connect() failed");')
      ->endif
      ->blank
      ->comment('Build HTTP request string')
      ->line('char req_buf[8192];')
      ->line('int req_len = snprintf(req_buf, sizeof(req_buf),')
      ->line('    "%s %s HTTP/1.1\\r\\n"')
      ->line('    "Host: %s\\r\\n"')
      ->line('    "Connection: close\\r\\n"')
      ->line('    "User-Agent: Hypersonic/1.0\\r\\n",')
      ->line('    method, path, host_buf);')
      ->blank
      ->if('body_sv && SvOK(body_sv)')
        ->line('STRLEN body_len;')
        ->line('const char *body = SvPV(body_sv, body_len);')
        ->line('req_len += snprintf(req_buf + req_len, sizeof(req_buf) - req_len,')
        ->line('    "Content-Length: %zu\\r\\n\\r\\n", body_len);')
        ->line('if (req_len + body_len < sizeof(req_buf)) {')
        ->line('    memcpy(req_buf + req_len, body, body_len);')
        ->line('    req_len += body_len;')
        ->line('}')
      ->else
        ->line('req_len += snprintf(req_buf + req_len, sizeof(req_buf) - req_len, "\\r\\n");')
      ->endif
      ->blank
      ->comment('Send request')
      ->line('if (send(fd, req_buf, req_len, 0) < 0) {')
      ->line('    close(fd);')
      ->line('    croak("send() failed");')
      ->line('}')
      ->blank
      ->comment('Receive response')
      ->line('char resp_buf[65536];')
      ->line('int resp_len = 0;')
      ->line('int n;')
      ->line('while ((n = recv(fd, resp_buf + resp_len, sizeof(resp_buf) - resp_len - 1, 0)) > 0) {')
      ->line('    resp_len += n;')
      ->line('}')
      ->line('resp_buf[resp_len] = 0;')
      ->line('close(fd);')
      ->blank
      ->comment('Parse response')
      ->line('HV *result = newHV();')
      ->blank
      ->comment('Extract status code')
      ->line('int status = 0;')
      ->line('if (resp_len > 12 && memcmp(resp_buf, "HTTP/1.", 7) == 0) {')
      ->line('    status = atoi(resp_buf + 9);')
      ->line('}')
      ->line('hv_stores(result, "status", newSViv(status));')
      ->blank
      ->comment('Find body')
      ->line('const char *body_start = strstr(resp_buf, "\\r\\n\\r\\n");')
      ->if('body_start')
        ->line('body_start += 4;')
        ->line('hv_stores(result, "body", newSVpv(body_start, resp_len - (body_start - resp_buf)));')
      ->else
        ->line('hv_stores(result, "body", newSVpvs(""));')
      ->endif
      ->blank
      ->comment('Store headers')
      ->line('HV *headers = newHV();')
      ->line('hv_stores(result, "headers", newRV_noinc((SV *)headers));')
      ->blank
      ->comment('If callback provided, call it')
      ->if('cb')
        ->line('SPAGAIN;')
        ->line('ENTER; SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV *)result)));')
        ->line('PUTBACK;')
        ->line('call_sv(cb, G_DISCARD);')
        ->line('FREETMPS; LEAVE;')
        ->line('XSRETURN_EMPTY;')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV *)result));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

# gen_xs_tick moved to Hypersonic::UA::Async for proper header ordering

sub gen_xs_pending {
    my ($class, $builder) = @_;

    $builder->comment('Get count of pending async requests')
      ->xs_function('xs_ua_pending')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $ua->pending()");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('HV *ua_hv = (HV *)SvRV(self_sv);')
      ->blank
      ->comment('Get the _async_pending array')
      ->line('SV **pending_svp = hv_fetch(ua_hv, "_async_pending", 14, 0);')
      ->if('!pending_svp || !SvROK(*pending_svp)')
        ->line('ST(0) = sv_2mortal(newSViv(0));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('AV *pending_av = (AV *)SvRV(*pending_svp);')
      ->line('I32 pending = av_len(pending_av) + 1;')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(pending));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_async {
    my ($class, $builder) = @_;

    $builder->comment('Async GET - returns a Future')
      ->xs_function('xs_ua_get_async')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->get_async($url)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("GET")));')
      ->line('XPUSHs(url_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request_async", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_post_async {
    my ($class, $builder) = @_;

    $builder->comment('Async POST - returns a Future')
      ->xs_function('xs_ua_post_async')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->post_async($url, $body)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("POST")));')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request_async", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_put_async {
    my ($class, $builder) = @_;

    $builder->comment('Async PUT - returns a Future')
      ->xs_function('xs_ua_put_async')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->put_async($url, $body)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("PUT")));')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request_async", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_delete_async {
    my ($class, $builder) = @_;

    $builder->comment('Async DELETE - returns a Future')
      ->xs_function('xs_ua_delete_async')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->delete_async($url)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->blank
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("DELETE")));')
      ->line('XPUSHs(url_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_method("request_async", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = &PL_sv_undef;')
      ->if('count > 0')
        ->line('result = POPs;')
        ->line('SvREFCNT_inc(result);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_request_async {
    my ($class, $builder) = @_;

    $builder->comment('Async general request - returns a Future')
      ->xs_function('xs_ua_request_async')
      ->xs_preamble
      ->line('if (items < 3) croak("Usage: $ua->request_async($method, $url, [$body])");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *method_sv = ST(1);')
      ->line('SV *url_sv = ST(2);')
      ->line('SV *body_sv = (items >= 4) ? ST(3) : &PL_sv_undef;')
      ->blank
      ->comment('Create a Future')
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_pv("Hypersonic::Future::new", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *future = &PL_sv_undef;')
      ->if('count > 0')
        ->line('future = POPs;')
        ->line('SvREFCNT_inc(future);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->comment('Start async request via Hypersonic::UA::Async')
      ->comment('Pass self_sv so start_request can auto-tick')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(method_sv);')
      ->line('XPUSHs(url_sv);')
      ->line('XPUSHs(body_sv);')
      ->line('XPUSHs(future);')
      ->line('XPUSHs(self_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('count = call_pv("Hypersonic::UA::Async::start_request", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('int async_slot = -1;')
      ->if('count > 0')
        ->line('async_slot = POPi;')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->comment('Store async slot in UA for polling')
      ->if('async_slot >= 0')
        ->comment('Associate slot with self for run() to find')
        ->line('HV *ua_hv = (HV *)SvRV(self_sv);')
        ->line('AV *pending_av;')
        ->line('SV **pending_svp = hv_fetch(ua_hv, "_async_pending", 14, 0);')
        ->if('pending_svp && SvROK(*pending_svp)')
          ->line('pending_av = (AV *)SvRV(*pending_svp);')
        ->else
          ->line('pending_av = newAV();')
          ->line('hv_store(ua_hv, "_async_pending", 14, newRV_noinc((SV *)pending_av), 0);')
        ->endif
        ->line('av_push(pending_av, newSViv(async_slot));')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(future);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_run {
    my ($class, $builder) = @_;

    $builder->comment('Run all pending async requests to completion')
      ->xs_function('xs_ua_run')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $ua->run()");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->blank
      ->comment('Poll until all pending requests complete')
      ->line('int iterations = 0;')
      ->line('int max_iterations = 10000;')
      ->blank
      ->line('SPAGAIN;')
      ->line('while (iterations++ < max_iterations) {')
      ->line('    ENTER; SAVETMPS;')
      ->line('    PUSHMARK(SP);')
      ->line('    XPUSHs(self_sv);')
      ->line('    PUTBACK;')
      ->blank
      ->line('    call_method("pending", G_SCALAR);')
      ->line('    SPAGAIN;')
      ->blank
      ->line('    int pending = POPi;')
      ->line('    PUTBACK;')
      ->line('    FREETMPS; LEAVE;')
      ->blank
      ->line('    if (pending == 0) break;')
      ->blank
      ->comment('    Tick once')
      ->line('    ENTER; SAVETMPS;')
      ->line('    PUSHMARK(SP);')
      ->line('    XPUSHs(self_sv);')
      ->line('    PUTBACK;')
      ->line('    call_method("tick", G_DISCARD);')
      ->line('    FREETMPS; LEAVE;')
      ->line('}')
      ->blank
      ->xs_return('0')
      ->xs_end
      ->blank;
}

sub gen_xs_run_one {
    my ($class, $builder) = @_;

    $builder->comment('Run one async request to completion')
      ->xs_function('xs_ua_run_one')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: $ua->run_one($future)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->line('SV *future_sv = ST(1);')
      ->blank
      ->comment('Poll until this specific future resolves')
      ->line('int iterations = 0;')
      ->line('int max_iterations = 10000;')
      ->blank
      ->line('SPAGAIN;')
      ->line('while (iterations++ < max_iterations) {')
      ->comment('    Check if future is done')
      ->line('    ENTER; SAVETMPS;')
      ->line('    PUSHMARK(SP);')
      ->line('    XPUSHs(future_sv);')
      ->line('    PUTBACK;')
      ->blank
      ->line('    call_method("is_ready", G_SCALAR);')
      ->line('    SPAGAIN;')
      ->blank
      ->line('    int ready = POPi;')
      ->line('    PUTBACK;')
      ->line('    FREETMPS; LEAVE;')
      ->blank
      ->line('    if (ready) break;')
      ->blank
      ->comment('    Tick once')
      ->line('    ENTER; SAVETMPS;')
      ->line('    PUSHMARK(SP);')
      ->line('    XPUSHs(self_sv);')
      ->line('    PUTBACK;')
      ->line('    call_method("tick", G_DISCARD);')
      ->line('    FREETMPS; LEAVE;')
      ->line('}')
      ->blank
      ->comment('Return the future result')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(future_sv);')
      ->line('PUTBACK;')
      ->blank
      ->line('call_method("get", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = POPs;')
      ->line('SvREFCNT_inc(result);')
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_parallel {
    my ($class, $builder) = @_;

    $builder->comment('Run multiple requests in parallel, wait for all')
      ->xs_function('xs_ua_parallel')
      ->xs_preamble
      ->line('int i;')
      ->line('if (items < 2) croak("Usage: $ua->parallel(@futures)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->blank
      ->comment('Collect futures')
      ->line('AV *futures = newAV();')
      ->line('for (i = 1; i < items; i++) {')
      ->line('    av_push(futures, SvREFCNT_inc(ST(i)));')
      ->line('}')
      ->blank
      ->comment('Create needs_all future')
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('for (i = 0; i <= av_len(futures); i++) {')
      ->line('    SV **f = av_fetch(futures, i, 0);')
      ->line('    if (f && *f) XPUSHs(*f);')
      ->line('}')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_pv("Hypersonic::Future::needs_all", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *combined = &PL_sv_undef;')
      ->if('count > 0')
        ->line('combined = POPs;')
        ->line('SvREFCNT_inc(combined);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->comment('Run until combined future resolves')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(combined);')
      ->line('PUTBACK;')
      ->blank
      ->line('call_method("run_one", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = POPs;')
      ->line('SvREFCNT_inc(result);')
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('SvREFCNT_dec((SV *)futures);')
      ->line('SvREFCNT_dec(combined);')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_race {
    my ($class, $builder) = @_;

    $builder->comment('Run multiple requests in parallel, return first to complete')
      ->xs_function('xs_ua_race')
      ->xs_preamble
      ->line('int i;')
      ->line('if (items < 2) croak("Usage: $ua->race(@futures)");')
      ->blank
      ->line('SV *self_sv = ST(0);')
      ->blank
      ->comment('Collect futures')
      ->line('AV *futures = newAV();')
      ->line('for (i = 1; i < items; i++) {')
      ->line('    av_push(futures, SvREFCNT_inc(ST(i)));')
      ->line('}')
      ->blank
      ->comment('Create needs_any future')
      ->line('SPAGAIN;')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('for (i = 0; i <= av_len(futures); i++) {')
      ->line('    SV **f = av_fetch(futures, i, 0);')
      ->line('    if (f && *f) XPUSHs(*f);')
      ->line('}')
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_pv("Hypersonic::Future::needs_any", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *combined = &PL_sv_undef;')
      ->if('count > 0')
        ->line('combined = POPs;')
        ->line('SvREFCNT_inc(combined);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->comment('Run until combined future resolves')
      ->line('ENTER; SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(self_sv);')
      ->line('XPUSHs(combined);')
      ->line('PUTBACK;')
      ->blank
      ->line('call_method("run_one", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->line('SV *result = POPs;')
      ->line('SvREFCNT_inc(result);')
      ->blank
      ->line('PUTBACK;')
      ->line('FREETMPS; LEAVE;')
      ->blank
      ->line('SvREFCNT_dec((SV *)futures);')
      ->line('SvREFCNT_dec(combined);')
      ->blank
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

#############################################################################
# Stub methods for disabled features (provide helpful error messages)
#############################################################################

# These are installed as Perl methods when the feature is not compiled
# They will be overwritten by XS if the feature IS compiled

sub _feature_not_enabled {
    my ($method, $feature) = @_;
    return sub {
        Carp::croak("$method() requires: Hypersonic::UA->compile($feature => 1)");
    };
}

# Install stubs for async methods (only if not compiled)
sub _install_stubs {
    my ($class) = @_;

    # Async methods require async => 1
    unless ($FEATURES{needs_async}) {
        no strict 'refs';
        *{"${class}::get_async"}     = _feature_not_enabled('get_async', 'async');
        *{"${class}::post_async"}    = _feature_not_enabled('post_async', 'async');
        *{"${class}::put_async"}     = _feature_not_enabled('put_async', 'async');
        *{"${class}::delete_async"}  = _feature_not_enabled('delete_async', 'async');
        *{"${class}::request_async"} = _feature_not_enabled('request_async', 'async');
        *{"${class}::tick"}          = _feature_not_enabled('tick', 'async');
        *{"${class}::run"}           = _feature_not_enabled('run', 'async');
        *{"${class}::run_one"}       = _feature_not_enabled('run_one', 'async');
        *{"${class}::pending"}       = _feature_not_enabled('pending', 'async');
    }

    # Parallel methods require parallel => 1
    unless ($FEATURES{needs_parallel}) {
        no strict 'refs';
        *{"${class}::parallel"} = _feature_not_enabled('parallel', 'parallel');
        *{"${class}::race"}     = _feature_not_enabled('race', 'parallel');
    }
}

# Call _install_stubs after compile() to set up error handlers
{
    my $orig_compile = \&compile;
    no warnings 'redefine';
    *compile = sub {
        my $result = $orig_compile->(@_);
        __PACKAGE__->_install_stubs() if $result;
        return $result;
    };
}

1;

__END__

=head1 NAME

Hypersonic::UA - High-performance JIT-compiled HTTP user agent

=head1 SYNOPSIS

    use Hypersonic::UA;

    # Compile with minimal features (blocking only)
    Hypersonic::UA->compile();

    # Or compile with async support
    Hypersonic::UA->compile(async => 1);

    # Or compile with all features
    Hypersonic::UA->compile(full => 1);

    # Create UA instance
    my $ua = Hypersonic::UA->new();

    # Blocking requests
    my $res = $ua->get('http://example.com/api');
    my $res = $ua->post('http://example.com/api', '{"data":"value"}');
    my $res = $ua->put('http://example.com/api', $body);
    my $res = $ua->delete('http://example.com/api');

    # Response is a hashref
    print $res->{status};   # 200
    print $res->{body};     # Response body

    # Async requests (requires async => 1)
    # No manual tick() needed - event loop runs automatically!
    my $future = $ua->get_async('http://example.com/api');

    # Chain with callbacks
    $future->then(sub {
        my ($response) = @_;
        print $response;
    });

    # Or fetch multiple URLs concurrently
    my @futures = map { $ua->get_async($_) } @urls;
    my $all = Hypersonic::Future->needs_all(@futures);
    my @results = $all->result;  # Automatically completes all requests

=head1 DESCRIPTION

C<Hypersonic::UA> is a high-performance HTTP client using JIT-compiled XS code.
It supports both blocking and async operations with connection pooling and
keep-alive support.

=head1 COMPILATION OPTIONS

    Hypersonic::UA->compile(%options);

=over 4

=item async => 1

Enable async methods: C<get_async>, C<post_async>, C<tick>, C<run>, C<pending>.

=item parallel => 1

Enable parallel methods: C<parallel>, C<race>. Implies C<async>.

=item tls => 1

Enable HTTPS/TLS support.

=item http2 => 1

Enable HTTP/2 protocol support.

=item compression => 1

Enable gzip/deflate response decompression.

=item cookie_jar => 1

Enable automatic cookie handling.

=item redirects => 1

Enable automatic redirect following.

=item full => 1

Enable all features.

=item cache_dir => $path

Directory for caching compiled XS code.

=back

=head1 METHODS

=head2 new

    my $ua = Hypersonic::UA->new(%options);

Create a new UA instance.

=head2 get

    my $res = $ua->get($url);

Perform a blocking GET request.

=head2 post

    my $res = $ua->post($url, $body);

Perform a blocking POST request.

=head2 put

    my $res = $ua->put($url, $body);

Perform a blocking PUT request.

=head2 delete

    my $res = $ua->delete($url);

Perform a blocking DELETE request.

=head2 head

    my $res = $ua->head($url);

Perform a blocking HEAD request.

=head2 patch

    my $res = $ua->patch($url, $body);

Perform a blocking PATCH request.

=head2 options

    my $res = $ua->options($url);

Perform a blocking OPTIONS request.

=head2 request

    my $res = $ua->request($method, $url, $body);

Perform a generic blocking request.

=head1 ASYNC METHODS

These require C<< async => 1 >> at compile time.

B<Note:> Async requests are automatically processed - you do NOT need to
call C<tick()> manually. The event loop runs automatically when you:

=over 4

=item * Start a new async request (C<get_async>, C<post_async>, etc.)

=item * Access a Future (C<is_ready>, C<result>, C<then>, etc.)

=back

=head2 get_async

    my $future = $ua->get_async($url);

    # Requests are processed automatically!
    # Just use the Future when you need the result:
    $future->then(sub {
        my ($response) = @_;
        print $response;
    });

Start an async GET request. Returns a Future that resolves with the response.

=head2 post_async

    my $future = $ua->post_async($url, $body);

Start an async POST request. Returns a Future.

=head2 tick

    $ua->tick();

Manually process pending async requests. B<Usually not needed> - the event
loop runs automatically. Returns remaining pending count (0 when all complete).

This method now loops internally until all requests complete or no progress
is made, so a single call is sufficient.

=head2 run

    $ua->run();

Run event loop until all pending requests complete. B<Usually not needed> -
prefer using Futures directly which auto-tick.

=head2 pending

    my $count = $ua->pending();

Return count of pending async requests.

=head1 PARALLEL METHODS

These require C<< parallel => 1 >> at compile time.

=head2 parallel

    my @results = $ua->parallel(@urls);

Fetch multiple URLs in parallel, wait for all to complete.

=head2 race

    my $result = $ua->race(@urls);

Fetch multiple URLs, return first to complete.

=head1 PERFORMANCE

C<Hypersonic::UA> is designed for high-throughput async HTTP operations.
Key performance features:

=head2 Connection Pooling

Connections are automatically pooled and reused with HTTP keep-alive.
This eliminates the TCP handshake overhead for subsequent requests to
the same host, significantly improving throughput.

=head2 Event-Driven I/O

Uses the best available event backend (kqueue on macOS/BSD, epoll on Linux)
for efficient non-blocking I/O with minimal syscall overhead.

=head2 JIT-Compiled XS

All hot paths are JIT-compiled to XS/C code, avoiding Perl interpreter
overhead in the request processing loop.

=head2 Benchmark Example

    use Hypersonic::Future;
    use Hypersonic::UA;
    use Time::HiRes qw(time);

    Hypersonic::Future->compile;
    Hypersonic::UA->compile(async => 1);

    my $ua = Hypersonic::UA->new();
    my @urls = ('http://127.0.0.1:8080/') x 1000;

    my $start = time();

    # Start all requests - event loop runs automatically!
    my @futures = map { $ua->get_async($_) } @urls;

    # Combine futures - when accessed, remaining requests complete
    my $all = Hypersonic::Future->needs_all(@futures);

    # Get results - this triggers any remaining processing
    my @responses = $all->result;

    my $elapsed = time() - $start;
    printf "%d requests in %.3fs (%.0f req/sec)\n",
        scalar(@responses), $elapsed, scalar(@responses) / $elapsed;

Typical results on modern hardware:

=over 4

=item * B<100,000+ requests/sec> to localhost

=item * B<Connection reuse> via keep-alive pooling

=item * B<Minimal memory overhead> with slot-based context management

=back

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
