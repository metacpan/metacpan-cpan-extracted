package Mail::POP3::Folder::mbox::parse_to_disk;

use strict;
use IO::File;
use Fcntl ':flock';

use vars qw(@ISA);
@ISA = qw(Mail::POP3::Folder::mbox);

my $CRLF = "\015\012";

sub new {
    my (
        $class,
        $user_name,
        $password,
        $user_id,
        $mailgroup,
        $spoolfile,
        $message_start,
        $message_end,
        $tmpdir,
        $debug,
    ) = @_;
    my $self = $class->SUPER::new(
        $user_name,
        $password,
        $user_id,
        $mailgroup,
        $spoolfile,
        $message_start,
        $message_end,
    );
    $self->{TMPDIR} = $tmpdir;
    $self->{DEBUG} = $debug;
    $self;
}

sub _start_new_message {
    my ($self, $newmessageno, $fromline) = @_;
    $self->SUPER::_start_new_message($newmessageno, $fromline);
    $> = 0;
    unless (-d $self->{TMPDIR}) {
        mkdir $self->{TMPDIR}, 0700
            or die "Couldn't create spool dir '$self->{TMPDIR}': $!\n";
    }
    my $file = $self->_tmpdir_lockfile;
    $self->{TMPDIRLOCK} = IO::File->new(">$file");
    unless (flock $self->{TMPDIRLOCK}, LOCK_EX|LOCK_NB) {
        die "Could not flock $file\n";
    }
    $file = $self->_msg2filename($newmessageno);
    $self->{MESSAGE_FH} = IO::File->new(">$file")
        or die "Couldn't create spool file: $!\n";
    chmod 0600, $file;
    $> = $self->{CLIENT_USER_ID};
}

sub _close_old_message {
    my ($self, $oldmessageno, $messageuidl, $messageoctets) = @_;
    return if $oldmessageno <= 0;
    $self->SUPER::_close_old_message(
        $oldmessageno, $messageuidl, $messageoctets
    );
    $> = 0;
    close $self->{MESSAGE_FH} if $self->{MESSAGE_FH};
    $> = $self->{CLIENT_USER_ID};
}

sub lock_release {
    my $self = shift;
    close $self->{TMPDIRLOCK};
    unlink $self->_tmpdir_lockfile;
    $self->SUPER::lock_release;
}

# Build message arrays or write the next line to disk
sub _push_message {
    my ($self, $messagecnt, $data) = @_;
    $> = 0;
    $self->{MESSAGE_FH}->print("$data\n");
    $> = $self->{CLIENT_USER_ID};
}

sub _tmpdir_lockfile {
    my ($self, $message) = @_;
    "$self->{TMPDIR}/.mpopd.lock";
}

sub _msg2filename {
    my ($self, $message) = @_;
    "$self->{TMPDIR}/$message";
}

# $message starts at 1
# returns number of bytes
sub top {
    my ($self, $message, $output_fh, $body_lines) = @_;
    my $top_bytes = 0;
    $> = 0;
    local *MSG;
    open MSG, $self->_msg2filename($message);
    # print the headers
    while (<MSG>) {
        chomp;
        $self->_lock_update;
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
        last if /^\s*$/;
    }
    my $cnt = 0;
    # print the TOP arg number of body lines
    while (<MSG>) {
        chomp;
        last if ++$cnt > $body_lines;
        # byte-stuff lines starting with .
        s/^\./\.\./o;
        $self->_lock_update;
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
    }
    close MSG;
    $> = $self->{CLIENT_USER_ID};
    $top_bytes;
}

sub flush_delete {
    my ($self) = @_;
    $self->SUPER::flush_delete;
    if (not $self->{DEBUG}) {
        foreach my $cnt (1..$self->{MESSAGECNT}) {
            unlink $self->_msg2filename($cnt);
        }
    }
}

sub retrieve {
    my ($self, $message, $output_fh, $mbox_destined) = @_;
    $> = 0;
    local *MSG;
    open MSG, $self->_msg2filename($message);
    while (<MSG>) {
        chomp;
        s/^\./\.\./o unless $mbox_destined;
        $self->_lock_update;
        my $line = $mbox_destined ? "$_\n" : "$_$CRLF";
        $output_fh->print($line);
    }
    close MSG;
    $> = $self->{CLIENT_USER_ID};
}

1;

__END__

=head1 NAME

Mail::POP3::Folder::mbox::parse_to_disk - class that handles an mbox-format mailbox for POP3, storing messages on disk and not in memory

=head1 SYNOPSIS

    my $mailbox = Mail::POP3::Folder::mbox::parse_to_disk->new(
        $user_id,
        $mbox_path,
        '^From ',
        '^\\s*$',
        $tmpdir,
    );
    die "Could not acquire lock\n" unless $mailbox->lock_acquire;
    $mailbox->uidl_list(\*STDOUT);
    print $mailbox->uidl(2), "\n";
    $mailbox->delete(2);
    $mailbox->top(3, \*STDOUT, 2);
    $mailbox->retrieve(3, \*STDOUT);
    print $mailbox->octets(1), "\n";
    $mailbox->flush_delete;
    $mailbox->lock_release;

=head1 DESCRIPTION

This class manages an mbox-format mailbox in accordance with the
requirements of a POP3 server. It stores the messages therein as
individual temporary files rather than in memory. It is otherwise entirely
compatible with L<Mail::POP3::Folder::mbox>.

The C<new> method takes one extra parameter, C<$tmpdir>, which is the
location of the temporary files into which the messages are placed.

=head1 SEE ALSO

RFC 1939, L<Mail::POP3>.
