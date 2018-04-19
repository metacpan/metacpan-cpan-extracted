=head1

Locale::CLDR::Locales::Hu - Package for language Hungarian

=cut

package Locale::CLDR::Locales::Hu;
# This file auto generated from Data\common\main\hu.xml
#	on Fri 13 Apr  7:13:41 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-cardinal-verbose','spellout-ordinal','spellout-ordinal-verbose' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínusz →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← egész →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(egy),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kettő),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(három),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(négy),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(öt),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(hat),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(hét),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(nyolc),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(kilenc),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tíz),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(tizen­→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(húsz),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(huszon­→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(harminc[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(negyven[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ötven[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(hatvan[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(hetven[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(nyolcvan[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(kilencven[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(száz[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-cardinal-initial←­száz[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ezer[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-initial←­ezer[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-initial← millió[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-initial← milliárd[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-initial← billió[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-initial← billiárd[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-initial' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(egy),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(két),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-cardinal-verbose' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínusz →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← egész →→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←­száz[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←­ezer[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← millió[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← milliárd[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← billió[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← billiárd[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínusz →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←←­száz[­→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínusz →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(első),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(második),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
			},
		},
		'spellout-ordinal-adik' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(adik),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
			},
		},
		'spellout-ordinal-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(edik),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(egyedik),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kettedik),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(harmadik),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(negyedik),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ötödik),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(hatodik),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(hetedik),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(nyolcadik),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(kilencedik),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tizedik),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(tizen→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(huszadik),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(huszon→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(harminc→%%spellout-ordinal-adik→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(negyven→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ötven→→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(hatvan→%%spellout-ordinal-adik→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(hetven→→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(nyolcvan→%%spellout-ordinal-adik→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(kilencven→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(száz→%%spellout-ordinal-adik→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-cardinal-initial←száz→%%spellout-ordinal-adik→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ezr→→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-initial←ezr→→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-initial← milliom→%%spellout-ordinal-odik→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-odik' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(odik),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
			},
		},
		'spellout-ordinal-verbose' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínusz →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(első),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(második),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
			},
		},
		'spellout-ordinal-verbose-adik' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(adik),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
			},
		},
		'spellout-ordinal-verbose-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-larger=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-verbose←száz→%%spellout-ordinal-verbose-adik→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-verbose←ezr→→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-verbose← milliom→%%spellout-ordinal-verbose-odik→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-verbose-odik' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(odik),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-verbose-larger=),
				},
			},
		},
	} },
);

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'aa' => 'afar',
 				'ab' => 'abház',
 				'ace' => 'achinéz',
 				'ach' => 'akoli',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'ae' => 'avesztán',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'agem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkád',
 				'ale' => 'aleut',
 				'alt' => 'dél-altaji',
 				'am' => 'amhara',
 				'an' => 'aragonéz',
 				'ang' => 'óangol',
 				'anp' => 'angika',
 				'ar' => 'arab',
 				'ar_001' => 'modern szabányos arab',
 				'arc' => 'arámi',
 				'arn' => 'mapucse',
 				'arp' => 'arapaho',
 				'arw' => 'aravak',
 				'as' => 'asszámi',
 				'asa' => 'asu',
 				'ast' => 'asztúr',
 				'av' => 'avar',
 				'awa' => 'awádi',
 				'ay' => 'ajmara',
 				'az' => 'azerbajdzsáni',
 				'az@alt=short' => 'azeri',
 				'ba' => 'baskír',
 				'bal' => 'balucsi',
 				'ban' => 'balinéz',
 				'bas' => 'basza',
 				'bax' => 'bamun',
 				'bbj' => 'gomala',
 				'be' => 'belarusz',
 				'bej' => 'bedzsa',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bolgár',
 				'bgn' => 'nyugati beludzs',
 				'bho' => 'bodzspuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bangla',
 				'bo' => 'tibeti',
 				'br' => 'breton',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosnyák',
 				'bss' => 'koszi',
 				'bua' => 'burját',
 				'bug' => 'buginéz',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'katalán',
 				'cad' => 'caddo',
 				'car' => 'karib',
 				'cay' => 'kajuga',
 				'cch' => 'atszam',
 				'ce' => 'csecsen',
 				'ceb' => 'szebuano',
 				'cgg' => 'kiga',
 				'ch' => 'csamoró',
 				'chb' => 'csibcsa',
 				'chg' => 'csagatáj',
 				'chk' => 'csukéz',
 				'chm' => 'mari',
 				'chn' => 'csinuk zsargon',
 				'cho' => 'csoktó',
 				'chp' => 'csipevé',
 				'chr' => 'cseroki',
 				'chy' => 'csejen',
 				'ckb' => 'közép-ázsiai kurd',
 				'co' => 'korzikai',
 				'cop' => 'kopt',
 				'cr' => 'krí',
 				'crh' => 'krími tatár',
 				'crs' => 'szeszelva kreol francia',
 				'cs' => 'cseh',
 				'csb' => 'kasub',
 				'cu' => 'egyházi szláv',
 				'cv' => 'csuvas',
 				'cy' => 'walesi',
 				'da' => 'dán',
 				'dak' => 'dakota',
 				'dar' => 'dargva',
 				'dav' => 'taita',
 				'de' => 'német',
 				'de_AT' => 'osztrák német',
 				'de_CH' => 'svájci felnémet',
 				'del' => 'delavár',
 				'den' => 'szlevi',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'alsó-szorb',
 				'dua' => 'duala',
 				'dum' => 'közép holland',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'diula',
 				'dz' => 'dzsonga',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efik',
 				'egy' => 'óegyiptomi',
 				'eka' => 'ekadzsuk',
 				'el' => 'görög',
 				'elx' => 'elamit',
 				'en' => 'angol',
 				'en_AU' => 'ausztrál angol',
 				'en_CA' => 'kanadai angol',
 				'en_GB' => 'brit angol',
 				'en_GB@alt=short' => 'angol (UK)',
 				'en_US' => 'amerikai angol',
 				'en_US@alt=short' => 'angol (USA)',
 				'enm' => 'közép angol',
 				'eo' => 'eszperantó',
 				'es' => 'spanyol',
 				'es_419' => 'latin-amerikai spanyol',
 				'es_ES' => 'európai spanyol',
 				'es_MX' => 'spanyol (mexikói)',
 				'et' => 'észt',
 				'eu' => 'baszk',
 				'ewo' => 'evondo',
 				'fa' => 'perzsa',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulani',
 				'fi' => 'finn',
 				'fil' => 'filippínó',
 				'fj' => 'fidzsi',
 				'fo' => 'feröeri',
 				'fon' => 'fon',
 				'fr' => 'francia',
 				'fr_CA' => 'kanadai francia',
 				'fr_CH' => 'svájci francia',
 				'frc' => 'cajun francia',
 				'frm' => 'közép francia',
 				'fro' => 'ófrancia',
 				'frr' => 'északi fríz',
 				'frs' => 'keleti fríz',
 				'fur' => 'friuli',
 				'fy' => 'nyugati fríz',
 				'ga' => 'ír',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gan' => 'gan kínai',
 				'gay' => 'gajo',
 				'gba' => 'gbaja',
 				'gd' => 'skóciai kelta',
 				'gez' => 'geez',
 				'gil' => 'ikiribati',
 				'gl' => 'gallego',
 				'gmh' => 'közép felső német',
 				'gn' => 'guarani',
 				'goh' => 'ófelső német',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gót',
 				'grb' => 'grebó',
 				'grc' => 'ógörög',
 				'gsw' => 'svájci német',
 				'gu' => 'gudzsaráti',
 				'guz' => 'guszii',
 				'gv' => 'man-szigeti',
 				'gwi' => 'gvicsin',
 				'ha' => 'hausza',
 				'hai' => 'haida',
 				'hak' => 'hakka kínai',
 				'haw' => 'hawaii',
 				'he' => 'héber',
 				'hi' => 'hindi',
 				'hil' => 'ilokano',
 				'hit' => 'hittite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'horvát',
 				'hsb' => 'felső-szorb',
 				'hsn' => 'xiang kínai',
 				'ht' => 'haiti kreol',
 				'hu' => 'magyar',
 				'hup' => 'hupa',
 				'hy' => 'örmény',
 				'hz' => 'herero',
 				'ia' => 'interlingva',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonéz',
 				'ie' => 'interlingue',
 				'ig' => 'igbó',
 				'ii' => 'szecsuán ji',
 				'ik' => 'inupiak',
 				'ilo' => 'ilokó',
 				'inh' => 'ingus',
 				'io' => 'idó',
 				'is' => 'izlandi',
 				'it' => 'olasz',
 				'iu' => 'inuktitut',
 				'ja' => 'japán',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'zsidó-perzsa',
 				'jrb' => 'zsidó-arab',
 				'jv' => 'jávai',
 				'ka' => 'grúz',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabije',
 				'kac' => 'kacsin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardi',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'kaszi',
 				'kho' => 'kotanéz',
 				'khq' => 'kojra-csíni',
 				'ki' => 'kikuju',
 				'kj' => 'kuanyama',
 				'kk' => 'kazah',
 				'kkj' => 'kakó',
 				'kl' => 'grönlandi',
 				'kln' => 'kalendzsin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreai',
 				'koi' => 'komi-permják',
 				'kok' => 'konkani',
 				'kos' => 'kosrei',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karacsáj-balkár',
 				'krl' => 'karelai',
 				'kru' => 'kuruh',
 				'ks' => 'kasmíri',
 				'ksb' => 'sambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurd',
 				'kum' => 'kumük',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'korni',
 				'ky' => 'kirgiz',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgi',
 				'lez' => 'lezg',
 				'lg' => 'ganda',
 				'li' => 'limburgi',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongó',
 				'lou' => 'louisianai kreol',
 				'loz' => 'lozi',
 				'lrc' => 'északi luri',
 				'lt' => 'litván',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'lujia',
 				'lv' => 'lett',
 				'mad' => 'madurai',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makaszar',
 				'man' => 'mandingó',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'moksán',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauritiusi kreol',
 				'mg' => 'malgas',
 				'mga' => 'közép ír',
 				'mgh' => 'makua-metó',
 				'mgo' => 'meta’',
 				'mh' => 'marshalli',
 				'mi' => 'maori',
 				'mic' => 'mikmak',
 				'min' => 'minangkabau',
 				'mk' => 'macedón',
 				'ml' => 'malajálam',
 				'mn' => 'mongol',
 				'mnc' => 'mandzsu',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'moszi',
 				'mr' => 'maráthi',
 				'ms' => 'maláj',
 				'mt' => 'máltai',
 				'mua' => 'mundang',
 				'mul' => 'többszörös nyelvek',
 				'mus' => 'krík',
 				'mwl' => 'mirandéz',
 				'mwr' => 'márvári',
 				'my' => 'burmai',
 				'mye' => 'myene',
 				'myv' => 'erzjány',
 				'mzn' => 'mázanderáni',
 				'na' => 'naurui',
 				'nan' => 'min nan kínai',
 				'nap' => 'nápolyi',
 				'naq' => 'nama',
 				'nb' => 'norvég (bokmål)',
 				'nd' => 'északi ndebele',
 				'nds' => 'alsónémet',
 				'nds_NL' => 'alsószász',
 				'ne' => 'nepáli',
 				'new' => 'nevari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niuei',
 				'nl' => 'holland',
 				'nl_BE' => 'flamand',
 				'nmg' => 'ngumba',
 				'nn' => 'norvég (nynorsk)',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvég',
 				'nog' => 'nogaj',
 				'non' => 'óskandináv',
 				'nqo' => 'n’kó',
 				'nr' => 'déli ndebele',
 				'nso' => 'északi szeszotó',
 				'nus' => 'nuer',
 				'nv' => 'navahó',
 				'nwc' => 'klasszikus newari',
 				'ny' => 'nyandzsa',
 				'nym' => 'nyamvézi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoró',
 				'nzi' => 'nzima',
 				'oc' => 'okszitán',
 				'oj' => 'ojibva',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'oszét',
 				'osa' => 'osage',
 				'ota' => 'ottomán török',
 				'pa' => 'pandzsábi',
 				'pag' => 'pangaszinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampangan',
 				'pap' => 'papiamento',
 				'pau' => 'palaui',
 				'pcm' => 'nigériai pidgin',
 				'peo' => 'óperzsa',
 				'phn' => 'főniciai',
 				'pi' => 'pali',
 				'pl' => 'lengyel',
 				'pon' => 'pohnpei',
 				'prg' => 'porosz',
 				'pro' => 'óprovánszi',
 				'ps' => 'pastu',
 				'pt' => 'portugál',
 				'pt_BR' => 'brazíliai portugál',
 				'pt_PT' => 'európai portugál',
 				'qu' => 'kecsua',
 				'quc' => 'kicse',
 				'raj' => 'radzsasztáni',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongai',
 				'rm' => 'rétoromán',
 				'rn' => 'kirundi',
 				'ro' => 'román',
 				'ro_MD' => 'moldvai',
 				'rof' => 'rombo',
 				'rom' => 'roma',
 				'root' => 'ősi',
 				'ru' => 'orosz',
 				'rup' => 'aromán',
 				'rw' => 'kinyarvanda',
 				'rwk' => 'rwo',
 				'sa' => 'szanszkrit',
 				'sad' => 'szandave',
 				'sah' => 'szaha',
 				'sam' => 'szamaritánus arámi',
 				'saq' => 'szamburu',
 				'sas' => 'sasak',
 				'sat' => 'szantáli',
 				'sba' => 'ngambay',
 				'sbp' => 'szangu',
 				'sc' => 'szardíniai',
 				'scn' => 'szicíliai',
 				'sco' => 'skót',
 				'sd' => 'szindhi',
 				'sdh' => 'dél-kurd',
 				'se' => 'északi számi',
 				'see' => 'szeneka',
 				'seh' => 'szena',
 				'sel' => 'szölkup',
 				'ses' => 'kojra-szenni',
 				'sg' => 'szangó',
 				'sga' => 'óír',
 				'sh' => 'szerbhorvát',
 				'shi' => 'tachelhit',
 				'shn' => 'san',
 				'shu' => 'csádi arab',
 				'si' => 'szingaléz',
 				'sid' => 'szidamó',
 				'sk' => 'szlovák',
 				'sl' => 'szlovén',
 				'sm' => 'szamoai',
 				'sma' => 'déli számi',
 				'smj' => 'lulei számi',
 				'smn' => 'inari számi',
 				'sms' => 'kolta számi',
 				'sn' => 'sona',
 				'snk' => 'szoninke',
 				'so' => 'szomáli',
 				'sog' => 'sogdien',
 				'sq' => 'albán',
 				'sr' => 'szerb',
 				'srn' => 'szranai tongó',
 				'srr' => 'szerer',
 				'ss' => 'sziszuati',
 				'ssy' => 'szahó',
 				'st' => 'déli szeszotó',
 				'su' => 'szundanéz',
 				'suk' => 'szukuma',
 				'sus' => 'szuszu',
 				'sux' => 'sumér',
 				'sv' => 'svéd',
 				'sw' => 'szuahéli',
 				'sw_CD' => 'kongói szuahéli',
 				'swb' => 'comorei',
 				'syc' => 'klasszikus szír',
 				'syr' => 'szír',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teszó',
 				'ter' => 'terenó',
 				'tet' => 'tetum',
 				'tg' => 'tadzsik',
 				'th' => 'thai',
 				'ti' => 'tigrinya',
 				'tig' => 'tigré',
 				'tiv' => 'tiv',
 				'tk' => 'türkmén',
 				'tkl' => 'tokelaui',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tmh' => 'tamasek',
 				'tn' => 'szecsuáni',
 				'to' => 'tongai',
 				'tog' => 'nyugati nyasza',
 				'tpi' => 'tok pisin',
 				'tr' => 'török',
 				'trv' => 'tarokó',
 				'ts' => 'conga',
 				'tsi' => 'csimsiáni',
 				'tt' => 'tatár',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'szavák',
 				'ty' => 'tahiti',
 				'tyv' => 'tuvai',
 				'tzm' => 'közép-atlaszi tamazigt',
 				'udm' => 'udmurt',
 				'ug' => 'ujgur',
 				'uga' => 'ugariti',
 				'uk' => 'ukrán',
 				'umb' => 'umbundu',
 				'und' => 'ismeretlen nyelv',
 				'ur' => 'urdu',
 				'uz' => 'üzbég',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnami',
 				'vo' => 'volapük',
 				'vot' => 'votják',
 				'vun' => 'vunjo',
 				'wa' => 'vallon',
 				'wae' => 'walser',
 				'wal' => 'valamo',
 				'war' => 'varaó',
 				'was' => 'vasó',
 				'wbp' => 'warlpiri',
 				'wo' => 'volof',
 				'wuu' => 'wu kínai',
 				'xal' => 'kalmük',
 				'xh' => 'xhosza',
 				'xog' => 'szoga',
 				'yao' => 'jaó',
 				'yap' => 'japi',
 				'yav' => 'jangben',
 				'ybb' => 'jemba',
 				'yi' => 'jiddis',
 				'yo' => 'joruba',
 				'yue' => 'kantoni',
 				'za' => 'zsuang',
 				'zap' => 'zapoték',
 				'zbl' => 'Bliss jelképrendszer',
 				'zen' => 'zenaga',
 				'zgh' => 'marokkói tamazight',
 				'zh' => 'kínai',
 				'zh_Hans' => 'egyszerűsített kínai',
 				'zh_Hant' => 'hagyományos kínai',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'nincs nyelvészeti tartalom',
 				'zza' => 'zaza',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Arab' => 'Arab',
 			'Arab@alt=variant' => 'Perzsa-arab',
 			'Armi' => 'Birodalmi arámi',
 			'Armn' => 'Örmény',
 			'Avst' => 'Avesztán',
 			'Bali' => 'Balinéz',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengáli',
 			'Blis' => 'Bliss jelképrendszer',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brámi',
 			'Brai' => 'Vakírás',
 			'Bugi' => 'Buginéz',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Csakma',
 			'Cans' => 'Egyesített kanadai őslakos jelek',
 			'Cari' => 'Kari',
 			'Cham' => 'Csám',
 			'Cher' => 'Cseroki',
 			'Copt' => 'Kopt',
 			'Cprt' => 'Ciprusi',
 			'Cyrl' => 'Cirill',
 			'Cyrs' => 'Óegyházi szláv cirill',
 			'Deva' => 'Devanagári',
 			'Dsrt' => 'Deseret',
 			'Egyd' => 'Egyiptomi demotikus',
 			'Egyh' => 'Egyiptomi hieratikus',
 			'Egyp' => 'Egyiptomi hieroglifák',
 			'Ethi' => 'Etióp',
 			'Geok' => 'Grúz kucsuri',
 			'Geor' => 'Grúz',
 			'Glag' => 'Glagolitikus',
 			'Goth' => 'Gót',
 			'Grek' => 'Görög',
 			'Gujr' => 'Gudzsaráti',
 			'Guru' => 'Gurmuki',
 			'Hanb' => 'Hanb',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Egyszerűsített',
 			'Hans@alt=stand-alone' => 'Egyszerűsített kínai',
 			'Hant' => 'Hagyományos',
 			'Hant@alt=stand-alone' => 'Hagyományos kínai',
 			'Hebr' => 'Héber',
 			'Hira' => 'Hiragana',
 			'Hmng' => 'Pahawh hmong',
 			'Hrkt' => 'Katakana vagy hiragana',
 			'Hung' => 'Ómagyar',
 			'Inds' => 'Indus',
 			'Ital' => 'Régi olasz',
 			'Jamo' => 'Jamo',
 			'Java' => 'Jávai',
 			'Jpan' => 'Japán',
 			'Kali' => 'Kajah li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreai',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latf' => 'Fraktur latin',
 			'Latg' => 'Gael latin',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Lineáris A',
 			'Linb' => 'Lineáris B',
 			'Lyci' => 'Líciai',
 			'Lydi' => 'Lídiai',
 			'Mand' => 'Mandai',
 			'Mani' => 'Manicheus',
 			'Maya' => 'Maja hieroglifák',
 			'Mero' => 'Meroitikus',
 			'Mlym' => 'Malajálam',
 			'Mong' => 'Mongol',
 			'Moon' => 'Moon',
 			'Mtei' => 'Meitei mayek',
 			'Mymr' => 'Burmai',
 			'Nkoo' => 'N’ko',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol chiki',
 			'Orkh' => 'Orhon',
 			'Orya' => 'Oriya',
 			'Osma' => 'Oszmán',
 			'Perm' => 'Ópermikus',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Felriatos pahlavi',
 			'Phlp' => 'Psalter pahlavi',
 			'Phlv' => 'Könyv pahlavi',
 			'Phnx' => 'Főniciai',
 			'Plrd' => 'Pollard fonetikus',
 			'Prti' => 'Feliratos parthian',
 			'Rjng' => 'Redzsang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runikus',
 			'Samr' => 'Szamaritán',
 			'Sara' => 'Szarati',
 			'Saur' => 'Szaurastra',
 			'Sgnw' => 'Jelírás',
 			'Shaw' => 'Shaw ábécé',
 			'Sinh' => 'Szingaléz',
 			'Sund' => 'Szundanéz',
 			'Sylo' => 'Sylheti nagári',
 			'Syrc' => 'Szíriai',
 			'Syre' => 'Estrangelo szíriai',
 			'Syrj' => 'Nyugat-szíriai',
 			'Syrn' => 'Kelet-szíriai',
 			'Tagb' => 'Tagbanwa',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Új tai lue',
 			'Taml' => 'Tamil',
 			'Tavt' => 'Tai viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Berber',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibeti',
 			'Ugar' => 'Ugari',
 			'Vaii' => 'Vai',
 			'Visp' => 'Látható beszéd',
 			'Xpeo' => 'Óperzsa',
 			'Xsux' => 'Ékírásos suméro-akkád',
 			'Yiii' => 'Ji',
 			'Zinh' => 'Származtatott',
 			'Zmth' => 'Matematikai jelrendszer',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Szimbólum',
 			'Zxxx' => 'Íratlan nyelvek kódja',
 			'Zyyy' => 'Meghatározatlan',
 			'Zzzz' => 'Ismeretlen írásrendszer',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'001' => 'Világ',
 			'002' => 'Afrika',
 			'003' => 'Észak-Amerika',
 			'005' => 'Dél-Amerika',
 			'009' => 'Óceánia',
 			'011' => 'Nyugat-Afrika',
 			'013' => 'Közép-Amerika',
 			'014' => 'Kelet-Afrika',
 			'015' => 'Észak-Afrika',
 			'017' => 'Közép-Afrika',
 			'018' => 'Afrika déli része',
 			'019' => 'Amerika',
 			'021' => 'Amerika északi része',
 			'029' => 'Karib-térség',
 			'030' => 'Kelet-Ázsia',
 			'034' => 'Dél-Ázsia',
 			'035' => 'Délkelet-Ázsia',
 			'039' => 'Dél-Európa',
 			'053' => 'Ausztrálázsia',
 			'054' => 'Melanézia',
 			'057' => 'Mikronéziai régió',
 			'061' => 'Polinézia',
 			'142' => 'Ázsia',
 			'143' => 'Közép-Ázsia',
 			'145' => 'Nyugat-Ázsia',
 			'150' => 'Európa',
 			'151' => 'Kelet-Európa',
 			'154' => 'Észak-Európa',
 			'155' => 'Nyugat-Európa',
 			'419' => 'Latin-Amerika',
 			'AC' => 'Ascension-sziget',
 			'AD' => 'Andorra',
 			'AE' => 'Egyesült Arab Emírségek',
 			'AF' => 'Afganisztán',
 			'AG' => 'Antigua és Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albánia',
 			'AM' => 'Örményország',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktisz',
 			'AR' => 'Argentína',
 			'AS' => 'Amerikai Szamoa',
 			'AT' => 'Ausztria',
 			'AU' => 'Ausztrália',
 			'AW' => 'Aruba',
 			'AX' => 'Åland-szigetek',
 			'AZ' => 'Azerbajdzsán',
 			'BA' => 'Bosznia-Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Banglades',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgária',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Holland Karib-térség',
 			'BR' => 'Brazília',
 			'BS' => 'Bahama-szigetek',
 			'BT' => 'Bhután',
 			'BV' => 'Bouvet-sziget',
 			'BW' => 'Botswana',
 			'BY' => 'Belarusz',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kókusz (Keeling)-szigetek',
 			'CD' => 'Kongó - Kinshasa',
 			'CD@alt=variant' => 'Kongó (KDK)',
 			'CF' => 'Közép-afrikai Köztársaság',
 			'CG' => 'Kongó - Brazzaville',
 			'CG@alt=variant' => 'Kongó (Köztársaság)',
 			'CH' => 'Svájc',
 			'CI' => 'Elefántcsontpart',
 			'CI@alt=variant' => 'CI',
 			'CK' => 'Cook-szigetek',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kína',
 			'CO' => 'Kolumbia',
 			'CP' => 'Clipperton-sziget',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Zöld-foki Köztársaság',
 			'CW' => 'Curaçao',
 			'CX' => 'Karácsony-sziget',
 			'CY' => 'Ciprus',
 			'CZ' => 'Csehország',
 			'CZ@alt=variant' => 'Cseh Köztársaság',
 			'DE' => 'Németország',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dzsibuti',
 			'DK' => 'Dánia',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikai Köztársaság',
 			'DZ' => 'Algéria',
 			'EA' => 'Ceuta és Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Észtország',
 			'EG' => 'Egyiptom',
 			'EH' => 'Nyugat-Szahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanyolország',
 			'ET' => 'Etiópia',
 			'EU' => 'Európai Unió',
 			'EZ' => 'Eurózóna',
 			'FI' => 'Finnország',
 			'FJ' => 'Fidzsi',
 			'FK' => 'Falkland-szigetek',
 			'FK@alt=variant' => 'Falkland-szigetek (Malvin-szigetek)',
 			'FM' => 'Mikronézia',
 			'FO' => 'Feröer-szigetek',
 			'FR' => 'Franciaország',
 			'GA' => 'Gabon',
 			'GB' => 'Egyesült Királyság',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Grúzia',
 			'GF' => 'Francia Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghána',
 			'GI' => 'Gibraltár',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Egyenlítői-Guinea',
 			'GR' => 'Görögország',
 			'GS' => 'Déli-Georgia és Déli-Sandwich-szigetek',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Bissau-Guinea',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong KKT',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard-sziget és McDonald-szigetek',
 			'HN' => 'Honduras',
 			'HR' => 'Horvátország',
 			'HT' => 'Haiti',
 			'HU' => 'Magyarország',
 			'IC' => 'Kanári-szigetek',
 			'ID' => 'Indonézia',
 			'IE' => 'Írország',
 			'IL' => 'Izrael',
 			'IM' => 'Man-sziget',
 			'IN' => 'India',
 			'IO' => 'Brit Indiai-óceáni Terület',
 			'IQ' => 'Irak',
 			'IR' => 'Irán',
 			'IS' => 'Izland',
 			'IT' => 'Olaszország',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordánia',
 			'JP' => 'Japán',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgizisztán',
 			'KH' => 'Kambodzsa',
 			'KI' => 'Kiribati',
 			'KM' => 'Comore-szigetek',
 			'KN' => 'Saint Kitts és Nevis',
 			'KP' => 'Észak-Korea',
 			'KR' => 'Dél-Korea',
 			'KW' => 'Kuvait',
 			'KY' => 'Kajmán-szigetek',
 			'KZ' => 'Kazahsztán',
 			'LA' => 'Laosz',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Srí Lanka',
 			'LR' => 'Libéria',
 			'LS' => 'Lesotho',
 			'LT' => 'Litvánia',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettország',
 			'LY' => 'Líbia',
 			'MA' => 'Marokkó',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegró',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaszkár',
 			'MH' => 'Marshall-szigetek',
 			'MK' => 'Macedónia',
 			'MK@alt=variant' => 'Macedónia (MVJK)',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Burma)',
 			'MN' => 'Mongólia',
 			'MO' => 'Makaó KKT',
 			'MO@alt=short' => 'Makaó',
 			'MP' => 'Északi Mariana-szigetek',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritánia',
 			'MS' => 'Montserrat',
 			'MT' => 'Málta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldív-szigetek',
 			'MW' => 'Malawi',
 			'MX' => 'Mexikó',
 			'MY' => 'Malajzia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namíbia',
 			'NC' => 'Új-Kaledónia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk-sziget',
 			'NG' => 'Nigéria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Hollandia',
 			'NO' => 'Norvégia',
 			'NP' => 'Nepál',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Új-Zéland',
 			'OM' => 'Omán',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francia Polinézia',
 			'PG' => 'Pápua Új-Guinea',
 			'PH' => 'Fülöp-szigetek',
 			'PK' => 'Pakisztán',
 			'PL' => 'Lengyelország',
 			'PM' => 'Saint-Pierre és Miquelon',
 			'PN' => 'Pitcairn-szigetek',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palesztin Terület',
 			'PS@alt=short' => 'Palesztina',
 			'PT' => 'Portugália',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Külső-Óceánia',
 			'RE' => 'Réunion',
 			'RO' => 'Románia',
 			'RS' => 'Szerbia',
 			'RU' => 'Oroszország',
 			'RW' => 'Ruanda',
 			'SA' => 'Szaúd-Arábia',
 			'SB' => 'Salamon-szigetek',
 			'SC' => 'Seychelle-szigetek',
 			'SD' => 'Szudán',
 			'SE' => 'Svédország',
 			'SG' => 'Szingapúr',
 			'SH' => 'Szent Ilona',
 			'SI' => 'Szlovénia',
 			'SJ' => 'Svalbard és Jan Mayen',
 			'SK' => 'Szlovákia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Szenegál',
 			'SO' => 'Szomália',
 			'SR' => 'Suriname',
 			'SS' => 'Dél-Szudán',
 			'ST' => 'São Tomé és Príncipe',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Szíria',
 			'SZ' => 'Szváziföld',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- és Caicos-szigetek',
 			'TD' => 'Csád',
 			'TF' => 'Francia Déli Területek',
 			'TG' => 'Togo',
 			'TH' => 'Thaiföld',
 			'TJ' => 'Tádzsikisztán',
 			'TK' => 'Tokelau',
 			'TL' => 'Kelet-Timor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Türkmenisztán',
 			'TN' => 'Tunézia',
 			'TO' => 'Tonga',
 			'TR' => 'Törökország',
 			'TT' => 'Trinidad és Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajvan',
 			'TZ' => 'Tanzánia',
 			'UA' => 'Ukrajna',
 			'UG' => 'Uganda',
 			'UM' => 'Az USA lakatlan külbirtokai',
 			'UN' => 'Egyesült Nemzetek Szervezete',
 			'UN@alt=short' => 'ENSZ',
 			'US' => 'Egyesült Államok',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Üzbegisztán',
 			'VA' => 'Vatikán',
 			'VC' => 'Saint Vincent és a Grenadine-szigetek',
 			'VE' => 'Venezuela',
 			'VG' => 'Brit Virgin-szigetek',
 			'VI' => 'Amerikai Virgin-szigetek',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis és Futuna',
 			'WS' => 'Szamoa',
 			'XK' => 'Koszovó',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Dél-afrikai Köztársaság',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Ismeretlen körzet',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Hagyományos német helyesírás',
 			'1994' => 'Szabványosított reziján helyesírás',
 			'1996' => '1996-os német helyesírás',
 			'1606NICT' => 'Késői közép francia 1606-ig',
 			'1694ACAD' => 'Korai modern francia',
 			'1959ACAD' => 'Akadémiai',
 			'ALALC97' => 'ALA-LC romanizáció, 1997-es kiadás',
 			'ALUKU' => 'Aluku dialektus',
 			'AREVELA' => 'Keleti örmény',
 			'AREVMDA' => 'Nyugati örmény',
 			'BAKU1926' => 'Egyesített türkic latin ábécé',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Biszkajan',
 			'BISKE' => 'San Giorgo/Bila tájszólás',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'IPA fonetika',
 			'FONUPA' => 'UPA fonetika',
 			'FONXSAMP' => 'Fonxsamp',
 			'HEPBURN' => 'Hepburn romanizáció',
 			'HOGNORSK' => 'Hongorszk',
 			'ITIHASA' => 'Itihasa',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Meghatározatlan helyesírás',
 			'LAUKIKA' => 'Laukika',
 			'LIPAW' => 'Reziján lipovaz tájszólás',
 			'LUNA1918' => 'Luna1918',
 			'MONOTON' => 'Monoton',
 			'NDYUKA' => 'Ndyuka dialektus',
 			'NEDIS' => 'Natisone dialektus',
 			'NJIVA' => 'Gniva/Njiva tájszólás',
 			'OSOJS' => 'Oseacco/Osojane tájszólás',
 			'PAMAKA' => 'Pamaka dialektus',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'pinjin átírás',
 			'POLYTON' => 'Politonikus',
 			'POSIX' => 'Számítógép',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Átdolgozott helyesírás',
 			'ROZAJ' => 'Reziján',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Skót szabványos angol',
 			'SCOUSE' => 'Scouse',
 			'SOLBA' => 'Stolvizza/Solbica tájszólás',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilv',
 			'SUTSILV' => 'Sutsilv',
 			'TARASK' => 'Taraskijevica helyesírás',
 			'UCCOR' => 'Egyesített helyesírás',
 			'UCRCOR' => 'Egyesített átdolgozott helyesírás',
 			'ULSTER' => 'Ulster',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valencia',
 			'VALLADER' => 'Vallader',
 			'WADEGILE' => 'Wade-Giles átírás',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Naptár',
 			'cf' => 'Pénznemformátum',
 			'colalternate' => 'Szimbólumokat figyelmen kívül hagyó rendezés',
 			'colbackwards' => 'Ékezetek fordított rendezése',
 			'colcasefirst' => 'Rendezés nagy- vagy kisbetűk szerint',
 			'colcaselevel' => 'Kisbetű-nagybetű érzékeny rendezés',
 			'collation' => 'Rendezési sorrend',
 			'colnormalization' => 'Normalizált rendezés',
 			'colnumeric' => 'Numerikus rendezés',
 			'colstrength' => 'Rendezés erőssége',
 			'currency' => 'Pénznem',
 			'hc' => 'Óraformátum (12 – 24)',
 			'lb' => 'Sortörés stílusa',
 			'ms' => 'Mértékegységrendszer',
 			'numbers' => 'Számok',
 			'timezone' => 'Időzóna',
 			'va' => 'Földrajzi helyvariáns',
 			'x' => 'Privát használatra',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{Buddhista naptár},
 				'chinese' => q{Kínai naptár},
 				'coptic' => q{Kopt naptár},
 				'dangi' => q{Dangi naptár},
 				'ethiopic' => q{Etióp naptár},
 				'ethiopic-amete-alem' => q{Etióp amete alem naptár},
 				'gregorian' => q{Gergely-naptár},
 				'hebrew' => q{Héber naptár},
 				'indian' => q{Indiai nemzeti naptár},
 				'islamic' => q{Iszlám naptár},
 				'islamic-civil' => q{Iszlám civil naptár},
 				'islamic-umalqura' => q{Iszlám Umm al-Qura naptár},
 				'iso8601' => q{ISO-8601 naptár},
 				'japanese' => q{Japán naptár},
 				'persian' => q{Perzsa naptár},
 				'roc' => q{Kínai köztársasági naptár},
 			},
 			'cf' => {
 				'account' => q{Könyvelési pénznemformátum},
 				'standard' => q{Normál pénznemformátum},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Szimbólumok rendezése},
 				'shifted' => q{Rendezés szimbólumok figyelmen kívül hagyásával},
 			},
 			'colbackwards' => {
 				'no' => q{Ékezetek normál rendezése},
 				'yes' => q{Ékezetek szerinti fordított rendezés},
 			},
 			'colcasefirst' => {
 				'lower' => q{Kisbetűs szavak rendezése előre},
 				'no' => q{Kisbetűs-nagybetűs szavak normál rendezése},
 				'upper' => q{Nagybetűs szavak rendezése előre},
 			},
 			'colcaselevel' => {
 				'no' => q{Kis- és nagybetűket meg nem különböztető rendezés},
 				'yes' => q{Rendezés kisbetű-nagybetű szerint},
 			},
 			'collation' => {
 				'big5han' => q{Hagyományos kínai sorrend - Big5},
 				'compat' => q{Előző rendezési sorrend a kompatibilitás érdekében},
 				'dictionary' => q{Szótári rendezési sorrend},
 				'ducet' => q{Alapértelmezett Unicode rendezési sorrend},
 				'eor' => q{Európai rendezési szabályok},
 				'gb2312han' => q{Egyszerűsített kínai sorrend - GB2312},
 				'phonebook' => q{Telefonkönyv sorrend},
 				'phonetic' => q{Fonetikus rendezési sorrend},
 				'pinyin' => q{Pinyin sorrend},
 				'reformed' => q{Átalakított rendezési elv},
 				'search' => q{Általános célú keresés},
 				'searchjl' => q{Keresés hangul kezdő mássalhangzó szerint},
 				'standard' => q{Normál rendezési sorrend},
 				'stroke' => q{Vonássorrend},
 				'traditional' => q{Hagyományos},
 				'unihan' => q{Szótővonás rendezési sorrend},
 			},
 			'colnormalization' => {
 				'no' => q{Rendezés normalizálás nélkül},
 				'yes' => q{Unicode szerinti normalizált rendezés},
 			},
 			'colnumeric' => {
 				'no' => q{Számjegyek egyedi rendezése},
 				'yes' => q{Számjegyek numerikus rendezése},
 			},
 			'colstrength' => {
 				'identical' => q{Összes rendezése},
 				'primary' => q{Csak az alapbetűk rendezése},
 				'quaternary' => q{Ékezetek/kisbetű-nagybetű/szélesség/kanák rendezése},
 				'secondary' => q{Ékezetek rendezése},
 				'tertiary' => q{Ékezetek/kisbetű-nagybetű/szélesség rendezése},
 			},
 			'd0' => {
 				'fwidth' => q{Teljes szélesség},
 				'hwidth' => q{Fél szélesség},
 				'npinyin' => q{Szám},
 			},
 			'hc' => {
 				'h11' => q{12 órás rendszer (0–11)},
 				'h12' => q{12 órás rendszer (0–12)},
 				'h23' => q{24 órás rendszer (0–23)},
 				'h24' => q{24 órás rendszer (0–24)},
 			},
 			'lb' => {
 				'loose' => q{Tág stílusú sortörés},
 				'normal' => q{Normál stílusú sortörés},
 				'strict' => q{Szűk stílusú sortörés},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Méterrendszer},
 				'uksystem' => q{Angolszász mértékegységrendszer},
 				'ussystem' => q{Amerikai mértékegységrendszer},
 			},
 			'numbers' => {
 				'arab' => q{Arab-indiai számjegyek},
 				'arabext' => q{Kibővített arab-indiai számjegyek},
 				'armn' => q{Örmény számok},
 				'armnlow' => q{Örmény kisbetűs számok},
 				'beng' => q{Bengáli számjegyek},
 				'deva' => q{Dévanágari számjegyek},
 				'ethi' => q{Etióp számok},
 				'finance' => q{Pénzügyi számok},
 				'fullwide' => q{Teljes szélességű számjegyek},
 				'geor' => q{Grúz számok},
 				'grek' => q{Görög számok},
 				'greklow' => q{Görög kisbetűs számok},
 				'gujr' => q{Gudzsaráti számjegyek},
 				'guru' => q{Gurmuki számjegyek},
 				'hanidec' => q{Kínai tizedes számok},
 				'hans' => q{Egyszerűsített kínai számok},
 				'hansfin' => q{Egyszerűsített kínai pénzügyi számok},
 				'hant' => q{Hagyományos kínai számok},
 				'hantfin' => q{Hagyományos kínai pénzügyi számok},
 				'hebr' => q{Héber számok},
 				'jpan' => q{Japán számok},
 				'jpanfin' => q{Japán pénzügyi számok},
 				'khmr' => q{Khmer számjegyek},
 				'knda' => q{Kannada számjegyek},
 				'laoo' => q{Lao számjegyek},
 				'latn' => q{Nyugati számjegyek},
 				'mlym' => q{Malajálam számjegyek},
 				'mong' => q{Mongol számjegyek},
 				'mymr' => q{Mianmari számjegyek},
 				'native' => q{Natív számjegyek},
 				'orya' => q{Orija számjegyek},
 				'roman' => q{Római számok},
 				'romanlow' => q{Római kisbetűs számok},
 				'taml' => q{Tamil hagyományos számok},
 				'tamldec' => q{Tamil számjegyek},
 				'telu' => q{Telugu számjegyek},
 				'thai' => q{Thai számjegyek},
 				'tibt' => q{Tibeti számjegyek},
 				'traditional' => q{Hagyományos számok},
 				'vaii' => q{Vai számjegyek},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{metrikus},
 			'UK' => q{angol},
 			'US' => q{amerikai},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Nyelv: {0}',
 			'script' => 'Írásrendszer: {0}',
 			'region' => 'Régió: {0}',

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[à ă â å ä ã ā æ ç è ĕ ê ë ē ì ĭ î ï ī ñ ò ŏ ô ø ō œ q ù ŭ û ū w x y ÿ]},
			index => ['A', 'Á', 'B', 'C', '{CS}', 'D', '{DZ}', '{DZS}', 'E', 'É', 'F', 'G', '{GY}', 'H', 'I', 'Í', 'J', 'K', 'L', '{LY}', 'M', 'N', '{NY}', 'O', 'Ó', 'Ö', 'Ő', 'P', 'Q', 'R', 'S', '{SZ}', 'T', '{TY}', 'U', 'Ú', 'Ü', 'Ű', 'V', 'W', 'X', 'Y', 'Z', '{ZS}'],
			main => qr{[a á b c {cs} {ccs} d {dz} {ddz} {dzs} {ddzs} e é f g {gy} {ggy} h i í j k l {ly} {lly} m n {ny} {nny} o ó ö ő p r s {sz} {ssz} t {ty} {tty} u ú ü ű v z {zs} {zzs}]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- – , ; \: ! ? . … ' ’ " ” „ « » ( ) \[ \] \{ \} ⟨ ⟩ § @ * / \& # ~ ⁒]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', '{CS}', 'D', '{DZ}', '{DZS}', 'E', 'É', 'F', 'G', '{GY}', 'H', 'I', 'Í', 'J', 'K', 'L', '{LY}', 'M', 'N', '{NY}', 'O', 'Ó', 'Ö', 'Ő', 'P', 'Q', 'R', 'S', '{SZ}', 'T', '{TY}', 'U', 'Ú', 'Ü', 'Ű', 'V', 'W', 'X', 'Y', 'Z', '{ZS}'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(hold),
						'one' => q({0} hold),
						'other' => q({0} hold),
					},
					'acre-foot' => {
						'name' => q(hold-láb),
						'one' => q({0} hold-láb),
						'other' => q({0} hold-láb),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(ívperc),
						'one' => q({0} ívperc),
						'other' => q({0} ívperc),
					},
					'arc-second' => {
						'name' => q(ívmásodperc),
						'one' => q({0} ívmásodperc),
						'other' => q({0} ívmásodperc),
					},
					'astronomical-unit' => {
						'name' => q(csillagászati egység),
						'one' => q({0} csillagászati egység),
						'other' => q({0} csillagászati egység),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bájt),
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					'calorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					'carat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					'celsius' => {
						'name' => q(Celsius-fok),
						'one' => q({0} Celsius-fok),
						'other' => q({0} Celsius-fok),
					},
					'centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					'centimeter' => {
						'name' => q(centiméter),
						'one' => q({0} centiméter),
						'other' => q({0} centiméter),
						'per' => q({0}/centimeter),
					},
					'century' => {
						'name' => q(évszázad),
						'one' => q({0} évszázad),
						'other' => q({0} évszázad),
					},
					'coordinate' => {
						'east' => q({0} K),
						'north' => q({0} É),
						'south' => q({0} D),
						'west' => q({0} Ny),
					},
					'cubic-centimeter' => {
						'name' => q(köbcentiméter),
						'one' => q({0} köbcentiméter),
						'other' => q({0} köbcentiméter),
						'per' => q({0}/köbcentiméter),
					},
					'cubic-foot' => {
						'name' => q(köbláb),
						'one' => q({0} köbláb),
						'other' => q({0} köbláb),
					},
					'cubic-inch' => {
						'name' => q(köbhüvelyk),
						'one' => q({0} köbhüvelyk),
						'other' => q({0} köbhüvelyk),
					},
					'cubic-kilometer' => {
						'name' => q(köbkilométer),
						'one' => q({0} köbkilométer),
						'other' => q({0} köbkilométer),
					},
					'cubic-meter' => {
						'name' => q(köbméter),
						'one' => q({0} köbméter),
						'other' => q({0} köbméter),
						'per' => q({0}/köbméter),
					},
					'cubic-mile' => {
						'name' => q(köbmérföld),
						'one' => q({0} köbmérföld),
						'other' => q({0} köbmérföld),
					},
					'cubic-yard' => {
						'name' => q(köbyard),
						'one' => q({0} köbyard),
						'other' => q({0} köbyard),
					},
					'cup' => {
						'name' => q(csésze),
						'one' => q({0} csésze),
						'other' => q({0} csésze),
					},
					'cup-metric' => {
						'name' => q(bögre),
						'one' => q({0} bögre),
						'other' => q({0} bögre),
					},
					'day' => {
						'name' => q(nap),
						'one' => q({0} nap),
						'other' => q({0} nap),
						'per' => q({0}/nap),
					},
					'deciliter' => {
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					'decimeter' => {
						'name' => q(deciméter),
						'one' => q({0} deciméter),
						'other' => q({0} deciméter),
					},
					'degree' => {
						'name' => q(fok),
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					'fahrenheit' => {
						'name' => q(Fahrenheit-fok),
						'one' => q({0} Fahrenheit-fok),
						'other' => q({0} Fahrenheit-fok),
					},
					'fluid-ounce' => {
						'name' => q(folyadékuncia),
						'one' => q({0} folyadékuncia),
						'other' => q({0} folyadékuncia),
					},
					'foodcalorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					'foot' => {
						'name' => q(láb),
						'one' => q({0} láb),
						'other' => q({0} láb),
						'per' => q({0}/láb),
					},
					'g-force' => {
						'name' => q(g gyorsulás),
						'one' => q({0} g gyorsulás),
						'other' => q({0} g gyorsulás),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					'gallon-imperial' => {
						'name' => q(birodalmi gallon),
						'one' => q({0} birodalmi gallon),
						'other' => q({0} birodalmi gallon),
						'per' => q({0}/birodalmi gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabájt),
						'one' => q({0} gigabájt),
						'other' => q({0} gigabájt),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					'hectare' => {
						'name' => q(hektár),
						'one' => q({0} hektár),
						'other' => q({0} hektár),
					},
					'hectoliter' => {
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(lóerő),
						'one' => q({0} lóerő),
						'other' => q({0} lóerő),
					},
					'hour' => {
						'name' => q(óra),
						'one' => q({0} óra),
						'other' => q({0} óra),
						'per' => q({0}/óra),
					},
					'inch' => {
						'name' => q(hüvelyk),
						'one' => q({0} hüvelyk),
						'other' => q({0} hüvelyk),
						'per' => q({0}/hüvelyk),
					},
					'inch-hg' => {
						'name' => q(higanyhüvelyk),
						'one' => q({0} higanyhüvelyk),
						'other' => q({0} higanyhüvelyk),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobájt),
						'one' => q({0} kilobájt),
						'other' => q({0} kilobájt),
					},
					'kilocalorie' => {
						'name' => q(kilokalória),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalória),
					},
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					'kilometer' => {
						'name' => q(kilométer),
						'one' => q({0} kilométer),
						'other' => q({0} kilométer),
						'per' => q({0}/kilométer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilométer per óra),
						'one' => q({0} kilométer per óra),
						'other' => q({0} kilométer per óra),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowattóra),
						'one' => q({0} kilowattóra),
						'other' => q({0} kilowattóra),
					},
					'knot' => {
						'name' => q(csomó),
						'one' => q({0} csomó),
						'other' => q({0} csomó),
					},
					'light-year' => {
						'name' => q(fényév),
						'one' => q({0} fényév),
						'other' => q({0} fényév),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0}/liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter/100 km),
						'one' => q({0} liter/100 km),
						'other' => q({0} liter/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilométer),
						'one' => q({0} liter per kilométer),
						'other' => q({0} liter per kilométer),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabájt),
						'one' => q({0} megabájt),
						'other' => q({0} megabájt),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(méter),
						'one' => q({0} méter),
						'other' => q({0} méter),
						'per' => q({0}/méter),
					},
					'meter-per-second' => {
						'name' => q(méter per másodperc),
						'one' => q({0} méter per másodperc),
						'other' => q({0} méter per másodperc),
					},
					'meter-per-second-squared' => {
						'name' => q(méter per másodpercnégyzet),
						'one' => q({0} méter per másodpercnégyzet),
						'other' => q({0} méter per másodpercnégyzet),
					},
					'metric-ton' => {
						'name' => q(metrikus tonna),
						'one' => q({0} metrikus tonna),
						'other' => q({0} metrikus tonna),
					},
					'microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					'micrometer' => {
						'name' => q(mikrométer),
						'one' => q({0} mikrométer),
						'other' => q({0} mikrométer),
					},
					'microsecond' => {
						'name' => q(mikroszekundum),
						'one' => q({0} mikroszekundum),
						'other' => q({0} mikroszekundum),
					},
					'mile' => {
						'name' => q(mérföld),
						'one' => q({0} mérföld),
						'other' => q({0} mérföld),
					},
					'mile-per-gallon' => {
						'name' => q(mérföld per gallon),
						'one' => q({0} mérföld per gallon),
						'other' => q({0} mérföld per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mérföld/birodalmi gallon),
						'one' => q({0} mérföld/birodalmi gallon),
						'other' => q({0} mérföld/birodalmi gallon),
					},
					'mile-per-hour' => {
						'name' => q(mérföld per óra),
						'one' => q({0} mérföld per óra),
						'other' => q({0} mérföld per óra),
					},
					'mile-scandinavian' => {
						'name' => q(svéd mérföld),
						'one' => q({0} svéd mérföld),
						'other' => q({0} svéd mérföld),
					},
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligramm/deciliter),
						'one' => q({0} milligramm/deciliter),
						'other' => q({0} milligramm/deciliter),
					},
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					'millimeter' => {
						'name' => q(milliméter),
						'one' => q({0} milliméter),
						'other' => q({0} milliméter),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} higanymilliméter),
						'other' => q({0} higanymilliméter),
					},
					'millimole-per-liter' => {
						'name' => q(millimól/liter),
						'one' => q({0} millimól/liter),
						'other' => q({0} millimól/liter),
					},
					'millisecond' => {
						'name' => q(ezredmásodperc),
						'one' => q({0} ezredmásodperc),
						'other' => q({0} ezredmásodperc),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(perc),
						'one' => q({0} perc),
						'other' => q({0} perc),
						'per' => q({0}/perc),
					},
					'month' => {
						'name' => q(hónap),
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hónap),
					},
					'nanometer' => {
						'name' => q(nanométer),
						'one' => q({0} nanométer),
						'other' => q({0} nanométer),
					},
					'nanosecond' => {
						'name' => q(nanoszekundum),
						'one' => q({0} nanoszekundum),
						'other' => q({0} nanoszekundum),
					},
					'nautical-mile' => {
						'name' => q(tengeri mérföld),
						'one' => q({0} tengeri mérföld),
						'other' => q({0} tengeri mérföld),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(uncia),
						'one' => q({0} uncia),
						'other' => q({0} uncia),
						'per' => q({0}/uncia),
					},
					'ounce-troy' => {
						'name' => q(troy uncia),
						'one' => q({0} troy uncia),
						'other' => q({0} troy uncia),
					},
					'parsec' => {
						'name' => q(parszek),
						'one' => q({0} parszek),
						'other' => q({0} parszek),
					},
					'part-per-million' => {
						'name' => q(részecske/millió),
						'one' => q({0} részecske/millió),
						'other' => q({0} részecske/millió),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(pikométer),
						'one' => q({0} pikométer),
						'other' => q({0} pikométer),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metrikus pint),
						'one' => q({0} metrikus pint),
						'other' => q({0} metrikus pint),
					},
					'point' => {
						'name' => q(pont),
						'one' => q({0} pont),
						'other' => q({0} pont),
					},
					'pound' => {
						'name' => q(font),
						'one' => q({0} font),
						'other' => q({0} font),
						'per' => q({0}/font),
					},
					'pound-per-square-inch' => {
						'name' => q(font per négyzethüvelyk),
						'one' => q({0} font per négyzethüvelyk),
						'other' => q({0} font per négyzethüvelyk),
					},
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					'radian' => {
						'name' => q(radián),
						'one' => q({0} radián),
						'other' => q({0} radián),
					},
					'revolution' => {
						'name' => q(fordulat),
						'one' => q({0} fordulat),
						'other' => q({0} fordulat),
					},
					'second' => {
						'name' => q(másodperc),
						'one' => q({0} másodperc),
						'other' => q({0} másodperc),
						'per' => q({0}/másodperc),
					},
					'square-centimeter' => {
						'name' => q(négyzetcentiméter),
						'one' => q({0} négyzetcentiméter),
						'other' => q({0} négyzetcentiméter),
						'per' => q({0}/négyzetcentiméter),
					},
					'square-foot' => {
						'name' => q(négyzetláb),
						'one' => q({0} négyzetláb),
						'other' => q({0} négyzetláb),
					},
					'square-inch' => {
						'name' => q(négyzethüvelyk),
						'one' => q({0} négyzethüvelyk),
						'other' => q({0} négyzethüvelyk),
						'per' => q({0}/négyzethüvelyk),
					},
					'square-kilometer' => {
						'name' => q(négyzetkilométer),
						'one' => q({0} négyzetkilométer),
						'other' => q({0} négyzetkilométer),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(négyzetméter),
						'one' => q({0} négyzetméter),
						'other' => q({0} négyzetméter),
						'per' => q({0}/négyzetméter),
					},
					'square-mile' => {
						'name' => q(négyzetmérföld),
						'one' => q({0} négyzetmérföld),
						'other' => q({0} négyzetmérföld),
						'per' => q({0}/négyzetmérföld),
					},
					'square-yard' => {
						'name' => q(négyzetyard),
						'one' => q({0} négyzetyard),
						'other' => q({0} négyzetyard),
					},
					'tablespoon' => {
						'name' => q(evőkanál),
						'one' => q({0} evőkanál),
						'other' => q({0} evőkanál),
					},
					'teaspoon' => {
						'name' => q(kávéskanál),
						'one' => q({0} kávéskanál),
						'other' => q({0} kávéskanál),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabájt),
						'one' => q({0} terabájt),
						'other' => q({0} terabájt),
					},
					'ton' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(hét),
						'one' => q({0} hét),
						'other' => q({0} hét),
						'per' => q({0}/hét),
					},
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(év),
						'one' => q({0} év),
						'other' => q({0} év),
						'per' => q({0}/év),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(sz.),
						'one' => q({0} sz.),
						'other' => q({0} sz.),
					},
					'coordinate' => {
						'east' => q({0} K),
						'north' => q({0} É),
						'south' => q({0} D),
						'west' => q({0} Ny),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(nap),
						'one' => q({0} nap),
						'other' => q({0} nap),
						'per' => q({0}/nap),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'foot' => {
						'name' => q(láb),
						'one' => q({0} láb),
						'other' => q({0} láb),
						'per' => q({0}/láb),
					},
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} LE),
						'other' => q({0} LE),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(hüvelyk),
						'one' => q({0} hüvelyk),
						'other' => q({0} hüvelyk),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'one' => q({0} fényév),
						'other' => q({0} fényév),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'name' => q(mf),
						'one' => q({0} mf),
						'other' => q({0} mf),
					},
					'mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(Hgmm),
						'one' => q({0} Hgmm),
						'other' => q({0} Hgmm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(hónap),
						'one' => q({0} h.),
						'other' => q({0} h.),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} uncia),
						'other' => q({0} uncia),
						'per' => q({0}/oz),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} font),
						'other' => q({0} font),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(hét),
						'one' => q({0} hét),
						'other' => q({0} hét),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(év),
						'one' => q({0} év),
						'other' => q({0} év),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(kh),
						'one' => q({0} kh),
						'other' => q({0} kh),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(ívperc),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(ívmásodperc),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(CsE),
						'one' => q({0} CsE),
						'other' => q({0} CsE),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bájt),
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(sz.),
						'one' => q({0} sz.),
						'other' => q({0} sz.),
					},
					'coordinate' => {
						'east' => q({0} K),
						'north' => q({0} É),
						'south' => q({0} D),
						'west' => q({0} Ny),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cs.),
						'one' => q({0} cs.),
						'other' => q({0} cs.),
					},
					'cup-metric' => {
						'name' => q(bg),
						'one' => q({0} bg),
						'other' => q({0} bg),
					},
					'day' => {
						'name' => q(nap),
						'one' => q({0} nap),
						'other' => q({0} nap),
						'per' => q({0}/nap),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(fok),
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'foot' => {
						'name' => q(láb),
						'one' => q({0} láb),
						'other' => q({0} láb),
						'per' => q({0}/láb),
					},
					'g-force' => {
						'name' => q(g gyorsulás),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(bir. gal),
						'one' => q({0} bir. gal),
						'other' => q({0} bir. gal),
						'per' => q({0}/bir. gal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(LE),
						'one' => q({0} LE),
						'other' => q({0} LE),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(hüvelyk),
						'one' => q({0} hüvelyk),
						'other' => q({0} hüvelyk),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(fényév),
						'one' => q({0} fényév),
						'other' => q({0} fényév),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mf),
						'one' => q({0} mf),
						'other' => q({0} mf),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mérföld/bir. gallon),
						'one' => q({0} mpg bir.),
						'other' => q({0} mpg bir.),
					},
					'mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(millimól/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(hónap),
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hó),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(részecske/millió),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pont),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(ford.),
						'one' => q({0} ford.),
						'other' => q({0} ford.),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(ek.),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					'teaspoon' => {
						'name' => q(kk.),
						'one' => q({0} kk.),
						'other' => q({0} kk.),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(hét),
						'one' => q({0} hét),
						'other' => q({0} hét),
						'per' => q({0}/hét),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(év),
						'one' => q({0} év),
						'other' => q({0} év),
						'per' => q({0}/év),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:igen|i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nem|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} és {1}),
				2 => q({0} és {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 4,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'1000' => {
					'one' => '0 E',
					'other' => '0 E',
				},
				'10000' => {
					'one' => '00 E',
					'other' => '00 E',
				},
				'100000' => {
					'one' => '000 E',
					'other' => '000 E',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0 Mrd',
					'other' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 ezer',
					'other' => '0 ezer',
				},
				'10000' => {
					'one' => '00 ezer',
					'other' => '00 ezer',
				},
				'100000' => {
					'one' => '000 ezer',
					'other' => '000 ezer',
				},
				'1000000' => {
					'one' => '0 millió',
					'other' => '0 millió',
				},
				'10000000' => {
					'one' => '00 millió',
					'other' => '00 millió',
				},
				'100000000' => {
					'one' => '000 millió',
					'other' => '000 millió',
				},
				'1000000000' => {
					'one' => '0 milliárd',
					'other' => '0 milliárd',
				},
				'10000000000' => {
					'one' => '00 milliárd',
					'other' => '00 milliárd',
				},
				'100000000000' => {
					'one' => '000 milliárd',
					'other' => '000 milliárd',
				},
				'1000000000000' => {
					'one' => '0 billió',
					'other' => '0 billió',
				},
				'10000000000000' => {
					'one' => '00 billió',
					'other' => '00 billió',
				},
				'100000000000000' => {
					'one' => '000 billió',
					'other' => '000 billió',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 E',
					'other' => '0 E',
				},
				'10000' => {
					'one' => '00 E',
					'other' => '00 E',
				},
				'100000' => {
					'one' => '000 E',
					'other' => '000 E',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0 Mrd',
					'other' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ADP' => {
			display_name => {
				'currency' => q(Andorrai peseta),
				'one' => q(Andorrai peseta),
				'other' => q(Andorrai peseta),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(EAE-dirham),
				'one' => q(EAE-dirham),
				'other' => q(EAE-dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgán afghani \(1927–2002\)),
				'one' => q(afgán afghani \(1927–2002\)),
				'other' => q(afgán afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgán afghani),
				'one' => q(afgán afghani),
				'other' => q(afgán afghani),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albán lek),
				'one' => q(albán lek),
				'other' => q(albán lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(örmény dram),
				'one' => q(örmény dram),
				'other' => q(örmény dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(holland antilláki forint),
				'one' => q(holland antilláki forint),
				'other' => q(holland antilláki forint),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(angolai kwanza),
				'one' => q(angolai kwanza),
				'other' => q(angolai kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolai kwanza \(1977–1990\)),
				'one' => q(Angolai kwanza \(1977–1990\)),
				'other' => q(Angolai kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolai új kwanza \(1990–2000\)),
				'one' => q(Angolai új kwanza \(1990–2000\)),
				'other' => q(Angolai új kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolai kwanza reajustado \(1995–1999\)),
				'one' => q(Angolai kwanza reajustado \(1995–1999\)),
				'other' => q(Angolai kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentín austral),
				'one' => q(Argentin austral),
				'other' => q(Argentin austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentín peso \(1983–1985\)),
				'one' => q(Argentín peso \(1983–1985\)),
				'other' => q(Argentín peso \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(argentin peso),
				'one' => q(argentin peso),
				'other' => q(argentin peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Osztrák schilling),
				'one' => q(Osztrák schilling),
				'other' => q(Osztrák schilling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(ausztrál dollár),
				'one' => q(ausztrál dollár),
				'other' => q(ausztrál dollár),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(arubai florin),
				'one' => q(arubai florin),
				'other' => q(arubai florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdzsáni manat \(1993–2006\)),
				'one' => q(azerbajdzsáni manat \(1993–2006\)),
				'other' => q(azerbajdzsáni manat \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(azerbajdzsáni manat),
				'one' => q(azerbajdzsáni manat),
				'other' => q(azerbajdzsáni manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosznia-hercegovinai dínár \(1992–1994\)),
				'one' => q(Bosznia-hercegovinai dínár \(1992–1994\)),
				'other' => q(Bosznia-hercegovinai dínár \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(bosznia-hercegovinai konvertibilis márka),
				'one' => q(bosznia-hercegovinai konvertibilis márka),
				'other' => q(bosznia-hercegovinai konvertibilis márka),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadosi dollár),
				'one' => q(barbadosi dollár),
				'other' => q(barbadosi dollár),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(bangladesi taka),
				'one' => q(bangladesi taka),
				'other' => q(bangladesi taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belga frank \(konvertibilis\)),
				'one' => q(Belga frank \(konvertibilis\)),
				'other' => q(Belga frank \(konvertibilis\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belga frank),
				'one' => q(Belga frank),
				'other' => q(Belga frank),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belga frank \(pénzügyi\)),
				'one' => q(Belga frank \(pénzügyi\)),
				'other' => q(Belga frank \(pénzügyi\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bolgár kemény leva),
				'one' => q(Bolgár kemény leva),
				'other' => q(Bolgár kemény leva),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bolgár új leva),
				'one' => q(bolgár új leva),
				'other' => q(bolgár új leva),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahreini dinár),
				'one' => q(bahreini dinár),
				'other' => q(bahreini dinár),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundi frank),
				'one' => q(burundi frank),
				'other' => q(burundi frank),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudai dollár),
				'one' => q(bermudai dollár),
				'other' => q(bermudai dollár),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brunei dollár),
				'one' => q(brunei dollár),
				'other' => q(brunei dollár),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(bolíviai boliviano),
				'one' => q(bolíviai boliviano),
				'other' => q(bolíviai boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolíviai peso),
				'one' => q(Bolíviai peso),
				'other' => q(Bolíviai peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolíviai mvdol),
				'one' => q(Bolíviai mvdol),
				'other' => q(Bolíviai mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brazi cruzeiro novo \(1967–1986\)),
				'one' => q(Brazi cruzeiro novo \(1967–1986\)),
				'other' => q(Brazi cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brazi cruzado \(1986–1989\)),
				'one' => q(Brazi cruzado \(1986–1989\)),
				'other' => q(Brazi cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brazil cruzeiro \(1990–1993\)),
				'one' => q(Brazil cruzeiro \(1990–1993\)),
				'other' => q(Brazil cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazil real),
				'one' => q(brazil real),
				'other' => q(brazil real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brazil cruzado novo \(1989–1990\)),
				'one' => q(Brazil cruzado novo \(1989–1990\)),
				'other' => q(Brazil cruzado novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazil cruzeiro \(1993–1994\)),
				'one' => q(Brazil cruzeiro \(1993–1994\)),
				'other' => q(Brazil cruzeiro \(1993–1994\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamai dollár),
				'one' => q(bahamai dollár),
				'other' => q(bahamai dollár),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(bhutáni ngultrum),
				'one' => q(bhutáni ngultrum),
				'other' => q(bhutáni ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmai kyat),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(botswanai pula),
				'one' => q(botswanai pula),
				'other' => q(botswanai pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Fehérorosz új rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(fehérorosz rubel),
				'one' => q(fehérorosz rubel),
				'other' => q(fehérorosz rubel),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(fehérorosz rubel \(2000–2016\)),
				'one' => q(fehérorosz rubel \(2000–2016\)),
				'other' => q(fehérorosz rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(belize-i dollár),
				'one' => q(belize-i dollár),
				'other' => q(belize-i dollár),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadai dollár),
				'one' => q(kanadai dollár),
				'other' => q(kanadai dollár),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(kongói frank),
				'one' => q(kongói frank),
				'other' => q(kongói frank),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(svájci frank),
				'one' => q(svájci frank),
				'other' => q(svájci frank),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR frank),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chilei unidades de fomento),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(chilei peso),
				'one' => q(chilei peso),
				'other' => q(chilei peso),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(kínai jüan \(offshore\)),
				'one' => q(kínai jüan \(offshore\)),
				'other' => q(kínai jüan \(offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kínai jüan),
				'one' => q(kínai jüan),
				'other' => q(kínai jüan),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(kolumbiai peso),
				'one' => q(kolumbiai peso),
				'other' => q(kolumbiai peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Costa Rica-i colon),
				'one' => q(Costa Rica-i colon),
				'other' => q(Costa Rica-i colon),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(szerb dinár),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Csehszlovák kemény korona),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubai konvertibilis peso),
				'one' => q(kubai konvertibilis peso),
				'other' => q(kubai konvertibilis peso),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubai peso),
				'one' => q(kubai peso),
				'other' => q(kubai peso),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Cape Verde-i escudo),
				'one' => q(Cape Verde-i escudo),
				'other' => q(Cape Verde-i escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Ciprusi font),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(cseh korona),
				'one' => q(cseh korona),
				'other' => q(cseh korona),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Kelet-Német márka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Német márka),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(dzsibuti frank),
				'one' => q(dzsibuti frank),
				'other' => q(dzsibuti frank),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(dán korona),
				'one' => q(dán korona),
				'other' => q(dán korona),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikai peso),
				'one' => q(dominikai peso),
				'other' => q(dominikai peso),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(algériai dínár),
				'one' => q(algériai dínár),
				'other' => q(algériai dínár),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadori sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ecuadori Unidad de Valor Constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Észt korona),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(egyiptomi font),
				'one' => q(egyiptomi font),
				'other' => q(egyiptomi font),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(eritreai nakfa),
				'one' => q(eritreai nakfa),
				'other' => q(eritreai nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spanyol peseta \(A–kontó\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spanyol peseta \(konvertibilis kontó\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spanyol peseta),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiópiai birr),
				'one' => q(etiópiai birr),
				'other' => q(etiópiai birr),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euró),
				'one' => q(euró),
				'other' => q(euró),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finn markka),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidzsi dollár),
				'one' => q(fidzsi dollár),
				'other' => q(fidzsi dollár),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(falkland-szigeteki font),
				'one' => q(falkland-szigeteki font),
				'other' => q(falkland-szigeteki font),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Francia frank),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(brit font),
				'one' => q(brit font),
				'other' => q(brit font),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Grúz kupon larit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(grúz lari),
				'one' => q(grúz lari),
				'other' => q(grúz lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghánai cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ghánai cedi),
				'one' => q(ghánai cedi),
				'other' => q(ghánai cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltári font),
				'one' => q(gibraltári font),
				'other' => q(gibraltári font),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambiai dalasi),
				'one' => q(gambiai dalasi),
				'other' => q(gambiai dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(guineai frank),
				'one' => q(guineai frank),
				'other' => q(guineai frank),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guineai syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Egyenlítői-guineai ekwele guineana),
				'one' => q(Egyenlítői-guineai ekwele),
				'other' => q(Egyenlítői-guineai ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Görög drachma),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(guatemalai quetzal),
				'one' => q(guatemalai quetzal),
				'other' => q(guatemalai quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugál guinea escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissaui peso),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(guyanai dollár),
				'one' => q(guyanai dollár),
				'other' => q(guyanai dollár),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(hongkongi dollár),
				'one' => q(hongkongi dollár),
				'other' => q(hongkongi dollár),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(hodurasi lempira),
				'one' => q(hodurasi lempira),
				'other' => q(hodurasi lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Horvát dínár),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(horvát kuna),
				'one' => q(horvát kuna),
				'other' => q(horvát kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haiti gourde),
				'one' => q(haiti gourde),
				'other' => q(haiti gourde),
			},
		},
		'HUF' => {
			symbol => 'Ft',
			display_name => {
				'currency' => q(magyar forint),
				'one' => q(magyar forint),
				'other' => q(magyar forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(indonéz rúpia),
				'one' => q(indonéz rúpia),
				'other' => q(indonéz rúpia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Ír font),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Izraeli font),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(izraeli új sékel),
				'one' => q(izraeli új sékel),
				'other' => q(izraeli új sékel),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indiai rúpia),
				'one' => q(indiai rúpia),
				'other' => q(indiai rúpia),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(iraki dínár),
				'one' => q(iraki dínár),
				'other' => q(iraki dínár),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iráni rial),
				'one' => q(iráni rial),
				'other' => q(iráni rial),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(izlandi korona),
				'one' => q(izlandi korona),
				'other' => q(izlandi korona),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Olasz líra),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamaicai dollár),
				'one' => q(jamaicai dollár),
				'other' => q(jamaicai dollár),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(jordániai dínár),
				'one' => q(jordániai dínár),
				'other' => q(jordániai dínár),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japán jen),
				'one' => q(japán jen),
				'other' => q(japán jen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(kenyai shilling),
				'one' => q(kenyai shilling),
				'other' => q(kenyai shilling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgizisztáni szom),
				'one' => q(kirgizisztáni szom),
				'other' => q(kirgizisztáni szom),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambodzsai riel),
				'one' => q(kambodzsai riel),
				'other' => q(kambodzsai riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(comorei frank),
				'one' => q(comorei frank),
				'other' => q(comorei frank),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(észak-koreai won),
				'one' => q(észak-koreai won),
				'other' => q(észak-koreai won),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(dél-koreai won),
				'one' => q(dél-koreai won),
				'other' => q(dél-koreai won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuvaiti dínár),
				'one' => q(kuvaiti dínár),
				'other' => q(kuvaiti dínár),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(kajmán-szigeteki dollár),
				'one' => q(kajmán-szigeteki dollár),
				'other' => q(kajmán-szigeteki dollár),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazahsztáni tenge),
				'one' => q(kazahsztáni tenge),
				'other' => q(kazahsztáni tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoszi kip),
				'one' => q(laoszi kip),
				'other' => q(laoszi kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanoni font),
				'one' => q(libanoni font),
				'other' => q(libanoni font),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Srí Lanka-i rúpia),
				'one' => q(Srí Lanka-i rúpia),
				'other' => q(Srí Lanka-i rúpia),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(libériai dollár),
				'one' => q(libériai dollár),
				'other' => q(libériai dollár),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesothoi loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litvániai litas),
				'one' => q(litvániai litas),
				'other' => q(litvániai litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litvániai talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgi konvertibilis frank),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburgi frank),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburgi pénzügyi frank),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(lett lats),
				'one' => q(lett lats),
				'other' => q(lett lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lett rubel),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(líbiai dínár),
				'one' => q(líbiai dínár),
				'other' => q(líbiai dínár),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(marokkói dirham),
				'one' => q(marokkói dirham),
				'other' => q(marokkói dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkói frank),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldován lei),
				'one' => q(moldován lei),
				'other' => q(moldován lei),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(madagaszkári ariary),
				'one' => q(madagaszkári ariary),
				'other' => q(madagaszkári ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaszkári frank),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(macedon dínár),
				'one' => q(macedon dínár),
				'other' => q(macedon dínár),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali frank),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(mianmari kyat),
				'one' => q(mianmari kyat),
				'other' => q(mianmari kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongóliai tugrik),
				'one' => q(mongóliai tugrik),
				'other' => q(mongóliai tugrik),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makaói pataca),
				'one' => q(makaói pataca),
				'other' => q(makaói pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mauritániai ouguiya),
				'one' => q(mauritániai ouguiya),
				'other' => q(mauritániai ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Máltai líra),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Máltai font),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(mauritiusi rúpia),
				'one' => q(mauritiusi rúpia),
				'other' => q(mauritiusi rúpia),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldív-szigeteki rufiyaa),
				'one' => q(maldív-szigeteki rufiyaa),
				'other' => q(maldív-szigeteki rufiyaa),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malawi kwacha),
				'one' => q(malawi kwacha),
				'other' => q(malawi kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(mexikói peso),
				'one' => q(mexikói peso),
				'other' => q(mexikói peso),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexikói ezüst peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexikói Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(malajziai ringgit),
				'one' => q(malajziai ringgit),
				'other' => q(malajziai ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambik escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambik metical),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(mozambiki metikális),
				'one' => q(mozambiki metikális),
				'other' => q(mozambiki metikális),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namíbiai dollár),
				'one' => q(namíbiai dollár),
				'other' => q(namíbiai dollár),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(nigériai naira),
				'one' => q(nigériai naira),
				'other' => q(nigériai naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaraguai cordoba),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(nicaraguai córdoba),
				'one' => q(nicaraguai córdoba),
				'other' => q(nicaraguai córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Holland forint),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(norvég korona),
				'one' => q(norvég korona),
				'other' => q(norvég korona),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(nepáli rúpia),
				'one' => q(nepáli rúpia),
				'other' => q(nepáli rúpia),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(új-zélandi dollár),
				'one' => q(új-zélandi dollár),
				'other' => q(új-zélandi dollár),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(ománi rial),
				'one' => q(ománi rial),
				'other' => q(ománi rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(panamai balboa),
				'one' => q(panamai balboa),
				'other' => q(panamai balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(perui inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(perui sol),
				'one' => q(perui sol),
				'other' => q(perui sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(perui sol \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(pápua új-guineai kina),
				'one' => q(pápua új-guineai kina),
				'other' => q(pápua új-guineai kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(fülöp-szigeteki peso),
				'one' => q(fülöp-szigeteki peso),
				'other' => q(fülöp-szigeteki peso),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakisztáni rúpia),
				'one' => q(pakisztáni rúpia),
				'other' => q(pakisztáni rúpia),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(lengyel zloty),
				'one' => q(lengyel zloty),
				'other' => q(lengyel zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Lengyel zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugál escudo),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(paraguayi guarani),
				'one' => q(paraguayi guarani),
				'other' => q(paraguayi guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(katari rial),
				'one' => q(katari rial),
				'other' => q(katari rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodéziai dollár),
				'one' => q(Rhodéziai dollár),
				'other' => q(Rhodéziai dollár),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(román lej \(1952–2006\)),
				'one' => q(román lej \(1952–2006\)),
				'other' => q(román lej \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(román lej),
				'one' => q(román lej),
				'other' => q(román lej),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(szerb dínár),
				'one' => q(szerb dínár),
				'other' => q(szerb dínár),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(orosz rubel),
				'one' => q(orosz rubel),
				'other' => q(orosz rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(orosz rubel \(1991–1998\)),
				'one' => q(orosz rubel \(1991–1998\)),
				'other' => q(orosz rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(ruandai frank),
				'one' => q(ruandai frank),
				'other' => q(ruandai frank),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(szaúdi riyal),
				'one' => q(szaúdi riyal),
				'other' => q(szaúdi riyal),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(salamon-szigeteki dollár),
				'one' => q(salamon-szigeteki dollár),
				'other' => q(salamon-szigeteki dollár),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(seychelle-szigeteki rúpia),
				'one' => q(seychelle-szigeteki rúpia),
				'other' => q(seychelle-szigeteki rúpia),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Szudáni dínár \(1992–2007\)),
				'one' => q(Szudáni dínár \(1992–2007\)),
				'other' => q(Szudáni dínár \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(szudáni font),
				'one' => q(szudáni font),
				'other' => q(szudáni font),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Szudáni font \(1957–1998\)),
				'one' => q(Szudáni font \(1957–1998\)),
				'other' => q(Szudáni font \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(svéd korona),
				'one' => q(svéd korona),
				'other' => q(svéd korona),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(szingapúri dollár),
				'one' => q(szingapúri dollár),
				'other' => q(szingapúri dollár),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Szent Ilona-i font),
				'one' => q(Szent Ilona-i font),
				'other' => q(Szent Ilona-i font),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Szlovén tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Szlovák korona),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra Leone-i leone),
				'one' => q(Sierra Leone-i leone),
				'other' => q(Sierra Leone-i leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(szomáli shilling),
				'one' => q(szomáli shilling),
				'other' => q(szomáli shilling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(suriname-i dollár),
				'one' => q(suriname-i dollár),
				'other' => q(suriname-i dollár),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Suriname-i gulden),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(dél-szudáni font),
				'one' => q(dél-szudáni font),
				'other' => q(dél-szudáni font),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(São Tomé és Príncipe-i dobra),
				'one' => q(São Tomé és Príncipe-i dobra),
				'other' => q(São Tomé és Príncipe-i dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Szovjet rubel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadori colón),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(szíriai font),
				'one' => q(szíriai font),
				'other' => q(szíriai font),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(szváziföldi lilangeni),
				'one' => q(szváziföldi lilangeni),
				'other' => q(szváziföldi lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(thai baht),
				'one' => q(thai baht),
				'other' => q(thai baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tádzsikisztáni rubel),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(tádzsikisztáni somoni),
				'one' => q(tádzsikisztáni somoni),
				'other' => q(tádzsikisztáni somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(türkmenisztáni manat \(1993–2009\)),
				'one' => q(türkmenisztáni manat \(1993–2009\)),
				'other' => q(türkmenisztáni manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(türkmenisztáni manat),
				'one' => q(türkmenisztáni manat),
				'other' => q(türkmenisztáni manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tunéziai dínár),
				'one' => q(tunéziai dínár),
				'other' => q(tunéziai dínár),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(tongai paanga),
				'one' => q(tongai paanga),
				'other' => q(tongai paanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timori escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(török líra \(1922–2005\)),
				'one' => q(török líra \(1922–2005\)),
				'other' => q(török líra \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(török líra),
				'one' => q(török líra),
				'other' => q(török líra),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad és Tobago-i dollár),
				'one' => q(Trinidad és Tobago-i dollár),
				'other' => q(Trinidad és Tobago-i dollár),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(tajvani új dollár),
				'one' => q(tajvani új dollár),
				'other' => q(tajvani új dollár),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzániai shilling),
				'one' => q(tanzániai shilling),
				'other' => q(tanzániai shilling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(ukrán hrivnya),
				'one' => q(ukrán hrivnya),
				'other' => q(ukrán hrivnya),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrán karbovanec),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandai shilling \(1966–1987\)),
				'one' => q(Ugandai shilling \(1966–1987\)),
				'other' => q(Ugandai shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(ugandai shilling),
				'one' => q(ugandai shilling),
				'other' => q(ugandai shilling),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(USA-dollár),
				'one' => q(USA-dollár),
				'other' => q(USA-dollár),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(USA dollár \(következő napi\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(USA dollár \(aznapi\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayi peso en unidades indexadas),
				'one' => q(Uruguayi peso en unidades indexadas),
				'other' => q(Uruguayi peso en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguay-i peso \(1975–1993\)),
				'one' => q(Uruguayi peso \(1975–1993\)),
				'other' => q(Uruguayi peso \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(uruguay-i peso),
				'one' => q(uruguayi peso),
				'other' => q(uruguayi peso),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(üzbegisztáni szum),
				'one' => q(üzbegisztáni szum),
				'other' => q(üzbegisztáni szum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelai bolivar \(1871–2008\)),
				'one' => q(Venezuelai bolivar \(1871–2008\)),
				'other' => q(Venezuelai bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(venezuelai bolivar),
				'one' => q(venezuelai bolivar),
				'other' => q(venezuelai bolivar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnami dong),
				'one' => q(vietnami dong),
				'other' => q(vietnami dong),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatui vatu),
				'one' => q(vanuatui vatu),
				'other' => q(vanuatui vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(nyugat-szamoai tala),
				'one' => q(nyugat-szamoai tala),
				'other' => q(nyugat-szamoai tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA frank BEAC),
				'one' => q(CFA frank BEAC),
				'other' => q(CFA frank BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Ezüst),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Arany),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Európai kompozit egység),
				'one' => q(Európai kompozit egység),
				'other' => q(Európai kompozit egység),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Európai monetáris egység),
				'one' => q(Európai monetáris egység),
				'other' => q(Európai monetáris egység),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Európai kontó egység \(XBC\)),
				'one' => q(Európai kontó egység \(XBC\)),
				'other' => q(Európai kontó egység \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Európai kontó egység \(XBD\)),
				'one' => q(Európai kontó egység \(XBD\)),
				'other' => q(Európai kontó egység \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(kelet-karibi dollár),
				'one' => q(kelet-karibi dollár),
				'other' => q(kelet-karibi dollár),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Special Drawing Rights),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(európai pénznemegység),
				'one' => q(Európai pénznemegység),
				'other' => q(Európai pénznemegység),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Francia arany frank),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Francia UIC-frank),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA frank BCEAO),
				'one' => q(CFA frank BCEAO),
				'other' => q(CFA frank BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palládium),
				'one' => q(Palládium),
				'other' => q(Palládium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(csendes-óceáni valutaközösségi frank),
				'one' => q(csendes-óceáni valutaközösségi frank),
				'other' => q(csendes-óceáni valutaközösségi frank),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'one' => q(Platina),
				'other' => q(Platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET tőke),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Tesztelési pénznemkód),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ismeretlen pénznem),
				'one' => q(\(ismeretlen pénznem\)),
				'other' => q(\(ismeretlen pénznem\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemeni dínár),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(jemeni rial),
				'one' => q(jemeni rial),
				'other' => q(jemeni rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoszláv kemény dínár),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoszláv új dínár),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoszláv konvertibilis dínár),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Dél-afrikai rand \(pénzügyi\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(dél-afrikai rand),
				'one' => q(dél-afrikai rand),
				'other' => q(dél-afrikai rand),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Zambiai kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(zambiai kwacha),
				'one' => q(zambiai kwacha),
				'other' => q(zambiai kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zairei új zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairei zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwei dollár \(1980–2008\)),
				'one' => q(Zimbabwei dollár \(1980–2008\)),
				'other' => q(Zimbabwei dollár \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwei dollár \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwei dollár \(2008\)),
				'one' => q(Zimbabwei dollár \(2008\)),
				'other' => q(Zimbabwei dollár \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Thot',
							'Paophi',
							'Athür',
							'Koiak',
							'Tübi',
							'Mehir',
							'Phamenóth',
							'Pharmuthi',
							'Pakhónsz',
							'Pauni',
							'Epip',
							'Meszoré',
							'Pi Kogi Enavot'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Thot',
							'Paophi',
							'Athür',
							'Koiak',
							'Tübi',
							'Mehir',
							'Phamenóth',
							'Pharmuthi',
							'Pakhónsz',
							'Pauni',
							'Epip',
							'Meszoré',
							'Pi Kogi Enavot'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Thot',
							'Paophi',
							'Athür',
							'Koiak',
							'Tübi',
							'Mehir',
							'Phamenóth',
							'Pharmuthi',
							'Pakhónsz',
							'Pauni',
							'Epip',
							'Meszoré',
							'Pi Kogi Enavot'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Thot',
							'Paophi',
							'Athür',
							'Koiak',
							'Tübi',
							'Mehir',
							'Phamenóth',
							'Pharmuthi',
							'Pakhónsz',
							'Pauni',
							'Epip',
							'Meszoré',
							'Pi Kogi Enavot'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'jan.',
							'febr.',
							'márc.',
							'ápr.',
							'máj.',
							'jún.',
							'júl.',
							'aug.',
							'szept.',
							'okt.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'Á',
							'M',
							'J',
							'J',
							'A',
							'Sz',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'január',
							'február',
							'március',
							'április',
							'május',
							'június',
							'július',
							'augusztus',
							'szeptember',
							'október',
							'november',
							'december'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan.',
							'febr.',
							'márc.',
							'ápr.',
							'máj.',
							'jún.',
							'júl.',
							'aug.',
							'szept.',
							'okt.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'Á',
							'M',
							'J',
							'J',
							'A',
							'Sz',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'január',
							'február',
							'március',
							'április',
							'május',
							'június',
							'július',
							'augusztus',
							'szeptember',
							'október',
							'november',
							'december'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tisri',
							'Hesván',
							'Kiszlév',
							'Tévész',
							'Svát',
							'Ádár I',
							'Ádár',
							'Niszán',
							'Ijár',
							'Sziván',
							'Tamuz',
							'Áv',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Ádár II'
						],
					},
					wide => {
						nonleap => [
							'Tisri',
							'Hesván',
							'Kiszlév',
							'Tévész',
							'Svát',
							'Ádár I',
							'Ádár',
							'Niszán',
							'Ijár',
							'Sziván',
							'Tamuz',
							'Áv',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Ádár II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tisri',
							'Hesván',
							'Kiszlév',
							'Tévész',
							'Svát',
							'Ádár I',
							'Ádár',
							'Niszán',
							'Ijár',
							'Sziván',
							'Tamuz',
							'Áv',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Ádár II'
						],
					},
					wide => {
						nonleap => [
							'Tisri',
							'Hesván',
							'Kiszlév',
							'Tévész',
							'Svát',
							'Ádár I',
							'Ádár',
							'Niszán',
							'Ijár',
							'Sziván',
							'Tamuz',
							'Áv',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Ádár II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Moh.',
							'Saf.',
							'Réb. 1',
							'Réb. 2',
							'Dsem. I',
							'Dsem. II',
							'Red.',
							'Sab.',
							'Ram.',
							'Sev.',
							'Dsül k.',
							'Dsül h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Moharrem',
							'Safar',
							'Rébi el avvel',
							'Rébi el accher',
							'Dsemádi el avvel',
							'Dsemádi el accher',
							'Redseb',
							'Sabán',
							'Ramadán',
							'Sevvál',
							'Dsül kade',
							'Dsül hedse'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Moharrem',
							'Safar',
							'Rébi I',
							'Rébi II',
							'Dsemádi I',
							'Dsemádi II',
							'Redseb',
							'Sabán',
							'Ramadán',
							'Sevvál',
							'Dsül kade',
							'Dsül hedse'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'H',
						tue => 'K',
						wed => 'Sze',
						thu => 'Cs',
						fri => 'P',
						sat => 'Szo',
						sun => 'V'
					},
					narrow => {
						mon => 'H',
						tue => 'K',
						wed => 'Sz',
						thu => 'Cs',
						fri => 'P',
						sat => 'Sz',
						sun => 'V'
					},
					short => {
						mon => 'H',
						tue => 'K',
						wed => 'Sze',
						thu => 'Cs',
						fri => 'P',
						sat => 'Szo',
						sun => 'V'
					},
					wide => {
						mon => 'hétfő',
						tue => 'kedd',
						wed => 'szerda',
						thu => 'csütörtök',
						fri => 'péntek',
						sat => 'szombat',
						sun => 'vasárnap'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'H',
						tue => 'K',
						wed => 'Sze',
						thu => 'Cs',
						fri => 'P',
						sat => 'Szo',
						sun => 'V'
					},
					narrow => {
						mon => 'H',
						tue => 'K',
						wed => 'Sz',
						thu => 'Cs',
						fri => 'P',
						sat => 'Sz',
						sun => 'V'
					},
					short => {
						mon => 'H',
						tue => 'K',
						wed => 'Sze',
						thu => 'Cs',
						fri => 'P',
						sat => 'Szo',
						sun => 'V'
					},
					wide => {
						mon => 'hétfő',
						tue => 'kedd',
						wed => 'szerda',
						thu => 'csütörtök',
						fri => 'péntek',
						sat => 'szombat',
						sun => 'vasárnap'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {0 => 'I. n.év',
						1 => 'II. n.év',
						2 => 'III. n.év',
						3 => 'IV. n.év'
					},
					narrow => {0 => 'I.',
						1 => 'II.',
						2 => 'III.',
						3 => 'IV.'
					},
					wide => {0 => 'I. negyedév',
						1 => 'II. negyedév',
						2 => 'III. negyedév',
						3 => 'IV. negyedév'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1. n.év',
						1 => '2. n.év',
						2 => '3. n.év',
						3 => '4. n.év'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
					},
					wide => {0 => '1. negyedév',
						1 => '2. negyedév',
						2 => '3. negyedév',
						3 => '4. negyedév'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
	my ($orig, $self) = @_;
	return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'narrow' => {
					'morning1' => q{reggel},
					'afternoon1' => q{du.},
					'noon' => q{dél},
					'night1' => q{éjjel},
					'pm' => q{du.},
					'midnight' => q{éjfél},
					'night2' => q{hajnal},
					'am' => q{de.},
					'morning2' => q{de.},
					'evening1' => q{este},
				},
				'wide' => {
					'am' => q{de.},
					'evening1' => q{este},
					'morning2' => q{délelőtt},
					'night2' => q{hajnal},
					'pm' => q{du.},
					'midnight' => q{éjfél},
					'afternoon1' => q{délután},
					'morning1' => q{reggel},
					'night1' => q{éjjel},
					'noon' => q{dél},
				},
				'abbreviated' => {
					'pm' => q{du.},
					'midnight' => q{éjfél},
					'noon' => q{dél},
					'night1' => q{éjjel},
					'afternoon1' => q{du.},
					'morning1' => q{reggel},
					'evening1' => q{este},
					'am' => q{de.},
					'morning2' => q{de.},
					'night2' => q{hajnal},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{de.},
					'evening1' => q{este},
					'morning2' => q{de.},
					'night2' => q{hajnal},
					'pm' => q{du.},
					'midnight' => q{éjfél},
					'night1' => q{éjjel},
					'noon' => q{dél},
					'afternoon1' => q{du.},
					'morning1' => q{reggel},
				},
				'narrow' => {
					'night2' => q{hajnal},
					'am' => q{de.},
					'morning2' => q{de.},
					'evening1' => q{este},
					'morning1' => q{reggel},
					'afternoon1' => q{du.},
					'noon' => q{dél},
					'night1' => q{éjjel},
					'pm' => q{du.},
					'midnight' => q{éjfél},
				},
				'wide' => {
					'pm' => q{du.},
					'midnight' => q{éjfél},
					'night1' => q{éjjel},
					'noon' => q{dél},
					'morning1' => q{reggel},
					'afternoon1' => q{délután},
					'am' => q{de.},
					'evening1' => q{este},
					'morning2' => q{délelőtt},
					'night2' => q{hajnal},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			abbreviated => {
				'0' => 'BK'
			},
			narrow => {
				'0' => 'BK'
			},
			wide => {
				'0' => 'BK'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'i. e.',
				'1' => 'i. sz.'
			},
			narrow => {
				'0' => 'ie.',
				'1' => 'isz.'
			},
			wide => {
				'0' => 'Krisztus előtt',
				'1' => 'időszámításunk szerint'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'TÉ'
			},
			narrow => {
				'0' => 'TÉ'
			},
			wide => {
				'0' => 'TÉ'
			},
		},
		'indian' => {
		},
		'islamic' => {
			abbreviated => {
				'0' => 'MF'
			},
			narrow => {
				'0' => 'MF'
			},
			wide => {
				'0' => 'MF'
			},
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'R.O.C. előtt',
				'1' => 'R.O.C.'
			},
			narrow => {
				'0' => 'R.O.C. előtt',
				'1' => 'R.O.C.'
			},
			wide => {
				'0' => 'R.O.C. előtt',
				'1' => 'R.O.C.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{G y. MMMM d., EEEE},
			'long' => q{G y. MMMM d.},
			'medium' => q{G y. MMM d.},
			'short' => q{GGGGG y. M. d.},
		},
		'gregorian' => {
			'full' => q{y. MMMM d., EEEE},
			'long' => q{y. MMMM d.},
			'medium' => q{y. MMM d.},
			'short' => q{y. MM. dd.},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{G y. MMMM d., EEEE},
			'long' => q{G y. MMMM d.},
			'medium' => q{G y.MM.dd.},
			'short' => q{GGGGG y.MM.dd.},
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d., E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y.},
			GyMMM => q{G y. MMM},
			GyMMMEd => q{G y. MMM d., E},
			GyMMMd => q{G y. MMM d.},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{M. d., E},
			MMM => q{LLL},
			MMMEd => q{MMM d., E},
			MMMMW => q{MMM W. 'hete'},
			MMMMd => q{MMMM d.},
			MMMd => q{MMM d.},
			Md => q{M. d.},
			d => q{d},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y.},
			yM => q{y. M.},
			yMEd => q{y. MM. dd., E},
			yMMM => q{y. MMM},
			yMMMEd => q{y. MMM d., E},
			yMMMM => q{y. MMMM},
			yMMMd => q{y. MMM d.},
			yMd => q{y. MM. dd.},
			yQQQ => q{y. QQQ},
			yQQQQ => q{y. QQQQ},
			yw => q{Y w. 'hete'},
		},
		'generic' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E h:mm},
			EBhms => q{E h:mm:ss},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d., E},
			Ehm => q{E h:mm},
			Ehms => q{E h:mm:ss},
			Gy => q{G y.},
			GyMMM => q{G y. MMM},
			GyMMMEd => q{G y. MMM d., E},
			GyMMMd => q{G y. MMM d.},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{M. d., E},
			MMM => q{LLL},
			MMMEd => q{MMM d., E},
			MMMMd => q{MMMM d.},
			MMMd => q{MMM d.},
			Md => q{M. d.},
			d => q{d},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			ms => q{mm:ss},
			y => q{G y.},
			yyyy => q{G y.},
			yyyyM => q{G y. MM.},
			yyyyMEd => q{G y. MM. dd., E},
			yyyyMMM => q{G y. MMM},
			yyyyMMMEd => q{G y. MMM d., E},
			yyyyMMMM => q{G y. MMMM},
			yyyyMMMd => q{G y. MMM d.},
			yyyyMd => q{G y. MM. dd.},
			yyyyQQQ => q{G y. QQQ},
			yyyyQQQQ => q{G y. QQQQ},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M.},
			},
			MEd => {
				M => q{M. d., E – M. d., E},
				d => q{M. dd., E – M. d., E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d., E – MMM d., E},
				d => q{MMM d., E – d., E},
			},
			MMMd => {
				M => q{MMM d. – MMM d.},
				d => q{MMM d–d.},
			},
			Md => {
				M => q{M. d. – M. d.},
				d => q{M. d–d.},
			},
			d => {
				d => q{d–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y. MM–MM.},
				y => q{y. MM. – y. MM.},
			},
			yMEd => {
				M => q{y. MM. dd., E – MM. dd., E},
				d => q{y. MM. dd., E – dd., E},
				y => q{y. MM. dd., E – y. MM. dd., E},
			},
			yMMM => {
				M => q{y. MMM–MMM},
				y => q{y. MMM – y. MMM},
			},
			yMMMEd => {
				M => q{y. MMM d., E – MMM d., E},
				d => q{y. MMM d., E – d., E},
				y => q{y. MMM d., E – y. MMM d., E},
			},
			yMMMM => {
				M => q{y. MMMM–MMMM},
				y => q{y. MMMM – y. MMMM},
			},
			yMMMd => {
				M => q{y. MMM d. – MMM d.},
				d => q{y. MMM d–d.},
				y => q{y. MMM d. – y. MMM d.},
			},
			yMd => {
				M => q{y. MM. dd. – MM. dd.},
				d => q{y. MM. dd–dd.},
				y => q{y. MM. dd. – y. MM. dd.},
			},
		},
		'generic' => {
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M.},
			},
			MEd => {
				M => q{MM. dd., E – MM. dd., E},
				d => q{MM. dd., E – MM. dd., E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d., E – MMM d., E},
				d => q{MMM d., E – d., E},
			},
			MMMd => {
				M => q{MMM d. – MMM d.},
				d => q{MMM d–d.},
			},
			Md => {
				M => q{MM. dd. – MM. dd.},
				d => q{MM. dd–dd.},
			},
			d => {
				d => q{d–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			y => {
				y => q{G y–y.},
			},
			yM => {
				M => q{G y. MM–MM.},
				y => q{G y. MM. – y. MM.},
			},
			yMEd => {
				M => q{G y. MM. dd., E – MM. dd., E},
				d => q{G y. MM. dd., E – dd., E},
				y => q{G y. MM. dd., E – y. MM. dd., E},
			},
			yMMM => {
				M => q{G y. MMM–MMM},
				y => q{G y. MMM – y. MMM},
			},
			yMMMEd => {
				M => q{G y. MMM d., E – MMM d., E},
				d => q{G y. MMM d., E – MMM d., E},
				y => q{G y. MMM d., E – y. MMM d., E},
			},
			yMMMM => {
				M => q{G y. MMMM–MMMM},
				y => q{G y. MMMM – y. MMMM},
			},
			yMMMd => {
				M => q{G y. MMM d. – MMM d.},
				d => q{G y. MMM d–d.},
				y => q{G y. MMM d. – y. MMM d.},
			},
			yMd => {
				M => q{G y. MM. dd. – MM. dd.},
				d => q{G y. MM. dd–dd.},
				y => q{G y. MM. dd. – y. MM. dd.},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} idő),
		regionFormat => q({0} nyári idő),
		regionFormat => q({0} zónaidő),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre nyári idő#,
				'generic' => q#Acre idő#,
				'standard' => q#Acre zónaidő#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#afganisztáni idő#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addisz-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algír#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairó#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es-Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dzsibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Ajún#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartúm#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabó#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunisz#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#közép-afrikai téli idő#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#kelet-afrikai téli idő#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#dél-afrikai téli idő#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#nyugat-afrikai nyári idő#,
				'generic' => q#nyugat-afrikai időzóna#,
				'standard' => q#nyugat-afrikai téli idő#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaszkai nyári idő#,
				'generic' => q#alaszkai idő#,
				'standard' => q#alaszkai zónaidő#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almati nyári idő#,
				'generic' => q#Almati idő#,
				'standard' => q#Almati zónaidő#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazóniai nyári idő#,
				'generic' => q#amazóniai idő#,
				'standard' => q#amazóniai téli idő#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmán-szigetek#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexikóváros#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Észak-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Észak-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Észak-Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Río Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#középső államokbeli nyári idő#,
				'generic' => q#középső államokbeli idő#,
				'standard' => q#középső államokbeli zónaidő#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#keleti államokbeli nyári idő#,
				'generic' => q#keleti államokbeli idő#,
				'standard' => q#keleti államokbeli zónaidő#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hegyvidéki nyári idő#,
				'generic' => q#hegyvidéki idő#,
				'standard' => q#hegyvidéki zónaidő#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#csendes-óceáni nyári idő#,
				'generic' => q#csendes-óceáni idő#,
				'standard' => q#csendes-óceáni zónaidő#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadíri nyári idő#,
				'generic' => q#Anadiri idő#,
				'standard' => q#Anadíri zónaidő#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vosztok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#apiai nyári idő#,
				'generic' => q#apiai idő#,
				'standard' => q#apiai téli idő#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtaui nyári idő#,
				'generic' => q#Aqtaui idő#,
				'standard' => q#Aqtaui zónaidő#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtobei nyári idő#,
				'generic' => q#Aqtobei idő#,
				'standard' => q#Aqtobei zónaidő#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arab nyári idő#,
				'generic' => q#arab idő#,
				'standard' => q#arab téli idő#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentínai nyári idő#,
				'generic' => q#argentínai idő#,
				'standard' => q#argentínai téli idő#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#nyugat-argentínai nyári idő#,
				'generic' => q#nyugat-argentínai időzóna#,
				'standard' => q#nyugat-argentínai téli idő#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#örményországi nyári idő#,
				'generic' => q#örményországi idő#,
				'standard' => q#örményországi téli idő#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Áden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma-Ata#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrút#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biskek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Csita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Csojbalszan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaszkusz#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gáza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutszk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzsálem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamcsatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karacsi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasznojarszk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kucseng#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makaó#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadán#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznyeck#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novoszibirszk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omszk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenjan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijád#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Si Minh-város#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Szahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Szamarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Szöul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sanghaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Szingapúr#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Szrednekolimszk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbiliszi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokió#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomszk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulánbátor#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Uszty-Nyera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientián#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vlagyivosztok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutszk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekatyerinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlanti-óceáni nyári idő#,
				'generic' => q#atlanti-óceáni idő#,
				'standard' => q#atlanti-óceáni zónaidő#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azori-szigetek#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanári-szigetek#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Zöld-foki szigetek#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feröer#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Déli-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Szent Ilona#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#közép-ausztráliai nyári idő#,
				'generic' => q#közép-ausztráliai idő#,
				'standard' => q#közép-ausztráliai téli idő#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#közép-nyugat-ausztráliai nyári idő#,
				'generic' => q#közép-nyugat-ausztráliai idő#,
				'standard' => q#közép-nyugat-ausztráliai téli idő#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#kelet-ausztráliai nyári idő#,
				'generic' => q#kelet-ausztráliai idő#,
				'standard' => q#kelet-ausztráliai téli idő#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#nyugat-ausztráliai nyári idő#,
				'generic' => q#nyugat-ausztráliai idő#,
				'standard' => q#nyugat-ausztráliai téli idő#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajdzsáni nyári idő#,
				'generic' => q#azerbajdzsáni idő#,
				'standard' => q#azerbajdzsáni téli idő#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#azori nyári idő#,
				'generic' => q#azori időzóna#,
				'standard' => q#azori téli idő#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladesi nyári idő#,
				'generic' => q#bangladesi idő#,
				'standard' => q#bangladesi téli idő#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#butáni idő#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolíviai téli idő#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brazíliai nyári idő#,
				'generic' => q#brazíliai idő#,
				'standard' => q#brazíliai téli idő#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam-i idő#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#zöld-foki-szigeteki nyári idő#,
				'generic' => q#zöld-foki-szigeteki időzóna#,
				'standard' => q#zöld-foki-szigeteki téli idő#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#chamorrói téli idő#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#chathami nyári idő#,
				'generic' => q#chathami idő#,
				'standard' => q#chathami téli idő#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilei nyári idő#,
				'generic' => q#chilei időzóna#,
				'standard' => q#chilei téli idő#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kínai nyári idő#,
				'generic' => q#kínai idő#,
				'standard' => q#kínai téli idő#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#csojbalszani nyári idő#,
				'generic' => q#csojbalszani idő#,
				'standard' => q#csojbalszani téli idő#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#karácsony-szigeti téli idő#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#kókusz-szigeteki téli idő#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolumbiai nyári idő#,
				'generic' => q#kolumbiai idő#,
				'standard' => q#kolumbiai téli idő#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#cook-szigeteki fél nyári idő#,
				'generic' => q#cook-szigeteki idő#,
				'standard' => q#cook-szigeteki téli idő#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubai nyári idő#,
				'generic' => q#kubai időzóna#,
				'standard' => q#kubai téli idő#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#davisi idő#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#dumont-d’Urville-i idő#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#kelet-timori téli idő#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#húsvét-szigeti nyári idő#,
				'generic' => q#húsvét-szigeti időzóna#,
				'standard' => q#húsvét-szigeti téli idő#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ecuadori téli idő#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#egyezményes koordinált világidő#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ismeretlen város#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amszterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Asztrahán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athén#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrád#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Pozsony#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüsszel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Koppenhága#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#ír nyári idő#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltár#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man-sziget#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Isztanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinyingrád#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisszabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#brit nyári idő#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Málta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minszk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moszkva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Párizs#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prága#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Róma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Szamara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Szarajevó#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Szaratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Szimferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Szófia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovszk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ungvár#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Bécs#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgográd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsó#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zágráb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozsje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#közép-európai nyári idő#,
				'generic' => q#közép-európai időzóna#,
				'standard' => q#közép-európai téli idő#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#kelet-európai nyári idő#,
				'generic' => q#kelet-európai időzóna#,
				'standard' => q#kelet-európai téli idő#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#minszki idő#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#nyugat-európai nyári idő#,
				'generic' => q#nyugat-európai időzóna#,
				'standard' => q#nyugat-európai téli idő#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falkland-szigeteki nyári idő#,
				'generic' => q#falkland-szigeteki idő#,
				'standard' => q#falkland-szigeteki téli idő#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fidzsi nyári idő#,
				'generic' => q#fidzsi idő#,
				'standard' => q#fidzsi téli idő#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#francia-guyanai idő#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#francia déli és antarktiszi idő#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#greenwichi középidő, téli idő#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#galápagosi téli idő#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#gambieri idő#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#grúziai nyári idő#,
				'generic' => q#grúziai idő#,
				'standard' => q#grúziai téli idő#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#gilbert-szigeteki idő#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#kelet-grönlandi nyári idő#,
				'generic' => q#kelet-grönlandi időzóna#,
				'standard' => q#kelet-grönlandi téli idő#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#nyugat-grönlandi nyári idő#,
				'generic' => q#nyugat-grönlandi időzóna#,
				'standard' => q#nyugat-grönlandi téli idő#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guami zónaidő#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#öbölbeli téli idő#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyanai téli idő#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#hawaii-aleuti nyári idő#,
				'generic' => q#hawaii-aleuti időzóna#,
				'standard' => q#hawaii-aleuti téli idő#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkongi nyári idő#,
				'generic' => q#hongkongi időzóna#,
				'standard' => q#hongkongi téli idő#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#hovdi nyári idő#,
				'generic' => q#hovdi idő#,
				'standard' => q#hovdi téli idő#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indiai téli idő#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Karácsony-sziget#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kókusz-sziget#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoró#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldív-szigetek#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#indiai-óceáni idő#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indokínai idő#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#közép-indonéziai idő#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#kelet-indonéziai idő#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#nyugat-indonéziai téli idő#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iráni nyári idő#,
				'generic' => q#iráni idő#,
				'standard' => q#iráni téli idő#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#irkutszki nyári idő#,
				'generic' => q#irkutszki idő#,
				'standard' => q#irkutszki téli idő#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#izraeli nyári idő#,
				'generic' => q#izraeli idő#,
				'standard' => q#izraeli téli idő#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japán nyári idő#,
				'generic' => q#japán idő#,
				'standard' => q#japán téli idő#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovszk-kamcsatkai nyári idő#,
				'generic' => q#Petropavlovszk-kamcsatkai idő#,
				'standard' => q#Petropavlovszk-kamcsatkai zónaidő#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#kelet-kazahsztáni idő#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#nyugat-kazahsztáni idő#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koreai nyári idő#,
				'generic' => q#koreai idő#,
				'standard' => q#koreai téli idő#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#kosraei idő#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krasznojarszki nyári idő#,
				'generic' => q#krasznojarszki idő#,
				'standard' => q#krasznojarszki téli idő#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgizisztáni idő#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lankai idő#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#sor-szigeteki idő#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe-szigeti nyári idő#,
				'generic' => q#Lord Howe-szigeti idő#,
				'standard' => q#Lord Howe-szigeti téli idő#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macaui nyári idő#,
				'generic' => q#Macaui idő#,
				'standard' => q#Macaui zónaidő#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#macquarie-szigeti téli idő#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#magadáni nyári idő#,
				'generic' => q#magadáni idő#,
				'standard' => q#magadani téli idő#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malajziai idő#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldív-szigeteki idő#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#marquises-szigeteki idő#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#marshall-szigeteki idő#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauritiusi nyári idő#,
				'generic' => q#mauritiusi időzóna#,
				'standard' => q#mauritiusi téli idő#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#mawsoni idő#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#északnyugat-mexikói nyári idő#,
				'generic' => q#északnyugat-mexikói idő#,
				'standard' => q#északnyugat-mexikói zónaidő#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexikói csendes-óceáni nyári idő#,
				'generic' => q#mexikói csendes-óceáni idő#,
				'standard' => q#mexikói csendes-óceáni zónaidő#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ulánbátori nyári idő#,
				'generic' => q#ulánbátori idő#,
				'standard' => q#ulánbátori téli idő#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moszkvai nyári idő#,
				'generic' => q#moszkvai idő#,
				'standard' => q#moszkvai téli idő#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#mianmari idő#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#naurui idő#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepáli idő#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#új-kaledóniai nyári idő#,
				'generic' => q#új-kaledóniai idő#,
				'standard' => q#új-kaledóniai téli idő#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#új-zélandi nyári idő#,
				'generic' => q#új-zélandi idő#,
				'standard' => q#új-zélandi téli idő#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#új-fundlandi nyári idő#,
				'generic' => q#új-fundlandi idő#,
				'standard' => q#új-fundlandi zónaidő#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niuei idő#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#norfolk-szigeteki idő#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-i nyári idő#,
				'generic' => q#Fernando de Noronha-i idő#,
				'standard' => q#Fernando de Noronha-i téli idő#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Észak-mariana-szigeteki idő#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#novoszibirszki nyári idő#,
				'generic' => q#novoszibirszki idő#,
				'standard' => q#novoszibirszki téli idő#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#omszki nyári idő#,
				'generic' => q#omszki idő#,
				'standard' => q#omszki téli idő#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham-szigetek#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Húsvét-szigetek#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidzsi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos-szigetek#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier-szigetek#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati-sziget#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae-szigetek#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein-zátony#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro-zátony#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas-szigetek#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway-szigetek#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn-szigetek#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape-szigetek#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Truk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake-sziget#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakisztáni nyári idő#,
				'generic' => q#pakisztáni idő#,
				'standard' => q#pakisztáni téli idő#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palaui idő#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#pápua új-guineai idő#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayi nyári idő#,
				'generic' => q#paraguayi idő#,
				'standard' => q#paraguayi téli idő#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#perui nyári idő#,
				'generic' => q#perui idő#,
				'standard' => q#perui téli idő#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#fülöp-szigeteki nyári idő#,
				'generic' => q#fülöp-szigeteki idő#,
				'standard' => q#fülöp-szigeteki téli idő#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#phoenix-szigeteki téli idő#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre és Miquelon-i nyári idő#,
				'generic' => q#Saint-Pierre és Miquelon-i idő#,
				'standard' => q#Saint-Pierre és Miquelon-i zónaidő#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#pitcairn-szigeteki idő#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ponape-szigeti idő#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#phenjani idő#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylordai nyári idő#,
				'generic' => q#Qyzylordai idő#,
				'standard' => q#Qyzylordai zónaidő#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#réunioni idő#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#rotherai idő#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#szahalini nyári idő#,
				'generic' => q#szahalini idő#,
				'standard' => q#szahalini téli idő#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Szamarai nyári idő#,
				'generic' => q#Szamarai idő#,
				'standard' => q#Szamarai zónaidő#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#szamoai nyári idő#,
				'generic' => q#szamoai idő#,
				'standard' => q#szamoai téli idő#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychelle-szigeteki idő#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#szingapúri téli idő#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#salamon-szigeteki idő#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#déli-georgiai idő#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#szurinámi idő#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#syowai idő#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahiti idő#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#taipei nyári idő#,
				'generic' => q#taipei idő#,
				'standard' => q#taipei téli idő#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tádzsikisztáni idő#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tokelaui idő#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tongai nyári idő#,
				'generic' => q#tongai idő#,
				'standard' => q#tongai téli idő#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#truki idő#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#türkmenisztáni nyári idő#,
				'generic' => q#türkmenisztáni idő#,
				'standard' => q#türkmenisztáni téli idő#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvalui idő#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayi nyári idő#,
				'generic' => q#uruguayi idő#,
				'standard' => q#uruguayi téli idő#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#üzbegisztáni nyári idő#,
				'generic' => q#üzbegisztáni idő#,
				'standard' => q#üzbegisztáni téli idő#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatui nyári idő#,
				'generic' => q#vanuatui idő#,
				'standard' => q#vanuatui téli idő#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelai idő#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#vlagyivosztoki nyári idő#,
				'generic' => q#vlagyivosztoki idő#,
				'standard' => q#vlagyivosztoki téli idő#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#volgográdi nyári idő#,
				'generic' => q#volgográdi idő#,
				'standard' => q#volgográdi téli idő#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#vosztoki idő#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#wake-szigeti idő#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis és Futuna-i idő#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#jakutszki nyári idő#,
				'generic' => q#jakutszki idő#,
				'standard' => q#jakutszki téli idő#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#jekatyerinburgi nyári idő#,
				'generic' => q#jekatyerinburgi idő#,
				'standard' => q#jekatyerinburgi téli idő#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
