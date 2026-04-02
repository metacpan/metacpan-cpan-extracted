package Hypersonic::UA::TLS;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant MAX_TLS_CONNS => 10000;

# Cache for OpenSSL detection result
my $OPENSSL_DETECTION;

# Check if OpenSSL is available (uses centralized detection)
sub check_openssl {
    return $OPENSSL_DETECTION->{available} if defined $OPENSSL_DETECTION;

    require Hypersonic::JIT::Util;
    $OPENSSL_DETECTION = Hypersonic::JIT::Util->detect_openssl();
    return $OPENSSL_DETECTION->{available};
}

# Get extra compiler flags for OpenSSL (uses centralized detection)
sub get_extra_cflags {
    require Hypersonic::JIT::Util;
    $OPENSSL_DETECTION //= Hypersonic::JIT::Util->detect_openssl();
    return $OPENSSL_DETECTION->{cflags} // '';
}

sub get_extra_ldflags {
    require Hypersonic::JIT::Util;
    $OPENSSL_DETECTION //= Hypersonic::JIT::Util->detect_openssl();
    # Need both -lssl and -lcrypto for full OpenSSL
    my $ldflags = $OPENSSL_DETECTION->{ldflags} // '';
    $ldflags .= ' -lcrypto' unless $ldflags =~ /-lcrypto/;
    return $ldflags;
}

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_conns = $opts->{max_tls_conns} // MAX_TLS_CONNS;

    $class->gen_tls_registry($builder, $max_conns);
    $class->gen_xs_init_context($builder);
    $class->gen_xs_connect($builder);
    $class->gen_xs_handshake($builder);
    $class->gen_xs_send($builder);
    $class->gen_xs_recv($builder);
    $class->gen_xs_recv_chunk($builder);
    $class->gen_xs_close($builder);
    $class->gen_xs_get_ssl($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::TLS::init_context'   => { source => 'xs_uatls_init_context', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_connect'    => { source => 'xs_uatls_connect', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_handshake'  => { source => 'xs_uatls_handshake', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_send'       => { source => 'xs_uatls_send', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_recv'       => { source => 'xs_uatls_recv', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_recv_chunk' => { source => 'xs_uatls_recv_chunk', is_xs_native => 1 },
        'Hypersonic::UA::TLS::tls_close'      => { source => 'xs_uatls_close', is_xs_native => 1 },
        'Hypersonic::UA::TLS::get_ssl'        => { source => 'xs_uatls_get_ssl', is_xs_native => 1 },
    };
}

sub gen_tls_registry {
    my ($class, $builder, $max_conns) = @_;

    $builder->line('#include <openssl/ssl.h>')
      ->line('#include <openssl/err.h>')
      ->line('#include <openssl/x509v3.h>')
      ->blank;

    $builder->line("#define UA_MAX_TLS_CONNS $max_conns")
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int     fd;')
      ->line('    SSL*    ssl;')
      ->line('    int     handshake_done;')
      ->line('    int     verify;')
      ->line('} UATLSClientConn;')
      ->blank
      ->line('static SSL_CTX* g_ua_client_ssl_ctx = NULL;')
      ->line("static UATLSClientConn ua_tls_registry[UA_MAX_TLS_CONNS];")
      ->blank;

    $builder->line('static UATLSClientConn* ua_tls_find(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_TLS_CONNS; i++) {')
      ->line('        if (ua_tls_registry[i].fd == fd) {')
      ->line('            return &ua_tls_registry[i];')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    $builder->line('static UATLSClientConn* ua_tls_alloc(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_TLS_CONNS; i++) {')
      ->line('        if (ua_tls_registry[i].fd == 0) {')
      ->line('            UATLSClientConn* c = &ua_tls_registry[i];')
      ->line('            memset(c, 0, sizeof(UATLSClientConn));')
      ->line('            c->fd = fd;')
      ->line('            return c;')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    $builder->line('static void ua_tls_free(UATLSClientConn* c) {')
      ->line('    if (c->ssl) {')
      ->line('        SSL_shutdown(c->ssl);')
      ->line('        SSL_free(c->ssl);')
      ->line('    }')
      ->line('    c->fd = 0;')
      ->line('    c->ssl = NULL;')
      ->line('    c->handshake_done = 0;')
      ->line('}')
      ->blank;

    $builder->line('static void ua_tls_registry_init(void) {')
      ->line('    memset(ua_tls_registry, 0, sizeof(ua_tls_registry));')
      ->line('}')
      ->blank;
}

sub gen_xs_init_context {
    my ($class, $builder) = @_;

    $builder->comment('Initialize client TLS context')
      ->xs_function('xs_uatls_init_context')
      ->xs_preamble
      ->line('int verify;')
      ->line('const char* ca_file;')
      ->blank
      ->line('if (items > 2) croak("Usage: init_context([verify], [ca_file])");')
      ->blank
      ->line('verify = (items > 0) ? (int)SvIV(ST(0)) : 1;')
      ->line('ca_file = (items > 1 && SvOK(ST(1))) ? SvPV_nolen(ST(1)) : NULL;')
      ->blank
      ->line('SSL_library_init();')
      ->line('SSL_load_error_strings();')
      ->line('OpenSSL_add_all_algorithms();')
      ->blank
      ->line('g_ua_client_ssl_ctx = SSL_CTX_new(TLS_client_method());')
      ->if('!g_ua_client_ssl_ctx')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSL_CTX_set_min_proto_version(g_ua_client_ssl_ctx, TLS1_2_VERSION);')
      ->blank
      ->if('verify')
        ->line('SSL_CTX_set_verify(g_ua_client_ssl_ctx, SSL_VERIFY_PEER, NULL);')
        ->if('ca_file')
          ->line('SSL_CTX_load_verify_locations(g_ua_client_ssl_ctx, ca_file, NULL);')
        ->else
          ->line('SSL_CTX_set_default_verify_paths(g_ua_client_ssl_ctx);')
        ->endif
      ->else
        ->line('SSL_CTX_set_verify(g_ua_client_ssl_ctx, SSL_VERIFY_NONE, NULL);')
      ->endif
      ->blank
      ->line('ua_tls_registry_init();')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_connect {
    my ($class, $builder) = @_;

    $builder->comment('TLS connect with SNI and verification')
      ->xs_function('xs_uatls_connect')
      ->xs_preamble
      ->line('int fd;')
      ->line('STRLEN host_len;')
      ->line('const char* hostname;')
      ->line('int verify;')
      ->line('SSL* ssl;')
      ->line('int ret;')
      ->line('int err;')
      ->line('UATLSClientConn* c;')
      ->blank
      ->line('if (items < 2 || items > 3) croak("Usage: tls_connect(fd, hostname, [verify])");')
      ->blank
      ->line('fd = (int)SvIV(ST(0));')
      ->line('hostname = SvPV(ST(1), host_len);')
      ->line('verify = (items > 2) ? (int)SvIV(ST(2)) : 1;')
      ->blank
      ->if('!g_ua_client_ssl_ctx')
        ->line('SSL_library_init();')
        ->line('SSL_load_error_strings();')
        ->line('g_ua_client_ssl_ctx = SSL_CTX_new(TLS_client_method());')
        ->line('SSL_CTX_set_min_proto_version(g_ua_client_ssl_ctx, TLS1_2_VERSION);')
        ->if('verify')
          ->line('SSL_CTX_set_verify(g_ua_client_ssl_ctx, SSL_VERIFY_PEER, NULL);')
          ->line('SSL_CTX_set_default_verify_paths(g_ua_client_ssl_ctx);')
        ->endif
        ->line('ua_tls_registry_init();')
      ->endif
      ->blank
      ->line('ssl = SSL_new(g_ua_client_ssl_ctx);')
      ->if('!ssl')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSL_set_fd(ssl, fd);')
      ->line('SSL_set_connect_state(ssl);')
      ->blank
      ->comment('Set SNI hostname')
      ->line('SSL_set_tlsext_host_name(ssl, hostname);')
      ->blank
      ->comment('Enable hostname verification')
      ->if('verify')
        ->line('SSL_set1_host(ssl, hostname);')
      ->endif
      ->blank
      ->line('ret = SSL_connect(ssl);')
      ->if('ret != 1')
        ->line('err = SSL_get_error(ssl, ret);')
        ->line('SSL_free(ssl);')
        ->line('ST(0) = sv_2mortal(newSViv(-err));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('c = ua_tls_alloc(fd);')
      ->if('!c')
        ->line('SSL_free(ssl);')
        ->line('ST(0) = sv_2mortal(newSViv(-999));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('c->ssl = ssl;')
      ->line('c->handshake_done = 1;')
      ->line('c->verify = verify;')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_handshake {
    my ($class, $builder) = @_;

    $builder->comment('Continue non-blocking handshake')
      ->xs_function('xs_uatls_handshake')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: tls_handshake(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('!c || !c->ssl')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('int ret = SSL_connect(c->ssl);')
      ->if('ret == 1')
        ->line('c->handshake_done = 1;')
        ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->else
        ->line('int err = SSL_get_error(c->ssl, ret);')
        ->if('err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE')
          ->line('ST(0) = sv_2mortal(newSViv(0));')
        ->else
          ->line('ST(0) = sv_2mortal(newSViv(-err));')
        ->endif
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_send {
    my ($class, $builder) = @_;

    $builder->comment('TLS send')
      ->xs_function('xs_uatls_send')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: tls_send(fd, data)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('!c || !c->ssl')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('int written = SSL_write(c->ssl, data, data_len);')
      ->line('ST(0) = sv_2mortal(newSViv(written));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv {
    my ($class, $builder) = @_;

    $builder->comment('TLS receive with timeout')
      ->xs_function('xs_uatls_recv')
      ->xs_preamble
      ->line('if (items < 1 || items > 2) croak("Usage: tls_recv(fd, [timeout_ms])");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('int timeout_ms = (items > 1) ? (int)SvIV(ST(1)) : 30000;')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('!c || !c->ssl')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('struct timeval tv;')
      ->line('tv.tv_sec = timeout_ms / 1000;')
      ->line('tv.tv_usec = (timeout_ms % 1000) * 1000;')
      ->line('setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));')
      ->blank
      ->line('static char recv_buf[65536];')
      ->line('size_t total = 0;')
      ->blank
      ->line('while (total < sizeof(recv_buf) - 1) {')
      ->line('    int n = SSL_read(c->ssl, recv_buf + total, sizeof(recv_buf) - 1 - total);')
      ->line('    if (n <= 0) {')
      ->line('        int err = SSL_get_error(c->ssl, n);')
      ->line('        if (err == SSL_ERROR_ZERO_RETURN) break;')
      ->line('        if (err == SSL_ERROR_WANT_READ) continue;')
      ->line('        break;')
      ->line('    }')
      ->line('    total += n;')
      ->blank
      ->line('    recv_buf[total] = \'\\0\';')
      ->line('    char* headers_end = strstr(recv_buf, "\\r\\n\\r\\n");')
      ->line('    if (headers_end) {')
      ->line('        char* cl = strcasestr(recv_buf, "Content-Length:");')
      ->line('        if (cl) {')
      ->line('            int content_len = atoi(cl + 15);')
      ->line('            char* body = headers_end + 4;')
      ->line('            if ((size_t)(total - (body - recv_buf)) >= (size_t)content_len) break;')
      ->line('        } else if (strcasestr(recv_buf, "Transfer-Encoding: chunked")) {')
      ->line('            if (strstr(recv_buf, "\\r\\n0\\r\\n")) break;')
      ->line('        } else {')
      ->line('            break;')
      ->line('        }')
      ->line('    }')
      ->line('}')
      ->blank
      ->if('total > 0')
        ->line('ST(0) = sv_2mortal(newSVpvn(recv_buf, total));')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv_chunk {
    my ($class, $builder) = @_;

    $builder->comment('TLS receive chunk (non-blocking)')
      ->xs_function('xs_uatls_recv_chunk')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: tls_recv_chunk(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('!c || !c->ssl')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('static char chunk_buf[65536];')
      ->line('int n = SSL_read(c->ssl, chunk_buf, sizeof(chunk_buf));')
      ->blank
      ->if('n > 0')
        ->line('ST(0) = sv_2mortal(newSVpvn(chunk_buf, n));')
      ->elsif('n == 0')
        ->line('ST(0) = &PL_sv_undef;')
      ->else
        ->line('int err = SSL_get_error(c->ssl, n);')
        ->if('err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE')
          ->line('ST(0) = sv_2mortal(newSVpvn("", 0));')
        ->else
          ->line('ST(0) = &PL_sv_undef;')
        ->endif
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->comment('TLS close')
      ->xs_function('xs_uatls_close')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: tls_close(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('c')
        ->line('ua_tls_free(c);')
      ->endif
      ->blank
      ->line('close(fd);')
      ->line('ST(0) = sv_2mortal(newSViv(0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_ssl {
    my ($class, $builder) = @_;

    $builder->comment('Get SSL handle')
      ->xs_function('xs_uatls_get_ssl')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: get_ssl(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('UATLSClientConn* c = ua_tls_find(fd);')
      ->if('c && c->ssl')
        ->line('ST(0) = sv_2mortal(newSViv(PTR2IV(c->ssl)));')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;
