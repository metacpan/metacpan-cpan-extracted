# Palm::Address.pm
# 
# Perl class for dealing with Palm AddressBook databases. 
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: Address.pm,v 1.19 2002/11/07 14:11:42 arensb Exp $

use strict;
package EBook::MOBI::MobiPerl::Palm::Address;
use EBook::MOBI::MobiPerl::Palm::Raw();
use EBook::MOBI::MobiPerl::Palm::StdAppInfo();

use vars qw( $VERSION @ISA
	$numFieldLabels $addrLabelLength @phoneLabels @countries
	%fieldMapBits );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.19 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::StdAppInfo EBook::MOBI::MobiPerl::Palm::Raw );

# AddressDB records are quite flexible and customizable, and therefore
# a pain in the ass to deal with correctly.

=head1 NAME

Palm::Address - Handler for Palm AddressBook databases

=head1 SYNOPSIS

    use Palm::Address;

=head1 DESCRIPTION

The Address PDB handler is a helper class for the Palm::PDB package.
It parses AddressBook databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{lastUniqueID}
    $pdb->{appinfo}{dirtyFields}

I don't know what these are.

    $pdb->{appinfo}{fieldLabels}{name}
    $pdb->{appinfo}{fieldLabels}{firstName}
    $pdb->{appinfo}{fieldLabels}{company}
    $pdb->{appinfo}{fieldLabels}{phone1}
    $pdb->{appinfo}{fieldLabels}{phone2}
    $pdb->{appinfo}{fieldLabels}{phone3}
    $pdb->{appinfo}{fieldLabels}{phone4}
    $pdb->{appinfo}{fieldLabels}{phone5}
    $pdb->{appinfo}{fieldLabels}{phone6}
    $pdb->{appinfo}{fieldLabels}{phone7}
    $pdb->{appinfo}{fieldLabels}{phone8}
    $pdb->{appinfo}{fieldLabels}{address}
    $pdb->{appinfo}{fieldLabels}{city}
    $pdb->{appinfo}{fieldLabels}{state}
    $pdb->{appinfo}{fieldLabels}{zipCode}
    $pdb->{appinfo}{fieldLabels}{country}
    $pdb->{appinfo}{fieldLabels}{title}
    $pdb->{appinfo}{fieldLabels}{custom1}
    $pdb->{appinfo}{fieldLabels}{custom2}
    $pdb->{appinfo}{fieldLabels}{custom3}
    $pdb->{appinfo}{fieldLabels}{custom4}
    $pdb->{appinfo}{fieldLabels}{note}

These are the names of the various fields in the address record.

    $pdb->{appinfo}{country}

An integer: the code for the country for which these labels were
designed. The country name is available as

        $Palm::Address::countries[$pdb->{appinfo}{country}];

    $pdb->{appinfo}{misc}

An integer. The least-significant bit is a flag that indicates whether
the database should be sorted by company. The other bits are reserved.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N];

    $record->{fields}{name}
    $record->{fields}{firstName}
    $record->{fields}{company}
    $record->{fields}{phone1}
    $record->{fields}{phone2}
    $record->{fields}{phone3}
    $record->{fields}{phone4}
    $record->{fields}{phone5}
    $record->{fields}{address}
    $record->{fields}{city}
    $record->{fields}{state}
    $record->{fields}{zipCode}
    $record->{fields}{country}
    $record->{fields}{title}
    $record->{fields}{custom1}
    $record->{fields}{custom2}
    $record->{fields}{custom3}
    $record->{fields}{custom4}
    $record->{fields}{note}

These are scalars, the values of the various address book fields.

    $record->{phoneLabel}{phone1}
    $record->{phoneLabel}{phone2}
    $record->{phoneLabel}{phone3}
    $record->{phoneLabel}{phone4}
    $record->{phoneLabel}{phone5}

Most fields in an AddressBook record are straightforward: the "name"
field always gives the person's last name.

The "phoneI<N>" fields, on the other hand, can mean different things
in different records. There are five such fields in each record, each
of which can take on one of eight different values: "Work", "Home",
"Fax", "Other", "E-mail", "Main", "Pager" and "Mobile".

