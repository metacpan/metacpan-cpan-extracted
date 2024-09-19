package MARC::Convert::Wikidata::Item::Periodical;

use base qw(MARC::Convert::Wikidata::Item);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;

our $VERSION = 0.16;

sub wikidata {
	my $self = shift;

	my $wikidata = Wikibase::Datatype::Item->new(
		$self->wikidata_labels,
		$self->wikidata_descriptions,
		'statements' => [
			# instance of: book series
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q1002697',
					),
					'property' => 'P31',
				),
			),

			# TODO
			$self->wikidata_authors,
			$self->wikidata_authors_of_introduction,
			$self->wikidata_compilers,
			$self->wikidata_dml,
			$self->wikidata_edition_number,
			$self->wikidata_editors,
			$self->wikidata_end_time,
			$self->wikidata_external_ids,
			$self->wikidata_illustrators,
			$self->wikidata_issn,
			$self->wikidata_krameriuses,
			$self->wikidata_language,
			$self->wikidata_number_of_pages,
			$self->wikidata_place_of_publication,
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
		$ret = decode_utf8('české periodikum');

	} elsif ($lang eq 'en') {
		$ret = 'Czech periodical';
	}

	return $ret;
}

1;

__END__
