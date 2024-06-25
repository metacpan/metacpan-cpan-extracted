package MARC::Convert::Wikidata::Item;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime;
use English;
use Error::Pure qw(err);
use Mo::utils 0.08 qw(check_isa check_required);
use Scalar::Util qw(blessed);
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

our $VERSION = 0.09;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Cover callback.
	$self->{'callback_cover'} = undef;

	# Lang callback.
	$self->{'callback_lang'} = undef;

	# People callback.
	$self->{'callback_people'} = undef;

	# Place of publication Wikidata lookup callback.
	$self->{'callback_publisher_place'} = undef;

	# Publisher Wikidata lookup callback.
	$self->{'callback_publisher_name'} = undef;

	# Book series Wikidata lookup callback.
	$self->{'callback_series'} = undef;

	# Retrieved date.
	$self->{'date_retrieved'} = undef;

	# MARC::Record object.
	$self->{'marc_record'} = undef;

	# Transform object.
	$self->{'transform_object'} = undef;

	# Process parameters.
	set_params($self, @params);

	check_required($self, 'marc_record');
	check_isa($self, 'marc_record', 'MARC::Record');

	if (! defined $self->{'date_retrieved'}) {
		$self->{'date_retrieved'} = '+'.DateTime->now
			->truncate('to' => 'day')->iso8601().'Z';
	}

	return $self;
}

sub wikidata_authors {
	my $self = shift;

	return $self->wikidata_people('authors', 'P50');
}

sub wikidata_authors_of_afterword {
	my $self = shift;

	return $self->wikidata_people('authors_of_afterword', 'P2680');
}

sub wikidata_authors_of_introduction {
	my $self = shift;

	return $self->wikidata_people('authors_of_introduction', 'P2679');
}

sub wikidata_ccnb {
	my $self = shift;

	if (! defined $self->{'transform_object'}->ccnb) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'transform_object'}->ccnb,
				),
				'property' => 'P3184',
			),
		),
	);
}

sub wikidata_descriptions {
	my $self = shift;

	if (! defined $self->{'transform_object'}->full_name) {
		return ();
	}

	return (
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => $self->_description('cs'),
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => $self->_description('en'),
			),
		],
	);
}

sub wikidata_directors {
	my $self = shift;

	return $self->wikidata_people('directors', 'P57');
}

sub wikidata_edition_number {
	my $self = shift;

	if (! defined $self->{'transform_object'}->edition_number) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'transform_object'}->edition_number,
				),
				'property' => 'P393',
			),
		),
	);
}

sub wikidata_editors {
	my $self = shift;

	return $self->wikidata_people('editors', 'P98');
}

sub wikidata_end_time {
	my $self = shift;

	if (! defined $self->{'transform_object'}->end_time) {
		return;
	}

	# XXX end_time is every year? Probably not.
	my $end_time = $self->{'transform_object'}->end_time;

	return $self->_year($end_time, 'end time', 'P582');
}

sub wikidata_compilers {
	my $self = shift;

	my $property_snaks_ar = [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q29514511',
			),
			'property' => 'P3831',
		),
	];
	return $self->wikidata_people('compilers', 'P98', $property_snaks_ar);
}

sub wikidata_dml {
	my $self = shift;

	if (! defined $self->{'transform_object'}->dml) {
		return;
	}

	return Wikibase::Datatype::Statement->new(
		'references' => [$self->wikidata_reference],
		'snak' => Wikibase::Datatype::Snak->new(
			'datatype' => 'external-id',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => $self->{'transform_object'}->dml,
			),
			'property' => 'P11378',
		),
	);
}

sub wikidata_illustrators {
	my $self = shift;

	return $self->wikidata_people('illustrators', 'P110');
}

sub wikidata_isbn_10 {
	my $self = shift;

	if (! @{$self->{'transform_object'}->isbns}) {
		return;
	}

	my @ret;
	foreach my $isbn (@{$self->{'transform_object'}->isbns}) {
		if ($isbn->type != 10) {
			next;
		}
		my $publisher = $self->_isbn_publisher($isbn);
		my $cover_qid = $self->_isbn_cover($isbn);
		push @ret, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $isbn->isbn,
				),
				'property' => 'P957',
			),
			defined $publisher ? (
				'property_snaks' => [
					Wikibase::Datatype::Snak->new(
						'datatype' => 'wikibase-item',
						'datavalue' => Wikibase::Datatype::Value::Item->new(
							'value' => $publisher->[0],
						),
						'property' => 'P123',
					),
				],
			) : (),
			defined $cover_qid ? (
				'property_snaks' => [
					Wikibase::Datatype::Snak->new(
						'datatype' => 'wikibase-item',
						'datavalue' => Wikibase::Datatype::Value::Item->new(
							'value' => $cover_qid,
						),
						'property' => 'P437',
					),
				],
			) : (),
		);
	}

	return @ret;
}

