package Hypersonic::Event::IOCP;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.19';

sub name { 'iocp' }

sub available {
    return $^O eq 'MSWin32';
}

sub includes {
    return <<'C';
#include <winsock2.h>
#include <mswsock.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "mswsock.lib")
C
}

sub defines {
    return <<'C';
#define EV_BACKEND_IOCP 1
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif

/* Operation types for OVERLAPPED tracking */
#define OP_ACCEPT  1
#define OP_READ    2
#define OP_WRITE   3

/* Per-I/O data structure */
typedef struct {
    OVERLAPPED overlapped;
    WSABUF wsa_buf;
    char buffer[65536];
    int op_type;
    SOCKET socket;
} PER_IO_DATA;

/* AcceptEx function pointer (loaded dynamically) */
static LPFN_ACCEPTEX lpfnAcceptEx = NULL;

/* Per-IO data for Hypersonic::UA::Async slot tracking.
 * One ASYNC_SLOT_IO is allocated per pending readiness notification
 * and freed in gen_get_slot once the completion is delivered.
 * Slot is also passed as the IOCP completion key (ULONG_PTR), so
 * gen_get_slot recovers it cheaply via lpCompletionKey, falling
 * back to overlapped->slot when the kernel delivers a NULL key. */
typedef struct {
    OVERLAPPED overlapped;
    int slot;
    char peek_buf[1];
} ASYNC_SLOT_IO;
C
}

sub event_struct { 'OVERLAPPED_ENTRY' }

sub extra_cflags  { '' }
sub extra_ldflags { '-lws2_32 -lmswsock' }

# Create the IOCP completion port without an associated listen socket.
# Used by Hypersonic::UA::Async tick path (no server listener required).
sub gen_create_loop {
    my ($class, $builder, $loop_var) = @_;

    $builder->comment('IOCP loop create (no listen socket - UA::Async tick path)')
      ->line('WSADATA wsa_data;')
      ->if('WSAStartup(MAKEWORD(2,2), &wsa_data) != 0')
        ->line('croak("WSAStartup failed");')
      ->endif
      ->line('HANDLE iocp_loop = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 0);')
      ->if('iocp_loop == NULL')
        ->line('WSACleanup();')
        ->line('croak("CreateIoCompletionPort (loop) failed");')
      ->endif
      ->line("$loop_var = (int)(intptr_t)iocp_loop;");
}

# ============================================================
# UA::Async slot integration (stub)
# ------------------------------------------------------------
# IOCP is completion-based, not readiness-based, so we fake
# readiness by posting a 1-byte WSARecv with MSG_PEEK (read) or
# synthesizing an immediate completion via PostQueuedCompletionStatus
# (write). The slot is carried both as the IOCP completion key
# (ULONG_PTR) and inside the per-IO ASYNC_SLOT_IO struct, so
# gen_get_slot can recover it from either source.
# This is enough to drive Hypersonic::UA::Async's tick loop on
# native Win32; high-throughput async users should still prefer
# the dedicated IOCP path in the future-server JIT.
# ============================================================

