package IPC::Manager::Client::MessageFiles;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak confess/;
use File::Spec;

use parent 'IPC::Manager::Base::FS';
use Object::HashBase qw{
    +dir_handle
};

sub check_path { -d $_[1] }
sub make_path  { mkdir($_[1]) or die "Could not make dir '$_[1]': $!" }
sub path_type  { 'subdir' }

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
    return $self->message_files('pend') ? 1 : 0;
}

sub ready_messages {
    my $self = shift;
    return 1 if $self->have_resume_file;
    return $self->message_files('ready') ? 1 : 0;
}

sub message_files {
    my $self = shift;
    $self->pid_check;
    my ($ext) = @_;
    my @out = grep { m/\.\Q$ext\E$/ } readdir($self->dir_handle);
    return @out ? [@out] : undef;
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
        close($full);
        unlink($full) or die "Could not unlink file '$full': $!";

        my $msg = IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($content));
        push @out => $msg;

        $self->{+STATS}->{read}->{$msg->{from}}++;
    }

    push @out => $self->read_resume_file;

    return sort { $a->stamp <=> $b->stamp } @out;
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

See L<IPC::Manager::Client>.

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
