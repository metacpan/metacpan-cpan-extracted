package Hypersonic::Protocol::HTTP1;
use strict;
use warnings;

# Hypersonic::Protocol::HTTP1 - JIT code generation for HTTP/1.1 protocol
#
# This module provides compile-time code generation methods for HTTP/1.1
# protocol handling. All methods return C code strings or use XS::JIT::Builder
# to generate code. There is NO runtime overhead - everything is JIT compiled.
#
# HTTP/1.1 specific features handled here:
# - Text-based request parsing (GET /path HTTP/1.1\r\n)
# - CRLF delimiters (\r\n\r\n header/body separator)
# - Connection: keep-alive/close header
# - Response format (HTTP/1.1 200 OK\r\nHeader: Value\r\n\r\nBody)

our $VERSION = '0.12';

# Protocol identifier - used for version negotiation
sub protocol_id { 'HTTP/1.1' }

# HTTP version string for responses
sub version_string { 'HTTP/1.1' }

# Generate a complete HTTP/1.1 response at compile time
# Returns the full response string with headers and body
sub build_response {
    my ($class, %args) = @_;
    
    my $status       = $args{status} // 200;
    my $status_text  = $args{status_text} // _status_text($status);
    my $headers      = $args{headers} // {};
    my $body         = $args{body} // '';
    my $keep_alive   = $args{keep_alive} // 1;
    my $security_headers = $args{security_headers} // '';
    
    my $ct = $headers->{'Content-Type'}
          // (($body =~ /^\s*[\[{]/) ? 'application/json' : 'text/plain');
    
    my $response = "HTTP/1.1 $status $status_text\r\n"
                 . "Content-Type: $ct\r\n"
                 . "Content-Length: " . length($body) . "\r\n"
                 . "Connection: " . ($keep_alive ? 'keep-alive' : 'close') . "\r\n";
    
    # Add security headers if provided
    $response .= $security_headers if $security_headers;
    
    # Add custom headers
    for my $h (keys %$headers) {
        next if $h eq 'Content-Type' || $h eq 'Content-Length' || $h eq 'Connection';
        $response .= "$h: $headers->{$h}\r\n";
    }
    
    $response .= "\r\n" . $body;
    
    return $response;
}

# Build 404 response at compile time
sub build_404_response {
    my ($class, %args) = @_;
    my $security_headers = $args{security_headers} // '';
    
    return $class->build_response(
        status      => 404,
        status_text => 'Not Found',
        body        => 'Not Found',
        keep_alive  => 0,  # Close on 404
        security_headers => $security_headers,
    );
}

