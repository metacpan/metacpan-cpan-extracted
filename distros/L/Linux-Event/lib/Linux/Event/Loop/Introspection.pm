package Linux::Event::Loop::Introspection;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);
my @CENSUS_TYPES = qw(pipe tty stream listener dgram timer signal event inotify process);

sub _type_of ($object) {
    return 'unknown'
        if $object->isa('Linux::Event::_ByteStream::_Deadline')
        || $object->isa('Linux::Event::_Socket::Dgram::_ReadyTimer');
    return 'pipe'     if $object->isa('Linux::Event::IO::Pipe');
    return 'tty'      if $object->isa('Linux::Event::IO::TTY');
    return 'stream'   if $object->isa('Linux::Event::IO::Sock::Stream');
    return 'listener' if $object->isa('Linux::Event::IO::Sock::Listener');
    return 'dgram'    if $object->isa('Linux::Event::IO::Sock::Dgram');
    return 'timer'    if $object->isa('Linux::Event::Kernel::Timer');
    return 'signal'   if $object->isa('Linux::Event::Kernel::Signal');
    return 'event'    if $object->isa('Linux::Event::Kernel::Event');
    return 'inotify'  if $object->isa('Linux::Event::Kernel::Inotify');
    return 'process'  if $object->isa('Linux::Event::Kernel::Process');
    return 'unknown';
}

sub _is_current ($self, $object) {
    return 0 if !blessed($object) || _type_of($object) eq 'unknown';
    my $loop = eval { $object->loop };
    return 0 if !$loop || refaddr($loop) != refaddr($self);
    return 0 if $object->can('is_terminal')
        && eval { $object->is_terminal };
    return 1;
}

sub _object_snapshot ($self) {
    my @candidate = @{ $self->_object_candidates_native };
    push @candidate, @{ Linux::Event::Kernel::Signal->_objects_for_loop($self) }
        if Linux::Event::Kernel::Signal->can('_objects_for_loop');
    push @candidate, @{ Linux::Event::Kernel::Event->_objects_for_loop($self) }
        if Linux::Event::Kernel::Event->can('_objects_for_loop');
    push @candidate, @{ Linux::Event::Kernel::Inotify->_objects_for_loop($self) }
        if Linux::Event::Kernel::Inotify->can('_objects_for_loop');
    push @candidate, @{ Linux::Event::_Resolver->_objects_for_loop($self) }
        if Linux::Event::_Resolver->can('_objects_for_loop');

    my %seen;
    my @result;
    for my $candidate (@candidate) {
        my $object = _owner_of($candidate) // next;
        next if $seen{ refaddr($object) }++;
        next if !$self->_is_current($object);
        push @result, $object;
    }
    return \@result;
}

sub count ($self) { scalar @{ $self->_object_snapshot } }

sub has ($self, $object) {
    return 0 if !blessed($object);
    return 0 if !$self->_is_current($object);
    my $id = refaddr($object);
    return !!grep { refaddr($_) == $id } @{ $self->_object_snapshot };
}

sub objects ($self) { [ @{ $self->_object_snapshot } ] }

sub census ($self) {
    my %count = map { $_ => 0 } @CENSUS_TYPES;
    $count{ _type_of($_) }++ for @{ $self->_object_snapshot };
    return \%count;
}

sub _value ($object, $method) {
    return undef if !$object->can($method);
    return eval { $object->$method() };
}

sub _owner_of ($candidate) {
    return undef if !ref($candidate);
    if (blessed($candidate)) {
        return $candidate if _type_of($candidate) ne 'unknown';
        return _owner_of(scalar eval { $candidate->object })
            if $candidate->isa('Linux::Event::_ByteStream::State');
        return _owner_of(scalar eval { $candidate->_introspection_owner })
            if $candidate->can('_introspection_owner');
        return undef;
    }
    if (ref($candidate) eq 'HASH') {
        for my $key (qw(stream recipient owner object request)) {
            my $owner = _owner_of($candidate->{$key});
            return $owner if $owner;
        }
    }
    return undef;
}

sub _fd ($object) {
    return _value($object, 'fd') if $object->can('fd');
    my $fh = _value($object, 'fh');
    return defined($fh) ? fileno($fh) : undef;
}

sub inspect ($self, $object) {
    return $self->_inspect_object($object, $self->has($object));
}

