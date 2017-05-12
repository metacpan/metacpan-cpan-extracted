#!/usr/bin/perl -w
#
#   Mail::Queue::DB - cache outgoing mail locally to a Berkley DB
#
#   Copyright (C) 2004  S. Zachariah Sprackett <zacs@cpan.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package Mail::Queue::DB;

require 5.004;

use vars qw($VERSION $DBVERSION @EXPORT_OK);

$VERSION = '0.03';
$DBVERSION = '0.01';
@EXPORT_OK = qw();
use constant DEBUG => 1;

use strict;
use DB_File::Lock;
use Fcntl qw(:flock O_RDWR O_CREAT O_RDONLY);
use Carp qw(croak carp);

=head1 NAME

Mail::Queue::DB - store outgoing email locally in a Berkely DB

=head1 SYNOPSIS

  use Mail::Queue::DB;
  my $d = new Mail::Queue:DB( db_file => '.database');

  print $d->count_queue() . " messages in the queue.\n";
  my $msg_id = $d->queue_mail($args, $msg);

  $z->dequeue_mail($msg_id);
  print $d->count_queue() . " messages in the queue.\n";

=head1 DESCRIPTION

Mail::Queue::DB allows one to create a local outgoing email store in
Berkely DB format.  This mail can then be flushed over SSH or some other
connection to an appropriate mailhost.  This module and the associated
tools work well on systems like laptops that need to be able to send
mail while offline.  It was designed to be complementary to OfflineIMAP.

=head1 METHODS
 
=head2 new(db_file => $file)

Creates a new Mail::Queue::DB object.  The argument db_file must be defined.

=cut
sub new {
	my $class = shift;

	my $self = bless {
		@_,
	}, $class;

	croak "db_file is not defined" unless $self->{db_file};

	return $self;
}

=head2 queue_mail($args, $msg)

Adds a new message to the queue.  Args must contain the arguments required
to pass to sendmail to actually send the email.  Typically, these arguments
will be something like: -oem -oi -- user@example.com

Msg contains the actual email message to be transmitted.

On success, the message id of the newly queued email will be returned.  On
failure, queue_mail() returns undef

=cut
sub queue_mail {
	my ($self, $mailargs, $msg) = @_;

	croak "Unable to lock database for writing" if (_db_write_lock($self, 1));

	my $id;
	do {
		$id  = _gen_msg_id(8);
	} while (exists $self->{dbh}{'message-' . $id});

	$self->{dbh}{'args-' . $id} = $mailargs;
	$self->{dbh}{'message-' . $id} = $msg;

	# Add this new message to the index
	$self->{dbh}{message_ids} = '' unless(exists $self->{dbh}{message_ids});
	$self->{dbh}{message_ids} .= ',' if (length($self->{dbh}{message_ids}));
	$self->{dbh}{message_ids} .= $id;

	_db_unlock($self);
}

=head2 queue_mail($id, $have_lock)

Deletes a message from the queue.  Id must contain a valid message id.
dequeue_mail() will attempt to attain a write lock on the database unless
the boolean value have_lock is set.

On success, queue_mail() returns 0.  On failure, it returns a negative
value.

=cut
sub dequeue_mail {
	my ($self, $id, $have_lock) = (@_);

	if (!$have_lock) {
		croak "Unable to lock database for writing" if (_db_write_lock($self));
	} elsif ($self->{lock} !~ /^write$/) {
		croak "dequeue_mail() called with \$have_lock set but no write lock.";
	}

	my %msgs;
	foreach my $t (split /,/, $self->{dbh}{message_ids}) {
		$msgs{$t} = 1;
	}
	# if it doesn't exist, return fail
	if(!$msgs{$id}) {
		_db_unlock($self);
		return -1;
	}

	# if it exists purge it
	delete $self->{dbh}{'message-' . $id};
	delete $self->{dbh}{'args-' . $id};
	delete $msgs{$id};

	# rewrite the message index
	$self->{dbh}{message_ids} = join(',', sort keys %msgs);
	if (!$have_lock) {
		_db_unlock($self);
	}
	return 0;
}

=head2 get_mail($id)

Fetches the message identified by Id from the queue.  On success, it returns
an array of Args, Msg.  On failure it returns undef. 

