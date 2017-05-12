package Mail::POP3::Folder::mbox;

use strict;
use IO::File;
use Fcntl ':flock';

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
    ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{CLIENT_USER_ID} = $user_id;
    $self->{MAILGROUP} = $mailgroup;
    $self->{SPOOLFILE} = $spoolfile;
    $self->{MESSAGE_START} = $message_start;
    $self->{MESSAGE_END} = $message_end;
    $self->{MESSAGECNT} = 0;
    $self->{MSG2OCTETS} = {};
    $self->{MSG2UIDL} = {};
    $self->{MSG2FROMLINE} = {};
    $self->{MSG2TEXT} = {};
    $self->{TOTALOCTETS} = 0;
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
    $self;
}

sub _start_new_message {
    my ($self, $newmessageno, $fromline) = @_;
    # Hold the "From ..." line to put back if message is not retrieved
    $self->{MSG2FROMLINE}->{$newmessageno} = $fromline;
}

sub _close_old_message {
    my ($self, $oldmessageno, $messageuidl, $messageoctets) = @_;
    return if $oldmessageno <= 0;
    $self->{TOTALOCTETS} += $messageoctets;
    $self->{MSG2OCTETS}->{$oldmessageno} = $messageoctets;
    $self->{MSG2UIDL}->{$oldmessageno} = $messageuidl;
}

# assume that mbox is good, no error-checking at start
# not sure the message_end is necessary, is that for MMDF?
sub _list_messages {
    my $self = shift;
    if (!-s $self->_spoolfile) {
        # no mail
        return;
    }
    my $seen_message_end = 1; # the end of fake "message 0"...
    my $messagecnt = 0;
    my $messageoctets = 0;
    my $messageuidl = '';
    local *MDROP;
    open MDROP, $self->_spoolfile;
    while (<MDROP>) {
        $self->_lock_update;
        s/\r|\n//g;
        if ($seen_message_end and /$self->{MESSAGE_START}/) {
            # tick over
            $self->_close_old_message(
                $messagecnt,
                $messageuidl,
                $messageoctets,
            );
            $messagecnt++;
            $messageuidl = '';
            $messageoctets = 0;
            $self->_start_new_message($messagecnt, $_);
        } else {
            $seen_message_end = 0;
            if (/$self->{MESSAGE_END}/) {
                $seen_message_end = 1;
            }
            if (/^Message-Id:\s*(.+)/ and not $messageuidl) {
                # only take first Message-ID; cf such a header appearing in body
                $messageuidl = $1;
            }
            $self->_push_message($messagecnt, $_);
            $messageoctets += length ($_.$CRLF);
        }
    }
    # catch the last one
    $self->_close_old_message($messagecnt, $messageuidl, $messageoctets);
    $self->{MESSAGECNT} = $messagecnt;
}

sub _spoolfile {
    my $self = shift;
    $self->{SPOOLFILE};
}

sub lock_acquire {
    my $self = shift;
    my $lockfile = $self->_lock_filename;
    return if -f $lockfile;
    $self->{LINE} = 0;
    $self->{LOCK_FH} = IO::File->new(
        ">$lockfile"
    ) or die "open >$lockfile: $!\n";
    unless (flock $self->{LOCK_FH}, LOCK_EX|LOCK_NB) {
        unlink $lockfile;
        return;
    }
    chmod 0600, $lockfile;
    chown $self->{CLIENT_USER_ID}, $self->{MAILGROUP}, $lockfile;
    my $oldfh = select $self->{LOCK_FH};
    $| = 1;
    select $oldfh;
    $self->_lock_refresh;
    # stat the file to get its size, this is checked before closing
    # the mailbox.
    # If the size has changed the lock may have been compromised, so a
    # backup is then made.
    my @filestat = stat $self->_spoolfile;
    $self->{MAILBOX_TIMESTAMP_OPEN} = $filestat[9];
    # set effective UID to user for the rest of the session;
    $> = $self->{CLIENT_USER_ID};
    $self->_list_messages;
die unless $self->{LOCK_FH};
    1;
}

sub lock_release {
    my $self = shift;
    close $self->{LOCK_FH};
    $> = 0;
    unlink $self->_lock_filename;
    $> = $self->{CLIENT_USER_ID};
}

sub _lock_filename {
    my ($self) = @_;
    "$self->{SPOOLFILE}.lock";
}

sub _lock_refresh {
    # This is to update the m time on the <user>.lock mbox lock file.
    # It may seem paranoid but I have seen lock files removed by impatient
    # MDA's, so the file is written-to, unbuffered, as often as is
    # practicable.
    my $self = shift;
    $> = 0;
die unless $self->{LOCK_FH};
    seek $self->{LOCK_FH}, 0, SEEK_SET;
    $self->{LOCK_FH}->print("\0");
    $> = $self->{CLIENT_USER_ID};
}

sub _lock_update {
    my $self = shift;
    if (++$self->{LINE} == 1000) {
        $self->_lock_refresh;
        $self->{LINE} = 0;
    }
}

sub _push_message_line {
    my ($self, $messagecnt, $data) = @_;
    push @{ $self->{MSG2TEXT}->{$messagecnt} }, "$data$CRLF";
}

sub _set_message_line {
    my ($self, $messagecnt, $lineno, $data) = @_;
    $self->{MSG2TEXT}->{$messagecnt}->[$lineno] = $data;
}

sub _get_message_line {
    my ($self, $messagecnt, $lineno) = @_;
    $self->{MSG2TEXT}->{$messagecnt}->[$lineno];
}

sub _unshift_message_line {
    my ($self, $messagecnt, $data) = @_;
    unshift @{ $self->{MSG2TEXT}->{$messagecnt} }, "$data$CRLF";
}

