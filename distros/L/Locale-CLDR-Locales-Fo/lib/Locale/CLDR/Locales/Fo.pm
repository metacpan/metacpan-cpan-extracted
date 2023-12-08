=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fo - Package for language Faroese

=cut

package Locale::CLDR::Locales::Fo;
# This file auto generated from Data\common\main\fo.xml
#	on Tue  5 Dec  1:10:32 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
 				'en_GB@alt=short' => 'enskt (UK)',
 				'en_US@alt=short' => 'enskt (USA)',
 				'eo' => 'esperanto',
 				'es' => 'spanskt',
 				'et' => 'estiskt',
 				'eu' => 'baskiskt',
 				'ewo' => 'ewondo',
 				'fa' => 'persiskt',
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
 				'root' => 'root',
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
 				'zgh' => 'vanligt marokanskt tamazight',
 				'zh' => 'kinesiskt',
 				'zh_Hans' => 'einkult kinesiskt',
 				'zh_Hant' => 'vanligt kinesiskt',
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
 			'MK' => 'Makedónia',
 			'MK@alt=variant' => 'Makedónia (FJM)',
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
 			'SZ' => 'Svasiland',
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
 			'UK' => q{UK},
 			'US' => q{US},

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
			index => ['A', 'Á', 'B', 'C', 'D', 'Ð', 'E', 'F', 'G', 'H', 'I', 'Í', 'J', 'K', 'L', 'M', 'N', 'O', 'Ó', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ú', 'V', 'W', 'X', 'Y', 'Ý', 'Z', 'Æ', 'Ø'],
			main => qr{[a á b d ð e f g h i í j k l m n o ó p r s t u ú v y ý æ ø]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', 'D', 'Ð', 'E', 'F', 'G', 'H', 'I', 'Í', 'J', 'K', 'L', 'M', 'N', 'O', 'Ó', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ú', 'V', 'W', 'X', 'Y', 'Ý', 'Z', 'Æ', 'Ø'], };
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
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
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
	default		=> qq{“},
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
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
						'name' => q(ekrur),
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					'acre-foot' => {
						'name' => q(ekraføtur),
						'one' => q({0} ekrafótur),
						'other' => q({0} ekraføtur),
					},
					'ampere' => {
						'name' => q(amperur),
						'one' => q({0} ampera),
						'other' => q({0} amperur),
					},
					'arc-minute' => {
						'name' => q(bogaminuttir),
						'one' => q({0} bogaminuttur),
						'other' => q({0} bogaminuttir),
					},
					'arc-second' => {
						'name' => q(bogasekundir),
						'one' => q({0} bogasekund),
						'other' => q({0} bogasekundir),
					},
					'astronomical-unit' => {
						'name' => q(stjørnufrøðilig eindir),
						'one' => q({0} stjørnufrøðilig eind),
						'other' => q({0} stjørnufrøðiligar eindir),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(být),
						'one' => q({0} být),
						'other' => q({0} být),
					},
					'calorie' => {
						'name' => q(kaloriur),
						'one' => q({0} kaloria),
						'other' => q({0} kaloriur),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(stig Celsius),
						'one' => q({0} stig Celsius),
						'other' => q({0} stig Celsius),
					},
					'centiliter' => {
						'name' => q(sentilitrar),
						'one' => q({0} sentilitur),
						'other' => q({0} sentilitrar),
					},
					'centimeter' => {
						'name' => q(sentimetrar),
						'one' => q({0} sentimetur),
						'other' => q({0} sentimetrar),
						'per' => q({0} fyri hvønn sentimetur),
					},
					'century' => {
						'name' => q(øldir),
						'one' => q({0} øld),
						'other' => q({0} øldir),
					},
					'coordinate' => {
						'east' => q({0} eystur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
					},
					'cubic-centimeter' => {
						'name' => q(kubikksentimetrar),
						'one' => q({0} kubikksentimetur),
						'other' => q({0} kubikksentimetrar),
						'per' => q({0} fyri hvønn kubikksentimetur),
					},
					'cubic-foot' => {
						'name' => q(kubikkføtur),
						'one' => q({0} kubikkfótur),
						'other' => q({0} kubikkføtur),
					},
					'cubic-inch' => {
						'name' => q(kubikktummar),
						'one' => q({0} kubikktummi),
						'other' => q({0} kubikktummar),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkkilometrar),
						'one' => q({0} kubikkkilometur),
						'other' => q({0} kubikkkilometrar),
					},
					'cubic-meter' => {
						'name' => q(kubikkmetrar),
						'one' => q({0} kubikkmetur),
						'other' => q({0} kubikkmetrar),
						'per' => q({0} fyri hvønn kubikkmetur),
					},
					'cubic-mile' => {
						'name' => q(kubikkmíl),
						'one' => q({0} kubikkmíl),
						'other' => q({0} kubikkmíl),
					},
					'cubic-yard' => {
						'name' => q(kubikkyards),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyards),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} koppur),
						'other' => q({0} koppar),
					},
					'cup-metric' => {
						'name' => q(metralag koppar),
						'one' => q({0} metralag koppur),
						'other' => q({0} metralag koppar),
					},
					'day' => {
						'name' => q(dagar),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} um dagin),
					},
					'deciliter' => {
						'name' => q(desilitrar),
						'one' => q({0} desilitur),
						'other' => q({0} desilitrar),
					},
					'decimeter' => {
						'name' => q(desimetrar),
						'one' => q({0} desimetur),
						'other' => q({0} desimetrar),
					},
					'degree' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					'fahrenheit' => {
						'name' => q(stig Fahrenheit),
						'one' => q({0} stig Fahrenheit),
						'other' => q({0} stig Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(flótandi unsur),
						'one' => q({0} flótandi unsa),
						'other' => q({0} flótandi unsur),
					},
					'foodcalorie' => {
						'name' => q(kostkaloriur),
						'one' => q({0} kostkaloria),
						'other' => q({0} kostkaloriur),
					},
					'foot' => {
						'name' => q(føtur),
						'one' => q({0} fótur),
						'other' => q({0} føtur),
						'per' => q({0}/fót),
					},
					'g-force' => {
						'name' => q(G-kreftir),
						'one' => q({0} G-kraft),
						'other' => q({0} G-kreftir),
					},
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} fyri hvønn gallon),
					},
					'gallon-imperial' => {
						'name' => q(bretskar gallons),
						'one' => q({0} bretskur gallon),
						'other' => q({0} bretskar gallons),
						'per' => q({0} fyri hvønn bretska gallon),
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
						'name' => q(gigabýt),
						'one' => q({0} gigabýt),
						'other' => q({0} gigabýt),
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
						'per' => q({0} fyri hvørt gramm),
					},
					'hectare' => {
						'name' => q(hektarar),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					'hectoliter' => {
						'name' => q(hektolitrar),
						'one' => q({0} hektolitur),
						'other' => q({0} hektolitrar),
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
						'name' => q(hestakreftur),
						'one' => q({0} hestakraft),
						'other' => q({0} hestakreftur),
					},
					'hour' => {
						'name' => q(tímar),
						'one' => q({0} tími),
						'other' => q({0} tímar),
						'per' => q({0} um tíman),
					},
					'inch' => {
						'name' => q(tummar),
						'one' => q({0} tummi),
						'other' => q({0} tummar),
						'per' => q({0} fyri hvønn tumma),
					},
					'inch-hg' => {
						'name' => q(tummar av kviksilvur),
						'one' => q({0} tummi av kviksilvur),
						'other' => q({0} tummar av kviksilvur),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobýt),
						'one' => q({0} kilobýt),
						'other' => q({0} kilobýt),
					},
					'kilocalorie' => {
						'name' => q(kilokaloriur),
						'one' => q({0} kilokaloria),
						'other' => q({0} kilokaloriur),
					},
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0} fyri hvørt kilogramm),
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
						'name' => q(kilometrar),
						'one' => q({0} kilometur),
						'other' => q({0} kilometrar),
						'per' => q({0} fyri hvønn kilometur),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometrar um tíman),
						'one' => q({0} kilometur um tíman),
						'other' => q({0} kilometrar um tíman),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatttímar),
						'one' => q({0} kilowatttími),
						'other' => q({0} kilowatttímar),
					},
					'knot' => {
						'name' => q(sjómíl um tíman),
						'one' => q({0} sjómíl um tíman),
						'other' => q({0} sjómíl um tíman),
					},
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
					},
					'liter' => {
						'name' => q(litrar),
						'one' => q({0} litur),
						'other' => q({0} litrar),
						'per' => q({0} fyri hvønn litur),
					},
					'liter-per-100kilometers' => {
						'name' => q(litrar fyri hvørjar 100 kilometrar),
						'one' => q({0} litur fyri hvørjar 100 kilometrar),
						'other' => q({0} litrar fyri hvørjar 100 kilometrar),
					},
					'liter-per-kilometer' => {
						'name' => q(litrar fyri hvønn kilometrar),
						'one' => q({0} litur fyri hvønn kilometrar),
						'other' => q({0} litrar fyri hvønn kilometrar),
					},
					'lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luks),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabýt),
						'one' => q({0} megabýt),
						'other' => q({0} megabýt),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megalitrar),
						'one' => q({0} megalitur),
						'other' => q({0} megalitrar),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(metrar),
						'one' => q({0} metur),
						'other' => q({0} metrar),
						'per' => q({0} fyri hvønn metur),
					},
					'meter-per-second' => {
						'name' => q(metrar um sekundi),
						'one' => q({0} metur um sekundi),
						'other' => q({0} metrar um sekundi),
					},
					'meter-per-second-squared' => {
						'name' => q(metrar um sekundi²),
						'one' => q({0} metur um sekundi²),
						'other' => q({0} metrar um sekundi²),
					},
					'metric-ton' => {
						'name' => q(tons),
						'one' => q({0} tons),
						'other' => q({0} tons),
					},
					'microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					'micrometer' => {
						'name' => q(mikrometrar),
						'one' => q({0} mikrometur),
						'other' => q({0} mikrometrar),
					},
					'microsecond' => {
						'name' => q(mikrosekundir),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundir),
					},
					'mile' => {
						'name' => q(míl),
						'one' => q({0} míl),
						'other' => q({0} míl),
					},
					'mile-per-gallon' => {
						'name' => q(míl fyri hvønn gallon),
						'one' => q({0} míl fyri hvønn gallon),
						'other' => q({0} míl fyri hvønn gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(míl fyri hvønn bretska gallon),
						'one' => q({0} míl fyri hvønn bretska gallon),
						'other' => q({0} míl fyri hvønn bretska gallon),
					},
					'mile-per-hour' => {
						'name' => q(míl um tíman),
						'one' => q({0} míl/t),
						'other' => q({0} míl/t),
					},
					'mile-scandinavian' => {
						'name' => q(skandinaviskt míl),
						'one' => q({0} skandinaviskt míl),
						'other' => q({0} skandinaviskt míl),
					},
					'milliampere' => {
						'name' => q(milliamperur),
						'one' => q({0} milliampera),
						'other' => q({0} milliamperur),
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
						'name' => q(milligramm fyri hvønn desilitur),
						'one' => q({0} milligramm fyri hvønn desilitur),
						'other' => q({0} milligramm fyri hvønn desilitur),
					},
					'milliliter' => {
						'name' => q(millilitrar),
						'one' => q({0} millilitur),
						'other' => q({0} millilitrar),
					},
					'millimeter' => {
						'name' => q(millimetrar),
						'one' => q({0} millimetur),
						'other' => q({0} millimetrar),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimetrar av kviksilvur),
						'one' => q({0} millimetur av kviksilvur),
						'other' => q({0} millimetrar av kviksilvur),
					},
					'millimole-per-liter' => {
						'name' => q(millimol fyri hvønn litur),
						'one' => q({0} millimol fyri hvønn litur),
						'other' => q({0} millimol fyri hvønn litur),
					},
					'millisecond' => {
						'name' => q(millisekundir),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundir),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minuttir),
						'one' => q({0} minuttur),
						'other' => q({0} minuttir),
						'per' => q({0} um minuttin),
					},
					'month' => {
						'name' => q(mánaðir),
						'one' => q({0} mánaður),
						'other' => q({0} mánaðir),
						'per' => q({0} um mánan),
					},
					'nanometer' => {
						'name' => q(nanometrar),
						'one' => q({0} nanometur),
						'other' => q({0} nanometrar),
					},
					'nanosecond' => {
						'name' => q(nanosekundir),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundir),
					},
					'nautical-mile' => {
						'name' => q(sjómíl),
						'one' => q({0} sjómíl),
						'other' => q({0} sjómíl),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(unsur),
						'one' => q({0} unsa),
						'other' => q({0} unsur),
						'per' => q({0} fyri hvørja unsu),
					},
					'ounce-troy' => {
						'name' => q(troy unsur),
						'one' => q({0} troy unsa),
						'other' => q({0} troy unsur),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(partar fyri hvørja millión),
						'one' => q({0} partur fyri hvørja millión),
						'other' => q({0} partar fyri hvørja millión),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(picometrar),
						'one' => q({0} picometur),
						'other' => q({0} picometrar),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					'pint-metric' => {
						'name' => q(metralag pints),
						'one' => q({0} metralag pint),
						'other' => q({0} metralag pints),
					},
					'point' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} fyri hvørt pund),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianir),
					},
					'revolution' => {
						'name' => q(snúningar),
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					'second' => {
						'name' => q(sekundir),
						'one' => q({0} sekund),
						'other' => q({0} sekundir),
						'per' => q({0} um sekundi),
					},
					'square-centimeter' => {
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetur),
						'other' => q({0} fersentimetrar),
						'per' => q({0} fyri hvønn fersentimetur),
					},
					'square-foot' => {
						'name' => q(ferføtur),
						'one' => q({0} ferfót),
						'other' => q({0} ferføtur),
					},
					'square-inch' => {
						'name' => q(fertummar),
						'one' => q({0} fertummi),
						'other' => q({0} fertummar),
						'per' => q({0} fyri hvønn fertumma),
					},
					'square-kilometer' => {
						'name' => q(ferkilometrar),
						'one' => q({0} ferkilometur),
						'other' => q({0} ferkilometrar),
						'per' => q({0} fyri hvønn ferkilometur),
					},
					'square-meter' => {
						'name' => q(fermetrar),
						'one' => q({0} fermetur),
						'other' => q({0} fermetrar),
						'per' => q({0} fyri hvønn fermetur),
					},
					'square-mile' => {
						'name' => q(fermíl),
						'one' => q({0} fermíl),
						'other' => q({0} fermíl),
						'per' => q({0} fyri hvørt fermíl),
					},
					'square-yard' => {
						'name' => q(feryards),
						'one' => q({0} feryard),
						'other' => q({0} feryards),
					},
					'tablespoon' => {
						'name' => q(súpiskeiðir),
						'one' => q({0} súpiskeið),
						'other' => q({0} súpiskeiðir),
					},
					'teaspoon' => {
						'name' => q(teskeiðir),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðir),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabýt),
						'one' => q({0} terabýt),
						'other' => q({0} terabýt),
					},
					'ton' => {
						'name' => q(stutt tons),
						'one' => q({0} stutt tons),
						'other' => q({0} stutt tons),
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
						'name' => q(vikur),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} um vikuna),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0} um ári),
					},
				},
				'narrow' => {
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}d.),
						'per' => q({0}/d),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'hour' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
						'per' => q({0}/t.),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0}km/t),
						'other' => q({0}km/t),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					'minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					'nanosecond' => {
						'name' => q(ns),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0}/s),
					},
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(v.),
						'one' => q({0}v.),
						'other' => q({0}v.),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0}ár),
						'other' => q({0}ár),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(ekrur),
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					'acre-foot' => {
						'name' => q(ekraføtur),
						'one' => q({0} ekrafótur),
						'other' => q({0} ekraføtur),
					},
					'ampere' => {
						'name' => q(amperur),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(bogamin.),
						'one' => q({0} bogamin.),
						'other' => q({0} bogamin.),
					},
					'arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(být),
						'one' => q({0} být),
						'other' => q({0} být),
					},
					'calorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
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
						'name' => q(ø.),
						'one' => q({0} ø.),
						'other' => q({0} ø.),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(føtur³),
						'one' => q({0} fótur³),
						'other' => q({0} føtur³),
					},
					'cubic-inch' => {
						'name' => q(tum.³),
						'one' => q({0} tum.³),
						'other' => q({0} tum.³),
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
						'name' => q(míl³),
						'one' => q({0} míl³),
						'other' => q({0} míl³),
					},
					'cubic-yard' => {
						'name' => q(yards³),
						'one' => q({0} yard³),
						'other' => q({0} yards³),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} koppur),
						'other' => q({0} koppar),
					},
					'cup-metric' => {
						'name' => q(metralag koppar),
						'one' => q({0} metralag koppur),
						'other' => q({0} metralag koppar),
					},
					'day' => {
						'name' => q(dagar),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
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
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(flótandi unsur),
						'one' => q({0} flótandi unsa),
						'other' => q({0} flótandi unsur),
					},
					'foodcalorie' => {
						'name' => q(kostkaloriur),
						'one' => q({0} kostkaloria),
						'other' => q({0} kostkaloriur),
					},
					'foot' => {
						'name' => q(føtur),
						'one' => q({0} fótur),
						'other' => q({0} føtur),
						'per' => q({0}/fót),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0}/gallon),
					},
					'gallon-imperial' => {
						'name' => q(UK gallons),
						'one' => q({0} UK gallon),
						'other' => q({0} UK gallons),
						'per' => q({0}/UK gallon),
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
						'name' => q(gigawatt),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(gramm),
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
						'name' => q(hestakreftur),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					'hour' => {
						'name' => q(tímar),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					'inch' => {
						'name' => q(tum.),
						'one' => q({0} tum.),
						'other' => q({0} tum.),
						'per' => q({0}/tum.),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
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
						'name' => q(KB),
						'one' => q({0} KB),
						'other' => q({0} KB),
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
						'name' => q(kilojoule),
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
						'name' => q(km/t),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
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
						'name' => q(smíl/t),
						'one' => q({0} smíl/t),
						'other' => q({0} smíl/t),
					},
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
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
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(luks),
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
						'name' => q(mikrosek.),
						'one' => q({0} μs.),
						'other' => q({0} μs.),
					},
					'mile' => {
						'name' => q(míl),
						'one' => q({0} míl),
						'other' => q({0} míl),
					},
					'mile-per-gallon' => {
						'name' => q(míl/gallon),
						'one' => q({0} míl/gallon),
						'other' => q({0} míl/gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(míl/UK gallon),
						'one' => q({0} míl/UK gallon),
						'other' => q({0} míl/UK gallon),
					},
					'mile-per-hour' => {
						'name' => q(míl/t),
						'one' => q({0} míl/t),
						'other' => q({0} míl/t),
					},
					'mile-scandinavian' => {
						'name' => q(sk. míl),
						'one' => q({0} sk. míl),
						'other' => q({0} sk. míl),
					},
					'milliampere' => {
						'name' => q(milliamperur),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mb),
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
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'name' => q(mán.),
						'one' => q({0} mán.),
						'other' => q({0} mán.),
						'per' => q({0}/m.),
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
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(unsur),
						'one' => q({0} unsa),
						'other' => q({0} unsur),
						'per' => q({0}/unsu),
					},
					'ounce-troy' => {
						'name' => q(troy unsur),
						'one' => q({0} troy unsa),
						'other' => q({0} troy unsur),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(partar/millión),
						'one' => q({0} partur/mill.),
						'other' => q({0} partar/mill.),
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
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					'pint-metric' => {
						'name' => q(metralag pints),
						'one' => q({0} metralag pint),
						'other' => q({0} metralag pints),
					},
					'point' => {
						'name' => q(pkt),
						'one' => q({0} pkt),
						'other' => q({0} pkt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(snúningar),
						'one' => q({0} snú.),
						'other' => q({0} snú.),
					},
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(føtur²),
						'one' => q({0} fót²),
						'other' => q({0} føtur²),
					},
					'square-inch' => {
						'name' => q(tum.²),
						'one' => q({0} tum.²),
						'other' => q({0} tum.²),
						'per' => q({0}/tum.²),
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
						'name' => q(míl²),
						'one' => q({0} míl²),
						'other' => q({0} míl²),
						'per' => q({0}/míl²),
					},
					'square-yard' => {
						'name' => q(yards²),
						'one' => q({0} yard²),
						'other' => q({0} yards²),
					},
					'tablespoon' => {
						'name' => q(súpisk.),
						'one' => q({0} súpisk.),
						'other' => q({0} súpisk.),
					},
					'teaspoon' => {
						'name' => q(tesk.),
						'one' => q({0} tesk.),
						'other' => q({0} tesk.),
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
						'name' => q(stutt t),
						'one' => q({0} stutt t),
						'other' => q({0} stutt t),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(vikur),
						'one' => q({0} vi.),
						'other' => q({0} vi.),
						'per' => q({0}/vi.),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ár),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
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
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Sameindu Emirríkini dirham),
				'one' => q(Sameindu Emirríkini dirham),
				'other' => q(Sameindu Emirríkini dirham),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afganistan afghani),
				'one' => q(Afganistan afghani),
				'other' => q(Afganistan afghani),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albania lek),
				'one' => q(Albania lek),
				'other' => q(Albania lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armenia dram),
				'one' => q(Armenia dram),
				'other' => q(Armenia dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Niðurlonds Karibia gyllin),
				'one' => q(Niðurlonds Karibia gyllin),
				'other' => q(Niðurlonds Karibia gyllin),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angola kwanza),
				'one' => q(Angola kwanza),
				'other' => q(Angola kwanza),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentina peso),
				'one' => q(Argentina peso),
				'other' => q(Argentina peso),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Avstralskur dollari),
				'one' => q(Avstralskur dollari),
				'other' => q(Avstralskir dollarar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruba florin),
				'one' => q(Aruba florin),
				'other' => q(Aruba florin),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Aserbadjan manat),
				'one' => q(Aserbadjan manat),
				'other' => q(Aserbadjan manat),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosnia-Hersegovina mark \(kann vekslast\)),
				'one' => q(Bosnia-Hersegovina mark \(kann vekslast\)),
				'other' => q(Bosnia-Hersegovina mark \(kann vekslast\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados dollari),
				'one' => q(Barbados dollari),
				'other' => q(Barbados dollarar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladesj taka),
				'one' => q(Bangladesj taka),
				'other' => q(Bangladesj taka),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bulgaria lev),
				'one' => q(Bulgaria lev),
				'other' => q(Bulgaria lev),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Barein dinar),
				'one' => q(Barein dinar),
				'other' => q(Barein dinar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi frankur),
				'one' => q(Burundi frankur),
				'other' => q(Burundi frankar),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda dollari),
				'one' => q(Bermuda dollari),
				'other' => q(Bermuda dollarar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunei dollari),
				'one' => q(Brunei dollari),
				'other' => q(Brunei dollarar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolivia boliviano),
				'one' => q(Bolivia boliviano),
				'other' => q(Bolivia boliviano),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brasilianskur real),
				'one' => q(Brasilianskur real),
				'other' => q(Brasilianskir real),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamaoyggjar dollari),
				'one' => q(Bahamaoyggjar dollari),
				'other' => q(Bahamaoyggjar dollarar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butan ngultrum),
				'one' => q(Butan ngultrum),
				'other' => q(Butan ngultrum),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botsvana pula),
				'one' => q(Botsvana pula),
				'other' => q(Botsvana pula),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Hvítarussland ruble),
				'one' => q(Hvítarussland ruble),
				'other' => q(Hvítarussland ruble),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Hvítarussland ruble \(2000–2016\)),
				'one' => q(Hvítarussland ruble \(2000–2016\)),
				'other' => q(Hvítarussland ruble \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belis dollari),
				'one' => q(Belis dollari),
				'other' => q(Belis dollarar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada dollari),
				'one' => q(Kanada dollari),
				'other' => q(Kanada dollarar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongo frankur),
				'one' => q(Kongo frankur),
				'other' => q(Kongo frankar),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(sveisiskur frankur),
				'one' => q(sveisiskur frankur),
				'other' => q(sveisiskir frankar),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Kili peso),
				'one' => q(Kili peso),
				'other' => q(Kili peso),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(kinesiskur yuan \(úr landi\)),
				'one' => q(kinesiskur yuan \(úr landi\)),
				'other' => q(kinesiskur yuan \(úr landi\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(kinesiskur yuan),
				'one' => q(kinesiskur yuan),
				'other' => q(kinesiskir yuan),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolombia peso),
				'one' => q(Kolombia peso),
				'other' => q(Kolombia peso),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kosta Rika colón),
				'one' => q(Kosta Rika colón),
				'other' => q(Kosta Rika colón),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuba peso \(sum kann vekslast\)),
				'one' => q(Kuba peso \(sum kann vekslast\)),
				'other' => q(Kuba peso \(sum kann vekslast\)),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuba peso),
				'one' => q(Kuba peso),
				'other' => q(Kuba peso),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Grønhøvdaoyggjar escudo),
				'one' => q(Grønhøvdaoyggjar escudo),
				'other' => q(Grønhøvdaoyggjar escudo),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Kekkia koruna),
				'one' => q(Kekkia koruna),
				'other' => q(Kekkia koruna),
			},
		},
		'DJF' => {
			symbol => 'DJF',
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
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominika peso),
				'one' => q(Dominika peso),
				'other' => q(Dominika peso),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Algeria dinar),
				'one' => q(Algeria dinar),
				'other' => q(Algeria dinar),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egyptaland pund),
				'one' => q(Egyptaland pund),
				'other' => q(Egyptaland pund),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritrea nakfa),
				'one' => q(Eritrea nakfa),
				'other' => q(Eritrea nakfa),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Etiopia birr),
				'one' => q(Etiopia birr),
				'other' => q(Etiopia birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Evra),
				'one' => q(evra),
				'other' => q(evrur),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fiji dollari),
				'one' => q(Fiji dollari),
				'other' => q(Fiji dollarar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falklandsoyggjar pund),
				'one' => q(Falklandsoyggjar pund),
				'other' => q(Falklandsoyggjar pund),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(bretsk pund),
				'one' => q(bretsk pund),
				'other' => q(bretsk pund),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Georgia lari),
				'one' => q(Georgia lari),
				'other' => q(Georgia lari),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Gana cedi),
				'one' => q(Gana cedi),
				'other' => q(Gana cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltar pund),
				'one' => q(Gibraltar pund),
				'other' => q(Gibraltar pund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambia dalasi),
				'one' => q(Gambia dalasi),
				'other' => q(Gambia dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Guinea frankur),
				'one' => q(Guinea frankur),
				'other' => q(Guinea frankar),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guatemala quetzal),
				'one' => q(Guatemala quetzal),
				'other' => q(Guatemala quetzal),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Gujana dollari),
				'one' => q(Gujana dollari),
				'other' => q(Gujana dollarar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hong Kong dollari),
				'one' => q(Hong Kong dollari),
				'other' => q(Hong Kong dollarar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Honduras lempira),
				'one' => q(Honduras lempira),
				'other' => q(Honduras lempira),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroatia kuna),
				'one' => q(Kroatia kuna),
				'other' => q(Kroatia kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haiti gourde),
				'one' => q(Haiti gourde),
				'other' => q(Haiti gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Ungarn forint),
				'one' => q(Ungarn forint),
				'other' => q(Ungarn forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesia rupiah),
				'one' => q(Indonesia rupiah),
				'other' => q(Indonesia rupiah),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Ísrael new shekel),
				'one' => q(Ísrael new shekel),
				'other' => q(Ísrael new shekel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(indiskir rupis),
				'one' => q(indiskur rupi),
				'other' => q(indiskir rupis),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Irak dinar),
				'one' => q(Irak dinar),
				'other' => q(Irak dinar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iranskir rials),
				'one' => q(iranskur rial),
				'other' => q(iranskir rials),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(íslendsk króna),
				'one' => q(íslendsk króna),
				'other' => q(íslendskar krónur),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaika dollari),
				'one' => q(Jamaika dollari),
				'other' => q(Jamaika dollarar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jordan dinar),
				'one' => q(Jordan dinar),
				'other' => q(Jordan dinar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(japanskur yen),
				'one' => q(japanskur yen),
				'other' => q(japanskir yen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(kenjanskur skillingur),
				'one' => q(kenjanskur skillingur),
				'other' => q(kenjanskir skillingar),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgisia som),
				'one' => q(Kirgisia som),
				'other' => q(Kirgisia som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodja riel),
				'one' => q(Kambodja riel),
				'other' => q(Kambodja riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komoroyggjar frankur),
				'one' => q(Komoroyggjar frankur),
				'other' => q(Komoroyggjar frankar),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Norðurkorea won),
				'one' => q(Norðurkorea won),
				'other' => q(Norðurkorea won),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Suðurkorea won),
				'one' => q(Suðurkorea won),
				'other' => q(Suðurkorea won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuvait dinar),
				'one' => q(Kuvait dinar),
				'other' => q(Kuvait dinar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Caymanoyggjar dollari),
				'one' => q(Caymanoyggjar dollari),
				'other' => q(Caymanoyggjar dollarar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kasakstan tenge),
				'one' => q(Kasakstan tenge),
				'other' => q(Kasakstan tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laos kip),
				'one' => q(Laos kip),
				'other' => q(Laos kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libanon pund),
				'one' => q(Libanon pund),
				'other' => q(Libanon pund),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lanka rupi),
				'one' => q(Sri Lanka rupi),
				'other' => q(Sri Lanka rupis),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberia dollari),
				'one' => q(Liberia dollari),
				'other' => q(Liberia dollarar),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Libya dinar),
				'one' => q(Libya dinar),
				'other' => q(Libya dinar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokko dirham),
				'one' => q(Marokko dirham),
				'other' => q(Marokko dirham),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldova leu),
				'one' => q(Moldova leu),
				'other' => q(Moldova leu),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Madagaskar ariary),
				'one' => q(Madagaskar ariary),
				'other' => q(Madagaskar ariary),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Makedónia denar),
				'one' => q(Makedónia denar),
				'other' => q(Makedónia denar),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmar \(Burma\) kyat),
				'one' => q(Myanmar \(Burma\) kyat),
				'other' => q(Myanmar \(Burma\) kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongolia tugrik),
				'one' => q(Mongolia tugrik),
				'other' => q(Mongolia tugrik),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makao pataca),
				'one' => q(Makao pataca),
				'other' => q(Makao pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Móritania ouguiya \(1973–2017\)),
				'one' => q(Móritania ouguiya \(1973–2017\)),
				'other' => q(Móritania ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Móritania ouguiya),
				'one' => q(Móritania ouguiya),
				'other' => q(Móritania ouguiya),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Móritius rupi),
				'one' => q(Móritius rupi),
				'other' => q(Móritius rupi),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldivoyggjar rufiyaa),
				'one' => q(Maldivoyggjar rufiyaa),
				'other' => q(Maldivoyggjar rufiyaa),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malavi kwacha),
				'one' => q(Malavi kwacha),
				'other' => q(Malavi kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Meksiko peso),
				'one' => q(Meksiko peso),
				'other' => q(Meksiko peso),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malaisia ringgit),
				'one' => q(Malaisia ringgit),
				'other' => q(Malaisia ringgit),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mosambik metical),
				'one' => q(Mosambik metical),
				'other' => q(Mosambik metical),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibia dollari),
				'one' => q(Namibia dollari),
				'other' => q(Namibia dollarar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeria naira),
				'one' => q(Nigeria naira),
				'other' => q(Nigeria naira),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaragua córdoba),
				'one' => q(Nikaragua córdoba),
				'other' => q(Nikaragua córdoba),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(norsk króna),
				'one' => q(norsk króna),
				'other' => q(norskar krónur),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepal rupi),
				'one' => q(Nepal rupi),
				'other' => q(Nepal rupis),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Nýsæland dollari),
				'one' => q(Nýsæland dollari),
				'other' => q(Nýsæland dollarar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Oman rial),
				'one' => q(Oman rial),
				'other' => q(Oman rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panama balboa),
				'one' => q(Panama balboa),
				'other' => q(Panama balboa),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peru sol),
				'one' => q(Peru sol),
				'other' => q(Peru sol),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papua Nýguinea kina),
				'one' => q(Papua Nýguinea kina),
				'other' => q(Papua Nýguinea kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipsoyggjar peso),
				'one' => q(Filipsoyggjar peso),
				'other' => q(Filipsoyggjar peso),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistan rupi),
				'one' => q(Pakistan rupi),
				'other' => q(Pakistan rupis),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Pólland zloty),
				'one' => q(Pólland zloty),
				'other' => q(Pólland zloty),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguai guarani),
				'one' => q(Paraguai guarani),
				'other' => q(Paraguai guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katar rial),
				'one' => q(Katar rial),
				'other' => q(Katar rial),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumenia leu),
				'one' => q(Rumenia leu),
				'other' => q(Rumenia lei),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbia dinar),
				'one' => q(Serbia dinar),
				'other' => q(Serbia dinar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Russland ruble),
				'one' => q(Russland ruble),
				'other' => q(Russland ruble),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruanda frankur),
				'one' => q(Ruanda frankur),
				'other' => q(Ruanda frankar),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudiarabia riyal),
				'one' => q(Saudiarabia riyal),
				'other' => q(Saudiarabia riyal),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Salomonoyggjar dollari),
				'one' => q(Salomonoyggjar dollari),
				'other' => q(Salomonoyggjar dollarar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seyskelloyggjar rupi),
				'one' => q(Seyskelloyggjar rupi),
				'other' => q(Seyskelloyggjar rupi),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudan pund),
				'one' => q(Sudan pund),
				'other' => q(Sudan pund),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(svensk króna),
				'one' => q(svensk króna),
				'other' => q(svenskar krónur),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapor dollari),
				'one' => q(Singapor dollari),
				'other' => q(Singapor dollarar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(St. Helena pund),
				'one' => q(St. Helena pund),
				'other' => q(St. Helena pund),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra Leona leone),
				'one' => q(Sierra Leona leone),
				'other' => q(Sierra Leona leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somalia skillingur),
				'one' => q(Somalia skillingur),
				'other' => q(Somalia skillingar),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinam dollari),
				'one' => q(Surinam dollari),
				'other' => q(Surinam dollarar),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Suðursudan pund),
				'one' => q(Suðursudan pund),
				'other' => q(Suðursudan pund),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Sao Tome & Prinsipi dobra \(1977–2017\)),
				'one' => q(Sao Tome & Prinsipi dobra \(1977–2017\)),
				'other' => q(Sao Tome & Prinsipi dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Sao Tome & Prinsipi dobra),
				'one' => q(Sao Tome & Prinsipi dobra),
				'other' => q(Sao Tome & Prinsipi dobra),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Sýria pund),
				'one' => q(Sýria pund),
				'other' => q(Sýria pund),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Svasiland lilangeni),
				'one' => q(Svasiland lilangeni),
				'other' => q(Svasiland lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Tailand baht),
				'one' => q(Tailand baht),
				'other' => q(Tailand baht),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tadsjikistan somoni),
				'one' => q(Tadsjikistan somoni),
				'other' => q(Tadsjikistan somoni),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmenistan manat),
				'one' => q(Turkmenistan manat),
				'other' => q(Turkmenistan manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunesia dinar),
				'one' => q(Tunesia dinar),
				'other' => q(Tunesia dinar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tonga paʻanga),
				'one' => q(Tonga paʻanga),
				'other' => q(Tonga paʻanga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkaland liri),
				'one' => q(Turkaland liri),
				'other' => q(Turkaland lirir),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad & Tobago dollari),
				'one' => q(Trinidad & Tobago dollari),
				'other' => q(Trinidad & Tobago dollarar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Taivan new dollari),
				'one' => q(Taivan new dollari),
				'other' => q(Taivan new dollarar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tansania skillingur),
				'one' => q(Tansania skillingur),
				'other' => q(Tansania skillingar),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukraina hryvnia),
				'one' => q(Ukraina hryvnia),
				'other' => q(Ukraina hryvnia),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Uganda skillingur),
				'one' => q(Uganda skillingur),
				'other' => q(Uganda skillingar),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(US dollari),
				'one' => q(US dollari),
				'other' => q(US dollarar),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguai peso),
				'one' => q(Uruguai peso),
				'other' => q(Uruguai peso),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Usbekistan som),
				'one' => q(Usbekistan som),
				'other' => q(Usbekistan som),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venesuela bolívar \(2008–2018\)),
				'one' => q(Venesuela bolívar \(2008–2018\)),
				'other' => q(Venesuela bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venesuela bolívar),
				'one' => q(Venesuela bolívar),
				'other' => q(Venesuela bolívar),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vjetnam dong),
				'one' => q(Vjetnam dong),
				'other' => q(Vjetnam dong),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatu vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoa tala),
				'one' => q(Samoa tala),
				'other' => q(Samoa tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Miðafrika CFA frankur),
				'one' => q(Miðafrika CFA frankur),
				'other' => q(Miðafrika CFA frankar),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(unse sølv),
				'one' => q(unse sølv),
				'other' => q(unse sølv),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(unse guld),
				'one' => q(unse guld),
				'other' => q(unse guld),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Eystur Karibia dollari),
				'one' => q(Eystur Karibia dollari),
				'other' => q(Eystur Karibia dollarar),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Vesturafrika CFA frankur),
				'one' => q(Vesturafrika CFA frankur),
				'other' => q(Vesturafrika CFA frankar),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(unse palladium),
				'one' => q(unse palladium),
				'other' => q(unse palladium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP frankur),
				'one' => q(CFP frankur),
				'other' => q(CFP frankar),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(unse platin),
				'one' => q(unse platin),
				'other' => q(unse platin),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ókent gjaldoyra),
				'one' => q(\(ókent gjaldoyra\)),
				'other' => q(\(ókent gjaldoyra\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemen rial),
				'one' => q(Jemen rial),
				'other' => q(Jemen rial),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Suðurafrika rand),
				'one' => q(Suðurafrika rand),
				'other' => q(Suðurafrika rand),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Sambia kwacha),
				'one' => q(Sambia kwacha),
				'other' => q(Sambia kwacha),
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. ársfjórðingur',
						1 => '2. ársfjórðingur',
						2 => '3. ársfjórðingur',
						3 => '4. ársfjórðingur'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1. ársfj.',
						1 => '2. ársfj.',
						2 => '3. ársfj.',
						3 => '4. ársfj.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
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
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E dd.MM},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{LL},
			MEd => q{E dd.MM},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMW => q{W. 'vika' 'í' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
		'generic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
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
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
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
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
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
			fallback => '{0} – {1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} tíð),
		regionFormat => q({0} summartíð),
		regionFormat => q({0} vanlig tíð),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan tíð#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
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
			exemplarCity => q#Cairo#,
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
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
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
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Malabo#,
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
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
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
			exemplarCity => q#Tucuman#,
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
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belis#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
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
			exemplarCity => q#Cancun#,
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
			exemplarCity => q#Cayman#,
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
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
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
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
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
			exemplarCity => q#Havana#,
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
			exemplarCity => q#Jamaika#,
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
			exemplarCity => q#Maceio#,
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
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico City#,
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
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
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
			exemplarCity => q#Puerto Riko#,
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
			exemplarCity => q#Rio Branco#,
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
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
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
			exemplarCity => q#Vostok#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barein#,
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
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
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
			exemplarCity => q#Gasa#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
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
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
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
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapor#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
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
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Grønhøvdaoyggjar#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Føroyar#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Suðurgeorgiaoyggjar#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
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
			exemplarCity => q#ókendur býur#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Keypmannahavn#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Írsk vanlig tíð#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Stóra Bretland summartíð#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemborg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkhólm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanið#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsjava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivoyggjar#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Móritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'standard' => q#Norfolksoyggj tíð#,
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
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
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
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
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
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
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
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
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
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
