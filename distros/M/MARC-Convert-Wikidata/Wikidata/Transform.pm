package MARC::Convert::Wikidata::Transform;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Kramerius;
use Error::Pure qw(err);
use List::Util qw(any none);
use MARC::Convert::Wikidata::Object 0.10;
use MARC::Convert::Wikidata::Object::ExternalId 0.05;
use MARC::Convert::Wikidata::Object::ISBN;
use MARC::Convert::Wikidata::Object::Kramerius;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Object::Series 0.09;
use MARC::Convert::Wikidata::Utils qw(clean_cover clean_date clean_edition_number
	clean_issn clean_number_of_pages clean_oclc clean_publication_date
	clean_publisher_name clean_publisher_place clean_series_name clean_series_ordinal
	clean_subtitle clean_title);
use Readonly;
use Scalar::Util qw(blessed);
use URI;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

Readonly::Array our @COVERS => qw(hardback paperback);
Readonly::Hash our %PEOPLE_TYPE => {
	'aft' => 'authors_of_afterword',
	'aui' => 'authors_of_introduction',
	'aut' => 'authors',
	'com' => 'compilers',
	'drt' => 'directors',
	'edt' => 'editors',
	'ill' => 'illustrators',
	'nrt' => 'narrators',
	'pht' => 'photographers',
	'trl' => 'translators',
};

our $VERSION = 0.27;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# MARC::Record object.
	$self->{'marc_record'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'marc_record'}) {
		err "Parameter 'marc_record' is required.";
	}
	if (! blessed($self->{'marc_record'})
		|| ! $self->{'marc_record'}->isa('MARC::Record')) {

		err "Parameter 'marc_record' must be a MARC::Record object.";
	}

	$self->{'_kramerius'} = Data::Kramerius->new;

	# Process people in 100, 700.
	$self->{'_people'} = {
		'authors' => [],
		'authors_of_afterword' => [],
		'authors_of_introduction' => [],
		'compilers' => [],
		'directors' => [],
		'editors' => [],
		'illustrators' => [],
		'narrators' => [],
		'photographers' => [],
		'translators' => [],
	};
	$self->_process_people_100;
	$self->_process_people_700;

	$self->{'_object'} = undef;
	$self->_process_object;

	return $self;
}

sub object {
	my $self = shift;

	return $self->{'_object'};
}

sub _ccnb {
	my $self = shift;

	my @ret;

	my $ccnb = $self->_subfield('015', 'a');
	if (defined $ccnb) {
		push @ret, MARC::Convert::Wikidata::Object::ExternalId->new(
			'name' => 'cnb',
			'value' => $ccnb,
		);
	}

	my @depr_ccnb = $self->_subfield('015', 'z');
	foreach my $depr_ccnb (@depr_ccnb) {
		push @ret, MARC::Convert::Wikidata::Object::ExternalId->new(
			'deprecated' => 1,
			'name' => 'cnb',
			'value' => $depr_ccnb,
		);
	}

	return @ret;
}

sub _construct_kramerius {
	my ($self, $kramerius_uri) = @_;

	# XXX krameriusndk.nkp.cz is virtual project domain.
	$kramerius_uri =~ s/krameriusndk\.nkp\.cz/kramerius.mzk.cz/ms;

	my $u = URI->new($kramerius_uri);
	my $authority = $u->authority;
	foreach my $k ($self->{'_kramerius'}->list) {
		if ($k->url =~ m/$authority\/$/ms) {
			my @path_seg = $u->path_segments;
			my $uuid = $path_seg[-1];
			$uuid =~ s/^uuid://ms;
			return MARC::Convert::Wikidata::Object::Kramerius->new(
				'kramerius_id' => $k->id,
				'object_id' => $uuid,
				'url' => $kramerius_uri,
			);
		}
	}

	return;
}

sub _cover {
	my $self = shift;

	my @cover = $self->_subfield('020', 'q');
	my @ret_cover;
	foreach my $cover (@cover) {
		$cover = clean_cover($cover);
		if (! defined $cover) {
			next;
		}
		if ($cover eq 'hardback' || $cover eq 'paperback') {
			if (none { $_ eq $cover } @ret_cover) {
				push @ret_cover, $cover;
			}
		} elsif ($cover eq 'collective') {
			# nothing
		} else {
			warn encode_utf8("Book cover '$cover' doesn't exist.\n");
		}
	}

	if (@ret_cover > 1) {
		err 'Multiple book covers.',
			'List', (join ',', @ret_cover),
		;
	}

	return $ret_cover[0];
}

