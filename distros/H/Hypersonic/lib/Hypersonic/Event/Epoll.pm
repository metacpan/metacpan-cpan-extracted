package Hypersonic::Event::Epoll;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'epoll' }

sub available {
    return $^O eq 'linux';
}

sub includes {
    return '#include <sys/epoll.h>';
}

sub defines {
    return <<'C';
#define EV_BACKEND_EPOLL 1
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif
C
}

sub event_struct { 'epoll_event' }

sub extra_cflags  { '' }
sub extra_ldflags { '' }

# Generate: create epoll instance and add listen socket
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->line('int ev_fd;')
      ->line('struct epoll_event ev;')
      ->blank
      ->line('ev_fd = epoll_create1(0);')
      ->if('ev_fd < 0')
        ->line('croak("epoll_create1() failed");')
      ->endif
      ->blank
      ->line('ev.events = EPOLLIN | EPOLLET;')
      ->line("ev.data.fd = $listen_fd_var;")
      ->if("epoll_ctl(ev_fd, EPOLL_CTL_ADD, $listen_fd_var, &ev) < 0")
        ->line('close(ev_fd);')
        ->line('croak("epoll_ctl() failed to add listen socket");')
      ->endif;
}

# Generate: add fd to epoll
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line('ev.events = EPOLLIN | EPOLLET;')
      ->line("ev.data.fd = $fd_var;")
      ->line("epoll_ctl($loop_var, EPOLL_CTL_ADD, $fd_var, &ev);");
}

# Generate: remove fd from epoll
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("epoll_ctl($loop_var, EPOLL_CTL_DEL, $fd_var, NULL);");
}

# Generate: wait for events (inside a loop - can use continue/break)
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line("int $count_var;")
      ->line("$count_var = epoll_wait($loop_var, $events_var, MAX_EVENTS, $timeout_var);")
      ->if("$count_var < 0")
        ->if('errno == EINTR')
          ->line('continue;')
        ->endif
        ->line('perror("epoll_wait");')
        ->line('break;')
      ->endif;
}

# Generate: wait for events - single call version (no loop control)
sub gen_wait_once {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_ms) = @_;

    $builder->line("$count_var = epoll_wait($loop_var, $events_var, MAX_EVENTS, $timeout_ms);")
      ->line("if ($count_var < 0 && errno == EINTR) $count_var = 0;");
}

# Generate: extract fd from event
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("int $fd_var;")
      ->line("$fd_var = ${events_var}[$index_var].data.fd;");
}

# ============================================================
# Async Slot Integration Methods (UA Async)
# ============================================================

# Generate: create epoll without adding any fds
# Note: loop_var must be already declared
sub gen_create_loop {
    my ($class, $builder, $loop_var) = @_;

    $builder->line('struct epoll_event ev;')
      ->blank
      ->line("$loop_var = epoll_create1(0);")
      ->if("$loop_var < 0")
        ->line('croak("epoll_create1() failed");')
      ->endif;
}

# Generate: add fd with slot as user data
# Note: epoll_event.data is a union - we use data.u32 for slot
sub gen_add_with_slot {
    my ($class, $builder, $loop_var, $fd_var, $slot_var, $events) = @_;
    
    my $ev_flags = $events eq 'read' ? 'EPOLLIN | EPOLLET | EPOLLONESHOT' 
                 : $events eq 'write' ? 'EPOLLOUT | EPOLLET | EPOLLONESHOT'
                 : 'EPOLLIN | EPOLLET | EPOLLONESHOT';
    
    $builder->line("ev.events = $ev_flags;")
      ->line("ev.data.u32 = (uint32_t)$slot_var;")
      ->line("epoll_ctl($loop_var, EPOLL_CTL_ADD, $fd_var, &ev);");
}

# Generate: extract slot from event data
sub gen_get_slot {
    my ($class, $builder, $events_var, $index_var, $slot_var) = @_;

    $builder->line("int $slot_var;")
      ->line("$slot_var = (int)${events_var}[$index_var].data.u32;");
}

# ============================================================
# Future/Pool Integration Methods
# ============================================================

# Future/Pool integration - add pool notify fd to epoll
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to epoll */")
            ->line('ev.events = EPOLLIN;')
            ->line("ev.data.fd = $notify_fd_var;")
            ->line("epoll_ctl($loop_var, EPOLL_CTL_ADD, $notify_fd_var, &ev);");
}

# Multi-pool integration - add all pool notify fds to epoll
sub gen_add_multi_pool_notify {
    my ($class, $builder, $loop_var, $pool_slots_var, $pool_count_var) = @_;

    $builder->line("/* Add all pool notify fds to epoll */")
            ->line("{ int _pi; int _pool_notify_fd;")
            ->line("for (_pi = 0; _pi < $pool_count_var; _pi++) {")
            ->line("    _pool_notify_fd = pool_get_notify_fd_slot($pool_slots_var\[_pi]);")
            ->line("    if (_pool_notify_fd >= 0) {")
            ->line("        ev.events = EPOLLIN;")
            ->line("        ev.data.fd = _pool_notify_fd;")
            ->line("        epoll_ctl($loop_var, EPOLL_CTL_ADD, _pool_notify_fd, &ev);")
            ->line("    }")
            ->line("} }");
}

1;

__END__

=head1 NAME

Hypersonic::Event::Epoll - epoll event backend for Linux

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('epoll');
    # $backend is 'Hypersonic::Event::Epoll'

=head1 DESCRIPTION

C<Hypersonic::Event::Epoll> is the epoll-based event backend for Hypersonic.
It uses edge-triggered mode (EPOLLET) for maximum performance.

epoll is the recommended backend for Linux systems. It provides O(1) event
notification for any number of file descriptors.

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::Epoll->name;  # 'epoll'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::Epoll->available) { ... }

Returns true if this backend is available (Linux only).

=head2 includes

Returns the C #include directives needed for epoll.

=head2 defines

Returns the C #define directives for epoll configuration.

=head2 event_struct

    my $struct = Hypersonic::Event::Epoll->event_struct;  # 'epoll_event'

Returns the C struct name used for the events array.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to create an epoll instance and register the listen socket.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to add a file descriptor to the epoll instance.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to remove a file descriptor from the epoll instance.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for events with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the file descriptor from an event.

=head1 AVAILABILITY

Linux only. For BSD/macOS, use L<Hypersonic::Event::Kqueue>.

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Kqueue>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
