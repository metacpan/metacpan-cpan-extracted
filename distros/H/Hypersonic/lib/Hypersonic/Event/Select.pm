package Hypersonic::Event::Select;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'select' }

sub available { 1 }  # Always available - most portable

sub includes {
    my $class = shift;
    if ($^O eq 'MSWin32') {
        return <<'C';
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
C
    }
    return '#include <sys/select.h>';
}

sub defines {
    return <<'C';
#define EV_BACKEND_SELECT 1

/* Increase FD_SETSIZE before including headers on some systems */
#ifndef FD_SETSIZE
#define FD_SETSIZE 1024
#endif

#ifndef MAX_EVENTS
#define MAX_EVENTS FD_SETSIZE
#endif
C
}

sub event_struct { 'fd_set' }  # Not really used as array

sub extra_cflags  { '' }
sub extra_ldflags { $^O eq 'MSWin32' ? '-lws2_32' : '' }

# select() needs to track all fds and rebuild fd_sets each iteration
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('select() backend - most portable, lowest performance')
      ->line('fd_set master_read_fds;')
      ->line('FD_ZERO(&master_read_fds);')
      ->line("FD_SET($listen_fd_var, &master_read_fds);")
      ->line("int max_fd = $listen_fd_var;")
      ->line('int ev_fd = 0;')  # Dummy - select doesn't use event fd
      ->blank;

    # Windows requires WSAStartup
    if ($^O eq 'MSWin32') {
        $builder->line('WSADATA wsa_data;')
          ->if('WSAStartup(MAKEWORD(2,2), &wsa_data) != 0')
            ->line('fprintf(stderr, "WSAStartup failed\\n");')
            ->line('return -1;')
          ->endif;
    }
}

# Add fd to master set
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("FD_SET($fd_var, &master_read_fds);")
      ->if("$fd_var > max_fd")
        ->line("max_fd = $fd_var;")
      ->endif;
}

# Remove fd from master set
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("FD_CLR($fd_var, &master_read_fds);")
      ->comment('Note: max_fd not updated (would need to scan)');
}

# Wait using select() - must copy fd_set each time
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->comment('Copy master set - select() modifies it')
      ->line('fd_set read_fds = master_read_fds;')
      ->blank
      ->line('struct timeval tv;')
      ->line("tv.tv_sec = $timeout_var / 1000;")
      ->line("tv.tv_usec = ($timeout_var % 1000) * 1000;")
      ->blank
      ->line('int select_result = select(max_fd + 1, &read_fds, NULL, NULL, &tv);')
      ->if('select_result < 0')
        ->if('errno == EINTR')
          ->line('continue;')
        ->endif
        ->line('perror("select");')
        ->line('break;')
      ->endif
      ->if('select_result == 0')
        ->line('continue;')  # Timeout
      ->endif
      ->blank
      ->comment('Store read_fds pointer for iteration')
      ->line("fd_set* $events_var = &read_fds;")
      ->line("int $count_var = max_fd + 1;");  # We check all fds up to max
}

# select() iteration is different - check each fd with FD_ISSET
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("int $fd_var = $index_var;")  # fd IS the index for select
      ->if("!FD_ISSET($fd_var, $events_var)")
        ->line('continue;')  # Skip fds without events
      ->endif;
}

# Windows cleanup
sub gen_cleanup {
    my ($class, $builder) = @_;
    if ($^O eq 'MSWin32') {
        $builder->line('WSACleanup();');
    }
}

# Future/Pool integration - add pool notify fd to master set
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to select master set */")
            ->line("FD_SET($notify_fd_var, &master_read_fds);")
            ->if("$notify_fd_var > max_fd")
              ->line("max_fd = $notify_fd_var;")
            ->endif;
}

1;

__END__

=head1 NAME

Hypersonic::Event::Select - select() event backend (universal)

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('select');
    # $backend is 'Hypersonic::Event::Select'

=head1 DESCRIPTION

C<Hypersonic::Event::Select> is the select()-based event backend for
Hypersonic. It provides universal compatibility across all platforms
including Windows, making it the fallback of last resort.

select() is the oldest and most portable event notification mechanism,
but also the slowest due to O(n) scanning and FD_SETSIZE limitations.

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::Select->name;  # 'select'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::Select->available) { ... }

Always returns true - select() is available on all systems.

=head2 includes

Returns the C #include directives needed for select. On Windows,
includes winsock2.h; on Unix, includes sys/select.h.

=head2 defines

Returns the C #define directives for select configuration,
including FD_SETSIZE.

=head2 event_struct

    my $struct = Hypersonic::Event::Select->event_struct;  # 'fd_set'

Returns 'fd_set' (note: not used as an array like other backends).

=head2 extra_ldflags

    my $flags = Hypersonic::Event::Select->extra_ldflags;

Returns '-lws2_32' on Windows, empty string otherwise.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to initialize the master fd_set and add the listen socket.
On Windows, also generates WSAStartup() call.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to add a file descriptor to the master fd_set
and update max_fd.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to remove a file descriptor from the master fd_set.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to copy the master fd_set (select modifies it)
and call select() with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to check FD_ISSET for each potential fd,
skipping those without events.

=head2 gen_cleanup($builder)

Generates C code for cleanup. On Windows, calls WSACleanup().

=head1 LIMITATIONS

=over 4

=item * FD_SETSIZE limit (typically 1024 on Unix, 64 on Windows)

=item * O(n) scanning of all file descriptors on each call

=item * Must copy fd_set on each iteration (select modifies it)

=item * Slower than poll(), epoll, or kqueue

=back

=head1 WINDOWS SUPPORT

On Windows, this backend uses Winsock2 (ws2_32.lib). It automatically
calls WSAStartup() during initialization and WSACleanup() during shutdown.

=head1 WHEN TO USE

=over 4

=item * Windows compatibility is required

=item * Very old Unix systems without poll()

=item * Testing on systems where other backends fail

=item * Low-concurrency scenarios (< 100 connections)

=back

=head1 AVAILABILITY

All systems: Linux, macOS, BSD, Windows, Solaris, AIX, HP-UX, etc.

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Poll>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