The $record->{phoneLabel}{phone*} fields are integers. Each one is
an index into @Palm::Address::phoneLabels, and indicates which
particular type of phone number each of the $record->{phone*} fields
represents.

    $record->{phoneLabel}{display}

Like the phone* fields above, this is an index into
@Palm::Address::phoneLabels. It indicates which of the phone*
fields to display in the list view.

    $record->{phoneLabel}{reserved}

I don't know what this is.

=head1 METHODS

=cut
#'

$addrLabelLength = 16;
$numFieldLabels = 22;

@phoneLabels = (
	"Work",
	"Home",
	"Fax",
	"Other",
	"E-mail",
	"Main",
	"Pager",
	"Mobile",
	);

@countries = (
	"Australia",
	"Austria",
	"Belgium",
	"Brazil",
	"Canada",
	"Denmark",
	"Finland",
	"France",
	"Germany",
	"Hong Kong",
	"Iceland",
	"Ireland",
	"Italy",
	"Japan",
	"Luxembourg",
	"Mexico",
	"Netherlands",
	"New Zealand",
	"Norway",
	"Spain",
	"Sweden",
	"Switzerland",
	"United Kingdom",
	"United States",
);

# fieldMapBits
# Each Address record contains a flag record ($fieldMap, in
# &PackRecord) that indicates which fields exist in the record. This
# hash defines these flags' values.
%fieldMapBits = (
	name		=> 0x0001,
	firstName	=> 0x0002,
	company		=> 0x0004,
	phone1		=> 0x0008,
	phone2		=> 0x0010,
	phone3		=> 0x0020,
	phone4		=> 0x0040,
	phone5		=> 0x0080,
	address		=> 0x0100,
	city		=> 0x0200,
	state		=> 0x0400,
	zipCode		=> 0x0800,
	country		=> 0x1000,
	title		=> 0x2000,
	custom1		=> 0x4000,
	custom2		=> 0x8000,
	custom3		=> 0x10000,
	custom4		=> 0x20000,
	note		=> 0x40000,
);

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "addr", "DATA" ],
		);
}

=head2 new

  $pdb = new Palm::Address;

Create a new PDB, initialized with the various Palm::Address fields
and an empty record list.

Use this method if you're creating an Address PDB from scratch.

=cut
#'

# new
# Create a new Palm::Address database, and return it
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "AddressDB";	# Default
	$self->{creator} = "addr";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since AddressDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		fieldLabels	=> {
			# Displayed labels for the various fields in
			# each address record.
			# XXX - These are American English defaults. It'd
			# be way keen to allow i18n.
			name		=> "Name",
			firstName	=> "First name",
			company		=> "Company",
			phone1		=> "Work",
			phone2		=> "Home",
			phone3		=> "Fax",
			phone4		=> "Other",
			phone5		=> "E-mail",
			phone6		=> "Main",
			phone7		=> "Pager",
			phone8		=> "Mobile",
			address		=> "Address",
			city		=> "City",
			state		=> "State",
			zipCode		=> "Zip Code",
			country		=> "Country",
			title		=> "Title",
			custom1		=> "Custom 1",
			custom2		=> "Custom 2",
			custom3		=> "Custom 3",
			custom4		=> "Custom 4",
			note		=> "Note",
		},

		# XXX - The country code corresponds to "United
		# States". Again, it'd be keen to allow the user's #
		# country-specific defaults.
		country		=> 22,

		misc		=> 0,
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

Creates a new Address record, with blank values for all of the fields.
The AppInfo block will contain only an "Unfiled" category, with ID 0.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

=cut

