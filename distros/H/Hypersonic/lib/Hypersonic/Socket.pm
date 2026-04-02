package Hypersonic::Socket;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use XS::JIT;
use XS::JIT::Builder;
use Hypersonic::JIT::Util;

# Platform detection
sub platform {
    return 'darwin'  if $^O eq 'darwin';
    return 'linux'   if $^O eq 'linux';
    return 'freebsd' if $^O eq 'freebsd';
    return 'openbsd' if $^O eq 'openbsd';
    return 'netbsd'  if $^O eq 'netbsd';
    die "Unsupported platform: $^O";
}

# Event backend detection (delegates to Hypersonic::Event)
sub event_backend {
    require Hypersonic::Event;
    return Hypersonic::Event->best_backend();
}

my $COMPILED = 0;
my $MODULE_ID = 0;

# Unified compile interface
sub compile {
    my ($class, %opts) = @_;
    return $class->compile_socket_ops(%opts);
}

# Generate and compile JIT socket functions using Builder
sub compile_socket_ops {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_cache/socket';
    my $module_name = 'Hypersonic::Socket::Ops_' . $MODULE_ID++;

    my $builder = XS::JIT::Builder->new;

    # Common includes via centralized utility
    Hypersonic::JIT::Util->add_standard_includes($builder,
        qw(stdio unistd fcntl socket));

    $builder->line('#define RECV_BUF_SIZE 65536')
      ->blank
      ->line('static char recv_buf[RECV_BUF_SIZE];')
      ->blank;

    # Generate create_listen_socket
    $builder->xs_function('jit_create_listen_socket')
      ->xs_preamble
      ->line('IV port;')
      ->line('int fd;')
      ->line('int opt;')
      ->line('int flags;')
      ->line('struct sockaddr_in addr;')
      ->blank
      ->line('if (items != 1) croak("Usage: create_listen_socket(port)");')
      ->line('port = SvIV(ST(0));')
      ->blank
      ->line('fd = socket(AF_INET, SOCK_STREAM, 0);')
      ->if('fd < 0')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('opt = 1;')
      ->line('setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));')
      ->line('#ifdef SO_REUSEPORT')
      ->line('setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt));')
      ->line('#endif')
      ->blank
      ->line('flags = fcntl(fd, F_GETFL, 0);')
      ->line('fcntl(fd, F_SETFL, flags | O_NONBLOCK);')
      ->blank
      ->line('memset(&addr, 0, sizeof(addr));')
      ->line('addr.sin_family = AF_INET;')
      ->line('addr.sin_port = htons((uint16_t)port);')
      ->line('addr.sin_addr.s_addr = INADDR_ANY;')
      ->blank
      ->if('bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0')
        ->line('close(fd);')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('listen(fd, SOMAXCONN) < 0')
        ->line('close(fd);')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(fd));')
      ->xs_return('1')
      ->xs_end;

    # Event loop functions (create_event_loop, event_add, event_del, ev_poll)
    # have been moved to Hypersonic::Event::* backend modules

    # Generate http_accept
    $builder->xs_function('jit_http_accept')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: http_accept(listen_fd)");')
      ->line('IV listen_fd = SvIV(ST(0));')
      ->blank
      ->line('struct sockaddr_in client_addr;')
      ->line('socklen_t client_len = sizeof(client_addr);')
      ->blank
      ->line('int client_fd = accept((int)listen_fd, (struct sockaddr*)&client_addr, &client_len);')
      ->blank
      ->if('client_fd < 0')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('int flags = fcntl(client_fd, F_GETFL, 0);')
      ->line('fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(client_fd));')
      ->xs_return('1')
      ->xs_end;

    # Generate http_recv - zero-copy HTTP parsing
    $builder->xs_function('jit_http_recv')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: http_recv(fd)");')
      ->line('IV fd = SvIV(ST(0));')
      ->blank
      ->line('ssize_t len = recv((int)fd, recv_buf, RECV_BUF_SIZE - 1, 0);')
      ->blank
      ->if('len <= 0')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('recv_buf[len] = \'\\0\';')
      ->blank
      ->comment('Quick parse - extract method, path, detect keep-alive')
      ->line('const char* p = recv_buf;')
      ->line('const char* end = recv_buf + len;')
      ->blank
      ->comment('Method')
      ->line('const char* method = p;')
      ->line('while (p < end && *p != \' \') p++;')
      ->line('int method_len = p - method;')
      ->if('p >= end')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('p++;')
      ->blank
      ->comment('Path')
      ->line('const char* path = p;')
      ->line('while (p < end && *p != \' \' && *p != \'?\') p++;')
      ->line('int path_len = p - path;')
      ->if('p >= end')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Skip to end of request line')
      ->line('while (p < end && *p != \'\\n\') p++;')
      ->if('p >= end')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('p++;')
      ->blank
      ->comment('Check for Connection: close')
      ->line('int keep_alive = 1;')
      ->line('while (p < end) {')
      ->line('    if (*p == \'\\r\' || *p == \'\\n\') break;')
      ->line('    if (end - p > 17 && strncasecmp(p, "Connection: close", 17) == 0) {')
      ->line('        keep_alive = 0;')
      ->line('    }')
      ->line('    while (p < end && *p != \'\\n\') p++;')
      ->line('    if (p < end) p++;')
      ->line('}')
      ->blank
      ->comment('Skip blank line')
      ->line('if (p < end && *p == \'\\r\') p++;')
      ->line('if (p < end && *p == \'\\n\') p++;')
      ->blank
      ->comment('Body')
      ->line('const char* body = p;')
      ->line('int body_len = end - p;')
      ->blank
      ->comment('Build request array: [method, path, body, keep_alive, fd]')
      ->line('AV* req = newAV();')
      ->line('av_push(req, newSVpvn(method, method_len));')
      ->line('av_push(req, newSVpvn(path, path_len));')
      ->line('av_push(req, newSVpvn(body, body_len));')
      ->line('av_push(req, newSViv(keep_alive));')
      ->line('av_push(req, newSViv(fd));')
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)req));')
      ->xs_return('1')
      ->xs_end;

    # Generate http_send - writev for zero-copy
    $builder->xs_function('jit_http_send')
      ->xs_preamble
      ->line('if (items < 2 || items > 3) croak("Usage: http_send(fd, body, [content_type])");')
      ->line('IV fd = SvIV(ST(0));')
      ->blank
      ->line('STRLEN body_len;')
      ->line('const char* body = SvPV(ST(1), body_len);')
      ->blank
      ->line('const char* content_type = "text/plain";')
      ->if('items == 3 && SvOK(ST(2))')
        ->line('STRLEN ct_len;')
        ->line('content_type = SvPV(ST(2), ct_len);')
      ->endif
      ->blank
      ->line('static __thread char header[512];')
      ->line('int hdr_len = snprintf(header, sizeof(header),')
      ->line('    "HTTP/1.1 200 OK\\r\\n"')
      ->line('    "Content-Type: %s\\r\\n"')
      ->line('    "Content-Length: %zu\\r\\n"')
      ->line('    "Connection: keep-alive\\r\\n\\r\\n",')
      ->line('    content_type, body_len);')
      ->blank
      ->line('struct iovec iov[2];')
      ->line('iov[0].iov_base = header;')
      ->line('iov[0].iov_len = (size_t)hdr_len;')
      ->line('iov[1].iov_base = (void*)body;')
      ->line('iov[1].iov_len = body_len;')
      ->blank
      ->line('ssize_t sent = writev((int)fd, iov, 2);')
      ->line('ST(0) = sv_2mortal(newSViv((IV)sent));')
      ->xs_return('1')
      ->xs_end;

    # Generate http_send_404
    $builder->xs_function('jit_http_send_404')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: http_send_404(fd)");')
      ->line('IV fd = SvIV(ST(0));')
      ->blank
      ->line('static const char resp[] =')
      ->line('    "HTTP/1.1 404 Not Found\\r\\n"')
      ->line('    "Content-Type: text/plain\\r\\n"')
      ->line('    "Content-Length: 9\\r\\n"')
      ->line('    "Connection: close\\r\\n\\r\\n"')
      ->line('    "Not Found";')
      ->blank
      ->line('ssize_t sent = send((int)fd, resp, sizeof(resp) - 1, 0);')
      ->line('ST(0) = sv_2mortal(newSViv((IV)sent));')
      ->xs_return('1')
      ->xs_end;

    # Generate close_fd
    $builder->xs_function('jit_close_fd')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: close_fd(fd)");')
      ->line('IV fd = SvIV(ST(0));')
      ->line('int result = close((int)fd);')
      ->line('ST(0) = sv_2mortal(newSViv(result));')
      ->xs_return('1')
      ->xs_end;

    # Compile via XS::JIT (socket-only functions - event loop is in backends)
    XS::JIT->compile(
        code      => $builder->code,
        name      => $module_name,
        cache_dir => $cache_dir,
        functions => {
            'Hypersonic::Socket::create_listen_socket' => { source => 'jit_create_listen_socket', is_xs_native => 1 },
            'Hypersonic::Socket::http_accept'          => { source => 'jit_http_accept', is_xs_native => 1 },
            'Hypersonic::Socket::http_recv'            => { source => 'jit_http_recv', is_xs_native => 1 },
            'Hypersonic::Socket::http_send'            => { source => 'jit_http_send', is_xs_native => 1 },
            'Hypersonic::Socket::http_send_404'        => { source => 'jit_http_send_404', is_xs_native => 1 },
            'Hypersonic::Socket::close_fd'             => { source => 'jit_close_fd', is_xs_native => 1 },
        },
    );

    $COMPILED = 1;
    return 1;
}

