=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Hu - Package for language Hungarian

=cut

package Locale::CLDR::Locales::Hu;
# This file auto generated from Data\common\main\hu.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
        use bigfloat;
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
					rule => q(ezer[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-initial←­ezer[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-initial←­millió[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-initial←­milliárd[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-initial←­billió[­→→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-initial←­billiárd[­→→]),
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
					rule => q(←←­ezer[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←←­millió[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←←­milliárd[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←­billió[­→→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←←­billiárd[­→→]),
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
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
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
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(ezer­→→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-initial←­ezr→→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-initial←­ezer­→→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-initial←­milliom­→%%spellout-ordinal-odik→),
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
					rule => q(nulladik),
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
					rule => q(←%spellout-cardinal-verbose←­ezr→→),
				},
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-verbose←­ezer­→→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-verbose←­milliom­→%%spellout-ordinal-verbose-odik→),
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
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'apc' => 'levantei arab',
 				'ar' => 'arab',
 				'ar_001' => 'modern szabványos arab',
 				'arc' => 'arámi',
 				'arn' => 'mapucse',
 				'arp' => 'arapaho',
 				'ars' => 'nedzsdi arab',
 				'ars@alt=menu' => 'arab, nedzsdi',
 				'arw' => 'aravak',
 				'as' => 'asszámi',
 				'asa' => 'asu',
 				'ast' => 'asztúr',
 				'atj' => 'attikamek',
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
 				'bgc' => 'haryanvi',
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
 				'ccp' => 'csakma',
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
 				'ckb@alt=variant' => 'kurd, szoráni',
 				'clc' => 'csilkotin',
 				'co' => 'korzikai',
 				'cop' => 'kopt',
 				'cr' => 'krí',
 				'crg' => 'micsif',
 				'crh' => 'krími tatár',
 				'crj' => 'délkeleti krí',
 				'crk' => 'síksági krí',
 				'crl' => 'északkeleti krí',
 				'crm' => 'moose krí',
 				'crr' => 'karolinai algonkin',
 				'crs' => 'szeszelva kreol francia',
 				'cs' => 'cseh',
 				'csb' => 'kasub',
 				'csw' => 'mocsári krí',
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
 				'fa_AF' => 'dari',
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
 				'hax' => 'déli haida',
 				'he' => 'héber',
 				'hi' => 'hindi',
 				'hi_Latn' => 'hindi (latin)',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'ilokano',
 				'hit' => 'hettita',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'horvát',
 				'hsb' => 'felső-szorb',
 				'hsn' => 'xiang kínai',
 				'ht' => 'haiti kreol',
 				'hu' => 'magyar',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
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
 				'ikt' => 'nyugat-kanadai inuit',
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
 				'kgp' => 'kaingang',
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
 				'kwk' => 'kwakʼwala',
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
 				'lij' => 'ligur',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'lmo' => 'lombard',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongó',
 				'lou' => 'louisianai kreol',
 				'loz' => 'lozi',
 				'lrc' => 'északi luri',
 				'lsm' => 'samia',
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
 				'moe' => 'innu-aimun',
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
 				'ojb' => 'északnyugati odzsibva',
 				'ojc' => 'középvidéki odzsibva',
 				'ojs' => 'odzsi-krí',
 				'ojw' => 'nyugati odzsibva',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'oszét',
 				'osa' => 'osage',
 				'ota' => 'oszmán-török',
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
 				'pis' => 'pidzsin',
 				'pl' => 'lengyel',
 				'pon' => 'pohnpei',
 				'pqm' => 'maliseet-passamaquoddy',
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
 				'rhg' => 'rohingja',
 				'rm' => 'rétoromán',
 				'rn' => 'kirundi',
 				'ro' => 'román',
 				'ro_MD' => 'moldvai',
 				'rof' => 'rombo',
 				'rom' => 'roma',
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
 				'slh' => 'déli lushootseed',
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
 				'str' => 'szorosmenti salish',
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
 				'szl' => 'sziléziai',
 				'ta' => 'tamil',
 				'tce' => 'déli tutchone',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teszó',
 				'ter' => 'terenó',
 				'tet' => 'tetum',
 				'tg' => 'tadzsik',
 				'tgx' => 'tagish',
 				'th' => 'thai',
 				'tht' => 'tahltan',
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
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'török',
 				'trv' => 'tarokó',
 				'ts' => 'conga',
 				'tsi' => 'csimsiáni',
 				'tt' => 'tatár',
 				'ttm' => 'északi tutchone',
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
 				'vec' => 'velencei',
 				'vi' => 'vietnámi',
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
 				'yrl' => 'nheengatu',
 				'yue' => 'kantoni',
 				'yue@alt=menu' => 'kantoni kínai',
 				'za' => 'zsuang',
 				'zap' => 'zapoték',
 				'zbl' => 'Bliss jelképrendszer',
 				'zen' => 'zenaga',
 				'zgh' => 'marokkói tamazight',
 				'zh' => 'kínai',
 				'zh@alt=menu' => 'mandarin',
 				'zh_Hans' => 'egyszerűsített kínai',
 				'zh_Hans@alt=long' => 'kínai (egyszerűsített)',
 				'zh_Hant' => 'hagyományos kínai',
 				'zh_Hant@alt=long' => 'kínai (hagyományos)',
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
			'Adlm' => 'Adlam',
 			'Aghb' => 'Kaukázusi albaniai',
 			'Arab' => 'Arab',
 			'Arab@alt=variant' => 'Perzsa-arab',
 			'Aran' => 'Nasztalik',
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
 			'Cpmn' => 'Ciprusi-minószi',
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
 			'Hanb' => 'Han bopomofóval',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Egyszerűsített',
 			'Hans@alt=stand-alone' => 'Egyszerűsített kínai',
 			'Hant' => 'Hagyományos',
 			'Hant@alt=stand-alone' => 'Hagyományos kínai',
 			'Hebr' => 'Héber',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anatóliai hieroglifák',
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
 			'Nbat' => 'Nabateus',
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
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Redzsang',
 			'Rohg' => 'Hanifi',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runikus',
 			'Samr' => 'Szamaritán',
 			'Sara' => 'Szarati',
 			'Saur' => 'Szaurastra',
 			'Sgnw' => 'Jelírás',
 			'Shaw' => 'Shaw ábécé',
 			'Sidd' => 'Sziddham',
 			'Sinh' => 'Szingaléz',
 			'Sogd' => 'Szogd',
 			'Sogo' => 'Ószogd',
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
 			'202' => 'Szubszaharai Afrika',
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
 			'CD' => 'Kongó – Kinshasa',
 			'CD@alt=variant' => 'Kongó (KDK)',
 			'CF' => 'Közép-afrikai Köztársaság',
 			'CG' => 'Kongó – Brazzaville',
 			'CG@alt=variant' => 'Kongó (Köztársaság)',
 			'CH' => 'Svájc',
 			'CI' => 'Elefántcsontpart',
 			'CK' => 'Cook-szigetek',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kína',
 			'CO' => 'Kolumbia',
 			'CP' => 'Clipperton-sziget',
 			'CQ' => 'Sark',
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
 			'FO' => 'Feröer szigetek',
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
 			'IO@alt=chagos' => 'Chagos-szigetcsoport',
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
 			'MK' => 'Észak-Macedónia',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar',
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
 			'NZ@alt=variant' => 'Aotearoa (Új-Zéland)',
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
 			'PS' => 'Palesztin Autonómia',
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
 			'SZ@alt=variant' => 'Eswatini',
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
 			'VN' => 'Vietnám',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis és Futuna',
 			'WS' => 'Szamoa',
 			'XA' => 'Pszeudo-nyelvjárások',
 			'XB' => 'Pszeudo-kétirányú',
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
 				'islamic' => q{Hidzsra naptár},
 				'islamic-civil' => q{Hidzsra naptár (táblázatos, polgári)},
 				'islamic-umalqura' => q{Hidzsra naptár (Umm al-Qura)},
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
 				'emoji' => q{Emodzsi rendezési sorrend},
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
 				'zhuyin' => q{Zujin rendezési sorrend},
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
 				'cakm' => q{Csakma számjegyek},
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
 				'java' => q{Jávai számjegyek},
 				'jpan' => q{Japán számok},
 				'jpanfin' => q{Japán pénzügyi számok},
 				'khmr' => q{Khmer számjegyek},
 				'knda' => q{Kannada számjegyek},
 				'laoo' => q{Lao számjegyek},
 				'latn' => q{Nyugati számjegyek},
 				'mlym' => q{Malajálam számjegyek},
 				'mong' => q{Mongol számjegyek},
 				'mtei' => q{Meitei Mayek számjegyek},
 				'mymr' => q{Mianmari számjegyek},
 				'native' => q{Natív számjegyek},
 				'olck' => q{Ol Chiki számjegyek},
 				'orya' => q{Orija számjegyek},
 				'roman' => q{Római számok},
 				'romanlow' => q{Római kisbetűs számok},
 				'taml' => q{Hagyományos tamil számjegyek},
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
			auxiliary => qr{[àăâåäãā æ ç èĕêëē ìĭîïī ñ òŏôøō œ q ùŭûū w x yÿ]},
			index => ['AÁ', 'B', 'C', '{CS}', 'D', '{DZ}', '{DZS}', 'EÉ', 'F', 'G', '{GY}', 'H', 'IÍ', 'J', 'K', 'L', '{LY}', 'M', 'N', '{NY}', 'OÓ', 'ÖŐ', 'P', 'Q', 'R', 'S', '{SZ}', 'T', '{TY}', 'UÚ', 'ÜŰ', 'V', 'W', 'X', 'Y', 'Z', '{ZS}'],
			main => qr{[aá b c {cs} {ccs} d {dz} {ddz} {dzs} {ddzs} eé f g {gy} {ggy} h ií j k l {ly} {lly} m n {ny} {nny} oó öő p r s {sz} {ssz} t {ty} {tty} uú üű v z {zs} {zzs}]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ – , ; \: ! ? . … '’ "”„ « » ( ) \[ \] \{ \} ⟨ ⟩ § @ * / \& # ~ ⁒]},
		};
	},
EOT
: sub {
		return { index => ['AÁ', 'B', 'C', '{CS}', 'D', '{DZ}', '{DZS}', 'EÉ', 'F', 'G', '{GY}', 'H', 'IÍ', 'J', 'K', 'L', '{LY}', 'M', 'N', '{NY}', 'OÓ', 'ÖŐ', 'P', 'Q', 'R', 'S', '{SZ}', 'T', '{TY}', 'UÚ', 'ÜŰ', 'V', 'W', 'X', 'Y', 'Z', '{ZS}'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
		};
	},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(kardinális irány),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kardinális irány),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} g gyorsulás),
						'other' => q({0} g gyorsulás),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g gyorsulás),
						'other' => q({0} g gyorsulás),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(méter per másodpercnégyzet),
						'one' => q({0} méter per másodpercnégyzet),
						'other' => q({0} méter per másodpercnégyzet),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(méter per másodpercnégyzet),
						'one' => q({0} méter per másodpercnégyzet),
						'other' => q({0} méter per másodpercnégyzet),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} ívperc),
						'other' => q({0} ívperc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} ívperc),
						'other' => q({0} ívperc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} ívmásodperc),
						'other' => q({0} ívmásodperc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} ívmásodperc),
						'other' => q({0} ívmásodperc),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radián),
						'one' => q({0} radián),
						'other' => q({0} radián),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radián),
						'one' => q({0} radián),
						'other' => q({0} radián),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(fordulat),
						'one' => q({0} fordulat),
						'other' => q({0} fordulat),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(fordulat),
						'one' => q({0} fordulat),
						'other' => q({0} fordulat),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(hold),
						'one' => q({0} hold),
						'other' => q({0} hold),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(hold),
						'one' => q({0} hold),
						'other' => q({0} hold),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektár),
						'one' => q({0} hektár),
						'other' => q({0} hektár),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektár),
						'one' => q({0} hektár),
						'other' => q({0} hektár),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(négyzetcentiméter),
						'one' => q({0} négyzetcentiméter),
						'other' => q({0} négyzetcentiméter),
						'per' => q({0}/négyzetcentiméter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(négyzetcentiméter),
						'one' => q({0} négyzetcentiméter),
						'other' => q({0} négyzetcentiméter),
						'per' => q({0}/négyzetcentiméter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(négyzetláb),
						'one' => q({0} négyzetláb),
						'other' => q({0} négyzetláb),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(négyzetláb),
						'one' => q({0} négyzetláb),
						'other' => q({0} négyzetláb),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(négyzethüvelyk),
						'one' => q({0} négyzethüvelyk),
						'other' => q({0} négyzethüvelyk),
						'per' => q({0}/négyzethüvelyk),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(négyzethüvelyk),
						'one' => q({0} négyzethüvelyk),
						'other' => q({0} négyzethüvelyk),
						'per' => q({0}/négyzethüvelyk),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(négyzetkilométer),
						'one' => q({0} négyzetkilométer),
						'other' => q({0} négyzetkilométer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(négyzetkilométer),
						'one' => q({0} négyzetkilométer),
						'other' => q({0} négyzetkilométer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(négyzetméter),
						'one' => q({0} négyzetméter),
						'other' => q({0} négyzetméter),
						'per' => q({0}/négyzetméter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(négyzetméter),
						'one' => q({0} négyzetméter),
						'other' => q({0} négyzetméter),
						'per' => q({0}/négyzetméter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(négyzetmérföld),
						'one' => q({0} négyzetmérföld),
						'other' => q({0} négyzetmérföld),
						'per' => q({0}/négyzetmérföld),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(négyzetmérföld),
						'one' => q({0} négyzetmérföld),
						'other' => q({0} négyzetmérföld),
						'per' => q({0}/négyzetmérföld),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(négyzetyard),
						'one' => q({0} négyzetyard),
						'other' => q({0} négyzetyard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(négyzetyard),
						'one' => q({0} négyzetyard),
						'other' => q({0} négyzetyard),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0} item),
						'other' => q({0} item),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} item),
						'other' => q({0} item),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm/deciliter),
						'one' => q({0} milligramm/deciliter),
						'other' => q({0} milligramm/deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm/deciliter),
						'one' => q({0} milligramm/deciliter),
						'other' => q({0} milligramm/deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} millimól/liter),
						'other' => q({0} millimól/liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} millimól/liter),
						'other' => q({0} millimól/liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mól),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mól),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} százalék),
						'other' => q({0} százalék),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} százalék),
						'other' => q({0} százalék),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ezrelék),
						'other' => q({0} ezrelék),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ezrelék),
						'other' => q({0} ezrelék),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0} részecske/millió),
						'other' => q({0} részecske/millió),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0} részecske/millió),
						'other' => q({0} részecske/millió),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(tízezrelék),
						'one' => q({0} tízezrelék),
						'other' => q({0} tízezrelék),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(tízezrelék),
						'one' => q({0} tízezrelék),
						'other' => q({0} tízezrelék),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter/100 km),
						'one' => q({0} liter/100 km),
						'other' => q({0} liter/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter/100 km),
						'one' => q({0} liter/100 km),
						'other' => q({0} liter/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter per kilométer),
						'one' => q({0} liter per kilométer),
						'other' => q({0} liter per kilométer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter per kilométer),
						'one' => q({0} liter per kilométer),
						'other' => q({0} liter per kilométer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mérföld per gallon),
						'one' => q({0} mérföld per gallon),
						'other' => q({0} mérföld per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mérföld per gallon),
						'one' => q({0} mérföld per gallon),
						'other' => q({0} mérföld per gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mérföld/birodalmi gallon),
						'one' => q({0} mérföld/birodalmi gallon),
						'other' => q({0} mérföld/birodalmi gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mérföld/birodalmi gallon),
						'one' => q({0} mérföld/birodalmi gallon),
						'other' => q({0} mérföld/birodalmi gallon),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabájt),
						'one' => q({0} gigabájt),
						'other' => q({0} gigabájt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabájt),
						'one' => q({0} gigabájt),
						'other' => q({0} gigabájt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobájt),
						'one' => q({0} kilobájt),
						'other' => q({0} kilobájt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobájt),
						'one' => q({0} kilobájt),
						'other' => q({0} kilobájt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabájt),
						'one' => q({0} megabájt),
						'other' => q({0} megabájt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabájt),
						'one' => q({0} megabájt),
						'other' => q({0} megabájt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabájt),
						'one' => q({0} petabájt),
						'other' => q({0} petabájt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabájt),
						'one' => q({0} petabájt),
						'other' => q({0} petabájt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabájt),
						'one' => q({0} terabájt),
						'other' => q({0} terabájt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabájt),
						'one' => q({0} terabájt),
						'other' => q({0} terabájt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(évszázad),
						'one' => q({0} évszázad),
						'other' => q({0} évszázad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(évszázad),
						'one' => q({0} évszázad),
						'other' => q({0} évszázad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} nap),
						'other' => q({0} nap),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} nap),
						'other' => q({0} nap),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'one' => q({0} nap),
						'other' => q({0} nap),
					},
					# Core Unit Identifier
					'day-person' => {
						'one' => q({0} nap),
						'other' => q({0} nap),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(évtized),
						'one' => q({0} évtized),
						'other' => q({0} évtized),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(évtized),
						'one' => q({0} évtized),
						'other' => q({0} évtized),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(óra),
						'one' => q({0} óra),
						'other' => q({0} óra),
						'per' => q({0}/óra),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(óra),
						'one' => q({0} óra),
						'other' => q({0} óra),
						'per' => q({0}/óra),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikroszekundum),
						'one' => q({0} mikroszekundum),
						'other' => q({0} mikroszekundum),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikroszekundum),
						'one' => q({0} mikroszekundum),
						'other' => q({0} mikroszekundum),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ezredmásodperc),
						'one' => q({0} ezredmásodperc),
						'other' => q({0} ezredmásodperc),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ezredmásodperc),
						'one' => q({0} ezredmásodperc),
						'other' => q({0} ezredmásodperc),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(perc),
						'one' => q({0} perc),
						'other' => q({0} perc),
						'per' => q({0}/perc),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(perc),
						'one' => q({0} perc),
						'other' => q({0} perc),
						'per' => q({0}/perc),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hónap),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hónap),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanoszekundum),
						'one' => q({0} nanoszekundum),
						'other' => q({0} nanoszekundum),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanoszekundum),
						'one' => q({0} nanoszekundum),
						'other' => q({0} nanoszekundum),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(negyedév),
						'one' => q({0} negyedév),
						'other' => q({0} negyedév),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(negyedév),
						'one' => q({0} negyedév),
						'other' => q({0} negyedév),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(másodperc),
						'one' => q({0} másodperc),
						'other' => q({0} másodperc),
						'per' => q({0}/másodperc),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(másodperc),
						'one' => q({0} másodperc),
						'other' => q({0} másodperc),
						'per' => q({0}/másodperc),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} hét),
						'other' => q({0} hét),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} hét),
						'other' => q({0} hét),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} év),
						'other' => q({0} év),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} év),
						'other' => q({0} év),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(brit hőegység),
						'one' => q({0} brit hőegység),
						'other' => q({0} brit hőegység),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(brit hőegység),
						'one' => q({0} brit hőegység),
						'other' => q({0} brit hőegység),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kalória),
						'one' => q({0} kalória),
						'other' => q({0} kalória),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalória),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalória),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalória),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalória),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowattóra),
						'one' => q({0} kilowattóra),
						'other' => q({0} kilowattóra),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowattóra),
						'one' => q({0} kilowattóra),
						'other' => q({0} kilowattóra),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(amerikai therm),
						'one' => q({0} amerikai therm),
						'other' => q({0} amerikai therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(amerikai therm),
						'one' => q({0} amerikai therm),
						'other' => q({0} amerikai therm),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(fonterő),
						'one' => q({0} fonterő),
						'other' => q({0} fonterő),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(fonterő),
						'one' => q({0} fonterő),
						'other' => q({0} fonterő),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pont per centiméter),
						'one' => q({0} pont per centiméter),
						'other' => q({0} pont per centiméter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pont per centiméter),
						'one' => q({0} pont per centiméter),
						'other' => q({0} pont per centiméter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pont per hüvelyk),
						'one' => q({0} pont per hüvelyk),
						'other' => q({0} pont per hüvelyk),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pont per hüvelyk),
						'one' => q({0} pont per hüvelyk),
						'other' => q({0} pont per hüvelyk),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(nyomdai em),
						'one' => q({0} kvirt),
						'other' => q({0} kvirt),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(nyomdai em),
						'one' => q({0} kvirt),
						'other' => q({0} kvirt),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(millió képpont),
						'one' => q({0} millió képpont),
						'other' => q({0} millió képpont),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(millió képpont),
						'one' => q({0} millió képpont),
						'other' => q({0} millió képpont),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} képpont),
						'other' => q({0} képpont),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} képpont),
						'other' => q({0} képpont),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(képpont per centiméter),
						'one' => q({0} képpont per centiméter),
						'other' => q({0} képpont per centiméter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(képpont per centiméter),
						'one' => q({0} képpont per centiméter),
						'other' => q({0} képpont per centiméter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(képpont per hüvelyk),
						'one' => q({0} képpont per hüvelyk),
						'other' => q({0} képpont per hüvelyk),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(képpont per hüvelyk),
						'one' => q({0} képpont per hüvelyk),
						'other' => q({0} képpont per hüvelyk),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(csillagászati egység),
						'one' => q({0} csillagászati egység),
						'other' => q({0} csillagászati egység),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(csillagászati egység),
						'one' => q({0} csillagászati egység),
						'other' => q({0} csillagászati egység),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centiméter),
						'one' => q({0} centiméter),
						'other' => q({0} centiméter),
						'per' => q({0}/centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centiméter),
						'one' => q({0} centiméter),
						'other' => q({0} centiméter),
						'per' => q({0}/centimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(deciméter),
						'one' => q({0} deciméter),
						'other' => q({0} deciméter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(deciméter),
						'one' => q({0} deciméter),
						'other' => q({0} deciméter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(földsugár),
						'one' => q({0} földsugár),
						'other' => q({0} földsugár),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(földsugár),
						'one' => q({0} földsugár),
						'other' => q({0} földsugár),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0}/hüvelyk),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0}/hüvelyk),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilométer),
						'one' => q({0} kilométer),
						'other' => q({0} kilométer),
						'per' => q({0}/kilométer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilométer),
						'one' => q({0} kilométer),
						'other' => q({0} kilométer),
						'per' => q({0}/kilométer),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(méter),
						'one' => q({0} méter),
						'other' => q({0} méter),
						'per' => q({0}/méter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(méter),
						'one' => q({0} méter),
						'other' => q({0} méter),
						'per' => q({0}/méter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrométer),
						'one' => q({0} mikrométer),
						'other' => q({0} mikrométer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrométer),
						'one' => q({0} mikrométer),
						'other' => q({0} mikrométer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mérföld),
						'one' => q({0} mérföld),
						'other' => q({0} mérföld),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mérföld),
						'one' => q({0} mérföld),
						'other' => q({0} mérföld),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(svéd mérföld),
						'one' => q({0} svéd mérföld),
						'other' => q({0} svéd mérföld),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(svéd mérföld),
						'one' => q({0} svéd mérföld),
						'other' => q({0} svéd mérföld),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milliméter),
						'one' => q({0} milliméter),
						'other' => q({0} milliméter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milliméter),
						'one' => q({0} milliméter),
						'other' => q({0} milliméter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanométer),
						'one' => q({0} nanométer),
						'other' => q({0} nanométer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanométer),
						'one' => q({0} nanométer),
						'other' => q({0} nanométer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(tengeri mérföld),
						'one' => q({0} tengeri mérföld),
						'other' => q({0} tengeri mérföld),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(tengeri mérföld),
						'one' => q({0} tengeri mérföld),
						'other' => q({0} tengeri mérföld),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parszek),
						'one' => q({0} parszek),
						'other' => q({0} parszek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parszek),
						'one' => q({0} parszek),
						'other' => q({0} parszek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikométer),
						'one' => q({0} pikométer),
						'other' => q({0} pikométer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikométer),
						'one' => q({0} pikométer),
						'other' => q({0} pikométer),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} pont),
						'other' => q({0} pont),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} pont),
						'other' => q({0} pont),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} Nap-sugár),
						'other' => q({0} Nap-sugár),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} Nap-sugár),
						'other' => q({0} Nap-sugár),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Nap-fényerő),
						'one' => q({0} Nap-fényerő),
						'other' => q({0} Nap-fényerő),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Nap-fényerő),
						'one' => q({0} Nap-fényerő),
						'other' => q({0} Nap-fényerő),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karát),
						'one' => q({0} karát),
						'other' => q({0} karát),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Föld-tömeg),
						'one' => q({0} Föld-tömeg),
						'other' => q({0} Föld-tömeg),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Föld-tömeg),
						'one' => q({0} Föld-tömeg),
						'other' => q({0} Föld-tömeg),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramm),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(uncia),
						'one' => q({0} uncia),
						'other' => q({0} uncia),
						'per' => q({0}/uncia),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(uncia),
						'one' => q({0} uncia),
						'other' => q({0} uncia),
						'per' => q({0}/uncia),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy uncia),
						'one' => q({0} troy uncia),
						'other' => q({0} troy uncia),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy uncia),
						'one' => q({0} troy uncia),
						'other' => q({0} troy uncia),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(font),
						'one' => q({0} font),
						'other' => q({0} font),
						'per' => q({0}/font),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(font),
						'one' => q({0} font),
						'other' => q({0} font),
						'per' => q({0}/font),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Nap-tömeg),
						'one' => q({0} Nap-tömeg),
						'other' => q({0} Nap-tömeg),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Nap-tömeg),
						'one' => q({0} Nap-tömeg),
						'other' => q({0} Nap-tömeg),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(amerikai tonna),
						'one' => q({0} amerikai tonna),
						'other' => q({0} amerikai tonna),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(amerikai tonna),
						'one' => q({0} amerikai tonna),
						'other' => q({0} amerikai tonna),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrikus tonna),
						'one' => q({0} metrikus tonna),
						'other' => q({0} metrikus tonna),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrikus tonna),
						'one' => q({0} metrikus tonna),
						'other' => q({0} metrikus tonna),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(lóerő),
						'one' => q({0} lóerő),
						'other' => q({0} lóerő),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(lóerő),
						'one' => q({0} lóerő),
						'other' => q({0} lóerő),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(négyzet{0}),
						'other' => q(négyzet{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(négyzet{0}),
						'other' => q(négyzet{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(köb{0}),
						'other' => q(köb{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(köb{0}),
						'other' => q(köb{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmoszféra),
						'one' => q({0} atmoszféra),
						'other' => q({0} atmoszféra),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmoszféra),
						'one' => q({0} atmoszféra),
						'other' => q({0} atmoszféra),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(higanyhüvelyk),
						'one' => q({0} higanyhüvelyk),
						'other' => q({0} higanyhüvelyk),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(higanyhüvelyk),
						'one' => q({0} higanyhüvelyk),
						'other' => q({0} higanyhüvelyk),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(higanymilliméter),
						'one' => q({0} higanymilliméter),
						'other' => q({0} higanymilliméter),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(higanymilliméter),
						'one' => q({0} higanymilliméter),
						'other' => q({0} higanymilliméter),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(font per négyzethüvelyk),
						'one' => q({0} font per négyzethüvelyk),
						'other' => q({0} font per négyzethüvelyk),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(font per négyzethüvelyk),
						'one' => q({0} font per négyzethüvelyk),
						'other' => q({0} font per négyzethüvelyk),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilométer per óra),
						'one' => q({0} kilométer per óra),
						'other' => q({0} kilométer per óra),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilométer per óra),
						'one' => q({0} kilométer per óra),
						'other' => q({0} kilométer per óra),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(csomó),
						'one' => q({0} csomó),
						'other' => q({0} csomó),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(csomó),
						'one' => q({0} csomó),
						'other' => q({0} csomó),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(méter per másodperc),
						'one' => q({0} méter per másodperc),
						'other' => q({0} méter per másodperc),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(méter per másodperc),
						'one' => q({0} méter per másodperc),
						'other' => q({0} méter per másodperc),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mérföld per óra),
						'one' => q({0} mérföld per óra),
						'other' => q({0} mérföld per óra),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mérföld per óra),
						'one' => q({0} mérföld per óra),
						'other' => q({0} mérföld per óra),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Celsius-fok),
						'one' => q({0} Celsius-fok),
						'other' => q({0} Celsius-fok),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Celsius-fok),
						'one' => q({0} Celsius-fok),
						'other' => q({0} Celsius-fok),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Fahrenheit-fok),
						'one' => q({0} Fahrenheit-fok),
						'other' => q({0} Fahrenheit-fok),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Fahrenheit-fok),
						'one' => q({0} Fahrenheit-fok),
						'other' => q({0} Fahrenheit-fok),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtonméter),
						'one' => q({0} newtonméter),
						'other' => q({0} newtonméter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtonméter),
						'one' => q({0} newtonméter),
						'other' => q({0} newtonméter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(fontláb),
						'one' => q({0} fontláb),
						'other' => q({0} fontláb),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(fontláb),
						'one' => q({0} fontláb),
						'other' => q({0} fontláb),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(hold-láb),
						'one' => q({0} hold-láb),
						'other' => q({0} hold-láb),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(hold-láb),
						'one' => q({0} hold-láb),
						'other' => q({0} hold-láb),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(köbcentiméter),
						'one' => q({0} köbcentiméter),
						'other' => q({0} köbcentiméter),
						'per' => q({0}/köbcentiméter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(köbcentiméter),
						'one' => q({0} köbcentiméter),
						'other' => q({0} köbcentiméter),
						'per' => q({0}/köbcentiméter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(köbláb),
						'one' => q({0} köbláb),
						'other' => q({0} köbláb),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(köbláb),
						'one' => q({0} köbláb),
						'other' => q({0} köbláb),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(köbhüvelyk),
						'one' => q({0} köbhüvelyk),
						'other' => q({0} köbhüvelyk),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(köbhüvelyk),
						'one' => q({0} köbhüvelyk),
						'other' => q({0} köbhüvelyk),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(köbkilométer),
						'one' => q({0} köbkilométer),
						'other' => q({0} köbkilométer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(köbkilométer),
						'one' => q({0} köbkilométer),
						'other' => q({0} köbkilométer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(köbméter),
						'one' => q({0} köbméter),
						'other' => q({0} köbméter),
						'per' => q({0}/köbméter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(köbméter),
						'one' => q({0} köbméter),
						'other' => q({0} köbméter),
						'per' => q({0}/köbméter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(köbmérföld),
						'one' => q({0} köbmérföld),
						'other' => q({0} köbmérföld),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(köbmérföld),
						'one' => q({0} köbmérföld),
						'other' => q({0} köbmérföld),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(köbyard),
						'one' => q({0} köbyard),
						'other' => q({0} köbyard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(köbyard),
						'one' => q({0} köbyard),
						'other' => q({0} köbyard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(csésze),
						'one' => q({0} csésze),
						'other' => q({0} csésze),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(csésze),
						'one' => q({0} csésze),
						'other' => q({0} csésze),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(bögre),
						'one' => q({0} bögre),
						'other' => q({0} bögre),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(bögre),
						'one' => q({0} bögre),
						'other' => q({0} bögre),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(folyadékuncia),
						'one' => q({0} folyadékuncia),
						'other' => q({0} folyadékuncia),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(folyadékuncia),
						'one' => q({0} folyadékuncia),
						'other' => q({0} folyadékuncia),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(bir. folyadék uncia),
						'one' => q({0} bir. folyadék uncia),
						'other' => q({0} bir. folyadék uncia),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(bir. folyadék uncia),
						'one' => q({0} bir. folyadék uncia),
						'other' => q({0} bir. folyadék uncia),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(birodalmi gallon),
						'one' => q({0} birodalmi gallon),
						'other' => q({0} birodalmi gallon),
						'per' => q({0}/birodalmi gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(birodalmi gallon),
						'one' => q({0} birodalmi gallon),
						'other' => q({0} birodalmi gallon),
						'per' => q({0}/birodalmi gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0}/liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0}/liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrikus pint),
						'one' => q({0} metrikus pint),
						'other' => q({0} metrikus pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrikus pint),
						'one' => q({0} metrikus pint),
						'other' => q({0} metrikus pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(birodalmi kvart),
						'one' => q({0} birodalmi kvart),
						'other' => q({0} birodalmi kvart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(birodalmi kvart),
						'one' => q({0} birodalmi kvart),
						'other' => q({0} birodalmi kvart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(evőkanál),
						'one' => q({0} evőkanál),
						'other' => q({0} evőkanál),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(evőkanál),
						'one' => q({0} evőkanál),
						'other' => q({0} evőkanál),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kávéskanál),
						'one' => q({0} kávéskanál),
						'other' => q({0} kávéskanál),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kávéskanál),
						'one' => q({0} kávéskanál),
						'other' => q({0} kávéskanál),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} h.),
						'other' => q({0} h.),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} h.),
						'other' => q({0} h.),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0} uncia),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} uncia),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} font),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} font),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Hgin),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Hgin),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(csi),
						'one' => q({0} csi),
						'other' => q({0} csi),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(csi),
						'one' => q({0} csi),
						'other' => q({0} csi),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(irány),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(irány),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g gyorsulás),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g gyorsulás),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ívperc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ívperc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ívmásodperc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ívmásodperc),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(fok),
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(fok),
						'one' => q({0} fok),
						'other' => q({0} fok),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ford.),
						'one' => q({0} ford.),
						'other' => q({0} ford.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ford.),
						'one' => q({0} ford.),
						'other' => q({0} ford.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(kh),
						'one' => q({0} kh),
						'other' => q({0} kh),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(kh),
						'one' => q({0} kh),
						'other' => q({0} kh),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimól/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimól/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(százalék),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(százalék),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(ezrelék),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(ezrelék),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(részecske/millió),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(részecske/millió),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mérföld/bir. gallon),
						'one' => q({0} mpg bir.),
						'other' => q({0} mpg bir.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mérföld/bir. gallon),
						'one' => q({0} mpg bir.),
						'other' => q({0} mpg bir.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} K),
						'north' => q({0} É),
						'south' => q({0} D),
						'west' => q({0} Ny),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} K),
						'north' => q({0} É),
						'south' => q({0} D),
						'west' => q({0} Ny),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bájt),
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bájt),
						'one' => q({0} bájt),
						'other' => q({0} bájt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sz.),
						'one' => q({0} sz.),
						'other' => q({0} sz.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sz.),
						'one' => q({0} sz.),
						'other' => q({0} sz.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(nap),
						'one' => q({0} nap),
						'other' => q({0} nap),
						'per' => q({0}/nap),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(nap),
						'one' => q({0} nap),
						'other' => q({0} nap),
						'per' => q({0}/nap),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ó),
						'one' => q({0} ó),
						'other' => q({0} ó),
						'per' => q({0}/ó),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ó),
						'one' => q({0} ó),
						'other' => q({0} ó),
						'per' => q({0}/ó),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
						'per' => q({0}/p),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
						'per' => q({0}/p),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(hónap),
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hó),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(hónap),
						'one' => q({0} hónap),
						'other' => q({0} hónap),
						'per' => q({0}/hó),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(n.év),
						'one' => q({0} n.év),
						'other' => q({0} n.év),
						'per' => q({0}/n.év),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(n.év),
						'one' => q({0} n.év),
						'other' => q({0} n.év),
						'per' => q({0}/n.év),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(mp),
						'one' => q({0} mp),
						'other' => q({0} mp),
						'per' => q({0}/mp),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(mp),
						'one' => q({0} mp),
						'other' => q({0} mp),
						'per' => q({0}/mp),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hét),
						'one' => q({0} hét),
						'other' => q({0} hét),
						'per' => q({0}/hét),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hét),
						'one' => q({0} hét),
						'other' => q({0} hét),
						'per' => q({0}/hét),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(év),
						'one' => q({0} év),
						'other' => q({0} év),
						'per' => q({0}/év),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(év),
						'one' => q({0} év),
						'other' => q({0} év),
						'per' => q({0}/év),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(USA therm),
						'one' => q({0} USA therm),
						'other' => q({0} USA therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(USA therm),
						'one' => q({0} USA therm),
						'other' => q({0} USA therm),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} képpont),
						'other' => q({0} képpont),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} képpont),
						'other' => q({0} képpont),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(képpont),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(képpont),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(CsE),
						'one' => q({0} CsE),
						'other' => q({0} CsE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(CsE),
						'one' => q({0} CsE),
						'other' => q({0} CsE),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(öl),
						'one' => q({0} öl),
						'other' => q({0} öl),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(öl),
						'one' => q({0} öl),
						'other' => q({0} öl),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(láb),
						'one' => q({0} láb),
						'other' => q({0} láb),
						'per' => q({0}/láb),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(láb),
						'one' => q({0} láb),
						'other' => q({0} láb),
						'per' => q({0}/láb),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(hüvelyk),
						'one' => q({0} hüvelyk),
						'other' => q({0} hüvelyk),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(hüvelyk),
						'one' => q({0} hüvelyk),
						'other' => q({0} hüvelyk),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(fényév),
						'one' => q({0} fényév),
						'other' => q({0} fényév),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(fényév),
						'one' => q({0} fényév),
						'other' => q({0} fényév),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mf),
						'one' => q({0} mf),
						'other' => q({0} mf),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mf),
						'one' => q({0} mf),
						'other' => q({0} mf),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pont),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pont),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Nap-sugár),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Nap-sugár),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(LE),
						'one' => q({0} LE),
						'other' => q({0} LE),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(LE),
						'one' => q({0} LE),
						'other' => q({0} LE),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(Hgmm),
						'one' => q({0} Hgmm),
						'other' => q({0} Hgmm),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(Hgmm),
						'one' => q({0} Hgmm),
						'other' => q({0} Hgmm),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(hordó),
						'one' => q({0} hordó),
						'other' => q({0} hordó),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(hordó),
						'one' => q({0} hordó),
						'other' => q({0} hordó),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(véka),
						'one' => q({0} véka),
						'other' => q({0} véka),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(véka),
						'one' => q({0} véka),
						'other' => q({0} véka),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cs.),
						'one' => q({0} cs.),
						'other' => q({0} cs.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cs.),
						'one' => q({0} cs.),
						'other' => q({0} cs.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(bg),
						'one' => q({0} bg),
						'other' => q({0} bg),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(bg),
						'one' => q({0} bg),
						'other' => q({0} bg),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(desszertkanál),
						'one' => q({0} desszertkanál),
						'other' => q({0} desszertkanál),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(desszertkanál),
						'one' => q({0} desszertkanál),
						'other' => q({0} desszertkanál),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(bir. desszertkanál),
						'one' => q({0} bir. desszertkanál),
						'other' => q({0} bir. desszertkanál),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(bir. desszertkanál),
						'one' => q({0} bir. desszertkanál),
						'other' => q({0} bir. desszertkanál),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fluid dram),
						'one' => q({0} fl dram),
						'other' => q({0} fl dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fluid dram),
						'one' => q({0} fl dram),
						'other' => q({0} fl dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(csepp),
						'one' => q({0} csepp),
						'other' => q({0} csepp),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(csepp),
						'one' => q({0} csepp),
						'other' => q({0} csepp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(bir. f. uncia),
						'one' => q({0} bir. f. uncia),
						'other' => q({0} bir. f. uncia),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(bir. f. uncia),
						'one' => q({0} bir. f. uncia),
						'other' => q({0} bir. f. uncia),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(bir. gal),
						'one' => q({0} bir. gal),
						'other' => q({0} bir. gal),
						'per' => q({0}/bir. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(bir. gal),
						'one' => q({0} bir. gal),
						'other' => q({0} bir. gal),
						'per' => q({0}/bir. gal),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(adagolópohár),
						'one' => q({0} adagolópohár),
						'other' => q({0} adagolópohár),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(adagolópohár),
						'one' => q({0} adagolópohár),
						'other' => q({0} adagolópohár),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(csipet),
						'one' => q({0} csipet),
						'other' => q({0} csipet),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(csipet),
						'one' => q({0} csipet),
						'other' => q({0} csipet),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(bir. qt),
						'one' => q({0} bir. qt),
						'other' => q({0} bir. qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(bir. qt),
						'one' => q({0} bir. qt),
						'other' => q({0} bir. qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ek.),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ek.),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kk.),
						'one' => q({0} kk.),
						'other' => q({0} kk.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kk.),
						'one' => q({0} kk.),
						'other' => q({0} kk.),
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
				end => q({0} és {1}),
				2 => q({0} és {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
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
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(EAE-dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgán afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgán afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albán lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albán lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(örmény dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(holland antilláki forint),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolai kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolai kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolai új kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolai kwanza reajustado \(1995–1999\)),
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
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentin peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Osztrák schilling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(ausztrál dollár),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubai florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdzsáni manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdzsáni manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosznia-hercegovinai dínár \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosznia-hercegovinai konvertibilis márka),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosznia-hercegovinai új dínár \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadosi dollár),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladesi taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belga frank \(konvertibilis\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belga frank),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belga frank \(pénzügyi\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bolgár kemény leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bolgár szocialista leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bolgár új leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bolgár leva \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahreini dinár),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundi frank),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudai dollár),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunei dollár),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolíviai boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolíviai peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolíviai mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brazi cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brazi cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brazil cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazil real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brazil cruzado novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazil cruzeiro \(1993–1994\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamai dollár),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutáni ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmai kyat),
				'one' => q(burmai kjap),
				'other' => q(burmai kjap),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanai pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Fehérorosz új rubel \(1994–1999\)),
				'one' => q(fehérorosz új rubel \(1994–1999\)),
				'other' => q(fehérorosz új rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(belarusz rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(fehérorosz rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belize-i dollár),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadai dollár),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongói frank),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(svájci frank),
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
			display_name => {
				'currency' => q(chilei peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kínai jüan \(offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kínai jüan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbiai peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rica-i colon),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(szerb dinár),
				'one' => q(szerb dinár \(2002–2006\)),
				'other' => q(szerb dinár \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Csehszlovák kemény korona),
				'one' => q(csehszlovák kemény korona),
				'other' => q(csehszlovák kemény korona),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubai konvertibilis peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubai peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Zöld-foki escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Ciprusi font),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(cseh korona),
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
			display_name => {
				'currency' => q(dzsibuti frank),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dán korona),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikai peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algériai dínár),
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
				'one' => q(észt korona),
				'other' => q(észt korona),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyiptomi font),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreai nakfa),
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
				'one' => q(spanyol peseta),
				'other' => q(spanyol peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiópiai birr),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euró),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finn markka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidzsi dollár),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falkland-szigeteki font),
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
				'currency' => q(angol font),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Grúz kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(grúz lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghánai cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghánai cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltári font),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiai dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineai frank),
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
				'one' => q(görög drachma),
				'other' => q(görög drachma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalai quetzal),
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
			display_name => {
				'currency' => q(guyanai dollár),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(hongkongi dollár),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(hodurasi lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Horvát dínár),
				'one' => q(horvát dínár),
				'other' => q(horvát dínár),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(horvát kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haiti gourde),
			},
		},
		'HUF' => {
			symbol => 'Ft',
			display_name => {
				'currency' => q(magyar forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonéz rúpia),
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
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indiai rúpia),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iraki dínár),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iráni rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(izlandi korona),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Olasz líra),
				'one' => q(olasz líra),
				'other' => q(olasz líra),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaicai dollár),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordániai dínár),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japán jen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyai shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgizisztáni szom),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodzsai riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(comorei frank),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(észak-koreai won),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(dél-koreai won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvaiti dínár),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmán-szigeteki dollár),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazahsztáni tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoszi kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanoni font),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Srí Lanka-i rúpia),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(libériai dollár),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothoi loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litvániai litas),
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
			display_name => {
				'currency' => q(lett lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lett rubel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(líbiai dínár),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkói dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkói frank),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldáv kupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldován lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaszkári ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaszkári frank),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(macedon dínár),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(macedón dénár \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali frank),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(mianmari kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongóliai tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaói pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritániai ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritániai ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Máltai líra),
				'one' => q(máltai líra),
				'other' => q(máltai líra),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Máltai font),
				'one' => q(máltai font),
				'other' => q(máltai font),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritiusi rúpia),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldív-szigeteki rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawi kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(mexikói peso),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexikói ezüst peso \(1861–1992\)),
				'one' => q(mexikói ezüst peso \(1861–1992\)),
				'other' => q(mexikói ezüst peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexikói Unidad de Inversion \(UDI\)),
				'one' => q(mexikói befektetési egység \(UDI\)),
				'other' => q(mexikói befektetési egység \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajziai ringgit),
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
			display_name => {
				'currency' => q(mozambiki metikális),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namíbiai dollár),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigériai naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaraguai cordoba),
				'one' => q(nicaraguai córdoba \(1988–1911\)),
				'other' => q(nicaraguai córdoba \(1988–1911\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguai córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Holland forint),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norvég korona),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepáli rúpia),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(új-zélandi dollár),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ománi rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamai balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(perui inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(perui sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(perui sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(pápua új-guineai kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(fülöp-szigeteki peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakisztáni rúpia),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(lengyel zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Lengyel zloty \(1950–1995\)),
				'one' => q(lengyel zloty \(PLZ\)),
				'other' => q(lengyel zloty \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugál escudo),
				'one' => q(portugál escudo),
				'other' => q(portugál escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayi guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katari rial),
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
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(román lej),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(szerb dínár),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(orosz rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(orosz rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandai frank),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(szaúdi riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salamon-szigeteki dollár),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelle-szigeteki rúpia),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Szudáni dínár \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(szudáni font),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Szudáni font \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(svéd korona),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(szingapúri dollár),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Szent Ilona-i font),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Szlovén tolar),
				'one' => q(szlovén tolár),
				'other' => q(szlovén tolár),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Szlovák korona),
				'one' => q(szlovák korona),
				'other' => q(szlovák korona),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leone-i leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leone-i leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(szomáli shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(suriname-i dollár),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Suriname-i gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(dél-szudáni font),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé és Príncipe-i dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé és Príncipe-i dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Szovjet rubel),
				'one' => q(szovjet rubel),
				'other' => q(szovjet rubel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadori colón),
				'one' => q(salvadori colón),
				'other' => q(salvadori colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(szíriai font),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(szvázi lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thai baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tádzsikisztáni rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tádzsikisztáni somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(türkmenisztáni manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(türkmenisztáni manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunéziai dínár),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongai paanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timori escudo),
				'one' => q(timori escudo),
				'other' => q(timori escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(török líra \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(török líra),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad és Tobago-i dollár),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(tajvani új dollár),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzániai shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrán hrivnya),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrán karbovanec),
				'one' => q(ukrán karbovanec),
				'other' => q(ukrán karbovanec),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandai shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandai shilling),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(USA-dollár),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(USA dollár \(következő napi\)),
				'one' => q(USA-dollár \(következő napi\)),
				'other' => q(USA-dollár \(következő napi\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(USA dollár \(aznapi\)),
				'one' => q(USA-dollár \(aznapi\)),
				'other' => q(USA-dollár \(aznapi\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayi peso en unidades indexadas),
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
			display_name => {
				'currency' => q(uruguay-i peso),
				'one' => q(uruguayi peso),
				'other' => q(uruguayi peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(üzbegisztáni szum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelai bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelai bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelai bolivar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnámi dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnámi dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatui vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(nyugat-szamoai tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA frank BEAC),
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
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Európai monetáris egység),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Európai kontó egység \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Európai kontó egység \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(kelet-karibi dollár),
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
			display_name => {
				'currency' => q(CFA frank BCEAO),
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
			display_name => {
				'currency' => q(csendes-óceáni valutaközösségi frank),
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
			display_name => {
				'currency' => q(jemeni rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoszláv kemény dínár),
				'one' => q(jugoszláv kemény dinár \(1966–1990\)),
				'other' => q(jugoszláv kemény dinár \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoszláv új dínár),
				'one' => q(jugoszláv új dinár \(1994–2002\)),
				'other' => q(jugoszláv új dinár \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoszláv konvertibilis dínár),
				'one' => q(jugoszláv konvertibilis dinár \(1990–1992\)),
				'other' => q(jugoszláv konvertibilis dinár \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(jugoszláv reformált dinár \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Dél-afrikai rand \(pénzügyi\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(dél-afrikai rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiai kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambiai kwacha),
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
				},
				'stand-alone' => {
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
				},
			},
			'hebrew' => {
				'format' => {
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
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
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
					narrow => {
						mon => 'H',
						tue => 'K',
						wed => 'Sz',
						thu => 'Cs',
						fri => 'P',
						sat => 'Sz',
						sun => 'V'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'night2' if $time >= 400
						&& $time < 600;
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
				'abbreviated' => {
					'afternoon1' => q{du.},
					'am' => q{de.},
					'evening1' => q{este},
					'midnight' => q{éjfél},
					'morning1' => q{reggel},
					'morning2' => q{de.},
					'night1' => q{éjjel},
					'night2' => q{hajnal},
					'noon' => q{dél},
					'pm' => q{du.},
				},
				'wide' => {
					'afternoon1' => q{délután},
					'evening1' => q{este},
					'midnight' => q{éjfél},
					'morning1' => q{reggel},
					'morning2' => q{délelőtt},
					'night1' => q{éjjel},
					'night2' => q{hajnal},
					'noon' => q{dél},
				},
			},
			'stand-alone' => {
				'wide' => {
					'afternoon1' => q{délután},
					'evening1' => q{este},
					'morning1' => q{reggel},
					'morning2' => q{délelőtt},
					'night1' => q{éjjel},
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
		},
		'chinese' => {
		},
		'coptic' => {
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
		},
		'islamic' => {
			abbreviated => {
				'0' => 'MF'
			},
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'R.O.C. előtt'
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
		'generic' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E h:mm},
			EBhms => q{E h:mm:ss},
			Ed => q{d., E},
			Ehm => q{E h:mm},
			Ehms => q{E h:mm:ss},
			Gy => q{G y.},
			GyMMM => q{G y. MMM},
			GyMMMEd => q{G y. MMM d., E},
			GyMMMd => q{G y. MMM d.},
			GyMd => q{GGGGG y/MM/dd},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{M. d., E},
			MMMEd => q{MMM d., E},
			MMMMd => q{MMMM d.},
			MMMd => q{MMM d.},
			Md => q{M. d.},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
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
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d., E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y.},
			GyMMM => q{G y. MMM},
			GyMMMEd => q{G y. MMM d., E},
			GyMMMd => q{G y. MMM d.},
			GyMd => q{GGGGG y. MM. dd.},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{M. d., E},
			MMMEd => q{MMM d., E},
			MMMMW => q{MMMM W. 'hete'},
			MMMMd => q{MMMM d.},
			MMMd => q{MMM d.},
			Md => q{M. d.},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			mmss => q{mm:ss},
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
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bhm => {
				m => q{h:mm – h:mm B},
			},
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
				M => q{MM. dd., E – MM. dd., E},
				d => q{MM. dd., E – MM. dd., E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d., E – MMM d., E},
				d => q{MMM d., E – d., E},
			},
			MMMd => {
				M => q{MMM d. – MMM d.},
				d => q{MMM d–d.},
			},
			Md => {
				M => q{MM. dd. – MM. dd.},
				d => q{MM. dd–dd.},
			},
			d => {
				d => q{d–d.},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			y => {
				y => q{G y–y.},
			},
			yM => {
				M => q{G y. MM–MM.},
				y => q{G y. MM. – y. MM.},
			},
			yMEd => {
				M => q{G y. MM. dd., E – MM. dd., E},
				d => q{G y. MM. dd., E – dd., E},
				y => q{G y. MM. dd., E – y. MM. dd., E},
			},
			yMMM => {
				M => q{G y. MMM–MMM},
				y => q{G y. MMM – y. MMM},
			},
			yMMMEd => {
				M => q{G y. MMM d., E – MMM d., E},
				d => q{G y. MMM d., E – MMM d., E},
				y => q{G y. MMM d., E – y. MMM d., E},
			},
			yMMMM => {
				M => q{G y. MMMM–MMMM},
				y => q{G y. MMMM – y. MMMM},
			},
			yMMMd => {
				M => q{G y. MMM d. – MMM d.},
				d => q{G y. MMM d–d.},
				y => q{G y. MMM d. – y. MMM d.},
			},
			yMd => {
				M => q{G y. MM. dd. – MM. dd.},
				d => q{G y. MM. dd–dd.},
				y => q{G y. MM. dd. – y. MM. dd.},
			},
		},
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
				M => q{M. d., E – M. d., E},
				d => q{M. dd., E – M. d., E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d., E – MMM d., E},
				d => q{MMM d., E – d., E},
			},
			MMMd => {
				M => q{MMM d. – MMM d.},
				d => q{MMM d–d.},
			},
			Md => {
				M => q{M. d. – M. d.},
				d => q{M. d–d.},
			},
			d => {
				d => q{d–d.},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			yM => {
				M => q{y. MM–MM.},
				y => q{y. MM. – y. MM.},
			},
			yMEd => {
				M => q{y. MM. dd., E – MM. dd., E},
				d => q{y. MM. dd., E – dd., E},
				y => q{y. MM. dd., E – y. MM. dd., E},
			},
			yMMM => {
				M => q{y. MMM–MMM},
				y => q{y. MMM – y. MMM},
			},
			yMMMEd => {
				M => q{y. MMM d., E – MMM d., E},
				d => q{y. MMM d., E – d., E},
				y => q{y. MMM d., E – y. MMM d., E},
			},
			yMMMM => {
				M => q{y. MMMM–MMMM},
				y => q{y. MMMM – y. MMMM},
			},
			yMMMd => {
				M => q{y. MMM d. – MMM d.},
				d => q{y. MMM d–d.},
				y => q{y. MMM d. – y. MMM d.},
			},
			yMd => {
				M => q{y. MM. dd. – MM. dd.},
				d => q{y. MM. dd–dd.},
				y => q{y. MM. dd. – y. MM. dd.},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'solarTerms' => {
				'format' => {
					'wide' => {
						1 => q(esővíz),
					},
				},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} idő),
		regionFormat => q({0} nyári idő),
		regionFormat => q({0} zónaidő),
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
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addisz-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algír#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairó#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es-Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dzsibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Ajún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartúm#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabó#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunisz#,
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
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmán-szigetek#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexikóváros#,
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
		'America/Rio_Branco' => {
			exemplarCity => q#Río Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
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
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrút#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biskek#,
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
		'Asia/Damascus' => {
			exemplarCity => q#Damaszkusz#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusanbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gáza#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutszk#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzsálem#,
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
		'Asia/Muscat' => {
			exemplarCity => q#Maszkat#,
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
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenjan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kosztanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
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
			exemplarCity => q#Timpu#,
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
			exemplarCity => q#Ürümcsi#,
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
		'Atlantic/Canary' => {
			exemplarCity => q#Kanári-szigetek#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Zöld-foki szigetek#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feröer#,
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
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
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
		'Casey' => {
			long => {
				'standard' => q#casey-i idő#,
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
				'standard' => q#karácsony-szigeti idő#,
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
				'standard' => q#koordinált világidő#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ismeretlen város#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amszterdam#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Pozsony#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüsszel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Koppenhága#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#ír nyári idő#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltár#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man-sziget#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Isztanbul#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinyingrád#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisszabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#brit nyári idő#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Málta#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minszk#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moszkva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Párizs#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prága#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Róma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Szamara#,
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
			exemplarCity => q#Szkopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Szófia#,
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
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Bécs#,
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
			exemplarCity => q#Zaporizzsja#,
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
		'Indian/Christmas' => {
			exemplarCity => q#Karácsony-sziget#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kókusz-sziget#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoró#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldív-szigetek#,
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
				'daylight' => q#norfolk-szigeteki nyári idő#,
				'generic' => q#norfolk-szigeteki idő#,
				'standard' => q#norfolk-szigeteki téli idő#,
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
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham-szigetek#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Húsvét-szigetek#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidzsi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos-szigetek#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier-szigetek#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
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
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn-szigetek#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape-szigetek#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Truk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake-sziget#,
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
		'Yukon' => {
			long => {
				'standard' => q#yukoni idő#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