sub _cycles {
	my $self = shift;

	my @cycle_787 = $self->{'marc_record'}->field('787');
	my @cycles;
	foreach my $cycle_787 (@cycle_787) {
		my $marc_787i = $cycle_787->subfield('i');
		if (defined $marc_787i && $marc_787i =~ m/^Z cyklu:/ms) {
			my $cycle_name = $cycle_787->subfield('t');
			my $cycle_ordinal = $cycle_787->subfield('g');

			# XXX Over all publishers.
			foreach my $publisher ($self->_publishers) {
				push @cycles, MARC::Convert::Wikidata::Object::Series->new(
					'name' => $cycle_name,
					defined $publisher ? (
						'publisher' => $publisher,
					) : (),
					'series_ordinal' => $cycle_ordinal,
				);
			}
		}
	}

	return @cycles;
}

sub _dml {
	my $self = shift;

	my @fields_856 = $self->{'marc_record'}->field('856');
	foreach my $field_856 (@fields_856) {
		my $uri = $field_856->subfield('u');
		if ($uri =~ m/https:\/\/dml\.cz\/handle\/10338\.dmlcz\/(\d+)$/ms) {
			return $1;
		}
	}

	return;
}

sub _edition_number {
	my $self = shift;

	my $edition_number = $self->_subfield('250', 'a');
	if (! defined $edition_number) {
		return;
	}
	my $orig_edition_number = $edition_number;
	$edition_number = clean_edition_number($edition_number);

	if (! defined $edition_number) {
		warn encode_utf8("Edition number '$orig_edition_number' cannot clean.\n");
	} elsif ($edition_number !~ m/^\d+$/ms) {
		warn encode_utf8("Edition number '$edition_number' isn't number.\n");
	}

	return $edition_number;
}

sub _isbns {
	my $self = shift;

	my @isbn_fields = $self->{'marc_record'}->field('020');
	my @ret_isbns;
	foreach my $isbn_field (@isbn_fields) {
		my $isbn = $isbn_field->subfield('a');
		my $valid = 1;
		if (! defined $isbn) {
			$isbn = $isbn_field->subfield('z');
			if (! defined $isbn) {
				next;
			}
			$valid = 0;
		}
		my @publishers = $isbn_field->subfield('q');
		my ($publisher, $cover, $collective) = (undef, undef, 0);
		foreach my $pub (@publishers) {
			$pub = clean_cover($pub);
			if (! defined $pub) {
				next;
			}
			if (any { $pub eq $_ } @COVERS) {
				$cover = $pub;
			} elsif ($pub eq 'collective') {
				$collective = 1;
			} else {
				$publisher = $pub;
			}
		}
		my $isbn_o = MARC::Convert::Wikidata::Object::ISBN->new(
			'collective' => $collective,
			defined $cover ? (
				'cover' => $cover,
			) : (),
			'isbn' => $isbn,
			defined $publisher ? (
				'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
					'name' => clean_publisher_name($publisher),
				),
			) : (),
			'valid' => $valid,
		);
		if (defined $isbn_o) {
			push @ret_isbns, $isbn_o;
		}
	}

	return (@ret_isbns);
}

sub _issn {
	my $self = shift;

	my $issn = $self->_subfield('022', 'a');

	return $issn;
}

sub _krameriuses {
	my $self = shift;

	return map {
		$self->_construct_kramerius($_);
	} $self->_subfield('856', 'u');
}

sub _languages {
	my $self = shift;

	my @lang = $self->_subfield('041', 'a');
	if (! @lang) {
		push @lang, $self->_subfield('040', 'b');
	}

	return @lang;
}

sub _lccn {
	my $self = shift;

	my @ret;

	my @lccn = $self->_subfield('035', 'a');
	foreach my $lccn (@lccn) {
		$lccn = clean_oclc($lccn);
		push @ret, MARC::Convert::Wikidata::Object::ExternalId->new(
			'name' => 'lccn',
			'value' => $lccn,
		);
	}

	return @ret;
}

