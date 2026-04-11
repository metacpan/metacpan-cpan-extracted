package IPC::Manager::Client::JSONFile;
use strict;
use warnings;

our $VERSION = '0.000016';

use Carp qw/croak/;
use Fcntl qw/:flock/;
use File::Temp ();

my $HAVE_SHA;
BEGIN { $HAVE_SHA = eval { require Digest::SHA; Digest::SHA->import('sha256_hex'); 1 } ? 1 : 0 }

use IPC::Manager::Message;
use IPC::Manager::Serializer::JSON;
use IPC::Manager::Util qw/USE_INOTIFY/;

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +_cache_state
    +_cache_mtime
    +_cache_sha
    +_cache_gen
    +_cache_time
    +_cache_sha_verified
    +_inotify
    interval
};

# Per-route write generation counter so that multiple client objects
# sharing the same file in a single process always detect each other's
# writes, even when filesystem mtime resolution is too coarse.
my %_WRITE_GEN;

sub _viable { USE_INOTIFY || $HAVE_SHA || die "Need Linux::Inotify2 or Digest::SHA" }

sub sanity {
    return if USE_INOTIFY || $HAVE_SHA;
    croak "JSONFile requires either Linux::Inotify2 or Digest::SHA for reliable cache invalidation";
}

# The route is the path to the JSON file.  The file stores:
#   {
#     clients  => { id => { pid => $$ } },
#     messages => { id => [ @message_hashes ] },
#     stats    => { id => { read => {}, sent => {} } },
#   }

sub spawn {
    my $class  = shift;
    my %params = @_;

    $class->sanity;

    my $template = delete $params{template} // "PerlIPCMgr-$$-XXXXXX";
    my ($fh, $file) = File::Temp::tempfile($template, TMPDIR => 1, SUFFIX => '.json', UNLINK => 0);

    my $state = {clients => {}, messages => {}, stats => {}};
    print $fh IPC::Manager::Serializer::JSON->serialize($state);
    close $fh;

    return $file;
}

sub unspawn {
    my $class = shift;
    my ($route) = @_;
    unlink $route if $route && -e $route;
}

# --- Cache / change-detection ---

sub _file_sha {
    my $self = shift;
    croak "Digest::SHA is required for SHA-based cache invalidation" unless $HAVE_SHA;
    open(my $fh, '<', $self->{route}) or return undef;
    my $data = do { local $/; <$fh> };
    close $fh;
    return sha256_hex($data);
}

sub _init_inotify {
    my $self = shift;
    return unless USE_INOTIFY;
    return if $self->{+_INOTIFY};

    my $i = Linux::Inotify2->new or return;
    $i->blocking(0);
    $i->watch(
        $self->{route},
        Linux::Inotify2::IN_MODIFY() | Linux::Inotify2::IN_CLOSE_WRITE(),
    ) or return;

    $self->{+_INOTIFY} = $i;
}

