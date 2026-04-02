package Hypersonic::UA::Socket;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant MAX_SOCKETS => 65536;
use constant RECV_BUF_SIZE => 65536;

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max = $opts->{max_sockets} // MAX_SOCKETS;

    $class->gen_includes($builder);
    $class->gen_socket_registry($builder, $max);
    $class->gen_xs_connect_to_host($builder);
    $class->gen_xs_connect_nonblocking($builder);
    $class->gen_xs_check_connect($builder);
    $class->gen_xs_send($builder);
    $class->gen_xs_send_nonblocking($builder);
    $class->gen_xs_recv($builder);
    $class->gen_xs_recv_nonblocking($builder);
    $class->gen_xs_recv_chunk($builder);
    $class->gen_xs_wait_readable($builder);
    $class->gen_xs_close($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Socket::connect_to_host'     => { source => 'xs_socket_connect_to_host', is_xs_native => 1 },
        'Hypersonic::UA::Socket::connect_nonblocking' => { source => 'xs_socket_connect_nonblocking', is_xs_native => 1 },
        'Hypersonic::UA::Socket::check_connect'       => { source => 'xs_socket_check_connect', is_xs_native => 1 },
        'Hypersonic::UA::Socket::send'                => { source => 'xs_socket_send', is_xs_native => 1 },
        'Hypersonic::UA::Socket::send_nonblocking'    => { source => 'xs_socket_send_nonblocking', is_xs_native => 1 },
        'Hypersonic::UA::Socket::recv'                => { source => 'xs_socket_recv', is_xs_native => 1 },
        'Hypersonic::UA::Socket::recv_nonblocking'    => { source => 'xs_socket_recv_nonblocking', is_xs_native => 1 },
        'Hypersonic::UA::Socket::recv_chunk'          => { source => 'xs_socket_recv_chunk', is_xs_native => 1 },
        'Hypersonic::UA::Socket::wait_readable'       => { source => 'xs_socket_wait_readable', is_xs_native => 1 },
        'Hypersonic::UA::Socket::close'               => { source => 'xs_socket_close', is_xs_native => 1 },
    };
}

sub gen_includes {
    my ($class, $builder) = @_;

    $builder->line('#include <stdio.h>')
      ->line('#include <stdlib.h>')
      ->line('#include <string.h>')
      ->line('#include <unistd.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <sys/types.h>')
      ->line('#include <sys/select.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <netinet/tcp.h>')
      ->line('#include <arpa/inet.h>')
      ->line('#include <netdb.h>')
      ->line('#include <sys/uio.h>')
      ->blank;
}

sub gen_socket_registry {
    my ($class, $builder, $max) = @_;

    $builder->line("#define SOCKET_MAX $max")
      ->line("#define SOCKET_RECV_BUF_SIZE " . RECV_BUF_SIZE)
      ->blank
      ->line('static char g_socket_recv_buf[SOCKET_RECV_BUF_SIZE];')
      ->blank;
}

