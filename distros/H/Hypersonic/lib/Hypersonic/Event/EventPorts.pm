package Hypersonic::Event::EventPorts;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'event_ports' }

sub available {
    # Event ports are available on Solaris 10+ and illumos
    return 0 unless $^O eq 'solaris';

    # Check for port_create in libc
    return -f '/usr/include/port.h';
}

sub includes {
    return <<'C';
#include <port.h>
#include <poll.h>
#include <time.h>
C
}

sub defines {
    return <<'C';
#define EV_BACKEND_EVENT_PORTS 1
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif
C
}

sub event_struct { 'port_event_t' }

sub extra_cflags  { '' }
sub extra_ldflags { '' }  # Event ports are in libc on Solaris

# Create event port and associate listen socket
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('Event Ports backend - Solaris/illumos high-performance I/O')
      ->blank
      ->line('int ev_fd = port_create();')
      ->if('ev_fd < 0')
        ->line('croak("port_create() failed");')
      ->endif
      ->blank
      ->comment('Associate listen socket with port')
      ->if("port_associate(ev_fd, PORT_SOURCE_FD, $listen_fd_var, POLLIN, NULL) < 0")
        ->line('close(ev_fd);')
        ->line('croak("port_associate() failed for listen socket");')
      ->endif
      ->blank;
}

# Associate fd with event port
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    # Event ports require re-association after each event (one-shot)
    $builder->if("port_associate($loop_var, PORT_SOURCE_FD, $fd_var, POLLIN, (void*)(intptr_t)$fd_var) < 0")
      ->line('perror("port_associate");')
    ->endif;
}

# Dissociate fd from event port
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("port_dissociate($loop_var, PORT_SOURCE_FD, $fd_var);");
}

# Wait for events using port_getn
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line("static port_event_t $events_var" . "[MAX_EVENTS];")
      ->line('uint_t nget = 1;')  # Minimum events to wait for
      ->line('uint_t max_events = MAX_EVENTS;')
      ->blank
      ->line('struct timespec ts;')
      ->line("ts.tv_sec = $timeout_var / 1000;")
      ->line("ts.tv_nsec = ($timeout_var % 1000) * 1000000;")
      ->blank
      ->line("int result = port_getn($loop_var, $events_var, max_events, &nget, &ts);")
      ->if('result < 0')
        ->if('errno == EINTR || errno == ETIME')
          ->line('continue;')  # Timeout or interrupted - normal
        ->endif
        ->line('perror("port_getn");')
        ->line('break;')
      ->endif
      ->line("int $count_var = (int)nget;");
}

# Extract fd from event - note: must re-associate after each event
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("port_event_t* pe = &${events_var}[$index_var];")
      ->line("int $fd_var = (int)pe->portev_object;")
      ->blank
      ->comment('Event ports are one-shot - must re-associate for more events')
      ->if("$fd_var != listen_fd")
        ->line("port_associate(ev_fd, PORT_SOURCE_FD, $fd_var, POLLIN, (void*)(intptr_t)$fd_var);")
      ->endif;
}

# Re-associate listen socket after accept
sub gen_rearm_listen {
    my ($class, $builder, $loop_var, $listen_fd_var) = @_;

    $builder->comment('Re-associate listen socket (event ports are one-shot)')
      ->line("port_associate($loop_var, PORT_SOURCE_FD, $listen_fd_var, POLLIN, NULL);");
}

# Future/Pool integration - add pool notify fd to event port
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to event port */")
            ->if("port_associate($loop_var, PORT_SOURCE_FD, $notify_fd_var, POLLIN, (void*)(intptr_t)$notify_fd_var) < 0")
              ->line('perror("port_associate pool notify");')
            ->endif;
}

1;

__END__

=head1 NAME

Hypersonic::Event::EventPorts - Event Ports backend for Solaris/illumos

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('event_ports');
    # $backend is 'Hypersonic::Event::EventPorts'

=head1 DESCRIPTION

C<Hypersonic::Event::EventPorts> is the event ports-based event backend
for Hypersonic on Solaris 10+ and illumos-based systems (SmartOS, OmniOS, etc).

Event ports are the modern, high-performance event notification mechanism
on Solaris, replacing the older /dev/poll interface. They provide O(1)
event notification similar to Linux's epoll and BSD's kqueue.

=head1 KEY CHARACTERISTICS

=over 4

=item * One-shot semantics - must re-associate after each event

=item * Can monitor file descriptors, timers, and other sources

=item * Provides event source information in results

=item * port_getn() can retrieve multiple events at once

=back

=head1 ONE-SHOT BEHAVIOR

Unlike epoll (with EPOLLET) or kqueue, event ports are inherently one-shot.
After an event is delivered, the file descriptor is automatically dissociated
from the port. You must call port_associate() again to receive more events.

This is handled automatically by gen_get_fd() which re-associates fds.

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::EventPorts->name;  # 'event_ports'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::EventPorts->available) { ... }

Returns true only on Solaris/illumos systems with event ports support.

=head2 includes

Returns the C #include directives needed for event ports.

=head2 defines

Returns the C #define directives for event ports configuration.

=head2 event_struct

    my $struct = Hypersonic::Event::EventPorts->event_struct;  # 'port_event_t'

Returns the C struct name used for the events array.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to create an event port and associate the listen socket.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to associate a file descriptor with the event port.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to dissociate a file descriptor from the event port.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for events using port_getn().

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the file descriptor from an event and
re-associate it for future events.

=head1 COMPARISON WITH OTHER BACKENDS

    Backend       Platform    Semantics    Performance
    -------       --------    ---------    -----------
    epoll         Linux       Level/Edge   O(1)
    kqueue        BSD/macOS   Level/Edge   O(1)
    event_ports   Solaris     One-shot     O(1)
    io_uring      Linux 5.1+  Completion   O(1) + batching
    poll          POSIX       Level        O(n)
    select        All         Level        O(n)

=head1 AVAILABILITY

Solaris 10 and later, illumos distributions (SmartOS, OmniOS, OpenIndiana).

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Poll>

For more information on event ports:
L<https://docs.oracle.com/cd/E19253-01/816-5168/port-create-3c/index.html>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
