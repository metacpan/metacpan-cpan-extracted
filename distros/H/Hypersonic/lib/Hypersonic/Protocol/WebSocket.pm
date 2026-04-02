package Hypersonic::Protocol::WebSocket;
use strict;
use warnings;

# Hypersonic::Protocol::WebSocket - JIT code generation for WebSocket handshake
#
# Implements RFC 6455 WebSocket opening handshake:
# - Parse Upgrade/Connection headers
# - Extract Sec-WebSocket-Key, Version, Protocol
# - Calculate Sec-WebSocket-Accept (SHA1 + Base64)
# - Generate 101 Switching Protocols response
#
# All methods return C code strings for JIT compilation.
# Zero runtime overhead - handshake code compiled only when websocket routes exist.

our $VERSION = '0.12';

# RFC 6455 magic GUID for accept key calculation
our $WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

# Protocol identifier
sub protocol_id { 'WebSocket' }

# Generate OpenSSL includes for SHA1/Base64
sub gen_includes {
    my ($class, $builder) = @_;
    
    $builder->line('#include <openssl/sha.h>')
            ->line('#include <openssl/bio.h>')
            ->line('#include <openssl/evp.h>')
            ->line('#include <openssl/buffer.h>')
            ->line('#include <ctype.h>')
            ->blank;
    return $builder;
}

# Generate WebSocket handshake struct
sub gen_handshake_struct {
    my ($class, $builder) = @_;
    
    $builder->comment('WebSocket handshake data from client request')
            ->line('typedef struct {')
            ->line('    char ws_key[64];')
            ->line('    char ws_protocol[128];')
            ->line('    int  ws_version;')
            ->line('    int  is_websocket;')
            ->line('} WSHandshake;')
            ->blank;
    return $builder;
}

# Generate Sec-WebSocket-Accept key calculation
# Accept = base64(SHA1(key + GUID))
sub gen_accept_key {
    my ($class, $builder) = @_;
    
    $builder->comment('Calculate Sec-WebSocket-Accept from client key')
            ->comment('RFC 6455 Section 4.2.2, Step 4')
            ->comment('Returns base64(SHA1(key + GUID))')
            ->line('static void calc_websocket_accept(const char* client_key, char* accept_out) {')
            ->line('    static const char* WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";')
            ->blank
            ->comment('    Concatenate key + GUID')
            ->line('    char concat[256];')
            ->line('    size_t key_len = strlen(client_key);')
            ->line('    size_t guid_len = 36;')
            ->blank;
    
    $builder->if('key_len + guid_len >= sizeof(concat)')
                ->line('accept_out[0] = \'\\0\';')
                ->line('return;')
            ->endif
            ->blank
            ->line('    memcpy(concat, client_key, key_len);')
                ->line('    memcpy(concat + key_len, WS_GUID, guid_len);')
                ->line('    concat[key_len + guid_len] = \'\\0\';')
                ->blank
                ->comment('    SHA1 hash')
                ->line('    unsigned char sha1_hash[SHA_DIGEST_LENGTH];')
                ->line('    SHA1((unsigned char*)concat, key_len + guid_len, sha1_hash);')
                ->blank
                ->comment('    Base64 encode using OpenSSL BIO')
                ->line('    BIO* b64 = BIO_new(BIO_f_base64());')
                ->line('    BIO* mem = BIO_new(BIO_s_mem());')
                ->line('    b64 = BIO_push(b64, mem);')
                ->line('    BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);')
                ->line('    BIO_write(b64, sha1_hash, SHA_DIGEST_LENGTH);')
                ->line('    BIO_flush(b64);')
                ->blank
                ->line('    BUF_MEM* buf;')
                ->line('    BIO_get_mem_ptr(b64, &buf);')
                ->blank;
        
        $builder->if('buf->length < 64')
                    ->line('memcpy(accept_out, buf->data, buf->length);')
                    ->line('accept_out[buf->length] = \'\\0\';')
                ->else
                    ->line('accept_out[0] = \'\\0\';')
                ->endif
                ->blank
                ->line('    BIO_free_all(b64);')
                ->line('}')
                ->blank;
    
    return $builder;
}

