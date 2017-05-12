# Palm::Mail.pm
# 
# Perl class for dealing with Palm Mail databases. 
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: Mail.pm,v 1.16 2002/11/07 14:11:59 arensb Exp $

use strict;
package EBook::MOBI::MobiPerl::Palm::Mail;
use EBook::MOBI::MobiPerl::Palm::Raw();
use EBook::MOBI::MobiPerl::Palm::StdAppInfo();
use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::StdAppInfo EBook::MOBI::MobiPerl::Palm::Raw );

=head1 NAME

Palm::Mail - Handler for Palm Mail databases.

=head1 SYNOPSIS

    use Palm::Mail;

=head1 DESCRIPTION

The Mail PDB handler is a helper class for the Palm::PDB package. It
parses Mail databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{sortOrder}
    $pdb->{appinfo}{unsent}
    $pdb->{appinfo}{sigOffset}

I don't know what these are.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N]

    $record->{year}
    $record->{month}
    $record->{day}
    $record->{hour}
    $record->{minute}

The message's timestamp.

    $record->{is_read}

This is defined and true iff the message has been read.

    $record->{has_signature}

For outgoing messages, this is defined and true iff the message should
have a signature attached. The signature itself is stored in the
"Saved Preferences.prc" database, and is of type "mail" with ID 2.

    $record->{confirm_read}

If this is defined and true, then the sender requests notification
when the message has been read.

    $record->{confirm_delivery}

If this is defined and true, then the sender requests notification
when the message has been delivered.

    $record->{priority}

An integer in the range 0-2, for high, normal, or low priority,
respectively.

    $record->{addressing}

An integer in the range 0-2, indicating the addressing type: To, Cc,
or Bcc respectively. I don't know what this means.

    $record->{subject}
    $record->{from}
    $record->{to}
    $record->{cc}
    $record->{bcc}
    $record->{replyTo}
    $record->{sentTo}

Strings, the various header fields.

    $record->{body}

A string, the body of the message.

=head1 METHODS

=cut
#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "mail", "DATA" ],
		);
}

=head2 new

  $pdb = new Palm::Mail;

Create a new PDB, initialized with the various Palm::Mail fields
and an empty record list.

Use this method if you're creating a Mail PDB from scratch.

=cut
#'

sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "MailDB";	# Default
	$self->{creator} = "mail";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since MailDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		sortOrder	=> undef,	# XXX - ?
		unsent		=> undef,	# XXX - ?
		sigOffset	=> 0,		# XXX - ?
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	$self->{sort} = undef;	# Empty sort block

	$self->{records} = [];	# Empty list of records

	return $self;
}

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new Mail record, with blank values for all of the fields.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

Note: the time given by the C<year>, C<month>, C<day>, C<hour>, and
C<minute> fields in the new record are initialized to the time when
the record was created. They should be reset to the time when the
message was sent.

=cut

sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	# Set the date and time on this message to today and now. This
	# is arguably bogus, since the Date: header on a message ought
	# to represent the time when the message was sent, rather than
	# the time when the user started composing it, but this is
	# better than nothing.

	($retval->{year},
	 $retval->{month},
	 $retval->{day},
	 $retval->{hour},
	 $retval->{minute}) = (localtime(time))[5,4,3,2,1];

	$retval->{is_read} = 0;	# Message hasn't been read yet.

	# No delivery service notification (DSN) by default.
	$retval->{confirm_read} = 0;
	$retval->{confirm_delivery} = 0;

	$retval->{priority} = 1;	# Normal priority

	$retval->{addressing} = 0;	# XXX - ?

	# All header fields empty by default.
	$retval->{from} = undef;
	$retval->{to} = undef;
	$retval->{cc} = undef;
	$retval->{bcc} = undef;
	$retval->{replyTo} = undef;
	$retval->{sentTo} = undef;

	$retval->{body} = "";

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for Mail databases.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $dirtyAppInfo;
	my $sortOrder;
	my $unsent;
	my $sigOffset;		# XXX - Offset of signature?
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-category part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"x2" .		# Padding
		"n" .		# Dirty AppInfo (what is this?)
		"Cx" .		# Sort order
		"N" .		# Unique ID of unsent message (what is this?)
		"n";		# Signature offset

	($dirtyAppInfo, $sortOrder, $unsent, $sigOffset) =
		unpack $unpackstr, $data;

	$appinfo->{dirty_AppInfo} = $dirtyAppInfo;
	$appinfo->{sort_order} = $sortOrder;
	$appinfo->{unsent} = $unsent;
	$appinfo->{sig_offset} = $sigOffset;

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;

	# Pack the non-category part of the AppInfo block
	$self->{appinfo}{other} = pack "x2 n Cx N n",
		$self->{appinfo}{dirty_AppInfo},
		$self->{appinfo}{sort_order},
		$self->{appinfo}{unsent},
		$self->{appinfo}{sig_offset};

	# Pack the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;
	my $data = $record{data};

	delete $record{offset};	# This is useless
	delete $record{data};

	my $date;
	my $hour;
	my $minute;
	my $flags;
	my $subject;
	my $from;
	my $to;
	my $cc;
	my $bcc;
	my $replyTo;
	my $sentTo;
	my $body;
	my $extra;		# Extra field after body. I don't know what
				# it is.
	my $unpackstr =
		"n" .		# Date
		"C" .		# Hour
		"C" .		# Minute
		"n";		# Flags

	($date, $hour, $minute, $flags) = unpack $unpackstr, $data;

	my $year;
	my $month;
	my $day;

	if ($date != 0)
	{
		$day   =  $date       & 0x001f;	# 5 bits
		$month = ($date >> 5) & 0x000f;	# 4 bits
		$year  = ($date >> 9) & 0x007f;	# 7 bits (years since 1904)
		$year += 1904;

		$record{year}   = $year;
		$record{month}  = $month;
		$record{day}    = $day;
		$record{hour}   = $hour;
		$record{minute} = $minute;
	}

	my $is_read		= ($flags & 0x8000);
	my $has_signature	= ($flags & 0x4000);
	my $confirm_read	= ($flags & 0x2000);
	my $confirm_delivery	= ($flags & 0x1000);
	my $priority	= ($flags >> 10) & 0x03;
	my $addressing	= ($flags >>  8) & 0x03;

	# The signature is problematic: it's not stored in
	# "MailDB.pdb": it's actually in "Saved Preferences.pdb". Work
	# around this somehow; either read it from "Saved
	# Preferences.pdb" or, more simply, just read ~/.signature if
	# it exists.

	$record{is_read} = 1 if $is_read;
	$record{has_signature} = 1 if $has_signature;
	$record{confirm_read} = 1 if $confirm_read;
	$record{confirm_delivery} = 1 if $confirm_delivery;
	$record{priority} = $priority;
	$record{addressing} = $addressing;

	my $fields = substr $data, 6;
	my @fields = split /\0/, $fields;

	($subject, $from, $to, $cc, $bcc, $replyTo, $sentTo, $body,
	 $extra) = @fields;

	# Clean things up a bit

	# Multi-line values are bad in these headers. Replace newlines
	# with commas. Ideally, we'd use arrays for multiple
	# recipients, but that would involve parsing addresses, which
	# is non-trivial. Besides, most likely we'll just wind up
	# sending these strings as they are to 'sendmail', which is
	# better equipped to parse them.

	$to =~ s/\s*\n\s*(?!$)/, /gs if defined($to);
	$cc =~ s/\s*\n\s*(?!$)/, /gs if defined($cc);
	$bcc =~ s/\s*\n\s*(?!$)/, /gs if defined($bcc);
	$replyTo =~ s/\s*\n\s*(?!$)/, /gs if defined($replyTo);
	$sentTo =~ s/\s*\n\s*(?!$)/, /gs if defined($sentTo);

	$record{subject} = $subject;
	$record{from} = $from;
	$record{to} = $to;
	$record{cc} = $cc;
	$record{bcc} = $bcc;
	$record{replyTo} = $replyTo;
	$record{sentTo} = $sentTo;
	$record{body} = $body;
	$record{extra} = $extra;

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;
	my $retval;
	my $rawDate;
	my $flags;

	$rawDate = ($record->{day} & 0x001f) |
		(($record->{month} & 0x000f) << 5) |
		((($record->{year} - 1904) & 0x07f) << 9);
	$flags = 0;
	$flags |= 0x8000 if $record->{is_read};
	$flags |= 0x4000 if $record->{has_signature};
	$flags |= 0x2000 if $record->{confirm_read};
	$flags |= 0x1000 if $record->{confirm_delivery};
	$flags |= (($record->{priority} & 0x03) << 10);
	$flags |= (($record->{addressing} & 0x03) << 8);

	$retval = pack "n C C n",
		$rawDate,
		$record->{hour},
		$record->{minute},
		$flags;

	$retval .= join "\0",
		$record->{subject},
		$record->{from},
		$record->{to},
		$record->{cc},
		$record->{bcc},
		$record->{replyTo},
		$record->{sentTo},
		$record->{body};
	$retval .= "\0";

	return $retval;
}

1;
__END__

=head1 AUTHOR

Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

=cut
