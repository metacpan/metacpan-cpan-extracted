package IPC::Manager::Base::FS;
use strict;
use warnings;

our $VERSION = '0.000001';

use File::Spec;

use Carp qw/croak/;
use File::Temp qw/tempdir/;
use File::Path qw/remove_tree/;

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +path
    +pidfile
    +resume_file
};

sub pending_messages { 0 }

sub ready_messages { croak "Not Implemented" }
sub get_messages   { croak "Not Implemented" }
sub send_message   { croak "Not Implemented" }
sub check_path     { croak "Not Implemented" }
sub make_path      { croak "Not Implemented" }
sub path_type      { croak "Not Implemented" }

sub have_resume_file { -e $_[0]->resume_file }

sub all_stats {
    my $self = shift;

    my $out = {};

    opendir(my $dh, $self->{+ROUTE}) or die "Could not open dir: $!";
    for my $file (readdir($dh)) {
        next unless $file =~ m/^(.+)\.stats$/;
        my $peer = $1;
        open(my $fh, '<', File::Spec->catfile($self->{+ROUTE}, $file)) or die "Could not open stats file: $!";
        $out->{$peer} = do { local $/; $self->{+SERIALIZER}->deserialize(<$fh>) };
        close($fh);
    }

    close($dh);

    return $out;
}

sub stats_file {
    my $self = shift;
    return File::Spec->catfile($self->{+ROUTE}, "$self->{+ID}.stats");
}

sub write_stats {
    my $self = shift;

    open(my $fh, '>', $self->stats_file) or die "Could not open stats file: $!";
    print $fh $self->{+SERIALIZER}->serialize($self->{+STATS});
    close($fh);
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
    return $self->{+PATH} //= File::Spec->catfile($self->{+ROUTE}, $self->{+ID});
}

sub resume_file {
    my $self = shift;
    return $self->{+RESUME_FILE} //= File::Spec->catfile($self->{+ROUTE}, $self->{+ID} . ".resume");
}

sub peer_pid_file {
    my $self = shift;
    my ($peer_id) = @_;

    return File::Spec->catfile($self->{+ROUTE}, $peer_id . ".pid");
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
    }

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
    open(my $fh, '>', $pidfile) or die "Could not open pidfile '$pidfile': $!";
    print $fh $self->{+PID};
    close($fh);
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
    remove_tree($self->path, {keep_root => 0, safe => 1});
}

sub pre_suspend_hook {
    my $self = shift;
    $self->clear_pid;
}

sub peers {
    my $self = shift;

    my @out;

    opendir(my $dh, $self->{+ROUTE}) or die "Could not open dir: $!";
    for my $file (readdir($dh)) {
        next if $file eq $self->{+ID};
        next if $file =~ m/^(\.|_)/;
        next if $file =~ m/\.pid$/;
        $self->peer_exists($file) or next;

        push @out => $file;
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

    my $path = File::Spec->catdir($self->{+ROUTE}, $peer_id);
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

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

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
