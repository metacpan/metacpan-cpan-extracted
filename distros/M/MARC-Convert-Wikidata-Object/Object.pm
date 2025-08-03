package MARC::Convert::Wikidata::Object;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build default is);
use Mo::utils 0.26 qw(check_isa check_number);
use Mo::utils::Array qw(check_array check_array_object);
use Readonly;

Readonly::Array our @COVERS => qw(hardback paperback);

our $VERSION = 0.14;

has authors => (
	default => [],
	is => 'ro',
);

has authors_of_afterword => (
	default => [],
	is => 'ro',
);

has authors_of_introduction => (
	default => [],
	is => 'ro',
);

has compilers => (
	default => [],
	is => 'ro',
);

has cover => (
	is => 'ro',
);

has covers => (
	default => [],
	is => 'ro',
);

has cycles => (
	default => [],
	is => 'ro',
);

has directors => (
	default => [],
	is => 'ro',
);

has dml => (
	is => 'ro',
);

has edition_number => (
	is => 'ro',
);

has edition_of_work => (
	is => 'ro',
);

has editors => (
	default => [],
	is => 'ro',
);

has end_time => (
	is => 'ro',
);

has external_ids => (
	default => [],
	is => 'ro',
);

has illustrators => (
	default => [],
	is => 'ro',
);

has isbns => (
	default => [],
	is => 'ro',
);

has issn => (
	is => 'ro',
);

has languages => (
	default => [],
	is => 'ro',
);

has krameriuses => (
	default => [],
	is => 'ro',
);

has narrators => (
	default => [],
	is => 'ro',
);

has number_of_pages => (
	is => 'ro',
);

has photographers => (
	default => [],
	is => 'ro',
);

has publication_date => (
	is => 'ro',
);

has publishers => (
	default => [],
	is => 'ro',
);

has series => (
	default => [],
	is => 'ro',
);

has start_time => (
	is => 'ro',
);

has subtitles => (
	default => [],
	is => 'ro',
);

has title => (
	is => 'ro',
);

has translators => (
	default => [],
	is => 'ro',
);

sub full_name {
	my $self = shift;

	my $full_name = $self->title;
	foreach my $subtitle (@{$self->subtitles}) {
		$full_name .= ': '.$subtitle;
	}

	return $full_name;
}