sub wikidata_isbn_13 {
	my $self = shift;

	if (! @{$self->{'transform_object'}->isbns}) {
		return;
	}

	my @ret;
	foreach my $isbn (@{$self->{'transform_object'}->isbns}) {
		if ($isbn->type != 13) {
			next;
		}
		my $publisher = $self->_isbn_publisher($isbn);
		my $cover_qid = $self->_isbn_cover($isbn);
		push @ret, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $isbn->isbn,
				),
				'property' => 'P212',
			),
			defined $publisher ? (
				'property_snaks' => [
					Wikibase::Datatype::Snak->new(
						'datatype' => 'wikibase-item',
						'datavalue' => Wikibase::Datatype::Value::Item->new(
							'value' => $publisher->[0],
						),
						'property' => 'P123',
					),
				],
			) : (),
			defined $cover_qid ? (
				'property_snaks' => [
					Wikibase::Datatype::Snak->new(
						'datatype' => 'wikibase-item',
						'datavalue' => Wikibase::Datatype::Value::Item->new(
							'value' => $cover_qid,
						),
						'property' => 'P437',
					),
				],
			) : (),
		);
	}

	return @ret;
}

sub wikidata_issn {
	my $self = shift;

	if (! $self->{'transform_object'}->issn) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'transform_object'}->issn,
				),
				'property' => 'P236',
			),
		),
	);
}

sub wikidata_labels {
	my $self = shift;

	if (! defined $self->{'transform_object'}->full_name) {
		return ();
	}

	return (
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => $self->{'transform_object'}->full_name,
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => $self->{'transform_object'}->full_name,
			),
		],
	);
}

sub wikidata_language {
	my $self = shift;

	if (! @{$self->{'transform_object'}->languages}) {
		return;
	}

	if (! defined $self->{'callback_lang'}) {
		warn "No callback method for translation of language.\n";
		return;
	}

	my @language_qids;
	foreach my $lang (@{$self->{'transform_object'}->languages}) {
		my $language_qid = $self->{'callback_lang'}->($lang);
		if (defined $language_qid) {
			push @language_qids, $language_qid;
		}
	}

	my @lang;
	foreach my $language_qid (@language_qids) {
		push @lang, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $language_qid,
				),
				'property' => 'P407',
			),
		);
	}

	return @lang;
}

sub wikidata_krameriuses {
	my $self = shift;

	if (! defined $self->{'transform_object'}->krameriuses) {
		return;
	}

	my @krameriuses;
	foreach my $k (@{$self->{'transform_object'}->krameriuses}) {
		if ($k->kramerius_id eq 'mzk') {
			push @krameriuses, Wikibase::Datatype::Statement->new(
				'references' => [$self->wikidata_reference],
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $k->object_id,
					),
					'property' => 'P8752',
				),
			),
		} else {
			push @krameriuses, Wikibase::Datatype::Statement->new(
				'references' => [$self->wikidata_reference],
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'url',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $k->url,
					),
					'property' => 'P953',
				),
				# TODO Language of work or name: Czech
			),
		}
	}

	return @krameriuses;
}

sub wikidata_narrators {
	my $self = shift;

	return $self->wikidata_people('narrators', 'P2438');
}

sub wikidata_number_of_pages {
	my $self = shift;

	if (! defined $self->{'transform_object'}->number_of_pages) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'quantity',
				'datavalue' => Wikibase::Datatype::Value::Quantity->new(
					'unit' => 'Q1069725',
					'value' => $self->{'transform_object'}->number_of_pages,
				),
				'property' => 'P1104',
			),
		),
	);
}

sub wikidata_oclc {
	my $self = shift;

	if (! defined $self->{'transform_object'}->oclc) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'transform_object'}->oclc,
				),
				'property' => 'P243',
			),
		),
	);
}

