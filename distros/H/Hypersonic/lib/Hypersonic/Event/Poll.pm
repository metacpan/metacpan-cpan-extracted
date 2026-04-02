package Hypersonic::Event::Poll;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'poll' }

sub available {
    # poll() is POSIX - available on all Unix systems
    # Not available on Windows (use select instead)
    return $^O ne 'MSWin32';
}

sub includes {
    return '#include <poll.h>';
}

sub defines {
    return <<'C';
#define EV_BACKEND_POLL 1
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif
#ifndef MAX_POLL_FDS
#define MAX_POLL_FDS 10000
#endif
C
}

sub event_struct { 'pollfd' }

sub extra_cflags  { '' }
sub extra_ldflags { '' }

# poll() needs additional state tracking
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('poll() backend - allocate pollfd array')
      ->line('static struct pollfd poll_fds[MAX_POLL_FDS];')
      ->line('static int poll_nfds = 0;')
      ->blank
      ->line("poll_fds[0].fd = $listen_fd_var;")
      ->line('poll_fds[0].events = POLLIN;')
      ->line('poll_nfds = 1;')
      ->line('int ev_fd = 0;')  # Dummy - poll doesn't use event fd
      ->blank;
}

# Add fd to poll array
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->if('poll_nfds < MAX_POLL_FDS')
      ->line("poll_fds[poll_nfds].fd = $fd_var;")
      ->line('poll_fds[poll_nfds].events = POLLIN;')
      ->line('poll_nfds++;')
    ->endif;
}

# Remove fd from poll array (compact)
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->comment('Find and remove fd from poll array')
      ->line('{ int j;')
      ->line('for (j = 0; j < poll_nfds; j++) {')
      ->line("    if (poll_fds[j].fd == $fd_var) {")
      ->line('        poll_fds[j] = poll_fds[poll_nfds - 1];')
      ->line('        poll_nfds--;')
      ->line('        break;')
      ->line('    }')
      ->line('} }');
}

# Wait using poll()
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    # poll() modifies the array in-place, doesn't need separate events array
    $builder->line("int poll_result = poll(poll_fds, poll_nfds, $timeout_var);")
      ->if('poll_result < 0')
        ->if('errno == EINTR')
          ->line('continue;')
        ->endif
        ->line('perror("poll");')
        ->line('break;')
      ->endif
      ->line("int $count_var = poll_nfds;")  # We check all fds
      ->line("(void)$events_var;");  # Unused - we use poll_fds directly
}

# poll() iteration is different - check revents
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->comment('Check if this fd has events')
      ->if("!(poll_fds[$index_var].revents & POLLIN)")
        ->line('continue;')  # Skip fds without events
      ->endif
      ->line("int $fd_var = poll_fds[$index_var].fd;");
}

# Future/Pool integration - add pool notify fd to poll array
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to poll array */")
            ->if('poll_nfds < MAX_POLL_FDS')
              ->line("poll_fds[poll_nfds].fd = $notify_fd_var;")
              ->line('poll_fds[poll_nfds].events = POLLIN;')
              ->line('poll_nfds++;')
            ->endif;
}

1;

__END__

=head1 NAME

Hypersonic::Event::Poll - poll() event backend (portable fallback)

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('poll');
    # $backend is 'Hypersonic::Event::Poll'

=head1 DESCRIPTION

C<Hypersonic::Event::Poll> is the poll()-based event backend for Hypersonic.
It provides a portable fallback that works on all POSIX systems.

poll() has O(n) complexity where n is the number of file descriptors
being watched. For servers with more than 1000 concurrent connections,
prefer epoll (Linux) or kqueue (BSD/macOS).

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::Poll->name;  # 'poll'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::Poll->available) { ... }

Returns true if this backend is available. poll() is available on all
POSIX systems (Linux, macOS, BSD, Solaris, etc.) but not on Windows.

=head2 includes

Returns the C #include directives needed for poll.

=head2 defines

Returns the C #define directives for poll configuration.

=head2 event_struct

    my $struct = Hypersonic::Event::Poll->event_struct;  # 'pollfd'

Returns the C struct name used for the events array.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to initialize the pollfd array and add the listen socket.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to add a file descriptor to the pollfd array.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to remove a file descriptor from the pollfd array.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for events using poll().

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the file descriptor from a pollfd entry,
skipping entries without events.

=head1 PERFORMANCE

poll() scans all file descriptors on each call, making it O(n) where
n is the number of watched descriptors. This is slower than epoll/kqueue
for large numbers of connections but is perfectly adequate for:

=over 4

=item * Development and testing

=item * Low-concurrency servers (< 1000 connections)

=item * Systems without epoll/kqueue support

=back

=head1 AVAILABILITY

All POSIX systems: Linux, macOS, BSD, Solaris, AIX, HP-UX, etc.
Not available on Windows (use L<Hypersonic::Event::Select> instead).

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Epoll>,
L<Hypersonic::Event::Kqueue>, L<Hypersonic::Event::Select>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
