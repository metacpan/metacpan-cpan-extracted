package MARC::Convert::Wikidata::Utils;

use base qw(Exporter);
use strict;
use warnings;

use List::Util qw(none);
use Readonly;
use Roman;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(clean_cover clean_date clean_edition_number
	clean_number_of_pages clean_oclc clean_publication_date clean_publisher_name
	clean_publisher_place clean_series_name clean_series_ordinal clean_subtitle
	clean_title);
Readonly::Array our @COVERS => qw(hardback paperback);

our $VERSION = 0.01;
our $DEBUG = 0;

sub clean_cover {
	my $cover = shift;

	if (! defined $cover) {
		return;
	}

	my $ret_cover = $cover;
	$ret_cover =~ s/\s*:\s*$//ms;
	$ret_cover =~ s/^\s*//ms;
	$ret_cover =~ s/^\(\s*//ms;
	$ret_cover =~ s/\s*\)$//ms;
	my $c = decode_utf8('(v|V)áz');
	$ret_cover =~ s/^$c\.?$/hardback/ms;
	$c = decode_utf8('(v|V)ázáno');
	$ret_cover =~ s/^$c$/hardback/ms;
	$c = decode_utf8('(b|B)rož');
	$ret_cover =~ s/^$c\.?$/paperback/ms;
	$c = decode_utf8('(b|B)rožováno');
	$ret_cover =~ s/^$c$/paperback/ms;

	if (none { $ret_cover eq $_ } @COVERS) {
		if ($DEBUG) {
			warn "Book cover '$ret_cover' couldn't clean.";
		}
		$ret_cover = undef;
	}

	return $ret_cover;
}

sub clean_date {
	my $date = shift;

	if (! defined $date) {
		return;
	}
	if (! $date) {
		return;
	}

	my $months_hr = {
		'leden' => '01',
		decode_utf8('únor') => '02',
		decode_utf8('březen') => '03',
		'duben' => '04',
		decode_utf8('květen') => '05',
		decode_utf8('červen') => '06',
		decode_utf8('červenec') => '07',
		'srpen' => '08',
		decode_utf8('září') => '09',
		decode_utf8('říjen') => '10',
		'listopad' => '11',
		'prosinec' => '12',
	};

	my $ret_date = $date;
	foreach my $month (keys %{$months_hr}) {
		$ret_date =~ s/^(\d{4})\s*$month\s*(\d+)\.$/$1-$months_hr->{$month}-$2/ms;
	}
	my $bk = decode_utf8('př. Kr.');
	$ret_date =~ s/^(\d+)\s*$bk/-$1/ms;
	$ret_date =~ s/\s*\.$//ms;

	if ($ret_date !~ m/^\-?\d+(\-\d+)?(\-\d+)?$/ms) {
		if ($DEBUG) {
			warn "Date '$date' couldn't clean.";
		}
		$ret_date = undef;
	}

	return $ret_date;
}

