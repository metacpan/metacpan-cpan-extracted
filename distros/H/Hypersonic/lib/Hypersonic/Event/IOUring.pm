package Hypersonic::Event::IOUring;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'io_uring' }

sub available {
    return 0 unless $^O eq 'linux';

    # Check kernel version >= 5.1
    my $ver = `uname -r 2>/dev/null` || '';
    my ($major, $minor) = $ver =~ /^(\d+)\.(\d+)/;
    return 0 unless $major && ($major > 5 || ($major == 5 && $minor >= 1));

    # Check for liburing headers
    my $has_header = -f '/usr/include/liburing.h'
        || -f '/usr/local/include/liburing.h'
        || -f '/usr/include/x86_64-linux-gnu/liburing.h';
    return 0 unless $has_header;

    # Verify liburing is actually linkable (not just headers/files exist)
    # This is the definitive test - prevents "undefined symbol" at runtime
    return __PACKAGE__->_can_link('-luring', 'io_uring_queue_init', '#include <liburing.h>');
}

sub includes {
    return '#include <liburing.h>';
}

sub defines {
    return <<'C';
#define EV_BACKEND_IO_URING 1
#ifndef URING_ENTRIES
#define URING_ENTRIES 256
#endif
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif

/* User data encoding: type in high bits, fd in low bits */
#define UD_ACCEPT 0x10000000
#define UD_READ   0x20000000
#define UD_WRITE  0x30000000
#define UD_FD_MASK 0x0FFFFFFF
C
}

sub event_struct { 'io_uring_cqe' }

sub extra_cflags  { '' }
sub extra_ldflags { '-luring' }

# io_uring is fundamentally different - uses submission/completion queues
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('io_uring backend - high performance Linux I/O')
      ->line('static struct io_uring ring;')
      ->line('static int ring_initialized = 0;')
      ->blank
      ->if('!ring_initialized')
        ->if('io_uring_queue_init(URING_ENTRIES, &ring, 0) < 0')
          ->line('perror("io_uring_queue_init");')
          ->line('return -1;')
        ->endif
        ->line('ring_initialized = 1;')
      ->endif
      ->blank
      ->comment('Submit initial accept')
      ->line('struct io_uring_sqe* sqe = io_uring_get_sqe(&ring);')
      ->if('sqe')
        ->line("io_uring_prep_accept(sqe, $listen_fd_var, NULL, NULL, 0);")
        ->line("io_uring_sqe_set_data(sqe, (void*)(uintptr_t)(UD_ACCEPT | $listen_fd_var));")
        ->line('io_uring_submit(&ring);')
      ->endif
      ->line('int ev_fd = 0;')  # Dummy - io_uring uses ring structure
      ->blank;
}

# Submit read operation
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line('sqe = io_uring_get_sqe(&ring);')
      ->if('sqe')
        ->line("io_uring_prep_recv(sqe, $fd_var, recv_buf, RECV_BUF_SIZE, 0);")
        ->line("io_uring_sqe_set_data(sqe, (void*)(uintptr_t)(UD_READ | $fd_var));")
        ->line('io_uring_submit(&ring);')
      ->endif;
}

# Cancel pending operations
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->comment('io_uring: close fd (pending ops will complete with error)')
      ->line("close($fd_var);");
}

# Wait for completions
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line('struct io_uring_cqe* cqe;')
      ->line('struct __kernel_timespec ts;')
      ->line("ts.tv_sec = $timeout_var / 1000;")
      ->line("ts.tv_nsec = ($timeout_var % 1000) * 1000000;")
      ->blank
      ->comment('Wait for at least one completion')
      ->line('int wait_result = io_uring_wait_cqe_timeout(&ring, &cqe, &ts);')
      ->if('wait_result < 0')
        ->if('wait_result == -ETIME')
          ->line('continue;')  # Timeout is normal
        ->endif
        ->if('wait_result == -EINTR')
          ->line('continue;')
        ->endif
        ->line('break;')
      ->endif
      ->blank
      ->comment('Process all available completions')
      ->line('unsigned head;')
      ->line("int $count_var = 0;")
      ->line("static struct io_uring_cqe* cqes[MAX_EVENTS];")
      ->line('io_uring_for_each_cqe(&ring, head, cqe) {')
      ->line("    if ($count_var < MAX_EVENTS) cqes[$count_var++] = cqe;")
      ->line('}')
      ->line("$events_var = cqes;");  # Point to our array
}

