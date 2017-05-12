# PDB.pm
#
# Perl module for reading and writing Palm databases (both PDB and PRC).
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: PDB.pm,v 1.29 2002/11/03 16:43:16 azummo Exp $

# A Palm database file (either .pdb or .prc) has the following overall
# structure:
#	Header
#	Index header
#	Record/resource index
#	Two NUL(?) bytes
#	Optional AppInfo block
#	Optional sort block
#	Records/resources
# See http://www.palmos.com/dev/tech/docs/fileformats.zip
# for details.

use strict;
package EBook::MOBI::MobiPerl::Palm::PDB;
use vars qw( $VERSION %PDBHandlers %PRCHandlers );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.29 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Palm::PDB - Parse Palm database files.

=head1 SYNOPSIS

    use Palm::PDB;
    use SomeHelperClass;

    $pdb = new Palm::PDB;
    $pdb->Load("myfile.pdb");

    # Manipulate records in $pdb

    $pdb->Write("myotherfile.pdb");

(Note: yes, you do want to use C<Palm::PDB>, even if you're dealing
with some other type of database. $pdb will be reblessed to the
appropriate type by C<$pdb-E<gt>Load>.)

=head1 DESCRIPTION

The Palm::PDB module provides a framework for reading and writing
database files for use on PalmOS devices such as the PalmPilot. It can
read and write both Palm Database (C<.pdb>) and Palm Resource
(C<.prc>) files.

By itself, the PDB module is not terribly useful; it is intended to be
used in conjunction with supplemental modules for specific types of
databases, such as Palm::Raw or Palm::Memo.

The Palm::PDB module encapsulates the common work of parsing the
structure of a Palm database. The L<Load()|/Load> function reads the file,
then passes the individual chunks (header, records, etc.) to
application-specific functions for processing. Similarly, the
L<Write()|/Write> function calls application-specific functions to get the
individual chunks, then writes them to a file.

=head1 METHODS

=cut

my $EPOCH_1904 = 2082844800;		# Difference between Palm's
					# epoch (Jan. 1, 1904) and
					# Unix's epoch (Jan. 1, 1970),
					# in seconds.
my $HeaderLen = 32+2+2+(9*4);		# Size of database header
my $RecIndexHeaderLen = 6;		# Size of record index header
my $IndexRecLen = 8;			# Length of record index entry
my $IndexRsrcLen = 10;			# Length of resource index entry

%PDBHandlers = ();			# Record handler map
%PRCHandlers = ();			# Resource handler map

=head2 new

  $new = new Palm::PDB();

Creates a new PDB. $new is a reference to an anonymous hash. Some of
its elements have special significance. See L<Load()|/Load>.

=cut

sub new
{
	my $class	= shift;
	my $params	= shift;

	my $self = {};


	# Initialize the PDB. These values are just defaults, of course.
	$self->{'name'} 	= $params->{'name'}		|| "";
	$self->{'attributes'}	= $params->{'attributes'} 	|| {};
	$self->{'version'}	= $params->{'version'} 		|| 0;

	my $now = time;

	$self->{'ctime'} 	= $params->{'ctime'}		|| $now;
	$self->{'mtime'} 	= $params->{'mtime'}		|| $now;
	$self->{'baktime'} 	= $params->{'baktime'}		|| -$EPOCH_1904;

	$self->{'modnum'}	= $params->{'modnum'}		|| 0;
	$self->{'type'}		= $params->{'type'}		|| "\0\0\0\0";
	$self->{'creator'} 	= $params->{'creator'}		|| "\0\0\0\0";
	$self->{'uniqueIDseed'} = $params->{'uniqueIDseed'}	|| 0;

	$self->{"2NULs"}	= "\0\0";

	bless $self, $class;
	return $self;
}

=head2 RegisterPDBHandlers

  &Palm::PDB::RegisterPDBHandlers("classname", typespec...);

Typically:

  &Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
	[ "FooB", "DATA" ],
	);

The $pdb->L<Load()|/Load> method acts as a virtual constructor. When
it reads the header of a C<.pdb> file, it looks up the file's creator
and type in a set of tables, and reblesses $pdb into a class capable
of parsing the application-specific parts of the file (AppInfo block,
records, etc.)

RegisterPDBHandlers() adds entries to these tables; it says that any
file whose creator and/or type match any of the I<typespec>s (there
may be several) should be reblessed into the class I<classname>.

Note that RegisterPDBHandlers() applies only to record databases
(C<.pdb> files). For resource databases, see
L<RegisterPRCHandlers()|/RegisterPRCHandlers>.

RegisterPDBHandlers() is typically called in the import() function of
a helper class. In this case, the class is registering itself, and it
is simplest just to use C<__PACKAGE__> for the package name:

    package PalmFoo;
    use Palm::PDB;

    sub import
    {
        &Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
            [ "FooZ", "DATA" ]
            );
    }

A I<typespec> can be either a string, or an anonymous array with two
elements. If it is an anonymous array, then the first element is the
file's creator; the second element is its type. If a I<typespec> is a
string, it is equivalent to specifying that string as the database's
creator, and a wildcard as its type.

The creator and type should be either four-character strings, or the
empty string. An empty string represents a wildcard. Thus:

    &Palm::PDB::RegisterPDBHandlers("MyClass",
        [ "fOOf", "DATA" ],
        [ "BarB", "" ],
        [ "", "BazQ" ],
        "Fred"
        );

Class MyClass will handle:

=over 4

=item Z<>

Databases whose creator is C<fOOf> and whose type is C<DATA>.

=item Z<>

Databases whose creator is C<BarB>, of any type.

=item Z<>

Databases with any creator whose type is C<BazQ>.

=item Z<>

