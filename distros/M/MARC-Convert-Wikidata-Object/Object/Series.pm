package MARC::Convert::Wikidata::Object::Series;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.08 qw(check_isa check_required);

our $VERSION = 0.15;

has issn => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has publisher => (
	is => 'ro',
);

has series_ordinal => (
	is => 'ro',
);

has series_ordinal_raw => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'name'.
	check_required($self, 'name');

	# Check 'publisher'.
	check_isa($self, 'publisher', 'MARC::Convert::Wikidata::Object::Publisher');

	# Check 'series_ordinal'.
	if (defined $self->{'series_ordinal'}
		&& $self->{'series_ordinal'} !~ m/^\d+$/ms
		&& $self->{'series_ordinal'} !~ m/^\d+\-\d+$/ms
		&& $self->{'series_ordinal'} !~ m/^(?i)M{0,3}(CM|CD|D?C{0,3})
			(XC|XL|L?X{0,3})
			(IX|IV|V?I{0,3})$/x) {

		err "Parameter 'series_ordinal' has bad value.",
			'Value', $self->{'series_ordinal'},
		;
	}

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
 my $issn = $obj->issn;
 my $name = $obj->name;
 my $publisher = $obj->publisher;
 my $series_ordinal = $obj->series_ordinal;
 my $series_ordinal_raw = $obj->series_ordinal_raw;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::Series->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<issn>

ISSN of series.

Parameter is optional.

=item * C<name>

Name of book series.

Parameter is required.

=item * C<publisher>

Publishing house L<MARC::Convert::Wikidata::Object::Publisher> object.

Default value is undef.

=item * C<series_ordinal>

Series ordinal.

Could be a number, range of numbers or roman number.

Default value is undef.

=item * C<series_ordinal_raw>

Series ordinal raw string.

Default value is undef.

=back

=head2 C<name>

 my $name = $obj->name;

Get name of book series.

Returns string.

=head2 C<publisher>

 my $place = $obj->publisher;

Get publishing house.

Returns L<MARC::Convert::Wikidata::Object::Publisher> object.

=head2 C<series_ordinal>

 my $series_ordinal = $obj->series_ordinal;

Get series ordinal.

Returns number.

=head2 C<series_ordinal_raw>

 my $series_ordinal_raw = $obj->series_ordinal_raw;

Get series ordinal raw string.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_isa():
                 Parameter 'publisher' must be a 'MARC::Convert::Wikidata::Object::Publisher' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::check_required():
                 Parameter 'name' is required.
         Parameter 'series_ordinal' has bad value.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=create_and_dump_series.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::Publisher;
 use MARC::Convert::Wikidata::Object::Series;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $obj = MARC::Convert::Wikidata::Object::Series->new(
         'name' => decode_utf8('Malé encyklopedie'),
         'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
                 'name' => decode_utf8('Mladá Fronta'),
         ),
         'series_ordinal' => 5,
         'series_ordinal_raw' => 'kn. 5',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::Series  {
 #     Parents       Mo::Object
 #     public methods (6) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_required (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         name             "Mal� encyklopedie",
 #         publisher        MARC::Convert::Wikidata::Object::Publisher,
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

© Michal Josef Špaček 2021-2025

BSD 2-Clause License

=head1 VERSION

0.15

=cut
