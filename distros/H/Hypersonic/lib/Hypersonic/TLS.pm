package Hypersonic::TLS;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# JIT-compiled TLS/HTTPS support for Hypersonic
# Uses OpenSSL for TLS support (via Alien::OpenSSL when available)
# Generates XS code via XS::JIT::Builder

use XS::JIT;
use XS::JIT::Builder;

my $COMPILED = 0;
my $MODULE_ID = 0;

# Cache for OpenSSL detection result
my $OPENSSL_DETECTION;

# Check if OpenSSL is available (uses centralized detection)
sub check_openssl {
    return $OPENSSL_DETECTION->{available} if defined $OPENSSL_DETECTION;

    require Hypersonic::JIT::Util;
    $OPENSSL_DETECTION = Hypersonic::JIT::Util->detect_openssl();
    return $OPENSSL_DETECTION->{available};
}

# Unified compile interface
sub compile {
    my ($class, %opts) = @_;
    return $class->compile_tls_ops(%opts);
}

# Compile TLS ops using XS::JIT::Builder
sub compile_tls_ops {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_cache/tls';
    my $module_name = 'Hypersonic::TLS::Ops_' . $MODULE_ID++;

    my $builder = XS::JIT::Builder->new;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    # Add OpenSSL includes
    $builder->include('<openssl/ssl.h>')
            ->include('<openssl/err.h>')
            ->include('<openssl/opensslv.h>');

    # Add TLS global state and structures
    $builder->line('/* Global SSL context - initialized once */')
            ->line('static SSL_CTX* g_ssl_ctx = NULL;')
            ->line('')
            ->line('/* Connection state for TLS */')
            ->line('typedef struct {')
            ->line('    int fd;')
            ->line('    SSL* ssl;')
            ->line('    time_t last_activity;')
            ->line('    int handshake_complete;')
            ->line('} TLSConnection;')
            ->line('')
            ->line('#define MAX_TLS_CONNECTIONS 10000')
            ->line('static TLSConnection g_tls_connections[MAX_TLS_CONNECTIONS];');

    # Helper to get TLS connection
    $builder->line('')
            ->line("static $inline TLSConnection* get_tls_connection(int fd) {")
            ->line('    int i;')
            ->line('    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {')
            ->line('        if (g_tls_connections[i].fd == fd) {')
            ->line('            return &g_tls_connections[i];')
            ->line('        }')
            ->line('    }')
            ->line('    return NULL;')
            ->line('}');

    # Helper to allocate TLS connection
    $builder->line('')
            ->line("static $inline TLSConnection* alloc_tls_connection(int fd, SSL* ssl) {")
            ->line('    int i;')
            ->line('    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {')
            ->line('        if (g_tls_connections[i].fd == 0) {')
            ->line('            g_tls_connections[i].fd = fd;')
            ->line('            g_tls_connections[i].ssl = ssl;')
            ->line('            g_tls_connections[i].last_activity = time(NULL);')
            ->line('            g_tls_connections[i].handshake_complete = 0;')
            ->line('            return &g_tls_connections[i];')
            ->line('        }')
            ->line('    }')
            ->line('    return NULL;')
            ->line('}');

    # Helper to free TLS connection
    $builder->line('')
            ->line("static $inline void free_tls_connection(int fd) {")
            ->line('    int i;')
            ->line('    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {')
            ->line('        if (g_tls_connections[i].fd == fd) {')
            ->line('            if (g_tls_connections[i].ssl) {')
            ->line('                SSL_shutdown(g_tls_connections[i].ssl);')
            ->line('                SSL_free(g_tls_connections[i].ssl);')
            ->line('            }')
            ->line('            g_tls_connections[i].fd = 0;')
            ->line('            g_tls_connections[i].ssl = NULL;')
            ->line('            return;')
            ->line('        }')
            ->line('    }')
            ->line('}');

    # SSL context initialization
    $builder->line('')
            ->line('static int init_ssl_ctx(const char* cert_file, const char* key_file) {')
            ->line('    SSL_library_init();')
            ->line('    SSL_load_error_strings();')
            ->line('    OpenSSL_add_all_algorithms();')
            ->line('')
            ->line('    g_ssl_ctx = SSL_CTX_new(TLS_server_method());')
            ->line('    if (!g_ssl_ctx) {')
            ->line('        return -1;')
            ->line('    }')
            ->line('')
            ->line('    /* Set minimum TLS version to 1.2 for security */')
            ->line('    SSL_CTX_set_min_proto_version(g_ssl_ctx, TLS1_2_VERSION);')
            ->line('')
            ->line('    /* Load certificate and key */')
            ->line('    if (SSL_CTX_use_certificate_file(g_ssl_ctx, cert_file, SSL_FILETYPE_PEM) <= 0) {')
            ->line('        SSL_CTX_free(g_ssl_ctx);')
            ->line('        g_ssl_ctx = NULL;')
            ->line('        return -2;')
            ->line('    }')
            ->line('')
            ->line('    if (SSL_CTX_use_PrivateKey_file(g_ssl_ctx, key_file, SSL_FILETYPE_PEM) <= 0) {')
            ->line('        SSL_CTX_free(g_ssl_ctx);')
            ->line('        g_ssl_ctx = NULL;')
            ->line('        return -3;')
            ->line('    }')
            ->line('')
            ->line('    /* Verify private key matches certificate */')
            ->line('    if (!SSL_CTX_check_private_key(g_ssl_ctx)) {')
            ->line('        SSL_CTX_free(g_ssl_ctx);')
            ->line('        g_ssl_ctx = NULL;')
            ->line('        return -4;')
            ->line('    }')
            ->line('')
            ->line('    return 0;')
            ->line('}');

    # TLS accept
    $builder->line('')
            ->line('/* Accept TLS connection - non-blocking */')
            ->line('static int tls_accept(int client_fd) {')
            ->line('    if (!g_ssl_ctx) return -1;')
            ->line('')
            ->line('    SSL* ssl = SSL_new(g_ssl_ctx);')
            ->line('    if (!ssl) return -2;')
            ->line('')
            ->line('    SSL_set_fd(ssl, client_fd);')
            ->line('    SSL_set_accept_state(ssl);')
            ->line('')
            ->line('    TLSConnection* conn = alloc_tls_connection(client_fd, ssl);')
            ->line('    if (!conn) {')
            ->line('        SSL_free(ssl);')
            ->line('        return -3;')
            ->line('    }')
            ->line('')
            ->line('    /* Non-blocking handshake will complete on first read */')
            ->line('    return 0;')
            ->line('}');

    # TLS handshake
    $builder->line('')
            ->line('/* Complete TLS handshake - may need multiple calls */')
            ->line('static int tls_handshake(TLSConnection* conn) {')
            ->line('    if (conn->handshake_complete) return 1;')
            ->line('')
            ->line('    int ret = SSL_accept(conn->ssl);')
            ->line('    if (ret == 1) {')
            ->line('        conn->handshake_complete = 1;')
            ->line('        return 1;')
            ->line('    }')
            ->line('')
            ->line('    int err = SSL_get_error(conn->ssl, ret);')
            ->line('    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {')
            ->line('        return 0; /* Need more data, try again later */')
            ->line('    }')
            ->line('')
            ->line('    return -1; /* Fatal error */')
            ->line('}');

    # TLS recv
    $builder->line('')
            ->line('/* TLS read - returns bytes read, 0 for EAGAIN, -1 for error/close */')
            ->line('static ssize_t tls_recv(TLSConnection* conn, char* buf, size_t len) {')
            ->line('    if (!conn->handshake_complete) {')
            ->line('        int hs = tls_handshake(conn);')
            ->line('        if (hs <= 0) return hs;')
            ->line('    }')
            ->line('')
            ->line('    int ret = SSL_read(conn->ssl, buf, (int)len);')
            ->line('    if (ret > 0) {')
            ->line('        conn->last_activity = time(NULL);')
            ->line('        return ret;')
            ->line('    }')
            ->line('')
            ->line('    int err = SSL_get_error(conn->ssl, ret);')
            ->line('    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {')
            ->line('        return 0; /* Would block, try again */')
            ->line('    }')
            ->line('')
            ->line('    return -1; /* Error or connection closed */')
            ->line('}');

    # TLS send
    $builder->line('')
            ->line('/* TLS write - returns bytes written, 0 for EAGAIN, -1 for error */')
            ->line('static ssize_t tls_send(TLSConnection* conn, const char* buf, size_t len) {')
            ->line('    int ret = SSL_write(conn->ssl, buf, (int)len);')
            ->line('    if (ret > 0) {')
            ->line('        conn->last_activity = time(NULL);')
            ->line('        return ret;')
            ->line('    }')
            ->line('')
            ->line('    int err = SSL_get_error(conn->ssl, ret);')
            ->line('    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {')
            ->line('        return 0; /* Would block, try again */')
            ->line('    }')
            ->line('')
            ->line('    return -1; /* Error */')
            ->line('}');

    # TLS close
    $builder->line('')
            ->line('/* Close TLS connection */')
            ->line('static void tls_close(int fd) {')
            ->line('    free_tls_connection(fd);')
            ->line('    close(fd);')
            ->line('}');

    # XS wrapper for init_ssl_ctx
    $builder->xs_function('jit_init_ssl_ctx')
      ->xs_preamble
      ->line('STRLEN cert_len, key_len;')
      ->line('const char* cert_file;')
      ->line('const char* key_file;')
      ->line('int result;')
      ->line('if (items != 2) {')
      ->line('    croak("init_ssl_ctx requires cert_file and key_file");')
      ->line('}')
      ->line('cert_file = SvPV(ST(0), cert_len);')
      ->line('key_file = SvPV(ST(1), key_len);')
      ->line('result = init_ssl_ctx(cert_file, key_file);')
      ->line('ST(0) = sv_2mortal(newSViv(result));')
      ->xs_return('1')
      ->xs_end;

    # XS wrapper for tls_accept
    $builder->xs_function('jit_tls_accept')
      ->xs_preamble
      ->line('int client_fd;')
      ->line('int result;')
      ->line('if (items != 1) {')
      ->line('    croak("tls_accept requires client_fd");')
      ->line('}')
      ->line('client_fd = SvIV(ST(0));')
      ->line('result = tls_accept(client_fd);')
      ->line('ST(0) = sv_2mortal(newSViv(result));')
      ->xs_return('1')
      ->xs_end;

    # XS wrapper for tls_close
    $builder->xs_function('jit_tls_close')
      ->xs_preamble
      ->line('int fd;')
      ->line('if (items != 1) {')
      ->line('    croak("tls_close requires fd");')
      ->line('}')
      ->line('fd = SvIV(ST(0));')
      ->line('tls_close(fd);')
      ->xs_return('0')
      ->xs_end;

    # Compile via XS::JIT with OpenSSL flags
    XS::JIT->compile(
        code        => $builder->code,
        name        => $module_name,
        cache_dir   => $cache_dir,
        extra_cflags  => get_extra_cflags(),
        extra_ldflags => get_extra_ldflags(),
        functions => {
            'Hypersonic::TLS::init_ssl_ctx' => { source => 'jit_init_ssl_ctx', is_xs_native => 1 },
            'Hypersonic::TLS::tls_accept'   => { source => 'jit_tls_accept', is_xs_native => 1 },
            'Hypersonic::TLS::tls_close'    => { source => 'jit_tls_close', is_xs_native => 1 },
        },
    );

    $COMPILED = 1;
    return 1;
}