=cut
sub get_mail {
	my ($self, $id) = @_;

	croak "get_mail() requires a message id." unless $id;
	croak "Unable to lock database for reading" if (_db_read_lock($self));

	my %msgs;
	foreach my $t (split /,/, $self->{dbh}{message_ids}) {
		$msgs{$t} = 1;
	}

	return undef unless $msgs{$id};
	return($self->{dbh}{'args-' . $id}, $self->{dbh}{'message-' . $id})
}

=head2 iterate_queue($callback, $locking)

For each message in the queue, run the passed callback function.
Lock state specifies the lock to hold for the entire iteration run.  It can
be one of either read or write.  If not specified, a read lock is assumed.

The passed in callback will receive arguments in the form
callback( $id, $args, $msg )

=cut
sub iterate_queue {
	my ($self, $callback, $locking) = (@_);

	if (!$locking) {
		$locking = 'read';
	}

	if ($locking =~ /^read$/) {
		croak "Unable to lock database for reading" if (_db_read_lock($self));
	} elsif ($locking =~ /^write$/) {
		croak "Unable to lock database for writing" if (_db_write_lock($self));
	} else {
		croak "Lock state must be either read or write.  Invalid state [$locking]";
	}

	foreach my $id (split /,/, $self->{dbh}{message_ids}) {
		&$callback($id, $self->{dbh}{'args-' . $id}, 
			$self->{dbh}{'message-' . $id});
	}

	_db_unlock($self);
}

=head2 count_queue( )

Returns an integer representing the number of emails currently in the 
queue.

=cut
sub count_queue {
	my ($self) = (@_);

	croak "Unable to lock database for reading" if (_db_read_lock($self));

	my $count = 0;
	foreach my $id (split /,/, $self->{dbh}{message_ids}) {
		$count++;
	}

	_db_unlock($self);
	return $count;
}
#
# tie and lock $self->{dbh} for writing
#
# args: $create - boolean.  specifies whether or not to use O_CREAT
sub _db_write_lock {
	my ($self, $create) = (@_);

	my $flags;
	if ($create) {
		$flags = O_CREAT|O_RDWR;
	} else {
		$flags = O_RDWR;
	}

	if ($self->{lock} && length($self->{lock})) {
		croak "Attempt to write_lock database, but it is already locked for " 
			. $self->{lock};
	}

	tie (%{$self->{dbh}}, "DB_File::Lock", $self->{db_file},
		$flags, 0600, $DB_HASH, 'write') || return -1;

	if (
		exists $self->{dbh}{'database_version'} && 
		length($self->{dbh}{'database_version'})
	) {
		croak "Database version mismatch want $DBVERSION got "
			. $self->{dbh}{'database_version'} 
			if ($DBVERSION ne $self->{dbh}{'database_version'});
	} else {
		$self->{dbh}{'database_version'} = $DBVERSION;
	}

	$self->{lock} = 'write';
	return 0;
}

#
# tie and lock $self->{dbh} for reading
#
sub _db_read_lock {
	my ($self) = (@_);

	if ($self->{lock} && length($self->{lock})) {
		croak "Attempt to read_lock database, but it is already locked for " 
			. $self->{lock};
	}

	tie (%{$self->{dbh}}, "DB_File::Lock", $self->{db_file},
		O_RDONLY, 0600, $DB_HASH, 'read') || return -1;

	if (!$self->{dbh}{'database_version'} ||
		$self->{dbh}{'database_version'} ne $DBVERSION) {
			croak "Database version mismatch want $DBVERSION got "
				. ($self->{dbh}{'database_version'} ? 
					$self->{dbh}{'database_version'} : "undefined");
	}

	$self->{lock} = 'read';
	return 0;
}

sub _db_unlock {
	my ($self) = (@_);

	if ($self->{dbh}) {
		untie $self->{dbh};
		delete $self->{dbh};
	}
	if ($self->{lock}) {
		delete $self->{lock};
	}

	return 0;
}

sub _gen_msg_id {
	my $len = shift;
	my $v = "1234567890abcdefghijklmnopqrstuvwxyz";
	my $str;

	$len = 8 unless $len;
	while($len--) {
		$str .= substr($v, rand(length($v)), 1);
	}
	return $str;
}
1;
__END__

=head1 AUTHOR

S. Zachariah Sprackett <zacs@cpan.org>

=head1 COPYRIGHT

(C) Copyright 2004, S. Zachariah Sprackett <zacs@cpan.org>

Distributed under the terms of the GPL version 2 or later.

=head1 SEE ALSO

L<mqdb-sendmail>, L<mqdb-list>, L<mqdb-rm>, L<mqdb-flush>

=cut