sub gen_add_with_slot {
    my ($class, $builder, $loop_var, $fd_var, $slot_var, $events) = @_;

    $builder->line('{')
      ->line("    HANDLE _iocp = (HANDLE)(intptr_t)$loop_var;")
      ->comment('    Associate fd with IOCP (slot as completion key); idempotent / errors ignored.')
      ->line("    CreateIoCompletionPort((HANDLE)(intptr_t)$fd_var, _iocp, (ULONG_PTR)$slot_var, 0);")
      ->line('    ASYNC_SLOT_IO *_io = (ASYNC_SLOT_IO *)calloc(1, sizeof(ASYNC_SLOT_IO));')
      ->if('!_io')
        ->line('croak("calloc(ASYNC_SLOT_IO) failed");')
      ->endif
      ->line("    _io->slot = $slot_var;");

    if ($events eq 'write') {
        $builder->comment('    Writability: synthesize an immediate completion.')
          ->line("    PostQueuedCompletionStatus(_iocp, 0, (ULONG_PTR)$slot_var, &_io->overlapped);");
    }
    else {
        $builder->comment('    Readability: post a 1-byte WSARecv with MSG_PEEK so we get notified')
          ->comment('    when data arrives without consuming it from the socket buffer.')
          ->line('    WSABUF _buf;')
          ->line('    _buf.buf = _io->peek_buf;')
          ->line('    _buf.len = 1;')
          ->line('    DWORD _flags = MSG_PEEK;')
          ->line('    DWORD _bytes = 0;')
          ->line("    int _rc = WSARecv((SOCKET)$fd_var, &_buf, 1, &_bytes, &_flags, &_io->overlapped, NULL);")
          ->line('    if (_rc == SOCKET_ERROR && WSAGetLastError() != WSA_IO_PENDING) {')
          ->comment('        Failed (e.g. socket closed): synthesize completion so caller can advance state.')
          ->line("        PostQueuedCompletionStatus(_iocp, 0, (ULONG_PTR)$slot_var, &_io->overlapped);")
          ->line('    }');
    }
    $builder->line('}');
}

sub gen_wait_once {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_ms) = @_;

    $builder->line('{')
      ->line("    HANDLE _iocp = (HANDLE)(intptr_t)$loop_var;")
      ->line('    ULONG _removed = 0;')
      ->line("    BOOL _ok = GetQueuedCompletionStatusEx(_iocp, $events_var, MAX_EVENTS, &_removed, (DWORD)($timeout_ms), FALSE);")
      ->line("    $count_var = _ok ? (int)_removed : 0;")
      ->line('}');
}

sub gen_get_slot {
    my ($class, $builder, $events_var, $index_var, $slot_var) = @_;

    $builder->line("int $slot_var = -1;")
      ->line('{')
      ->line("    OVERLAPPED_ENTRY *_entry = &${events_var}" . "[$index_var];")
      ->line("    $slot_var = (int)(intptr_t)_entry->lpCompletionKey;")
      ->line('    if (_entry->lpOverlapped) {')
      ->line('        ASYNC_SLOT_IO *_io = CONTAINING_RECORD(_entry->lpOverlapped, ASYNC_SLOT_IO, overlapped);')
      ->line("        if ($slot_var < 0) $slot_var = _io->slot;")
      ->line('        free(_io);')
      ->line('    }')
      ->line('}');
}

# IOCP is completion-based, fundamentally different from readiness-based APIs
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('IOCP backend - Windows I/O Completion Ports')
      ->comment('High-performance completion-based I/O')
      ->blank
      ->comment('Initialize Winsock')
      ->line('WSADATA wsa_data;')
      ->if('WSAStartup(MAKEWORD(2,2), &wsa_data) != 0')
        ->line('croak("WSAStartup failed");')
      ->endif
      ->blank
      ->comment('Create I/O Completion Port')
      ->line('HANDLE iocp = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 0);')
      ->if('iocp == NULL')
        ->line('WSACleanup();')
        ->line('croak("CreateIoCompletionPort failed");')
      ->endif
      ->blank
      ->comment('Associate listen socket with IOCP')
      ->line("if (CreateIoCompletionPort((HANDLE)$listen_fd_var, iocp, (ULONG_PTR)$listen_fd_var, 0) == NULL) {")
      ->line('    CloseHandle(iocp);')
      ->line('    WSACleanup();')
      ->line('    croak("Failed to associate listen socket with IOCP");')
      ->line('}')
      ->blank
      ->comment('Load AcceptEx function')
      ->line('GUID guid_acceptex = WSAID_ACCEPTEX;')
      ->line('DWORD bytes;')
      ->line("if (WSAIoctl($listen_fd_var, SIO_GET_EXTENSION_FUNCTION_POINTER,")
      ->line('             &guid_acceptex, sizeof(guid_acceptex),')
      ->line('             &lpfnAcceptEx, sizeof(lpfnAcceptEx),')
      ->line('             &bytes, NULL, NULL) == SOCKET_ERROR) {')
      ->line('    CloseHandle(iocp);')
      ->line('    WSACleanup();')
      ->line('    croak("Failed to load AcceptEx");')
      ->line('}')
      ->blank
      ->comment('Post initial AcceptEx')
      ->line('PER_IO_DATA* accept_data = (PER_IO_DATA*)calloc(1, sizeof(PER_IO_DATA));')
      ->line('accept_data->op_type = OP_ACCEPT;')
      ->line('accept_data->socket = WSASocket(AF_INET, SOCK_STREAM, 0, NULL, 0, WSA_FLAG_OVERLAPPED);')
      ->line("lpfnAcceptEx($listen_fd_var, accept_data->socket, accept_data->buffer,")
      ->line('             0, sizeof(struct sockaddr_in) + 16, sizeof(struct sockaddr_in) + 16,')
      ->line('             &bytes, &accept_data->overlapped);')
      ->blank
      ->line('int ev_fd = (int)(intptr_t)iocp;')  # Store IOCP handle as ev_fd
      ->blank;
}

