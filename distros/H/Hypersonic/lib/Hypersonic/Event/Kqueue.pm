package Hypersonic::Event::Kqueue;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.12';

sub name { 'kqueue' }

sub available {
    return $^O =~ /^(darwin|freebsd|openbsd|netbsd)$/;
}

sub includes {
    return '#include <sys/event.h>';
}

sub defines {
    return <<'C';
#define EV_BACKEND_KQUEUE 1
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif
C
}

sub event_struct { 'kevent' }

sub extra_cflags  { '' }
sub extra_ldflags { '' }

# Generate: create kqueue and add listen socket
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->line('int ev_fd;')
      ->line('struct kevent ev;')
      ->blank
      ->line('ev_fd = kqueue();')
      ->if('ev_fd < 0')
        ->line('croak("kqueue() failed");')
      ->endif
      ->blank
      ->line("EV_SET(&ev, $listen_fd_var, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);")
      ->if("kevent(ev_fd, &ev, 1, NULL, 0, NULL) < 0")
        ->line('close(ev_fd);')
        ->line('croak("kevent() failed to add listen socket");')
      ->endif;
}

# Generate: add fd to kqueue
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("EV_SET(&ev, $fd_var, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);")
      ->line("kevent($loop_var, &ev, 1, NULL, 0, NULL);");
}

# Generate: remove fd from kqueue
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line("EV_SET(&ev, $fd_var, EVFILT_READ, EV_DELETE, 0, 0, NULL);")
      ->line("kevent($loop_var, &ev, 1, NULL, 0, NULL);");
}

# Generate: wait for events with timeout (inside a loop - can use continue/break)
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line('struct timespec ts;')
      ->line("int $count_var;")
      ->blank
      ->line("ts.tv_sec = $timeout_var / 1000;")
      ->line("ts.tv_nsec = ($timeout_var % 1000) * 1000000;")
      ->blank
      ->line("$count_var = kevent($loop_var, NULL, 0, $events_var, MAX_EVENTS, &ts);")
      ->if("$count_var < 0")
        ->if('errno == EINTR')
          ->line('continue;')
        ->endif
        ->line('perror("kevent");')
        ->line('break;')
      ->endif;
}

# Generate: wait for events - single call version (no loop control)
sub gen_wait_once {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_ms) = @_;

    $builder->line('struct timespec ts;')
      ->blank
      ->line("ts.tv_sec = $timeout_ms / 1000;")
      ->line("ts.tv_nsec = ($timeout_ms % 1000) * 1000000;")
      ->blank
      ->line("$count_var = kevent($loop_var, NULL, 0, $events_var, MAX_EVENTS, &ts);")
      ->line("if ($count_var < 0 && errno == EINTR) $count_var = 0;");
}

# Generate: extract fd from event
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("int $fd_var;")
      ->line("$fd_var = (int)${events_var}[$index_var].ident;");
}

# ============================================================
# Async Slot Integration Methods (UA Async)
# ============================================================

# Generate: create kqueue without adding any fds
# Note: loop_var must be already declared
sub gen_create_loop {
    my ($class, $builder, $loop_var) = @_;

    $builder->line('struct kevent ev;')
      ->blank
      ->line("$loop_var = kqueue();")
      ->if("$loop_var < 0")
        ->line('croak("kqueue() failed");')
      ->endif;
}

# Generate: add fd with slot as user data
sub gen_add_with_slot {
    my ($class, $builder, $loop_var, $fd_var, $slot_var, $events) = @_;
    
    my $filter = $events eq 'read' ? 'EVFILT_READ' 
               : $events eq 'write' ? 'EVFILT_WRITE'
               : 'EVFILT_READ';  # default to read
    
    $builder->line('{')
      ->line('    struct kevent _ev;')
      ->line("    EV_SET(&_ev, $fd_var, $filter, EV_ADD | EV_ENABLE | EV_ONESHOT, 0, 0, (void *)(intptr_t)$slot_var);")
      ->line("    kevent($loop_var, &_ev, 1, NULL, 0, NULL);")
      ->line('}');
}

# Generate: extract slot from event udata
sub gen_get_slot {
    my ($class, $builder, $events_var, $index_var, $slot_var) = @_;

    $builder->line("int $slot_var;")
      ->line("$slot_var = (int)(intptr_t)${events_var}[$index_var].udata;");
}

# ============================================================
# Future/Pool Integration Methods
# ============================================================

# Future/Pool integration - add pool notify fd to kqueue
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;

    $builder->line("/* Add pool notify fd to kqueue */")
            ->line("EV_SET(&ev, $notify_fd_var, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);")
            ->line("kevent($loop_var, &ev, 1, NULL, 0, NULL);");
}

# Multi-pool integration - add all pool notify fds to kqueue
sub gen_add_multi_pool_notify {
    my ($class, $builder, $loop_var, $pool_slots_var, $pool_count_var) = @_;

    $builder->line("/* Add all pool notify fds to kqueue */")
            ->line("{ int _pi; int _pool_notify_fd;")
            ->line("for (_pi = 0; _pi < $pool_count_var; _pi++) {")
            ->line("    _pool_notify_fd = pool_get_notify_fd_slot($pool_slots_var\[_pi]);")
            ->line("    if (_pool_notify_fd >= 0) {")
            ->line("        EV_SET(&ev, _pool_notify_fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);")
            ->line("        kevent($loop_var, &ev, 1, NULL, 0, NULL);")
            ->line("    }")
            ->line("} }");
}

1;

__END__

=head1 NAME

Hypersonic::Event::Kqueue - kqueue event backend for BSD/macOS

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('kqueue');
    # $backend is 'Hypersonic::Event::Kqueue'

=head1 DESCRIPTION

C<Hypersonic::Event::Kqueue> is the kqueue-based event backend for Hypersonic.
It is native to BSD-derived systems including macOS.

kqueue provides efficient O(1) event notification similar to Linux's epoll,
making it ideal for high-performance servers.

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::Kqueue->name;  # 'kqueue'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::Kqueue->available) { ... }

Returns true if this backend is available (BSD/macOS only).

=head2 includes

Returns the C #include directives needed for kqueue.

=head2 defines

Returns the C #define directives for kqueue configuration.

=head2 event_struct

    my $struct = Hypersonic::Event::Kqueue->event_struct;  # 'kevent'

Returns the C struct name used for the events array.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to create a kqueue instance and register the listen socket.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to add a file descriptor to the kqueue.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to remove a file descriptor from the kqueue.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for events with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the file descriptor from an event.

=head1 AVAILABILITY

macOS (darwin), FreeBSD, OpenBSD, NetBSD.

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Epoll>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
