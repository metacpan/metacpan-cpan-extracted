# Palm::Memo32.pm
# 
# Perl class for dealing with PaulComputing pEdit Memo32 databases.
#      Copyright (C) 2002, 2003, Wayne A. Arthurton
#
#      Large portions are from Palm::Memo by Andrew Arensburger E<lt>arensb@ooblick.comE<gt>
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: Memo32.pm,v 1.01 2003/5/01 15:00:00 warthurt Exp $

use strict;
package Palm::Memo32;
use Palm::Raw();
use Palm::StdAppInfo();
use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( Palm::StdAppInfo Palm::Raw );

=head1 NAME

Palm::Memo32 - Handler for PaulComputing pEdit Memo32 databases.

=head1 SYNOPSIS

    use Palm::Memo32;

=head1 DESCRIPTION

The Memo32 PDB handler is a helper class for the Palm::PDB package. It
parses PaulComputing (http://www.paulcomputing.com/) pEdit Memo32 databases.

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
		[ "pn32", "DATA" ],
		);
}

=head2 new

  $pdb = new Palm::Memo32;

Create a new PDB, initialized with the various Palm::Memo32 fields
and an empty record list.

Use this method if you're creating a Memo32 PDB from scratch.

=cut
#'
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "Memo32DB";	# Default
	$self->{creator} = "pn32";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since Memo32DB is explicitly not a PRC.

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

Creates a new Memo32 record, with blank values for all of the fields.

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

Wayne A. Arthurton E<lt>wayner@arthurton.comE<gt>

=head1 SEE ALSO

Palm::PDB(3)

Palm::Memo(3)

Palm::StdAppInfo(3)

=cut
