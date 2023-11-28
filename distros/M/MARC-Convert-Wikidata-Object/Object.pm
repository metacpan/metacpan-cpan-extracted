package MARC::Convert::Wikidata::Object;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(build default is);
use Mo::utils qw(check_array check_array_object check_number);
use Readonly;

Readonly::Array our @COVERS => qw(hardback paperback);

our $VERSION = 0.03;

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

has ccnb => (
	is => 'ro',
);

has compilers => (
	default => [],
	is => 'ro',
);

has cover => (
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

has editors => (
	default => [],
	is => 'ro',
);

has end_time => (
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

has oclc => (
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
	check_array_object($self, 'authors',
		'MARC::Convert::Wikidata::Object::People', 'Author');

	# Check authors of introduction.
	check_array_object($self, 'authors_of_afterword',
		'MARC::Convert::Wikidata::Object::People', 'Author of afterword');

	# Check authors of introduction.
	check_array_object($self, 'authors_of_introduction',
		'MARC::Convert::Wikidata::Object::People', 'Author of introduction');

	# Check compilers.
	check_array_object($self, 'compilers',
		'MARC::Convert::Wikidata::Object::People', 'Compiler');

	if (defined $self->{'cover'} && none { $_ eq $self->{'cover'} } @COVERS) {
		err "Book cover '".$self->{'cover'}."' doesn't exist.";
	}

	# Check directors.
	check_array_object($self, 'directors',
		'MARC::Convert::Wikidata::Object::People', 'Director');

	# Check dml id
	check_number($self, 'dml');

	# Check editors.
	check_array_object($self, 'editors',
		'MARC::Convert::Wikidata::Object::People', 'Editor');

	# Check end_time.
	check_number($self, 'end_time');

	# Check illustrators.
	check_array_object($self, 'illustrators',
		'MARC::Convert::Wikidata::Object::People', 'Illustrator');

	# Check isbns.
	check_array_object($self, 'isbns',
		'MARC::Convert::Wikidata::Object::ISBN', 'ISBN');

	# Check languages.
	check_array($self, 'languages');

	# Check Kramerius systems.
	check_array_object($self, 'krameriuses',
		'MARC::Convert::Wikidata::Object::Kramerius', 'Kramerius');

	# Check narrators.
	check_array_object($self, 'narrators',
		'MARC::Convert::Wikidata::Object::People', 'Narrator');

	# Check photographers.
	check_array_object($self, 'photographers',
		'MARC::Convert::Wikidata::Object::People', 'Photographers');

	# Check list of publishers.
	check_array_object($self, 'publishers',
		'MARC::Convert::Wikidata::Object::Publisher', 'Publisher');

	# Check series.
	check_array_object($self, 'series',
		'MARC::Convert::Wikidata::Object::Series', 'Book series');

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
 my $ccnb = $obj->ccnb;
 my $compilers = $obj->compilers;
 my $cover = $obj->cover;
 my $directors_ar = $obj->directors;
 my $dml = $obj->dml;
 my $edition_number = $obj->edition_number;
 my $editors_ar = $obj->editors;
 my $end_time = $obj->end_time;
 my $full_name = $obj->full_name;
 my $illustrators_ar = $obj->illustrators;
 my $isbns_ar = $obj->isbns;
 my $issn = $obj->issn;
 my $kramerius_ar = $obj->krameriuses;
 my $languages_ar = $obj->languages;
 my $narrators_ar = $obj->narrators;
 my $number_of_pages = $obj->number_of_pages;
 my $oclc = $obj->oclc;
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

=item * C<ccnb>

ČČNB (Česká národní bibliografie) id.

Default value is undef.

=item * C<compilers>

List of compilers.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<cover>

Book cover.
Possible values:
 * hardback
 * paperback

Default value is undef.

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

=item * C<editors>

List of editors.
Reference to array with MARC::Convert::Wikidata::Object::People instances.

Default value is reference to blank array.

=item * C<end_time>

End time.

Default value is undef.

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

=item * C<oclc>

OCLC control number.

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

=head2 C<ccnb>

 my $ccnb = $obj->ccnb;

Get ČČNB (Česká národní bibliografie) ID.

Returns string.

=head2 C<compilers>

 my $compilers_ar = $obj->compilers;

Get list of compilers.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<cover>

 my $cover = $obj->cover;

Get book cover.

Returns string (hardback or paperback).

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

=head2 C<editors>

 my $editors_ar = $obj->editors;

Get list of editors.

Returns reference to array of MARC::Convert::Wikidata::Object::People instances.

=head2 C<end_time>

 my $end_time = $obj->end_time;

Get end time.

Returns number.

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

=head2 C<oclc>

 my $oclc = $obj->oclc;

Get OCLC control number.

Returns string.

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
         From Mo::utils::check_array_object():
                 Author isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Author of afterword isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Author of introduction isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Book series isn't 'MARC::Convert::Wikidata::Object::Series' object.
                 Book cover '%s' doesn't exist.
                 Compiler isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Director isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Editor isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Illustrator isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Narrator isn't 'MARC::Convert::Wikidata::Object::People' object.
                 Parameter 'authors' must be a array.
                 Parameter 'authors_of_afterword' must be a array.
                 Parameter 'authors_of_introduction' must be a array.
                 Parameter 'compilers' must be a array.
                 Parameter 'directors' must be a array.
                 Parameter 'editors' must be a array.
                 Parameter 'end_time' must be a number.
                 Parameter 'illustrators' must be a array.
                 Parameter 'languages' must be a array.
                 Parameter 'narrators' must be a array.
                 Parameter 'publishers' must be a array.
                 Parameter 'series' must be a array.
                 Parameter 'start_time' must be a number.
                 Parameter 'translators' must be a array.
                 Publisher isn't 'MARC::Convert::Wikidata::Object::Publisher' object.
                 Translator isn't 'MARC::Convert::Wikidata::Object::People' object.

         From Mo::utils::check_number():
                 Parameter '%s' must a number.
                         Value: %s

=head1 EXAMPLE1

=for comment filename=create_and_dump_wikidata_object.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object;
 use MARC::Convert::Wikidata::Object::ISBN;
 use MARC::Convert::Wikidata::Object::People;
 use MARC::Convert::Wikidata::Object::Publisher;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $aut = MARC::Convert::Wikidata::Object::People->new(
         'date_of_birth' => '1952-12-08',
         'name' => decode_utf8('Jiří'),
         'nkcr_aut' => 'jn20000401266',
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
         'ccnb' => 'cnb001188266',
         'date_of_publication' => 2002,
         'edition_number' => 2,
         'isbns' => [$isbn],
         'number_of_pages' => 414,
         'publishers' => [$publisher],
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object  {
 #     Parents       Mo::Object
 #     public methods (11) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), full_name, check_array (Mo::utils), check_array_object (Mo::utils), isa (UNIVERSAL), none (List::MoreUtils::XS), Readonly (Readonly), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         authors                   [
 #             [0] MARC::Convert::Wikidata::Object::People
 #         ],
 #         authors_of_introduction   [],
 #         ccnb                      "cnb001188266",
 #         compilers                 [],
 #         date_of_publication       2002,
 #         edition_number            2,
 #         editors                   [],
 #         illustrators              [],
 #         isbns                     [
 #             [0] MARC::Convert::Wikidata::Object::ISBN
 #         ],
 #         krameriuses               [],
 #         number_of_pages           414,
 #         publishers                [
 #             [0] MARC::Convert::Wikidata::Object::Publisher
 #         ],
 #         series                    [],
 #         translators               []
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::MoreUtils>,
L<Mo>,
L<Mo::utils>,
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

© Michal Josef Špaček 2021-2023

BSD 2-Clause License

=head1 VERSION

0.03

=cut