# Associate socket with IOCP and post read operation
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("HANDLE iocp_handle = (HANDLE)(intptr_t)$loop_var;")
      ->line("CreateIoCompletionPort((HANDLE)$fd_var, iocp_handle, (ULONG_PTR)$fd_var, 0);")
      ->blank
      ->comment('Post initial read operation')
      ->line('PER_IO_DATA* io_data = (PER_IO_DATA*)calloc(1, sizeof(PER_IO_DATA));')
      ->line('io_data->op_type = OP_READ;')
      ->line("io_data->socket = $fd_var;")
      ->line('io_data->wsa_buf.buf = io_data->buffer;')
      ->line('io_data->wsa_buf.len = sizeof(io_data->buffer);')
      ->line('DWORD flags = 0;')
      ->line("WSARecv($fd_var, &io_data->wsa_buf, 1, NULL, &flags, &io_data->overlapped, NULL);");
}

# Cancel pending I/O and close socket
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("CancelIo((HANDLE)$fd_var);")
      ->line("closesocket($fd_var);");
}

# Wait for completions using GetQueuedCompletionStatusEx
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line("HANDLE iocp_handle = (HANDLE)(intptr_t)$loop_var;")
      ->line("static OVERLAPPED_ENTRY $events_var" . "[MAX_EVENTS];")
      ->line("ULONG $count_var = 0;")
      ->blank
      ->line("BOOL ok = GetQueuedCompletionStatusEx(iocp_handle, $events_var, MAX_EVENTS, &$count_var, $timeout_var, FALSE);")
      ->if('!ok')
        ->if('GetLastError() == WAIT_TIMEOUT')
          ->line('continue;')
        ->endif
        ->line('perror("GetQueuedCompletionStatusEx");')
        ->line('break;')
      ->endif;
}

# Extract socket and operation type from completion
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("OVERLAPPED_ENTRY* entry = &${events_var}[$index_var];")
      ->line('PER_IO_DATA* io_data = CONTAINING_RECORD(entry->lpOverlapped, PER_IO_DATA, overlapped);')
      ->line("int $fd_var = (int)io_data->socket;")
      ->line('int op_type = io_data->op_type;')
      ->line('DWORD bytes_transferred = entry->dwNumberOfBytesTransferred;')
      ->blank
      ->if('op_type == OP_ACCEPT')
        ->comment('Accept completed - io_data->socket is the new client')
        ->line("$fd_var = listen_fd;")  # Signal this was accept
        ->line('int client_fd = (int)io_data->socket;')
      ->elsif('op_type == OP_READ')
        ->if('bytes_transferred == 0')
          ->comment('Connection closed')
          ->line("closesocket($fd_var);")
          ->line('free(io_data);')
          ->line('g_active_connections--;')
          ->line('continue;')
        ->endif
        ->comment('Data received - already in io_data->buffer')
      ->endif;
}

