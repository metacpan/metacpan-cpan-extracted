package Hypersonic::UA::Async;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# Use Hypersonic::Event for backend detection
use Hypersonic::Event;

# Maximum concurrent async contexts
use constant MAX_ASYNC_CONTEXTS => 1024;

# Async context states
use constant {
    STATE_CONNECTING => 0,
    STATE_TLS        => 1,
    STATE_SENDING    => 2,
    STATE_RECEIVING  => 3,
    STATE_DONE       => 4,
    STATE_ERROR      => 5,
    STATE_CANCELLED  => 6,
};

# Poll wait events
use constant {
    WAIT_NONE  => 0,
    WAIT_READ  => 1,
    WAIT_WRITE => 2,
};

# Object slots (array-based for performance)
use constant {
    SLOT_ID     => 0,
    SLOT_UA     => 1,
    SLOT_FUTURE => 2,
};

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    $class->gen_async_context_registry($builder, $opts);
    $class->gen_async_poll_one($builder);
    $class->gen_async_advance_state($builder);
    $class->gen_xs_start_request($builder);
    $class->gen_xs_poll($builder);
    $class->gen_xs_poll_batch($builder, $opts);
    $class->gen_xs_get_fd($builder);
    $class->gen_xs_get_events($builder);
    $class->gen_xs_cancel($builder);
    $class->gen_xs_cleanup($builder);
    $class->gen_xs_get_future($builder);
    $class->gen_xs_get_state($builder);
    $class->gen_xs_get_result($builder);
    
    # Generate tick here after all async structures/headers are defined
    $class->gen_xs_tick($builder, $opts);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Async::start_request' => { source => 'xs_async_start_request', is_xs_native => 1 },
        'Hypersonic::UA::Async::poll'          => { source => 'xs_async_poll', is_xs_native => 1 },
        'Hypersonic::UA::Async::poll_batch'    => { source => 'xs_async_poll_batch', is_xs_native => 1 },
        'Hypersonic::UA::Async::get_fd'        => { source => 'xs_async_get_fd', is_xs_native => 1 },
        'Hypersonic::UA::Async::get_events'    => { source => 'xs_async_get_events', is_xs_native => 1 },
        'Hypersonic::UA::Async::cancel'        => { source => 'xs_async_cancel', is_xs_native => 1 },
        'Hypersonic::UA::Async::cleanup'       => { source => 'xs_async_cleanup', is_xs_native => 1 },
        'Hypersonic::UA::Async::get_future'    => { source => 'xs_async_get_future', is_xs_native => 1 },
        'Hypersonic::UA::Async::get_state'     => { source => 'xs_async_get_state', is_xs_native => 1 },
        'Hypersonic::UA::Async::get_result'    => { source => 'xs_async_get_result', is_xs_native => 1 },
        'Hypersonic::UA::tick'                 => { source => 'xs_ua_tick', is_xs_native => 1 },
    };
}