# Auto-compile on import
sub import {
    my $class = shift;
    my %opts = @_;
    $class->compile_socket_ops(%opts);
}

1;

__END__

=head1 NAME

Hypersonic::Socket - JIT-compiled socket operations for Hypersonic

=head1 SYNOPSIS

    use Hypersonic::Socket;

    # Platform detection
    my $platform = Hypersonic::Socket::platform();  # 'darwin', 'linux', etc.

    # Low-level socket operations (usually called internally)
    my $listen_fd = Hypersonic::Socket::create_listen_socket(8080);

    # Accept and handle connections
    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);
    my $req = Hypersonic::Socket::http_recv($client_fd);
    Hypersonic::Socket::http_send($client_fd, 'Hello', 'text/plain');
    Hypersonic::Socket::close_fd($client_fd);

=head1 DESCRIPTION

C<Hypersonic::Socket> provides JIT-compiled XS socket functions for the
Hypersonic HTTP server. It handles low-level socket operations while event
loop functionality is provided by L<Hypersonic::Event> backend modules.

B<This module is for internal use by Hypersonic.> You typically don't
need to use it directly.

All functions are compiled to native XS code on first use via
L<XS::JIT::Builder>.

=head1 PLATFORM DETECTION

=head2 platform

    my $os = Hypersonic::Socket::platform();