# Generate OpenSSL includes (for use by Hypersonic.pm code generation)
sub gen_includes {
    return <<'C';
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/opensslv.h>
C
}

# Generate SSL context initialization (for use by Hypersonic.pm code generation)
sub gen_ssl_ctx_init {
    my (%opts) = @_;
    my $enable_http2 = $opts{http2} // 0;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    my $alpn_code = '';
    if ($enable_http2) {
        $alpn_code = <<'ALPN';

/* ALPN protocol list for HTTP/2 negotiation */
static const unsigned char alpn_protos[] = {
    2, 'h', '2',                              /* HTTP/2 */
    8, 'h', 't', 't', 'p', '/', '1', '.', '1' /* HTTP/1.1 fallback */
};

/* ALPN selection callback - called during TLS handshake */
static int alpn_select_cb(SSL* ssl,
                          const unsigned char** out,
                          unsigned char* outlen,
                          const unsigned char* in,
                          unsigned int inlen,
                          void* arg) {
    (void)ssl; (void)arg;
    
    /* Use OpenSSL's helper to select preferred protocol */
    if (SSL_select_next_proto((unsigned char**)out, outlen,
                              alpn_protos, sizeof(alpn_protos),
                              in, inlen) == OPENSSL_NPN_NEGOTIATED) {
        return SSL_TLSEXT_ERR_OK;
    }
    
    /* No matching protocol - allow connection anyway (HTTP/1.1) */
    return SSL_TLSEXT_ERR_NOACK;
}
ALPN
    }
    
    my $alpn_setup = $enable_http2 
        ? "\n    /* Enable ALPN for HTTP/2 negotiation */\n    SSL_CTX_set_alpn_select_cb(g_ssl_ctx, alpn_select_cb, NULL);\n" 
        : '';
    
    return <<"C";
/* Global SSL context - initialized once */
static SSL_CTX* g_ssl_ctx = NULL;

/* Connection state for TLS */
typedef struct {
    int fd;
    SSL* ssl;
    time_t last_activity;
    int handshake_complete;
    int protocol;  /* PROTO_HTTP1=1, PROTO_HTTP2=2 */
} TLSConnection;

#define PROTO_HTTP1 1
#define PROTO_HTTP2 2
#define MAX_TLS_CONNECTIONS 10000
static TLSConnection g_tls_connections[MAX_TLS_CONNECTIONS];
$alpn_code
static $inline TLSConnection* get_tls_connection(int fd) {
    int i;
    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {
        if (g_tls_connections[i].fd == fd) {
            return &g_tls_connections[i];
        }
    }
    return NULL;
}

static $inline TLSConnection* alloc_tls_connection(int fd, SSL* ssl) {
    int i;
    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {
        if (g_tls_connections[i].fd == 0) {
            g_tls_connections[i].fd = fd;
            g_tls_connections[i].ssl = ssl;
            g_tls_connections[i].last_activity = time(NULL);
            g_tls_connections[i].handshake_complete = 0;
            g_tls_connections[i].protocol = PROTO_HTTP1;  /* Default */
            return &g_tls_connections[i];
        }
    }
    return NULL;
}

static $inline void free_tls_connection(int fd) {
    int i;
    for (i = 0; i < MAX_TLS_CONNECTIONS; i++) {
        if (g_tls_connections[i].fd == fd) {
            if (g_tls_connections[i].ssl) {
                SSL_shutdown(g_tls_connections[i].ssl);
                SSL_free(g_tls_connections[i].ssl);
            }
            g_tls_connections[i].fd = 0;
            g_tls_connections[i].ssl = NULL;
            return;
        }
    }
}

/* Check negotiated protocol after TLS handshake */
static $inline int get_negotiated_protocol(TLSConnection* conn) {
    const unsigned char* alpn = NULL;
    unsigned int alpn_len = 0;
    SSL_get0_alpn_selected(conn->ssl, &alpn, &alpn_len);
    
    if (alpn_len == 2 && memcmp(alpn, "h2", 2) == 0) {
        conn->protocol = PROTO_HTTP2;
        return PROTO_HTTP2;
    }
    conn->protocol = PROTO_HTTP1;
    return PROTO_HTTP1;
}

static int init_ssl_ctx(const char* cert_file, const char* key_file) {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();

    g_ssl_ctx = SSL_CTX_new(TLS_server_method());
    if (!g_ssl_ctx) {
        return -1;
    }

    /* Set minimum TLS version to 1.2 for security */
    SSL_CTX_set_min_proto_version(g_ssl_ctx, TLS1_2_VERSION);
$alpn_setup
    /* Load certificate and key */
    if (SSL_CTX_use_certificate_file(g_ssl_ctx, cert_file, SSL_FILETYPE_PEM) <= 0) {
        SSL_CTX_free(g_ssl_ctx);
        g_ssl_ctx = NULL;
        return -2;
    }

    if (SSL_CTX_use_PrivateKey_file(g_ssl_ctx, key_file, SSL_FILETYPE_PEM) <= 0) {
        SSL_CTX_free(g_ssl_ctx);
        g_ssl_ctx = NULL;
        return -3;
    }

    /* Verify private key matches certificate */
    if (!SSL_CTX_check_private_key(g_ssl_ctx)) {
        SSL_CTX_free(g_ssl_ctx);
        g_ssl_ctx = NULL;
        return -4;
    }

    return 0;
}
C
}