# Generate handshake request parser
sub gen_handshake_parser {
    my ($class, $builder) = @_;
    
    # Case-insensitive strstr helper
    $builder->comment('Case-insensitive strstr for header matching')
            ->line('static const char* ws_strcasestr(const char* haystack, const char* needle) {')
            ->line('    if (!*needle) return haystack;')
            ->blank;
        
        $builder->for('', '*haystack', 'haystack++')
                    ->line('const char* h = haystack;')
                    ->line('const char* n = needle;')
                    ->blank
                    ->while('*h && *n && (tolower((unsigned char)*h) == tolower((unsigned char)*n))')
                        ->line('h++;')
                        ->line('n++;')
                    ->endloop
                    ->blank;
        
        $builder->if('!*n')
                        ->line('return haystack;')
                    ->endif
                ->endfor
                ->line('    return NULL;')
                ->line('}')
                ->blank;
        
        # Main parser function
        $builder->comment('Parse WebSocket upgrade request headers')
                ->comment('Returns 1 if valid WebSocket upgrade, 0 otherwise')
                ->line('static int parse_ws_handshake(const char* request, size_t len, WSHandshake* hs) {')
                ->line('    hs->is_websocket = 0;')
                ->line('    hs->ws_version = 0;')
                ->line('    hs->ws_key[0] = \'\\0\';')
                ->line('    hs->ws_protocol[0] = \'\\0\';')
                ->blank
                ->comment('    Check for Upgrade: websocket header')
                ->line('    const char* upgrade = ws_strcasestr(request, "Upgrade:");');
        
        $builder->if('!upgrade')
                    ->line('return 0;')
                ->endif
                ->blank
                ->line('    const char* ws = ws_strcasestr(upgrade, "websocket");');
        
        $builder->if('!ws || ws > upgrade + 64')
                    ->line('return 0;')
                ->endif
                ->blank
                ->comment('    Check for Connection: Upgrade header')
                ->line('    const char* conn = ws_strcasestr(request, "Connection:");');
        
        $builder->if('!conn')
                    ->line('return 0;')
                ->endif
                ->blank
                ->line('    const char* upg = ws_strcasestr(conn, "Upgrade");');
        
        $builder->if('!upg || upg > conn + 128')
                    ->line('return 0;')
                ->endif
                ->blank
                ->comment('    Extract Sec-WebSocket-Key')
                ->line('    const char* key = ws_strcasestr(request, "Sec-WebSocket-Key:");');
        
        $builder->if('key')
                    ->line('key += 18;')
                    ->while('*key == \' \' || *key == \'\\t\'')
                        ->line('key++;')
                    ->endloop
                    ->blank
                    ->line('const char* end = key;')
                    ->while('*end && *end != \'\\r\' && *end != \'\\n\'')
                        ->line('end++;')
                    ->endloop
                    ->blank
                    ->comment('Trim trailing whitespace')
                    ->while('end > key && (*(end-1) == \' \' || *(end-1) == \'\\t\')')
                        ->line('end--;')
                    ->endloop
                    ->blank
                    ->line('size_t key_len = end - key;');
        
        $builder->if('key_len > 0 && key_len < sizeof(hs->ws_key)')
                        ->line('memcpy(hs->ws_key, key, key_len);')
                        ->line('hs->ws_key[key_len] = \'\\0\';')
                    ->endif
                ->endif
                ->blank
                ->comment('    Extract Sec-WebSocket-Version')
                ->line('    const char* ver = ws_strcasestr(request, "Sec-WebSocket-Version:");');
        
        $builder->if('ver')
                    ->line('ver += 22;')
                    ->while('*ver == \' \' || *ver == \'\\t\'')
                        ->line('ver++;')
                    ->endloop
                    ->line('hs->ws_version = atoi(ver);')
                ->endif
                ->blank
                ->comment('    Extract Sec-WebSocket-Protocol (optional)')
                ->line('    const char* proto = ws_strcasestr(request, "Sec-WebSocket-Protocol:");');
        
        $builder->if('proto')
                    ->line('proto += 23;')
                    ->while('*proto == \' \' || *proto == \'\\t\'')
                        ->line('proto++;')
                    ->endloop
                    ->blank
                    ->line('const char* end = proto;')
                    ->while('*end && *end != \'\\r\' && *end != \'\\n\'')
                        ->line('end++;')
                    ->endloop
                    ->blank
                    ->line('size_t proto_len = end - proto;');
        
        $builder->if('proto_len > 0 && proto_len < sizeof(hs->ws_protocol)')
                        ->line('memcpy(hs->ws_protocol, proto, proto_len);')
                        ->line('hs->ws_protocol[proto_len] = \'\\0\';')
                    ->endif
                ->endif
                ->blank
                ->comment('    Valid if we have key and version 13')
                ->line('    hs->is_websocket = (hs->ws_key[0] != \'\\0\' && hs->ws_version == 13);')
            ->line('    return hs->is_websocket;')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate 101 Switching Protocols response builder
sub gen_handshake_response {
    my ($class, $builder) = @_;
    
    $builder->comment('Build and send WebSocket handshake response')
            ->comment('Returns bytes sent, or -1 on error')
            ->line('static int send_ws_handshake_response(int fd, const char* client_key, const char* protocol) {')
            ->line('    char accept_key[64];')
            ->line('    calc_websocket_accept(client_key, accept_key);')
            ->blank;
        
        $builder->if('accept_key[0] == \'\\0\'')
                    ->line('return -1;')
                ->endif
                ->blank
                ->line('    char response[512];')
                ->line('    int len;')
                ->blank;
        
        $builder->if('protocol && protocol[0]')
                    ->comment('Include negotiated subprotocol')
                    ->line('len = snprintf(response, sizeof(response),')
                    ->line('    "HTTP/1.1 101 Switching Protocols\\r\\n"')
                    ->line('    "Upgrade: websocket\\r\\n"')
                    ->line('    "Connection: Upgrade\\r\\n"')
                    ->line('    "Sec-WebSocket-Accept: %s\\r\\n"')
                    ->line('    "Sec-WebSocket-Protocol: %s\\r\\n"')
                    ->line('    "\\r\\n",')
                    ->line('    accept_key, protocol);')
                ->else
                    ->line('len = snprintf(response, sizeof(response),')
                    ->line('    "HTTP/1.1 101 Switching Protocols\\r\\n"')
                    ->line('    "Upgrade: websocket\\r\\n"')
                    ->line('    "Connection: Upgrade\\r\\n"')
                    ->line('    "Sec-WebSocket-Accept: %s\\r\\n"')
                    ->line('    "\\r\\n",')
                    ->line('    accept_key);')
                ->endif
                ->blank;
        
        $builder->if('len >= (int)sizeof(response)')
                    ->line('return -1;')
                ->endif
                ->blank
            ->line('    return send(fd, response, len, 0);')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate error response functions
sub gen_error_responses {
    my ($class, $builder) = @_;
    
    $builder->comment('Send 400 Bad Request for malformed WebSocket requests')
            ->line('static int send_ws_bad_request(int fd) {')
            ->line('    static const char resp[] =')
            ->line('        "HTTP/1.1 400 Bad Request\\r\\n"')
            ->line('        "Content-Type: text/plain\\r\\n"')
            ->line('        "Content-Length: 11\\r\\n"')
            ->line('        "Connection: close\\r\\n"')
            ->line('        "\\r\\n"')
            ->line('        "Bad Request";')
            ->line('    return send(fd, resp, sizeof(resp) - 1, 0);')
            ->line('}')
            ->blank
            ->comment('Send 426 Upgrade Required for wrong WebSocket version')
            ->line('static int send_ws_upgrade_required(int fd) {')
            ->line('    static const char resp[] =')
            ->line('        "HTTP/1.1 426 Upgrade Required\\r\\n"')
            ->line('        "Sec-WebSocket-Version: 13\\r\\n"')
            ->line('        "Content-Type: text/plain\\r\\n"')
            ->line('        "Content-Length: 26\\r\\n"')
            ->line('        "Connection: close\\r\\n"')
            ->line('        "\\r\\n"')
            ->line('        "WebSocket version 13 only";')
            ->line('    return send(fd, resp, sizeof(resp) - 1, 0);')
            ->line('}')
            ->blank
            ->comment('Send 403 Forbidden for origin check failure')
            ->line('static int send_ws_forbidden(int fd) {')
            ->line('    static const char resp[] =')
            ->line('        "HTTP/1.1 403 Forbidden\\r\\n"')
            ->line('        "Content-Type: text/plain\\r\\n"')
            ->line('        "Content-Length: 14\\r\\n"')
            ->line('        "Connection: close\\r\\n"')
            ->line('        "\\r\\n"')
            ->line('        "Origin denied";')
            ->line('    return send(fd, resp, sizeof(resp) - 1, 0);')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate protocol negotiation helper
sub gen_protocol_negotiation {
    my ($class, $builder) = @_;
    
    $builder->comment('Check if requested protocol is in comma-separated list')
            ->comment('Returns pointer to matched protocol, or NULL')
            ->line('static const char* ws_negotiate_protocol(const char* requested, const char* supported) {');
    
    $builder->if('!requested || !requested[0] || !supported || !supported[0]')
                ->line('return NULL;')
            ->endif
            ->blank
            ->comment('    Parse comma-separated requested protocols')
            ->line('    char buf[128];')
            ->line('    strncpy(buf, requested, sizeof(buf) - 1);')
            ->line('    buf[sizeof(buf) - 1] = \'\\0\';')
            ->blank
            ->line('    char* token = strtok(buf, ", ");');
    
    $builder->while('token')
                ->comment('Skip whitespace')
                ->while('*token == \' \'')
                    ->line('token++;')
                ->endloop
                ->blank
                ->comment('Check if this protocol is supported');
    
    $builder->if('strstr(supported, token)')
                    ->line('return token;')
                ->endif
                ->blank
                ->line('token = strtok(NULL, ", ");')
            ->endloop
            ->blank
            ->line('    return NULL;')
            ->line('}')
            ->blank;
    
    $builder->comment('Extract first protocol from list (for simple cases)')
            ->line('static void ws_first_protocol(const char* list, char* out, size_t out_size) {');
    
    $builder->if('!list || !list[0]')
                ->line('out[0] = \'\\0\';')
                ->line('return;')
            ->endif
            ->blank
            ->line('    const char* end = list;')
            ->while('*end && *end != \',\' && *end != \' \'')
                ->line('end++;')
            ->endloop
            ->blank
            ->line('    size_t len = end - list;');
    
    $builder->if('len >= out_size')
                ->line('len = out_size - 1;')
            ->endif
            ->blank
            ->line('    memcpy(out, list, len);')
            ->line('    out[len] = \'\\0\';')
            ->line('}')
            ->blank;
    
    return $builder;
}

# Generate all WebSocket handshake C code
sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    
    $class->gen_includes($builder);
    $class->gen_handshake_struct($builder);
    $class->gen_accept_key($builder);
    $class->gen_handshake_parser($builder);
    $class->gen_handshake_response($builder);
    $class->gen_error_responses($builder);
    $class->gen_protocol_negotiation($builder);
    
    return $builder;
}

#
# Perl-side helpers for testing and fallback
#

# Calculate accept key in pure Perl (for testing)
sub calc_accept_key {
    my ($class, $client_key) = @_;
    
    require Digest::SHA;
    require MIME::Base64;
    
    my $concat = $client_key . $WS_GUID;
    my $sha1 = Digest::SHA::sha1($concat);
    my $accept = MIME::Base64::encode_base64($sha1, '');
    
    return $accept;
}

# Parse WebSocket headers from request string (Perl fallback)
sub parse_handshake {
    my ($class, $request) = @_;
    
    my %result = (
        is_websocket => 0,
        ws_key       => '',
        ws_version   => 0,
        ws_protocol  => '',
    );
    
    # Check Upgrade: websocket
    return \%result unless $request =~ /Upgrade:\s*websocket/i;
    
    # Check Connection: Upgrade
    return \%result unless $request =~ /Connection:.*Upgrade/i;
    
    # Extract Sec-WebSocket-Key
    if ($request =~ /Sec-WebSocket-Key:\s*(\S+)/i) {
        $result{ws_key} = $1;
    }
    
    # Extract Sec-WebSocket-Version
    if ($request =~ /Sec-WebSocket-Version:\s*(\d+)/i) {
        $result{ws_version} = int($1);
    }
    
    # Extract Sec-WebSocket-Protocol
    if ($request =~ /Sec-WebSocket-Protocol:\s*([^\r\n]+)/i) {
        $result{ws_protocol} = $1;
        $result{ws_protocol} =~ s/\s+$//;  # Trim trailing
    }
    
    # Valid if we have key and version 13
    $result{is_websocket} = ($result{ws_key} && $result{ws_version} == 13) ? 1 : 0;
    
    return \%result;
}

# Build handshake response in Perl
sub build_response {
    my ($class, %args) = @_;
    
    my $client_key = $args{key} or return '';
    my $protocol   = $args{protocol};
    
    my $accept = $class->calc_accept_key($client_key);
    
    my $response = "HTTP/1.1 101 Switching Protocols\r\n"
                 . "Upgrade: websocket\r\n"
                 . "Connection: Upgrade\r\n"
                 . "Sec-WebSocket-Accept: $accept\r\n";
    
    if ($protocol) {
        $response .= "Sec-WebSocket-Protocol: $protocol\r\n";
    }
    
    $response .= "\r\n";
    
    return $response;
}

# Validate WebSocket key format (16 bytes base64 = 24 chars)
sub validate_key {
    my ($class, $key) = @_;
    
    return 0 unless defined $key && length($key) == 24;
    return 0 unless $key =~ m{^[A-Za-z0-9+/]{22}==$};
    
    return 1;
}

1;

__END__

=head1 NAME

Hypersonic::Protocol::WebSocket - WebSocket handshake code generation

=head1 SYNOPSIS

    use Hypersonic::Protocol::WebSocket;
    
    # Generate C code for JIT compilation
    my $code = Hypersonic::Protocol::WebSocket->generate_c_code($builder);
    
    # Perl-side testing
    my $accept = Hypersonic::Protocol::WebSocket->calc_accept_key($key);
    my $hs = Hypersonic::Protocol::WebSocket->parse_handshake($request);

=head1 DESCRIPTION

Implements RFC 6455 WebSocket opening handshake. All C code is generated
at compile time for JIT compilation - zero runtime overhead.

=head1 RFC 6455 COMPLIANCE

=over 4

=item * Sec-WebSocket-Version: Only version 13 supported (returns 426 otherwise)

=item * Sec-WebSocket-Accept: SHA1 + Base64 per spec

=item * Sec-WebSocket-Protocol: Optional subprotocol negotiation

=back

=head1 SEE ALSO

L<Hypersonic::Protocol::WebSocket::Frame> for frame encoding/decoding.

=cut
