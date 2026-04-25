package IPC::Manager::Base::FS;
use strict;
use warnings;

our $VERSION = '0.000033';

use File::Spec;

use Carp qw/croak/;
use File::Temp qw/tempdir/;
use File::Path qw/remove_tree/;
use Digest::SHA qw/sha256_hex/;

use IPC::Manager::Util qw/USE_INOTIFY USE_IO_SELECT/;

# When the peer id is too long or contains path-unsafe characters, we hash
# it to this on-disk form. "h-" + 40 hex chars of sha256 = 42 chars total.
# The "h-" prefix is reserved: any caller-supplied id starting with "h-"
# that would otherwise be used verbatim is still hashed, so the real name
# is always read from the ".name" sidecar to avoid ambiguity.
use constant ON_DISK_HASH_LEN => 40;
use constant ON_DISK_HASH_PREFIX => 'h-';

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +path
    +pidfile
    +resume_file
    +select
    +peer_inotify
};

sub pending_messages { 0 }

sub ready_messages { croak "Not Implemented" }
sub get_messages   { croak "Not Implemented" }
sub send_message   { croak "Not Implemented" }
sub check_path     { croak "Not Implemented" }
sub make_path      { croak "Not Implemented" }
sub path_type      { croak "Not Implemented" }

sub max_on_disk_name_length { 200 }

sub on_disk_name {
    my ($self, $peer_id) = @_;
    croak "peer_id is required" unless defined $peer_id && length $peer_id;

    my $max = $self->max_on_disk_name_length;
    if (length($peer_id) <= $max
        && $peer_id !~ m{[\x00-\x1f/\\]}
        && index($peer_id, ON_DISK_HASH_PREFIX) != 0)
    {
        return $peer_id;
    }

    my $hashed_len = length(ON_DISK_HASH_PREFIX) + ON_DISK_HASH_LEN;
    croak sprintf(
        "Cannot map peer id '%s' to on-disk name: hashed form (%d bytes) exceeds available budget (%d bytes) under route '%s'",
        $peer_id, $hashed_len, $max, $self->{+ROUTE},
    ) if $hashed_len > $max;

    return ON_DISK_HASH_PREFIX . substr(sha256_hex($peer_id), 0, ON_DISK_HASH_LEN);
}

sub name_file {
    my $self = shift;
    my ($peer_id) = @_;
    $peer_id //= $self->{+ID};
    return File::Spec->catfile($self->{+ROUTE}, $self->on_disk_name($peer_id) . ".name");
}

sub _read_name_file {
    my ($self, $on_disk) = @_;
    my $file = File::Spec->catfile($self->{+ROUTE}, "$on_disk.name");
    return undef unless -e $file;
    open(my $fh, '<', $file) or return undef;
    my $real = do { local $/; <$fh> };
    close($fh);
    return $real;
}

sub _real_name_for_on_disk {
    my ($self, $on_disk) = @_;
    my $real = $self->_read_name_file($on_disk);
    return defined($real) ? $real : $on_disk;
}

sub _write_name_file {
    my $self = shift;

    my $on_disk = $self->on_disk_name($self->{+ID});
    return if $on_disk eq $self->{+ID};

    my $file = File::Spec->catfile($self->{+ROUTE}, "$on_disk.name");
    my $pend = $file . ".pend";
    open(my $fh, '>', $pend) or die "Could not open name file '$pend': $!";
    print $fh $self->{+ID};
    close($fh);
    rename($pend, $file) or die "Could not rename '$pend' -> '$file': $!";
}

sub have_resume_file {
    my $self = shift;
    my $file = eval { $self->resume_file } // return 0;
    return -e $file;
}

sub can_select { USE_IO_SELECT() }
sub select {
    my $self = shift;

    return $self->{+SELECT} if $self->{+SELECT};

    croak "Not Implemented (Or you are missing IO::Select)" unless USE_IO_SELECT();
    my $sel = IO::Select->new;
    $sel->add($self->handles_for_select);

    return $self->{+SELECT} = $sel;
}

sub all_stats {
    my $self = shift;

    my $out = {};

    opendir(my $dh, $self->{+ROUTE}) or die "Could not open dir: $!";
    for my $file (readdir($dh)) {
        next unless $file =~ m/^(.+)\.stats$/;
        my $peer = $self->_real_name_for_on_disk($1);
        open(my $fh, '<', File::Spec->catfile($self->{+ROUTE}, $file)) or die "Could not open stats file: $!";
        $out->{$peer} = do { local $/; $self->{+SERIALIZER}->deserialize(<$fh>) };
        close($fh);
    }

    close($dh);

    return $out;
}

