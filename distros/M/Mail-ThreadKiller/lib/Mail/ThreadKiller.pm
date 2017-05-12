package Mail::ThreadKiller;
use strict;
use warnings;

use DB_File;
use Fcntl ':flock';
use Carp;

our $VERSION = '1.0.1';

sub new
{
	my ($class) = @_;
	return bless {
		db_file => undef,
		lock_fd => undef,
		lockfile => undef,
		lock_fd => undef,
		tied => undef,
	}, $class;
}

sub set_db_file
{
	my ($self, $filename) = @_;
	$self->{db_file} = $filename;
}

sub open_db_file
{
	my ($self, $filename) = @_;
	if (defined($filename)) {
		$self->{db_file} = $filename;
	}

	croak("DB file not set") unless defined($self->{db_file});
	my $lockfile = $self->{db_file} . '.lock';
	my $fp;
	open($fp, ">>$lockfile") or croak("Cannot open $lockfile: $!");
	flock($fp, LOCK_EX) or croak("Cannot lock $lockfile: $!");
	$self->{lock_fd} = $fp;
	$self->{lockfile} = $lockfile;
	if (!tie(%{$self->{tied}}, 'DB_File', $self->{db_file})) {
		croak("Cannot tie to " . $self->{db_file} . ": $!");
	}
	return 1;
}

sub close_db_file
{
	my ($self) = @_;
	if (defined($self->{tied})) {
		untie(%{$self->{tied}});
		$self->{tied} = undef;
	}
	if (defined($self->{lock_fd})) {
		close($self->{lock_fd});
		$self->{lock_fd} = undef;
	}
	if (defined($self->{lockfile})) {
		unlink($self->{lockfile});
		$self->{lockfile} = undef;
	}
}

sub DESTROY
{
	my ($self) = @_;
	$self->close_db_file();
}

# Add a message-ID to the database
sub add_message_id {
	my ($self, $msgid) = @_;
	my $now = time();

	$self->{tied}->{$msgid} = $now;
	return $now;
}

# Are any IDs in the database?
sub any_ids_in_database {
	my ($self, $msgid_line, $in_reply_to_line, $references_line) = @_;
	if (defined($msgid_line) && ($msgid_line =~ /(<\S+>)/)) {
		return $self->{tied}->{$1} if (exists($self->{tied}->{$1}));
	}
	if (defined($in_reply_to_line) && ($in_reply_to_line =~ /(<\S+>)/)) {
		return $self->{tied}->{$1} if (exists($self->{tied}->{$1}));
	}
	if (defined($references_line)) {
		my @ids = split(/\s+/, $references_line);
		foreach my $id (@ids) {
			return $self->{tied}->{$id} if (exists($self->{tied}->{$id}));
		}
	}
	return 0;
}

# Convenience function
sub kill_message
{
	my ($self, $mail) = @_;
	my $mid = $mail->header('Message-ID');
	return 0 unless defined($mid);
	return $self->add_message_id($mid);
}

# Convenience function
sub should_kill_message {
	my ($self, $mail) = @_;
	# NOTE: We need to force scalar context, hence the crazy || '' code.
	if ($self->any_ids_in_database(($mail->header('Message-ID') || ''),
				       ($mail->header('In-Reply-To') || ''),
				       ($mail->header('References') || ''))) {
		$self->add_message_id($mail->header('Message-ID'));
		return 1;
	}
	return 0;
}

# Clean out anything in DB older than $days
sub clean_db {
	my ($self, $days) = @_;
	my ($k, $v);
	my (@toKill);
	my ($secs) = $days * 86400;
	my ($now) = time();
	while (($k, $v) = each(%{$self->{tied}})) {
		push @toKill, $k if (($now - $v) > $secs);
	}
	my $num_cleaned = 0;
	foreach $k (@toKill) {
		$num_cleaned++;
		delete $self->{tied}->{$k};
	}
	return $num_cleaned;
}

