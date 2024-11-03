package MARC::Convert::Wikidata::Item::BookEdition;

use base qw(MARC::Convert::Wikidata::Item);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;

our $VERSION = 0.17;

sub wikidata {
	my $self = shift;

	my $wikidata = Wikibase::Datatype::Item->new(
		$self->wikidata_labels,
		$self->wikidata_descriptions,
		'statements' => [
			# instance of: version, edition, or translation
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q3331189',
					),
					'property' => 'P31',
				),
			),

			$self->wikidata_authors,
			$self->wikidata_authors_of_afterword,
			$self->wikidata_authors_of_introduction,
			$self->wikidata_compilers,
			$self->wikidata_dml,
			$self->wikidata_edition_number,
			$self->wikidata_editors,
			$self->wikidata_end_time,
			$self->wikidata_external_ids,
			$self->wikidata_illustrators,
			$self->wikidata_isbn_10,
			$self->wikidata_isbn_13,
			$self->wikidata_krameriuses,
			$self->wikidata_language,
			$self->wikidata_number_of_pages,
			$self->wikidata_place_of_publication,
			$self->wikidata_photographers,
			$self->wikidata_publication_date,
			$self->wikidata_publishers,
			$self->wikidata_series,
			$self->wikidata_start_time,
			$self->wikidata_subtitles,
			$self->wikidata_title,
			$self->wikidata_translators,
		],
	);

	return $wikidata;
}

sub _description {
	my ($self, $lang) = @_;

	my $ret;
	if ($lang eq 'cs') {
		$ret = decode_utf8('české knižní vydání');
		if (defined $self->{'transform_object'}->publication_date) {
			$ret .= ' z roku '.$self->{'transform_object'}->publication_date;
		}

	} elsif ($lang eq 'en') {
		if (defined $self->{'transform_object'}->publication_date) {
			$ret = $self->{'transform_object'}->publication_date.' ';
		}
		$ret .= 'Czech book edition';
	}

	return $ret;
}

1;

__END__
