=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fo - Package for language Faroese

=cut

package Locale::CLDR::Locales::Fo;
# This file auto generated from Data\common\main\fo.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ein),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tvær),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tríggjar),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fýre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjúgo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tríati[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fýrati[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjeyti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttati[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[­og­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusin[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← millióner[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliard[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarder[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billióner[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiard[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarder[ og →→]),
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
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ein),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tveir),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tríggir),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fýre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fimm),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seks),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjey),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(átta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(níggju),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tíggju),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellivu),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tólv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trettan),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjúrtan),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(fímtan),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sekstan),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(seytan),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(átjan),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nítjan),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjúgo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tríati[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fýrati[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjeyti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttati[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[­og­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusin[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← millióner[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliard[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarder[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billióner[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiard[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarder[ og →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eitt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tvey),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trý),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fýre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjúgo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tríati[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fýrati[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjeyti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttati[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[­og­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusin[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← millióner[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliard[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarder[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billióner[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiard[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarder[ og →→]),
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
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
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
					rule => q(←←­hundrað[­og­→→]),
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
 				'ab' => 'abkhasiskt',
 				'ace' => 'achinese',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'ale' => 'aleut',
 				'alt' => 'suður altai',
 				'am' => 'amhariskt',
 				'an' => 'aragoniskt',
 				'anp' => 'angika',
 				'ar' => 'arabiskt',
 				'ar_001' => 'nútíðar vanligt arabiskt',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'as' => 'assamesiskt',
 				'asa' => 'asu',
 				'ast' => 'asturianskt',
 				'av' => 'avariskt',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'aserbajdsjanskt',
 				'az@alt=short' => 'azeri',
 				'ba' => 'bashkir',
 				'ban' => 'balinesiskt',
 				'bas' => 'basaa',
 				'be' => 'hvitarussiskt',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgarskt',
 				'bgn' => 'vestur balochi',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bangla',
 				'bo' => 'tibetskt',
 				'br' => 'bretonskt',
 				'brx' => 'bodo',
 				'bs' => 'bosniskt',
 				'bss' => 'bakossi',
 				'bug' => 'buginesiskt',
 				'byn' => 'blin',
 				'ca' => 'katalani',
 				'ccp' => 'khakma',
 				'ce' => 'tjetjenskt',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'miðkurdiskt',
 				'ckb@alt=menu' => 'kurdiskt, mið',
 				'ckb@alt=variant' => 'kurdiskt, sorani',
 				'co' => 'korsikanskt',
 				'crs' => 'seselwa creole franskt',
 				'cs' => 'kekkiskt',
 				'cu' => 'kirkju sláviskt',
 				'cv' => 'chuvash',
 				'cy' => 'walisiskt',
 				'da' => 'danskt',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'týskt',
 				'de_CH' => 'høgt týskt (Sveis)',
 				'dgr' => 'dogrib',
 				'dje' => 'sarma',
 				'dsb' => 'lágt sorbian',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'grikskt',
 				'en' => 'enskt',
 				'eo' => 'esperanto',
 				'es' => 'spanskt',
 				'et' => 'estiskt',
 				'eu' => 'baskiskt',
 				'ewo' => 'ewondo',
 				'fa' => 'persiskt',
 				'fa_AF' => 'dari',
 				'ff' => 'fulah',
 				'fi' => 'finskt',
 				'fil' => 'filipiniskt',
 				'fj' => 'fijimál',
 				'fo' => 'føroyskt',
 				'fon' => 'fon',
 				'fr' => 'franskt',
 				'fur' => 'friuliskt',
 				'fy' => 'vestur frísiskt',
 				'ga' => 'írskt',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gan' => 'gan kinesiskt',
 				'gd' => 'skotskt gæliskt',
 				'gez' => 'geez',
 				'gil' => 'kiribatiskt',
 				'gl' => 'galisiskt',
 				'gn' => 'guarani',
 				'gor' => 'gorontalo',
 				'gsw' => 'týskt (Sveis)',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwich’in',
 				'ha' => 'hausa',
 				'hak' => 'hakka kinesiskt',
 				'haw' => 'hawaiianskt',
 				'he' => 'hebraiskt',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'hiligaynon',
 				'hmn' => 'hmong',
 				'hr' => 'kroatiskt',
 				'hsb' => 'ovara sorbian',
 				'hsn' => 'xiang kinesiskt',
 				'ht' => 'haitiskt creole',
 				'hu' => 'ungarskt',
 				'hup' => 'hupa',
 				'hy' => 'armenskt',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesiskt',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ilo' => 'iloko',
 				'inh' => 'inguish',
 				'io' => 'ido',
 				'is' => 'íslendskt',
 				'it' => 'italskt',
 				'iu' => 'inuktitut',
 				'ja' => 'japanskt',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javanskt',
 				'ka' => 'georgiskt',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'kabardinskt',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'grønhøvdaoyggjarskt',
 				'kfo' => 'koro',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakh',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreanskt',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'karelskt',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kølnskt',
 				'ku' => 'kurdiskt',
 				'kum' => 'kumyk',
 				'kv' => 'komi',
 				'kw' => 'corniskt',
 				'ky' => 'kyrgyz',
 				'la' => 'latín',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lb' => 'luksemborgskt',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgiskt',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoskt',
 				'loz' => 'lozi',
 				'lrc' => 'norður luri',
 				'lt' => 'litaviskt',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'lettiskt',
 				'mad' => 'maduresiskt',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malagassiskt',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'metaʼ',
 				'mh' => 'marshallesiskt',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedónskt',
 				'ml' => 'malayalam',
 				'mn' => 'mongolskt',
 				'mni' => 'manupuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malaiiskt',
 				'mt' => 'maltiskt',
 				'mua' => 'mundang',
 				'mul' => 'ymisk mál',
 				'mus' => 'creek',
 				'mwl' => 'mirandesiskt',
 				'my' => 'burmesiskt',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nan' => 'min nan kinesiskt',
 				'nap' => 'napolitanskt',
 				'naq' => 'nama',
 				'nb' => 'norskt bókmál',
 				'nd' => 'norður ndebele',
 				'nds' => 'lágt týskt',
 				'nds_NL' => 'lágt saksiskt',
 				'ne' => 'nepalskt',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niuean',
 				'nl' => 'hálendskt',
 				'nl_BE' => 'flamskt',
 				'nmg' => 'kwasio',
 				'nn' => 'nýnorskt',
 				'nnh' => 'ngiemboon',
 				'no' => 'norskt',
 				'nog' => 'nogai',
 				'nqo' => 'nʼko',
 				'nr' => 'suður ndebele',
 				'nso' => 'norður sotho',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'occitanskt',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossetiskt',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauan',
 				'pcm' => 'nigeriskt pidgin',
 				'pl' => 'pólskt',
 				'prg' => 'prusslanskt',
 				'ps' => 'pashto',
 				'pt' => 'portugiskiskt',
 				'pt_BR' => 'portugiskiskt (Brasilia)',
 				'pt_PT' => 'portugiskiskt (Evropa)',
 				'qu' => 'quechua',
 				'quc' => 'kʼicheʼ',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongiskt',
 				'rm' => 'retoromanskt',
 				'rn' => 'rundi',
 				'ro' => 'rumenskt',
 				'ro_MD' => 'moldaviskt',
 				'rof' => 'rombo',
 				'ru' => 'russiskt',
 				'rup' => 'aromenskt',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardiskt',
 				'scn' => 'sisilanskt',
 				'sco' => 'skotskt',
 				'sd' => 'sindhi',
 				'sdh' => 'suður kurdiskt',
 				'se' => 'norður sámiskt',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sh' => 'serbokroatiskt',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'si' => 'singalesiskt',
 				'sk' => 'slovakiskt',
 				'sl' => 'slovenskt',
 				'sm' => 'sámoiskt',
 				'sma' => 'suður sámiskt',
 				'smj' => 'lule sámiskt',
 				'smn' => 'inari sami',
 				'sms' => 'skolt sámiskt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somaliskt',
 				'sq' => 'albanskt',
 				'sr' => 'serbiskt',
 				'srn' => 'sranan tongo',
 				'ss' => 'swatiskt',
 				'ssy' => 'saho',
 				'st' => 'sesotho',
 				'su' => 'sundanesiskt',
 				'suk' => 'sukuma',
 				'sv' => 'svenskt',
 				'sw' => 'swahili',
 				'sw_CD' => 'kongo svahili',
 				'swb' => 'komoriskt',
 				'syr' => 'syriac',
 				'ta' => 'tamilskt',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tajik',
 				'th' => 'tailendskt',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tk' => 'turkmenskt',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonskt',
 				'tn' => 'tswana',
 				'to' => 'tonganskt',
 				'tpi' => 'tok pisin',
 				'tr' => 'turkiskt',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tatar',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiskt',
 				'tyv' => 'tuvinian',
 				'tzm' => 'miðatlasfjøll tamazight',
 				'udm' => 'udmurt',
 				'ug' => 'uyghur',
 				'uk' => 'ukrainskt',
 				'umb' => 'umbundu',
 				'und' => 'ókent mál',
 				'ur' => 'urdu',
 				'uz' => 'usbekiskt',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vjetnamesiskt',
 				'vo' => 'volapykk',
 				'vun' => 'vunjo',
 				'wa' => 'walloon',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu kinesiskt',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddiskt',
 				'yo' => 'yoruba',
 				'yue' => 'kantonesiskt',
 				'yue@alt=menu' => 'kinesiskt, kantonesiskt',
 				'zgh' => 'vanligt marokanskt tamazight',
 				'zh' => 'kinesiskt',
 				'zh@alt=menu' => 'kinesiskt, mandarin',
 				'zh_Hans' => 'einkult kinesiskt',
 				'zh_Hans@alt=long' => 'mandarin kinesiskt (einkult)',
 				'zh_Hant' => 'vanligt kinesiskt',
 				'zh_Hant@alt=long' => 'mandarin kinesiskt (vanligt)',
 				'zu' => 'sulu',
 				'zun' => 'zuni',
 				'zxx' => 'einki málsligt innihald',
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
			'Arab' => 'arabisk',
 			'Armn' => 'armenskt',
 			'Beng' => 'bangla',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'blindaskrift',
 			'Cyrl' => 'kyrilliskt',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopiskt',
 			'Geor' => 'georgianskt',
 			'Grek' => 'grikskt',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'einkult',
 			'Hans@alt=stand-alone' => 'einkult han',
 			'Hant' => 'vanligt',
 			'Hant@alt=stand-alone' => 'vanligt han',
 			'Hebr' => 'hebraiskt',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japanskir stavir',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japanskt',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreanskt',
 			'Laoo' => 'lao',
 			'Latn' => 'latínskt',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolsk',
 			'Mymr' => 'myanmarskt',
 			'Orya' => 'odia',
 			'Sinh' => 'sinhala',
 			'Taml' => 'tamilskt',
 			'Telu' => 'telugu',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailendskt',
 			'Tibt' => 'tibetskt',
 			'Zinh' => 'arver skrift',
 			'Zmth' => 'støddfrøðilig teknskipan',
 			'Zsye' => 'emoji',
 			'Zsym' => 'tekin',
 			'Zxxx' => 'óskriva',
 			'Zyyy' => 'vanlig',
 			'Zzzz' => 'ókend skrift',

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
			'001' => 'heimur',
 			'002' => 'Afrika',
 			'003' => 'Norðuramerika',
 			'005' => 'Suðuramerika',
 			'009' => 'Osiania',
 			'011' => 'Vesturafrika',
 			'013' => 'Miðamerika',
 			'014' => 'Eysturafrika',
 			'015' => 'Norðurafrika',
 			'017' => 'Miðafrika',
 			'018' => 'sunnari partur av Afrika',
 			'019' => 'Amerika',
 			'021' => 'Amerika norðanfyri Meksiko',
 			'029' => 'Karibia',
 			'030' => 'Eysturasia',
 			'034' => 'Suðurasia',
 			'035' => 'Útsynningsasia',
 			'039' => 'Suðurevropa',
 			'053' => 'Avstralasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesi øki',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Miðasia',
 			'145' => 'Vesturasia',
 			'150' => 'Evropa',
 			'151' => 'Eysturevropa',
 			'154' => 'Norðurevropa',
 			'155' => 'Vesturevropa',
 			'202' => 'Afrika sunnanfyri Sahara',
 			'419' => 'Latínamerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Sameindu Emirríkini',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua & Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikanska Samoa',
 			'AT' => 'Eysturríki',
 			'AU' => 'Avstralia',
 			'AW' => 'Aruba',
 			'AX' => 'Áland',
 			'AZ' => 'Aserbadjan',
 			'BA' => 'Bosnia-Hersegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesj',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Barein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Niðurlonds Karibia',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamaoyggjar',
 			'BT' => 'Butan',
 			'BV' => 'Bouvetoyggj',
 			'BW' => 'Botsvana',
 			'BY' => 'Hvítarussland',
 			'BZ' => 'Belis',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosoyggjar',
 			'CD' => 'Kongo, Dem. Lýðveldið',
 			'CF' => 'Miðafrikalýðveldið',
 			'CG' => 'Kongo',
 			'CH' => 'Sveis',
 			'CI' => 'Fílabeinsstrondin',
 			'CK' => 'Cooksoyggjar',
 			'CL' => 'Kili',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Kolombia',
 			'CP' => 'Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Grønhøvdaoyggjar',
 			'CW' => 'Curaçao',
 			'CX' => 'Jólaoyggjin',
 			'CY' => 'Kýpros',
 			'CZ' => 'Kekkia',
 			'DE' => 'Týskland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibuti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikalýðveldið',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ekvador',
 			'EE' => 'Estland',
 			'EG' => 'Egyptaland',
 			'EH' => 'Vestursahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spania',
 			'ET' => 'Etiopia',
 			'EU' => 'Evropasamveldið',
 			'EZ' => 'Evrasona',
 			'FI' => 'Finnland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsoyggjar',
 			'FK@alt=variant' => 'Falklandsoyggjar (Islas Malvinas)',
 			'FM' => 'Mikronesiasamveldið',
 			'FO' => 'Føroyar',
 			'FR' => 'Frakland',
 			'GA' => 'Gabon',
 			'GB' => 'Stórabretland',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Franska Gujana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grønland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatorguinea',
 			'GR' => 'Grikkaland',
 			'GS' => 'Suðurgeorgia og Suðursandwichoyggjar',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Gujana',
 			'HK' => 'Hong Kong SAR Kina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard og McDonaldoyggjar',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanariuoyggjar',
 			'ID' => 'Indonesia',
 			'IE' => 'Írland',
 			'IL' => 'Ísrael',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Stóra Bretlands Indiahavoyggjar',
 			'IO@alt=chagos' => 'Khagosoyggjar',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Ísland',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenja',
 			'KG' => 'Kirgisia',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoroyggjar',
 			'KN' => 'St. Kitts & Nevis',
 			'KP' => 'Norðurkorea',
 			'KR' => 'Suðurkorea',
 			'KW' => 'Kuvait',
 			'KY' => 'Caymanoyggjar',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lusia',
 			'LI' => 'Liktinstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Litava',
 			'LU' => 'Luksemborg',
 			'LV' => 'Lettland',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalloyggjar',
 			'MK' => 'Norður Makedónia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Makao SAR Kina',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Norðaru Mariuoyggjar',
 			'MQ' => 'Martinique',
 			'MR' => 'Móritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Móritius',
 			'MV' => 'Maldivoyggjar',
 			'MW' => 'Malavi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaisia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Nýkaledónia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolksoyggj',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Niðurlond',
 			'NO' => 'Noreg',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nýsæland',
 			'NZ@alt=variant' => 'Aotearoa Nýsæland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Franska Polynesia',
 			'PG' => 'Papua Nýguinea',
 			'PH' => 'Filipsoyggjar',
 			'PK' => 'Pakistan',
 			'PL' => 'Pólland',
 			'PM' => 'Saint Pierre & Miquelon',
 			'PN' => 'Pitcairnoyggjar',
 			'PR' => 'Puerto Riko',
 			'PS' => 'Palestinskt landøki',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'fjarskoti Osiania',
 			'RE' => 'Réunion',
 			'RO' => 'Rumenia',
 			'RS' => 'Serbia',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudiarabia',
 			'SB' => 'Salomonoyggjar',
 			'SC' => 'Seyskelloyggjar',
 			'SD' => 'Sudan',
 			'SE' => 'Svøríki',
 			'SG' => 'Singapor',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard & Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Suðursudan',
 			'ST' => 'Sao Tome & Prinsipi',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sýria',
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Svasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicosoyggjar',
 			'TD' => 'Kjad',
 			'TF' => 'Fronsku sunnaru landaøki',
 			'TG' => 'Togo',
 			'TH' => 'Tailand',
 			'TJ' => 'Tadsjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Eysturtimor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkaland',
 			'TT' => 'Trinidad & Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taivan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Sambandsríki Amerikas fjarskotnu oyggjar',
 			'UN' => 'Sameindu Tjóðir',
 			'US' => 'Sambandsríki Amerika',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguai',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanbýur',
 			'VC' => 'St. Vinsent & Grenadinoyggjar',
 			'VE' => 'Venesuela',
 			'VG' => 'Stóra Bretlands Jomfrúoyggjar',
 			'VI' => 'Sambandsríki Amerikas Jomfrúoyggjar',
 			'VN' => 'Vjetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis- og Futunaoyggjar',
 			'WS' => 'Samoa',
 			'XA' => 'óekta tónalag',
 			'XB' => 'óektaður BIDI tekstur',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suðurafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabvi',
 			'ZZ' => 'ókent øki',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'MONOTON' => 'monotonísk',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonísk',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalendari',
 			'cf' => 'gjaldoyra format',
 			'collation' => 'raðskipan',
 			'currency' => 'gjaldoyra',
 			'hc' => 'klokkuskipan (12 ímóti 24)',
 			'lb' => 'reglubrot stílur',
 			'ms' => 'mátingareind',
 			'numbers' => 'tøl',

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
 				'buddhist' => q{buddistiskur kalendari},
 				'chinese' => q{kinesiskur kalendari},
 				'dangi' => q{dangi kalendari},
 				'ethiopic' => q{etiopiskur kalendari},
 				'gregorian' => q{gregorianskur kalendari},
 				'hebrew' => q{hebraiskur kalendari},
 				'islamic' => q{islamiskur kalendari},
 				'iso8601' => q{ISO-8601 kalendari},
 				'japanese' => q{japanskur kalendari},
 				'persian' => q{persiskur kalendari},
 				'roc' => q{minguo kalendari},
 			},
 			'cf' => {
 				'account' => q{gjaldoyras roknskaparførsla format},
 				'standard' => q{vanlig gjaldoyra format},
 			},
 			'collation' => {
 				'ducet' => q{forsett Unicode raðskipan},
 				'eor' => q{röðina fyrir fjöltyngi evrópskum skjölum},
 				'search' => q{vanlig leiting},
 				'standard' => q{vanlig raðskipan},
 			},
 			'hc' => {
 				'h11' => q{12 tímar klokkuskipan (0–11)},
 				'h12' => q{12 tímar klokkuskipan (1–12)},
 				'h23' => q{24 tímar klokkuskipan (0–23)},
 				'h24' => q{24 tímar klokkuskipan (1–24)},
 			},
 			'lb' => {
 				'loose' => q{leysur reglubrot stílur},
 				'normal' => q{vanligur reglubrot stílur},
 				'strict' => q{strangur reglubrot stílur},
 			},
 			'ms' => {
 				'metric' => q{metralag},
 				'uksystem' => q{mátingareind (UK)},
 				'ussystem' => q{mátingareind (USA)},
 			},
 			'numbers' => {
 				'arab' => q{arabisk tøl},
 				'arabext' => q{víðkað arabisk tøl},
 				'armn' => q{armensk tøl},
 				'armnlow' => q{armensk tøl (smáir bókstavir)},
 				'beng' => q{bangla tøl},
 				'deva' => q{devanagarik tøl},
 				'ethi' => q{etiopisk tøl},
 				'fullwide' => q{tøl í fullari longd},
 				'geor' => q{gregoriansk tøl},
 				'grek' => q{grikskt tøl},
 				'greklow' => q{grikskt tøl (smáir bókstavir)},
 				'gujr' => q{gujaratik tøl},
 				'guru' => q{gurmukhik tøl},
 				'hanidec' => q{kinesisk desimal tøl},
 				'hans' => q{einkul kinesisk tøl},
 				'hansfin' => q{einkul kinesisk fíggjarlig tøl},
 				'hant' => q{vanlig kinesisk tøl},
 				'hantfin' => q{vanlig kinesisk fíggjarlig tøl},
 				'hebr' => q{hebraisk tøl},
 				'jpan' => q{japanskt tøl},
 				'jpanfin' => q{japanskt fíggjarlig tøl},
 				'khmr' => q{khmer tøl},
 				'knda' => q{kannada tøl},
 				'laoo' => q{lao tøl},
 				'latn' => q{vesturlendsk tøl},
 				'mlym' => q{malayalam tøl},
 				'mymr' => q{myanmarsk tøl},
 				'orya' => q{odia tøl},
 				'roman' => q{rómartøl},
 				'romanlow' => q{rómartøl (smáir bókstavir)},
 				'taml' => q{vanlig tamilsk tøl},
 				'tamldec' => q{tamilsk tøl},
 				'telu' => q{telugu tøl},
 				'thai' => q{tailendsk tøl},
 				'tibt' => q{tibetsk tøl},
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
			'metric' => q{metralagið},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Mál: {0}',
 			'script' => 'Skrift: {0}',
 			'region' => 'Øki: {0}',

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
			auxiliary => qr{[c q w x z]},
			index => ['AÁ', 'B', 'C', 'DÐ', 'E', 'F', 'G', 'H', 'IÍ', 'J', 'K', 'L', 'M', 'N', 'OÓ', 'P', 'Q', 'R', 'S', 'T', 'UÚ', 'V', 'W', 'X', 'YÝ', 'Z', 'Æ', 'Ø'],
			main => qr{[aá b dð e f g h ií j k l m n oó p r s t uú v yý æ ø]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['AÁ', 'B', 'C', 'DÐ', 'E', 'F', 'G', 'H', 'IÍ', 'J', 'K', 'L', 'M', 'N', 'OÓ', 'P', 'Q', 'R', 'S', 'T', 'UÚ', 'V', 'W', 'X', 'YÝ', 'Z', 'Æ', 'Ø'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
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
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
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
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
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
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
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
						'name' => q(G-kreftir),
						'one' => q({0} G-kraft),
						'other' => q({0} G-kreftir),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G-kreftir),
						'one' => q({0} G-kraft),
						'other' => q({0} G-kreftir),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metrar um sekundi²),
						'one' => q({0} metur um sekundi²),
						'other' => q({0} metrar um sekundi²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metrar um sekundi²),
						'one' => q({0} metur um sekundi²),
						'other' => q({0} metrar um sekundi²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bogaminuttir),
						'one' => q({0} bogaminuttur),
						'other' => q({0} bogaminuttir),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bogaminuttir),
						'one' => q({0} bogaminuttur),
						'other' => q({0} bogaminuttir),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogasekundir),
						'one' => q({0} bogasekund),
						'other' => q({0} bogasekundir),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogasekundir),
						'one' => q({0} bogasekund),
						'other' => q({0} bogasekundir),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianir),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianir),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarar),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarar),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetur),
						'other' => q({0} fersentimetrar),
						'per' => q({0} fyri hvønn fersentimetur),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetur),
						'other' => q({0} fersentimetrar),
						'per' => q({0} fyri hvønn fersentimetur),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ferføtur),
						'one' => q({0} ferfót),
						'other' => q({0} ferføtur),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ferføtur),
						'one' => q({0} ferfót),
						'other' => q({0} ferføtur),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(fertummar),
						'one' => q({0} fertummi),
						'other' => q({0} fertummar),
						'per' => q({0} fyri hvønn fertumma),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(fertummar),
						'one' => q({0} fertummi),
						'other' => q({0} fertummar),
						'per' => q({0} fyri hvønn fertumma),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ferkilometrar),
						'one' => q({0} ferkilometur),
						'other' => q({0} ferkilometrar),
						'per' => q({0} fyri hvønn ferkilometur),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ferkilometrar),
						'one' => q({0} ferkilometur),
						'other' => q({0} ferkilometrar),
						'per' => q({0} fyri hvønn ferkilometur),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(fermetrar),
						'one' => q({0} fermetur),
						'other' => q({0} fermetrar),
						'per' => q({0} fyri hvønn fermetur),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(fermetrar),
						'one' => q({0} fermetur),
						'other' => q({0} fermetrar),
						'per' => q({0} fyri hvønn fermetur),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(fermíl),
						'one' => q({0} fermíl),
						'other' => q({0} fermíl),
						'per' => q({0} fyri hvørt fermíl),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(fermíl),
						'one' => q({0} fermíl),
						'other' => q({0} fermíl),
						'per' => q({0} fyri hvørt fermíl),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(feryards),
						'one' => q({0} feryard),
						'other' => q({0} feryards),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(feryards),
						'one' => q({0} feryard),
						'other' => q({0} feryards),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm fyri hvønn desilitur),
						'one' => q({0} milligramm fyri hvønn desilitur),
						'other' => q({0} milligramm fyri hvønn desilitur),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm fyri hvønn desilitur),
						'one' => q({0} milligramm fyri hvønn desilitur),
						'other' => q({0} milligramm fyri hvønn desilitur),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol fyri hvønn litur),
						'one' => q({0} millimol fyri hvønn litur),
						'other' => q({0} millimol fyri hvønn litur),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol fyri hvønn litur),
						'one' => q({0} millimol fyri hvønn litur),
						'other' => q({0} millimol fyri hvønn litur),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} prosent),
						'other' => q({0} prosent),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} prosent),
						'other' => q({0} prosent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} promilla),
						'other' => q({0} promillur),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} promilla),
						'other' => q({0} promillur),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partar fyri hvørja millión),
						'one' => q({0} partur fyri hvørja millión),
						'other' => q({0} partar fyri hvørja millión),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partar fyri hvørja millión),
						'one' => q({0} partur fyri hvørja millión),
						'other' => q({0} partar fyri hvørja millión),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} promyriad),
						'other' => q({0} promyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} promyriad),
						'other' => q({0} promyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litrar fyri hvørjar 100 kilometrar),
						'one' => q({0} litur fyri hvørjar 100 kilometrar),
						'other' => q({0} litrar fyri hvørjar 100 kilometrar),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litrar fyri hvørjar 100 kilometrar),
						'one' => q({0} litur fyri hvørjar 100 kilometrar),
						'other' => q({0} litrar fyri hvørjar 100 kilometrar),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litrar fyri hvønn kilometrar),
						'one' => q({0} litur fyri hvønn kilometrar),
						'other' => q({0} litrar fyri hvønn kilometrar),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litrar fyri hvønn kilometrar),
						'one' => q({0} litur fyri hvønn kilometrar),
						'other' => q({0} litrar fyri hvønn kilometrar),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(míl fyri hvønn gallon),
						'one' => q({0} míl fyri hvønn gallon),
						'other' => q({0} míl fyri hvønn gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(míl fyri hvønn gallon),
						'one' => q({0} míl fyri hvønn gallon),
						'other' => q({0} míl fyri hvønn gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(míl fyri hvønn bretska gallon),
						'one' => q({0} míl fyri hvønn bretska gallon),
						'other' => q({0} míl fyri hvønn bretska gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(míl fyri hvønn bretska gallon),
						'one' => q({0} míl fyri hvønn bretska gallon),
						'other' => q({0} míl fyri hvønn bretska gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} eystur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} eystur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
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
						'name' => q(gigabýt),
						'one' => q({0} gigabýt),
						'other' => q({0} gigabýt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabýt),
						'one' => q({0} gigabýt),
						'other' => q({0} gigabýt),
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
						'name' => q(kilobýt),
						'one' => q({0} kilobýt),
						'other' => q({0} kilobýt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobýt),
						'one' => q({0} kilobýt),
						'other' => q({0} kilobýt),
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
						'name' => q(megabýt),
						'one' => q({0} megabýt),
						'other' => q({0} megabýt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabýt),
						'one' => q({0} megabýt),
						'other' => q({0} megabýt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabýt),
						'one' => q({0} petabýt),
						'other' => q({0} petabýt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabýt),
						'one' => q({0} petabýt),
						'other' => q({0} petabýt),
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
						'name' => q(terabýt),
						'one' => q({0} terabýt),
						'other' => q({0} terabýt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabýt),
						'one' => q({0} terabýt),
						'other' => q({0} terabýt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(øldir),
						'one' => q({0} øld),
						'other' => q({0} øldir),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(øldir),
						'one' => q({0} øld),
						'other' => q({0} øldir),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} um dagin),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} um dagin),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(áratíggju),
						'one' => q({0} áratíggju),
						'other' => q({0} áratíggju),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(áratíggju),
						'one' => q({0} áratíggju),
						'other' => q({0} áratíggju),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} tími),
						'other' => q({0} tímar),
						'per' => q({0} um tíman),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} tími),
						'other' => q({0} tímar),
						'per' => q({0} um tíman),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekundir),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundir),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekundir),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundir),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekundir),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundir),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekundir),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundir),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuttir),
						'one' => q({0} minuttur),
						'other' => q({0} minuttir),
						'per' => q({0} um minuttin),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuttir),
						'one' => q({0} minuttur),
						'other' => q({0} minuttir),
						'per' => q({0} um minuttin),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mánaðir),
						'one' => q({0} mánaður),
						'other' => q({0} mánaðir),
						'per' => q({0} um mánan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mánaðir),
						'one' => q({0} mánaður),
						'other' => q({0} mánaðir),
						'per' => q({0} um mánan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekundir),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundir),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekundir),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundir),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundir),
						'one' => q({0} sekund),
						'other' => q({0} sekundir),
						'per' => q({0} um sekundi),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundir),
						'one' => q({0} sekund),
						'other' => q({0} sekundir),
						'per' => q({0} um sekundi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} um vikuna),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} um vikuna),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} um ári),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} um ári),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} ampera),
						'other' => q({0} amperur),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} ampera),
						'other' => q({0} amperur),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} milliampera),
						'other' => q({0} milliamperur),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} milliampera),
						'other' => q({0} milliamperur),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0} bretsk hitaeind),
						'other' => q({0} bretskar hitaeindir),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0} bretsk hitaeind),
						'other' => q({0} bretskar hitaeindir),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloriur),
						'one' => q({0} kaloria),
						'other' => q({0} kaloriur),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloriur),
						'one' => q({0} kaloria),
						'other' => q({0} kaloriur),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloriur),
						'one' => q({0} kilokaloria),
						'other' => q({0} kilokaloriur),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloriur),
						'one' => q({0} kilokaloria),
						'other' => q({0} kilokaloriur),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatttímar),
						'one' => q({0} kilowatttími),
						'other' => q({0} kilowatttímar),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatttímar),
						'one' => q({0} kilowatttími),
						'other' => q({0} kilowatttímar),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0} hitaeind),
						'other' => q({0} hitaeindir),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} hitaeind),
						'other' => q({0} hitaeindir),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pund av kraft),
						'one' => q({0} pund av kraft),
						'other' => q({0} pund av kraft),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pund av kraft),
						'one' => q({0} pund av kraft),
						'other' => q({0} pund av kraft),
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
						'name' => q(punkt fyri hvønn sentimetur),
						'one' => q({0} punkt fyri hvønn sentimetur),
						'other' => q({0} punkt fyri hvønn sentimetur),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punkt fyri hvønn sentimetur),
						'one' => q({0} punkt fyri hvønn sentimetur),
						'other' => q({0} punkt fyri hvønn sentimetur),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punkt fyri hvønn tumma),
						'one' => q({0} punkt fyri hvønn tumma),
						'other' => q({0} punkt fyri hvønn tumma),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkt fyri hvønn tumma),
						'one' => q({0} punkt fyri hvønn tumma),
						'other' => q({0} punkt fyri hvønn tumma),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(prent em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(prent em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megaskíggjadepil),
						'other' => q({0} megaskíggjadeplar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megaskíggjadepil),
						'other' => q({0} megaskíggjadeplar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} skíggjadeplar),
						'other' => q({0} skíggjadeplar),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} skíggjadeplar),
						'other' => q({0} skíggjadeplar),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(skíggjadeplar fyri hvønn sentimetur),
						'one' => q({0} skíggjadeplar fyri hvønn sentimetur),
						'other' => q({0} skíggjadeplar fyri hvønn sentimetur),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(skíggjadeplar fyri hvønn sentimetur),
						'one' => q({0} skíggjadeplar fyri hvønn sentimetur),
						'other' => q({0} skíggjadeplar fyri hvønn sentimetur),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(skíggjadeplar fyri hvønn tunna),
						'one' => q({0} skíggjadepil fyri hvønn tunna),
						'other' => q({0} skíggjadeplar fyri hvønn tunna),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(skíggjadeplar fyri hvønn tunna),
						'one' => q({0} skíggjadepil fyri hvønn tunna),
						'other' => q({0} skíggjadeplar fyri hvønn tunna),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(stjørnufrøðilig eindir),
						'one' => q({0} stjørnufrøðilig eind),
						'other' => q({0} stjørnufrøðiligar eindir),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(stjørnufrøðilig eindir),
						'one' => q({0} stjørnufrøðilig eind),
						'other' => q({0} stjørnufrøðiligar eindir),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimetrar),
						'one' => q({0} sentimetur),
						'other' => q({0} sentimetrar),
						'per' => q({0} fyri hvønn sentimetur),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimetrar),
						'one' => q({0} sentimetur),
						'other' => q({0} sentimetrar),
						'per' => q({0} fyri hvønn sentimetur),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimetrar),
						'one' => q({0} desimetur),
						'other' => q({0} desimetrar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimetrar),
						'one' => q({0} desimetur),
						'other' => q({0} desimetrar),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius á jørðuni),
						'one' => q({0} radius á jørðuni),
						'other' => q({0} radius á jørðuni),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius á jørðuni),
						'one' => q({0} radius á jørðuni),
						'other' => q({0} radius á jørðuni),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tummar),
						'one' => q({0} tummi),
						'other' => q({0} tummar),
						'per' => q({0} fyri hvønn tumma),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tummar),
						'one' => q({0} tummi),
						'other' => q({0} tummar),
						'per' => q({0} fyri hvønn tumma),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometrar),
						'one' => q({0} kilometur),
						'other' => q({0} kilometrar),
						'per' => q({0} fyri hvønn kilometur),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometrar),
						'one' => q({0} kilometur),
						'other' => q({0} kilometrar),
						'per' => q({0} fyri hvønn kilometur),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metrar),
						'one' => q({0} metur),
						'other' => q({0} metrar),
						'per' => q({0} fyri hvønn metur),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metrar),
						'one' => q({0} metur),
						'other' => q({0} metrar),
						'per' => q({0} fyri hvønn metur),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometrar),
						'one' => q({0} mikrometur),
						'other' => q({0} mikrometrar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometrar),
						'one' => q({0} mikrometur),
						'other' => q({0} mikrometrar),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(skandinaviskt míl),
						'one' => q({0} skandinaviskt míl),
						'other' => q({0} skandinaviskt míl),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(skandinaviskt míl),
						'one' => q({0} skandinaviskt míl),
						'other' => q({0} skandinaviskt míl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetrar),
						'one' => q({0} millimetur),
						'other' => q({0} millimetrar),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetrar),
						'one' => q({0} millimetur),
						'other' => q({0} millimetrar),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometrar),
						'one' => q({0} nanometur),
						'other' => q({0} nanometrar),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometrar),
						'one' => q({0} nanometur),
						'other' => q({0} nanometrar),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sjómíl),
						'one' => q({0} sjómíl),
						'other' => q({0} sjómíl),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sjómíl),
						'one' => q({0} sjómíl),
						'other' => q({0} sjómíl),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometrar),
						'one' => q({0} picometur),
						'other' => q({0} picometrar),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometrar),
						'one' => q({0} picometur),
						'other' => q({0} picometrar),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} sólarradius),
						'other' => q({0} sólarradii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} sólarradius),
						'other' => q({0} sólarradii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
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
						'one' => q({0} luks),
						'other' => q({0} luks),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} luks),
						'other' => q({0} luks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} sólarljósmegi),
						'other' => q({0} sólarljósmegi),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} sólarljósmegi),
						'other' => q({0} sólarljósmegi),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} jarðmassi),
						'other' => q({0} jarðmassar),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} jarðmassi),
						'other' => q({0} jarðmassar),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0} fyri hvørt gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0} fyri hvørt gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0} fyri hvørt kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0} fyri hvørt kilogramm),
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
						'per' => q({0} fyri hvørja unsu),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q({0} fyri hvørja unsu),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} fyri hvørt pund),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} fyri hvørt pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} sólarmassi),
						'other' => q({0} sólarmassar),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} sólarmassi),
						'other' => q({0} sólarmassar),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(stutt tons),
						'one' => q({0} stutt tons),
						'other' => q({0} stutt tons),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(stutt tons),
						'one' => q({0} stutt tons),
						'other' => q({0} stutt tons),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tons),
						'one' => q({0} tons),
						'other' => q({0} tons),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tons),
						'one' => q({0} tons),
						'other' => q({0} tons),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} hestakraft),
						'other' => q({0} hestakreftur),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hestakraft),
						'other' => q({0} hestakreftur),
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
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(fer{0}),
						'other' => q(fer{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(fer{0}),
						'other' => q(fer{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(kubikk{0}),
						'other' => q(kubikk{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(kubikk{0}),
						'other' => q(kubikk{0}),
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
						'name' => q(tummar av kviksilvur),
						'one' => q({0} tummi av kviksilvur),
						'other' => q({0} tummar av kviksilvur),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tummar av kviksilvur),
						'one' => q({0} tummi av kviksilvur),
						'other' => q({0} tummar av kviksilvur),
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
						'name' => q(millimetrar av kviksilvur),
						'one' => q({0} millimetur av kviksilvur),
						'other' => q({0} millimetrar av kviksilvur),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetrar av kviksilvur),
						'one' => q({0} millimetur av kviksilvur),
						'other' => q({0} millimetrar av kviksilvur),
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
						'name' => q(pund fyri hvønn kvadrattumma),
						'one' => q(pund fyri hvønn kvadrattumma),
						'other' => q({0} pund fyri hvønn kvadrattumma),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pund fyri hvønn kvadrattumma),
						'one' => q(pund fyri hvønn kvadrattumma),
						'other' => q({0} pund fyri hvønn kvadrattumma),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometrar um tíman),
						'one' => q({0} kilometur um tíman),
						'other' => q({0} kilometrar um tíman),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometrar um tíman),
						'one' => q({0} kilometur um tíman),
						'other' => q({0} kilometrar um tíman),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(sjómíl um tíman),
						'one' => q({0} sjómíl um tíman),
						'other' => q({0} sjómíl um tíman),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(sjómíl um tíman),
						'one' => q({0} sjómíl um tíman),
						'other' => q({0} sjómíl um tíman),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metrar um sekundi),
						'one' => q({0} metur um sekundi),
						'other' => q({0} metrar um sekundi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metrar um sekundi),
						'one' => q({0} metur um sekundi),
						'other' => q({0} metrar um sekundi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(míl um tíman),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(míl um tíman),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(stig Celsius),
						'one' => q({0} stig Celsius),
						'other' => q({0} stig Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(stig Celsius),
						'one' => q({0} stig Celsius),
						'other' => q({0} stig Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(stig Fahrenheit),
						'one' => q({0} stig Fahrenheit),
						'other' => q({0} stig Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(stig Fahrenheit),
						'one' => q({0} stig Fahrenheit),
						'other' => q({0} stig Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtonmetur),
						'one' => q({0} newtonmetur),
						'other' => q({0} newtonmetrar),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtonmetur),
						'one' => q({0} newtonmetur),
						'other' => q({0} newtonmetrar),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pund føtur),
						'one' => q({0} pund fótur),
						'other' => q({0} pund føtur),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pund føtur),
						'one' => q({0} pund fótur),
						'other' => q({0} pund føtur),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tunnur),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tunnur),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilitrar),
						'one' => q({0} sentilitur),
						'other' => q({0} sentilitrar),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilitrar),
						'one' => q({0} sentilitur),
						'other' => q({0} sentilitrar),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kubikksentimetrar),
						'one' => q({0} kubikksentimetur),
						'other' => q({0} kubikksentimetrar),
						'per' => q({0} fyri hvønn kubikksentimetur),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kubikksentimetrar),
						'one' => q({0} kubikksentimetur),
						'other' => q({0} kubikksentimetrar),
						'per' => q({0} fyri hvønn kubikksentimetur),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kubikkføtur),
						'one' => q({0} kubikkfótur),
						'other' => q({0} kubikkføtur),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kubikkføtur),
						'one' => q({0} kubikkfótur),
						'other' => q({0} kubikkføtur),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubikktummar),
						'one' => q({0} kubikktummi),
						'other' => q({0} kubikktummar),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubikktummar),
						'one' => q({0} kubikktummi),
						'other' => q({0} kubikktummar),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubikkkilometrar),
						'one' => q({0} kubikkkilometur),
						'other' => q({0} kubikkkilometrar),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubikkkilometrar),
						'one' => q({0} kubikkkilometur),
						'other' => q({0} kubikkkilometrar),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kubikkmetrar),
						'one' => q({0} kubikkmetur),
						'other' => q({0} kubikkmetrar),
						'per' => q({0} fyri hvønn kubikkmetur),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kubikkmetrar),
						'one' => q({0} kubikkmetur),
						'other' => q({0} kubikkmetrar),
						'per' => q({0} fyri hvønn kubikkmetur),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubikkmíl),
						'one' => q({0} kubikkmíl),
						'other' => q({0} kubikkmíl),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubikkmíl),
						'one' => q({0} kubikkmíl),
						'other' => q({0} kubikkmíl),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubikkyards),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyards),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubikkyards),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyards),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitrar),
						'one' => q({0} desilitur),
						'other' => q({0} desilitrar),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitrar),
						'one' => q({0} desilitur),
						'other' => q({0} desilitrar),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessertskeið),
						'one' => q({0} dessertskeið),
						'other' => q({0} dessertskeiðir),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessertskeið),
						'one' => q({0} dessertskeið),
						'other' => q({0} dessertskeiðir),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(bretsk dessertskeið),
						'one' => q({0} bretsk dessertskeið),
						'other' => q({0} bretskar dessertskeiðir),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(bretsk dessertskeið),
						'one' => q({0} bretsk dessertskeið),
						'other' => q({0} bretskar dessertskeiðir),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} bretsk flótandi unsa),
						'other' => q({0} bretskar flótandi unsur),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} bretsk flótandi unsa),
						'other' => q({0} bretskar flótandi unsur),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} fyri hvønn gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} fyri hvønn gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(bretskar gallons),
						'one' => q({0} bretskur gallon),
						'other' => q({0} bretskar gallons),
						'per' => q({0} fyri hvønn bretska gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(bretskar gallons),
						'one' => q({0} bretskur gallon),
						'other' => q({0} bretskar gallons),
						'per' => q({0} fyri hvønn bretska gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitrar),
						'one' => q({0} hektolitur),
						'other' => q({0} hektolitrar),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitrar),
						'one' => q({0} hektolitur),
						'other' => q({0} hektolitrar),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litrar),
						'one' => q({0} litur),
						'other' => q({0} litrar),
						'per' => q({0} fyri hvønn litur),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litrar),
						'one' => q({0} litur),
						'other' => q({0} litrar),
						'per' => q({0} fyri hvønn litur),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitrar),
						'one' => q({0} megalitur),
						'other' => q({0} megalitrar),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitrar),
						'one' => q({0} megalitur),
						'other' => q({0} megalitrar),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitrar),
						'one' => q({0} millilitur),
						'other' => q({0} millilitrar),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitrar),
						'one' => q({0} millilitur),
						'other' => q({0} millilitrar),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(súpiskeiðir),
						'one' => q({0} súpiskeið),
						'other' => q({0} súpiskeiðir),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(súpiskeiðir),
						'one' => q({0} súpiskeið),
						'other' => q({0} súpiskeiðir),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(teskeiðir),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðir),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(teskeiðir),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðir),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
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
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
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
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}d.),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}d.),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(v.),
						'one' => q({0}v.),
						'other' => q({0}v.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(v.),
						'one' => q({0}v.),
						'other' => q({0}v.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}ár),
						'other' => q({0}ár),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}ár),
						'other' => q({0}ár),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/t),
						'other' => q({0}km/t),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/t),
						'other' => q({0}km/t),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ætt),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ætt),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(dam{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(dam{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bogamin.),
						'one' => q({0} bogamin.),
						'other' => q({0} bogamin.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bogamin.),
						'one' => q({0} bogamin.),
						'other' => q({0} bogamin.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(snúningar),
						'one' => q({0} snú.),
						'other' => q({0} snú.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(snúningar),
						'one' => q({0} snú.),
						'other' => q({0} snú.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ekrur),
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekrur),
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
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
					'area-square-foot' => {
						'name' => q(føtur²),
						'one' => q({0} fót²),
						'other' => q({0} føtur²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(føtur²),
						'one' => q({0} fót²),
						'other' => q({0} føtur²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tum.²),
						'one' => q({0} tum.²),
						'other' => q({0} tum.²),
						'per' => q({0}/tum.²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tum.²),
						'one' => q({0} tum.²),
						'other' => q({0} tum.²),
						'per' => q({0}/tum.²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(míl²),
						'one' => q({0} míl²),
						'other' => q({0} míl²),
						'per' => q({0}/míl²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(míl²),
						'one' => q({0} míl²),
						'other' => q({0} míl²),
						'per' => q({0}/míl²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yards²),
						'one' => q({0} yard²),
						'other' => q({0} yards²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yards²),
						'one' => q({0} yard²),
						'other' => q({0} yards²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
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
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(prosent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(prosent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promillur),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promillur),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partar/millión),
						'one' => q({0} pt./mill.),
						'other' => q({0} pt./mill.),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partar/millión),
						'one' => q({0} pt./mill.),
						'other' => q({0} pt./mill.),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(promyriad),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(promyriad),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
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
						'name' => q(míl/gallon),
						'one' => q({0} míl/gallon),
						'other' => q({0} míl/gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(míl/gallon),
						'one' => q({0} míl/gallon),
						'other' => q({0} míl/gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(míl/UK gallon),
						'one' => q({0} míl/UK gallon),
						'other' => q({0} míl/UK gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(míl/UK gallon),
						'one' => q({0} míl/UK gallon),
						'other' => q({0} míl/UK gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(být),
						'one' => q({0} být),
						'other' => q({0} být),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(být),
						'one' => q({0} být),
						'other' => q({0} být),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ø.),
						'one' => q({0} ø.),
						'other' => q({0} ø.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ø.),
						'one' => q({0} ø.),
						'other' => q({0} ø.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dagar),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dagar),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(áratí.),
						'one' => q({0} áratí.),
						'other' => q({0} áratí.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(áratí.),
						'one' => q({0} áratí.),
						'other' => q({0} áratí.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(tímar),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(tímar),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosek.),
						'one' => q({0} μs.),
						'other' => q({0} μs.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosek.),
						'one' => q({0} μs.),
						'other' => q({0} μs.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mnð.),
						'one' => q({0} mnð.),
						'other' => q({0} mnð.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mnð.),
						'one' => q({0} mnð.),
						'other' => q({0} mnð.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vikur),
						'one' => q({0} vi.),
						'other' => q({0} vi.),
						'per' => q({0}/vi.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vikur),
						'one' => q({0} vi.),
						'other' => q({0} vi.),
						'per' => q({0}/vi.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ár),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ár),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperur),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperur),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamperur),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamperur),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(bretskar hitaeindir),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(bretskar hitaeindir),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kostkaloriur),
						'one' => q({0} kostkaloria),
						'other' => q({0} kostkaloriur),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kostkaloriur),
						'one' => q({0} kostkaloria),
						'other' => q({0} kostkaloriur),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(hitaeindir),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(hitaeindir),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megaskíggjadeplar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megaskíggjadeplar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(skíggjadeplar),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(skíggjadeplar),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(favnar),
						'one' => q({0} favnur),
						'other' => q({0} favnar),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(favnar),
						'one' => q({0} favnur),
						'other' => q({0} favnar),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(føtur),
						'one' => q({0} fótur),
						'other' => q({0} føtur),
						'per' => q({0}/fót),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(føtur),
						'one' => q({0} fótur),
						'other' => q({0} føtur),
						'per' => q({0}/fót),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongrar),
						'one' => q({0} furlongur),
						'other' => q({0} furlongrar),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongrar),
						'one' => q({0} furlongur),
						'other' => q({0} furlongrar),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tum.),
						'one' => q({0} tum.),
						'other' => q({0} tum.),
						'per' => q({0}/tum.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tum.),
						'one' => q({0} tum.),
						'other' => q({0} tum.),
						'per' => q({0}/tum.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
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
						'name' => q(míl),
						'one' => q({0} míl),
						'other' => q({0} míl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(míl),
						'one' => q({0} míl),
						'other' => q({0} míl),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sk. míl),
						'one' => q({0} sk. míl),
						'other' => q({0} sk. míl),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sk. míl),
						'one' => q({0} sk. míl),
						'other' => q({0} sk. míl),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(prikkar),
						'one' => q({0} prikkur),
						'other' => q({0} prikkar),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(prikkar),
						'one' => q({0} prikkur),
						'other' => q({0} prikkar),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sólarradii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sólarradii),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(sólarljósmegi),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(sólarljósmegi),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(jarðmassi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(jarðmassi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unsur),
						'one' => q({0} unsa),
						'other' => q({0} unsur),
						'per' => q({0}/unsu),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unsur),
						'one' => q({0} unsa),
						'other' => q({0} unsur),
						'per' => q({0}/unsu),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy unsur),
						'one' => q({0} troy unsa),
						'other' => q({0} troy unsur),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy unsur),
						'one' => q({0} troy unsa),
						'other' => q({0} troy unsur),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sólarmassi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sólarmassi),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(stutt t),
						'one' => q({0} stutt t),
						'other' => q({0} stutt t),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(stutt t),
						'one' => q({0} stutt t),
						'other' => q({0} stutt t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hestakreftur),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestakreftur),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(lufttrýst),
						'one' => q({0} lufttrýst),
						'other' => q({0} lufttrýst),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(lufttrýst),
						'one' => q({0} lufttrýst),
						'other' => q({0} lufttrýst),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(smíl/t),
						'one' => q({0} smíl/t),
						'other' => q({0} smíl/t),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(smíl/t),
						'one' => q({0} smíl/t),
						'other' => q({0} smíl/t),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(míl/t),
						'one' => q({0} míl/t),
						'other' => q({0} míl/t),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(míl/t),
						'one' => q({0} míl/t),
						'other' => q({0} míl/t),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekraføtur),
						'one' => q({0} ekrafótur),
						'other' => q({0} ekraføtur),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekraføtur),
						'one' => q({0} ekrafótur),
						'other' => q({0} ekraføtur),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tunna),
						'one' => q({0} tunna),
						'other' => q({0} tunnur),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tunna),
						'one' => q({0} tunna),
						'other' => q({0} tunnur),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skeppur),
						'one' => q({0} skeppa),
						'other' => q({0} skeppur),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skeppur),
						'one' => q({0} skeppa),
						'other' => q({0} skeppur),
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
					'volume-cubic-foot' => {
						'name' => q(føtur³),
						'one' => q({0} fótur³),
						'other' => q({0} føtur³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(føtur³),
						'one' => q({0} fótur³),
						'other' => q({0} føtur³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(tum.³),
						'one' => q({0} tum.³),
						'other' => q({0} tum.³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(tum.³),
						'one' => q({0} tum.³),
						'other' => q({0} tum.³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(míl³),
						'one' => q({0} míl³),
						'other' => q({0} míl³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(míl³),
						'one' => q({0} míl³),
						'other' => q({0} míl³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yards³),
						'one' => q({0} yard³),
						'other' => q({0} yards³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yards³),
						'one' => q({0} yard³),
						'other' => q({0} yards³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koppar),
						'one' => q({0} koppur),
						'other' => q({0} koppar),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} koppur),
						'other' => q({0} koppar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metralag koppar),
						'one' => q({0} metralag koppur),
						'other' => q({0} metralag koppar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metralag koppar),
						'one' => q({0} metralag koppur),
						'other' => q({0} metralag koppar),
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
						'name' => q(dessertsk.),
						'one' => q({0} dessertsk.),
						'other' => q({0} dessertsk.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessertsk.),
						'one' => q({0} dessertsk.),
						'other' => q({0} dessertsk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(bretsk dessertsk.),
						'one' => q({0} bretsk dessertsk.),
						'other' => q({0} bretskar dessertsk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(bretsk dessertsk.),
						'one' => q({0} bretsk dessertsk.),
						'other' => q({0} bretskar dessertsk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drammur),
						'one' => q({0} drammur),
						'other' => q({0} drammar),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drammur),
						'one' => q({0} drammur),
						'other' => q({0} drammar),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dropi),
						'one' => q({0} dropi),
						'other' => q({0} dropar),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dropi),
						'one' => q({0} dropi),
						'other' => q({0} dropar),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(flótandi unsur),
						'one' => q({0} flótandi unsa),
						'other' => q({0} flótandi unsur),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(flótandi unsur),
						'one' => q({0} flótandi unsa),
						'other' => q({0} flótandi unsur),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(bretskar flótandi unsur),
						'one' => q({0} bretsk flótandi unsa),
						'other' => q({0} bretskar flót. unsur),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(bretskar flótandi unsur),
						'one' => q({0} bretsk flótandi unsa),
						'other' => q({0} bretskar flót. unsur),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0}/gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0}/gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(UK gallons),
						'one' => q({0} UK gallon),
						'other' => q({0} UK gallons),
						'per' => q({0}/UK gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(UK gallons),
						'one' => q({0} UK gallon),
						'other' => q({0} UK gallons),
						'per' => q({0}/UK gallon),
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
						'name' => q(snapsur),
						'one' => q({0} snapsur),
						'other' => q({0} snapsar),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(snapsur),
						'one' => q({0} snapsur),
						'other' => q({0} snapsar),
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
						'name' => q(vet),
						'one' => q({0} vet),
						'other' => q({0} vet),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(vet),
						'one' => q({0} vet),
						'other' => q({0} vet),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metralag pints),
						'one' => q({0} metralag pint),
						'other' => q({0} metralag pints),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metralag pints),
						'one' => q({0} metralag pint),
						'other' => q({0} metralag pints),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(bretskur quart),
						'one' => q({0} bretskur quart),
						'other' => q({0} bretskir quartar),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(bretskur quart),
						'one' => q({0} bretskur quart),
						'other' => q({0} bretskir quartar),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(súpisk.),
						'one' => q({0} súpisk.),
						'other' => q({0} súpisk.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(súpisk.),
						'one' => q({0} súpisk.),
						'other' => q({0} súpisk.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tesk.),
						'one' => q({0} tesk.),
						'other' => q({0} tesk.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tesk.),
						'one' => q({0} tesk.),
						'other' => q({0} tesk.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, og {1}),
				2 => q({0} og {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'minusSign' => q(−),
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
					'one' => '0 túsund',
					'other' => '0 túsund',
				},
				'10000' => {
					'one' => '00 túsund',
					'other' => '00 túsund',
				},
				'100000' => {
					'one' => '000 túsund',
					'other' => '000 túsund',
				},
				'1000000' => {
					'one' => '0 millión',
					'other' => '0 milliónir',
				},
				'10000000' => {
					'one' => '00 milliónir',
					'other' => '00 milliónir',
				},
				'100000000' => {
					'one' => '000 milliónir',
					'other' => '000 milliónir',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliardir',
				},
				'10000000000' => {
					'one' => '00 milliardir',
					'other' => '00 milliardir',
				},
				'100000000000' => {
					'one' => '000 milliardir',
					'other' => '000 milliardir',
				},
				'1000000000000' => {
					'one' => '0 billión',
					'other' => '0 billiónir',
				},
				'10000000000000' => {
					'one' => '00 billiónir',
					'other' => '00 billiónir',
				},
				'100000000000000' => {
					'one' => '000 billiónir',
					'other' => '000 billiónir',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tús'.'',
					'other' => '0 tús'.'',
				},
				'10000' => {
					'one' => '00 tús'.'',
					'other' => '00 tús'.'',
				},
				'100000' => {
					'one' => '000 tús'.'',
					'other' => '000 tús'.'',
				},
				'1000000' => {
					'one' => '0 mió'.'',
					'other' => '0 mió'.'',
				},
				'10000000' => {
					'one' => '00 mió'.'',
					'other' => '00 mió'.'',
				},
				'100000000' => {
					'one' => '000 mió'.'',
					'other' => '000 mió'.'',
				},
				'1000000000' => {
					'one' => '0 mia'.'',
					'other' => '0 mia'.'',
				},
				'10000000000' => {
					'one' => '00 mia'.'',
					'other' => '00 mia'.'',
				},
				'100000000000' => {
					'one' => '000 mia'.'',
					'other' => '000 mia'.'',
				},
				'1000000000000' => {
					'one' => '0 bió'.'',
					'other' => '0 bió'.'',
				},
				'10000000000000' => {
					'one' => '00 bió'.'',
					'other' => '00 bió'.'',
				},
				'100000000000000' => {
					'one' => '000 bió'.'',
					'other' => '000 bió'.'',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
						'negative' => '(#,##0.00 ¤)',
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
		'AED' => {
			display_name => {
				'currency' => q(Sameindu Emirríkini dirham),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistan afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albania lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenia dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niðurlonds Karibia gyllin),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola kwanza),
				'one' => q(Angola kwanza),
				'other' => q(Angola kwanzar),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentina peso),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Avstralskur dollari),
				'one' => q(Avstralskur dollari),
				'other' => q(Avstralskir dollarar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbadjan manat),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Hersegovina mark \(kann vekslast\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados dollari),
				'one' => q(Barbados dollari),
				'other' => q(Barbados dollarar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladesj taka),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarskur lev),
				'one' => q(bulgarskur lev),
				'other' => q(bulgarskir leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Barein dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi frankur),
				'one' => q(Burundi frankur),
				'other' => q(Burundi frankar),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda dollari),
				'one' => q(Bermuda dollari),
				'other' => q(Bermuda dollarar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei dollari),
				'one' => q(Brunei dollari),
				'other' => q(Brunei dollarar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivia boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasilianskur real),
				'one' => q(Brasilianskur real),
				'other' => q(Brasilianskir real),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamaoyggjar dollari),
				'one' => q(Bahamaoyggjar dollari),
				'other' => q(Bahamaoyggjar dollarar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan ngultrum),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsvana pula),
				'one' => q(Botsvana pula),
				'other' => q(Botsvana pular),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Hvítarussiskur ruble),
				'one' => q(hvítarussiskur ruble),
				'other' => q(hvítarussiskir ruble),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Hvítarussland ruble \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belis dollari),
				'one' => q(Belis dollari),
				'other' => q(Belis dollarar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanadiskur dollari),
				'one' => q(kanadiskur dollari),
				'other' => q(kanadiskir dollarar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo frankur),
				'one' => q(Kongo frankur),
				'other' => q(Kongo frankar),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(sveisiskur frankur),
				'one' => q(sveisiskur frankur),
				'other' => q(sveisiskir frankar),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Kili peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kinesiskur yuan \(úr landi\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kinesiskur yuan),
				'one' => q(kinesiskur yuan),
				'other' => q(kinesiskir yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolombia peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kosta Rika colón),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kuba peso \(sum kann vekslast\)),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuba peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Grønhøvdaoyggjar escudo),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Kekkiskt koruna),
				'one' => q(kekkiskt koruna),
				'other' => q(kekkiskar korunur),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djibuti frankur),
				'one' => q(Djibuti frankur),
				'other' => q(Djibuti frankar),
			},
		},
		'DKK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(donsk króna),
				'one' => q(donsk króna),
				'other' => q(danskar krónur),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominika peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algeria dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptaland pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrea nakfa),
				'one' => q(Eritrea nakfa),
				'other' => q(Eritrea nakfar),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiopia birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Evra),
				'one' => q(evra),
				'other' => q(evrur),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fiji dollari),
				'one' => q(Fiji dollari),
				'other' => q(Fiji dollarar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklandsoyggjar pund),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(bretsk pund),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgia lari),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Gana cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar pund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinea frankur),
				'one' => q(Guinea frankur),
				'other' => q(Guinea frankar),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemala quetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Gujana dollari),
				'one' => q(Gujana dollari),
				'other' => q(Gujana dollarar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong dollari),
				'one' => q(Hong Kong dollari),
				'other' => q(Hong Kong dollarar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduras lempira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatia kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungarskur forintur),
				'one' => q(ungarskur forintur),
				'other' => q(ungarskir forintar),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesia rupiah),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Ísrael new shekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indiskir rupis),
				'one' => q(indiskur rupi),
				'other' => q(indiskir rupis),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irak dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranskir rials),
				'one' => q(iranskur rial),
				'other' => q(iranskir rials),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(íslendsk króna),
				'one' => q(íslendsk króna),
				'other' => q(íslendskar krónur),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika dollari),
				'one' => q(Jamaika dollari),
				'other' => q(Jamaika dollarar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordan dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japanskur yen),
				'one' => q(japanskur yen),
				'other' => q(japanskir yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenjanskur skillingur),
				'one' => q(kenjanskur skillingur),
				'other' => q(kenjanskir skillingar),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisia som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodja riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoroyggjar frankur),
				'one' => q(Komoroyggjar frankur),
				'other' => q(Komoroyggjar frankar),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Norðurkorea won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Suðurkorea won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuvait dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Caymanoyggjar dollari),
				'one' => q(Caymanoyggjar dollari),
				'other' => q(Caymanoyggjar dollarar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasakstan tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laos kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanon pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lanka rupi),
				'one' => q(Sri Lanka rupi),
				'other' => q(Sri Lanka rupis),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberia dollari),
				'one' => q(Liberia dollari),
				'other' => q(Liberia dollarar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libya dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokko dirham),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovanskur leu),
				'one' => q(moldovanskur leu),
				'other' => q(moldovanskir lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskar ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedónia denar),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar \(Burma\) kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolia tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Móritania ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Móritania ouguiya),
				'one' => q(Móritania ouguiya),
				'other' => q(Móritania ouguiyar),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Móritius rupi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivoyggjar rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malavi kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksiko peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaisia ringgit),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambik metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia dollari),
				'one' => q(Namibia dollari),
				'other' => q(Namibia dollarar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeria naira),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragua córdoba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norsk króna),
				'one' => q(norsk króna),
				'other' => q(norskar krónur),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepal rupi),
				'one' => q(Nepal rupi),
				'other' => q(Nepal rupis),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Nýsæland dollari),
				'one' => q(Nýsæland dollari),
				'other' => q(Nýsæland dollarar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Oman rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua Nýguinea kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipsoyggjar peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistan rupi),
				'one' => q(Pakistan rupi),
				'other' => q(Pakistan rupis),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Pólskur zloty),
				'one' => q(pólskur zloty),
				'other' => q(pólskir zloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguai guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar rial),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumenia leu),
				'one' => q(Rumenia leu),
				'other' => q(Rumenia lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbia dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russland ruble),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda frankur),
				'one' => q(Ruanda frankur),
				'other' => q(Ruanda frankar),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudiarabia riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomonoyggjar dollari),
				'one' => q(Salomonoyggjar dollari),
				'other' => q(Salomonoyggjar dollarar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyskelloyggjar rupi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan pund),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(svensk króna),
				'one' => q(svensk króna),
				'other' => q(svenskar krónur),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapor dollari),
				'one' => q(Singapor dollari),
				'other' => q(Singapor dollarar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena pund),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leona leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leona leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalia skillingur),
				'one' => q(Somalia skillingur),
				'other' => q(Somalia skillingar),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam dollari),
				'one' => q(Surinam dollari),
				'other' => q(Surinam dollarar),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Suðursudan pund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tome & Prinsipi dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome & Prinsipi dobra),
				'one' => q(Sao Tome & Prinsipi dobra),
				'other' => q(Sao Tome & Prinsipi dobrar),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Sýria pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svasiland lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Tailand baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadsjikistan somoni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistan manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunesia dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkaland liri),
				'one' => q(Turkaland liri),
				'other' => q(Turkaland lirir),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad & Tobago dollari),
				'one' => q(Trinidad & Tobago dollari),
				'other' => q(Trinidad & Tobago dollarar),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Taivan new dollari),
				'one' => q(Taivan new dollari),
				'other' => q(Taivan new dollarar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansania skillingur),
				'one' => q(Tansania skillingur),
				'other' => q(Tansania skillingar),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukraina hryvnia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda skillingur),
				'one' => q(Uganda skillingur),
				'other' => q(Uganda skillingar),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(US dollari),
				'one' => q(US dollari),
				'other' => q(US dollarar),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguai peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbekistan som),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venesuela bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venesuela bolívar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vjetnam dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Miðafrika CFA frankur),
				'one' => q(Miðafrika CFA frankur),
				'other' => q(Miðafrika CFA frankar),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(unse sølv),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(unse guld),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Eystur Karibia dollari),
				'one' => q(Eystur Karibia dollari),
				'other' => q(Eystur Karibia dollarar),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Vesturafrika CFA frankur),
				'one' => q(Vesturafrika CFA frankur),
				'other' => q(Vesturafrika CFA frankar),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(unse palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP frankur),
				'one' => q(CFP frankur),
				'other' => q(CFP frankar),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(unse platin),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Ókent gjaldoyra),
				'one' => q(\(ókent gjaldoyra\)),
				'other' => q(\(ókent gjaldoyra\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemen rial),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Suðurafrika rand),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Sambia kwacha),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'jan.',
							'feb.',
							'mar.',
							'apr.',
							'mai',
							'jun.',
							'jul.',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'des.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'mars',
							'apríl',
							'mai',
							'juni',
							'juli',
							'august',
							'september',
							'oktober',
							'november',
							'desember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'feb',
							'mar',
							'apr',
							'mai',
							'jun',
							'jul',
							'aug',
							'sep',
							'okt',
							'nov',
							'des'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
						mon => 'mán.',
						tue => 'týs.',
						wed => 'mik.',
						thu => 'hós.',
						fri => 'frí.',
						sat => 'ley.',
						sun => 'sun.'
					},
					short => {
						mon => 'má.',
						tue => 'tý.',
						wed => 'mi.',
						thu => 'hó.',
						fri => 'fr.',
						sat => 'le.',
						sun => 'su.'
					},
					wide => {
						mon => 'mánadagur',
						tue => 'týsdagur',
						wed => 'mikudagur',
						thu => 'hósdagur',
						fri => 'fríggjadagur',
						sat => 'leygardagur',
						sun => 'sunnudagur'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'mán',
						tue => 'týs',
						wed => 'mik',
						thu => 'hós',
						fri => 'frí',
						sat => 'ley',
						sun => 'sun'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'M',
						thu => 'H',
						fri => 'F',
						sat => 'L',
						sun => 'S'
					},
					short => {
						mon => 'má',
						tue => 'tý',
						wed => 'mi',
						thu => 'hó',
						fri => 'fr',
						sat => 'le',
						sun => 'su'
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
					abbreviated => {0 => '1. ársfj.',
						1 => '2. ársfj.',
						2 => '3. ársfj.',
						3 => '4. ársfj.'
					},
					wide => {0 => '1. ársfjórðingur',
						1 => '2. ársfjórðingur',
						2 => '3. ársfjórðingur',
						3 => '4. ársfjórðingur'
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			narrow => {
				'0' => 'fKr',
				'1' => 'eKr'
			},
			wide => {
				'0' => 'fyri Krist',
				'1' => 'eftir Krist'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, dd. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{dd.MM.y},
			'short' => q{dd.MM.yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{dd.MM.y GGGGG},
			MEd => q{E dd.MM},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yM => q{MM.y},
			yMEd => q{E dd.MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM y},
			yMMMd => q{d. MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ 'í' y},
			yQQQQ => q{QQQQ 'í' y},
			yyyy => q{y G},
			yyyyM => q{MM.y GGGGG},
			yyyyMEd => q{E dd.MM.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{dd.MM.y GGGGG},
			yyyyQQQ => q{QQQ 'í' y G},
			yyyyQQQQ => q{QQQQ 'í' y G},
		},
		'gregorian' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{dd.MM.y G},
			M => q{LL},
			MEd => q{E dd.MM},
			MMMEd => q{E d. MMM},
			MMMMW => q{W. 'vika' 'í' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM.y},
			yMEd => q{E dd.MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ 'í' y},
			yQQQQ => q{QQQQ 'í' y},
			yw => q{w. 'vika' 'í' Y},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y–MM.y GGGGG},
				y => q{MM.y–MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y–dd.MM.y GGGGG},
				d => q{dd.MM.y–dd.MM.y GGGGG},
				y => q{dd.MM.y–dd.MM.y GGGGG},
			},
			MEd => {
				M => q{E dd.MM–E dd.MM},
				d => q{E dd.MM–E dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d. MMM–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d.–d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y–MM.y GGGGG},
				y => q{MM.y–MM.y GGGGG},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y GGGGG},
				d => q{E dd.MM.y–E dd.MM.y GGGGG},
				y => q{E dd.MM.y–E dd.MM.y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM y},
				d => q{E d. MMM–E d. MMM y},
				y => q{E d. MMM y–E d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y–MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y GGGGG},
				d => q{dd.MM.y–dd.MM.y GGGGG},
				y => q{dd.MM.y–dd.MM.y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y–MM.y GGGGG},
				y => q{MM.y–MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y–dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			MEd => {
				M => q{E dd.MM–E dd.MM},
				d => q{E dd.MM–E dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d. MMM–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d.–d.},
			},
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y},
				d => q{E dd.MM.y–E dd.MM.y},
				y => q{E dd.MM.y–E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E dd. MMM–E dd. MMM y},
				d => q{E dd. MMM–E dd. MMM y},
				y => q{E dd. MMM y–E dd. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y–MMMM y},
			},
			yMMMd => {
				M => q{dd. MMM–dd. MMM y},
				d => q{d.–d. MMM y},
				y => q{dd. MMM y–dd. MMM y},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y},
				d => q{dd.MM.y–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} tíð),
		regionFormat => q({0} summartíð),
		regionFormat => q({0} vanlig tíð),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan tíð#,
			},
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Miðafrika tíð#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Eysturafrika tíð#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Suðurafrika vanlig tíð#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Vesturafrika summartíð#,
				'generic' => q#Vesturafrika tíð#,
				'standard' => q#Vesturafrika vanlig tíð#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska summartíð#,
				'generic' => q#Alaska tíð#,
				'standard' => q#Alaska vanlig tíð#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amasona summartíð#,
				'generic' => q#Amasona tíð#,
				'standard' => q#Amasona vanlig tíð#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Belis#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central summartíð#,
				'generic' => q#Central tíð#,
				'standard' => q#Central vanlig tíð#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern summartíð#,
				'generic' => q#Eastern tíð#,
				'standard' => q#Eastern vanlig tíð#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain summartíð#,
				'generic' => q#Mountain tíð#,
				'standard' => q#Mountain vanlig tíð#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific summartíð#,
				'generic' => q#Pacific tíð#,
				'standard' => q#Pacific vanlig tíð#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia summartíð#,
				'generic' => q#Apia tíð#,
				'standard' => q#Apia vanlig tíð#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabisk summartíð#,
				'generic' => q#Arabisk tíð#,
				'standard' => q#Arabisk vanlig tíð#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina summartíð#,
				'generic' => q#Argentina tíð#,
				'standard' => q#Argentina vanlig tíð#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Vestur Argentina summartíð#,
				'generic' => q#Vestur Argentina tíð#,
				'standard' => q#Vestur Argentina vanlig tíð#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia summartíð#,
				'generic' => q#Armenia tíð#,
				'standard' => q#Armenia vanlig tíð#,
			},
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barein#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gasa#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapor#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic summartíð#,
				'generic' => q#Atlantic tíð#,
				'standard' => q#Atlantic vanlig tíð#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorurnar#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Grønhøvdaoyggjar#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Føroyar#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Suðurgeorgiaoyggjar#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#mið Avstralia summartíð#,
				'generic' => q#mið Avstralia tíð#,
				'standard' => q#mið Avstralia vanlig tíð#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#miðvestur Avstralia summartíð#,
				'generic' => q#miðvestur Avstralia tíð#,
				'standard' => q#miðvestur Avstralia vanlig tíð#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#eystur Avstralia summartíð#,
				'generic' => q#eystur Avstralia tíð#,
				'standard' => q#eystur Avstralia vanlig tíð#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#vestur Avstralia summartíð#,
				'generic' => q#vestur Avstralia tíð#,
				'standard' => q#vestur Avstralia vanlig tíð#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbadjan summartíð#,
				'generic' => q#Aserbadjan tíð#,
				'standard' => q#Aserbadjan vanlig tíð#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorurnar summartíð#,
				'generic' => q#Azorurnar tíð#,
				'standard' => q#Azorurnar vanlig tíð#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesj summartíð#,
				'generic' => q#Bangladesj tíð#,
				'standard' => q#Bangladesj vanlig tíð#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan tíð#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia tíð#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia summartíð#,
				'generic' => q#Brasilia tíð#,
				'standard' => q#Brasilia vanlig tíð#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam tíð#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Grønhøvdaoyggjar summartíð#,
				'generic' => q#Grønhøvdaoyggjar tíð#,
				'standard' => q#Grønhøvdaoyggjar vanlig tíð#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro vanlig tíð#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham summartíð#,
				'generic' => q#Chatham tíð#,
				'standard' => q#Chatham vanlig tíð#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Kili summartíð#,
				'generic' => q#Kili tíð#,
				'standard' => q#Kili vanlig tíð#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kina summartíð#,
				'generic' => q#Kina tíð#,
				'standard' => q#Kina vanlig tíð#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan summartíð#,
				'generic' => q#Choibalsan tíð#,
				'standard' => q#Choibalsan vanlig tíð#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Jólaoyggj tíð#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokosoyggjar tíð#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolombia summartíð#,
				'generic' => q#Kolombia tíð#,
				'standard' => q#Kolombia vanlig tíð#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cooksoyggjar summartíð#,
				'generic' => q#Cooksoyggjar tíð#,
				'standard' => q#Cooksoyggjar vanlig tíð#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba summartíð#,
				'generic' => q#Cuba tíð#,
				'standard' => q#Cuba vanlig tíð#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis tíð#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville tíð#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Eysturtimor tíð#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Páskaoyggin summartíð#,
				'generic' => q#Páskaoyggin tíð#,
				'standard' => q#Páskaoyggin vanlig tíð#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador tíð#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Samskipað heimstíð#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ókendur býur#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Keypmannahavn#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Írsk vanlig tíð#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Bretsk summartíð#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemborg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkhólm#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanið#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsjava#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Miðevropa summartíð#,
				'generic' => q#Miðevropa tíð#,
				'standard' => q#Miðevropa vanlig tíð#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Eysturevropa summartíð#,
				'generic' => q#Eysturevropa tíð#,
				'standard' => q#Eysturevropa vanlig tíð#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#longri Eysturevropa tíð#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Vesturevropa summartíð#,
				'generic' => q#Vesturevropa tíð#,
				'standard' => q#Vesturevropa vanlig tíð#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandsoyggjar summartíð#,
				'generic' => q#Falklandsoyggjar tíð#,
				'standard' => q#Falklandsoyggjar vanlig tíð#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji summartíð#,
				'generic' => q#Fiji tíð#,
				'standard' => q#Fiji vanlig tíð#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Franska Gujana tíð#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fronsku sunnaru landaøki og Antarktis tíð#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean tíð#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos tíð#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier tíð#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia summartíð#,
				'generic' => q#Georgia tíð#,
				'standard' => q#Georgia vanlig tíð#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertoyggjar tíð#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Eystur grønlendsk summartíð#,
				'generic' => q#Eystur grønlendsk tíð#,
				'standard' => q#Eystur grønlendsk vanlig tíð#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Vestur grønlendsk summartíð#,
				'generic' => q#Vestur grønlendsk tíð#,
				'standard' => q#Vestur grønlendsk vanlig tíð#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gulf vanlig tíð#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gujana tíð#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian summartíð#,
				'generic' => q#Hawaii-Aleutian tíð#,
				'standard' => q#Hawaii-Aleutian vanlig tíð#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong summartíð#,
				'generic' => q#Hong Kong tíð#,
				'standard' => q#Hong Kong vanlig tíð#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd summartíð#,
				'generic' => q#Hovd tíð#,
				'standard' => q#Hovd vanlig tíð#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India tíð#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivoyggjar#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Móritius#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiahav tíð#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokina tíð#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Mið Indonesia tíð#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eystur Indonesia tíð#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Vestur Indonesia tíð#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran summartíð#,
				'generic' => q#Iran tíð#,
				'standard' => q#Iran vanlig tíð#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk summartíð#,
				'generic' => q#Irkutsk tíð#,
				'standard' => q#Irkutsk vanlig tíð#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ísrael summartíð#,
				'generic' => q#Ísrael tíð#,
				'standard' => q#Ísrael vanlig tíð#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan summartíð#,
				'generic' => q#Japan tíð#,
				'standard' => q#Japan vanlig tíð#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Eystur Kasakstan tíð#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Vestur Kasakstan tíð#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korea summartíð#,
				'generic' => q#Korea tíð#,
				'standard' => q#Korea vanlig tíð#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae tíð#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk summartíð#,
				'generic' => q#Krasnoyarsk tíð#,
				'standard' => q#Krasnoyarsk vanlig tíð#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisia tíð#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Lineoyggjar tíð#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe summartíð#,
				'generic' => q#Lord Howe tíð#,
				'standard' => q#Lord Howe vanlig tíð#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquariesoyggj tíð#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan summartíð#,
				'generic' => q#Magadan tíð#,
				'standard' => q#Magadan vanlig tíð#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaisia tíð#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivoyggjar tíð#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas tíð#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalloyggjar tíð#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Móritius summartíð#,
				'generic' => q#Móritius tíð#,
				'standard' => q#Móritius vanlig tíð#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson tíð#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Northwest Mexico summartíð#,
				'generic' => q#Northwest Mexico tíð#,
				'standard' => q#Northwest Mexico vanlig tíð#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific summartíð#,
				'generic' => q#Mexican Pacific tíð#,
				'standard' => q#Mexican Pacific vanlig tíð#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator summartíð#,
				'generic' => q#Ulan Bator tíð#,
				'standard' => q#Ulan Bator vanlig tíð#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva summartíð#,
				'generic' => q#Moskva tíð#,
				'standard' => q#Moskva vanlig tíð#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar (Burma) tíð#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru tíð#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal tíð#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nýkaledónia summartíð#,
				'generic' => q#Nýkaledónia tíð#,
				'standard' => q#Nýkaledónia vanlig tíð#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nýsæland summartíð#,
				'generic' => q#Nýsæland tíð#,
				'standard' => q#Nýsæland vanlig tíð#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland summartíð#,
				'generic' => q#Newfoundland tíð#,
				'standard' => q#Newfoundland vanlig tíð#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue tíð#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolkoyggj summartíð#,
				'generic' => q#Norfolkoyggj tíð#,
				'standard' => q#Norfolkoyggj vanlig tíð#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha summartíð#,
				'generic' => q#Fernando de Noronha tíð#,
				'standard' => q#Fernando de Noronha vanlig tíð#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk summartíð#,
				'generic' => q#Novosibirsk tíð#,
				'standard' => q#Novosibirsk vanlig tíð#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk summartíð#,
				'generic' => q#Omsk tíð#,
				'standard' => q#Omsk vanlig tíð#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan summartíð#,
				'generic' => q#Pakistan tíð#,
				'standard' => q#Pakistan vanlig tíð#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau tíð#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Nýguinea tíð#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguai summartíð#,
				'generic' => q#Paraguai tíð#,
				'standard' => q#Paraguai vanlig tíð#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru summartíð#,
				'generic' => q#Peru tíð#,
				'standard' => q#Peru vanlig tíð#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipsoyggjar summartíð#,
				'generic' => q#Filipsoyggjar tíð#,
				'standard' => q#Filipsoyggjar vanlig tíð#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixoyggjar tíð#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon summartíð#,
				'generic' => q#St. Pierre & Miquelon tíð#,
				'standard' => q#St. Pierre & Miquelon vanlig tíð#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairnoyggjar tíð#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape tíð#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang tíð#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion tíð#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera tíð#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin summartíð#,
				'generic' => q#Sakhalin tíð#,
				'standard' => q#Sakhalin vanlig tíð#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa summartíð#,
				'generic' => q#Samoa tíð#,
				'standard' => q#Samoa vanlig tíð#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyskelloyggjar tíð#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapor tíð#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonoyggjar tíð#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Suðurgeorgiaoyggjar tíð#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam tíð#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa tíð#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti tíð#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei summartíð#,
				'generic' => q#Taipei tíð#,
				'standard' => q#Taipei vanlig tíð#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadsjikistan tíð#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau tíð#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga summartíð#,
				'generic' => q#Tonga tíð#,
				'standard' => q#Tonga vanlig tíð#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk tíð#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan summartíð#,
				'generic' => q#Turkmenistan tíð#,
				'standard' => q#Turkmenistan vanlig tíð#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu tíð#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguai summartíð#,
				'generic' => q#Uruguai tíð#,
				'standard' => q#Uruguai vanlig tíð#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistan summartíð#,
				'generic' => q#Usbekistan tíð#,
				'standard' => q#Usbekistan vanlig tíð#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu summartíð#,
				'generic' => q#Vanuatu tíð#,
				'standard' => q#Vanuatu vanlig tíð#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venesuela tíð#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok summartíð#,
				'generic' => q#Vladivostok tíð#,
				'standard' => q#Vladivostok vanlig tíð#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd summartíð#,
				'generic' => q#Volgograd tíð#,
				'standard' => q#Volgograd vanlig tíð#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok tíð#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wakeoyggj tíð#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis- og Futunaoyggjar tíð#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk summartíð#,
				'generic' => q#Yakutsk tíð#,
				'standard' => q#Yakutsk vanlig tíð#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg summartíð#,
				'generic' => q#Yekaterinburg tíð#,
				'standard' => q#Yekaterinburg vanlig tíð#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon tíð#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