sub clean_edition_number {
	my $edition_number = shift;

	if (! defined $edition_number) {
		return;
	}

	my $ret_edition_number = $edition_number;

	# Remove [] on begin and end.
	$ret_edition_number = _remove_square_brackets($ret_edition_number);

	# Remove trailing whitespace
	$ret_edition_number = _remove_trailing_whitespace($ret_edition_number);

	# Remove special meanings.
	$ret_edition_number =~ s/,//msg;
	$ret_edition_number =~ s/\s+a\s+//ms;

	# Edition.
	my $v1 = decode_utf8('Vydání');
	my $v2 = decode_utf8('vydání');
	$ret_edition_number =~ s/\s*(Vyd\.|vyd\.|$v1|$v2|Vydanie|vyd)//gx;

	$ret_edition_number =~ s/\s*rozmn\.//ms;
	my $re = decode_utf8('souborné');
	$ret_edition_number =~ s/\s*$re//ms;

	# Authorized.
	$ret_edition_number =~ s/\s*aut\.//ms;
	$ret_edition_number =~ s/\s*autoris\.//ms;
	$ret_edition_number =~ s/\s*autoriz\.//ms;
	$re = decode_utf8('autorisované');
	$ret_edition_number =~ s/\s*$re//ms;

	# Extended.
	$re = decode_utf8('přeprac');
	$ret_edition_number =~ s/\s*$re\.//ms;
	$re = decode_utf8('přepracované');
	$ret_edition_number =~ s/\s*$re//ms;
	$ret_edition_number =~ s/\s*aktualiz\.//ms;
	$re = decode_utf8('aktualizované');
	$ret_edition_number =~ s/\s*$re//ms;
	$ret_edition_number =~ s/\s*nezm\.//ms;
	$re = decode_utf8('rozšířené');
	$ret_edition_number =~ s/\s*$re//ms;
	$re = decode_utf8('rozš');
	$ret_edition_number =~ s/\s*$re\.?//ms;
	$ret_edition_number =~ s/\s*dopl\.//ms;
	$ret_edition_number =~ s/\s*dopln\.//ms;
	$re = decode_utf8('doplněné');
	$ret_edition_number =~ s/\s*$re//ms;
	$re = decode_utf8('upravené');
	$ret_edition_number =~ s/\s*$re//ms;
	$ret_edition_number =~ s/\s*upr\.//ms;
	$ret_edition_number =~ s/\s*opr\.//ms;
	$re = decode_utf8('revidované');
	$ret_edition_number =~ s/\s*$re//ms;

	# Czech.
	$re = decode_utf8('(v|V) českém jazyce');
	$ret_edition_number =~ s/\s*$re//ms;
	$re = decode_utf8('(Č|č)eské');
	$ret_edition_number =~ s/\s*$re//ms;
	$re = decode_utf8('(Č|č)es\.');
	$ret_edition_number =~ s/\s*$re//ms;
	$re = decode_utf8('(v|V) češtině\s*');
	$ret_edition_number =~ s/\s*$re//ms;

	# With illustration.
	$re = decode_utf8('s vyobrazeními');
	$ret_edition_number =~ s/\s*$re//ms;

	# Remove trailing whitespace
	$ret_edition_number = _remove_trailing_whitespace($ret_edition_number);

	# Rewrite number in Czech to number.
	my $dict_hr = {
		decode_utf8('První') => 1,
		decode_utf8('první') => 1,
		decode_utf8('prvé') => 1,
		decode_utf8('Druhé') => 2,
		decode_utf8('druhé') => 2,
		decode_utf8('Třetí') => 3,
		decode_utf8('třetí') => 3,
		decode_utf8('Čtvrté') => 4,
		decode_utf8('čtvrté') => 4,
		decode_utf8('Páté') => 5,
		decode_utf8('páté') => 5,
		decode_utf8('Šesté') => 6,
		decode_utf8('šesté') => 6,
		decode_utf8('Sedmé') => 7,
		decode_utf8('sedmé') => 7,
		decode_utf8('Osmé') => 8,
		decode_utf8('osmé') => 8,
		decode_utf8('Deváté') => 9,
		decode_utf8('deváté') => 9,
		decode_utf8('Desáté') => 10,
		decode_utf8('desáté') => 10,
		decode_utf8('Dvacáté') => 20,
		decode_utf8('dvacáté') => 20,
	};
	foreach my $origin (keys %{$dict_hr}) {
		$ret_edition_number =~ s/\s*$origin\s*/$dict_hr->{$origin}/ms;
	}

	# Remove dots.
	$ret_edition_number =~ s/\s*\.\s*//ms;

	# Remove :
	$ret_edition_number =~ s/\s*:\s*//ms;

	# Rename roman to arabic
	if (isroman($ret_edition_number)) {
		$ret_edition_number = arabic($ret_edition_number);
	}

	if ($ret_edition_number !~ m/^\d+$/ms) {
		if ($DEBUG) {
			warn "Edition number '$edition_number' couldn't clean ($ret_edition_number).";
		}
		$ret_edition_number = undef;
	}

	return $ret_edition_number;
}