sub gen_xs_connect_to_host {
    my ($class, $builder) = @_;

    $builder->comment('Connect to host with DNS resolution and timeout')
      ->xs_function('xs_socket_connect_to_host')
      ->xs_preamble
      ->line('STRLEN host_len;')
      ->line('const char* host;')
      ->line('int port;')
      ->line('int timeout_ms;')
      ->line('struct addrinfo hints, *res, *rp;')
      ->line('char port_str[8];')
      ->line('int fd = -1;')
      ->blank
      ->line('if (items != 3) croak("Usage: connect_to_host(host, port, timeout_ms)");')
      ->blank
      ->line('host = SvPV(ST(0), host_len);')
      ->line('port = (int)SvIV(ST(1));')
      ->line('timeout_ms = (int)SvIV(ST(2));')
      ->blank
      ->comment('DNS lookup')
      ->line('memset(&hints, 0, sizeof(hints));')
      ->line('hints.ai_family = AF_UNSPEC;')
      ->line('hints.ai_socktype = SOCK_STREAM;')
      ->blank
      ->line('snprintf(port_str, sizeof(port_str), "%d", port);')
      ->blank
      ->if('getaddrinfo(host, port_str, &hints, &res) != 0')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Try each address')
      ->line('for (rp = res; rp != NULL; rp = rp->ai_next) {')
      ->line('    fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);')
      ->line('    if (fd < 0) continue;')
      ->blank
      ->comment('    Set non-blocking for connect timeout')
      ->line('    int flags = fcntl(fd, F_GETFL, 0);')
      ->line('    fcntl(fd, F_SETFL, flags | O_NONBLOCK);')
      ->blank
      ->comment('    Disable Nagle')
      ->line('    int opt = 1;')
      ->line('    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &opt, sizeof(opt));')
      ->blank
      ->comment('    Non-blocking connect')
      ->line('    int ret = connect(fd, rp->ai_addr, rp->ai_addrlen);')
      ->line('    if (ret == 0) break;')
      ->line('    if (errno == EINPROGRESS) {')
      ->line('        fd_set wfds;')
      ->line('        FD_ZERO(&wfds);')
      ->line('        FD_SET(fd, &wfds);')
      ->line('        struct timeval tv;')
      ->line('        tv.tv_sec = timeout_ms / 1000;')
      ->line('        tv.tv_usec = (timeout_ms % 1000) * 1000;')
      ->line('        if (select(fd + 1, NULL, &wfds, NULL, &tv) > 0) {')
      ->line('            int error;')
      ->line('            socklen_t len = sizeof(error);')
      ->line('            getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &len);')
      ->line('            if (error == 0) break;')
      ->line('        }')
      ->line('    }')
      ->line('    close(fd);')
      ->line('    fd = -1;')
      ->line('}')
      ->blank
      ->line('freeaddrinfo(res);')
      ->blank
      ->comment('Set back to blocking')
      ->if('fd >= 0')
        ->line('int flags = fcntl(fd, F_GETFL, 0);')
        ->line('fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(fd));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_connect_nonblocking {
    my ($class, $builder) = @_;

    $builder->comment('Non-blocking connect - returns fd immediately')
      ->xs_function('xs_socket_connect_nonblocking')
      ->xs_preamble
      ->line('STRLEN host_len;')
      ->line('const char* host;')
      ->line('int port;')
      ->line('struct addrinfo hints, *res;')
      ->line('char port_str[8];')
      ->line('int fd;')
      ->line('int flags;')
      ->line('int opt;')
      ->line('int ret;')
      ->blank
      ->line('if (items != 2) croak("Usage: connect_nonblocking(host, port)");')
      ->blank
      ->line('host = SvPV(ST(0), host_len);')
      ->line('port = (int)SvIV(ST(1));')
      ->blank
      ->comment('DNS lookup')
      ->line('memset(&hints, 0, sizeof(hints));')
      ->line('hints.ai_family = AF_UNSPEC;')
      ->line('hints.ai_socktype = SOCK_STREAM;')
      ->blank
      ->line('snprintf(port_str, sizeof(port_str), "%d", port);')
      ->blank
      ->if('getaddrinfo(host, port_str, &hints, &res) != 0')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);')
      ->if('fd < 0')
        ->line('freeaddrinfo(res);')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Set non-blocking')
      ->line('flags = fcntl(fd, F_GETFL, 0);')
      ->line('fcntl(fd, F_SETFL, flags | O_NONBLOCK);')
      ->blank
      ->comment('Disable Nagle')
      ->line('opt = 1;')
      ->line('setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &opt, sizeof(opt));')
      ->blank
      ->comment('Start non-blocking connect')
      ->line('ret = connect(fd, res->ai_addr, res->ai_addrlen);')
      ->line('freeaddrinfo(res);')
      ->blank
      ->if('ret == 0 || errno == EINPROGRESS')
        ->line('ST(0) = sv_2mortal(newSViv(fd));')
      ->else
        ->line('close(fd);')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_check_connect {
    my ($class, $builder) = @_;

    $builder->comment('Check if non-blocking connect completed: 1=done, 0=pending, <0=error')
      ->xs_function('xs_socket_check_connect')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: check_connect(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('fd_set wfds;')
      ->line('FD_ZERO(&wfds);')
      ->line('FD_SET(fd, &wfds);')
      ->blank
      ->line('struct timeval tv = {0, 0};')
      ->blank
      ->line('int ret = select(fd + 1, NULL, &wfds, NULL, &tv);')
      ->if('ret == 0')
        ->line('ST(0) = sv_2mortal(newSViv(0));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('ret < 0')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('int error;')
      ->line('socklen_t len = sizeof(error);')
      ->line('getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &len);')
      ->blank
      ->if('error != 0')
        ->line('ST(0) = sv_2mortal(newSViv(-error));')
      ->else
        ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_send {
    my ($class, $builder) = @_;

    $builder->comment('Send data (blocking)')
      ->xs_function('xs_socket_send')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: send(fd, data)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->blank
      ->line('ssize_t total = 0;')
      ->line('while (total < (ssize_t)data_len) {')
      ->line('    ssize_t sent = send(fd, data + total, data_len - total, 0);')
      ->line('    if (sent < 0) {')
      ->line('        if (errno == EINTR) continue;')
      ->line('        break;')
      ->line('    }')
      ->line('    total += sent;')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv((IV)total));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_send_nonblocking {
    my ($class, $builder) = @_;

    $builder->comment('Non-blocking send: returns bytes sent, -2=EAGAIN, -1=error')
      ->xs_function('xs_socket_send_nonblocking')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: send_nonblocking(fd, data)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->blank
      ->line('ssize_t sent = send(fd, data, data_len, 0);')
      ->blank
      ->if('sent < 0')
        ->if('errno == EAGAIN || errno == EWOULDBLOCK')
          ->line('ST(0) = sv_2mortal(newSViv(-2));')
        ->else
          ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->endif
      ->else
        ->line('ST(0) = sv_2mortal(newSViv((IV)sent));')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv {
    my ($class, $builder) = @_;

    $builder->comment('Receive HTTP response with timeout')
      ->xs_function('xs_socket_recv')
      ->xs_preamble
      ->line('if (items < 1 || items > 2) croak("Usage: recv(fd, [timeout_ms])");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('int timeout_ms = (items > 1) ? (int)SvIV(ST(1)) : 30000;')
      ->blank
      ->comment('Set receive timeout')
      ->line('struct timeval tv;')
      ->line('tv.tv_sec = timeout_ms / 1000;')
      ->line('tv.tv_usec = (timeout_ms % 1000) * 1000;')
      ->line('setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));')
      ->blank
      ->line('size_t total = 0;')
      ->line('int headers_complete = 0;')
      ->line('int content_length = -1;')
      ->line('const char* body_start = NULL;')
      ->blank
      ->comment('Read until headers complete')
      ->line('while (!headers_complete && total < SOCKET_RECV_BUF_SIZE - 1) {')
      ->line('    ssize_t n = recv(fd, g_socket_recv_buf + total, SOCKET_RECV_BUF_SIZE - 1 - total, 0);')
      ->line('    if (n <= 0) break;')
      ->line('    total += n;')
      ->line('    g_socket_recv_buf[total] = \'\\0\';')
      ->blank
      ->line('    const char* hdr_end = strstr(g_socket_recv_buf, "\\r\\n\\r\\n");')
      ->line('    if (hdr_end) {')
      ->line('        headers_complete = 1;')
      ->line('        body_start = hdr_end + 4;')
      ->blank
      ->line('        const char* cl = strcasestr(g_socket_recv_buf, "\\r\\nContent-Length:");')
      ->line('        if (cl) content_length = atoi(cl + 17);')
      ->line('    }')
      ->line('}')
      ->blank
      ->if('!headers_complete')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Read body if Content-Length known')
      ->line('size_t body_received = total - (body_start - g_socket_recv_buf);')
      ->if('content_length > 0')
        ->line('while (body_received < (size_t)content_length && total < SOCKET_RECV_BUF_SIZE - 1) {')
        ->line('    ssize_t n = recv(fd, g_socket_recv_buf + total, SOCKET_RECV_BUF_SIZE - 1 - total, 0);')
        ->line('    if (n <= 0) break;')
        ->line('    total += n;')
        ->line('    body_received += n;')
        ->line('}')
      ->endif
      ->blank
      ->line('g_socket_recv_buf[total] = \'\\0\';')
      ->line('ST(0) = sv_2mortal(newSVpvn(g_socket_recv_buf, total));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv_nonblocking {
    my ($class, $builder) = @_;

    $builder->comment('Non-blocking recv: returns data, empty string=closed, undef=EAGAIN')
      ->xs_function('xs_socket_recv_nonblocking')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: recv_nonblocking(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('ssize_t n = recv(fd, g_socket_recv_buf, SOCKET_RECV_BUF_SIZE - 1, 0);')
      ->blank
      ->if('n < 0')
        ->if('errno == EAGAIN || errno == EWOULDBLOCK')
          ->line('ST(0) = &PL_sv_undef;')
        ->else
          ->line('ST(0) = sv_2mortal(newSVpvn("", 0));')
        ->endif
      ->elsif('n == 0')
        ->line('ST(0) = sv_2mortal(newSVpvn("", 0));')
      ->else
        ->line('ST(0) = sv_2mortal(newSVpvn(g_socket_recv_buf, n));')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv_chunk {
    my ($class, $builder) = @_;

    $builder->comment('Receive a chunk of data (non-blocking)')
      ->xs_function('xs_socket_recv_chunk')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: recv_chunk(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->blank
      ->line('ssize_t n = recv(fd, g_socket_recv_buf, SOCKET_RECV_BUF_SIZE, MSG_DONTWAIT);')
      ->blank
      ->if('n < 0')
        ->if('errno == EAGAIN || errno == EWOULDBLOCK')
          ->line('ST(0) = sv_2mortal(newSVpvn("", 0));')
        ->else
          ->line('ST(0) = &PL_sv_undef;')
        ->endif
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('n == 0')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSVpvn(g_socket_recv_buf, n));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_wait_readable {
    my ($class, $builder) = @_;

    $builder->comment('Wait for socket to be readable')
      ->xs_function('xs_socket_wait_readable')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: wait_readable(fd, timeout_ms)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('int timeout_ms = (int)SvIV(ST(1));')
      ->blank
      ->line('fd_set rfds;')
      ->line('FD_ZERO(&rfds);')
      ->line('FD_SET(fd, &rfds);')
      ->blank
      ->line('struct timeval tv;')
      ->line('tv.tv_sec = timeout_ms / 1000;')
      ->line('tv.tv_usec = (timeout_ms % 1000) * 1000;')
      ->blank
      ->line('int ret = select(fd + 1, &rfds, NULL, NULL, &tv);')
      ->line('ST(0) = sv_2mortal(newSViv(ret));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->comment('Close file descriptor')
      ->xs_function('xs_socket_close')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: close(fd)");')
      ->line('int fd = (int)SvIV(ST(0));')
      ->line('int ret = close(fd);')
      ->line('ST(0) = sv_2mortal(newSViv(ret));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;