1;

__END__

=head1 NAME

Mail::ThreadKiller - get rid of an entire email thread

=head1 SYNOPSIS

    use Mail::ThreadKiller;

    my $tk = Mail::ThreadKiller->new();
    $tk->open_db_file('/path/to/berkeley_db');

    # $mail is assumed to be an Email::Simple object
    if (whatever_criteria_you_like_to_kill_thread($mail)) {
            $tk->kill_message($mail);
            # And do whatever's needed in your filter to discard mail
    }

    # Check if this is a followup to a killed thread
    if ($tk->should_kill_message($mail)) {
            # Do whatever's needed in your filter to discard mail
    }

    # Prune the datase - delete message-IDs not seen in 30 days
    $tk->clean_db(30);

    # Close the DB.  This called automatically if $tk goes out of scope
    $tk->close_db_file();

=head1 DESCRIPTION

This module is meant to be used within an email filter such as
Email::Filter; specifically, it should be used in a filter that
is run by a delivery agent so it runs as the particular user whose mail
is being filtered---it is not suitable as a milter or any other type
of central filter.

Mail::ThreadKiller helps you discard or otherwise redirect entire
message threads.  The basic idea is as follows:

=over

=item *

You use whatever criteria you like to detect the I<beginning> of an
email thread you'd like to kill.  Such criteria could include
the subject, the sender, the recipient list, etc.  For example,
a very common desire is to stop seeing all mail from a troublesome
mailing list poster as well as any replies to a thread started
by that poster.  In this case, your initial criterion could
be the troublesome poster's email address in the From: header.

=item *

Once you've detected the beginning of a thread, you I<kill> the
message.  You use Mail::ThreadKiller to add the Message-ID to a
Berkeley database of IDs; we call this database the I<persistent
database of killed threads> or the I<kill database> for short.  Then
you configure your filter to dispose of the message however you like.

=item *

For all other messages, you ask Mail::ThreadKiller if any Message-IDs
in the C<Message-ID:>, C<In-Reply-To:> or C<References:> headers is in
the kill database.  If so, Mail::ThreadKiller adds the current
Message-ID to the database and returns true; you then dispose of the
message according to your policy.  If the message does not refer to
anything in the database, then Mail::ThreadKiller does nothing and
your filter continues processing normally.

=item *

Periodically, you run the script C<threadkiller-clean-db.pl>
to remove very old Message-IDs from the kill database.

=back

=head1 METHODS

=head2 Mail::ThreadKiller->new()

Create a new Mail::ThreadKiller object

=head2 open_db_file('/path/to/berkeley_db')

Opens the kill database.  This method must be called before any other
methods.  Note that you should minimize the code between opening the
DB file and closing it because Mail::ThreadKiller obtains an exclusive
lock on the file for the duration.

=head2 kill_message ( $mail )

$mail is an instance of Email::Simple.  This method simply adds the
Message-Id: field to the kill database.  It returns 0 if the
Message-ID is not defined; otherwise non-zero.

=head2 add_message_id ( $msgid )

Add the message-ID $msgid to the database of killed threads.  This is a
low-level internal function used by kill_message, but which may occasionally
be useful for external callers.

=head2 should_kill_message ( $mail )

$mail is an instance of Email::Simple.  It returns non-zero if any of
the Message-Ids found in the Message-Id:, In-Reply-To: or References:
headers is found in the kill database.  Additionally, it adds the
Message-Id: of $mail to the kill database.

If none of the Message-Ids was found, returns zero.

=head2 clean_db ( $days )

Removes all Message-Ids from the kill database that are older than
$days days.  Returns the number of entries removed.

=head2 close_db_file ( )

Closes the database file.  The only method that can be called once
this method has been called is open_db_file.

=head1 AUTHOR

Dianne Skoll <dfs@roaringpenguin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Roaring Penguin Software Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

threadkiller-clean-db.pl, threadkiller-kill-msgids.pl
