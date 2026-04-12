package IPC::Manager::Client::MessageFiles;
use strict;
use warnings;

our $VERSION = '0.000018';

use Carp qw/croak confess/;
use File::Spec;

use IPC::Manager::Util qw/USE_INOTIFY/;

use parent 'IPC::Manager::Base::FS';
use Object::HashBase qw{
    +dir_handle
    +inotify

    +pend_count
    +ready_count
};

sub _viable { 1 }

sub check_path { -d $_[1] }
sub make_path  { mkdir($_[1]) or die "Could not make dir '$_[1]': $!" }
sub path_type  { 'subdir' }

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+PEND_COUNT}  = 0;
    $self->{+READY_COUNT} = 0;

    # Prime the message-directory inotify watch now that the path exists,
    # so events are captured from the start.  Skip on reconnect so the
    # first message_files() call does a full directory scan and picks up
    # any messages written while the client was suspended.
    $self->inotify if USE_INOTIFY && !$self->{+RECONNECT};
}

sub have_handles_for_select { USE_INOTIFY() }
sub handles_for_select { USE_INOTIFY() ? $_[0]->inotify->fh : () }

sub inotify {
    my $self = shift;
    croak "Not Implemented (Or you are missing Linux::Inotify2)" unless USE_INOTIFY();

    return $self->{+INOTIFY} if $self->{+INOTIFY};

    my $i = Linux::Inotify2->new;
    $i->blocking(0);
    $i->watch($self->path, Linux::Inotify2::IN_CREATE() | Linux::Inotify2::IN_MOVED_TO());

    return $self->{+INOTIFY} = $i;
}

sub pre_disconnect_hook {
    my $self = shift;

    my $new_path = File::Spec->catfile($self->{+ROUTE}, "_" . $self->{+ID});
    rename($self->path, $new_path) or die "Cannot rename directory: $!";
    $self->{+PATH} = $new_path;
}

sub dir_handle {
    my $self = shift;
    $self->pid_check;
    my $out = $self->{+DIR_HANDLE} //= do {
        opendir(my $dh, $self->path) or die "Could not open dir: $!";
        $dh;
    };

    rewinddir($out);

    return $out;
}

sub pending_messages {
    my $self = shift;
    return 1 if $self->{+PEND_COUNT};
    return $self->message_files('pend') ? 1 : 0;
}

sub ready_messages {
    my $self = shift;
    return 1 if $self->{+READY_COUNT};
    return 1 if $self->have_resume_file;
    return $self->message_files('ready') ? 1 : 0;
}

sub message_files {
    my $self = shift;
    $self->pid_check;
    my ($ext) = @_;

    if (USE_INOTIFY && !$self->{+READY_COUNT} && !$self->{+PEND_COUNT}) {
        my $check_for_pre_inotify = $self->{+INOTIFY} ? 0 : 1;

        if ($self->select->can_read(0)) {
            # Reset the status
            $self->inotify->read;
        }
        else {
            return undef unless $check_for_pre_inotify;
        }
    }

    my (@pend, @ready);
    for my $file (readdir($self->dir_handle)) {
        if ($file =~ m/\.ready$/) {
            push @ready => $file;
        }
        elsif ($file =~ m/\.pend$/) {
            push @pend => $file;
        }
    }

    $self->{+READY_COUNT} = @ready;
    $self->{+PEND_COUNT}  = @pend;

    return @ready ? \@ready : undef if $ext eq 'ready';
    return @pend  ? \@pend  : undef if $ext eq 'pend';

    return undef;
}

sub get_messages {
    my $self = shift;
    my ($ext) = @_;

    my @out;

    my $ready = $self->message_files('ready') or return;

    for my $msg (@$ready) {
        my $full = File::Spec->catfile($self->path, $msg);
        open(my $fh, '<', $full) or die "Could not open file '$full': $!";
        my $content = do { local $/; <$fh> };
        close($fh);
        unlink($full) or die "Could not unlink file '$full': $!";

        my $msg = IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($content));
        push @out => $msg;

        $self->{+STATS}->{read}->{$msg->{from}}++;
    }

    push @out => $self->read_resume_file;

    return $self->sort_messages(@out);
}

sub _write_message_file {
    my $self = shift;
    my ($msg, $peer) = @_;

    $peer //= $msg->to or croak "Message has no peer";

    my $msg_dir  = $self->peer_exists($peer) or croak "Client does not exist";
    my $msg_file = File::Spec->catfile($msg_dir, $msg->id);

    my $pend  = "$msg_file.pend";
    my $ready = "$msg_file.ready";

    confess "Message file '$msg_file' already exists" if -e $pend || -e $ready;

    open(my $fh, '>', $pend) or die "Could not open '$pend': $!";

    print $fh $self->{+SERIALIZER}->serialize($msg);

    close($fh);

    rename($pend, $ready) or die "Could not rename file: $!";

    $self->{+STATS}->{sent}->{$msg->{to}}++;
    return $ready;
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);
    $self->pid_check;
    $self->_write_message_file($msg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::MessageFiles - Use files on disk as a message store.

=head1 DESCRIPTION

The message store is a directory. Each client has a subdirectory. Each message
is a file added to the client subdirectories.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'MessageFiles');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2, $spawn->info);

    $con1->send_message(con1 => {'hello' => 'con2'});

    my @messages = $con2->get_messages;

=head1 METHODS

See L<IPC::Manager::Client> and L<IPC::Manager::Base::FS> for inherited methods.

=over 4

=item $inotify = $con->inotify

Returns the L<Linux::Inotify2> instance watching the client's message
directory for newly created message files.  Created on first call.  Dies
unless L<Linux::Inotify2> is available.

=item $arrayref_or_undef = $con->message_files($ext)

Scans the client's message directory and returns an arrayref of filenames
matching C<.ready> (when C<$ext> is C<'ready'>) or C<.pend> (when C<$ext>
is C<'pend'>), or undef if there are none.  As a side-effect, updates the
internal C<pend_count> and C<ready_count> caches.

=item $dirhandle = $con->dir_handle

Returns a cached, rewound directory handle for the client's message
directory.  Opens the directory on first call.

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