sub stats_file {
    my $self = shift;
    return File::Spec->catfile($self->{+ROUTE}, $self->on_disk_name($self->{+ID}) . ".stats");
}

sub write_stats {
    my $self = shift;

    my $file = eval { $self->stats_file } // return;
    if (open(my $fh, '>', $file)) {
        print $fh $self->{+SERIALIZER}->serialize($self->{+STATS});
        close($fh);
    }
    elsif(-d $self->{+ROUTE}) {
        die "Could not open stats file ($file): $!";
    }
}

sub read_stats {
    my $self = shift;

    open(my $fh, '<', $self->stats_file) or die "Could not open stats file: $!";
    my $stats = do { local $/; <$fh> };
    close($fh);
    $self->{+SERIALIZER}->deserialize($stats);
}

sub pidfile {
    my $self = shift;
    return $self->{+PIDFILE} //= $self->peer_pid_file($self->{+ID});
}

sub path {
    my $self = shift;
    return $self->{+PATH} //= File::Spec->catfile($self->{+ROUTE}, $self->on_disk_name($self->{+ID}));
}

sub resume_file {
    my $self = shift;
    return $self->{+RESUME_FILE} //= File::Spec->catfile($self->{+ROUTE}, $self->on_disk_name($self->{+ID}) . ".resume");
}

sub peer_pid_file {
    my $self = shift;
    my ($peer_id) = @_;

    return File::Spec->catfile($self->{+ROUTE}, $self->on_disk_name($peer_id) . ".pid");
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $id   = $self->{+ID};
    my $path = $self->path;

    my $pt = $self->path_type;

    if ($self->{+RECONNECT}) {
        croak "${id} ${pt} does not exist" unless $self->check_path($path);
        my $pidfile = $self->pidfile;
        if (open(my $fh, '<', $pidfile)) {
            chomp(my $pid = <$fh>);
            croak "Looks like the connection is already running in pid $pid" if $pid && $self->pid_is_running($pid);
            close($fh);
        }
    }
    else {
        croak "${id} ${pt} already exists" if -e $path;
        $self->make_path($path);
        $self->_write_name_file;
    }

    # Prime the peer-change inotify watch now that the route directory
    # exists, so events are captured from the start.
    $self->handles_for_peer_change if USE_INOTIFY();

    $self->write_pid;
}

sub clear_pid {
    my $self = shift;

    my $pidfile = $self->pidfile;
    unlink($pidfile) or die "Could not unlink pidfile '$pidfile': $!";
}

sub write_pid {
    my $self = shift;

    my $pidfile = $self->pidfile;
    my $pend = $pidfile . ".pend";
    open(my $fh, '>', $pend) or die "Could not open pidfile '$pend': $!";
    print $fh $self->{+PID};
    close($fh);
    rename($pend, $pidfile) or die "Could not rename file '$pend' -> '$pidfile': $!";
}

sub requeue_message {
    my $self = shift;
    $self->pid_check;
    open(my $fh, '>>', $self->resume_file) or die "Could not open resume file: $!";
    for my $msg (@_) {
        print $fh $self->{+SERIALIZER}->serialize($msg), "\n";
    }
    close($fh);
}

sub read_resume_file {
    my $self = shift;

    my @out;

    my $rf = $self->resume_file;
    return @out unless -e $rf;

    open(my $fh, '<', $rf) or die "Could not open resume file: $!";
    while (my $line = <$fh>) {
        push @out => IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($line));
    }
    close($fh);

    unlink($rf) or die "Could not unlink resume file";

    return @out;
}

sub post_disconnect_hook {
    my $self = shift;
    $self->SUPER::post_disconnect_hook;
    my $path = eval { $self->path } // return;
    remove_tree($path, {keep_root => 0, safe => 1}) if -e $path;
}

sub pre_suspend_hook {
    my $self = shift;
    $self->clear_pid;
}

sub reset_handles_for_peer_change { $_[0]->{+PEER_INOTIFY}->read }
sub have_handles_for_peer_change { USE_INOTIFY() }
sub handles_for_peer_change {
    my $self = shift;
    croak "Not Implemented (Linux::Inotify2)" unless USE_INOTIFY();

    unless ($self->{+PEER_INOTIFY}) {
        my $i = Linux::Inotify2->new;
        $i->blocking(0);
        $i->watch($self->{+ROUTE}, Linux::Inotify2::IN_CREATE());
        $self->{+PEER_INOTIFY} = $i;
    }

    return $self->{+PEER_INOTIFY}->fh;
}