sub _number_of_pages {
	my $self = shift;

	my $number_of_pages = $self->_subfield('300', 'a');
	$number_of_pages = clean_number_of_pages($number_of_pages);

	return $number_of_pages;
}

sub _process_object {
	my $self = shift;

	my ($publication_date, $publication_date_option) = $self->_publication_date;
	my ($start_time, $end_time);
	if ($publication_date =~ m/^(\d+)\-(\d*)$/ms) {
		$start_time = $1;
		if ($2) {
			$end_time = $2;
		}
		undef $publication_date;
	}

	# TODO $publication_date_option; end_time; start_time
	$self->{'_object'} = MARC::Convert::Wikidata::Object->new(
		'authors' => $self->{'_people'}->{'authors'},
		'authors_of_afterword' => $self->{'_people'}->{'authors_of_afterword'},
		'authors_of_introduction' => $self->{'_people'}->{'authors_of_introduction'},
		'compilers' => $self->{'_people'}->{'compilers'},
		'cover' => $self->_cover,
		'cycles' => [$self->_cycles],
		'directors' => $self->{'_people'}->{'directors'},
		$self->_dml ? ('dml' => $self->_dml) : (),
		$self->_edition_number ? ('edition_number' => $self->_edition_number) : (),
		'editors' => $self->{'_people'}->{'editors'},
		'end_time' => $end_time,
		'external_ids' => [
			$self->_ccnb,
			$self->_lccn,
		],
		'isbns' => [$self->_isbns],
		'issn' => $self->_issn,
		'illustrators' => $self->{'_people'}->{'illustrators'},
		'krameriuses' => [$self->_krameriuses],
		'languages' => [$self->_languages],
		'narrators' => $self->{'_people'}->{'narrators'},
		'number_of_pages' => $self->_number_of_pages,
		'photographers' => $self->{'_people'}->{'photographers'},
		'publication_date' => $publication_date,
		'publishers' => [$self->_publishers],
		'series' => [$self->_series],
		'start_time' => $start_time,
		'subtitles' => [$self->_subtitles],
		'title' => $self->_title,
		'translators' => $self->{'_people'}->{'translators'},
	);

	return;
}

sub _process_people {
	my ($self, $field) = @_;

	my @types = $field->subfield('4');
	my @type_keys;
	foreach my $type (@types) {
		my $type_key = $self->_process_people_type($type);
		if (defined $type_key) {
			push @type_keys, $type_key;
		}
	}
	if (! @type_keys) {
		return;
	}

	my $full_name = $field->subfield('a');
	# TODO Only if type 1. Fix for type 0 and 2.
	my ($surname, $name) = split m/,\s*/ms, $full_name;

	my $nkcr_aut = $field->subfield('7');

	my $dates = $field->subfield('d');
	my ($date_of_birth, $date_of_death, $work_period_start, $work_period_end);
	if (defined $dates) {
		my $active_re = decode_utf8('činný');
		if ($dates =~ m/^$active_re\s*(.*)/ms) {
			my ($start_date, $end_date) = split m/-/ms, $1;
			$work_period_start = clean_date($start_date);
			$work_period_end = clean_date($end_date);
		} else {
			my ($start_date, $end_date) = split m/-/ms, $dates;
			$date_of_birth = clean_date($start_date);
			$date_of_death = clean_date($end_date);
		}
	}

	foreach my $type_key (@type_keys) {
		push @{$self->{'_people'}->{$type_key}},
			MARC::Convert::Wikidata::Object::People->new(
				'date_of_birth' => $date_of_birth,
				'date_of_death' => $date_of_death,
				defined $nkcr_aut ? (
					'external_ids' => [
						MARC::Convert::Wikidata::Object::ExternalId->new(
							'name' => 'nkcr_aut',
							'value' => $nkcr_aut,
						),
					],
				) : (),
				'work_period_start' => $work_period_start,
				'work_period_end' => $work_period_end,
				'name' => $name,
				'surname' => $surname,
			);
	}

	return;
}

