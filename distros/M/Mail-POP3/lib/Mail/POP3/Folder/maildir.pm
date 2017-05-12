package Mail::POP3::Folder::maildir;

use strict;
use Fcntl ':flock';

my $CRLF = "\015\012";

sub new {
    my ($class, $user_name, $password, $user_id, $maildir) = @_;
    my $self = {};
    bless $self, $class;
    $self->{CLIENT_USER_ID} = $user_id;
    $self->{MAILDIR} = $maildir;
    $self->{MESSAGECNT} = 0;
    $self->{MSG2OCTETS} = {};
    $self->{MSG2UIDL} = {};
    $self->{TOTALOCTETS} = 0;
    $self->{DELETE} = {};
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
    $self;
}

# class method
sub find_maildir {
    my ($class, $user_name) = @_;
    my $maildir;
    my $home = (getpwnam $user_name)[7];
    local *QMAIL;
    if (open QMAIL, "$home/.qmail") {
        $maildir = <QMAIL>;
        close QMAIL;
        chomp $maildir;
        $maildir =~ s#/$##;
        $maildir =~ s#^\.##;
        $maildir =~ s#^/##;
        $maildir = "$home/$maildir";
    } else {
        $maildir = "$home/Maildir";
    }
    $maildir;
}

sub uidl_list {
    my ($self, $output_fh) = @_;
    for (1..$self->{MESSAGECNT}) {
        $self->lock_refresh;
        if (!$self->is_deleted($_)) {
            $output_fh->print("$_ $self->{MSG2UIDL}->{$_}$CRLF");
        }
    }
    $output_fh->print(".$CRLF");
}

# find relevant info about available messages
sub _list_messages {
    my $self = shift;
    local *MAILDIR;
    opendir MAILDIR, "$self->{MAILDIR}/new";
    $self->{MAILDIR_FILES} = [ sort grep !/^\./, readdir MAILDIR ];
    closedir MAILDIR;
    # Get the number and size of messages in a Maildir mailbox
    my $cnt = 0;
    foreach (@{ $self->{MAILDIR_FILES} }) {
        $cnt++;
        # check/create the unique ID code
        my $file = "$self->{MAILDIR}/new/$_";
        my $octets = -s $file;
        $self->{MSG2OCTETS}->{$cnt} = $octets;
        $self->{MSG2UIDL}->{$cnt} = $_;
        $self->{TOTALOCTETS} += $octets;
    }
    $self->{MESSAGECNT} = $cnt;
}

# takes a message-number, which starts from 1
sub _msg2filename {
    my ($self, $msg) = @_;
    "$self->{MAILDIR}/new/$self->{MAILDIR_FILES}->[$msg - 1]";
}

# Slightly paranoid mailbox locking...
sub lock_acquire {
    my $self = shift;
    if (-f "$self->{MAILDIR}/new/.mpopd.lock") {
        die "Maildir/new lockfile already exists... :|(";
    }
    local *MAILDIRLOCK;
    open MAILDIRLOCK, ">$self->{MAILDIR}/new/.mpopd.lock";
    unless (flock MAILDIRLOCK, LOCK_EX|LOCK_NB) {
        unlink "$self->{MAILDIR}/new/.mpopd.lock";
        return 0;
    }
    $self->{LOCK_FH} = \*MAILDIRLOCK;
    $self->_list_messages;
}

sub is_valid {
    my ($self, $msg) = @_;
    $self->lock_refresh;
    $msg > 0 and $msg <= $self->{MESSAGECNT} and !$self->is_deleted($msg);
}

sub lock_release {
    my $self = shift;
    eval { $self->{LOCK_FH}->close; };
    unlink "$self->{MAILDIR}/new/.mpopd.lock";
}

# $message starts at 1
sub retrieve {
    my ($self, $message, $output_fh, $mbox_destined) = @_;
    # $self->{MAILDIR} is the full /path/file and starts at 0 !
    local *MSG;
    open MSG, "$self->{MAILDIR}/new/$self->{MAILDIR_FILES}->[$message - 1]";
    while (<MSG>) {
        chomp;
        # byte-stuff lines starting with .
        s/^\./\.\./o unless $mbox_destined;
        my $line = $mbox_destined ? "$_\n" : "$_$CRLF";
        $output_fh->print($line);
        $self->lock_update;
    }
    close MSG;
}

# $message starts at 1
# returns number of bytes
sub top {
    my ($self, $message, $output_fh, $body_lines) = @_;
    my $top_bytes = 0;
    local *MSG;
    open MSG, $self->_msg2filename($message);
    # print the headers
    while (<MSG>) {
        chomp;
        $self->lock_update;
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
        last if /^\s+$/;
    }
    my $cnt = 0;
    # print the TOP arg number of body lines
    while (<MSG>) {
        ++$cnt;
        last if $cnt > $body_lines;
        # byte-stuff lines starting with .
        s/^\./\.\./o;
        $self->lock_update;
        chomp;
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
    }
    close MSG;
    $output_fh->print(".$CRLF");
    $top_bytes;
}

sub is_deleted {
    my ($self, $message) = @_;
    return $self->{DELETE}->{$message};
}

sub delete {
    my ($self, $message) = @_;
    $self->lock_refresh;
    $self->{DELETE}->{$message} = 1;
    $self->{DELMESSAGECNT} += 1;
    $self->{DELTOTALOCTETS} += $self->{OCTETS}->{$message};
}

sub flush_delete {
    my $self = shift;
    for (1..$self->{MESSAGECNT}) {
        if ($self->{MAILBOX}->is_deleted($_)) {
            unlink $self->_msg2filename($_);
        }
    }
}

sub reset {
    my $self = shift;
    $self->lock_refresh;
    $self->{DELETE} = {};
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
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

sub uidl {
    my ($self, $message) = @_;
    $self->{MSG2UIDL}->{$message};
}

1;

__END__

=head1 NAME

Mail::POP3::Folder::maildir - class that handles an maildir-format
mailbox for POP3

=head1 DESCRIPTION

This class manages an maildir-format mailbox in accordance with the
requirements of a POP3 server. It is entirely API-compatible with
L<Mail::POP3::Folder::mbox>.

=head1 METHODS

=head2 $class->find_maildir($user_name)

The one extra class method implemented here, it is to assist in finding
the $maildir parameter to C<new>.

=head1 SEE ALSO

RFC 1939, L<Mail::POP3::Folder::mbox>.
