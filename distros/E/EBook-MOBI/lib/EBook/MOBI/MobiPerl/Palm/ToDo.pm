# Palm::ToDo.pm
# 
# Perl class for dealing with Palm ToDo databases. 
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: ToDo.pm,v 1.12 2002/11/07 14:12:10 arensb Exp $

# XXX - Bug: apparently, the first ToDo item shows up with a category
# of "unfiled"

use strict;
package EBook::MOBI::MobiPerl::Palm::ToDo;
use EBook::MOBI::MobiPerl::Palm::Raw();
use EBook::MOBI::MobiPerl::Palm::StdAppInfo();

use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::StdAppInfo EBook::MOBI::MobiPerl::Palm::Raw );

=head1 NAME

Palm::ToDo - Handler for Palm ToDo databases.

=head1 SYNOPSIS

    use Palm::ToDo;

=head1 DESCRIPTION

The ToDo PDB handler is a helper class for the Palm::PDB package. It
parses ToDo databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{dirty_appinfo}
    $pdb->{appinfo}{sortOrder}

I don't know what these are.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N]

    $record->{due_day}
    $record->{due_month}
    $record->{due_year}

The due date of the ToDo item. If the item has no due date, these are
undefined.

    $record->{completed}

This is defined and true iff the item has been completed.

    $record->{priority}

An integer. The priority of the item.

    $record->{description}

A text string. The description of the item.

    $record->{note}

A text string. The note attached to the item. Undefined if the item
has no note.

=cut
#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "todo", "DATA" ],
		);
}

=head2 new

  $pdb = new Palm::ToDo;

Create a new PDB, initialized with the various Palm::ToDo fields
and an empty record list.

Use this method if you're creating a ToDo PDB from scratch.

=cut
#'

# new
# Create a new Palm::ToDo database, and return it
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "ToDoDB";	# Default
	$self->{creator} = "todo";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since ToDoDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		dirty_appinfo	=> undef,	# ?
		sortOrder	=> undef,	# ?
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	# Give the PDB a blank sort block
	$self->{sort} = undef;

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
}

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new ToDo record, with blank values for all of the fields.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

=cut

# new_Record
# Create a new, initialized record.
sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	# Item has no due date by default.
	$retval->{due_day} = undef;
	$retval->{due_month} = undef;
	$retval->{due_year} = undef;

	$retval->{completed} = 0;	# Not completed
	$retval->{priority} = 1;

	# Empty description, no note.
	$retval->{description} = "";
	$retval->{note} = undef;

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for ToDo databases.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $dirtyAppInfo;
	my $sortOrder;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-category part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"x2" .		# Reserved
		"n" .		# XXX - Dirty AppInfo (what is this?)
		"Cx";		# Sort order

	($dirtyAppInfo, $sortOrder) = unpack $unpackstr, $data;

	$appinfo->{dirty_appinfo} = $dirtyAppInfo;
	$appinfo->{sort_order} = $sortOrder;

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;

	# Pack the application-specific part of the AppInfo block
	$self->{appinfo}{other} = pack("x2 n Cx",
		$self->{appinfo}{dirty_appinfo},
		$self->{appinfo}{sort_order});

	# Pack the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;
	my $data = $record{data};

	delete $record{offset};		# This is useless
	delete $record{data};		# No longer necessary

	my $date;
	my $priority;

	($date, $priority) = unpack "n C", $data;
	$data = substr $data, 3;	# Remove the stuff we've already seen

	if ($date != 0xffff)
	{
		my $day;
		my $month;
		my $year;

		$day   =  $date       & 0x001f;	# 5 bits
		$month = ($date >> 5) & 0x000f;	# 4 bits
		$year  = ($date >> 9) & 0x007f;	# 7 bits (years since 1904)
		$year += 1904;

		$record{due_day} = $day;
		$record{due_month} = $month;
		$record{due_year} = $year;
	}

	my $completed;		# Boolean

	$completed = $priority & 0x80;
	$priority &= 0x7f;	# Strip high bit

	$record{completed} = 1 if $completed;
	$record{priority} = $priority;

	my $description;
	my $note;

	($description, $note) = split /\0/, $data;

	$record{description} = $description;
	$record{note} = $note unless $note eq "";

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;
	my $retval;
	my $rawDate;
	my $priority;

	if (defined($record->{due_day}))
	{
		$rawDate = ($record->{due_day} & 0x001f) |
			(($record->{due_month} & 0x000f) << 5) |
			((($record->{due_year} - 1904) & 0x007f) << 9);
	} else {
		$rawDate = 0xffff;
	}
	$priority = $record->{priority} & 0x7f;
	$priority |= 0x80 if $record->{completed};

	$retval = pack "n C",
		$rawDate,
		$priority;
	$retval .= $record->{description} . "\0";
	$retval .= $record->{note} . "\0";

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