# Extract operation type and fd from completion
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("struct io_uring_cqe* completion = ${events_var}[$index_var];")
      ->line('uintptr_t user_data = (uintptr_t)io_uring_cqe_get_data(completion);')
      ->line('int op_type = user_data & 0xF0000000;')
      ->line("int $fd_var = user_data & UD_FD_MASK;")
      ->line('int result = completion->res;')
      ->blank
      ->comment('Mark completion as seen')
      ->line('io_uring_cqe_seen(&ring, completion);')
      ->blank
      ->comment('Handle based on operation type')
      ->if('op_type == UD_ACCEPT')
        ->if('result >= 0')
          ->comment('result is the new client fd')
          ->line("int client_fd = result;")
          ->line("$fd_var = listen_fd;")  # Signal this was accept
        ->else
          ->line('continue;')  # Accept failed
        ->endif
      ->elsif('op_type == UD_READ')
        ->if('result <= 0')
          ->comment('Connection closed or error')
          ->line("close($fd_var);")
          ->line('g_active_connections--;')
          ->line('continue;')
        ->endif
        ->comment('result is bytes read - already in recv_buf')
      ->endif;
}

# Cleanup io_uring resources
sub gen_cleanup {
    my ($class, $builder) = @_;

    $builder->if('ring_initialized')
      ->line('io_uring_queue_exit(&ring);')
      ->line('ring_initialized = 0;')
    ->endif;
}

# Future/Pool integration - add pool notify fd via poll on the fd
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to io_uring via poll */")
            ->line('sqe = io_uring_get_sqe(&ring);')
            ->if('sqe')
              ->line("io_uring_prep_poll_add(sqe, $notify_fd_var, POLLIN);")
              ->line("io_uring_sqe_set_data(sqe, (void*)(uintptr_t)(0x40000000 | $notify_fd_var));")
              ->line('io_uring_submit(&ring);')
            ->endif;
}

1;

__END__

=head1 NAME

Hypersonic::Event::IOUring - io_uring event backend for Linux 5.1+

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('io_uring');
    # $backend is 'Hypersonic::Event::IOUring'

=head1 DESCRIPTION

C<Hypersonic::Event::IOUring> is the io_uring-based event backend for
Hypersonic. It provides the highest performance on modern Linux systems
by using submission queues (SQE) and completion queues (CQE) to batch
I/O operations and reduce syscall overhead.

io_uring is fundamentally different from epoll/kqueue in that it:

=over 4

=item * Uses a ring buffer shared between kernel and userspace

=item * Supports true asynchronous I/O including accept, read, write

=item * Can batch multiple operations in a single syscall

=item * Supports kernel-side polling for even lower latency

=back

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::IOUring->name;  # 'io_uring'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::IOUring->available) { ... }

Returns true if this backend is available. Requires:

=over 4

=item * Linux kernel 5.1 or later

=item * liburing library installed (liburing-dev package)

=back

=head2 includes

Returns the C #include directives needed for io_uring.

=head2 defines

Returns the C #define directives for io_uring configuration,
including user data encoding macros.

=head2 event_struct

    my $struct = Hypersonic::Event::IOUring->event_struct;  # 'io_uring_cqe'

Returns the C struct name used for completion queue entries.

=head2 extra_ldflags

    my $flags = Hypersonic::Event::IOUring->extra_ldflags;  # '-luring'

Returns linker flags needed for liburing.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to initialize the io_uring and submit the first accept.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to submit a recv operation for a file descriptor.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to close a file descriptor (pending operations
will complete with an error).

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for completions with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the operation type and file descriptor
from a completion queue entry.

=head2 gen_cleanup($builder)

Generates C code to clean up io_uring resources on shutdown.

=head1 USER DATA ENCODING

io_uring uses user_data to track operations. This backend encodes
the operation type in the high bits and the file descriptor in the
low bits:

    UD_ACCEPT (0x10000000) - accept operation
    UD_READ   (0x20000000) - read/recv operation
    UD_WRITE  (0x30000000) - write/send operation
    UD_FD_MASK (0x0FFFFFFF) - mask to extract fd

=head1 PERFORMANCE

io_uring can achieve 1.5-2x the throughput of epoll for high-concurrency
workloads due to:

=over 4

=item * Batched submissions (fewer syscalls)

=item * Zero-copy I/O paths

=item * Optional kernel-side polling (IORING_SETUP_SQPOLL)

=back

=head1 REQUIREMENTS

=over 4

=item * Linux kernel 5.1 or later

=item * liburing library: C<apt install liburing-dev> (Debian/Ubuntu)
or C<dnf install liburing-devel> (Fedora/RHEL)

=back

=head1 AVAILABILITY

Linux 5.1+ with liburing installed.

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Epoll>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