sub wikidata_people {
	my ($self, $people_method, $people_property, $property_snaks_ar) = @_;

	if (! @{$self->{'transform_object'}->$people_method}) {
		return;
	}

	if (! defined $self->{'callback_people'}) {
		warn "No callback method for translation of people in '$people_method' method.\n";
		return;
	}

	my @people_qids;
	foreach my $people (@{$self->{'transform_object'}->$people_method}) {
		my $people_qid = $self->{'callback_people'}->($people);
		if (defined $people_qid) {
			push @people_qids, $people_qid;
		}
	}

	my @people;
	foreach my $people_qid (@people_qids) {
		push @people, Wikibase::Datatype::Statement->new(
			defined $property_snaks_ar ? (
				'property_snaks' => $property_snaks_ar,
			) : (),
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $people_qid,
				),
				'property' => $people_property,
			),
		),
	}

	return @people;
}

sub wikidata_photographers {
	my $self = shift;

	my $property_snaks_ar = [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q33231',
			),
			'property' => 'P3831',
		),
	];
	return $self->wikidata_people('photographers', 'P50', $property_snaks_ar);
}

sub wikidata_place_of_publication {
	my $self = shift;

	if (! @{$self->{'transform_object'}->publishers}) {
		return;
	}

	my @places;
	my $publication_date = $self->{'transform_object'}->publication_date;
	if (! defined $self->{'callback_publisher_place'}) {
		return;
	} else {
		foreach my $publisher (@{$self->{'transform_object'}->publishers}) {
			my $place_qid;
			# No concrete place.
			if ($publisher->place eq 'sine loco') {
				$place_qid = 'Q11254169';
			} else {
				$place_qid = $self->{'callback_publisher_place'}->($publisher);
			}
			my $publisher_qid = $self->{'callback_publisher_name'}->($publisher, $publication_date);
			if ($place_qid) {
				push @places, [$publisher_qid, $place_qid];
			}
		}
	}

	if (! @places) {
		return;
	}

	my $multiple = @places > 1 ? 1 : 0;
	return map {
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $_->[1],
				),
				'property' => 'P291',
			),
			$multiple ? (
				'property_snaks' => [
					Wikibase::Datatype::Snak->new(
						'datatype' => 'wikibase-item',
						'datavalue' => Wikibase::Datatype::Value::Item->new(
							'value' => $_->[0],
						),
						'property' => 'P123',
					),
				],
			) : (),
		);
	} @places;
}

sub wikidata_publication_date {
	my $self = shift;

	if (! defined $self->{'transform_object'}->publication_date) {
		return;
	}

	# TODO Second parameter of publication_date().

	# XXX Publication date is every year? Probably not.
	my $publication_date = $self->{'transform_object'}->publication_date;

	return $self->_year($publication_date, 'publication date', 'P577');
}

sub wikidata_publishers {
	my $self = shift;

	if (! @{$self->{'transform_object'}->publishers}) {
		return;
	}

	my @publisher_qids = $self->_publisher_translate(@{$self->{'transform_object'}->publishers});
	if (! @publisher_qids) {
		return;
	}

	my @publishers;
	foreach my $publisher_ar (@publisher_qids) {
		push @publishers, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $publisher_ar->[0],
				),
				'property' => 'P123',
			),
			'property_snaks' => [
				Wikibase::Datatype::Snak->new(
					'datatype' => 'string',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $publisher_ar->[1],
					),
					'property' => 'P1810',
				),
			],
		);
	}

	return @publishers;
}

sub wikidata_reference {
	my $self = shift;

	if (! defined $self->{'transform_object'}->ccnb) {
		err decode_utf8('Missing ČČNB id.');
	}
	return (
		Wikibase::Datatype::Reference->new(
			'snaks' => [
				# Stated in Czech National Bibliography
				Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q86914821',
					),
					'property' => 'P248',
				),

				# Czech National Bibliography book ID
				Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $self->{'transform_object'}->ccnb,
					),
					'property' => 'P3184',
				),

				# Retrieved.
				Wikibase::Datatype::Snak->new(
					'datatype' => 'time',
					'datavalue' => Wikibase::Datatype::Value::Time->new(
						'value' => $self->{'date_retrieved'},
					),
					'property' => 'P813',
				),
			],
		),
	);
}

