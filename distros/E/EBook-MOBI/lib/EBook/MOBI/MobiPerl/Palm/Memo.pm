# Palm::Memo.pm
# 
# Perl class for dealing with Palm Memo databases. 
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: Memo.pm,v 1.13 2002/11/07 14:12:05 arensb Exp $

use strict;
package EBook::MOBI::MobiPerl::Palm::Memo;
use EBook::MOBI::MobiPerl::Palm::Raw();
use EBook::MOBI::MobiPerl::Palm::StdAppInfo();
use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.13 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::StdAppInfo EBook::MOBI::MobiPerl::Palm::Raw );

=head1 NAME

Palm::Memo - Handler for Palm Memo databases.

=head1 SYNOPSIS

    use Palm::Memo;

=head1 DESCRIPTION

The Memo PDB handler is a helper class for the Palm::PDB package. It
parses Memo databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{sortOrder}

I don't know what this is.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N]

    $record->{data}

A string, the text of the memo.

=cut
#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "memo", "DATA" ],
		);
}

=head2 new

  $pdb = new Palm::Memo;

Create a new PDB, initialized with the various Palm::Memo fields
and an empty record list.

Use this method if you're creating a Memo PDB from scratch.

=cut
#'
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "MemoDB";	# Default
	$self->{creator} = "memo";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since MemoDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		sortOrder	=> undef,	# XXX - ?
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

Creates a new Memo record, with blank values for all of the fields.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

=cut

sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	$retval->{data} = "";

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for Memo databases.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $sortOrder;
	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-category part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"x4" .		# Padding
		"C";		# Sort order

	($sortOrder) = unpack $unpackstr, $data;

	$appinfo->{sortOrder} = $sortOrder;

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;
	my $i;

	# Pack the non-category part of the AppInfo block
	$self->{appinfo}{other} =
		pack("x4 C x1", $self->{appinfo}{sortOrder});

	# Pack the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

sub PackSortBlock
{
	# XXX
	return undef;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	delete $record{offset};		# This is useless
	$record{data} =~ s/\0$//;	# Trim trailing NUL

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;

	return $record->{data} . "\0";	# Add the trailing NUL
}

1;
__END__

=head1 AUTHOR

Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

=cut