sub _inspect_object ($self, $object, $registered) {
    my $type = blessed($object) ? _type_of($object) : 'unknown';
    my $result = {
        type       => $type,
        class      => blessed($object) || undef,
        registered => $registered ? 1 : 0,
    };
    return $result if !$registered;

    $result->{state} = _value($object, 'state');
    if ($type eq 'pipe' || $type eq 'tty' || $type eq 'stream') {
        @$result{qw(fd read_fd write_fd pending_bytes read_paused read_eof
            read_closed write_ended write_blocked)} = (
            _fd($object), _value($object, 'read_fd'),
            _value($object, 'write_fd'),
            _value($object, 'pending_bytes'),
            _value($object, 'is_read_paused') ? 1 : 0,
            _value($object, 'is_read_eof') ? 1 : 0,
            _value($object, 'is_read_closed') ? 1 : 0,
            _value($object, 'is_write_ended') ? 1 : 0,
            _value($object, 'is_write_blocked') ? 1 : 0,
        );
        if ($type eq 'stream') {
            @$result{qw(local peer transport)} = (
                _value($object, 'local'), _value($object, 'peer'),
                _value($object, 'transport_name'),
            );
        }
    }
    elsif ($type eq 'listener') {
        @$result{qw(fd host port path family paused accepted)} = (
            _fd($object), _value($object, 'host'), _value($object, 'port'),
            _value($object, 'path'), _value($object, 'family'),
            _value($object, 'is_paused') ? 1 : 0,
            _value($object, 'accepted'),
        );
    }
    elsif ($type eq 'dgram') {
        @$result{qw(fd local peer connected pending_bytes pending_datagrams
            read_paused)} = (
            _fd($object), _value($object, 'local'),
            _value($object, 'peer'),
            _value($object, 'is_connected') ? 1 : 0,
            _value($object, 'pending_bytes'),
            _value($object, 'pending_datagrams'),
            _value($object, 'is_read_paused') ? 1 : 0,
        );
    }
    elsif ($type eq 'timer') {
        @$result{qw(deadline interval expirations)} = (
            _value($object, 'deadline'), _value($object, 'interval'),
            _value($object, 'expirations'),
        );
    }
    elsif ($type eq 'signal') {
        $result->{signals} = _value($object, 'signals');
    }
    elsif ($type eq 'inotify') {
        @$result{qw(fd watches)} = (
            _value($object, 'fd'), _value($object, 'watch_count'),
        );
    }
    elsif ($type eq 'process') {
        @$result{qw(pid pending_stdin_bytes)} = (
            _value($object, 'pid'), _value($object, 'pending_stdin_bytes'),
        );
    }
    return $result;
}

sub resources ($self) {
    my $resource = $self->_resources_native;
    $resource->{defer_fd} = $self->_deferred_fd;
    $resource->{pending_deferred} = $self->_deferred_count;
    return $resource;
}

sub why_alive ($self) {
    my @reason = map {
        my $snapshot = $self->_inspect_object($_, 1);
        $snapshot->{object} = $_;
        $snapshot;
    } @{ $self->_object_snapshot };
    my $resources = $self->resources;
    push @reason, map {
        +{ type => 'registration', registered => 1, fd => $_ }
    } @{ $resources->{public_registration_fds} };
    push @reason, {
        type => 'deferred', pending => $resources->{pending_deferred},
    } if $resources->{pending_deferred};
    return \@reason;
}

sub pressure ($self) {
    my $resource = $self->_resources_native;
    my $stats = $self->stats;
    my $registry_capacity = $resource->{registry_capacity};
    my $timer_capacity = $resource->{timer_heap_capacity};
    my $event_capacity = $resource->{event_capacity};
    return {
        registrations => {
            active      => $resource->{registered_fds},
            capacity    => $registry_capacity,
            utilization => $registry_capacity
                ? $resource->{registered_fds} / $registry_capacity : 0,
        },
        timers => {
            active      => $resource->{active_timers},
            capacity    => $timer_capacity,
            utilization => $timer_capacity
                ? $resource->{active_timers} / $timer_capacity : 0,
        },
        event_batch => {
            capacity    => $event_capacity,
            maximum     => $stats->{epoll_wait_calls}
                ? $stats->{epoll_wait_max_batch} : undef,
            utilization => $stats->{epoll_wait_calls} && $event_capacity
                ? $stats->{epoll_wait_max_batch} / $event_capacity : undef,
        },
    };
}

1;