Databases whose creator is C<Fred>, of any type.

=back

=for html </DL>
<!-- Grrr... pod2html is broken, and doesn't terminate the list correctly -->

=cut
#'	<-- For Emacs.

sub RegisterPDBHandlers
{
	my $handler = shift;		# Name of class that'll handle
					# these databases
	my @types = @_;
	my $item;

	foreach $item (@types)
	{
		if (ref($item) eq "ARRAY")
		{
			$PDBHandlers{$item->[0]}{$item->[1]} = $handler;
		} else {
			$PDBHandlers{$item}{""} = $handler;
		}
	}
}

=head2 RegisterPRCHandlers

  &Palm::PDB::RegisterPRCHandlers("classname", typespec...);

Typically:

  &Palm::PDB::RegisterPRCHandlers(__PACKAGE__,
	[ "FooZ", "CODE" ],
	);

RegisterPRCHandlers() is similar to
L<RegisterPDBHandlers()|/RegisterPDBHandlers>, but specifies a class
to handle resource database (C<.prc>) files.

A class for parsing applications should begin with:

    package PalmApps;
    use Palm::PDB;

    sub import
    {
        &Palm::PDB::RegisterPRCHandlers(__PACKAGE__,
            [ "", "appl" ]
            );
    }

=cut

sub RegisterPRCHandlers
{
	my $handler = shift;		# Name of class that'll handle
					# these databases
	my @types = @_;
	my $item;

	foreach $item (@types)
	{
		if (ref($item) eq "ARRAY")
		{
			$PRCHandlers{$item->[0]}{$item->[1]} = $handler;
		} else {
			$PRCHandlers{$item}{""} = $handler;
		}
	}
}

=head2 Load

  $pdb->Load("filename");

Reads the file F<filename>, parses it, reblesses $pdb to the
appropriate class, and invokes appropriate methods to parse the
application-specific parts of the database (see L</HELPER CLASSES>).

Load() uses the I<typespec>s given to RegisterPDBHandlers() and
RegisterPRCHandlers() when deciding how to rebless $pdb. For record
databases, it uses the I<typespec>s passed to RegisterPDBHandlers(),
and for resource databases, it uses the I<typespec>s passed to
RegisterPRCHandlers().

Load() looks for matching I<typespec>s in the following order, from
most to least specific:

=over 4

=item 1

A I<typespec> that specifies both the database's creator and its type
exactly.

=item 2

A I<typespec> that specifies the database's type and has a wildcard
for the creator (this is rarely used).

=item 3

A I<typespec> that specifies the database's creator and has a wildcard
for the type.

=item 4

A I<typespec> that has wildcards for both the creator and type.

=back

=for html </OL>
<!-- Grrr... pod2html is broken, and doesn't terminate the list correctly -->

Thus, if the database has creator "FooZ" and type "DATA", Load() will
first look for "FooZ"/"DATA", then ""/"DATA", then "FooZ"/"", and
finally will fall back on ""/"" (the universal default).

After Load() returns, $pdb may contain the following fields:

=over

=item $pdb-E<gt>{Z<>"name"Z<>}

The name of the database.

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"ResDB"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"ReadOnly"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"AppInfoDirty"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Backup"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"OKToInstallNewer"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"ResetAfterInstall"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"CopyPrevention"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Stream"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Hidden"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"LaunchableData"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Recyclable"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Bundle"Z<>}

=item $pdb-E<gt>{Z<>"attributes"Z<>}{Z<>"Open"Z<>}

These are the attribute flags from the database header. Each is true
iff the corresponding flag is set.

The "LaunchableData" attribute is set on PQAs.

=item $pdb-E<gt>{Z<>"version"Z<>}

The database's version number. An integer.

=item $pdb-E<gt>{Z<>"ctime"Z<>}

=item $pdb-E<gt>{Z<>"mtime"Z<>}

=item $pdb-E<gt>{Z<>"baktime"Z<>}

The database's creation time, last modification time, and time of last
backup, in Unix C<time_t> format (seconds since Jan. 1, 1970).

=item $pdb-E<gt>{Z<>"modnum"Z<>}

The database's modification number. An integer.

=item $pdb-E<gt>{Z<>"type"Z<>}

The database's type. A four-character string.

=item $pdb-E<gt>{Z<>"creator"Z<>}

The database's creator. A four-character string.

=item $pdb-E<gt>{Z<>"uniqueIDseed"Z<>}

The database's unique ID seed. An integer.

=item $pdb-E<gt>{Z<>"2NULs"Z<>}

The two NUL bytes that appear after the record index and the AppInfo
block. Included here because every once in a long while, they are not
NULs, for some reason.

=item $pdb-E<gt>{Z<>"appinfo"Z<>}

The AppInfo block, as returned by the $pdb->ParseAppInfoBlock() helper
method.

=item $pdb-E<gt>{Z<>"sort"Z<>}

The sort block, as returned by the $pdb->ParseSortBlock() helper
method.

=item @{$pdb-E<gt>{Z<>"records"Z<>}}

The list of records in the database, as returned by the
$pdb->ParseRecord() helper method. Resource databases do not have
this.

=item @{$pdb-E<gt>{Z<>"resources"Z<>}}

The list of resources in the database, as returned by the
$pdb->ParseResource() helper method. Record databases do not have
this.

=back

All of these fields may be set by hand, but should conform to the
format given above.

=for html </DL>
<!-- Grrr... pod2html is broken, and doesn't terminate the list correctly -->

=cut
#'