# Generate TLS accept code
sub gen_ssl_accept {
    return <<'C';
/* Accept TLS connection - non-blocking */
static int tls_accept(int client_fd) {
    if (!g_ssl_ctx) return -1;

    SSL* ssl = SSL_new(g_ssl_ctx);
    if (!ssl) return -2;

    SSL_set_fd(ssl, client_fd);
    SSL_set_accept_state(ssl);

    TLSConnection* conn = alloc_tls_connection(client_fd, ssl);
    if (!conn) {
        SSL_free(ssl);
        return -3;
    }

    /* Non-blocking handshake will complete on first read */
    return 0;
}

/* Complete TLS handshake - may need multiple calls */
static int tls_handshake(TLSConnection* conn) {
    if (conn->handshake_complete) return 1;

    int ret = SSL_accept(conn->ssl);
    if (ret == 1) {
        conn->handshake_complete = 1;
        return 1;
    }

    int err = SSL_get_error(conn->ssl, ret);
    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
        return 0; /* Need more data, try again later */
    }

    return -1; /* Fatal error */
}
C
}

# Generate TLS read/write wrappers
sub gen_ssl_io {
    return <<'C';
/* TLS read - returns bytes read, 0 for EAGAIN, -1 for error/close */
static ssize_t tls_recv(TLSConnection* conn, char* buf, size_t len) {
    if (!conn->handshake_complete) {
        int hs = tls_handshake(conn);
        if (hs <= 0) return hs;
    }

    int ret = SSL_read(conn->ssl, buf, (int)len);
    if (ret > 0) {
        conn->last_activity = time(NULL);
        return ret;
    }

    int err = SSL_get_error(conn->ssl, ret);
    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
        return 0; /* Would block, try again */
    }

    return -1; /* Error or connection closed */
}