sub gen_async_context_registry {
    my ($class, $builder, $opts) = @_;

    # Get the best event backend for this platform
    my $backend_name = Hypersonic::Event->best_backend;
    my $event_backend = Hypersonic::Event->backend($backend_name);
    
    # Store backend for other methods to use
    $opts->{event_backend} = $event_backend;
    $opts->{event_backend_name} = $backend_name;

    # Add required includes for networking
    $builder->line('#include <sys/socket.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <netdb.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->line('#include <unistd.h>');
    
    # Add event backend includes and defines
    $builder->line($event_backend->includes)
      ->line($event_backend->defines)
      ->blank;
    
    $builder->line('#define MAX_ASYNC_CONTEXTS 1024')
      ->line('#ifndef MAX_EVENTS')
      ->line('#define MAX_EVENTS 256')
      ->line('#endif')
      ->blank
      ->line('#define ASYNC_STATE_CONNECTING 0')
      ->line('#define ASYNC_STATE_TLS        1')
      ->line('#define ASYNC_STATE_SENDING    2')
      ->line('#define ASYNC_STATE_RECEIVING  3')
      ->line('#define ASYNC_STATE_DONE       4')
      ->line('#define ASYNC_STATE_ERROR      5')
      ->line('#define ASYNC_STATE_CANCELLED  6')
      ->blank
      ->line('#define ASYNC_WAIT_NONE  0')
      ->line('#define ASYNC_WAIT_READ  1')
      ->line('#define ASYNC_WAIT_WRITE 2')
      ->blank
      ->line('typedef struct {')
      ->line('    int fd;')
      ->line('    void *ssl;')  # Use void* instead of SSL* to avoid OpenSSL dependency
      ->line('    int state;')
      ->line('    int tls;')
      ->line('    char *host;')
      ->line('    int port;')
      ->line('    char *request;')
      ->line('    size_t request_len;')
      ->line('    size_t request_sent;')
      ->line('    char *recv_buffer;')
      ->line('    size_t recv_buffer_len;')
      ->line('    size_t recv_buffer_cap;')
      ->line('    SV *future_sv;')
      ->line('    SV *callback;')
      ->line('    time_t deadline;')
      ->line('    char *error;')
      ->line('    int in_use;')
      ->line('} AsyncContext;')
      ->blank
      ->line('static AsyncContext async_registry[MAX_ASYNC_CONTEXTS];')
      ->line('static int async_ev_fd = -1;')  # event loop fd (kqueue/epoll) for batched polling
      ->blank
      ->comment('Async connection pool for keep-alive')
      ->line('#define ASYNC_POOL_SIZE 512')
      ->line('typedef struct {')
      ->line('    int fd;')
      ->line('    char host[256];')
      ->line('    int port;')
      ->line('    time_t expires;')
      ->line('} AsyncPooledConn;')
      ->blank
      ->line('static AsyncPooledConn async_conn_pool[ASYNC_POOL_SIZE];')
      ->blank
      ->comment('Get a pooled connection')
      ->line('static int async_pool_get(const char *host, int port) {')
      ->line('    int i;')
      ->line('    time_t now = time(NULL);')
      ->line('    for (i = 0; i < ASYNC_POOL_SIZE; i++) {')
      ->line('        if (async_conn_pool[i].fd > 0 && async_conn_pool[i].port == port &&')
      ->line('            strcmp(async_conn_pool[i].host, host) == 0 && async_conn_pool[i].expires > now) {')
      ->line('            int fd = async_conn_pool[i].fd;')
      ->line('            async_conn_pool[i].fd = 0;')
      ->line('            return fd;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank
      ->comment('Return connection to pool (10 second keep-alive)')
      ->line('static void async_pool_put(int fd, const char *host, int port) {')
      ->line('    int i;')
      ->line('    if (fd < 0) return;')
      ->line('    time_t now = time(NULL);')
      ->line('    for (i = 0; i < ASYNC_POOL_SIZE; i++) {')
      ->line('        if (async_conn_pool[i].fd <= 0 || async_conn_pool[i].expires <= now) {')
      ->line('            if (async_conn_pool[i].fd > 0) close(async_conn_pool[i].fd);')
      ->line('            async_conn_pool[i].fd = fd;')
      ->line('            strncpy(async_conn_pool[i].host, host, 255);')
      ->line('            async_conn_pool[i].host[255] = 0;')
      ->line('            async_conn_pool[i].port = port;')
      ->line('            async_conn_pool[i].expires = now + 10;')
      ->line('            return;')
      ->line('        }')
      ->line('    }')
      ->line('    close(fd);')
      ->line('}')
      ->blank
      ->line('static int async_alloc_slot(void) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_ASYNC_CONTEXTS; i++) {')
      ->line('        if (!async_registry[i].in_use) {')
      ->line('            memset(&async_registry[i], 0, sizeof(AsyncContext));')
      ->line('            async_registry[i].in_use = 1;')
      ->line('            async_registry[i].fd = -1;')
      ->line('            async_registry[i].future_sv = NULL;')
      ->line('            return i;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank
      ->line('static void async_free_slot(int slot) {')
      ->line('    if (slot >= 0 && slot < MAX_ASYNC_CONTEXTS) {')
      ->line('        AsyncContext *ctx = &async_registry[slot];')
      ->comment('        Return connection to pool if successful')
      ->line('        if (ctx->fd >= 0 && ctx->state == ASYNC_STATE_DONE && ctx->host) {')
      ->line('            async_pool_put(ctx->fd, ctx->host, ctx->port);')
      ->line('            ctx->fd = -1;')
      ->line('        }')
      ->line('        if (ctx->fd >= 0) close(ctx->fd);')
      ->line('        if (ctx->host) free(ctx->host);')
      ->line('        if (ctx->request) free(ctx->request);')
      ->line('        if (ctx->recv_buffer) free(ctx->recv_buffer);')
      ->line('        if (ctx->error) free(ctx->error);')
      ->line('        if (ctx->callback) SvREFCNT_dec(ctx->callback);')
      ->line('        if (ctx->future_sv) SvREFCNT_dec(ctx->future_sv);')
      ->line('        memset(ctx, 0, sizeof(AsyncContext));')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_async_poll_one {
    my ($class, $builder) = @_;

    $builder->comment('Poll a single async context, return events needed')
      ->line('static int async_poll_one(int slot) {')
      ->line('    if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) return ASYNC_WAIT_NONE;')
      ->line('    AsyncContext *ctx = &async_registry[slot];')
      ->line('    if (!ctx->in_use) return ASYNC_WAIT_NONE;')
      ->blank
      ->line('    switch (ctx->state) {')
      ->line('        case ASYNC_STATE_CONNECTING:')
      ->line('            return ASYNC_WAIT_WRITE;')
      ->blank
      ->line('        case ASYNC_STATE_TLS:')
      ->line('            return ASYNC_WAIT_WRITE;')
      ->blank
      ->line('        case ASYNC_STATE_SENDING: {')
      ->line('            ssize_t n = send(ctx->fd, ctx->request + ctx->request_sent,')
      ->line('                             ctx->request_len - ctx->request_sent, MSG_DONTWAIT);')
      ->line('            if (n > 0) {')
      ->line('                ctx->request_sent += n;')
      ->line('                if (ctx->request_sent >= ctx->request_len) {')
      ->line('                    ctx->state = ASYNC_STATE_RECEIVING;')
      ->line('                    return ASYNC_WAIT_READ;')
      ->line('                }')
      ->line('            } else if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {')
      ->line('                ctx->state = ASYNC_STATE_ERROR;')
      ->line('                ctx->error = strdup("send failed");')
      ->line('                return ASYNC_WAIT_NONE;')
      ->line('            }')
      ->line('            return ASYNC_WAIT_WRITE;')
      ->line('        }')
      ->blank
      ->line('        case ASYNC_STATE_RECEIVING: {')
      ->line('            if (!ctx->recv_buffer) {')
      ->line('                ctx->recv_buffer_cap = 8192;')
      ->line('                ctx->recv_buffer = (char *)malloc(ctx->recv_buffer_cap);')
      ->line('                ctx->recv_buffer_len = 0;')
      ->line('            }')
      ->blank
      ->line('            if (ctx->recv_buffer_len >= ctx->recv_buffer_cap - 1) {')
      ->line('                ctx->recv_buffer_cap *= 2;')
      ->line('                ctx->recv_buffer = (char *)realloc(ctx->recv_buffer, ctx->recv_buffer_cap);')
      ->line('            }')
      ->blank
      ->line('            ssize_t n = recv(ctx->fd, ctx->recv_buffer + ctx->recv_buffer_len,')
      ->line('                             ctx->recv_buffer_cap - ctx->recv_buffer_len - 1, MSG_DONTWAIT);')
      ->line('            if (n > 0) {')
      ->line('                ctx->recv_buffer_len += n;')
      ->line('                ctx->recv_buffer[ctx->recv_buffer_len] = 0;')
      ->blank
      ->comment('                Check if response is complete (Content-Length or connection close)')
      ->line('                char *headers_end = strstr(ctx->recv_buffer, "\\r\\n\\r\\n");')
      ->line('                if (headers_end) {')
      ->line('                    char *body_start = headers_end + 4;')
      ->line('                    size_t body_received = ctx->recv_buffer_len - (body_start - ctx->recv_buffer);')
      ->blank
      ->comment('                    Parse Content-Length')
      ->line('                    char *cl = strcasestr(ctx->recv_buffer, "Content-Length:");')
      ->line('                    if (cl && cl < headers_end) {')
      ->line('                        size_t content_length = atol(cl + 15);')
      ->line('                        if (body_received >= content_length) {')
      ->line('                            ctx->state = ASYNC_STATE_DONE;')
      ->line('                            return ASYNC_WAIT_NONE;')
      ->line('                        }')
      ->line('                    } else {')
      ->comment('                        No Content-Length - check for Transfer-Encoding: chunked')
      ->line('                        char *te = strcasestr(ctx->recv_buffer, "Transfer-Encoding:");')
      ->line('                        if (te && te < headers_end && strcasestr(te, "chunked")) {')
      ->comment('                            Check for chunked end marker')
      ->line('                            if (strstr(body_start, "\\r\\n0\\r\\n\\r\\n") || ')
      ->line('                                (body_received >= 5 && memcmp(body_start, "0\\r\\n\\r\\n", 5) == 0)) {')
      ->line('                                ctx->state = ASYNC_STATE_DONE;')
      ->line('                                return ASYNC_WAIT_NONE;')
      ->line('                            }')
      ->line('                        }')
      ->line('                    }')
      ->line('                }')
      ->blank
      ->line('                return ASYNC_WAIT_READ;')
      ->line('            } else if (n == 0) {')
      ->line('                ctx->state = ASYNC_STATE_DONE;')
      ->line('                return ASYNC_WAIT_NONE;')
      ->line('            } else if (errno != EAGAIN && errno != EWOULDBLOCK) {')
      ->line('                ctx->state = ASYNC_STATE_ERROR;')
      ->line('                ctx->error = strdup("recv failed");')
      ->line('                return ASYNC_WAIT_NONE;')
      ->line('            }')
      ->line('            return ASYNC_WAIT_READ;')
      ->line('        }')
      ->blank
      ->line('        case ASYNC_STATE_DONE:')
      ->line('        case ASYNC_STATE_ERROR:')
      ->line('        case ASYNC_STATE_CANCELLED:')
      ->line('            return ASYNC_WAIT_NONE;')
      ->line('    }')
      ->blank
      ->line('    return ASYNC_WAIT_NONE;')
      ->line('}')
      ->blank;
}

sub gen_async_advance_state {
    my ($class, $builder) = @_;
    
    $builder->comment('Advance state for a single slot (check connect, send, recv)')
      ->line('static int async_advance_state(int slot) {')
      ->line('    if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) return ASYNC_WAIT_NONE;')
      ->line('    AsyncContext *ctx = &async_registry[slot];')
      ->line('    if (!ctx->in_use) return ASYNC_WAIT_NONE;')
      ->blank
      ->line('    if (ctx->state == ASYNC_STATE_CONNECTING) {')
      ->line('        int err = 0;')
      ->line('        socklen_t errlen = sizeof(err);')
      ->line('        getsockopt(ctx->fd, SOL_SOCKET, SO_ERROR, &err, &errlen);')
      ->line('        if (err == 0) {')
      ->line('            ctx->state = ASYNC_STATE_SENDING;')
      ->line('        } else {')
      ->line('            ctx->state = ASYNC_STATE_ERROR;')
      ->line('            ctx->error = strdup("connect failed");')
      ->line('            return ASYNC_WAIT_NONE;')
      ->line('        }')
      ->line('    }')
      ->blank
      ->line('    return async_poll_one(slot);')
      ->line('}')
      ->blank;
}

sub gen_xs_poll_batch {
    my ($class, $builder, $opts) = @_;

    my $event_backend = $opts->{event_backend};
    my $backend_name = $opts->{event_backend_name};

    # Check if this backend supports the slot API (kqueue, epoll)
    my $use_advanced = $backend_name =~ /^(kqueue|epoll)$/;

    $builder->comment("Batch poll all pending slots using $backend_name")
      ->xs_function('xs_async_poll_batch')
      ->xs_preamble
      ->line('int i;')
      ->line('int slot_count;')
      ->line('int registered;')
      ->line('int nev;')
      ->line('AV *ready;');

    # Add event struct declaration for advanced backends (C89 compliance)
    if ($use_advanced) {
        my $event_struct = $event_backend->event_struct;
        $builder->line("struct $event_struct events[MAX_EVENTS];");
    }

    $builder->line('if (items < 1) croak("Usage: poll_batch(@slots)");')
      ->blank;
    
    if ($use_advanced) {
        # Create event loop if needed
        $builder->comment('Create event loop if not exists')
          ->line('if (async_ev_fd < 0) {');
        
        # Use the backend's gen_create_loop method
        $event_backend->gen_create_loop($builder, 'async_ev_fd');
        
        $builder->line('}')
          ->blank;
        
        # Collect slots and register with event loop
        $builder->comment('Collect all pending slots and register with event loop')
          ->line('slot_count = items;')
          ->line('registered = 0;')
          ->blank
          ->line('for (i = 0; i < slot_count; i++) {')
          ->line('    int slot = SvIV(ST(i));')
          ->line('    if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) continue;')
          ->line('    AsyncContext *ctx = &async_registry[slot];')
          ->line('    if (!ctx->in_use || ctx->fd < 0) continue;')
          ->blank
          ->line('    int events = async_poll_one(slot);')
          ->line('    if (events == ASYNC_WAIT_NONE) continue;')
          ->blank;
        
        # Add for read or write based on what we need
        $builder->line('    if (events == ASYNC_WAIT_READ) {');
        $event_backend->gen_add_with_slot($builder, 'async_ev_fd', 'ctx->fd', 'slot', 'read');
        $builder->line('    } else {');
        $event_backend->gen_add_with_slot($builder, 'async_ev_fd', 'ctx->fd', 'slot', 'write');
        $builder->line('    }')
          ->line('    registered++;')
          ->line('}')
          ->blank;
        
        # Wait for events (events array already declared at top for C89 compliance)
        $builder->comment('Wait for events (short timeout for responsiveness)');
        
        # Use gen_wait_once (no loop control statements)
        $event_backend->gen_wait_once($builder, 'async_ev_fd', 'events', 'nev', '1');  # 1ms timeout
        
        # Process ready events
        $builder->blank
          ->comment('Process ready events')
          ->line('ready = newAV();')
          ->line('for (i = 0; i < nev; i++) {');
        
        # Get slot from event
        $event_backend->gen_get_slot($builder, 'events', 'i', 'slot');
        
        $builder->line('    if (slot >= 0 && slot < MAX_ASYNC_CONTEXTS) {')
          ->line('        int result = async_advance_state(slot);')
          ->line('        if (result == ASYNC_WAIT_NONE) {')
          ->line('            av_push(ready, newSViv(slot));')
          ->line('        }')
          ->line('    }')
          ->line('}')
          ->blank
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV *)ready));')
          ->xs_return('1')
          ->xs_end
          ->blank;
    } else {
        # Fallback to select-based implementation for other backends
        $builder->comment('Fallback to select() for portability')
          ->line('AV *ready = newAV();')
          ->line('for (i = 0; i < items; i++) {')
          ->line('    int slot = SvIV(ST(i));')
          ->line('    if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) continue;')
          ->line('    AsyncContext *ctx = &async_registry[slot];')
          ->line('    if (!ctx->in_use || ctx->fd < 0) continue;')
          ->blank
          ->line('    int events = async_poll_one(slot);')
          ->line('    if (events == ASYNC_WAIT_NONE) {')
          ->line('        av_push(ready, newSViv(slot));')
          ->line('        continue;')
          ->line('    }')
          ->blank
          ->comment('Check readiness with select')
          ->line('    fd_set rfds, wfds;')
          ->line('    FD_ZERO(&rfds); FD_ZERO(&wfds);')
          ->line('    if (events == ASYNC_WAIT_READ) FD_SET(ctx->fd, &rfds);')
          ->line('    if (events == ASYNC_WAIT_WRITE) FD_SET(ctx->fd, &wfds);')
          ->line('    struct timeval tv = {0, 0};')
          ->line('    int sel = select(ctx->fd + 1, &rfds, &wfds, NULL, &tv);')
          ->line('    if (sel > 0) {')
          ->line('        int result = async_advance_state(slot);')
          ->line('        if (result == ASYNC_WAIT_NONE) {')
          ->line('            av_push(ready, newSViv(slot));')
          ->line('        }')
          ->line('    }')
          ->line('}')
          ->blank
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV *)ready));')
          ->xs_return('1')
          ->xs_end
          ->blank;
    }
}

