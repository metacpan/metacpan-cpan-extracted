package IPC::Manager::Client::SharedMem;
use strict;
use warnings;

our $VERSION = '0.000011';

use Carp qw/croak/;

use IPC::Manager::Message;
use IPC::Manager::Serializer::JSON;

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +_shm_id
    +_sem_id
};

my $SHM_INITIAL_SIZE = 65536;
my $SHM_GROW_FACTOR  = 2;

my ($_IPC_PRIVATE, $_IPC_CREAT, $_IPC_RMID, $_S_IRUSR, $_S_IWUSR);

sub _load_constants {
    return if $_IPC_PRIVATE;
    require IPC::SysV;
    $_IPC_PRIVATE = IPC::SysV::IPC_PRIVATE();
    $_IPC_CREAT   = IPC::SysV::IPC_CREAT();
    $_IPC_RMID    = IPC::SysV::IPC_RMID();
    $_S_IRUSR     = IPC::SysV::S_IRUSR();
    $_S_IWUSR     = IPC::SysV::S_IWUSR();
}

sub viable {
    local $@;
    eval { require IPC::SysV; IPC::SysV->VERSION('2.09'); 1 } || 0;
}

# Route format: "shmid:semid"

sub _parse_route {
    my ($route) = @_;
    my ($shm_id, $sem_id) = split /:/, $route, 2;
    return ($shm_id + 0, $sem_id + 0);
}

sub _build_route {
    my ($shm_id, $sem_id) = @_;
    return "$shm_id:$sem_id";
}

sub spawn {
    my $class  = shift;
    my %params = @_;

    _load_constants();

    my $size  = delete $params{shm_size} // $SHM_INITIAL_SIZE;
    my $flags = $_S_IRUSR | $_S_IWUSR | $_IPC_CREAT;

    my $sem_id = semget($_IPC_PRIVATE, 1, $flags);
    defined $sem_id or croak "Cannot create semaphore: $!";
    # Initialize semaphore to 1 (unlocked)
    semop($sem_id, pack("s!3", 0, 1, 0)) or croak "Cannot init semaphore: $!";

    my $shm_id = shmget($_IPC_PRIVATE, $size, $flags);
    defined $shm_id or croak "Cannot create shared memory: $!";

    my $state = {clients => {}, messages => {}, stats => {}};
    my $data  = IPC::Manager::Serializer::JSON->serialize($state);
    _shm_write($shm_id, $data, $size);

    return _build_route($shm_id, $sem_id);
}

sub unspawn {
    my $class = shift;
    my ($route) = @_;
    return unless $route;

    _load_constants();

    my ($shm_id, $sem_id) = _parse_route($route);

    # Follow any forwarding pointers to find and remove grown segments
    local $@;
    eval {
        my ($data) = _shm_read($shm_id);
        if ($data) {
            my $state = IPC::Manager::Serializer::JSON->deserialize($data);
            if ($state->{_shm_id} && $state->{_shm_id} != $shm_id) {
                shmctl($state->{_shm_id}, $_IPC_RMID, 0);
            }
        }
        1;
    } or warn $@;

    # Remove original shared memory segment
    eval { shmctl($shm_id, $_IPC_RMID, 0); 1 } or warn $@;

    # Remove semaphore
    eval { semctl($sem_id, 0, $_IPC_RMID, 0); 1 } or warn $@;
}

# --- Raw shared memory I/O ---
#
# Segment layout:
#   bytes 0-3:  segment capacity  (network-order u32)
#   bytes 4-7:  data length       (network-order u32)
#   bytes 8+:   JSON data

my $HEADER_SIZE = 8;

sub _shm_write {
    my ($shm_id, $data, $capacity) = @_;
    my $needed = $HEADER_SIZE + length($data);
    croak "Data too large for shared memory segment ($needed > $capacity)"
        if $needed > $capacity;
    my $header = pack("NN", $capacity, length($data));
    shmwrite($shm_id, $header . $data, 0, $needed) or croak "shmwrite failed: $!";
}

sub _shm_read {
    my ($shm_id) = @_;
    my $header = '';
    shmread($shm_id, $header, 0, $HEADER_SIZE) or croak "shmread (header) failed: $!";
    my ($capacity, $len) = unpack("NN", $header);
    return (undef, 0) unless $len;
    my $data = '';
    shmread($shm_id, $data, $HEADER_SIZE, $len) or croak "shmread (data) failed: $!";
    # shmread pads with nulls; trim to actual length
    $data = substr($data, 0, $len);
    return ($data, $capacity);
}

# --- Locking via semaphore ---