# Load
sub Load
{
	my $self = shift;
	my $fname = shift;		# Filename to read from
	my $buf;			# Buffer into which to read stuff

	# Open database file
	open PDB, "< $fname" or die "Can't open \"$fname\": $!\n";
	binmode PDB;			# Read as binary file under MS-DOS

	# Get the size of the file. It'll be useful later
	seek PDB, 0, 2;		# 2 == SEEK_END. Seek to the end.
	$self->{_size} = tell PDB;
	seek PDB, 0, 0;		# 0 == SEEK_START. Rewind to the beginning.

	# Read header
	my $name;
	my $attributes;
	my $version;
	my $ctime;
	my $mtime;
	my $baktime;
	my $modnum;
	my $appinfo_offset;
	my $sort_offset;
	my $type;
	my $creator;
	my $uniqueIDseed;

	read PDB, $buf, $HeaderLen;	# Read the PDB header

	# Split header into its component fields
	($name, $attributes, $version, $ctime, $mtime, $baktime,
	$modnum, $appinfo_offset, $sort_offset, $type, $creator,
	$uniqueIDseed) =
		unpack "a32 n n N N N N N N a4 a4 N", $buf;

	($self->{name} = $name) =~ s/\0.*$//;
	$self->{attributes}{resource} = 1 if $attributes & 0x0001;
	$self->{attributes}{"read-only"} = 1 if $attributes & 0x0002;
	$self->{attributes}{"AppInfo dirty"} = 1 if $attributes & 0x0004;
	$self->{attributes}{backup} = 1 if $attributes & 0x0008;
	$self->{attributes}{"OK newer"} = 1 if $attributes & 0x0010;
	$self->{attributes}{reset} = 1 if $attributes & 0x0020;
	$self->{attributes}{open} = 1 if $attributes & 0x8000;
	$self->{attributes}{launchable} = 1 if $attributes & 0x0200;

	# Attribute names as of PalmOS 5.0 ( see /Core/System/DataMgr.h )

	$self->{'attributes'}{'ResDB'}			= 1 if $attributes & 0x0001; 
	$self->{'attributes'}{'ReadOnly'}		= 1 if $attributes & 0x0002; 
	$self->{'attributes'}{'AppInfoDirty'}		= 1 if $attributes & 0x0004; 
	$self->{'attributes'}{'Backup'}			= 1 if $attributes & 0x0008; 
	$self->{'attributes'}{'OKToInstallNewer'}	= 1 if $attributes & 0x0010; 
	$self->{'attributes'}{'ResetAfterInstall'}	= 1 if $attributes & 0x0020; 
	$self->{'attributes'}{'CopyPrevention'}		= 1 if $attributes & 0x0040; 
	$self->{'attributes'}{'Stream'}			= 1 if $attributes & 0x0080; 
	$self->{'attributes'}{'Hidden'}			= 1 if $attributes & 0x0100; 
	$self->{'attributes'}{'LaunchableData'}		= 1 if $attributes & 0x0200; 
	$self->{'attributes'}{'Recyclable'}		= 1 if $attributes & 0x0400; 
	$self->{'attributes'}{'Bundle'}			= 1 if $attributes & 0x0800; 
	$self->{'attributes'}{'Open'}			= 1 if $attributes & 0x8000; 


	$self->{version} = $version;
	$self->{ctime} = $ctime - $EPOCH_1904;
	$self->{mtime} = $mtime - $EPOCH_1904;
	$self->{baktime} = $baktime - $EPOCH_1904;
	$self->{modnum} = $modnum;
	# _appinfo_offset and _sort_offset are private fields
	$self->{_appinfo_offset} = $appinfo_offset;
	$self->{_sort_offset} = $sort_offset;
	$self->{type} = $type;
	$self->{creator} = $creator;
	$self->{uniqueIDseed} = $uniqueIDseed;

	# Rebless this PDB object, depending on its type and/or
	# creator. This allows us to magically invoke the proper
	# &Parse*() function on the various parts of the database.

	# Look for most specific handlers first, least specific ones
	# last. That is, first look for a handler that deals
	# specifically with this database's creator and type, then for
	# one that deals with this database's creator and any type,
	# and finally for one that deals with anything.

	my $handler;
	if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
	{
		# Look among resource handlers
		$handler = $PRCHandlers{$self->{creator}}{$self->{type}} ||
			$PRCHandlers{undef}{$self->{type}} ||
			$PRCHandlers{$self->{creator}}{""} ||
			$PRCHandlers{""}{""};
	} else {
		# Look among record handlers
		$handler = $PDBHandlers{$self->{creator}}{$self->{type}} ||
			$PDBHandlers{""}{$self->{type}} ||
			$PDBHandlers{$self->{creator}}{""} ||
			$PDBHandlers{""}{""};
	}

	if (defined($handler))
	{
		bless $self, $handler;
	} else {
		# XXX - This should probably return 'undef' or something,
		# rather than die.
		die "No handler defined for creator \"$creator\", type \"$type\"\n";
	}

	## Read record/resource index
	# Read index header
	read PDB, $buf, $RecIndexHeaderLen;

	my $next_index;
	my $numrecs;

	($next_index, $numrecs) = unpack "N n", $buf;
	$self->{_numrecs} = $numrecs;

	# Read the index itself
	if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
	{
		&_load_rsrc_index($self, \*PDB);
	} else {
		&_load_rec_index($self, \*PDB);
	}

	# Read the two NUL bytes
	# XXX - Actually, these are bogus. They don't appear in the
	# spec. The Right Thing to do is to ignore them, and use the
	# specified or calculated offsets, if they're sane. Sane ==
	# appears later than the current position.
#	read PDB, $buf, 2;
#	$self->{"2NULs"} = $buf;

	# Read AppInfo block, if it exists
	if ($self->{_appinfo_offset} != 0)
	{
		&_load_appinfo_block($self, \*PDB);
	}

	# Read sort block, if it exists
	if ($self->{_sort_offset} != 0)
	{
		&_load_sort_block($self, \*PDB);
	}

	# Read record/resource list
	if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
	{
		&_load_resources($self, \*PDB);
	} else {
		&_load_records($self, \*PDB);
	}

	# These keys were needed for parsing the file, but are not
	# needed any longer. Delete them.
	delete $self->{_index};
	delete $self->{_numrecs};
	delete $self->{_appinfo_offset};
	delete $self->{_sort_offset};
	delete $self->{_size};

	close PDB;
}