sub clean_number_of_pages {
	my $number_of_pages = shift;

	if (! defined $number_of_pages) {
		return;
	}

	my $ret_number_of_pages = $number_of_pages;
	$ret_number_of_pages =~ s/^\[(\d+)\]/$1/ms;
	$ret_number_of_pages =~ s/^(\d+)\s*(s\.|stran).*$/$1/ms;

	if ($ret_number_of_pages !~ m/^\d+$/ms) {
		if ($DEBUG) {
			warn "Number of pages '$number_of_pages' couldn't clean.";
		}
		$ret_number_of_pages = undef;
	}

	return $ret_number_of_pages;
}

sub clean_oclc {
	my $oclc = shift;

	if (! defined $oclc) {
		return;
	}

	my $ret_oclc = $oclc;
	$ret_oclc =~ s/^\(OCoLC\)//ms;

	return $ret_oclc;
}

sub clean_publication_date {
	my $publication_date = shift;

	my $ret_publication_date = $publication_date;

	# Remove [] on begin and end.
	$ret_publication_date = _remove_square_brackets($ret_publication_date);

	my $option;
	if ($ret_publication_date =~ s/^c(.*)$/$1/ms
		|| $ret_publication_date =~ s/^(.*)\?$/$1/ms) {

		$option = 'circa';
	}

	if ($ret_publication_date !~ m/^\d+$/ms
		&& $ret_publication_date !~ m/^\d+\-\d*$/ms) {

		if ($DEBUG) {
			warn "Publication date '$publication_date' couldn't clean.";
		}
		$ret_publication_date = undef;
	}

	return ($ret_publication_date, $option);
}

sub clean_publisher_name {
	my $publisher_name = shift;

	if (! defined $publisher_name) {
		return;
	}

	my $ret_publisher_name = $publisher_name;

	# Trailing whitespace on begin and end
	$ret_publisher_name = _remove_trailing_whitespace($ret_publisher_name);

	# Separators on the end.
	$ret_publisher_name =~ s/\s*,$//g;
	$ret_publisher_name =~ s/\s*:$//g;
	$ret_publisher_name =~ s/\s*;$//g;

	# Remove ( from begin and not ending.
	$ret_publisher_name =~ s/^\(([^\)]+)$/$1/ms;

	# Remove [] on begin and end.
	$ret_publisher_name = _remove_square_brackets($ret_publisher_name);

	return $ret_publisher_name;
}

sub clean_publisher_place {
	my $publisher_place = shift;

	if (! defined $publisher_place) {
		return;
	}

	my $dict_hr = {
		'Blansku' => 'Blansko',
		decode_utf8('Č. Budějovice') => decode_utf8('České Budějovice'),
		'Plzni' => decode_utf8('Plzeň'),
		'Praze' => 'Praha',
		decode_utf8('Pardubicích') => 'Pardubice',
		decode_utf8('Brně') => 'Brno',
		decode_utf8('Jičíně') => decode_utf8('Jičín'),
		decode_utf8('Jihlavě') => 'Jihlava',
		decode_utf8('Jimramově') => 'Jimramov',
		decode_utf8('Karlových Varech') => 'Karlovy Vary',
		'Liberci' => 'Liberec',
		'Nymburce' => 'Nymburk',
		'Olomouci' => 'Olomouc',
		decode_utf8('Poděbradech') => decode_utf8('Poděbrady'),
		decode_utf8('Přerově') => decode_utf8('Přerov'),
		decode_utf8('Třebíč na Moravě') => decode_utf8('Třebíč'),
		decode_utf8('Třebíči') => decode_utf8('Třebíč'),
		decode_utf8('Třebíči na Moravě') => decode_utf8('Třebíč'),
		decode_utf8('Ostravě') => 'Ostrava',
		decode_utf8('Řevnicích') => decode_utf8('Řevnice'),
	};

	my $ret_publisher_place = $publisher_place;

	$ret_publisher_place =~ s/\s+$//g;
	$ret_publisher_place =~ s/\s*:$//g;
	$ret_publisher_place =~ s/\s*;$//g;

	# [V Praze]
	$ret_publisher_place =~ s/^\[(.*?)\]?$/$1/ms;

	$ret_publisher_place =~ s/^V\s+//ms;

	foreach my $origin (keys %{$dict_hr}) {
		$ret_publisher_place =~ s/^$origin$/$dict_hr->{$origin}/ms;
	}

	$ret_publisher_place =~ s/^V\s+([\s\w]+)$/$1/ms;
	# [Praha]
	$ret_publisher_place =~ s/^\[(.*?)\]$/$1/ms;

	return $ret_publisher_place;
}