sub BUILD {
	my $self = shift;

	# Check authors.
	check_array_object($self, 'authors', 'MARC::Convert::Wikidata::Object::People');

	# Check authors of introduction.
	check_array_object($self, 'authors_of_afterword', 'MARC::Convert::Wikidata::Object::People');

	# Check authors of introduction.
	check_array_object($self, 'authors_of_introduction', 'MARC::Convert::Wikidata::Object::People');

	# Check compilers.
	check_array_object($self, 'compilers', 'MARC::Convert::Wikidata::Object::People');

	# Check cover.
	if (defined $self->{'cover'} && none { $_ eq $self->{'cover'} } @COVERS) {
		err "Book cover '".$self->{'cover'}."' doesn't exist.";
	}

	# Check covers.
	# XXX Common check.
	foreach my $cover (@{$self->covers}) {
		if (! defined $cover && none { $_ eq $cover } @COVERS) {
			err "Book cover '".$cover."' doesn't exist.";
		}
	}

	# Check cycles.
	check_array_object($self, 'cycles', 'MARC::Convert::Wikidata::Object::Series');

	# Check directors.
	check_array_object($self, 'directors', 'MARC::Convert::Wikidata::Object::People');

	# Check dml id
	check_number($self, 'dml');

	# Check edition_of_work.
	check_isa($self, 'edition_of_work', 'MARC::Convert::Wikidata::Object::Work');

	# Check editors.
	check_array_object($self, 'editors', 'MARC::Convert::Wikidata::Object::People');

	# Check end_time.
	check_number($self, 'end_time');

	# Check external_ids.
	check_array_object($self, 'external_ids', 'MARC::Convert::Wikidata::Object::ExternalId');

	# Check illustrators.
	check_array_object($self, 'illustrators', 'MARC::Convert::Wikidata::Object::People');

	# Check isbns.
	check_array_object($self, 'isbns', 'MARC::Convert::Wikidata::Object::ISBN');

	# Check languages.
	check_array($self, 'languages');

	# Check Kramerius systems.
	check_array_object($self, 'krameriuses', 'MARC::Convert::Wikidata::Object::Kramerius');

	# Check narrators.
	check_array_object($self, 'narrators', 'MARC::Convert::Wikidata::Object::People');

	# Check photographers.
	check_array_object($self, 'photographers', 'MARC::Convert::Wikidata::Object::People');

	# Check list of publishers.
	check_array_object($self, 'publishers', 'MARC::Convert::Wikidata::Object::Publisher');

	# Check series.
	check_array_object($self, 'series', 'MARC::Convert::Wikidata::Object::Series');

	# Check start_time.
	check_number($self, 'start_time');

	# Check series.
	check_array($self, 'subtitles');

	# Check translators.
	check_array_object($self, 'translators',
		'MARC::Convert::Wikidata::Object::People', 'Translator');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object - Bibliographic Wikidata object defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object;

 my $obj = MARC::Convert::Wikidata::Object->new(%params);
 my $authors_ar = $obj->authors;
 my $authors_of_afterword_ar = $obj->authors_of_afterword;
 my $authors_of_introduction_ar = $obj->authors_of_introduction;
 my $compilers = $obj->compilers;
 my $cover = $obj->cover;
 my $covers_ar = $obj->covers;
 my $cycles_ar = $obj->cycles;
 my $directors_ar = $obj->directors;
 my $dml = $obj->dml;
 my $edition_number = $obj->edition_number;
 my $edition_of_work = $obj->edition_of_work;
 my $editors_ar = $obj->editors;
 my $end_time = $obj->end_time;
 my $external_ids_ar = $obj->external_ids;
 my $full_name = $obj->full_name;
 my $illustrators_ar = $obj->illustrators;
 my $isbns_ar = $obj->isbns;
 my $issn = $obj->issn;
 my $kramerius_ar = $obj->krameriuses;
 my $languages_ar = $obj->languages;
 my $narrators_ar = $obj->narrators;
 my $number_of_pages = $obj->number_of_pages;
 my $photographers_ar = $obj->photographers;
 my $publication_date = $obj->publication_date;
 my $publishers_ar = $obj->publishers;
 my $series_ar = $obj->series;
 my $start_time = $obj->start_time;
 my $subtitles_ar = $obj->subtitles;
 my $title = $obj->title;
 my $translators_ar = $obj->translators;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<authors>

List of authors.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<authors_of_afterword>

List of authors of afterword.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<authors_of_introduction>

List of authors of introduction.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<compilers>

List of compilers.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<cover>

I<Parameter is deprecated. Use L<covers> instead of it.>

Book cover.
Possible values:
 * hardback
 * paperback

Default value is undef.

=item * C<covers>

Book covers.

It's reference to array with 'hardback', 'paperback' values.

Default value is [].

=item * C<cycles>

List of book cycles.
Reference to array with MARC::Convert::Wikidata::Object::Series instances.

Default value is [].

=item * C<directors>

List of directors.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<dml>

DML id.

Default value is undef.

=item * C<edition_number>

Edition number.

Default value is undef.

=item * C<edition_of_work>

Edition of work.

Default value is undef.

=item * C<editors>

List of editors.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<end_time>

End time.

Default value is undef.

=item * C<external_ids>

External ids.

Need to be a reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

Default value is [].

=item * C<illustrators>

List of illustrators.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<isbns>

List of ISBNs.
Reference to array with MARC::Convert::Wikidata::Object::ISBN instances.

Default value is reference to blank array.

=item * C<issn>

ISSN number.

Default value is undef.

=item * C<krameriuses>

List of Kramerius systems with digitized scan.
Reference to array with MARC::Convert::Wikidata::Object::Kramerius instances.

Default value is reference to blank array.

=item * C<languages>

List of languages of book edition (TODO Format)

Default value is reference to blank array.

=item * C<narrators>

List of narrators.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<number_of_pages>

Number of pages.

Default value is undef.

=item * C<photographers>

List of photographers.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<publication_date>

Publication date.

Default value is undef.

=item * C<publishers>

List of Publishers.
Reference to array with MARC::Convert::Wikidata::Object::Publisher instances.

Default value is [].

=item * C<series>

List of book series.
Reference to array with MARC::Convert::Wikidata::Object::Series instances.

Default value is [].

=item * C<start_time>

Start time.

Default value is undef.

=item * C<subtitles>

List of subtitles.
Reference to array with strings.

Default value is [].

=item * C<title>

Title of book edition.

Default value is undef.

=item * C<translators>

List of translators.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=back

=head2 C<authors>

 my $authors_ar = $obj->authors;

Get reference to array with author objects.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<authors_of_afterword>

 my $authors_of_afterword_ar = $obj->authors_of_afterword;

Get reference to array with author of afterword objects.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<authors_of_introduction>

 my $authors_of_introduction_ar = $obj->authors_of_introduction;

Get reference to array with author of introduction objects.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<compilers>

 my $compilers_ar = $obj->compilers;

Get list of compilers.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<cover>

 my $cover = $obj->cover;

Get book cover.

Returns string (hardback or paperback).

=head2 C<covers>

 my $covers_ar = $obj->covers;

Get book covers.

Returns reference to array with cover strings.

=head2 C<cycles>

 my $cycles_ar = $obj->cycles;

Get reference to array with Serie item objects.

Returns reference to array of MARC::Convert::Wikidata::Object::Series instances.

=head2 C<directors>

 my $directors_ar = $obj->directors;

Get list of directors.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<dml>

 my $dml = $obj->dml;

Get DML id.

Returns number.

=head2 C<edition_number>

 my $edition_number = $obj->edition_number;

Get edition number.

Returns number.

=head2 C<edition_of_work>

 my $edition_of_work = $obj->edition_of_work;

Get edition of work.

Returns L<MARC::Convert::Wikidata::Object::Work> instance.

=head2 C<editors>

 my $editors_ar = $obj->editors;

Get list of editors.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<end_time>

 my $end_time = $obj->end_time;

Get end time.

Returns number.

=head2 C<external_ids>

 my $external_ids_ar = $obj->external_ids;

Get list of external ids.

Returns reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

=head2 C<full_name>

 my $full_name = $obj->full_name;

Get full name of edition in format '__TITLE__: __SUBTITLE__'.

Returns string.

=head2 C<illustrators>

 my $illustrators_ar = $obj->illustrators;

Get list of illustrators.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<isbns>

 my $isbns_ar = $obj->isbns;

Get list of ISBNs.

Returns reference to array of MARC::Convert::Wikidata::Object::ISBN instances.

=head2 C<issn>

 my $issn = $obj->issn;

Get ISSN number.

Returns string.

=head2 c<krameriuses>

 my $kramerius_ar = $obj->krameriuses;

Get reference to array with Kramerius item objects.

Returns reference to array of MARC::Convert::Wikidata::Object::Kramerius instances.

=head2 C<languages>

 my $languages_ar = $obj->languages;

TODO

=head2 C<narrators>

 my $narrators_ar = $obj->narrators;

Get list of narrators.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<number_of_pages>

 my $number_of_pages = $obj->number_of_pages;

TODO

=head2 C<photographers>

 my $photographers_ar = $obj->photographers;

Get reference to array with photographers objects.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<publication_date>

 my $publication_date = $obj->publication_date;

TODO

=head2 C<publishers>

 my $publishers_ar = $obj->publishers;

Get list of publishing houses.

Returns reference to array of MARC::Convert::Wikidata::Object::Publisher instances.

=head2 C<series>

 my $series_ar = $obj->series;

Get reference to array with Serie item objects.

Returns reference to array of MARC::Convert::Wikidata::Object::Series instances.

=head2 C<start_time>

 my $start_time = $obj->start_time;

Get start time.

Returns number.

=head2 C<subtitle>

 my $subtitles_ar = $obj->subtitles;

Get reference to array with subtitles.

Returns reference to array of strings.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head2 C<translators>

 my $translators_ar = $obj->translators;

Get list of translators.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head1 ERRORS

 new():
         Book cover '%s' doesn't exist.
         Parameter 'end_time' must be a number.
         Parameter 'start_time' must be a number.
         From Mo::utils::check_isa():
                 Parameter 'edition_of_work' must be a 'MARC::Convert::Wikidata::Object::Work' object.
                         Value: %s
                         Reference: %s

         From Mo::utils::check_number():
                 Parameter '%s' must a number.
                         Value: %s

         From Mo::utils::Array::check_array():
                 Parameter 'languages' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'subtitles' must be a array.
                         Value: %s
                         Reference: %s

         From Mo::utils::Array::check_array_object():
                 Parameter 'authors' must be a array.
                 Parameter 'authors' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'authors_of_afterword' must be a array.
                 Parameter 'authors_of_afterword' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'authors_of_introduction' must be a array.
                 Parameter 'authors_of_introduction' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'compilers' must be a array.
                 Parameter 'compilers' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'cycles' must be a array.
                 Parameter 'cycles' with array must contain 'MARC::Convert::Wikidata::Object::Series' objects.
                 Parameter 'directors' must be a array.
                 Parameter 'directors' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'editors' must be a array.
                 Parameter 'editors' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'external_ids' must be a array.
                 Parameter 'external_ids' with array must contain 'MARC::Convert::Wikidata::Object::ExternalId' objects.
                 Parameter 'illustrators' must be a array.
                 Parameter 'illustrators' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'narrators' must be a array.
                 Parameter 'narrators' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.
                 Parameter 'publishers' must be a array.
                 Parameter 'publishers' with array must contain 'MARC::Convert::Wikidata::Object::Publisher' objects.
                 Parameter 'series' must be a array.
                 Parameter 'series' with array must contain 'MARC::Convert::Wikidata::Object::Series' objects.
                 Parameter 'translators' must be a array.
                 Parameter 'translators' with array must contain 'MARC::Convert::Wikidata::Object::People' objects.

=head1 EXAMPLE1

=for comment filename=create_and_dump_wikidata_object.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object;
 use MARC::Convert::Wikidata::Object::ExternalId;
 use MARC::Convert::Wikidata::Object::ISBN;
 use MARC::Convert::Wikidata::Object::People;
 use MARC::Convert::Wikidata::Object::Publisher;
 use MARC::Convert::Wikidata::Object::Work;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $aut = MARC::Convert::Wikidata::Object::People->new(
         'date_of_birth' => '1952-12-08',
         'external_ids' => [
                 MARC::Convert::Wikidata::Object::ExternalId->new(
                         'name' => 'nkcr_aut',
                         'value' => 'jn20000401266',
                 ),
         ],
         'name' => decode_utf8('Jiří'),
         'surname' => 'Jurok',
 );

 my $publisher = MARC::Convert::Wikidata::Object::Publisher->new(
         'name' => decode_utf8('Město Příbor'),
         'place' => decode_utf8('Příbor'),
 );

 my $isbn = MARC::Convert::Wikidata::Object::ISBN->new(
         'isbn' => '80-238-9541-9',
         'publisher' => $publisher,
 );

 my $obj = MARC::Convert::Wikidata::Object->new(
         'authors' => [$aut],
         'date_of_publication' => 2002,
         'edition_number' => 2,
         'edition_of_work' => MARC::Convert::Wikidata::Object::Work->new(
                 'title' => decode_utf8('Dějiny města Příbora'),
                 'title_language' => 'cze',
         ),
         'external_ids' => [
                 MARC::Convert::Wikidata::Object::ExternalId->new(
                         'name' => 'cnb',
                         'value' => 'cnb001188266',
                 ),
                 MARC::Convert::Wikidata::Object::ExternalId->new(
                         'name' => 'lccn',
                         'value' => '53860313',
                 ),
         ],
         'isbns' => [$isbn],
         'number_of_pages' => 414,
         'publishers' => [$publisher],
         'title' => decode_utf8('Dějiny města Příbora'),
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object  {
 #     parents: Mo::Object
 #     public methods (9):
 #         BUILD, full_name
 #         Error::Pure:
 #             err
 #         List::Util:
 #             none
 #         Mo::utils:
 #             check_isa, check_number
 #         Mo::utils::Array:
 #             check_array, check_array_object
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         authors               [
 #             [0] MARC::Convert::Wikidata::Object::People
 #         ],
 #         covers                [],
 #         date_of_publication   2002,
 #         edition_number        2,
 #         edition_of_work       MARC::Convert::Wikidata::Object::Work,
 #         external_ids          [
 #             [0] MARC::Convert::Wikidata::Object::ExternalId,
 #             [1] MARC::Convert::Wikidata::Object::ExternalId
 #         ],
 #         isbns                 [
 #             [0] MARC::Convert::Wikidata::Object::ISBN
 #         ],
 #         number_of_pages       414,
 #         publishers            [
 #             [0] MARC::Convert::Wikidata::Object::Publisher
 #         ],
 #         title                 "Dějiny města Příbora"
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::Array>,
L<Readonly>.

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

0.14

=cut