sub _get_ids {
    my $self = shift;

    unless ($self->{+_SHM_ID}) {
        my ($shm_id, $sem_id) = _parse_route($self->{route});
        $self->{+_SHM_ID} = $shm_id;
        $self->{+_SEM_ID} = $sem_id;
    }

    return ($self->{+_SHM_ID}, $self->{+_SEM_ID});
}

sub _sem_lock {
    my ($sem_id) = @_;
    # decrement semaphore (wait until > 0, then decrement)
    semop($sem_id, pack("s!3", 0, -1, 0)) or croak "Cannot acquire semaphore lock: $!";
}

sub _sem_unlock {
    my ($sem_id) = @_;
    # increment semaphore
    semop($sem_id, pack("s!3", 0, 1, 0)) or croak "Cannot release semaphore lock: $!";
}

sub _lock_read {
    my $self = shift;
    my ($shm_id, $sem_id) = $self->_get_ids;
    _sem_lock($sem_id);

    my ($state, $err);
    my $ok = eval {
        my ($data) = _shm_read($shm_id);
        $state = IPC::Manager::Serializer::JSON->deserialize($data);

        # Follow forwarding pointer if segment was grown by another process
        if ($state->{_shm_id} && $state->{_shm_id} != $shm_id) {
            $self->{+_SHM_ID} = $state->{_shm_id};
            ($data) = _shm_read($self->{+_SHM_ID});
            $state  = IPC::Manager::Serializer::JSON->deserialize($data);
        }
        1;
    };

    $err = $@ unless $ok;
    _sem_unlock($sem_id);
    die $err if $err;
    return $state;
}

sub _lock_write {
    my $self = shift;
    my ($shm_id, $sem_id) = $self->_get_ids;
    _sem_lock($sem_id);
    my ($data) = _shm_read($shm_id);
    my $state  = IPC::Manager::Serializer::JSON->deserialize($data);

    # If the segment was grown by another process, follow the pointer
    if ($state->{_shm_id} && $state->{_shm_id} != $shm_id) {
        $self->{+_SHM_ID} = $state->{_shm_id};
        ($data) = _shm_read($self->{+_SHM_ID});
        $state  = IPC::Manager::Serializer::JSON->deserialize($data);
    }

    return $state;
}

sub _commit {
    my ($self, $state) = @_;
    my ($shm_id, $sem_id) = $self->_get_ids;

    # Remove internal tracking keys before serializing
    delete $state->{_shm_id};

    my $data   = IPC::Manager::Serializer::JSON->serialize($state);
    my $needed = $HEADER_SIZE + length($data);

    # Read current capacity from the segment header
    my $cap_buf = '';
    shmread($shm_id, $cap_buf, 0, 4) or croak "shmread (capacity) failed: $!";
    my $capacity = unpack("N", $cap_buf);

    if ($needed > $capacity) {
        $self->_grow_segment($state, $data, $capacity);
    }
    else {
        _shm_write($shm_id, $data, $capacity);
    }

    _sem_unlock($sem_id);
}

sub _unlock {
    my $self = shift;
    my (undef, $sem_id) = $self->_get_ids;
    eval { _sem_unlock($sem_id); 1 } or warn $@;
}

sub _grow_segment {
    my ($self, $state, $data, $old_capacity) = @_;

    _load_constants();

    my $needed = $HEADER_SIZE + length($data);
    my $new_capacity = $old_capacity;
    $new_capacity *= $SHM_GROW_FACTOR while $new_capacity < $needed;

    my $flags = $_S_IRUSR | $_S_IWUSR | $_IPC_CREAT;
    my $new_shm_id = shmget($_IPC_PRIVATE, $new_capacity, $flags);
    defined $new_shm_id or croak "Cannot create new shared memory segment: $!";

    _shm_write($new_shm_id, $data, $new_capacity);

    # Write a forwarding pointer to the old segment so other processes
    # can find the new one
    my $old_shm_id = $self->{+_SHM_ID};
    my $fwd = IPC::Manager::Serializer::JSON->serialize({_shm_id => $new_shm_id});
    eval { _shm_write($old_shm_id, $fwd, $old_capacity); 1 } or warn $@;

    $self->{+_SHM_ID} = $new_shm_id;

    # Update route
    $self->{route} = _build_route($new_shm_id, $self->{+_SEM_ID});
}

# --- Client lifecycle ---

sub init {
    my $self = shift;

    $self->SUPER::init();

    _load_constants();

    my $id    = $self->{id};
    my $state = $self->_lock_write;

    my $ok = eval {
        if ($self->{reconnect}) {
            unless ($state->{clients}{$id}) {
                $self->{disconnected} = 1;
                croak "Client '$id' does not exist";
            }
            my $data = $state->{clients}{$id};
            if ($data->{pid} && $data->{pid} != $$ && kill(0, $data->{pid})) {
                $self->{disconnected} = 1;
                croak "Connection already running in pid $data->{pid}";
            }
        }
        else {
            if ($state->{clients}{$id}) {
                $self->{disconnected} = 1;
                croak "Client '$id' already exists";
            }
            $state->{clients}{$id} = {pid => $$};
            $state->{messages}{$id} //= [];
        }

        $state->{clients}{$id}{pid} = $$;

        $self->_commit($state);
        1;
    };

    unless ($ok) {
        my $err = $@;
        $self->_unlock;
        die $err;
    }
}