# Generate C code for parsing HTTP method from request buffer
# Uses XS::JIT::Builder API for clean code generation
sub gen_method_parser {
    my ($class, $builder, $analysis) = @_;
    
    my %methods_used = %{$analysis->{methods_used} // {}};
    
    # Method lengths: GET=3, PUT=3, POST=4, HEAD=4, PATCH=5, DELETE=6, OPTIONS=7
    my %method_lens = (
        GET => 3, PUT => 3, POST => 4, HEAD => 4,
        PATCH => 5, DELETE => 6, OPTIONS => 7
    );
    
    # Group methods by length
    my %by_length;
    for my $method (keys %methods_used) {
        my $len = $method_lens{$method} // length($method);
        push @{$by_length{$len}}, $method;
    }
    
    # If single method, generate super-optimized check
    if ($analysis->{single_method}) {
        my $method = $analysis->{single_method};
        my $len = $method_lens{$method};
        my $first_char = substr($method, 0, 1);
        my $path_offset = $len + 1;
        
        $builder->comment("OPTIMIZED: Single method ($method) - verify first char only")
          ->line('const char* method = recv_buf;')
          ->line("int method_len = $len;")
          ->line("const char* path = recv_buf + $path_offset;")
          ->blank
          ->comment("Quick validation: first char must be '$first_char'")
          ->if("recv_buf[0] != '$first_char'")
            ->line('HYPERSONIC_SEND(fd, RESP_404, RESP_404_LEN);')
            ->line('continue;')
          ->endif;
        
        return $builder;
    }
    
    # Multiple methods - generate only the length checks we need
    $builder->comment('HTTP/1.1: Parse method (space-delimited)')
      ->line('const char* method = recv_buf;')
      ->line('int method_len;')
      ->line('const char* path;')
      ->blank;
    
    my $first = 1;
    for my $len (sort { $a <=> $b } keys %by_length) {
        my @methods_at_len = @{$by_length{$len}};
        my $comment = join(', ', @methods_at_len);
        my $path_offset = $len + 1;
        
        if ($first) {
            $builder->if("recv_buf[$len] == ' '");
            $first = 0;
        } else {
            $builder->elsif("recv_buf[$len] == ' '");
        }
        $builder->line("method_len = $len;  /* $comment */")
          ->line("path = recv_buf + $path_offset;");
    }
    
    # Add fallback for unknown methods
    $builder->else
      ->comment('Fallback: scan for space')
      ->line('const char* sp = recv_buf;')
      ->while('*sp && *sp != \' \'')
        ->line('sp++;')
      ->endwhile
      ->line('method_len = sp - recv_buf;')
      ->line('path = sp + 1;')
    ->endif;
    
    return $builder;
}

# Generate C code for parsing path from HTTP/1.1 request
# HTTP/1.1 format: METHOD /path?query HTTP/1.1\r\n
sub gen_path_parser {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/1.1: Find end of path (space before HTTP/1.1)')
      ->line('const char* path_end = path;')
      ->line('int full_path_len;')
      ->line('const char* query_pos;')
      ->line('int path_len;')
      ->while('*path_end && *path_end != \' \'')
        ->line('path_end++;')
      ->endwhile
      ->line('full_path_len = path_end - path;')
      ->blank
      ->comment('Strip query string for route dispatch')
      ->line('query_pos = memchr(path, \'?\', full_path_len);')
      ->line('path_len = query_pos ? (query_pos - path) : full_path_len;');
    
    return $builder;
}

# Generate C code for finding request body (after \r\n\r\n)
sub gen_body_parser {
    my ($class, $builder, %opts) = @_;
    
    if ($opts{has_body_access}) {
        $builder->comment('HTTP/1.1: Find body after CRLF CRLF')
          ->line('const char* body_start = strstr(recv_buf, "\\r\\n\\r\\n");')
          ->line('const char* body = "";')
          ->line('int body_len = 0;')
          ->if('body_start')
            ->line('body = body_start + 4;')  # Skip \r\n\r\n
            ->line('body_len = len - (body - recv_buf);')
          ->endif;
    } else {
        $builder->comment('OPTIMIZED: No body parsing needed')
          ->line('const char* body = "";')
          ->line('int body_len = 0;');
    }
    
    return $builder;
}

# Generate C code for keep-alive detection
sub gen_keepalive_check {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/1.1: Check Connection header for keep-alive')
      ->line('int keep_alive = 1;')  # HTTP/1.1 default is keep-alive
      ->if('len > 20')
        ->comment('Search for "Connection:" header (case-insensitive C or c)')
        ->line('const char* conn = strstr(recv_buf + 16, "onnection:");')
        ->if('conn && (conn[-1] == \'C\' || conn[-1] == \'c\')')
          ->if('strstr(conn, "close") || strstr(conn, "Close")')
            ->line('keep_alive = 0;')
          ->endif
        ->endif
      ->endif;
    
    return $builder;
}

# Status code to text mapping (complete list)
sub _status_text {
    my ($code) = @_;
    my %text = (
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        204 => 'No Content',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        307 => 'Temporary Redirect',
        308 => 'Permanent Redirect',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        408 => 'Request Timeout',
        409 => 'Conflict',
        410 => 'Gone',
        413 => 'Payload Too Large',
        415 => 'Unsupported Media Type',
        422 => 'Unprocessable Entity',
        429 => 'Too Many Requests',
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Timeout',
    );
    return $text{$code} // 'Unknown';
}

# Get status text (class method for external use)
sub status_text {
    my ($class, $code) = @_;
    return _status_text($code);
}

# ============================================================
# Chunked Transfer Encoding (HTTP/1.1 streaming)
# ============================================================

# Generate C code for chunked response headers
sub gen_chunked_start {
    my ($class, $builder) = @_;
    
    $builder->comment('Send HTTP/1.1 headers with chunked encoding')
      ->line('static void send_chunked_headers(int fd, int status, const char* content_type) {')
      ->line('    char headers[2048];')
      ->line('    const char* status_str = "OK";')
      ->line('    switch(status) {')
      ->line('        case 200: status_str = "OK"; break;')
      ->line('        case 201: status_str = "Created"; break;')
      ->line('        case 202: status_str = "Accepted"; break;')
      ->line('        case 204: status_str = "No Content"; break;')
      ->line('        case 206: status_str = "Partial Content"; break;')
      ->line('        case 400: status_str = "Bad Request"; break;')
      ->line('        case 401: status_str = "Unauthorized"; break;')
      ->line('        case 403: status_str = "Forbidden"; break;')
      ->line('        case 404: status_str = "Not Found"; break;')
      ->line('        case 500: status_str = "Internal Server Error"; break;')
      ->line('        case 503: status_str = "Service Unavailable"; break;')
      ->line('    }')
      ->line('    int len = snprintf(headers, sizeof(headers),')
      ->line('        "HTTP/1.1 %d %s\\r\\n"')
      ->line('        "Content-Type: %s\\r\\n"')
      ->line('        "Transfer-Encoding: chunked\\r\\n"')
      ->line('        "Connection: keep-alive\\r\\n"')
      ->line('        "\\r\\n",')
      ->line('        status, status_str, content_type);')
      ->line('    send(fd, headers, len, 0);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate C code for sending a chunk (hex length + data + CRLF)
sub gen_chunked_write {
    my ($class, $builder) = @_;
    
    $builder->comment('Send a single chunk - HTTP/1.1 chunked transfer encoding')
      ->line('static void send_chunk(int fd, const char* data, size_t len) {')
      ->line('    if (len == 0) return;')
      ->line('    ')
      ->line('    char size_line[32];')
      ->line('    int header_len = snprintf(size_line, sizeof(size_line), "%zx\\r\\n", len);')
      ->line('    ')
      ->line('    /* Use writev for efficiency (header + data + crlf in one syscall) */')
      ->line('    struct iovec iov[3];')
      ->line('    iov[0].iov_base = size_line;')
      ->line('    iov[0].iov_len = header_len;')
      ->line('    iov[1].iov_base = (void*)data;')
      ->line('    iov[1].iov_len = len;')
      ->line('    iov[2].iov_base = "\\r\\n";')
      ->line('    iov[2].iov_len = 2;')
      ->line('    ')
      ->line('    writev(fd, iov, 3);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate C code for final chunk (0\r\n\r\n)
sub gen_chunked_end {
    my ($class, $builder) = @_;
    
    $builder->comment('Send final zero-length chunk to end stream')
      ->line('static void send_chunk_end(int fd) {')
      ->line('    send(fd, "0\\r\\n\\r\\n", 5, 0);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Build a pre-formatted chunk for compile-time use
sub build_chunk {
    my ($class, $data) = @_;
    
    return '' unless defined $data && length($data);
    
    my $len = length($data);
    return sprintf("%x\r\n%s\r\n", $len, $data);
}

# Build final chunk
sub build_final_chunk {
    return "0\r\n\r\n";
}

1;

__END__

=head1 NAME

Hypersonic::Protocol::HTTP1 - JIT code generation for HTTP/1.1 protocol

=head1 SYNOPSIS

    use Hypersonic::Protocol::HTTP1;
    
    # Build a complete response at compile time
    my $response = Hypersonic::Protocol::HTTP1->build_response(
        status  => 200,
        headers => { 'X-Custom' => 'value' },
        body    => '{"ok":true}',
    );
    
    # Generate C code for method parsing
    Hypersonic::Protocol::HTTP1->gen_method_parser($builder, $analysis);

=head1 DESCRIPTION

This module provides JIT compile-time code generation for HTTP/1.1 protocol
handling. All methods either return pre-built strings or generate C code
using XS::JIT::Builder. There is zero runtime overhead.

=head2 HTTP/1.1 Specifics

=over 4

=item * Text-based request format: C<GET /path HTTP/1.1\r\n>

=item * CRLF delimiters: C<\r\n> between headers, C<\r\n\r\n> before body

=item * Keep-alive: Default in HTTP/1.1, detected via C<Connection: close>

=item * Response format: Status line + headers + body

=back

=head1 METHODS

=head2 build_response(%args)

Build a complete HTTP/1.1 response string at compile time.

=head2 gen_method_parser($builder, $analysis)

Generate C code for parsing HTTP method using XS::JIT::Builder.

=head2 gen_path_parser($builder)

Generate C code for parsing request path.

=head2 gen_body_parser($builder, %opts)

Generate C code for finding request body.

=head2 gen_keepalive_check($builder)

Generate C code for detecting Connection: close.

=head1 AUTHOR

Hypersonic Contributors

=cut