# new_Record
# Create a new, initialized record.
sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	# Initialize the fields. This isn't particularly enlightening,
	# but every AddressDB record has these.
	$retval->{fields} = {
		name		=> undef,
		firstName	=> undef, 
		company		=> undef,
		phone1		=> undef,
		phone2		=> undef,
		phone3		=> undef,
		phone4		=> undef,
		phone5		=> undef,
		address		=> undef,
		city		=> undef,
		state		=> undef,
		zipCode		=> undef,
		country		=> undef,
		title		=> undef,
		custom1		=> undef,
		custom2		=> undef,
		custom3		=> undef,
		custom4		=> undef,
		note		=> undef,
	};

	# Initialize the phone labels
	$retval->{phoneLabel} = {
		phone1	=> 0,		# Work
		phone2	=> 1,		# Home
		phone3	=> 2,		# Fax
		phone4	=> 3,		# Other
		phone5	=> 4,		# E-mail
		display	=> 0,		# Display work phone by default
		reserved => undef	# ???
	};

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for Address databases.
#
# The AppInfo block has the following overall structure:
#	1: Categories (see StdAppInfo.pm)
#	2: reserved word
#	3: dirty field labels
#	4: field labels
#	5: country
#	6: misc
# 3: I think this is similar to the first part of the standard AppInfo
#    blocka, a bit field of which field labels have changed (i.e.,
#    which fields have been renamed).
# 4: An array of field labels (16-character strings, NUL-terminated).
# 5: The code for the country for which the labels were designed.
# 6: 7 reserved bits followed by one flag that's set if the database
#    should be sorted by company.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $dirtyFields;
	my @fieldLabels;
	my $country;
	my $misc;

	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-standard part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"x2" .		# Reserved
		"N" .		# Dirty flags
		"a$addrLabelLength" x $numFieldLabels .
				# Address labels
		"C" .		# Country
		"C";		# Misc

	($dirtyFields,
	 @fieldLabels[0..($numFieldLabels-1)],
	 $country,
	 $misc) =
		unpack $unpackstr, $data;
	for (@fieldLabels)
	{
		s/\0.*$//;	# Trim everything after the first NUL
				# (when renaming custom fields, might
				# have something like "Foo\0om 1"
	}

	$appinfo->{dirtyFields} = $dirtyFields;
	$appinfo->{fieldLabels} = {
		name		=> $fieldLabels[0],
		firstName	=> $fieldLabels[1],
		company		=> $fieldLabels[2],
		phone1		=> $fieldLabels[3],
		phone2		=> $fieldLabels[4],
		phone3		=> $fieldLabels[5],
		phone4		=> $fieldLabels[6],
		phone5		=> $fieldLabels[7],
		address		=> $fieldLabels[8],
		city		=> $fieldLabels[9],
		state		=> $fieldLabels[10],
		zipCode		=> $fieldLabels[11],
		country		=> $fieldLabels[12],
		title		=> $fieldLabels[13],
		custom1		=> $fieldLabels[14],
		custom2		=> $fieldLabels[15],
		custom3		=> $fieldLabels[16],
		custom4		=> $fieldLabels[17],
		note		=> $fieldLabels[18],
		phone6		=> $fieldLabels[19],
		phone7		=> $fieldLabels[20],
		phone8		=> $fieldLabels[21],
		};
	$appinfo->{country} = $country;
	$appinfo->{misc} = $misc;	# XXX - Parse the "misc" field further

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;
	my $i;
	my $other;		# Non-standard AppInfo stuff

	# Pack the application-specific part of the AppInfo block
	$other = pack("x2 N", $self->{appinfo}{dirtyFields});
	$other .= pack("a$addrLabelLength" x $numFieldLabels,
		$self->{appinfo}{fieldLabels}{name},
		$self->{appinfo}{fieldLabels}{firstName},
		$self->{appinfo}{fieldLabels}{company},
		$self->{appinfo}{fieldLabels}{phone1},
		$self->{appinfo}{fieldLabels}{phone2},
		$self->{appinfo}{fieldLabels}{phone3},
		$self->{appinfo}{fieldLabels}{phone4},
		$self->{appinfo}{fieldLabels}{phone5},
		$self->{appinfo}{fieldLabels}{address},
		$self->{appinfo}{fieldLabels}{city},
		$self->{appinfo}{fieldLabels}{state},
		$self->{appinfo}{fieldLabels}{zipCode},
		$self->{appinfo}{fieldLabels}{country},
		$self->{appinfo}{fieldLabels}{title},
		$self->{appinfo}{fieldLabels}{custom1},
		$self->{appinfo}{fieldLabels}{custom2},
		$self->{appinfo}{fieldLabels}{custom3},
		$self->{appinfo}{fieldLabels}{custom4},
		$self->{appinfo}{fieldLabels}{note},
		$self->{appinfo}{fieldLabels}{phone6},
		$self->{appinfo}{fieldLabels}{phone7},
		$self->{appinfo}{fieldLabels}{phone8});
	$other .= pack("C C x2",
		$self->{appinfo}{country},
		$self->{appinfo}{misc});
	$self->{appinfo}{other} = $other;

	# Pack the standard part of the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