# _load_rec_index
# Private function. Read the record index, for a record database
sub _load_rec_index
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $i;
	my $lastoffset = 0;

	# Read each record index entry in turn
	for ($i = 0; $i < $pdb->{_numrecs}; $i++)
	{
		my $buf;		# Input buffer

		# Read the next record index entry
		my $offset;
		my $attributes;
		my @id;			# Raw ID
		my $id;			# Numerical ID
		my $entry = {};		# Parsed index entry

		read $fh, $buf, $IndexRecLen;

		# The ID field is a bit weird: it's represented as 3
		# bytes, but it's really a double word (long) value.

		($offset, $attributes, @id) = unpack "N C C3", $buf;

		if ($offset == $lastoffset)
		{
			print STDERR "Record $i has same offset as previous one: $offset\n";
		}

		$lastoffset = $offset;

		$entry->{offset} = $offset;

		$entry->{attributes}{expunged} = 1 if $attributes & 0x80;
		$entry->{attributes}{dirty} = 1 if $attributes & 0x40;
		$entry->{attributes}{deleted} = 1 if $attributes & 0x20;
		$entry->{attributes}{private} = 1 if $attributes & 0x10;

		# Attribute names as of PalmOS 5.0 ( see /Core/System/DataMgr.h )

		$entry->{'attributes'}{'Delete'}	= 1 if $attributes & 0x80;
		$entry->{'attributes'}{'Dirty'}		= 1 if $attributes & 0x40;
		$entry->{'attributes'}{'Busy'}		= 1 if $attributes & 0x20;
		$entry->{'attributes'}{'Secret'}	= 1 if $attributes & 0x10;

		$entry->{id} =	($id[0] << 16) |
				($id[1] << 8)  |
				 $id[2];

		# The lower 4 bits of the attributes field are
		# overloaded: If the record has been deleted and/or
		# expunged, then bit 0x08 indicates whether the record
		# should be archived. Otherwise (if it's an ordinary,
		# non-deleted record), the lower 4 bits specify the
		# category that the record belongs in.
		if (($attributes & 0xa0) == 0)
		{
			$entry->{category} = $attributes & 0x0f;
		} else {
			$entry->{attributes}{archive} = 1
				if $attributes & 0x08;
		}

		# Put this information on a temporary array
		push @{$pdb->{_index}}, $entry;
	}
}

# _load_rsrc_index
# Private function. Read the resource index, for a resource database
sub _load_rsrc_index
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $i;

	# Read each resource index entry in turn
	for ($i = 0; $i < $pdb->{_numrecs}; $i++)
	{
		my $buf;		# Input buffer

		# Read the next resource index entry
		my $type;
		my $id;
		my $offset;
		my $entry = {};		# Parsed index entry

		read $fh, $buf, $IndexRsrcLen;

		($type, $id, $offset) = unpack "a4 n N", $buf;

		$entry->{type} = $type;
		$entry->{id} = $id;
		$entry->{offset} = $offset;

		push @{$pdb->{_index}}, $entry;
	}
}

# _load_appinfo_block
# Private function. Read the AppInfo block
sub _load_appinfo_block
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $len;		# Length of AppInfo block
	my $buf;		# Input buffer

	# Sanity check: make sure we're positioned at the beginning of
	# the AppInfo block
	if (tell($fh) > $pdb->{_appinfo_offset})
	{
		die "Bad AppInfo offset: expected ",
			sprintf("0x%08x", $pdb->{_appinfo_offset}),
			", but I'm at ",
			tell($fh), "\n";
	}

	# Seek to the right place, if necessary
	if (tell($fh) != $pdb->{_appinfo_offset})
	{
		seek PDB, $pdb->{_appinfo_offset}, 0;
	}

	# There's nothing that explicitly gives the size of the
	# AppInfo block. Rather, it has to be inferred from the offset
	# of the AppInfo block (previously recorded in
	# $pdb->{_appinfo_offset}) and whatever's next in the file.
	# That's either the sort block, the first data record, or the
	# end of the file.

	if ($pdb->{_sort_offset})
	{
		# The next thing in the file is the sort block
		$len = $pdb->{_sort_offset} - $pdb->{_appinfo_offset};
	} elsif ((defined $pdb->{_index}) && @{$pdb->{_index}})
	{
		# There's no sort block; the next thing in the file is
		# the first data record
		$len = $pdb->{_index}[0]{offset} -
			$pdb->{_appinfo_offset};
	} else {
		# There's no sort block and there are no records. The
		# AppInfo block goes to the end of the file.
		$len = $pdb->{_size} - $pdb->{_appinfo_offset};
	}

	# Read the AppInfo block
	read $fh, $buf, $len;

	# Tell the real class to parse the AppInfo block
	$pdb->{appinfo} = $pdb->ParseAppInfoBlock($buf);
}