# --- Messages ---

sub pending_messages { 0 }

sub ready_messages {
    my $self = shift;
    my $state;
    unless (eval { $state = $self->_lock_read; 1 }) {
        warn $@;
        return 0;
    }
    my $msgs = $state->{messages}{$self->{id}} // [];
    return @$msgs ? 1 : 0;
}

sub get_messages {
    my $self = shift;
    $self->pid_check;

    my $state = $self->_lock_write;
    my $raw   = delete $state->{messages}{$self->{id}} // [];
    $state->{messages}{$self->{id}} = [];
    $self->_commit($state);

    my @out;
    for my $h (@$raw) {
        my $msg = IPC::Manager::Message->new(%$h);
        $self->{stats}{read}{$msg->{from}}++;
        push @out, $msg;
    }

    return sort { $a->stamp <=> $b->stamp } @out;
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);
    $self->pid_check;

    my $peer_id = $msg->to or croak "Message has no peer";

    my $state = $self->_lock_write;

    my $ok = eval {
        croak "Client '$peer_id' does not exist"
            unless $state->{clients}{$peer_id};

        push @{$state->{messages}{$peer_id}}, $msg->TO_JSON;

        $self->_commit($state);
        1;
    };

    unless ($ok) {
        my $err = $@;
        $self->_unlock;
        die $err;
    }

    $self->{stats}{sent}{$peer_id}++;
}

# --- Peer queries ---

sub peers {
    my $self  = shift;
    my $state = $self->_lock_read;
    return sort grep { $_ ne $self->{id} } keys %{$state->{clients}};
}

sub peer_exists {
    my $self = shift;
    my ($peer_id) = @_;
    croak "'peer_id' is required" unless $peer_id;
    my $state = $self->_lock_read;
    return $state->{clients}{$peer_id} ? 1 : undef;
}

sub peer_pid {
    my $self = shift;
    my ($peer_id) = @_;
    my $state = $self->_lock_read;
    my $data = $state->{clients}{$peer_id};
    return undef unless $data;
    return $data->{pid};
}

# --- Stats ---

sub write_stats {
    my $self  = shift;
    my $state;
    unless (eval { $state = $self->_lock_write; 1 }) {
        warn $@;
        return;
    }

    my $ok = eval {
        $state->{stats}{$self->{id}} = $self->{stats};
        $self->_commit($state);
        1;
    };

    unless ($ok) {
        warn $@;
        $self->_unlock;
    }
}

sub read_stats {
    my $self  = shift;
    my $state = $self->_lock_read;
    return $state->{stats}{$self->{id}} // {read => {}, sent => {}};
}

sub all_stats {
    my $self  = shift;
    my $state = $self->_lock_read;
    my %out;
    for my $id (keys %{$state->{stats}}) {
        $out{$id} = $state->{stats}{$id};
    }
    return \%out;
}

# --- Disconnect ---

sub post_disconnect_hook {
    my $self  = shift;
    my $state;
    unless (eval { $state = $self->_lock_write; 1 }) {
        warn $@;
        return;
    }

    my $ok = eval {
        delete $state->{clients}{$self->{id}};
        delete $state->{messages}{$self->{id}};
        $self->_commit($state);
        1;
    };

    unless ($ok) {
        warn $@;
        $self->_unlock;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::SharedMem - SysV shared memory as a message store

=head1 DESCRIPTION

This protocol stores all client state, messages, and statistics in a SysV
shared memory segment.  Access is serialised with a SysV semaphore.  Every
mutation acquires the semaphore, reads the segment, modifies the in-memory
structure, writes it back, and releases the semaphore.

The data is stored as JSON prefixed with a 4-byte network-order length.
When the data outgrows the current segment, a new larger segment is
allocated and the old one is removed.

This protocol requires L<IPC::SysV> version 2.09 or later (a core module).

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'SharedMem');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2 => $spawn->info);

    $con1->send_message(con2 => {hello => 'world'});

    my @messages = $con2->get_messages;

=head1 ROUTE FORMAT

The route is a colon-separated string: C<shmid:semid>, where C<shmid>
and C<semid> are SysV IPC identifiers (integers).  The segment capacity
is stored in the segment header itself, so it does not need to appear
in the route.

=head1 METHODS

See L<IPC::Manager::Client> for inherited methods.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