# ParseRecord
# Parse an Address Book record.

# Address book records have the following overall structure:
#	1: phone labels
#	2: field map
#	3: fields

# Each record can contain a number of fields, such as "name",
# "address", "city", "company", and so forth. Each field has an
# internal name ("zipCode"), a printable name ("Zip Code"), and a
# value ("90210").
#
# For most fields, there is a hard mapping between internal and
# printed names: "name" always corresponds to "Last Name". The fields
# "phone1" through "phone5" are different: each of these can be mapped
# to one of several printed names: "Work", "Home", "Fax", "Other",
# "E-Mail", "Main", "Pager" or "Mobile". Multiple internal names can
# map to the same printed name (a person might have several e-mail
# addresses), and the mapping is part of the record (i.e., each record
# has its own mapping).
#
# Part (3) is simply a series of NUL-terminated strings, giving the
# values of the various fields in the record, in a certain order. If a
# record does not have a given field, there is no string corresponding
# to it in this part.
#
# Part (2) is a bit field that specifies which fields the record
# contains.
#
# Part (1) determines the phone mapping described above. This is
# implemented as an unsigned long, but what we're interested in are
# the six least-significant nybbles. They are:
#	disp	phone5	phone4	phone3	phone2	phone1
# ("phone1" is the least-significant nybble). Each nybble holds a
# value in the range 0-15 which in turn specifies the printed name for
# that particular internal name.

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	delete $record{offset};	# This is useless

	my $phoneFlags;
	my @phoneTypes;
	my $dispPhone;		# Which phone to display in the phone list
	my $reserved;		# Not sure what this is. It's the 8 high bits
				# of the "phone types" field.
	my $fieldMap;
	my $companyFieldOff;	# Company field offset: offset into the
				# raw "fields" string of the beginning of
				# the company name, plus 1. Presumably this
				# is to allow the address book app to quickly
				# display by company name. It is 0 in entries
				# that don't have a "Company" field.
				# This can be ignored when reading, and
				# must be computed when writing.
	my $fields;
	my @fields;

	($phoneFlags, $fieldMap, $companyFieldOff, $fields) =
		unpack("N N C a*", $record{data});
	@fields = split /\0/, $fields;

	# Parse the phone flags
	$phoneTypes[0] =  $phoneFlags        & 0x0f;
	$phoneTypes[1] = ($phoneFlags >>  4) & 0x0f;
	$phoneTypes[2] = ($phoneFlags >>  8) & 0x0f;
	$phoneTypes[3] = ($phoneFlags >> 12) & 0x0f;
	$phoneTypes[4] = ($phoneFlags >> 16) & 0x0f;
	$dispPhone     = ($phoneFlags >> 20) & 0x0f;
	$reserved      = ($phoneFlags >> 24) & 0xff;

	$record{phoneLabel}{phone1} = $phoneTypes[0];
	$record{phoneLabel}{phone2} = $phoneTypes[1];
	$record{phoneLabel}{phone3} = $phoneTypes[2];
	$record{phoneLabel}{phone4} = $phoneTypes[3];
	$record{phoneLabel}{phone5} = $phoneTypes[4];
	$record{phoneLabel}{display} = $dispPhone;
	$record{phoneLabel}{reserved} = $reserved;

	# Get the relevant fields
	$fieldMap & 0x0001 and $record{fields}{name} = shift @fields;
	$fieldMap & 0x0002 and $record{fields}{firstName} =
		shift @fields;
	$fieldMap & 0x0004 and $record{fields}{company} = shift @fields;
	$fieldMap & 0x0008 and $record{fields}{phone1} = shift @fields;
	$fieldMap & 0x0010 and $record{fields}{phone2} = shift @fields;
	$fieldMap & 0x0020 and $record{fields}{phone3} = shift @fields;
	$fieldMap & 0x0040 and $record{fields}{phone4} = shift @fields;
	$fieldMap & 0x0080 and $record{fields}{phone5} = shift @fields;
	$fieldMap & 0x0100 and $record{fields}{address} = shift @fields;
	$fieldMap & 0x0200 and $record{fields}{city} = shift @fields;
	$fieldMap & 0x0400 and $record{fields}{state} = shift @fields;
	$fieldMap & 0x0800 and $record{fields}{zipCode} = shift @fields;
	$fieldMap & 0x1000 and $record{fields}{country} = shift @fields;
	$fieldMap & 0x2000 and $record{fields}{title} = shift @fields;
	$fieldMap & 0x4000 and $record{fields}{custom1} = shift @fields;
	$fieldMap & 0x8000 and $record{fields}{custom2} = shift @fields;
	$fieldMap & 0x10000 and $record{fields}{custom3} = shift @fields;
	$fieldMap & 0x20000 and $record{fields}{custom4} = shift @fields;
	$fieldMap & 0x40000 and $record{fields}{note} = shift @fields;

	delete $record{data};

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;
	my $retval;

	$retval = pack("N",
		($record->{phoneLabel}{phone1}    & 0x0f) |
		(($record->{phoneLabel}{phone2}   & 0x0f) <<  4) |
		(($record->{phoneLabel}{phone3}   & 0x0f) <<  8) |
		(($record->{phoneLabel}{phone4}   & 0x0f) << 12) |
		(($record->{phoneLabel}{phone5}   & 0x0f) << 16) |
		(($record->{phoneLabel}{display}  & 0x0f) << 20) |
		(($record->{phoneLabel}{reserved} & 0xff) << 24));

	# Set the flag bits that indicate which fields exist in this
	# record.
	my $fieldMap = 0;

	foreach my $fieldname (qw(name firstName company
			phone1 phone2 phone3 phone4 phone5
			address city state zipCode country title
			custom1 custom2 custom3 custom4
			note))
	{
		if (defined($record->{fields}{$fieldname}) &&
		    ($record->{fields}{$fieldname} ne ""))
		{
			$fieldMap |= $fieldMapBits{$fieldname};
		}
		else 
		{ 
			$record->{fields}{$fieldname} = ""; 
		} 
	}

	$retval .= pack("N", $fieldMap);

	my $fields = '';
	my $companyFieldOff = 0;

	$fields .= $record->{fields}{name} . "\0"
		unless $record->{fields}{name} eq "";
	$fields .= $record->{fields}{firstName} . "\0"
		unless $record->{fields}{firstName} eq "";
	if ($record->{fields}{company} ne "")
	{
		$companyFieldOff = length($fields) + 1;
		$fields .= $record->{fields}{company} . "\0"
	}

	# Append each nonempty field in turn to $fields.
	foreach my $fieldname (qw(phone1 phone2 phone3 phone4 phone5
			address city state zipCode country title
			custom1 custom2 custom3 custom4 note))
	{
		# Skip empty fields (either blank or undefined).
		next if !defined($record->{fields}{$fieldname});
		next if $record->{fields}{$fieldname} eq "";

		# Append the field (with a terminating NUL)
		$fields .= $record->{fields}{$fieldname} . "\0";
	}

	$retval .= pack("C", $companyFieldOff);
	$retval .= $fields;

	return $retval;
}

1;
__END__

=head1 AUTHOR

Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

=head1 BUGS

The new() method initializes the AppInfo block with English labels and
"United States" as the country.

=cut