sub _list_message_line {
    my ($self, $messagecnt) = @_;
    @{ $self->{MSG2TEXT}->{$messagecnt} };
}

sub octets {
    my ($self, $message) = @_;
    if (defined $message) {
        $self->{MSG2OCTETS}->{$message};
    } else {
        $self->{TOTALOCTETS} - $self->{DELTOTALOCTETS};
    }
}

sub messages {
    my ($self) = @_;
    $self->{MESSAGECNT} - $self->{DELMESSAGECNT};
}

# Build message arrays or write the next line to disk
sub _push_message {
    my ($self, $messagecnt, $data) = @_;
    $self->_push_message_line($messagecnt, $data);
}

# $message starts at 1
# returns number of bytes
sub top {
    my ($self, $message, $output_fh, $body_lines) = @_;
    my $top_bytes = 0;
    my $rows = (scalar $self->_list_message_line($message)) -1;
    $body_lines = $rows if $body_lines > $rows;
    my $cnt = 0;
    for my $line ($self->_list_message_line($message)) {
        $top_bytes += length($line);
        ++$cnt;
        $self->_lock_update;
        $output_fh->print($line);
        last if $line =~ /^\s*$/;
    }
    for my $lineno ($cnt..(($cnt + $body_lines) -1)) {
        $self->_lock_update;
        my $line = $self->_get_message_line($message, $lineno);
        $top_bytes += length($line);
        $line =~ s/^\./\.\./o;
        $output_fh->print($line);
    }
    $top_bytes;
}

sub flush_delete {
    my ($self) = @_;
    my $spool_mtime = (stat $self->_spoolfile)[9];
    if ($spool_mtime != $self->{MAILBOX_TIMESTAMP_OPEN}) {
        die "spool lock error\n";
    }
    my $spoolfile = $self->_spoolfile;
    open MDROP, '>' . $spoolfile or die "open >$spoolfile: $!\n";
    foreach my $cnt (1..$self->{MESSAGECNT}) {
        if (!$self->is_deleted($cnt)) {
            print MDROP "$self->{MSG2FROMLINE}->{$cnt}\n";
            $self->retrieve($cnt, \*MDROP, 1);
        }
    }
    close MDROP;
}

sub retrieve {
    my ($self, $message, $output_fh, $mbox_destined) = @_;
    for my $line ($self->_list_message_line($message)) {
        $line =~ s/^\./\.\./o unless $mbox_destined;
        $line =~ s/\r$// if $mbox_destined;
        $self->_lock_update;
        $output_fh->print($line);
    }
}

sub uidl {
    my ($self, $message) = @_;
    $self->{MSG2UIDL}->{$message};
}

sub uidl_list {
    my ($self, $output_fh) = @_;
    for (1..$self->{MESSAGECNT}) {
        $self->_lock_refresh;
        if (!$self->is_deleted($_)) {
            $output_fh->print("$_ $self->{MSG2UIDL}->{$_}$CRLF");
        }
    }
    $output_fh->print(".$CRLF");
}

sub is_deleted {
    my ($self, $message) = @_;
    $self->{DELETE}->{$message};
}

sub delete {
    my ($self, $message) = @_;
    $self->_lock_refresh;
    $self->{DELETE}->{$message} = 1;
    $self->{DELMESSAGECNT} += 1;
    $self->{DELTOTALOCTETS} += $self->{MSG2OCTETS}->{$message};
}

sub is_valid {
    my ($self, $msg) = @_;
    $self->_lock_refresh;
    $msg > 0 and $msg <= $self->{MESSAGECNT} and !$self->is_deleted($msg);
}

sub reset {
    my $self = shift;
    $self->_lock_refresh;
    $self->{DELETE} = {};
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
}

1;

__END__

=head1 NAME

Mail::POP3::Folder::mbox - class that handles an mbox-format mailbox for POP3

=head1 SYNOPSIS

    my $mailbox = Mail::POP3::Folder::mbox->new(
        $user_id,
        $mbox_path,
        '^From ',
        '^\\s*$',
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
requirements of a POP3 server.

=head1 METHODS

=head2 $class->new($user_id, $mbox_path, $message_start, $message_end)

Returns an object.

=head2 $mailbox->lock_acquire

Acquires a lock on the mailbox.

=head2 $mailbox->lock_release

Releases the lock on the mailbox.

=head2 $mailbox->octets

Returns the number of octets in all non-deleted messages.

=head2 $mailbox->messages

Returns the number of non-deleted messages.

=head2 $mailbox->flush_delete

Actually deletes all messages marked as deleted. Throws an exception if
the spool-file was modified since the lock was acquired.

=head2 $mailbox->reset

=head2 $mailbox->top($message, $output_fh, $body_lines)

Prints the header and top $body_lines lines of the given message to the
given file-handle. It does not produce a final C<".$CRLF">.

=head2 $mailbox->retrieve($message, $output_fh, $mbox_destined)

Prints the given message to the given file-handle. It does not produce a
final C<".$CRLF">. If C<$mbox_destined> is true, then ends each line with
LF, not CRLF, and do not byte-stuff the C<.> character.

=head2 $mailbox->uidl_list($output_fh)

Prints a list of all message numbers and their UIDLs to the given
file-handle. It does produce a final C<".$CRLF">.

=head2 $mailbox->uidl($message)

Returns the persistent unique ID for the given message.

=head2 $mailbox->is_deleted($message)

Returns true if the given message has been marked as deleted.

=head2 $mailbox->is_valid($message)

Returns true if the given message has NOT been marked as deleted and is
within the range of messages in the mailbox.

=head2 $mailbox->delete($message)

Marks the given message as deleted.

=head1 SEE ALSO

RFC 1939, L<Mail::POP3>.