# Cleanup IOCP resources
sub gen_cleanup {
    my ($class, $builder) = @_;

    $builder->line('CloseHandle(iocp);')
      ->line('WSACleanup();');
}

# Future/Pool integration - IOCP uses different mechanism for pool notify
# On Windows, pool uses a pipe which can be added to IOCP via overlapped read
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to IOCP */")
            ->line("HANDLE iocp_handle = (HANDLE)(intptr_t)$loop_var;")
            ->line("CreateIoCompletionPort((HANDLE)$notify_fd_var, iocp_handle, (ULONG_PTR)$notify_fd_var, 0);")
            ->line('PER_IO_DATA* pool_io = (PER_IO_DATA*)calloc(1, sizeof(PER_IO_DATA));')
            ->line('pool_io->op_type = 4;')  # New type for pool notify
            ->line("pool_io->socket = $notify_fd_var;")
            ->line('pool_io->wsa_buf.buf = pool_io->buffer;')
            ->line('pool_io->wsa_buf.len = 1;')
            ->line('DWORD flags = 0;')
            ->line("ReadFile((HANDLE)$notify_fd_var, pool_io->buffer, 1, NULL, &pool_io->overlapped);");
}

1;

__END__

=head1 NAME

Hypersonic::Event::IOCP - I/O Completion Ports backend for Windows

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('iocp');
    # $backend is 'Hypersonic::Event::IOCP'

=head1 DESCRIPTION

C<Hypersonic::Event::IOCP> is the I/O Completion Ports (IOCP) event backend
for Hypersonic on Windows. IOCP is the highest-performance I/O mechanism
available on Windows, designed for servers handling thousands of connections.

Unlike epoll/kqueue which are "readiness" based (notify when fd is ready),
IOCP is "completion" based (notify when I/O operation completes). This
requires a different programming model where operations are posted
asynchronously and completions are retrieved later.

=head1 KEY DIFFERENCES FROM UNIX BACKENDS

=over 4

=item * Completion-based vs readiness-based

=item * Uses OVERLAPPED structures for async I/O

=item * AcceptEx for async accept operations

=item * WSARecv/WSASend for async socket I/O

=item * Thread pool friendly design

=back

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::IOCP->name;  # 'iocp'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::IOCP->available) { ... }

Returns true only on Windows (MSWin32).

=head2 includes

Returns the C #include directives needed for IOCP.

=head2 defines

Returns the C #define directives including operation type constants
and the PER_IO_DATA structure.

=head2 event_struct

    my $struct = Hypersonic::Event::IOCP->event_struct;  # 'OVERLAPPED_ENTRY'

Returns the C struct name used for completion entries.

=head2 extra_ldflags

    my $flags = Hypersonic::Event::IOCP->extra_ldflags;  # '-lws2_32 -lmswsock'

Returns linker flags needed for Winsock2.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to create an IOCP, associate the listen socket,
load AcceptEx, and post the initial accept operation.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to associate a socket with IOCP and post a read operation.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to cancel pending I/O and close a socket.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for completions using GetQueuedCompletionStatusEx.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the socket and operation type from a completion.

=head2 gen_cleanup($builder)

Generates C code to close IOCP handle and cleanup Winsock.

=head1 PERFORMANCE

IOCP can handle 100,000+ concurrent connections efficiently due to:

=over 4

=item * Kernel-managed completion queue

=item * Efficient thread pool integration

=item * Zero-copy I/O paths available

=item * Scalable to many cores

=back

=head1 AVAILABILITY

Windows only (Windows NT 3.5 and later, including all modern Windows).

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Select>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