/* TLS write - returns bytes written, 0 for EAGAIN, -1 for error */
static ssize_t tls_send(TLSConnection* conn, const char* buf, size_t len) {
    int ret = SSL_write(conn->ssl, buf, (int)len);
    if (ret > 0) {
        conn->last_activity = time(NULL);
        return ret;
    }

    int err = SSL_get_error(conn->ssl, ret);
    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
        return 0; /* Would block, try again */
    }

    return -1; /* Error */
}
C
}

# Generate TLS close
sub gen_ssl_close {
    return <<'C';
/* Close TLS connection */
static void tls_close(int fd) {
    free_tls_connection(fd);
    close(fd);
}
C
}

# Return all TLS C code (for Hypersonic.pm to embed in generated code)
sub generate_tls_code {
    return join("\n\n",
        gen_includes(),
        gen_ssl_ctx_init(),
        gen_ssl_accept(),
        gen_ssl_io(),
        gen_ssl_close(),
    );
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

1;

__END__

=head1 NAME

Hypersonic::TLS - TLS/HTTPS support for Hypersonic

=head1 SYNOPSIS

    use Hypersonic;

    # Create an HTTPS server
    my $server = Hypersonic->new(
        tls       => 1,
        cert_file => '/path/to/cert.pem',
        key_file  => '/path/to/key.pem',
    );

    $server->get('/api/secure' => sub { '{"secure":true}' });
    $server->compile();
    $server->run(port => 8443);

    # Generate self-signed certificate for testing
    # openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
    #   -days 365 -nodes -subj "/CN=localhost"

=head1 DESCRIPTION

C<Hypersonic::TLS> provides TLS/HTTPS support for the Hypersonic HTTP
server using OpenSSL. The TLS handshake and encryption/decryption are
JIT-compiled to native XS code for maximum performance.

B<This module is used internally by Hypersonic when TLS is enabled.>
You typically don't need to use it directly.

=head1 REQUIREMENTS

=over 4

=item * OpenSSL development libraries

=item * L<Alien::OpenSSL> (recommended for portability)

=back

=head2 Installing OpenSSL

B<macOS (Homebrew):>

    brew install openssl@3

B<Debian/Ubuntu:>

    apt-get install libssl-dev

B<RHEL/CentOS/Fedora:>

    yum install openssl-devel

B<Using Alien::OpenSSL (recommended):>

    cpanm Alien::OpenSSL

=head1 USAGE

TLS is enabled via the main C<Hypersonic> constructor:

    use Hypersonic;

    my $server = Hypersonic->new(
        tls       => 1,                    # Enable TLS
        cert_file => 'cert.pem',           # Certificate file (required)
        key_file  => 'key.pem',            # Private key file (required)
    );

=head2 Certificate Files

The certificate and key files must be in PEM format:

=over 4

=item cert_file

PEM-encoded X.509 certificate (or certificate chain)

=item key_file

PEM-encoded private key (RSA, ECDSA, or Ed25519)

=back

=head2 Certificate Chain

For production, include the full certificate chain in cert_file:

    cat server.crt intermediate.crt root.crt > fullchain.pem

=head1 CLASS METHODS

=head2 check_openssl

    if (Hypersonic::TLS::check_openssl()) {
        # OpenSSL is available
    }

Returns true if OpenSSL is available for compilation.

Checks:

=over 4

=item 1. L<Alien::OpenSSL> availability (preferred)

=item 2. System OpenSSL via test compilation

=back

=head2 compile_tls_ops

    Hypersonic::TLS->compile_tls_ops(
        cache_dir => '_tls_cache',
    );

Compile the TLS operations to XS. Called automatically when TLS is
enabled in the server constructor.

=head2 get_extra_cflags

    my $cflags = Hypersonic::TLS::get_extra_cflags();
    # e.g., "-I/opt/homebrew/opt/openssl@3/include"

Returns extra compiler flags for OpenSSL include paths.

=head2 get_extra_ldflags

    my $ldflags = Hypersonic::TLS::get_extra_ldflags();
    # e.g., "-L/opt/homebrew/opt/openssl@3/lib -lssl -lcrypto"

Returns extra linker flags for OpenSSL.

=head1 CODE GENERATION METHODS

These methods generate C code fragments included in the compiled server.

=head2 gen_includes

Returns C code for OpenSSL includes:

    #include <openssl/ssl.h>
    #include <openssl/err.h>

=head2 gen_ssl_ctx_init

Returns C code to initialize the SSL context with certificate/key.

=head2 gen_ssl_accept

Returns C code for TLS handshake on new connections.

=head2 gen_ssl_io

Returns C code for TLS-encrypted read/write operations.

=head2 gen_ssl_close

Returns C code for clean TLS connection shutdown.

=head1 SECURITY FEATURES

=head2 Protocol Version

=over 4

=item * TLS 1.2 minimum (TLS 1.0/1.1 disabled by default)

=item * TLS 1.3 supported if available

=back

=head2 Best Practices

=over 4

=item * Private key permissions should be C<0600> (owner read only)

=item * Use strong cipher suites in production

=item * Enable HSTS header (Strict-Transport-Security)

=item * Keep OpenSSL updated

=back

=head2 Security Headers

When TLS is enabled, Hypersonic automatically adds HSTS header:

    Strict-Transport-Security: max-age=31536000; includeSubDomains

=head1 PERFORMANCE

TLS operations are JIT-compiled with:

=over 4

=item * Session resumption for reduced handshake overhead

=item * Optimized buffer handling

=item * Direct OpenSSL API calls (no Perl layer)

=back

=head1 TESTING TLS

Generate a self-signed certificate for testing:

    # Generate certificate and key
    openssl req -x509 -newkey rsa:2048 \
        -keyout key.pem -out cert.pem \
        -days 365 -nodes \
        -subj "/CN=localhost"

    # Test with curl (skip verification for self-signed)
    curl -k https://localhost:8443/api/test

=head1 TROUBLESHOOTING

=head2 "TLS support not available"

OpenSSL not found. Install it:

    # macOS
    brew install openssl@3

    # Or use Alien::OpenSSL
    cpanm Alien::OpenSSL

=head2 "cert_file not found"

Verify the certificate file path is correct and readable.

=head2 "Failed to initialize TLS context"

Check that:

=over 4

=item * Certificate and key match (same public key)

=item * Key file is in PEM format

=item * Key file has correct permissions

=back

Verify with:

    openssl x509 -noout -modulus -in cert.pem | md5
    openssl rsa -noout -modulus -in key.pem | md5

Both commands should output the same MD5 hash.

=head1 EXAMPLE

Complete HTTPS server:

    use Hypersonic;
    use Hypersonic::Response 'res';

    my $server = Hypersonic->new(
        tls       => 1,
        cert_file => 'fullchain.pem',
        key_file  => 'privkey.pem',
        
        # Security hardening
        max_request_size => 16384,
        enable_security_headers => 1,
    );

    $server->get('/api/status' => sub {
        res->json({ status => 'ok', tls => 'enabled' });
    }, { dynamic => 1 });

    $server->compile();
    $server->run(port => 8443, workers => 4);

=head1 SEE ALSO

L<Hypersonic> - Main HTTP server module

L<Alien::OpenSSL> - Portable OpenSSL installation

L<https://www.openssl.org/> - OpenSSL documentation

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