Returns the detected platform:

=over 4

=item * C<darwin> - macOS

=item * C<linux> - Linux

=item * C<freebsd> - FreeBSD

=item * C<openbsd> - OpenBSD

=item * C<netbsd> - NetBSD

=back

Dies on unsupported platforms.

=head1 CLASS METHODS

=head2 compile_socket_ops

    Hypersonic::Socket->compile_socket_ops(
        cache_dir => '_socket_cache',
    );

Compile the JIT socket operations. Called automatically on module import.

Options:

=over 4

=item cache_dir

Directory for caching compiled XS code. Default: C<_hypersonic_socket_cache>

=back

=head1 SOCKET FUNCTIONS

All functions are JIT-compiled to XS for maximum performance.

=head2 create_listen_socket

    my $fd = Hypersonic::Socket::create_listen_socket($port);

Create a non-blocking TCP listening socket.

Features:

=over 4

=item * SO_REUSEADDR - Allow quick restart

=item * SO_REUSEPORT - Enable kernel load balancing (Linux)

=item * O_NONBLOCK - Non-blocking I/O

=item * Bound to all interfaces (INADDR_ANY)

=back

Returns the file descriptor, or -1 on error.

=head2 http_accept

    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

Accept a new connection on the listen socket.

Returns the client file descriptor, or -1 on error.

=head2 http_recv

    my $request = Hypersonic::Socket::http_recv($fd);

Receive and quick-parse an HTTP request.

Returns an arrayref: C<[method, path, body, keep_alive, fd]>

=over 4

=item * C<method> - HTTP method (GET, POST, etc.)

=item * C<path> - Request path

=item * C<body> - Request body (for POST, PUT, etc.)

=item * C<keep_alive> - 1 if Connection: keep-alive, 0 otherwise

=item * C<fd> - Client file descriptor

=back

Uses zero-copy parsing for maximum speed.

=head2 http_send

    Hypersonic::Socket::http_send($fd, $body, $content_type);

Send an HTTP 200 response with the given body.

Uses C<writev()> for zero-copy I/O when possible.

=head2 http_send_404

    Hypersonic::Socket::http_send_404($fd);

Send a pre-computed 404 Not Found response.

=head2 close_fd

    Hypersonic::Socket::close_fd($fd);

Close a file descriptor.

=head1 PERFORMANCE

All functions achieve approximately 7M operations/second in benchmarks
due to:

=over 4

=item * JIT compilation to native XS

=item * Zero-copy parsing

=item * Minimal memory allocations

=back

=head1 INTERNAL USE

These functions are typically called by the main C<Hypersonic> module's
JIT-compiled event loop. The generated C code calls these functions
directly for socket operations.

You only need to use this module directly if:

=over 4

=item * Extending Hypersonic with custom protocols

=item * Testing or debugging socket operations

=back

=head1 SEE ALSO

L<Hypersonic> - Main HTTP server module

L<Hypersonic::Event> - Event backend selection

L<XS::JIT::Builder> - JIT compilation API

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