sub gen_xs_start_request {
    my ($class, $builder) = @_;

    $builder->comment('Start an async request')
      ->xs_function('xs_async_start_request')
      ->xs_preamble
      ->line('if (items < 5) croak("Usage: start_request($method, $url, $body, $future_or_cb, $ua_sv)");')
      ->blank
      ->line('SV *method_sv = ST(0);')
      ->line('SV *url_sv = ST(1);')
      ->line('SV *body_sv = ST(2);')
      ->line('SV *future_or_cb = ST(3);')
      ->line('SV *ua_sv = ST(4);')
      ->blank
      ->line('int slot = async_alloc_slot();')
      ->line('if (slot < 0) croak("Too many async requests");')
      ->blank
      ->line('AsyncContext *ctx = &async_registry[slot];')
      ->blank
      ->comment('Parse URL')
      ->line('STRLEN url_len;')
      ->line('const char *url = SvPV(url_sv, url_len);')
      ->blank
      ->line('const char *scheme_end = strstr(url, "://");')
      ->line('if (!scheme_end) {')
      ->line('    async_free_slot(slot);')
      ->line('    croak("Invalid URL");')
      ->line('}')
      ->blank
      ->line('ctx->tls = (scheme_end - url == 5 && memcmp(url, "https", 5) == 0);')
      ->blank
      ->line('const char *host_start = scheme_end + 3;')
      ->line('const char *host_end = host_start;')
      ->line('ctx->port = ctx->tls ? 443 : 80;')
      ->blank
      ->line('while (*host_end && *host_end != \':\' && *host_end != \'/\') host_end++;')
      ->blank
      ->line('int host_len = host_end - host_start;')
      ->line('ctx->host = (char *)malloc(host_len + 1);')
      ->line('memcpy(ctx->host, host_start, host_len);')
      ->line('ctx->host[host_len] = 0;')
      ->blank
      ->if('*host_end == \':\'')
        ->line('ctx->port = atoi(host_end + 1);')
        ->line('while (*host_end && *host_end != \'/\') host_end++;')
      ->endif
      ->blank
      ->line('const char *path = (*host_end == \'/\') ? host_end : "/";')
      ->blank
      ->comment('Try to get a pooled connection')
      ->line('int pooled_fd = async_pool_get(ctx->host, ctx->port);')
      ->blank
      ->comment('Build request')
      ->line('STRLEN method_len;')
      ->line('const char *method = SvPV(method_sv, method_len);')
      ->blank
      ->line('STRLEN body_len = 0;')
      ->line('const char *body = NULL;')
      ->if('SvOK(body_sv)')
        ->line('body = SvPV(body_sv, body_len);')
      ->endif
      ->blank
      ->line('size_t req_cap = method_len + strlen(path) + host_len + 128 + body_len;')
      ->line('ctx->request = (char *)malloc(req_cap);')
      ->blank
      ->line('int req_len = snprintf(ctx->request, req_cap,')
      ->line('    "%s %s HTTP/1.1\\r\\n"')
      ->line('    "Host: %s\\r\\n"')
      ->line('    "Connection: keep-alive\\r\\n"')
      ->line('    "User-Agent: Hypersonic/1.0\\r\\n",')
      ->line('    method, path, ctx->host);')
      ->blank
      ->if('body_len > 0')
        ->line('req_len += snprintf(ctx->request + req_len, req_cap - req_len,')
        ->line('    "Content-Length: %zu\\r\\n\\r\\n", body_len);')
        ->line('memcpy(ctx->request + req_len, body, body_len);')
        ->line('req_len += body_len;')
      ->else
        ->line('req_len += snprintf(ctx->request + req_len, req_cap - req_len, "\\r\\n");')
      ->endif
      ->blank
      ->line('ctx->request_len = req_len;')
      ->line('ctx->request_sent = 0;')
      ->blank
      ->comment('Store callback or future')
      ->if('SvROK(future_or_cb) && SvTYPE(SvRV(future_or_cb)) == SVt_PVCV')
        ->line('ctx->callback = SvREFCNT_inc(future_or_cb);')
        ->line('ctx->future_sv = NULL;')
      ->else
        ->comment('Store the future SV directly')
        ->line('ctx->future_sv = SvREFCNT_inc(future_or_cb);')
        ->line('ctx->callback = NULL;')
      ->endif
      ->blank
      ->comment('Use pooled connection if available, otherwise create new socket')
      ->if('pooled_fd >= 0')
        ->line('ctx->fd = pooled_fd;')
        ->line('ctx->state = ASYNC_STATE_SENDING;')
      ->else
        ->comment('Create socket and set non-blocking')
        ->line('ctx->fd = socket(AF_INET, SOCK_STREAM, 0);')
        ->line('if (ctx->fd < 0) {')
        ->line('    async_free_slot(slot);')
        ->line('    croak("socket() failed");')
        ->line('}')
        ->line('int opt = 1;')
        ->line('setsockopt(ctx->fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));')
        ->line('int flags = fcntl(ctx->fd, F_GETFL, 0);')
        ->line('fcntl(ctx->fd, F_SETFL, flags | O_NONBLOCK);')
        ->blank
        ->comment('Start async connect')
        ->line('struct hostent *he = gethostbyname(ctx->host);')
        ->if('!he')
          ->line('async_free_slot(slot);')
          ->line('croak("DNS resolution failed");')
        ->endif
        ->blank
        ->line('struct sockaddr_in addr;')
        ->line('memset(&addr, 0, sizeof(addr));')
        ->line('addr.sin_family = AF_INET;')
        ->line('addr.sin_port = htons(ctx->port);')
        ->line('memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);')
        ->blank
        ->line('int rc = connect(ctx->fd, (struct sockaddr *)&addr, sizeof(addr));')
        ->if('rc < 0 && errno != EINPROGRESS')
          ->line('async_free_slot(slot);')
          ->line('croak("connect() failed");')
        ->endif
        ->blank
        ->line('ctx->state = ASYNC_STATE_CONNECTING;')
      ->endif
      ->blank
      ->comment('Auto-tick: process all pending async requests immediately')
      ->comment('This drives the event loop without requiring manual tick() calls')
      ->if('SvROK(ua_sv)')
        ->line('dSP;')
        ->line('ENTER; SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(ua_sv);')
        ->line('PUTBACK;')
        ->line('call_method("tick", G_DISCARD);')
        ->line('FREETMPS; LEAVE;')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(slot));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_poll {
    my ($class, $builder) = @_;

    $builder->comment('Poll async context, advance state machine')
      ->xs_function('xs_async_poll')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: poll($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) {')
      ->line('    ST(0) = sv_2mortal(newSViv(ASYNC_WAIT_NONE));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('AsyncContext *ctx = &async_registry[slot];')
      ->if('!ctx->in_use')
        ->line('ST(0) = sv_2mortal(newSViv(ASYNC_WAIT_NONE));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Check connect completion if connecting')
      ->if('ctx->state == ASYNC_STATE_CONNECTING')
        ->comment('Use select to check if socket is writable (connect complete)')
        ->line('fd_set wfds;')
        ->line('FD_ZERO(&wfds);')
        ->line('FD_SET(ctx->fd, &wfds);')
        ->line('struct timeval tv = {0, 0};')
        ->line('int sel = select(ctx->fd + 1, NULL, &wfds, NULL, &tv);')
        ->if('sel > 0 && FD_ISSET(ctx->fd, &wfds)')
          ->comment('Socket is writable - check for actual connection')
          ->line('int err = 0;')
          ->line('socklen_t errlen = sizeof(err);')
          ->line('getsockopt(ctx->fd, SOL_SOCKET, SO_ERROR, &err, &errlen);')
          ->if('err == 0')
            ->comment('Connected, move to sending')
            ->line('ctx->state = ASYNC_STATE_SENDING;')
          ->else
            ->line('ctx->state = ASYNC_STATE_ERROR;')
            ->line('ctx->error = strdup("connect failed");')
          ->endif
        ->endif
      ->endif
      ->blank
      ->line('int events = async_poll_one(slot);')
      ->line('ST(0) = sv_2mortal(newSViv(events));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_fd {
    my ($class, $builder) = @_;

    $builder->comment('Get file descriptor for async context')
      ->xs_function('xs_async_get_fd')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: get_fd($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS || !async_registry[slot].in_use) {')
      ->line('    ST(0) = sv_2mortal(newSViv(-1));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(async_registry[slot].fd));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_events {
    my ($class, $builder) = @_;

    $builder->comment('Get events needed for async context')
      ->xs_function('xs_async_get_events')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: get_events($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('int events = async_poll_one(slot);')
      ->line('ST(0) = sv_2mortal(newSViv(events));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_cancel {
    my ($class, $builder) = @_;

    $builder->comment('Cancel async request')
      ->xs_function('xs_async_cancel')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: cancel($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot >= 0 && slot < MAX_ASYNC_CONTEXTS && async_registry[slot].in_use) {')
      ->line('    async_registry[slot].state = ASYNC_STATE_CANCELLED;')
      ->line('}')
      ->xs_return('0')
      ->xs_end
      ->blank;
}

sub gen_xs_cleanup {
    my ($class, $builder) = @_;

    $builder->comment('Cleanup completed async request')
      ->xs_function('xs_async_cleanup')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: cleanup($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('async_free_slot(slot);')
      ->xs_return('0')
      ->xs_end
      ->blank;
}

sub gen_xs_get_future {
    my ($class, $builder) = @_;

    $builder->comment('Get future SV for async context')
      ->xs_function('xs_async_get_future')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: get_future($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS || !async_registry[slot].in_use) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('SV *future = async_registry[slot].future_sv;')
      ->line('ST(0) = future ? sv_2mortal(SvREFCNT_inc(future)) : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_state {
    my ($class, $builder) = @_;

    $builder->comment('Get state of async context')
      ->xs_function('xs_async_get_state')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: get_state($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS || !async_registry[slot].in_use) {')
      ->line('    ST(0) = sv_2mortal(newSViv(-1));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(async_registry[slot].state));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_result {
    my ($class, $builder) = @_;

    $builder->comment('Get result buffer from async context')
      ->xs_function('xs_async_get_result')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: get_result($slot)");')
      ->blank
      ->line('int slot = SvIV(ST(0));')
      ->line('if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS || !async_registry[slot].in_use) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('AsyncContext *ctx = &async_registry[slot];')
      ->blank
      ->if('ctx->state == ASYNC_STATE_ERROR && ctx->error')
        ->comment('Return error as a list (0, error_msg)')
        ->line('ST(0) = sv_2mortal(newSViv(0));')
        ->line('ST(1) = sv_2mortal(newSVpv(ctx->error, 0));')
        ->line('XSRETURN(2);')
      ->elsif('ctx->state == ASYNC_STATE_DONE && ctx->recv_buffer')
        ->comment('Return success as a list (1, body)')
        ->line('ST(0) = sv_2mortal(newSViv(1));')
        ->line('ST(1) = sv_2mortal(newSVpvn(ctx->recv_buffer, ctx->recv_buffer_len));')
        ->line('XSRETURN(2);')
      ->else
        ->comment('Not ready yet')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_tick {
    my ($class, $builder, $opts) = @_;

    my $event_backend = $opts->{event_backend};
    my $backend_name = $opts->{event_backend_name} // 'kqueue';

    $builder->comment("Process pending async events - AUTO-TICKING pure C path ($backend_name)")
      ->comment('Loops until all requests complete OR no progress for 1ms')
      ->xs_function('xs_ua_tick')
      ->xs_preamble
      ->line('int i;')
      ->line('int nev;')
      ->line('I32 j;')
      ->line('if (items < 1) croak("Usage: $ua->tick()");')
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
      ->blank
      ->comment('Main tick loop - process until no pending or no progress')
      ->line('int total_completed = 0;')
      ->line('int iterations = 0;')
      ->line('int max_iterations = 1000;  /* Safety cap */')
      ->blank
      ->line('tick_loop:')
      ->line('{')
      ->line('    I32 len = av_len(pending_av) + 1;')
      ->line('    if (len == 0 || iterations++ >= max_iterations) {')
      ->line('        ST(0) = sv_2mortal(newSViv(len));')
      ->line('        XSRETURN(1);')
      ->line('    }')
      ->blank
      ->comment('    Collect slots from pending array')
      ->line('    int slots[MAX_ASYNC_CONTEXTS];')
      ->line('    int slot_count = 0;')
      ->blank
      ->line('    for (j = 0; j < len; j++) {')
      ->line('        SV **slot_svp = av_fetch(pending_av, j, 0);')
      ->line('        if (!slot_svp) continue;')
      ->line('        int slot = SvIV(*slot_svp);')
      ->line('        if (slot >= 0 && slot < MAX_ASYNC_CONTEXTS) {')
      ->line('            AsyncContext *ctx = &async_registry[slot];')
      ->line('            if (ctx->in_use && ctx->fd >= 0) {')
      ->line('                slots[slot_count++] = slot;')
      ->line('            }')
      ->line('        }')
      ->line('    }')
      ->blank;
    
    # Create event loop using the backend
    $builder->comment('Create event loop if needed')
      ->line('if (async_ev_fd < 0) {');
    $event_backend->gen_create_loop($builder, 'async_ev_fd');
    $builder->line('}')
      ->blank;
    
    # Register all fds - use backend's native struct
    my $event_struct = $event_backend->event_struct;
    
    $builder->comment('Register all fds with event loop')
      ->line('int change_count = 0;')
      ->blank
      ->line('for (i = 0; i < slot_count; i++) {')
      ->line('    int slot = slots[i];')
      ->line('    AsyncContext *ctx = &async_registry[slot];')
      ->line('    int events = async_poll_one(slot);')
      ->line('    if (events == ASYNC_WAIT_NONE) continue;')
      ->blank
      ->line('    if (events == ASYNC_WAIT_READ) {');
    $event_backend->gen_add_with_slot($builder, 'async_ev_fd', 'ctx->fd', 'slot', 'read');
    $builder->line('    } else {');
    $event_backend->gen_add_with_slot($builder, 'async_ev_fd', 'ctx->fd', 'slot', 'write');
    $builder->line('    }')
      ->line('    change_count++;')
      ->line('}')
      ->blank;
    
    # Wait for events
    $builder->comment('Wait for events (1ms timeout)')
      ->line("struct $event_struct ready_events[MAX_EVENTS];");
    $event_backend->gen_wait_once($builder, 'async_ev_fd', 'ready_events', 'nev', '1');
    
    # Process ready events
    $builder->blank
      ->comment('Process ready events in pure C')
      ->line('for (i = 0; i < nev; i++) {');
    $event_backend->gen_get_slot($builder, 'ready_events', 'i', 'slot');
    $builder->line('    if (slot >= 0 && slot < MAX_ASYNC_CONTEXTS) {')
      ->line('        async_advance_state(slot);')
      ->line('    }')
      ->line('}')
      ->blank
      ->comment('Check for completed slots and resolve futures')
      ->line('int completed = 0;')
      ->line('for (j = len - 1; j >= 0; j--) {')
      ->line('    SV **slot_svp = av_fetch(pending_av, j, 0);')
      ->line('    if (!slot_svp) continue;')
      ->line('    int slot = SvIV(*slot_svp);')
      ->line('    if (slot < 0 || slot >= MAX_ASYNC_CONTEXTS) continue;')
      ->blank
      ->line('    AsyncContext *ctx = &async_registry[slot];')
      ->line('    if (!ctx->in_use) continue;')
      ->blank
      ->line('    if (ctx->state == ASYNC_STATE_DONE || ctx->state == ASYNC_STATE_ERROR) {')
      ->comment('        Resolve future')
      ->line('        if (ctx->future_sv && SvOK(ctx->future_sv)) {')
      ->line('            dSP;')
      ->line('            ENTER; SAVETMPS;')
      ->line('            PUSHMARK(SP);')
      ->line('            XPUSHs(ctx->future_sv);')
      ->blank
      ->line('            if (ctx->state == ASYNC_STATE_DONE && ctx->recv_buffer) {')
      ->line('                XPUSHs(sv_2mortal(newSVpv(ctx->recv_buffer, ctx->recv_buffer_len)));')
      ->line('                PUTBACK;')
      ->line('                call_method("done", G_DISCARD);')
      ->line('            } else {')
      ->line('                XPUSHs(sv_2mortal(newSVpv(ctx->error ? ctx->error : "unknown error", 0)));')
      ->line('                PUTBACK;')
      ->line('                call_method("fail", G_DISCARD);')
      ->line('            }')
      ->line('            FREETMPS; LEAVE;')
      ->line('        }')
      ->blank
      ->comment('        Cleanup slot')
      ->line('        async_free_slot(slot);')
      ->line('        av_delete(pending_av, j, G_DISCARD);')
      ->line('        completed++;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('    total_completed += completed;')
      ->blank
      ->comment('    If we made progress AND still have pending, loop back immediately')
      ->comment('    This drives requests to completion without manual tick() calls')
      ->line('    I32 remaining = av_len(pending_av) + 1;')
      ->line('    if (remaining > 0 && (completed > 0 || nev > 0)) {')
      ->line('        goto tick_loop;')
      ->line('    }')
      ->line('}')
      ->blank
      ->comment('Return remaining pending count (0 = all done)')
      ->line('I32 final_remaining = av_len(pending_av) + 1;')
      ->line('ST(0) = sv_2mortal(newSViv(final_remaining));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;

__END__

=head1 NAME

Hypersonic::UA::Async - Async HTTP request handling for Hypersonic::UA

=head1 SYNOPSIS

    # This module is used internally by Hypersonic::UA
    # Enable async support when compiling UA:

    use Hypersonic::UA;
    Hypersonic::UA->compile(async => 1);

=head1 DESCRIPTION

C<Hypersonic::UA::Async> provides the async request state machine and event
loop integration for C<Hypersonic::UA>. It uses platform-native event
mechanisms (kqueue on macOS/BSD, epoll on Linux) for efficient I/O
multiplexing.

=head1 INTERNAL API

These methods are used internally by Hypersonic::UA.

=head2 start_request

    my $slot = Hypersonic::UA::Async::start_request($method, $url, $body, $cb);

Start an async request. Returns a slot ID for tracking.

=head2 poll

    my $events = Hypersonic::UA::Async::poll($slot);

Poll a single async context, return events needed.

=head2 poll_batch

    my $ready = Hypersonic::UA::Async::poll_batch(@slots);

Poll multiple slots using platform-native event loop (kqueue/epoll).
Returns arrayref of completed slot IDs.

=head2 get_fd

    my $fd = Hypersonic::UA::Async::get_fd($slot);

Get file descriptor for async context.

=head2 get_state

    my $state = Hypersonic::UA::Async::get_state($slot);

Get current state of async context:

    0 = CONNECTING
    1 = TLS
    2 = SENDING
    3 = RECEIVING
    4 = DONE
    5 = ERROR
    6 = CANCELLED

=head2 get_result

    my ($ok, $data) = Hypersonic::UA::Async::get_result($slot);

Get result from completed async context.

=head2 cancel

    Hypersonic::UA::Async::cancel($slot);

Cancel an async request.

=head2 cleanup

    Hypersonic::UA::Async::cleanup($slot);

Clean up completed async context and free resources.

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