sub peers {
    my $self = shift;

    my $my_on_disk = $self->on_disk_name($self->{+ID});

    my @out;

    opendir(my $dh, $self->{+ROUTE}) or die "Could not open dir: $!";
    for my $file (readdir($dh)) {
        next if $file eq $my_on_disk;
        next if $file =~ m/^(\.|_)/;
        next if $file =~ m/\.(?:pid|name|resume|stats)$/;

        my $path = File::Spec->catdir($self->{+ROUTE}, $file);
        next unless $self->check_path($path);

        push @out => $self->_real_name_for_on_disk($file);
    }

    close($dh);

    return sort @out;
}

sub peer_pid {
    my $self = shift;
    my ($peer_id) = @_;

    my $path    = $self->peer_exists($peer_id) or return undef;
    my $pidfile = $self->peer_pid_file($peer_id);
    return 0 unless -f $pidfile;
    open(my $fh, '<', $pidfile) or return 0;
    chomp(my $pid = <$fh>);
    close($fh);
    return $pid;
}

sub peer_exists {
    my $self = shift;
    my ($peer_id) = @_;

    croak "'peer_id' is required" unless $peer_id;

    my $path = File::Spec->catdir($self->{+ROUTE}, $self->on_disk_name($peer_id));
    return $path if $self->check_path($path);
    return undef;
}

sub spawn {
    my $class = shift;
    my (%params) = @_;

    my $template = delete $params{template} // "PerlIPCManager-$$-XXXXXX";
    my $dir      = tempdir($template, TMPDIR => 1, CLEANUP => 0, %params);

    return "$dir";
}

sub unspawn {
    my $class = shift;
    my ($route) = @_;
    remove_tree($route, {keep_root => 0, safe => 1});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Base::FS - Base class for filesystem based protocols

=head1 DESCRIPTION

This is the base class for filesystem based message stores and protocols.

=head1 METHODS

See L<IPC::Manager::Client> for inherited methods

=head2 FS SPECIFIC

=over 4

=item $bool = $con->check_path($path)

Check if a path is a valid client path, what that means is protocol specific.

=item $con->clear_pid

Remove the pid from the pidfile, marking the client inactive.

=item $bool = $con->have_resume_file

Check if we have a resume file. A resume file is where re-queued messages go.

=item $con->make_path($path)

Create the path for the client. What this means is protocol specific.

=item $path = $con->path

Get the proper path for the client.

=item $string = $con->path_type

Returns a human readable name for what types of files/etc the paths should be.

=item $on_disk = $con->on_disk_name($peer_id)

Returns the filesystem component used for C<$peer_id> under the route directory.
For short, safe names the peer id is returned unchanged.  For names that would
exceed L</max_on_disk_name_length>, contain path-unsafe characters, or begin with
the reserved C<h-> prefix, returns C<< "h-" . substr(sha256_hex($peer_id), 0, 40) >>.
The mapping from hashed on-disk name back to the real peer id is recorded in a
C<.name> sidecar file so that L</peers> and L</all_stats> report real peer names.
This lets callers use arbitrarily long peer ids transparently.

=item $n = $con->max_on_disk_name_length

Returns the maximum length of an on-disk peer name component before it is hashed.
Defaults to 200, which is safe on common filesystems.  Subclasses may override
this.  In particular L<IPC::Manager::Client::UnixSocket> computes it dynamically
from the route length to stay within the C<sun_path> limit.

=item $file = $con->name_file($peer_id)

Returns the path to the C<.name> sidecar file for C<$peer_id>.  Defaults to
C<$self-E<gt>{+ID}> when C<$peer_id> is not given.

=item $file = $con->peer_pid_file($peer_name)

Get the path to the pidfile for the peer of the given name.

=item $file = $con->pidfile

Get the pidfile for the connection.

=item @messages = $con->read_resume_file

Get any messages from the resume file, then delete the file.

=item $file = $con->resume_file

Get the resume file for the connection.

=item $file = $con->stats_file

Get the stats file for the connection.

=item $con->write_pid

Write the pidfile for the connection.

=item $bool = $con->can_select

Returns true if C<IO::Select> is available and this client can use it for
non-blocking message detection.

=item $select = $con->select

Returns a cached L<IO::Select> object populated with the client's
C<handles_for_select>.  Creates the object on first call.  Returns undef if
C<can_select> is false or there are no handles to monitor.

=item $bool = $con->have_handles_for_peer_change

Returns true if L<Linux::Inotify2> is available and can be used to watch the
route directory for new peer connections.

=item $con->reset_handles_for_peer_change

Drains pending inotify events after a peer-change notification so that the
handle does not remain spuriously readable.

=item @handles = $con->handles_for_peer_change

Returns the inotify filehandle watching the route directory for peer arrivals
and departures.  Dies unless L<Linux::Inotify2> is available.

=back

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