sub clean_series_name {
	my $series_name = shift;

	if (! defined $series_name) {
		return;
	}

	my $ret_series_name = $series_name;

	# Trailing whitespace on begin and end
	$ret_series_name = _remove_trailing_whitespace($ret_series_name);

	$ret_series_name =~ s/\s*;$//g;
	$ret_series_name =~ s/\s*:$//g;

	# Remove [] on begin and end.
	$ret_series_name = _remove_square_brackets($ret_series_name);

	return $ret_series_name;
}

sub clean_series_ordinal {
	my $series_ordinal = shift;

	if (! defined $series_ordinal) {
		return;
	}

	my $ret_series_ordinal = $series_ordinal;

	# Trailing whitespace on begin and end
	$ret_series_ordinal = _remove_trailing_whitespace($ret_series_ordinal);

	$ret_series_ordinal =~ s/^(S|s)v\.\s*//g;
	$ret_series_ordinal =~ s/^svazek\s*//g;
	$ret_series_ordinal =~ s/\s*svazek$//g;

	my $c = decode_utf8('(č|Č)');
	$ret_series_ordinal =~ s/^$c\.\s*//ms;
	$c = decode_utf8('(č|Č)íslo');
	$ret_series_ordinal =~ s/^$c\s*//ms;

	$ret_series_ordinal =~ s/^(\d+)\.$/$1/ms;

	if ($ret_series_ordinal =~ m/^(\d+)-(\d+)$/ms) {
		my $first = $1;
		my $second = $2;
		if ($second < $first) {
			my $first_len = length $first;
			my $second_len = length $second;
			my $first_addition = substr $first, 0, ($first_len - $second_len);
			$ret_series_ordinal = $first.'-'.$first_addition.$second;
		}
	}

	return $ret_series_ordinal;
}

sub clean_subtitle {
	my $subtitle = shift;

	if (! defined $subtitle) {
		return;
	}

	my $ret_subtitle = $subtitle;
	$ret_subtitle =~ s/\s+$//g;
	$ret_subtitle =~ s/\/$//g;
	$ret_subtitle =~ s/\s+$//g;
	$ret_subtitle =~ s/,$//g;

	return $ret_subtitle;
}

sub clean_title {
	my $title = shift;

	if (! defined $title) {
		return;
	}

	my $ret_title = $title;
	$ret_title =~ s/\s+$//g;
	$ret_title =~ s/\s*\/$//g;
	$ret_title =~ s/\s*\:$//g;
	$ret_title =~ s/\.$//g;

	return $ret_title;
}

sub _remove_trailing_whitespace {
	my $string = shift;

	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;

	return $string;
}

sub _remove_square_brackets {
	my $string = shift;

	$string =~ s/^\[\s*(.*?)\s*\]$/$1/ms;
	$string =~ s/^\[\s*([^\]]+)$/$1/ms;

	return $string;
}

1;

__END__
