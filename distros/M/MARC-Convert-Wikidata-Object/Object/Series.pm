package MARC::Convert::Wikidata::Object::Series;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);

our $VERSION = 0.03;

has name => (
	is => 'ro',
);

has publisher => (
	is => 'ro',
);

has series_ordinal => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	check_required($self, 'name');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::Series - Bibliographic Wikidata object for series defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::Series;

 my $obj = MARC::Convert::Wikidata::Object::Series->new(%params);
 my $name = $obj->name;
 my $publisher = $obj->publisher;
 my $series_ordinal = $obj->series_ordinal;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::Series->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<name>

Name of book series.

Parameter is required.

=item * C<publisher>

Name of publishing house.

Default value is undef.

=item * C<series_ordinal>

Series ordinal.

Default value is undef.

=back

=head2 C<name>

 my $name = $obj->name;

Get name of book series.

Returns string.

=head2 C<place>

 my $place = $obj->publisher;

Get name of publishing house.

Returns string.

=head2 C<series_ordinal>

 my $series_ordinal = $obj->series_ordinal;

Get series ordinal.

Returns string.

=head1 ERRORS

 new():
         Parameter 'name' is required.

=head1 EXAMPLE1

=for comment filename=create_and_dump_series.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::Series;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $obj = MARC::Convert::Wikidata::Object::Series->new(
         'name' => decode_utf8('Malé encyklopedie'),
         'publisher' => decode_utf8('Mladá Fronta'),
         'series_ordinal' => 5,
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::Series  {
 #     Parents       Mo::Object
 #     public methods (6) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_required (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         name             "Mal� encyklopedie",
 #         publisher        "Mlad� Fronta",
 #         series_ordinal   5
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 SEE ALSO

=over

=item L<MARC::Convert::Wikidata>

Conversion class between MARC record and Wikidata object.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Convert-Wikidata-Object>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021-2023

BSD 2-Clause License

=head1 VERSION

0.03

=cut