# _load_sort_block
# Private function. Read the sort block.
sub _load_sort_block
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $len;		# Length of sort block
	my $buf;		# Input buffer

	# Sanity check: make sure we're positioned at the beginning of
	# the sort block
	if (tell($fh) > $pdb->{_sort_offset})
	{
		die "Bad sort block offset: expected ",
			sprintf("0x%08x", $pdb->{_sort_offset}),
			", but I'm at ",
			tell($fh), "\n";
	}

	# Seek to the right place, if necessary
	if (tell($fh) != $pdb->{_sort_offset})
	{
		seek PDB, $pdb->{_sort_offset}, 0;
	}

	# There's nothing that explicitly gives the size of the sort
	# block. Rather, it has to be inferred from the offset of the
	# sort block (previously recorded in $pdb->{_sort_offset})
	# and whatever's next in the file. That's either the first
	# data record, or the end of the file.

	if (defined($pdb->{_index}))
	{
		# The next thing in the file is the first data record
		$len = $pdb->{_index}[0]{offset} -
			$pdb->{_sort_offset};
	} else {
		# There are no records. The sort block goes to the end
		# of the file.
		$len = $pdb->{_size} - $pdb->{_sort_offset};
	}

	# Read the AppInfo block
	read $fh, $buf, $len;

	# XXX - Check to see if the sort block has some predefined
	# structure. If so, it might be a good idea to parse the sort
	# block here.

	# Tell the real class to parse the sort block
	$pdb->{sort} = $pdb->ParseSortBlock($buf);
}

# _load_records
# Private function. Load the actual data records, for a record database
# (PDB)
sub _load_records
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $i;

	# Read each record in turn
	for ($i = 0; $i < $pdb->{_numrecs}; $i++)
	{
		my $len;	# Length of record
		my $buf;	# Input buffer

		# Sanity check: make sure we're where we think we
		# should be.
		if (tell($fh) > $pdb->{_index}[$i]{offset})
		{
			die "Bad offset for record $i: expected ",
				sprintf("0x%08x",
					$pdb->{_index}[$i]{offset}),
				" but it's at ",
				sprintf("[0x%08x]", tell($fh)), "\n";
		}

		# Seek to the right place, if necessary
		if (tell($fh) != $pdb->{_index}[$i]{offset})
		{
			seek PDB, $pdb->{_index}[$i]{offset}, 0;
		}

		# Compute the length of the record: the last record
		# extends to the end of the file. The others extend to
		# the beginning of the next record.
		if ($i == $pdb->{_numrecs} - 1)
		{
			# This is the last record
			$len = $pdb->{_size} -
				$pdb->{_index}[$i]{offset};
		} else {
			# This is not the last record
			$len = $pdb->{_index}[$i+1]{offset} -
				$pdb->{_index}[$i]{offset};
		}

		# Read the record
		read $fh, $buf, $len;

		# Tell the real class to parse the record data. Pass
		# &ParseRecord all of the information from the index,
		# plus a "data" field with the raw record data.
		my $record;

		$record = $pdb->ParseRecord(
			%{$pdb->{_index}[$i]},
			"data"	=> $buf,
			);
		push @{$pdb->{records}}, $record;
	}
}

# _load_resources
# Private function. Load the actual data resources, for a resource database
# (PRC)
sub _load_resources
{
	my $pdb = shift;
	my $fh = shift;		# Input file handle
	my $i;

	# Read each resource in turn
	for ($i = 0; $i < $pdb->{_numrecs}; $i++)
	{
		my $len;	# Length of record
		my $buf;	# Input buffer

		# Sanity check: make sure we're where we think we
		# should be.
		if (tell($fh) > $pdb->{_index}[$i]{offset})
		{
			die "Bad offset for resource $i: expected ",
				sprintf("0x%08x",
					$pdb->{_index}[$i]{offset}),
				" but it's at ",
				sprintf("0x%08x", tell($fh)), "\n";
		}

		# Seek to the right place, if necessary
		if (tell($fh) != $pdb->{_index}[$i]{offset})
		{
			seek PDB, $pdb->{_index}[$i]{offset}, 0;
		}

		# Compute the length of the resource: the last
		# resource extends to the end of the file. The others
		# extend to the beginning of the next resource.
		if ($i == $pdb->{_numrecs} - 1)
		{
			# This is the last resource
			$len = $pdb->{_size} -
				$pdb->{_index}[$i]{offset};
		} else {
			# This is not the last resource
			$len = $pdb->{_index}[$i+1]{offset} -
				$pdb->{_index}[$i]{offset};
		}

		# Read the resource
		read $fh, $buf, $len;

		# Tell the real class to parse the resource data. Pass
		# &ParseResource all of the information from the
		# index, plus a "data" field with the raw resource
		# data.
		my $resource;

		$resource = $pdb->ParseResource(
			%{$pdb->{_index}[$i]},
			"data"	=> $buf,
			);
		push @{$pdb->{resources}}, $resource;
	}
}

=head2 Write

  $pdb->Write("filename");

Invokes methods in helper classes to get the application-specific
parts of the database, then writes the database to the file
I<filename>.

Write() uses the following helper methods:

=over

=item Z<>

PackAppInfoBlock()

=item Z<>

PackSortBlock()

=item Z<>

PackResource() or PackRecord()

=back

=for html </DL>
<!-- Grrr... pod2html is broken, and doesn't terminate the list correctly -->

See also L</HELPER CLASSES>.

=cut
#'	<-- For Emacs

