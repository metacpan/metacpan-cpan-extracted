# Palm::Raw.pm
# 
# Perl class for dealing with "raw" PDB databases. A "raw" database is
# one where the AppInfo and sort blocks, and all of the
# records/resources, are just strings of bytes.
# This is useful as a default PDB handler, for cases where you want to
# be able to handle any kind of database in a generic fashion.
# You may also find it useful to subclass this class, for cases where
# you don't care about every type of thing in a database.
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: Raw.pm,v 1.10 2002/11/03 16:43:16 azummo Exp $

use strict;
package EBook::MOBI::MobiPerl::Palm::Raw;
use EBook::MOBI::MobiPerl::Palm::PDB;
use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::PDB );

=head1 NAME

Palm::Raw - Handler for "raw" Palm databases.

=head1 SYNOPSIS

    use Palm::Raw;

For standalone programs.

    use Palm::Raw();
    @ISA = qw( Palm::Raw );

For Palm::PDB helper modules.

=head1 DESCRIPTION

The Raw PDB handler is a helper class for the Palm::PDB package. It is
intended as a generic handler for any database, or as a fallback
default handler.

If you have a standalone program and want it to be able to parse any
type of database, use

    use Palm::Raw;

If you are using Palm::Raw as a parent class for your own database
handler, use

    use Palm::Raw();

If you omit the parentheses, Palm::Raw will register itself as the
default handler for all databases, which is probably not what you
want.

The Raw handler does no processing on the database whatsoever. The
AppInfo block, sort block, records and resources are simply strings,
raw data from the database.

By default, the Raw handler only handles record databases (.pdb
files). If you want it to handle resource databases (.prc files) as
well, you need to call

    &Palm::PDB::RegisterPRCHandlers("Palm::Raw", "");

in your script.

=head2 AppInfo block

    $pdb->{appinfo}

This is a scalar, the raw data of the AppInfo block.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    @{$pdb->{records}};

Each element in the "records" array is a scalar, the raw data of that
record.

=head2 Resources

    @{$pdb->{resources}};

Each element in the "resources" array is a scalar, the raw data of
that resource.

=cut
#'

sub import
{
	# This package handles any PDB.
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "", "" ]
		);
}

# sub new
# sub new_Record
# These are just inherited.

sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;

	return $data;
}

sub ParseSortBlock
{
	my $self = shift;
	my $data = shift;

	return $data;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	return \%record;
}

sub ParseResource
{
	my $self = shift;
	my %resource = @_;

	return \%resource;
}

sub PackAppInfoBlock
{
	my $self = shift;

	return $self->{appinfo};
}

sub PackSortBlock
{
	my $self = shift;

	return $self->{sort};
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;

	return $record->{data};
}

sub PackResource
{
	my $self = shift;
	my $resource = shift;

	return $resource->{data};
}

1;
__END__

=head1 AUTHOR

Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

=head1 SEE ALSO

Palm::PDB(3)

=cut
