package MARC::Convert::Wikidata::Item::BookEdition;

use base qw(MARC::Convert::Wikidata::Item);
use strict;
use warnings;

use Error::Pure qw(err);
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;

our $VERSION = 0.29;

sub wikidata {
	my $self = shift;

	my $instance_value = 'Q3331189';
	if ($self->wikidata_translators) {
		$instance_value = 'Q21112633';
	}

	my $wikidata = Wikibase::Datatype::Item->new(
		$self->wikidata_labels,
		$self->wikidata_descriptions,
		'statements' => [
			# instance of: version, edition, or translation
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => $instance_value,
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
	my @lang = @{$self->{'transform_object'}->languages};
	if ($lang eq 'cs') {
		if (@lang == 1 && $lang[0] eq 'cze') {
			$ret = decode_utf8('české');
		} elsif (@lang == 1 && $lang[0] eq 'slo') {
			$ret = decode_utf8('slovenské');
		} elsif (@lang > 1) {
			if (@lang == 2 && $lang[0] eq 'cze' && $lang[1] eq 'slo') {
				$ret = decode_utf8('česko-slovenské');
			} else {
				err "Multiple language description isn't supported.";
			}
		} else {
			err "Description for language '$lang[0]' isn't supported.";
		}
		if (length($ret) > 0) {
			$ret .= ' ';
		}
		$ret .= decode_utf8('knižní vydání');
		if (defined $self->{'transform_object'}->publication_date) {
			$ret .= ' z roku '.$self->{'transform_object'}->publication_date;
		} elsif (defined $self->{'transform_object'}->start_time) {
			# XXX cnb003591924
			if ($self->{'transform_object'}->start_time
				== $self->{'transform_object'}->end_time) {

				$ret .= ' z roku '.$self->{'transform_object'}->start_time;
			} else {
				$ret .= ' z let '.$self->{'transform_object'}->start_time.'-'.
					$self->{'transform_object'}->end_time;
			}
		}

	} elsif ($lang eq 'en') {
		if (defined $self->{'transform_object'}->publication_date) {
			$ret = $self->{'transform_object'}->publication_date.' ';
		} elsif (defined $self->{'transform_object'}->start_time) {
			# XXX cnb003591924
			if ($self->{'transform_object'}->start_time
				== $self->{'transform_object'}->end_time) {

				$ret = $self->{'transform_object'}->start_time.' ';
			} else {
				$ret = $self->{'transform_object'}->start_time.'-'.
					$self->{'transform_object'}->end_time.' ';
			}
		}
		if (@lang == 1 && $lang[0] eq 'cze') {
			$ret .= 'Czech';
		} elsif (@lang == 1 && $lang[0] eq 'slo') {
			$ret .= 'Slovak';
		} elsif (@lang > 1) {
			if (@lang == 2 && $lang[0] eq 'cze' && $lang[1] eq 'slo') {
				$ret .= 'Czech-Slovak';
			} else {
				err "Multiple language description isn't supported.";
			}
		} else {
			err "Description for language '$lang[0]' isn't supported.";
		}
		if (length($ret) > 0) {
			$ret .= ' ';
		}
		$ret .= 'book edition';
	}

	return $ret;
}

1;

__END__