sub Write
{
	my $self = shift;
	my $fname = shift;		# Output file name
	my @record_data;

	# Open file
	open my $OFILE, '>', $fname or die "Can't write to \"$fname\": $!\n";
	binmode $OFILE;			# Write as binary file under MS-DOS

	# Get AppInfo block
	my $appinfo_block = $self->PackAppInfoBlock;

	# Get sort block
	my $sort_block = $self->PackSortBlock;

	my $index_len;

	# Get records or resources
	if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
	{
		# Resource database
		my $resource;

		foreach $resource (@{$self->{resources}})
		{
			my $type;
			my $id;
			my $data;

			# Get all the stuff that goes in the index, as
			# well as the resource data.
			$type = $resource->{type};
			$id = $resource->{id};
			$data = $self->PackResource($resource);

			push @record_data, [ $type, $id, $data ];
		}
		# Figure out size of index
		$index_len = $RecIndexHeaderLen +
			($#record_data + 1) * $IndexRsrcLen;
	} else {
		my $record;

		foreach $record (@{$self->{records}})
		{
			my $attributes;
			my $id;
			my $data;

			# XXX - Should probably check the length of this
			# record and not add it to the record if it's 0.

			# Get all the stuff that goes in the index, as
			# well as the record data.
			$attributes = 0;
			if ($record->{attributes}{expunged} ||
			    $record->{attributes}{deleted})
			{
				$attributes |= 0x08
					if $record->{attributes}{archive};
			} else {
				$attributes = ($record->{category} & 0x0f);
			}
			$attributes |= 0x80
				if $record->{attributes}{expunged};
			$attributes |= 0x40
				if $record->{attributes}{dirty};
			$attributes |= 0x20
				if $record->{attributes}{deleted};
			$attributes |= 0x10
				if $record->{attributes}{private};

			$attributes |= 0x80 if $record->{'attributes'}{'Delete'};
			$attributes |= 0x40 if $record->{'attributes'}{'Dirty'};
			$attributes |= 0x20 if $record->{'attributes'}{'Busy'};
			$attributes |= 0x10 if $record->{'attributes'}{'Secret'};

			$id = $record->{id};

			$data = $self->PackRecord($record);

			push @record_data, [ $attributes, $id, $data ];
		}
		# Figure out size of index
		$index_len = $RecIndexHeaderLen +
			($#record_data + 1) * $IndexRecLen;
	}

	my $header;
	my $attributes = 0x0000;
	my $appinfo_offset;
	my $sort_offset;

	# Build attributes field
	$attributes =
		($self->{attributes}{resource}	? 0x0001 : 0) |
		($self->{attributes}{"read-only"}	? 0x0002 : 0) |
		($self->{attributes}{"AppInfo dirty"}	? 0x0004 : 0) |
		($self->{attributes}{backup}	? 0x0008 : 0) |
		($self->{attributes}{"OK newer"}	? 0x0010 : 0) |
		($self->{attributes}{reset}		? 0x0020 : 0) |
		($self->{attributes}{open}		? 0x8000 : 0);

	$attributes |= 0x0001 if $self->{'attributes'}{'ResDB'};
	$attributes |= 0x0002 if $self->{'attributes'}{'ReadOnly'};
	$attributes |= 0x0004 if $self->{'attributes'}{'AppInfoDirty'};
	$attributes |= 0x0008 if $self->{'attributes'}{'Backup'};
	$attributes |= 0x0010 if $self->{'attributes'}{'OKToInstallNewer'};
	$attributes |= 0x0020 if $self->{'attributes'}{'ResetAfterInstall'};
	$attributes |= 0x0040 if $self->{'attributes'}{'CopyPrevention'};
	$attributes |= 0x0080 if $self->{'attributes'}{'Stream'};
	$attributes |= 0x0100 if $self->{'attributes'}{'Hidden'};
	$attributes |= 0x0200 if $self->{'attributes'}{'LaunchableData'};
	$attributes |= 0x0400 if $self->{'attributes'}{'Recyclable'};
	$attributes |= 0x0800 if $self->{'attributes'}{'Bundle'};
	$attributes |= 0x8000 if $self->{'attributes'}{'Open'};	


	# Calculate AppInfo block offset
	if ((!defined($appinfo_block)) || ($appinfo_block eq ""))
	{
		# There's no AppInfo block
		$appinfo_offset = 0;
	} else {
		# Offset of AppInfo block from start of file
		$appinfo_offset = $HeaderLen + $index_len + 2;
	}

	# Calculate sort block offset
	if ((!defined($sort_block)) || ($sort_block eq ""))
	{
		# There's no sort block
		$sort_offset = 0;
	} else {
		# Offset of sort block...
		if ($appinfo_offset == 0)
		{
			# ...from start of file
			$sort_offset = $HeaderLen + $index_len + 2;
		} else {
			# ...or just from start of AppInfo block
			$sort_offset = $appinfo_offset +
				length($appinfo_block);
		}
	}

	# Write header
	$header = pack "a32 n n N N N N N N a4 a4 N",
		$self->{name},
		$attributes,
		$self->{version},
		$self->{ctime} + $EPOCH_1904,
		$self->{mtime} + $EPOCH_1904,
		$self->{baktime} + $EPOCH_1904,
		$self->{modnum},
		$appinfo_offset,
		$sort_offset,
		$self->{type},
		$self->{creator},
		$self->{uniqueIDseed};
		;

	print $OFILE "$header";

	# Write index header
	my $index_header;

	$index_header = pack "N n", 0, ($#record_data+1);
	print $OFILE "$index_header";

	# Write index
	my $rec_offset;		# Offset of next record/resource

	# Calculate offset of first record/resource
	if ($sort_offset != 0)
	{
		$rec_offset = $sort_offset + length($sort_block);
	} elsif ($appinfo_offset != 0)
	{
		$rec_offset = $appinfo_offset + length($appinfo_block);
	} else {
		$rec_offset = $HeaderLen + $index_len + 2;
	}

	if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
	{
		# Resource database
		# Record database
		my $rsrc_data;

		foreach $rsrc_data (@record_data)
		{
			my $type;
			my $id;
			my $data;
			my $index_data;

			($type, $id, $data) = @{$rsrc_data};
			$index_data = pack "a4 n N",
				$type,
				$id,
				$rec_offset;
			print $OFILE "$index_data";

			$rec_offset += length($data);
		}
	} else {
		# Record database
		my $rec_data;

		foreach $rec_data (@record_data)
		{
			my $attributes;
			my $data;
			my $id;
			my $index_data;

			# XXX - Probably shouldn't write this record if
			# length($data) == 0
			($attributes, $id, $data) = @{$rec_data};

			if (length($data) == 0)
			{
				warn printf("Write: Warning: record 0x%08x has length 0\n", $id)
			}

			$index_data = pack "N C C3",
				$rec_offset,
				$attributes,
				($id >> 16) & 0xff,
				($id >> 8) & 0xff,
				$id & 0xff;
			print $OFILE "$index_data";

			$rec_offset += length($data);
		}
	}

	# Write the two NULs
	if (length($self->{"2NULs"}) == 2)
	{
		print $OFILE $self->{"2NULs"};
	} else {
		print $OFILE "\0\0";
	}

	# Write AppInfo block
	print $OFILE $appinfo_block unless $appinfo_offset == 0;

	# Write sort block
	print $OFILE $sort_block unless $sort_offset == 0;

	# Write record/resource list
	my $record;
	foreach $record (@record_data)
	{
		my $data;

		if ($self->{attributes}{resource} || $self->{'attributes'}{'ResDB'})
		{
			# Resource database
			my $type;
			my $id;

			($type, $id, $data) = @{$record};
		} else {
			my $attributes;
			my $id;

			($attributes, $id, $data) = @{$record};
		}
		print $OFILE $data;
	}

	close $OFILE;
}

=head2 new_Record

  $record = Palm::PDB->new_Record();
  $record = new_Record Palm::PDB;

Creates a new record, with the bare minimum needed:

	$record->{'category'}
	$record->{'attributes'}{'Dirty'}
	$record->{'id'}

The ``Dirty'' attribute is originally set, since this function will
usually be called to create records to be added to a database.

C<new_Record> does B<not> add the new record to a PDB. For that,
you want C<append_Record>.

=cut

# PDB::new_Record()
# Create a new, initialized record, and return a reference to it.
# The record is initially marked as being dirty, since that's usually
# the Right Thing.
sub new_Record
{
	my $classname = shift;
	my $retval = {};

	# Initialize the record
	$retval->{'category'} = 0;	# Unfiled, by convention
	$retval->{'attributes'} = {
#		expunged	=> 0,
		dirty		=> 1,	# Note: originally dirty
		'Dirty'		=> 1,
#		deleted		=> 0,
#		private		=> 0,
#		archive         => 0,
	};
	$retval->{'id'} = 0;		# Initially, no record ID

	return $retval;
}

=head2 append_Record

  $record  = $pdb->append_Record;
  $record2 = $pdb->append_Record($record1);

If called without any arguments, creates a new record with
L<new_Record()|/new_Record>, and appends it to $pdb.

If given a reference to a record, appends that record to
@{$pdb->{records}}.

Returns a reference to the newly-appended record.

This method updates $pdb's "last modification" time.

=cut
#'

# append_Record
# Append the given records to the database's list of records. If no
# records are given, create one, append it, and return a reference to
# it.
sub append_Record
{
	my $self = shift;

	if ($#_ < 0)
	{
		# No arguments given. Create a new record.
		my $record = $self->new_Record;

		push @{$self->{records}}, $record;

		# Update the "last modification time".
		$self->{mtime} = time;

		return $record;
	}

	# At least one argument was given. Append all of the arguments
	# to the list of records, and return the first one.
	push @{$self->{records}}, @_;

	# Update the "last modification time".
	$self->{mtime} = time;

	return $_[0];
}

=head2

  $resource = Palm::PDB->new_Resource();
  $resource = new_Resource Palm::PDB;

Creates a new resource and initializes

	$resource->{type}
	$resource->{id}

=cut

# new_Resource
# Create a new, initialized resource, and return a reference to it.
sub new_Resource
{
	my $classname = shift;
	my $retval = {};

	# Initialize the resource
	$retval->{type} = "\0\0\0\0";
	$retval->{id} = 0;

	return $retval;
}

=head2 append_Resource

  $resource  = $pdb->append_Resource;
  $resource2 = $pdb->append_Resource($resource1);

If called without any arguments, creates a new resource with
L<new_Resource()|/new_Resource>, and appends it to $pdb.

If given a reference to a resource, appends that resource to
@{$pdb->{resources}}.

Returns a reference to the newly-appended resource.

This method updates $pdb's "last modification" time.

=cut
#'

# append_Resource
# Append the given resources to the database's list of resources. If no
# resources are given, create one, append it, and return a reference to
# it.
sub append_Resource
{
	my $self = shift;

	if ($#_ < 0)
	{
		# No arguments given. Create a new resource
		my $resource = $self->new_Resource;

		push @{$self->{resources}}, $resource;

		# Update the "last modification time".
		$self->{mtime} = time;

		return $resource;
	}

	# At least one argument was given. Append all of the arguments
	# to the list of resources, and return the first one.
	push @{$self->{resources}}, @_;

	# Update the "last modification time".
	$self->{mtime} = time;

	return $_[0];
}

=head2 findRecordByID

  $record = $pdb->findRecordByID($id);

Looks through the list of records in $pdb, and returns a reference to
the record with ID $id, or the undefined value if no such record was
found.

=cut

# findRecordByID
# Returns a reference to the record with the given ID, or 'undef' if
# it doesn't exist.
sub findRecordByID
{
	my $self = shift;
	my $id = shift;

	return undef if $id eq "";

	for (@{$self->{records}})
	{
		next unless $_->{id} == $id;
		return $_;		# Found it
	}

	return undef;			# Not found
}

=head2 delete_Record

  $pdb->delete_Record($record, $expunge);

Marks $record for deletion, so that it will be deleted from the
database at the next sync.

If $expunge is false or omitted, the record will be marked
for deletion with archival. If $expunge is true, the record will be
marked for deletion without archival.

This method updates $pdb's "last modification" time.

=cut
#'

# delete_Record
# $pdb->delete_Record($record ?, $expunge?)
#
# Mark the given record for deletion. If $expunge is true, mark the
# record for deletion without an archive.

sub delete_Record
{
	my $self = shift;
	my $record = shift;
	my $expunge = shift;

	$record->{attributes}{deleted} = 1;
	if ($expunge)
	{
		$record->{attributes}{expunged} = 1;
		$record->{attributes}{archive} = 0;
	} else {
		$record->{attributes}{expunged} = 0;
		$record->{attributes}{archive} = 1;
	}

	# Update the "last modification time".
	$self->{mtime} = time;
}

1;

__END__

=head1 HELPER CLASSES

$pdb->Load() reblesses $pdb into a new class. This helper class is
expected to convert raw data from the database into parsed
representations of it, and vice-versa.

A helper class must have all of the methods listed below. The
Palm::Raw class is useful if you don't want to define all of the
required methods.


=head2 ParseAppInfoBlock

  $appinfo = $pdb->ParseAppInfoBlock($buf);

$buf is a string of raw data. ParseAppInfoBlock() should parse this
data and return it, typically in the form of a reference to an object
or to an anonymous hash.

This method will not be called if the database does not have an
AppInfo block.

The return value from ParseAppInfoBlock() will be accessible as
$pdb->{appinfo}.

=head2 PackAppInfoBlock

  $buf = $pdb->PackAppInfoBlock();

This is the converse of ParseAppInfoBlock(). It takes $pdb's AppInfo
block, $pdb->{appinfo}, and returns a string of binary data
that can be written to the database file.

=head2 ParseSortBlock

  $sort = $pdb->ParseSortBlock($buf);

$buf is a string of raw data. ParseSortBlock() should parse this data
and return it, typically in the form of a reference to an object or to
an anonymous hash.

This method will not be called if the database does not have a sort
block.

The return value from ParseSortBlock() will be accessible as
$pdb->{sort}.

=head2 PackSortBlock

  $buf = $pdb->PackSortBlock();

This is the converse of ParseSortBlock(). It takes $pdb's sort block,
$pdb->{sort}, and returns a string of raw data that can be
written to the database file.

=head2 ParseRecord

  $record = $pdb->ParseRecord(
          offset         => $offset,	# Record's offset in file
          attributes     =>		# Record attributes
              {
        	expunged => bool,	# True iff expunged
        	dirty    => bool,	# True iff dirty
        	deleted  => bool,	# True iff deleted
        	private  => bool,	# True iff private
	        archive  => bool,       # True iff to be archived
              },
          category       => $category,	# Record's category number
          id             => $id,	# Record's unique ID
          data           => $buf,	# Raw record data
        );

ParseRecord() takes the arguments listed above and returns a parsed
representation of the record, typically as a reference to a record
object or anonymous hash.

The output from ParseRecord() will be appended to
@{$pdb->{records}}. The records appear in this list in the
same order as they appear in the file.

$offset argument is not normally useful, but is included for
completeness.

The fields in %$attributes are boolean values. They are true iff the
record has the corresponding flag set.

$category is an integer in the range 0-15, which indicates which
category the record belongs to. This is normally an index into a table
given at the beginning of the AppInfo block.

A typical ParseRecord() method has this general form:

    sub ParseRecord
    {
        my $self = shift
        my %record = @_;

        # Parse $self->{data} and put the fields into new fields in
        # $self.

        delete $record{data};		# No longer useful
        return \%record;
    }

=head2 PackRecord

  $buf = $pdb->PackRecord($record);

The converse of ParseRecord(). PackRecord() takes a record as returned
by ParseRecord() and returns a string of raw data that can be written
to the database file.

PackRecord() is never called when writing a resource database.

=head2 ParseResource

  $record = $pdb->ParseResource(
          type   => $type,		# Resource type
          id     => $id,		# Resource ID
          offset => $offset,		# Resource's offset in file
          data   => $buf,		# Raw resource data
        );

ParseResource() takes the arguments listed above and returns a parsed
representation of the resource, typically as a reference to a resource
object or anonymous hash.

The output from ParseResource() will be appended to
@{$pdb->{resources}}. The resources appear in this list in
the same order as they appear in the file.

$type is a four-character string giving the resource's type.

$id is an integer that uniquely identifies the resource amongst others
of its type.

$offset is not normally useful, but is included for completeness.

=head2 PackResource

  $buf = $pdb->PackResource($resource);

The converse of ParseResource(). PackResource() takes a resource as
returned by PackResource() and returns a string of raw data that can
be written to the database file.

PackResource() is never called when writing a record database.

=head1 BUGS

These functions die too easily. They should return an error code.

Database manipulation is still an arcane art.

It may be possible to parse sort blocks further.

=head1 AUTHOR

Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

=head1 SEE ALSO

Palm::Raw(3)

Palm::Address(3)

Palm::Datebook(3)

Palm::Mail(3)

Palm::Memo(3)

Palm::ToDo(3)

F<Palm Database Files>, in the ColdSync distribution.

The Virtual Constructor (aka Factory Method) pattern is described in
F<Design Patterns>, by Erich Gamma I<et al.>, Addison-Wesley.