sub wikidata_series {
	my $self = shift;

	if (! @{$self->{'transform_object'}->series}) {
		return;
	}

	my @series_qids;
	if (! defined $self->{'callback_series'}) {
		return;
	} else {
		foreach my $series (@{$self->{'transform_object'}->series}) {
			my $series_qid = $self->{'callback_series'}->($series);
			if ($series_qid) {
				push @series_qids, [
					$series_qid,
					$series->name,
					$series->series_ordinal,
				];
			}
		}
	}

	if (! @series_qids) {
		return;
	}

	my @series;
	foreach my $series_ar (@series_qids) {
		push @series, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $series_ar->[0],
				),
				'property' => 'P179',
			),
			'property_snaks' => [

				# Series ordinal.
				$series_ar->[2] ? (
					Wikibase::Datatype::Snak->new(
						'datatype' => 'string',
						'datavalue' => Wikibase::Datatype::Value::String->new(
							'value' => $series_ar->[2],
						),
						'property' => 'P1545',
					),
				) : (),
			],
		);
	}

	return @series;
}

sub wikidata_start_time {
	my $self = shift;

	if (! defined $self->{'transform_object'}->start_time) {
		return;
	}

	# XXX start_time is every year? Probably not.
	my $start_time = $self->{'transform_object'}->start_time;

	return $self->_year($start_time, 'start time', 'P580');
}

sub wikidata_subtitles {
	my $self = shift;

	if (! @{$self->{'transform_object'}->subtitles}) {
		return;
	}

	my @ret;
	foreach my $subtitle (@{$self->{'transform_object'}->subtitles}) {
		push @ret, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'language' => $self->_marc_lang_to_wd_lang,
					'value' => $subtitle,
				),
				'property' => 'P1680',
			),
		),
	}

	return @ret;
}

sub wikidata_title {
	my $self = shift;

	if (! defined $self->{'transform_object'}->title) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'language' => $self->_marc_lang_to_wd_lang,
					'value' => $self->{'transform_object'}->title,
				),
				'property' => 'P1476',
			),
		),
	);
}

sub wikidata_translators {
	my $self = shift;

	return $self->wikidata_people('translators', 'P655');
}

sub _description {
	my ($self, $lang) = @_;

	err "Method _description() is abstract, you need to implement.";
}

sub _isbn_publisher {
	my ($self, $isbn_o) = @_;

	if (! defined $isbn_o->publisher) {
		return;
	}

	my ($publisher) = $self->_publisher_translate(
		$isbn_o->publisher
	);
	if (! defined $publisher) {
		return;
	}

	return $publisher;
}

sub _isbn_cover {
	my ($self, $isbn_o) = @_;

	if (! defined $isbn_o->cover) {
		return;
	}

	return $self->_cover_translate($isbn_o->cover);
}

sub _marc_lang_to_wd_lang {
	my $self = shift;

	my $wd_lang;
	my $marc_lang = $self->{'transform_object'}->languages->[0];
	# TODO Common way. ISO 639-2 code for bibliography
	if ($marc_lang eq 'cze') {
		$wd_lang = 'cs';
	} elsif ($marc_lang eq 'eng') {
		$wd_lang = 'en';
	}

	return $wd_lang;
}

sub _publisher_translate {
	my ($self, @publishers) = @_;

	my @publisher_qids;
	my $publication_date = $self->{'transform_object'}->publication_date;
	if (! defined $self->{'callback_publisher_name'}) {
		return;
	} else {
		foreach my $publisher (@publishers) {
			my $publisher_qid = $self->{'callback_publisher_name'}->($publisher, $publication_date);
			if ($publisher_qid) {
				push @publisher_qids, [$publisher_qid, $publisher->name];
			}
		}
	}

	return @publisher_qids;
}

sub _cover_translate {
	my ($self, $cover) = @_;

	my $cover_qid;
	if (! defined $self->{'callback_cover'}) {
		return;
	} else {
		$cover_qid = $self->{'callback_cover'}->($cover);
	}

	return $cover_qid;
}

sub _year {
	my ($self, $year, $title, $property) = @_;

	my $value_dt = eval {
		DateTime->new(
			'year' => $year,
		);
	};
	if ($EVAL_ERROR) {
		return;
		err "Cannot process $title '$year'.",
			'Error', $EVAL_ERROR;
	}
	my $value = '+'.$value_dt->iso8601().'Z';
	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'time',
				'datavalue' => Wikibase::Datatype::Value::Time->new(
					# Precision for year.
					'precision' => 9,
					'value' => $value,
				),
				'property' => $property,
			),
		),
	);
}

1;

__END__