sub _cache_is_stale {
    my $self = shift;

    # No cache yet
    return 1 unless defined $self->{+_CACHE_MTIME};

    # Another client in this process wrote to the same file
    my $current_gen = $_WRITE_GEN{$self->{route}} // 0;
    return 1 if ($self->{+_CACHE_GEN} // 0) != $current_gen;

    if (my $i = $self->{+_INOTIFY}) {
        # If inotify has pending events the file has changed
        my @events = $i->read;
        return 1 if @events;
        return 0;
    }

    # Fallback: compare mtime, then SHA after an interval.
    # Mtime has only 1-second resolution on many filesystems, so
    # cross-process writes within the same second go undetected.
    # Once the configured interval elapses with an unchanged mtime we
    # fall back to a SHA comparison to catch those writes.
    my $current_mtime = (stat($self->{route}))[9] // return 1;

    if ($current_mtime != $self->{+_CACHE_MTIME}) {
        delete $self->{+_CACHE_SHA_VERIFIED};
        return 1;
    }

    # Mtime unchanged — if we already verified via SHA, trust it
    # until the mtime changes again.
    return 0 if $self->{+_CACHE_SHA_VERIFIED};

    # Wait for the interval before falling back to SHA.
    my $elapsed = time() - ($self->{+_CACHE_TIME} // 0);
    return 0 if $elapsed < ($self->{+INTERVAL} // 1);

    # Interval elapsed, mtime still unchanged — compare SHA.
    my $current_sha = $self->_file_sha // return 1;
    if ($current_sha ne ($self->{+_CACHE_SHA} // '')) {
        return 1;
    }

    $self->{+_CACHE_SHA_VERIFIED} = 1;
    return 0;
}

sub _update_cache {
    my ($self, $state) = @_;
    $self->{+_CACHE_STATE} = $state;
    $self->{+_CACHE_MTIME} = (stat($self->{route}))[9];
    $self->{+_CACHE_SHA}   = $self->_file_sha if $HAVE_SHA;
    $self->{+_CACHE_GEN}   = $_WRITE_GEN{$self->{route}} // 0;
    $self->{+_CACHE_TIME}  = time();
    delete $self->{+_CACHE_SHA_VERIFIED};
}

sub _invalidate_cache {
    my $self = shift;
    delete $self->{+_CACHE_STATE};
    delete $self->{+_CACHE_MTIME};
}

# --- File I/O with locking ---

sub _read_file_locked {
    my ($self, $fh) = @_;
    seek($fh, 0, 0) or croak "Cannot seek: $!";
    my $data = do { local $/; <$fh> };
    return IPC::Manager::Serializer::JSON->deserialize($data);
}

sub _lock_read {
    my $self = shift;

    # Fast path: return cached state if the file hasn't changed.
    # We return undef for $fh to signal that no lock is held — callers
    # that receive undef must not try to close it.
    unless ($self->_cache_is_stale) {
        return ($self->{+_CACHE_STATE}, undef);
    }

    my $route = $self->{route};
    open(my $fh, '<', $route) or croak "Cannot open '$route': $!";
    flock($fh, LOCK_SH) or croak "Cannot lock '$route': $!";
    my $state = $self->_read_file_locked($fh);
    close $fh;

    $self->_update_cache($state);

    return ($state, undef);
}

sub _lock_write {
    my $self = shift;
    my $route = $self->{route};
    open(my $fh, '+<', $route) or croak "Cannot open '$route': $!";
    flock($fh, LOCK_EX) or croak "Cannot lock '$route': $!";
    my $state = $self->_read_file_locked($fh);
    # Don't update cache yet — caller will modify state and call _commit
    return ($state, $fh);
}

sub _commit {
    my ($self, $state, $fh) = @_;
    seek($fh, 0, 0) or croak "Cannot seek: $!";
    truncate($fh, 0) or croak "Cannot truncate: $!";
    print $fh IPC::Manager::Serializer::JSON->serialize($state);
    close $fh;

    $_WRITE_GEN{$self->{route}}++;

    # Drain any inotify events caused by our own write so the cache
    # doesn't immediately appear stale on the next read.
    if (my $i = $self->{+_INOTIFY}) {
        $i->read;
    }

    $self->_update_cache($state);
}

# --- Client lifecycle ---

sub init {
    my $self = shift;

    $self->sanity;

    $self->SUPER::init();

    $self->_init_inotify;

    my $id = $self->{id};
    my ($state, $fh) = $self->_lock_write;

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

    $self->_commit($state, $fh);
}

# --- Messages ---

sub pending_messages { 0 }

sub ready_messages {
    my $self = shift;
    my $state;
    unless (eval { ($state) = $self->_lock_read; 1 }) {
        warn $@;
        return 0;
    }
    my $msgs = $state->{messages}{$self->{id}} // [];
    return @$msgs ? 1 : 0;
}

sub get_messages {
    my $self = shift;
    $self->pid_check;

    my ($state, $fh) = $self->_lock_write;
    my $raw = delete $state->{messages}{$self->{id}} // [];
    $state->{messages}{$self->{id}} = [];
    $self->_commit($state, $fh);

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

    my ($state, $fh) = $self->_lock_write;

    croak "Client '$peer_id' does not exist"
        unless $state->{clients}{$peer_id};

    push @{$state->{messages}{$peer_id}}, $msg->TO_JSON;

    $self->_commit($state, $fh);

    $self->{stats}{sent}{$peer_id}++;
}

# --- Peer queries ---

sub peers {
    my $self = shift;
    my ($state) = $self->_lock_read;
    return sort grep { $_ ne $self->{id} } keys %{$state->{clients}};
}

sub peer_exists {
    my $self = shift;
    my ($peer_id) = @_;
    croak "'peer_id' is required" unless $peer_id;
    my ($state) = $self->_lock_read;
    return $state->{clients}{$peer_id} ? 1 : undef;
}

sub peer_pid {
    my $self = shift;
    my ($peer_id) = @_;
    my ($state) = $self->_lock_read;
    my $data = $state->{clients}{$peer_id};
    return undef unless $data;
    return $data->{pid};
}

# --- Stats ---

sub write_stats {
    my $self = shift;
    my ($state, $fh);
    unless (eval { ($state, $fh) = $self->_lock_write; 1 }) {
        warn $@;
        return;
    }
    $state->{stats}{$self->{id}} = $self->{stats};
    $self->_commit($state, $fh);
}

sub read_stats {
    my $self = shift;
    my ($state) = $self->_lock_read;
    return $state->{stats}{$self->{id}} // {read => {}, sent => {}};
}

sub all_stats {
    my $self = shift;
    my ($state) = $self->_lock_read;
    my %out;
    for my $id (keys %{$state->{stats}}) {
        $out{$id} = $state->{stats}{$id};
    }
    return \%out;
}

# --- Disconnect ---

sub post_disconnect_hook {
    my $self = shift;
    my ($state, $fh);
    unless (eval { ($state, $fh) = $self->_lock_write; 1 }) {
        warn $@;
        return;
    }
    delete $state->{clients}{$self->{id}};
    delete $state->{messages}{$self->{id}};
    $self->_commit($state, $fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::JSONFile - Single JSON file as a message store

=head1 DESCRIPTION

This protocol stores all client state, messages, and statistics in a single
JSON file.  The file is the "route".  All access is serialised with
L<flock(2)> — a shared lock for reads and an exclusive lock for writes.
Every mutation reads the file, modifies the in-memory structure, and rewrites
the entire file.

State is cached in memory and only re-read when the file has changed.  When
L<Linux::Inotify2> is available the file is watched for C<IN_MODIFY> /
C<IN_CLOSE_WRITE> events; otherwise the file's mtime is compared to detect
changes.

This protocol is simple and portable but not suited for high-throughput
workloads; the file-level lock serialises all operations across all clients.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'JSONFile');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2 => $spawn->info);

    $con1->send_message(con2 => {hello => 'world'});

    my @messages = $con2->get_messages;

=head1 FILE STRUCTURE

The route is the path to a single JSON file created by C<spawn()>.  The file
contains one JSON object with three top-level keys:

    {
        "clients":  { ... },
        "messages": { ... },
        "stats":    { ... }
    }

=head2 clients

A hash mapping each connected client's ID to its metadata.  A client entry is
added during C<init()> (connect) and removed during C<post_disconnect_hook()>.

    "clients": {
        "con1": { "pid": 12345 },
        "con2": { "pid": 12346 }
    }

=over 4

=item pid

The process ID that owns the connection.  Written at connect and checked at
reconnect to prevent duplicate ownership.

=back

=head2 messages

A hash mapping each client ID to an array of pending messages addressed to
that client.  Messages are plain JSON objects (the output of
C<< IPC::Manager::Message->TO_JSON >>).  C<send_message()> appends to the
recipient's array; C<get_messages()> drains it.

    "messages": {
        "con1": [],
        "con2": [
            {
                "id":        "019D55F2-...",
                "stamp":     1775263425.787,
                "from":      "con1",
                "to":        "con2",
                "broadcast": null,
                "content":   { "hello": "world" }
            }
        ]
    }

Each message object has the following fields:

=over 4

=item id

A UUID string uniquely identifying the message.

=item stamp

A high-resolution Unix timestamp (seconds since epoch with sub-second
precision) indicating when the message was created.

=item from

The client ID of the sender.

=item to

The client ID of the intended recipient.

=item broadcast

C<true> if the message was sent via C<broadcast()>, C<null> otherwise.

=item content

The application payload — any JSON-serialisable value (hash, array, string,
number, etc.).

=back

=head2 stats

A hash mapping client IDs to their send/receive statistics.  Entries are
written by C<write_stats()> (called during disconnect) and persist after the
client entry is removed, so that C<all_stats()> and
C<< Spawn->sanity_check() >> can compare totals after all clients have
disconnected.

    "stats": {
        "con1": {
            "read": { "con2": 3 },
            "sent": { "con2": 5 }
        },
        "con2": {
            "read": { "con1": 5 },
            "sent": { "con1": 3 }
        }
    }

=over 4

=item read

A hash mapping sender client IDs to the number of messages received from
that sender.

=item sent

A hash mapping recipient client IDs to the number of messages sent to that
recipient.

=back

=head1 CONCURRENCY

All file access is protected by L<flock(2)>:

=over 4

=item *

B<Read operations> (C<peers>, C<peer_exists>, C<peer_pid>, C<ready_messages>,
C<read_stats>, C<all_stats>) acquire a B<shared lock> (C<LOCK_SH>).  Multiple
readers may proceed concurrently.

=item *

B<Write operations> (C<init>, C<send_message>, C<get_messages>,
C<write_stats>, C<post_disconnect_hook>) acquire an B<exclusive lock>
(C<LOCK_EX>), re-read the file to get the latest state, modify it, and
rewrite the entire file.

=back

State is cached in memory and only re-read from disk when a change is
detected.  When L<Linux::Inotify2> is available, the file is watched for
C<IN_MODIFY> / C<IN_CLOSE_WRITE> events.  Otherwise the file's mtime is
compared against the cached value.  After each write the cache is updated
and any self-generated inotify events are drained so the cache is not
spuriously invalidated.

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