sub _process_people_100 {
	my $self = shift;

	my @field_100 = $self->{'marc_record'}->field('100');
	foreach my $field (@field_100) {
		$self->_process_people($field);
	}

	return;
}

sub _process_people_700 {
	my $self = shift;

	my @field_700 = $self->{'marc_record'}->field('700');
	foreach my $field (@field_700) {
		$self->_process_people($field);
	}

	return;
}

sub _process_people_type {
	my ($self, $type) = @_;

	if (! defined $type || $type eq '') {
		warn "People type set to 'aut'.\n";
		$type = 'aut';
	}

	if (exists $PEOPLE_TYPE{$type}) {
		return $PEOPLE_TYPE{$type};
	} else {
		warn "People type '$type' doesn't exist.\n";
		return;
	}
}

sub _process_publisher_field {
	my ($self, $field_num) = @_;

	my $field = $self->{'marc_record'}->field($field_num);
	if (! defined $field) {
		return ();
	}
	my @publisher_names = $field->subfield('b');
	my @publishers;
	for (my $i = 0; $i < @publisher_names; $i++) {
		my $publisher_name = clean_publisher_name($publisher_names[$i]);

		my @places = $field->subfield('a');
		my $place;
		if (defined $places[$i]) {
			$place = $places[$i];
		} else {
			$place = $places[0];
		}
		$place = clean_publisher_place($place);

		push @publishers, MARC::Convert::Wikidata::Object::Publisher->new(
			'name' => $publisher_name,
			'place' => $place,
		);
	}

	return @publishers;
}

sub _publication_date {
	my $self = shift;

	my $publication_date = $self->_subfield('264', 'c');
	if (! $publication_date) {
		$publication_date = $self->_subfield('260', 'c');
	}

	my $option;
	($publication_date, $option) = clean_publication_date($publication_date);

	return wantarray ? ($publication_date, $option) : $publication_date;
}

sub _publishers {
	my $self = shift;

	my @publishers = $self->_process_publisher_field('260');
	push @publishers, $self->_process_publisher_field('264');

	return @publishers;
}

sub _series {
	my $self = shift;

	my @series_830 = $self->{'marc_record'}->field('830');

	my @series_490 = $self->{'marc_record'}->field('490');
	my @series;
	foreach my $series_490 (@series_490) {
		my $series_name = $series_490->subfield('a');
		$series_name = clean_series_name($series_name);
		my $series_ordinal = $series_490->subfield('v');
		$series_ordinal = clean_series_ordinal($series_ordinal);
		my $issn = $series_490->subfield('x');
		$issn = clean_issn($issn);

		# XXX Over all publishers.
		foreach my $publisher ($self->_publishers) {
			push @series, MARC::Convert::Wikidata::Object::Series->new(
				defined $issn ? (
					'issn' => $issn,
				) : (),
				'name' => $series_name,
				defined $publisher ? (
					'publisher' => $publisher,
				) : (),
				'series_ordinal' => $series_ordinal,
			);
		}
	}

	return @series;
}

sub _subfield {
	my ($self, $field, $subfield) = @_;

	my @ret;

	my @field_values = $self->{'marc_record'}->field($field);
	foreach my $field_value (@field_values) {
		my @subfield_values = $field_value->subfield($subfield);
		foreach my $subfield_value (@subfield_values) {
			push @ret, $subfield_value;
		}
	}

	return wantarray ? @ret : $ret[0];
}

sub _subtitles {
	my $self = shift;

	my @ret;
	my $subtitle = $self->_subfield('245', 'b');
	$subtitle = clean_subtitle($subtitle);
	if (defined $subtitle) {
		push @ret, $subtitle;
	}
	my $number_of_part = $self->_subfield('245', 'n');
	$number_of_part = clean_subtitle($number_of_part);
	if (defined $number_of_part) {
		push @ret, $number_of_part;
	}
	my $name_of_part = $self->_subfield('245', 'p');
	$name_of_part = clean_subtitle($name_of_part);
	if (defined $name_of_part) {
		push @ret, $name_of_part;
	}

	return @ret;
}

sub _title {
	my $self = shift;

	my $title = $self->_subfield('245', 'a');
	$title = clean_title($title);

	return $title;
}

1;

__END__
