=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Af - Package for language Afrikaans

=cut

package Locale::CLDR::Locales::Af;
# This file auto generated from Data\common\main\af.xml
#	on Fri 13 Oct  9:04:29 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bigfloat;
		return {
		'2d-year' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(honderd[ →%spellout-numbering→]),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(nul =%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
			},
		},
		'digits-ordinal-indicator' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ste),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ste),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(ste),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
			},
		},
		'ord-ste' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ste),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' en =%spellout-ordinal=),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(min →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nul),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(een),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(twee),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drie),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(vier),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(vyf),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ses),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sewe),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(agt),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nege),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tien),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elf),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(twaalf),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(dertien),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(veertien),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(vyftien),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sestien),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sewentien),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(agttien),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(negentien),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→→-en-]twintig),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→→-en-]dertig),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→→-en-]veertig),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→→-en-]vyftig),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→→-en-]sestig),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→→-en-]sewentig),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→→-en-]tagtig),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→→-en-]negentig),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(honderd[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←honderd[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(duisend[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­duisend[ →→]),
				},
				'21000' => {
					base_value => q(21000),
					divisor => q(1000),
					rule => q(←← duisend[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljard[ →→]),
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
					rule => q(min →→),
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
					rule => q(←← →%%2d-year→),
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
					rule => q(min →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulste),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eerste),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tweede),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(derde),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%spellout-numbering=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-numbering=ste),
				},
				'102' => {
					base_value => q(102),
					divisor => q(100),
					rule => q(←%spellout-numbering← honderd→%%ord-ste→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← duisend→%%ord-ste→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering← miljoen→%%ord-ste→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering← miljard→%%ord-ste→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering← biljoen→%%ord-ste→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering← biljard→%%ord-ste→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
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
				'aa' => 'Afar',
 				'ab' => 'Abkasies',
 				'ace' => 'Atsjenees',
 				'ach' => 'Akoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Suid-Altai',
 				'am' => 'Amharies',
 				'an' => 'Aragonees',
 				'anp' => 'Angika',
 				'ar' => 'Arabies',
 				'ar_001' => 'Moderne Standaardarabies',
 				'arc' => 'Aramees',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'as' => 'Assamees',
 				'asa' => 'Asu',
 				'ast' => 'Asturies',
 				'av' => 'Avaries',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbeidjans',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Baskir',
 				'ban' => 'Balinees',
 				'bas' => 'Basaa',
 				'be' => 'Belarussies',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgaars',
 				'bgn' => 'Wes-Balochi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengaals',
 				'bo' => 'Tibettaans',
 				'br' => 'Bretons',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnies',
 				'bug' => 'Buginees',
 				'byn' => 'Blin',
 				'ca' => 'Katalaans',
 				'ce' => 'Tsjetsjeens',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Kiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chuukees',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chr' => 'Cherokees',
 				'chy' => 'Cheyennees',
 				'ckb' => 'Sorani',
 				'co' => 'Korsikaans',
 				'cop' => 'Kopties',
 				'crs' => 'Seselwa Franskreools',
 				'cs' => 'Tsjeggies',
 				'cu' => 'Kerkslawies',
 				'cv' => 'Chuvash',
 				'cy' => 'Wallies',
 				'da' => 'Deens',
 				'dak' => 'Dakotaans',
 				'dar' => 'Dakota',
 				'dav' => 'Taita',
 				'de' => 'Duits',
 				'de_CH' => 'Switserse hoog-Duits',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'dsb' => 'Benedesorbies',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Antieke Egipties',
 				'eka' => 'Ekajuk',
 				'el' => 'Grieks',
 				'en' => 'Engels',
 				'en_GB' => 'Engels (VK)',
 				'en_GB@alt=short' => 'Engels (VK)',
 				'en_US' => 'Engels (VSA)',
 				'en_US@alt=short' => 'Engels (VSA)',
 				'eo' => 'Esperanto',
 				'es' => 'Spaans',
 				'et' => 'Estnies',
 				'eu' => 'Baskies',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persies',
 				'ff' => 'Fulah',
 				'fi' => 'Fins',
 				'fil' => 'Filippyns',
 				'fj' => 'Fidjiaans',
 				'fo' => 'Faroëes',
 				'fon' => 'Fon',
 				'fr' => 'Frans',
 				'fur' => 'Friuliaans',
 				'fy' => 'Fries',
 				'ga' => 'Iers',
 				'gaa' => 'Gaa',
 				'gag' => 'Gagauz',
 				'gan' => 'Gan-Sjinees',
 				'gd' => 'Skotse Gallies',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertees',
 				'gl' => 'Galisies',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'got' => 'Goties',
 				'grc' => 'Antieke Grieks',
 				'gsw' => 'Switserse Duits',
 				'gu' => 'Goedjarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hak' => 'Hakka-Sjinees',
 				'haw' => 'Hawais',
 				'he' => 'Hebreeus',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hetities',
 				'hmn' => 'Hmong',
 				'hr' => 'Kroaties',
 				'hsb' => 'Oppersorbies',
 				'hsn' => 'Xiang-Sjinees',
 				'ht' => 'Haïtiaans',
 				'hu' => 'Hongaars',
 				'hup' => 'Hupa',
 				'hy' => 'Armeens',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Ibanees',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesies',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Yslands',
 				'it' => 'Italiaans',
 				'iu' => 'Inuïties',
 				'ja' => 'Japannees',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Javaans',
 				'ka' => 'Georgies',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardiaans',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'kfo' => 'Koro',
 				'kg' => 'Kongolees',
 				'kha' => 'Khasi',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazaks',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaans',
 				'koi' => 'Komi-Permyaks',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpellees',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelies',
 				'kru' => 'Kurukh',
 				'ks' => 'Kasjmirs',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Keuls',
 				'ku' => 'Koerdies',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Kornies',
 				'ky' => 'Kirgisies',
 				'la' => 'Latyn',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lb' => 'Luxemburgs',
 				'lez' => 'Lezghies',
 				'lg' => 'Ganda',
 				'li' => 'Limburgs',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingaals',
 				'lo' => 'Lao',
 				'loz' => 'Lozi',
 				'lrc' => 'Noord-Luri',
 				'lt' => 'Litaus',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Letties',
 				'mad' => 'Madurees',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisjen',
 				'mg' => 'Malgassies',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallees',
 				'mi' => 'Maori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabaus',
 				'mk' => 'Masedonies',
 				'ml' => 'Malabaars',
 				'mn' => 'Mongools',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Maleis',
 				'mt' => 'Maltees',
 				'mua' => 'Mundang',
 				'mul' => 'Verskeie tale',
 				'mus' => 'Kreek',
 				'mwl' => 'Mirandees',
 				'my' => 'Birmaans',
 				'myv' => 'Erzya',
 				'mzn' => 'Masanderani',
 				'na' => 'Nauru',
 				'nan' => 'Min Nan-Sjinees',
 				'nap' => 'Neapolitaans',
 				'naq' => 'Nama',
 				'nb' => 'Boeknoors',
 				'nd' => 'Noord-Ndebele',
 				'nds' => 'Lae Duits',
 				'nds_NL' => 'Nedersaksies',
 				'ne' => 'Nepalees',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niueaans',
 				'nl' => 'Nederlands',
 				'nl_BE' => 'Vlaams',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nuwe Noors',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Noors',
 				'nog' => 'Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'Suid-Ndebele',
 				'nso' => 'Noord-Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Oksitaans',
 				'om' => 'Oromo',
 				'or' => 'Oriya',
 				'os' => 'Osseties',
 				'pa' => 'Pandjabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauaans',
 				'pcm' => 'Nigeriese Pidgin',
 				'phn' => 'Fenisies',
 				'pl' => 'Pools',
 				'prg' => 'Pruisies',
 				'ps' => 'Pasjto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portugees',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongaans',
 				'rm' => 'Reto-Romaans',
 				'rn' => 'Rundi',
 				'ro' => 'Roemeens',
 				'rof' => 'Rombo',
 				'root' => 'Root',
 				'ru' => 'Russies',
 				'rup' => 'Aromanies',
 				'rw' => 'Rwandees',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawees',
 				'sah' => 'Sakhaans',
 				'saq' => 'Samburu',
 				'sat' => 'Santalies',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinies',
 				'scn' => 'Sisiliaans',
 				'sco' => 'Skots',
 				'sd' => 'Sindhi',
 				'sdh' => 'Suid-Koerdies',
 				'se' => 'Noord-Sami',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sh' => 'Serwo-Kroaties',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sk' => 'Slowaaks',
 				'sl' => 'Sloweens',
 				'sm' => 'Samoaans',
 				'sma' => 'Suid-Sami',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalies',
 				'sq' => 'Albanees',
 				'sr' => 'Serwies',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swazi',
 				'ssy' => 'Saho',
 				'st' => 'Suid-Sotho',
 				'su' => 'Sundanees',
 				'suk' => 'Sukuma',
 				'sv' => 'Sweeds',
 				'sw' => 'Swahili',
 				'swb' => 'Comoraans',
 				'syr' => 'Siries',
 				'ta' => 'Tamil',
 				'te' => 'Teloegoe',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetoem',
 				'tg' => 'Tadjiks',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmeens',
 				'tlh' => 'Klingon',
 				'tn' => 'Tswana',
 				'to' => 'Tongaans',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turks',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tataars',
 				'tum' => 'Toemboeka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahities',
 				'tyv' => 'Tuvinees',
 				'tzm' => 'Sentraal-Atlas-Tamazight',
 				'udm' => 'Udmurt',
 				'ug' => 'Uighur',
 				'uk' => 'Oekraïens',
 				'umb' => 'Umbundu',
 				'und' => 'Onbekende of ongeldige taal',
 				'ur' => 'Oerdoe',
 				'uz' => 'Oezbeeks',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Viëtnamees',
 				'vo' => 'Volapük',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu-Sjinees',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddisj',
 				'yo' => 'Yoruba',
 				'yue' => 'Kantonees',
 				'zgh' => 'Standaard Marokkaanse Tamazight',
 				'zh' => 'Sjinees',
 				'zh_Hans' => 'Chinees (Vereenvoudig)',
 				'zh_Hant' => 'Chinees (Tradisioneel)',
 				'zu' => 'Zoeloe',
 				'zun' => 'Zuni',
 				'zxx' => 'Geen taalinhoud nie',
 				'zza' => 'Zaza',

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
			'Arab' => 'Arabies',
 			'Arab@alt=variant' => 'Perso-Arabies',
 			'Armn' => 'Armeens',
 			'Beng' => 'Bengaals',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Copt' => 'Koptieses',
 			'Cyrl' => 'Sirillies',
 			'Cyrs' => 'Ou Kerkslawiese Sirillieses',
 			'Deva' => 'Devanagari',
 			'Egyp' => 'Egiptieses hiërogliewe',
 			'Ethi' => 'Etiopies',
 			'Geor' => 'Georgies',
 			'Goth' => 'Gotieses',
 			'Grek' => 'Grieks',
 			'Gujr' => 'Gudjarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Hanb',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Vereenvoudig',
 			'Hans@alt=stand-alone' => 'Vereenvoudigde Han',
 			'Hant' => 'Tradisioneel',
 			'Hant@alt=stand-alone' => 'Tradisionele Han',
 			'Hebr' => 'Hebreeus',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Japannese lettergreepskrif',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japannees',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreaans',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latyn',
 			'Mlym' => 'Malabaars',
 			'Mong' => 'Mongools',
 			'Mymr' => 'Mianmar',
 			'Orya' => 'Oriya',
 			'Phnx' => 'Fenisieses',
 			'Sinh' => 'Sinhala',
 			'Taml' => 'Tamil',
 			'Telu' => 'Teloegoe',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibettaans',
 			'Ugar' => 'Ugaritieses',
 			'Visp' => 'Visible Speech-karakters',
 			'Zmth' => 'Wiskundige notasie',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbole',
 			'Zxxx' => 'Ongeskrewe',
 			'Zyyy' => 'Algemeen',
 			'Zzzz' => 'Onbekende skryfstelsel',

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
			'001' => 'Wêreld',
 			'002' => 'Afrika',
 			'003' => 'Noord-Amerika',
 			'005' => 'Suid-Amerika',
 			'009' => 'Oseanië',
 			'011' => 'Wes-Afrika',
 			'013' => 'Sentraal-Amerika',
 			'014' => 'Oos-Afrika',
 			'015' => 'Noord-Afrika',
 			'017' => 'Midde-Afrika',
 			'018' => 'Suider-Afrika',
 			'019' => 'Amerikas',
 			'021' => 'Noordelike Amerika',
 			'029' => 'Karibiese streek',
 			'030' => 'Oos-Asië',
 			'034' => 'Suid-Asië',
 			'035' => 'Suidoos-Asië',
 			'039' => 'Suid-Europa',
 			'053' => 'Australasië',
 			'054' => 'Melanesië',
 			'057' => 'Mikronesiese streek',
 			'061' => 'Polinesië',
 			'142' => 'Asië',
 			'143' => 'Sentraal-Asië',
 			'145' => 'Wes-Asië',
 			'150' => 'Europa',
 			'151' => 'Oos-Europa',
 			'154' => 'Noord-Europa',
 			'155' => 'Wes-Europa',
 			'202' => 'Afrika suid van die Sahara',
 			'419' => 'Latyns-Amerika',
 			'AC' => 'Ascensioneiland',
 			'AD' => 'Andorra',
 			'AE' => 'Verenigde Arabiese Emirate',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua en Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanië',
 			'AM' => 'Armenië',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentinië',
 			'AS' => 'Amerikaanse Samoa',
 			'AT' => 'Oostenryk',
 			'AU' => 'Australië',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandeilande',
 			'AZ' => 'Azerbeidjan',
 			'BA' => 'Bosnië en Herzegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesj',
 			'BE' => 'België',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarye',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Broenei',
 			'BO' => 'Bolivië',
 			'BQ' => 'Karibiese Nederland',
 			'BR' => 'Brasilië',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhoetan',
 			'BV' => 'Bouvet-eiland',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokoseilande',
 			'CD' => 'Demokratiese Republiek van die Kongo',
 			'CD@alt=variant' => 'Kongo (DRK)',
 			'CF' => 'Sentraal-Afrikaanse Republiek',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republiek die)',
 			'CH' => 'Switserland',
 			'CI' => 'Ivoorkus',
 			'CK' => 'Cookeilande',
 			'CL' => 'Chili',
 			'CM' => 'Kameroen',
 			'CN' => 'Sjina',
 			'CO' => 'Colombië',
 			'CP' => 'Clippertoneiland',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kaap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Kerseiland',
 			'CY' => 'Siprus',
 			'CZ' => 'Tsjeggië',
 			'CZ@alt=variant' => 'Tsjeggiese Republiek',
 			'DE' => 'Duitsland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djiboeti',
 			'DK' => 'Denemarke',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaanse Republiek',
 			'DZ' => 'Algerië',
 			'EA' => 'Ceuta en Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egipte',
 			'EH' => 'Wes-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanje',
 			'ET' => 'Ethiopië',
 			'EU' => 'Europese Unie',
 			'EZ' => 'Eurosone',
 			'FI' => 'Finland',
 			'FJ' => 'Fidji',
 			'FK' => 'Falklandeilande',
 			'FK@alt=variant' => 'Falklandeilande (Malvinas)',
 			'FM' => 'Mikronesië',
 			'FO' => 'Faroëreilande',
 			'FR' => 'Frankryk',
 			'GA' => 'Gaboen',
 			'GB' => 'Verenigde Koninkryk',
 			'GB@alt=short' => 'VK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgië',
 			'GF' => 'Frans-Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenland',
 			'GM' => 'Gambië',
 			'GN' => 'Guinee',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekwatoriaal-Guinee',
 			'GR' => 'Griekeland',
 			'GS' => 'Suid-Georgië en die Suidelike Sandwicheilande',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinee-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong SAS Sjina',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardeiland en McDonaldeilande',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasië',
 			'HT' => 'Haïti',
 			'HU' => 'Hongarye',
 			'IC' => 'Kanariese Eilande',
 			'ID' => 'Indonesië',
 			'IE' => 'Ierland',
 			'IL' => 'Israel',
 			'IM' => 'Eiland Man',
 			'IN' => 'Indië',
 			'IO' => 'Brits-Indiese Oseaangebied',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Ysland',
 			'IT' => 'Italië',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordanië',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comore',
 			'KN' => 'Sint Kitts en Nevis',
 			'KP' => 'Noord-Korea',
 			'KR' => 'Suid-Korea',
 			'KW' => 'Koeweit',
 			'KY' => 'Kaaimanseilande',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Sint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberië',
 			'LS' => 'Lesotho',
 			'LT' => 'Litaue',
 			'LU' => 'Luxemburg',
 			'LV' => 'Letland',
 			'LY' => 'Libië',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldowa',
 			'ME' => 'Montenegro',
 			'MF' => 'Sint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalleilande',
 			'MK' => 'Macedonië',
 			'MK@alt=variant' => 'Macedonië (VJRM)',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birma)',
 			'MN' => 'Mongolië',
 			'MO' => 'Macau SAS Sjina',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Noord-Mariane-eilande',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritanië',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maledive',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Maleisië',
 			'MZ' => 'Mosambiek',
 			'NA' => 'Namibië',
 			'NC' => 'Nieu-Kaledonië',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkeiland',
 			'NG' => 'Nigerië',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederland',
 			'NO' => 'Noorweë',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nieu-Seeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frans-Polinesië',
 			'PG' => 'Papoea-Nieu-Guinee',
 			'PH' => 'Filippyne',
 			'PK' => 'Pakistan',
 			'PL' => 'Pole',
 			'PM' => 'Sint Pierre en Miquelon',
 			'PN' => 'Pitcairneilande',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestynse gebiede',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Afgeleë Oseanië',
 			'RE' => 'Réunion',
 			'RO' => 'Roemenië',
 			'RS' => 'Serwië',
 			'RU' => 'Rusland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saoedi-Arabië',
 			'SB' => 'Salomonseilande',
 			'SC' => 'Seychelle',
 			'SD' => 'Soedan',
 			'SE' => 'Swede',
 			'SG' => 'Singapoer',
 			'SH' => 'Sint Helena',
 			'SI' => 'Slowenië',
 			'SJ' => 'Svalbard en Jan Mayen',
 			'SK' => 'Slowakye',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalië',
 			'SR' => 'Suriname',
 			'SS' => 'Suid-Soedan',
 			'ST' => 'São Tomé en Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sirië',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- en Caicoseilande',
 			'TD' => 'Tsjad',
 			'TF' => 'Franse Suidelike Gebiede',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Oos-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisië',
 			'TO' => 'Tonga',
 			'TR' => 'Turkye',
 			'TT' => 'Trinidad en Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzanië',
 			'UA' => 'Oekraïne',
 			'UG' => 'Uganda',
 			'UM' => 'Klein afgeleë eilande van die VSA',
 			'UN' => 'Verenigde Nasies',
 			'UN@alt=short' => 'VN',
 			'US' => 'Verenigde State van Amerika',
 			'US@alt=short' => 'VSA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Oesbekistan',
 			'VA' => 'Vatikaanstad',
 			'VC' => 'Sint Vincent en die Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Britse Maagde-eilande',
 			'VI' => 'VSA se Maagde-eilande',
 			'VN' => 'Viëtnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis en Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suid-Afrika',
 			'ZM' => 'Zambië',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Onbekende gebied',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Duitse ortografie van 1901',
 			'1996' => 'Duitse ortografie van 1996',
 			'PINYIN' => 'pinyin',
 			'REVISED' => 'hersiene ortografie',
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
			'calendar' => 'Kalender',
 			'cf' => 'Geldeenheidformaat',
 			'colalternate' => 'Ignoreer simboolsortering',
 			'colbackwards' => 'Omgekeerde aksentsortering',
 			'colcasefirst' => 'Hoofletters/kleinletters-sortering',
 			'colcaselevel' => 'Kassensitiewe sortering',
 			'collation' => 'Rangskikvolgorde',
 			'colnormalization' => 'Genormaliseerde sortering',
 			'colnumeric' => 'Numeriese sortering',
 			'colstrength' => 'Sorteringssterkte',
 			'currency' => 'Geldeenheid',
 			'hc' => 'Uursiklus (12 vs 24)',
 			'lb' => 'Reëlafbreek-styl',
 			'ms' => 'Maatstelsel',
 			'numbers' => 'Syfers',
 			'timezone' => 'Tydsone',
 			'va' => 'Lokaalvariant',
 			'x' => 'Privaat gebruik',

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
 				'buddhist' => q{Boeddhistiese kalender},
 				'chinese' => q{Sjinese kalender},
 				'coptic' => q{Koptiese kalender},
 				'dangi' => q{Dangi-kalender},
 				'ethiopic' => q{Etiopiese kalender},
 				'ethiopic-amete-alem' => q{Etiopiese Amete Alem-kalender},
 				'gregorian' => q{Gregoriaanse kalender},
 				'hebrew' => q{Hebreeuse kalender},
 				'indian' => q{Indiese nasionale kalender},
 				'islamic' => q{Islamitiese kalender},
 				'islamic-civil' => q{Islamitiese siviele kalender},
 				'iso8601' => q{ISO-8601-kalender},
 				'japanese' => q{Japannese kalender},
 				'persian' => q{Persiese kalender},
 				'roc' => q{Minguo-kalender},
 			},
 			'cf' => {
 				'account' => q{Rekeningkundige geldeenheidformaat},
 				'standard' => q{Standaard geldeenheidformaat},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sorteer simbole},
 				'shifted' => q{Sorteer ignoreersimbole},
 			},
 			'colbackwards' => {
 				'no' => q{Sorteer aksente gewoonweg},
 				'yes' => q{Sorteer aksente omgekeerd},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sorteer kleinletters veerste},
 				'no' => q{Sorteer gewone letterorde},
 				'upper' => q{Sorteer hoofletters eerste},
 			},
 			'colcaselevel' => {
 				'no' => q{Sorteer nie kassensitief nie},
 				'yes' => q{Sorteer kassensitief},
 			},
 			'collation' => {
 				'big5han' => q{Tradisionele Chinese sorteervolgorde - Groot5},
 				'dictionary' => q{Woordeboek-sorteervolgorde},
 				'ducet' => q{Verstek Unicode-rangskikvolgorde},
 				'gb2312han' => q{Vereenvoudigde Chinese sorteervolgorde - GB2312},
 				'phonebook' => q{Foonboek-sorteervolgorde},
 				'phonetic' => q{Fonetiese sorteerorde},
 				'pinyin' => q{Pinyin-sorteervolgorde},
 				'reformed' => q{Gereformeerde sorteervolgorde},
 				'search' => q{Algemenedoel-soektog},
 				'searchjl' => q{Soek volgens Hangul-beginkonsonant},
 				'standard' => q{Standaard rangskikvolgorde},
 				'stroke' => q{Slag-sorteervolgorde},
 				'traditional' => q{Tradisionele sorteervolgorde},
 				'unihan' => q{Radikale-slag-sorteervolgorde},
 			},
 			'colnormalization' => {
 				'no' => q{Sorteer sonder normalisering},
 				'yes' => q{Sorteer Unicode genormaliseer},
 			},
 			'colnumeric' => {
 				'no' => q{Sorteer syfers individueel},
 				'yes' => q{Sorteer syfers numeries},
 			},
 			'colstrength' => {
 				'identical' => q{Sorteer almal},
 				'primary' => q{Sorteer slegs basisletters},
 				'quaternary' => q{Sorteer aksente/kas/breedte/Kana},
 				'secondary' => q{Sorteer aksente},
 				'tertiary' => q{Sorteer aksente/kas/breedte},
 			},
 			'd0' => {
 				'fwidth' => q{Vollewydte},
 				'hwidth' => q{Halfwydte},
 				'npinyin' => q{Numeries},
 			},
 			'hc' => {
 				'h11' => q{12-uur-stelsel (0-11)},
 				'h12' => q{12-uur-stelsel (1-12)},
 				'h23' => q{24-uur-stelsel (0-23)},
 				'h24' => q{24-uur-stelsel (1-24)},
 			},
 			'lb' => {
 				'loose' => q{Losse reëlafbreek-styl},
 				'normal' => q{Normale reëlafbreek-styl},
 				'strict' => q{Streng reëlafbreek-styl},
 			},
 			'm0' => {
 				'bgn' => q{BGN-transliterasie},
 				'ungegn' => q{UNGEGN-transliterasie},
 			},
 			'ms' => {
 				'metric' => q{Metrieke stelsel},
 				'uksystem' => q{Imperiale maatstelsel},
 				'ussystem' => q{VSA-maatstelsel},
 			},
 			'numbers' => {
 				'arab' => q{Arabies-Indiese syfers},
 				'arabext' => q{Uitgebreide Arabies-Indiese syfers},
 				'armn' => q{Armeense syfers},
 				'armnlow' => q{Armeense kleinletter-syfers},
 				'beng' => q{Bengaalse syfers},
 				'deva' => q{Devanagari-syfers},
 				'ethi' => q{Etiopiese syfers},
 				'finance' => q{Finansiële syfers},
 				'fullwide' => q{Vollewydte-syfers},
 				'geor' => q{Georgiese syfers},
 				'grek' => q{Griekse syfers},
 				'greklow' => q{Griekse kleinletter-syfers},
 				'gujr' => q{Goedjarati-syfers},
 				'guru' => q{Gurmukhi-syfers},
 				'hanidec' => q{Sjinese desimale syfers},
 				'hans' => q{Vereenvoudigde Sjinese syfers},
 				'hansfin' => q{Vereenvoudigde Sjinese finansiële syfers},
 				'hant' => q{Tradisionele Sjinese syfers},
 				'hantfin' => q{Tradisionele Sjinese finansiële syfers},
 				'hebr' => q{Hebreeuse syfers},
 				'jpan' => q{Japannese syfers},
 				'jpanfin' => q{Japannese finansiële syfers},
 				'khmr' => q{Khmer-syfers},
 				'knda' => q{Kannada-syfers},
 				'laoo' => q{Lao-syfers},
 				'latn' => q{Westerse syfers},
 				'mlym' => q{Malabaarse syfers},
 				'mong' => q{Mongoliese syfers},
 				'mymr' => q{Mianmar-syfers},
 				'native' => q{Inheemse syfers},
 				'orya' => q{Odia-syfers},
 				'roman' => q{Romeinse syfers},
 				'romanlow' => q{Romeinse kleinletter-syfers},
 				'taml' => q{Tradisionele Tamil-syfers},
 				'tamldec' => q{Tamil-syfers},
 				'telu' => q{Teloegoe-syfers},
 				'thai' => q{Thaise syfers},
 				'tibt' => q{Tibettaanse syfers},
 				'traditional' => q{Tradisionele syfers},
 				'vaii' => q{Vai-syfers},
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
			'metric' => q{Metrieke stelsel},
 			'UK' => q{VK},
 			'US' => q{VSA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Taal: {0}',
 			'script' => 'Skrif: {0}',
 			'region' => 'Streek: {0}',

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
			auxiliary => qr{[à å ä ã æ ç í ì ó ò ú ù ü ý]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á â b c d e é è ê ë f g h i î ï j k l m n o ô ö p q r s t u û v w x y z]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
				hm => 'hh:mm',
				hms => 'hh:mm:ss',
				ms => 'mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'' => {
						'name' => q(kardinale rigting),
					},
					'acre' => {
						'name' => q(akker),
						'one' => q({0} akker),
						'other' => q({0} akker),
					},
					'acre-foot' => {
						'name' => q(akkervoet),
						'one' => q({0} akkervoet),
						'other' => q({0} akkervoet),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(boogminute),
						'one' => q({0} boogminuut),
						'other' => q({0} boogminute),
					},
					'arc-second' => {
						'name' => q(boogsekondes),
						'one' => q({0} boogsekonde),
						'other' => q({0} boogsekondes),
					},
					'astronomical-unit' => {
						'name' => q(astronomiese eenheid),
						'one' => q({0} astronomiese eenheid),
						'other' => q({0} astronomiese eenheid),
					},
					'atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfere),
					},
					'bit' => {
						'name' => q(bis),
						'one' => q({0} bis),
						'other' => q({0} bis),
					},
					'byte' => {
						'name' => q(grepe),
						'one' => q({0} greep),
						'other' => q({0} grepe),
					},
					'calorie' => {
						'name' => q(kalorië),
						'one' => q({0} kalorie),
						'other' => q({0} kalorië),
					},
					'carat' => {
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					'celsius' => {
						'name' => q(grade Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} grade Celsius),
					},
					'centiliter' => {
						'name' => q(sentiliter),
						'one' => q({0} sentiliter),
						'other' => q({0} sentiliter),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'one' => q({0} sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
					},
					'century' => {
						'name' => q(eeu),
						'one' => q({0} eeu),
						'other' => q({0} eeue),
					},
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(kubieke sentimeter),
						'one' => q({0} kubieke sentimeter),
						'other' => q({0} kubieke sentimeter),
						'per' => q({0} per kubieke sentimeter),
					},
					'cubic-foot' => {
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(kubieke duim),
						'one' => q({0} kubieke duim),
						'other' => q({0} kubieke duim),
					},
					'cubic-kilometer' => {
						'name' => q(kubieke kilometer),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometer),
					},
					'cubic-meter' => {
						'name' => q(kubieke meter),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meter),
						'per' => q({0} per kubieke meter),
					},
					'cubic-mile' => {
						'name' => q(kubieke myl),
						'one' => q({0} kubieke myl),
						'other' => q({0} kubieke myl),
					},
					'cubic-yard' => {
						'name' => q(kubieke jaart),
						'one' => q({0} kubieke jaart),
						'other' => q({0} kubieke jaart),
					},
					'cup' => {
						'name' => q(koppies),
						'one' => q({0} koppie),
						'other' => q({0} koppies),
					},
					'cup-metric' => {
						'name' => q(metrieke koppies),
						'one' => q({0} metrieke koppie),
						'other' => q({0} metrieke koppies),
					},
					'day' => {
						'name' => q(dae),
						'one' => q({0} dag),
						'other' => q({0} dae),
						'per' => q({0}/d.),
					},
					'deciliter' => {
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					'decimeter' => {
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					'degree' => {
						'name' => q(grade),
						'one' => q({0} graad),
						'other' => q({0} grade),
					},
					'fahrenheit' => {
						'name' => q(grade Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} grade Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(vloeistofonse),
						'one' => q({0} vloeistofons),
						'other' => q({0} vloeistofonse),
					},
					'foodcalorie' => {
						'name' => q(Kalorië),
						'one' => q({0} Kalorie),
						'other' => q({0} Kalorië),
					},
					'foot' => {
						'name' => q(voet),
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					'g-force' => {
						'name' => q(swaartekrag van die Aarde),
						'one' => q({0} swaartekrag van die Aarde),
						'other' => q({0} swaartekrag van die Aarde),
					},
					'gallon' => {
						'name' => q(gelling),
						'one' => q({0} gelling),
						'other' => q({0} gelling),
						'per' => q({0} per gelling),
					},
					'gallon-imperial' => {
						'name' => q(imp. gelling),
						'one' => q({0} imp. gelling),
						'other' => q({0} imp. gelling),
						'per' => q({0}/imp. gel.),
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
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hektaar),
						'one' => q({0} hektaar),
						'other' => q({0} hektaar),
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
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(perdekrag),
						'one' => q({0} perdekrag),
						'other' => q({0} perdekrag),
					},
					'hour' => {
						'name' => q(uur),
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(duim),
						'one' => q({0} duim),
						'other' => q({0} duim),
						'per' => q({0} per duim),
					},
					'inch-hg' => {
						'name' => q(duim kwik),
						'one' => q({0} duim kwik),
						'other' => q({0} duim kwik),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
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
						'name' => q(kilokalorië),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorië),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
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
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knope),
					},
					'light-year' => {
						'name' => q(ligjare),
						'one' => q({0} ligjare),
						'other' => q({0} ligjare),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter per 100 kilometers),
						'one' => q({0} liter per 100 kilometers),
						'other' => q({0} liter per 100 kilometers),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
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
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meter per sekonde),
						'one' => q({0} meter per sekonde),
						'other' => q({0} meter per sekonde),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(metrieke ton),
						'one' => q({0} metrieke ton),
						'other' => q({0} metrieke ton),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					'microsecond' => {
						'name' => q(mikrosekondes),
						'one' => q({0} mikrosekonde),
						'other' => q({0} mikrosekondes),
					},
					'mile' => {
						'name' => q(myl),
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					'mile-per-gallon' => {
						'name' => q(myl per gelling),
						'one' => q({0} myl per gelling),
						'other' => q({0} myl per gelling),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(myl per imp. gelling),
						'one' => q({0} myl per imp. gelling),
						'other' => q({0} myl per imp. gelling),
					},
					'mile-per-hour' => {
						'name' => q(myl per uur),
						'one' => q({0} myl per uur),
						'other' => q({0} myl per uur),
					},
					'mile-scandinavian' => {
						'name' => q(skandinawiese myl),
						'one' => q({0} skandinawiese myl),
						'other' => q({0} skandinawiese myl),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeter kwik),
						'one' => q({0} millimeter kwik),
						'other' => q({0} millimeter kwik),
					},
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					'millisecond' => {
						'name' => q(millisekondes),
						'one' => q({0} millisekonde),
						'other' => q({0} millisekondes),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(minute),
						'one' => q({0} minuut),
						'other' => q({0} minute),
						'per' => q({0} per minuut),
					},
					'month' => {
						'name' => q(maande),
						'one' => q({0} maand),
						'other' => q({0} maande),
						'per' => q({0}/md.),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanosekondes),
						'one' => q({0} nanosekonde),
						'other' => q({0} nanosekondes),
					},
					'nautical-mile' => {
						'name' => q(seemyl),
						'one' => q({0} seemyl),
						'other' => q({0} seemyl),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(onse),
						'one' => q({0} ons),
						'other' => q({0} onse),
						'per' => q({0} per ons),
					},
					'ounce-troy' => {
						'name' => q(troy-onse),
						'one' => q({0} troy-ons),
						'other' => q({0} troy-onse),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(dele per miljoen),
						'one' => q({0} dele per miljoen),
						'other' => q({0} dele per miljoen),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'percent' => {
						'name' => q(persent),
						'one' => q({0} persent),
						'other' => q({0} persent),
					},
					'permille' => {
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					'petabyte' => {
						'name' => q(petagrepe),
						'one' => q({0} petagreep),
						'other' => q({0} petagrepe),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pinte),
						'one' => q({0} pint),
						'other' => q({0} pinte),
					},
					'pint-metric' => {
						'name' => q(metrieke pinte),
						'one' => q({0} metrieke pint),
						'other' => q({0} metrieke pinte),
					},
					'point' => {
						'name' => q(punte),
						'one' => q({0} punt),
						'other' => q({0} punte),
					},
					'pound' => {
						'name' => q(pond),
						'one' => q({0} pond),
						'other' => q({0} pond),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(pond per vierkante duim),
						'one' => q({0} pond per vierkante duim),
						'other' => q({0} pond per vierkante duim),
					},
					'quart' => {
						'name' => q(kwarte),
						'one' => q({0} kwart),
						'other' => q({0} kwarte),
					},
					'radian' => {
						'name' => q(radiale),
						'one' => q({0} radiaal),
						'other' => q({0} radiale),
					},
					'revolution' => {
						'name' => q(rewolusie),
						'one' => q({0} rewolusie),
						'other' => q({0} rewolusies),
					},
					'second' => {
						'name' => q(sekondes),
						'one' => q({0} sekonde),
						'other' => q({0} sekondes),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(vierkante sentimeter),
						'one' => q({0} vierkante sentimeter),
						'other' => q({0} vierkante sentimeter),
						'per' => q({0} per vierkante sentimeter),
					},
					'square-foot' => {
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					'square-inch' => {
						'name' => q(vierkante duim),
						'one' => q({0} vierkante duim),
						'other' => q({0} vierkante duim),
						'per' => q({0} per vierkante duim),
					},
					'square-kilometer' => {
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					'square-meter' => {
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					'square-mile' => {
						'name' => q(vierkante myl),
						'one' => q({0} vierkante myl),
						'other' => q({0} vierkante myl),
						'per' => q({0} per vierkante myl),
					},
					'square-yard' => {
						'name' => q(vierkante jaart),
						'one' => q({0} vierkante jaart),
						'other' => q({0} vierkante jaart),
					},
					'tablespoon' => {
						'name' => q(eetlepel),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					'teaspoon' => {
						'name' => q(teelepels),
						'one' => q({0} teelepel),
						'other' => q({0} teelepels),
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
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
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
						'name' => q(weke),
						'one' => q({0} week),
						'other' => q({0} weke),
						'per' => q({0}/w.),
					},
					'yard' => {
						'name' => q(jaart),
						'one' => q({0} jaart),
						'other' => q({0} jaart),
					},
					'year' => {
						'name' => q(jaar),
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(rigting),
					},
					'acre' => {
						'one' => q({0} ak),
						'other' => q({0} ak),
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
					},
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-mile' => {
						'one' => q({0} myl³),
						'other' => q({0} myl³),
					},
					'day' => {
						'name' => q(dag),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q({0} vt.),
						'other' => q({0} vt.),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'horsepower' => {
						'one' => q({0}pk.),
						'other' => q({0}pk.),
					},
					'hour' => {
						'name' => q(uur),
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					'inch' => {
						'one' => q({0} duim),
						'other' => q({0} duim),
					},
					'inch-hg' => {
						'one' => q({0} dm.Hg),
						'other' => q({0} dm.Hg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'light-year' => {
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} ℓ),
						'other' => q({0} ℓ),
					},
					'liter-per-100kilometers' => {
						'name' => q(ℓ/100km),
						'one' => q({0} ℓ/100km),
						'other' => q({0} ℓ/100km),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'mile' => {
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					'mile-per-hour' => {
						'one' => q({0} myl/h),
						'other' => q({0} myl/h),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0} mbar),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(minute),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					'month' => {
						'name' => q(maand),
						'one' => q({0} md.),
						'other' => q({0} md.),
					},
					'ounce' => {
						'one' => q({0} oz.),
						'other' => q({0} oz.),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pound' => {
						'one' => q({0} lb.),
						'other' => q({0} lb.),
					},
					'second' => {
						'name' => q(sekondes),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					'square-foot' => {
						'one' => q({0} vt.²),
						'other' => q({0} vt.²),
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
						'one' => q({0}myl²),
						'other' => q({0}myl²),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(w.),
						'one' => q({0} w.),
						'other' => q({0} w.),
					},
					'yard' => {
						'one' => q({0} jt.),
						'other' => q({0} jt.),
					},
					'year' => {
						'name' => q(jaar),
						'one' => q({0} j.),
						'other' => q({0} j.),
					},
				},
				'short' => {
					'' => {
						'name' => q(rigting),
					},
					'acre' => {
						'name' => q(akker),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					'acre-foot' => {
						'name' => q(akkervoet),
						'one' => q({0} ak.vt.),
						'other' => q({0} ak.vt.),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(boogminute),
						'one' => q({0} boogmin.),
						'other' => q({0} boogmin.),
					},
					'arc-second' => {
						'name' => q(boogsekondes),
						'one' => q({0} boogsek.),
						'other' => q({0} boogsek.),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bis),
						'one' => q({0} bis),
						'other' => q({0} bis),
					},
					'byte' => {
						'name' => q(greep),
						'one' => q({0} greep),
						'other' => q({0} greep),
					},
					'calorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					'carat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
					},
					'celsius' => {
						'name' => q(grade Celsius),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cℓ),
						'one' => q({0} cℓ),
						'other' => q({0} cℓ),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(e.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
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
						'name' => q(duim³),
						'one' => q({0} dm.³),
						'other' => q({0} dm.³),
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
						'name' => q(myl³),
						'one' => q({0} myl³),
						'other' => q({0} myl³),
					},
					'cubic-yard' => {
						'name' => q(jt.³),
						'one' => q({0} jt.³),
						'other' => q({0} jt.³),
					},
					'cup' => {
						'name' => q(koppie),
						'one' => q({0} kp.),
						'other' => q({0} kp.),
					},
					'cup-metric' => {
						'name' => q(mkp.),
						'one' => q({0} mkp.),
						'other' => q({0} mkp.),
					},
					'day' => {
						'name' => q(dae),
						'one' => q({0} dag),
						'other' => q({0} dae),
						'per' => q({0}/d.),
					},
					'deciliter' => {
						'name' => q(dℓ),
						'one' => q({0} dℓ),
						'other' => q({0} dℓ),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(grade),
						'one' => q({0} gr.),
						'other' => q({0} gr.),
					},
					'fahrenheit' => {
						'name' => q(grade Fahrenheit),
						'one' => q({0} °F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(vloz.),
						'one' => q({0} vloz.),
						'other' => q({0} vloz.),
					},
					'foodcalorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					'foot' => {
						'name' => q(voet),
						'one' => q({0} vt.),
						'other' => q({0} vt.),
						'per' => q({0}/vt.),
					},
					'g-force' => {
						'name' => q(swaartekrag van die Aarde),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gell.),
						'one' => q({0} gell.),
						'other' => q({0} gell.),
						'per' => q({0}/gell.),
					},
					'gallon-imperial' => {
						'name' => q(imp. gel.),
						'one' => q({0} imp. gel.),
						'other' => q({0} imp. gel.),
						'per' => q({0}/imp. gel.),
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
						'name' => q(hektaar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hℓ),
						'one' => q({0} hℓ),
						'other' => q({0} hℓ),
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
						'name' => q(perdekrag),
						'one' => q({0} pk.),
						'other' => q({0} pk.),
					},
					'hour' => {
						'name' => q(uur),
						'one' => q({0} u.),
						'other' => q({0} u.),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(duim),
						'one' => q({0} duim),
						'other' => q({0} duim),
						'per' => q({0}/duim),
					},
					'inch-hg' => {
						'name' => q(duim kwik),
						'one' => q({0} dm.Hg),
						'other' => q({0} dm.Hg),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
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
						'name' => q(kkal.),
						'one' => q({0} kkal.),
						'other' => q({0} kkal.),
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
						'name' => q(km/uur),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn.),
						'one' => q({0} kn.),
						'other' => q({0} kn.),
					},
					'light-year' => {
						'name' => q(ligjare),
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} ℓ),
						'other' => q({0} ℓ),
						'per' => q({0}/ℓ),
					},
					'liter-per-100kilometers' => {
						'name' => q(ℓ/100km),
						'one' => q({0} ℓ/100km),
						'other' => q({0} ℓ/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'one' => q({0} ℓ/km),
						'other' => q({0} ℓ/km),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
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
						'name' => q(Mℓ),
						'one' => q({0} Mℓ),
						'other' => q({0} Mℓ),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(meter per sekonde),
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
						'name' => q(myl),
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					'mile-per-gallon' => {
						'name' => q(myl/gel.),
						'one' => q({0} m.p.g.),
						'other' => q({0} m.p.g.),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(myl/imp. gel.),
						'one' => q({0} m.p.imp.g.),
						'other' => q({0} m.p.imp.g.),
					},
					'mile-per-hour' => {
						'name' => q(myl per uur),
						'one' => q({0} myl/h),
						'other' => q({0} myl/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dℓ),
						'one' => q({0} mg/dℓ),
						'other' => q({0} mg/dℓ),
					},
					'milliliter' => {
						'name' => q(mℓ),
						'one' => q({0} mℓ),
						'other' => q({0} mℓ),
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
						'name' => q(millimol/ℓ),
						'one' => q({0} mmol/ℓ),
						'other' => q({0} mmol/ℓ),
					},
					'millisecond' => {
						'name' => q(millisekondes),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(minute),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(maande),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
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
						'name' => q(sm.),
						'one' => q({0} sm.),
						'other' => q({0} sm.),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz.),
						'one' => q({0} oz.),
						'other' => q({0} oz.),
						'per' => q({0}/oz.),
					},
					'ounce-troy' => {
						'name' => q(troy-ons),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(dele/miljoen),
						'one' => q({0} d.p.m.),
						'other' => q({0} d.p.m.),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(percent),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(per mille),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PGrepe),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pinte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					'pint-metric' => {
						'name' => q(mpt.),
						'one' => q({0} mpt.),
						'other' => q({0} mpt.),
					},
					'point' => {
						'name' => q(punte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					'pound' => {
						'name' => q(lb.),
						'one' => q({0} lb.),
						'other' => q({0} lb.),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(pond per vierkante duim),
						'one' => q({0} pd.vk.dm.),
						'other' => q({0} pd.vk.dm.),
					},
					'quart' => {
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kw.),
					},
					'radian' => {
						'name' => q(radiale),
						'one' => q({0} rad.),
						'other' => q({0} rad.),
					},
					'revolution' => {
						'name' => q(rew.),
						'one' => q({0} rew.),
						'other' => q({0} rew.),
					},
					'second' => {
						'name' => q(sekondes),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(vt.²),
						'one' => q({0} vt.²),
						'other' => q({0} vt.²),
					},
					'square-inch' => {
						'name' => q(duim²),
						'one' => q({0} dm.²),
						'other' => q({0} dm.²),
						'per' => q({0}/dm.²),
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
						'name' => q(myl²),
						'one' => q({0} myl²),
						'other' => q({0} myl²),
						'per' => q({0}/myl²),
					},
					'square-yard' => {
						'name' => q(jaart²),
						'one' => q({0} jt.²),
						'other' => q({0} jt.²),
					},
					'tablespoon' => {
						'name' => q(eetl.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					'teaspoon' => {
						'name' => q(teel.),
						'one' => q({0} teel.),
						'other' => q({0} teel.),
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
						'name' => q(ton),
						'one' => q({0} tn),
						'other' => q({0} tn),
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
						'name' => q(weke),
						'one' => q({0} w.),
						'other' => q({0} w.),
						'per' => q({0}/w.),
					},
					'yard' => {
						'name' => q(jaart),
						'one' => q({0} jt.),
						'other' => q({0} jt.),
					},
					'year' => {
						'name' => q(jaar),
						'one' => q({0} j.),
						'other' => q({0} j.),
						'per' => q({0}/j.),
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
	default		=> sub { qr'^(?i:nee|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} en {1}),
				2 => q({0} en {1}),
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
					'one' => '0 k',
					'other' => '0 k',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
				},
				'1000000' => {
					'one' => '0 m',
					'other' => '0 m',
				},
				'10000000' => {
					'one' => '00 m',
					'other' => '00 m',
				},
				'100000000' => {
					'one' => '000 m',
					'other' => '000 m',
				},
				'1000000000' => {
					'one' => '0 mjd',
					'other' => '0 mjd',
				},
				'10000000000' => {
					'one' => '00 mjd',
					'other' => '00 mjd',
				},
				'100000000000' => {
					'one' => '000 mjd',
					'other' => '000 mjd',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 duisend',
					'other' => '0 duisend',
				},
				'10000' => {
					'one' => '00 duisend',
					'other' => '00 duisend',
				},
				'100000' => {
					'one' => '000 duisend',
					'other' => '000 duisend',
				},
				'1000000' => {
					'one' => '0 miljoen',
					'other' => '0 miljoen',
				},
				'10000000' => {
					'one' => '00 miljoen',
					'other' => '00 miljoen',
				},
				'100000000' => {
					'one' => '000 miljoen',
					'other' => '000 miljoen',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljard',
				},
				'10000000000' => {
					'one' => '00 miljard',
					'other' => '00 miljard',
				},
				'100000000000' => {
					'one' => '000 miljard',
					'other' => '000 miljard',
				},
				'1000000000000' => {
					'one' => '0 biljoen',
					'other' => '0 biljoen',
				},
				'10000000000000' => {
					'one' => '00 biljoen',
					'other' => '00 biljoen',
				},
				'100000000000000' => {
					'one' => '000 biljoen',
					'other' => '000 biljoen',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 k',
					'other' => '0 k',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
				},
				'1000000' => {
					'one' => '0 m',
					'other' => '0 m',
				},
				'10000000' => {
					'one' => '00 m',
					'other' => '00 m',
				},
				'100000000' => {
					'one' => '000 m',
					'other' => '000 m',
				},
				'1000000000' => {
					'one' => '0 mjd',
					'other' => '0 mjd',
				},
				'10000000000' => {
					'one' => '00 mjd',
					'other' => '00 mjd',
				},
				'100000000000' => {
					'one' => '000 mjd',
					'other' => '000 mjd',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(Verenigde Arabiese Emirate dirham),
				'one' => q(Verenigde Arabiese Emirate dirham),
				'other' => q(Verenigde Arabiese Emirate dirham),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgaanse afgani),
				'one' => q(Afgaanse afgani),
				'other' => q(Afgaanse afgani),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albanese lek),
				'one' => q(Albanese lek),
				'other' => q(Albanese lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armeense dram),
				'one' => q(Armeense dram),
				'other' => q(Armeense dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Nederlands-Antilliaanse gulde),
				'one' => q(Nederlands-Antilliaanse gulde),
				'other' => q(Nederlands-Antilliaanse gulde),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angolese kwanza),
				'one' => q(Angolese kwanza),
				'other' => q(Angolese kwanza),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentynse peso),
				'one' => q(Argentynse peso),
				'other' => q(Argentynse peso),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Australiese dollar),
				'one' => q(Australiese dollar),
				'other' => q(Australiese dollar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Arubaanse floryn),
				'one' => q(Arubaanse floryn),
				'other' => q(Arubaanse floryn),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Azerbeidjaanse manat),
				'one' => q(Azerbeidjaanse manat),
				'other' => q(Azerbeidjaanse manat),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosnies-Herzegowiniese omskakelbare marka),
				'one' => q(Bosnies-Herzegowiniese omskakelbare marka),
				'other' => q(Bosnies-Herzegowiniese omskakelbare marka),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados-dollar),
				'one' => q(Barbados-dollar),
				'other' => q(Barbados-dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladesjiese taka),
				'one' => q(Bangladesjiese taka),
				'other' => q(Bangladesjiese taka),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bulgaarse lev),
				'one' => q(Bulgaarse lev),
				'other' => q(Bulgaarse lev),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahreinse dinar),
				'one' => q(Bahreinse dinar),
				'other' => q(Bahreinse dinar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundiese frank),
				'one' => q(Burundiese frank),
				'other' => q(Burundiese frank),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda-dollar),
				'one' => q(Bermuda-dollar),
				'other' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Broeneise dollar),
				'one' => q(Broeneise dollar),
				'other' => q(Broeneise dollar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviaanse boliviano),
				'one' => q(Boliviaanse boliviano),
				'other' => q(Boliviaanse boliviano),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brasilliaanse reaal),
				'one' => q(Brasillianse reaal),
				'other' => q(Brasillianse reaal),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamiaanse dollar),
				'one' => q(Bahamiaanse dollar),
				'other' => q(Bahamiaanse dollar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Bhoetanese ngoeltroem),
				'one' => q(Bhoetanese ngoeltroem),
				'other' => q(Bhoetanese ngoeltroem),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswana pula),
				'one' => q(Botswana pula),
				'other' => q(Botswana pula),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Belo-Russiese roebel),
				'one' => q(Belo-Russiese roebel),
				'other' => q(Belo-Russiese roebel),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Belo-Russiese roebel \(2000–2016\)),
				'one' => q(Belo-Russiese roebel \(2000–2016\)),
				'other' => q(Belo-Russiese roebel \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Beliziese dollar),
				'one' => q(Beliziese dollar),
				'other' => q(Beliziese dollar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanadese dollar),
				'one' => q(Kanadese dollar),
				'other' => q(Kanadese dollar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongolese frank),
				'one' => q(Kongolese frank),
				'other' => q(Kongolese frank),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Switserse frank),
				'one' => q(Switserse frank),
				'other' => q(Switserse frank),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chileense peso),
				'one' => q(Chileense peso),
				'other' => q(Chileense peso),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Chinese joean),
				'one' => q(Chinese joean \(buiteland\)),
				'other' => q(Chinese joean \(buiteland\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Sjinese joean renminbi),
				'one' => q(Sjinese joean renminbi),
				'other' => q(Sjinese joean renminbi),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Colombiaanse peso),
				'one' => q(Colombiaanse peso),
				'other' => q(Colombiaanse peso),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Costa Ricaanse colón),
				'one' => q(Costa Ricaanse colón),
				'other' => q(Costa Ricaanse colón),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kubaanse omskakelbare peso),
				'one' => q(Kubaanse omskakelbare peso),
				'other' => q(Kubaanse omskakelbare peso),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kubaanse peso),
				'one' => q(Kubaanse peso),
				'other' => q(Kubaanse peso),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kaap Verdiese escudo),
				'one' => q(Kaap Verdiese escudo),
				'other' => q(Kaap Verdiese escudo),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Tsjeggiese kroon),
				'one' => q(Tsjeggiese kroon),
				'other' => q(Tsjeggiese kroon),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Djiboeti frank),
				'one' => q(Djiboeti frank),
				'other' => q(Djiboeti frank),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Deense kroon),
				'one' => q(Deense kroon),
				'other' => q(Deense kroon),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikaanse peso),
				'one' => q(Dominikaanse peso),
				'other' => q(Dominikaanse peso),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Algeriese dinar),
				'one' => q(Algeriese dinar),
				'other' => q(Algeriese dinar),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egiptiese pond),
				'one' => q(Egiptiese pond),
				'other' => q(Egiptiese pond),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritrese nakfa),
				'one' => q(Eritrese nakfa),
				'other' => q(Eritrese nakfa),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Etiopiese birr),
				'one' => q(Etiopiese birr),
				'other' => q(Etiopiese birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fidjiaanse dollar),
				'one' => q(Fidjiaanse dollar),
				'other' => q(Fidjiaanse dollar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falkland-eilande pond),
				'one' => q(Falkland-eilande pond),
				'other' => q(Falkland-eilande pond),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Britse pond),
				'one' => q(Britse pond),
				'other' => q(Britse pond),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Georgiese lari),
				'one' => q(Georgiese lari),
				'other' => q(Georgiese lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanese cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ghanese cedi),
				'one' => q(Ghanese cedi),
				'other' => q(Ghanese cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltarese pond),
				'one' => q(Gibraltarese pond),
				'other' => q(Gibraltarese pond),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambiese dalasi),
				'one' => q(Gambiese dalasi),
				'other' => q(Gambiese dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Guinese frank),
				'one' => q(Guinese frank),
				'other' => q(Guinese frank),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinese syli),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guatemalaanse quetzal),
				'one' => q(Guatemalaanse quetzal),
				'other' => q(Guatemalaanse quetzal),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyanese dollar),
				'one' => q(Guyanese dollar),
				'other' => q(Guyanese dollar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hong Kong dollar),
				'one' => q(Hong Kong dollar),
				'other' => q(Hong Kong dollar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Hondurese lempira),
				'one' => q(Hondurese lempira),
				'other' => q(Hondurese lempira),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroatiese kuna),
				'one' => q(Kroatiese kuna),
				'other' => q(Kroatiese kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haïtiaanse gourde),
				'one' => q(Haïtiaanse gourde),
				'other' => q(Haïtiaanse gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Hongaarse florint),
				'one' => q(Hongaarse florint),
				'other' => q(Hongaarse florint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesiese roepia),
				'one' => q(Indonesiese roepia),
				'other' => q(Indonesiese roepia),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Israeliese nuwe sikkel),
				'one' => q(Israeliese nuwe sikkel),
				'other' => q(Israeliese nuwe sikkel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indiese roepee),
				'one' => q(Indiese rupee),
				'other' => q(Indiese rupee),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Irakse dinar),
				'one' => q(Irakse dinar),
				'other' => q(Irakse dinar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Iranse rial),
				'one' => q(Iranse rial),
				'other' => q(Iranse rial),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Yslandse kroon),
				'one' => q(Yslandse kroon),
				'other' => q(Yslandse kroon),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiaanse lier),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaikaanse dollar),
				'one' => q(Jamaikaanse dollar),
				'other' => q(Jamaikaanse dollar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jordaniese dinar),
				'one' => q(Jordaniese dinar),
				'other' => q(Jordaniese dinar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japannese jen),
				'one' => q(Japannese jen),
				'other' => q(Japannese jen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Keniaanse sjieling),
				'one' => q(Keniaanse sjieling),
				'other' => q(Keniaanse sjieling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgisiese som),
				'one' => q(Kirgisiese som),
				'other' => q(Kirgisiese som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodjaanse riel),
				'one' => q(Kambodjaanse riel),
				'other' => q(Kambodjaanse riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Comoraanse frank),
				'one' => q(Comoraanse frank),
				'other' => q(Comoraanse frank),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Noord-Koreaanse won),
				'one' => q(Noord-Koreaanse won),
				'other' => q(Noord-Koreaanse won),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Suid-Koreaanse won),
				'one' => q(Suid-Koreaanse won),
				'other' => q(Suid-Koreaanse won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Koeweitse dinar),
				'one' => q(Koeweitse dinar),
				'other' => q(Koeweitse dinar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Cayman-eilande dollar),
				'one' => q(Cayman-eilande dollar),
				'other' => q(Cayman-eilande dollar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kazakse tenge),
				'one' => q(Kazakse tenge),
				'other' => q(Kazakse tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laosiaanse kip),
				'one' => q(Laosiaanse kip),
				'other' => q(Laosiaanse kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Lebanese pond),
				'one' => q(Lebanese pond),
				'other' => q(Lebanese pond),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lankaanse roepee),
				'one' => q(Sri Lankaanse roepee),
				'other' => q(Sri Lankaanse roepee),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberiese dollar),
				'one' => q(Liberiese dollar),
				'other' => q(Liberiese dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litause litas),
				'one' => q(Litause litas),
				'other' => q(Litause litas),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lettiese lats),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Libiese dinar),
				'one' => q(Libiese dinar),
				'other' => q(Libiese dinar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokkaanse dirham),
				'one' => q(Marokkaanse dirham),
				'other' => q(Marokkaanse dirham),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldowiese leu),
				'one' => q(Moldowiese leu),
				'other' => q(Moldowiese leu),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malgassiese ariary),
				'one' => q(Malgassiese ariary),
				'other' => q(Malgassiese ariary),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Macedoniese denar),
				'one' => q(Macedoniese denar),
				'other' => q(Macedoniese denar),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Mianmese kyat),
				'one' => q(Mianmese kyat),
				'other' => q(Mianmese kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongoolse toegrik),
				'one' => q(Mongoolse toegrik),
				'other' => q(Mongoolse toegrik),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Macaose pataca),
				'one' => q(Macaose pataca),
				'other' => q(Macaose pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mauritaniese ouguiya \(1973–2017\)),
				'one' => q(Mauritaniese ouguiya \(1973–2017\)),
				'other' => q(Mauritaniese ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritaniese ouguiya),
				'one' => q(Mauritaniese ouguiya),
				'other' => q(Mauritaniese ouguiya),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mauritiaanse rupee),
				'one' => q(Mauritiaanse rupee),
				'other' => q(Mauritiaanse rupee),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Malediviese rufia),
				'one' => q(Malediviese rufia),
				'other' => q(Malediviese rufia),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malawiese kwacha),
				'one' => q(Malawiese kwacha),
				'other' => q(Malawiese kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Meksikaanse peso),
				'one' => q(Meksikaanse peso),
				'other' => q(Meksikaanse peso),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Maleisiese ringgit),
				'one' => q(Maleisiese ringgit),
				'other' => q(Maleisiese ringgit),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mosambiekse metical \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mosambiekse metical),
				'one' => q(Mosambiekse metical),
				'other' => q(Mosambiekse metical),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibiese dollar),
				'one' => q(Namibiese dollar),
				'other' => q(Namibiese dollar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeriese naira),
				'one' => q(Nigeriese naira),
				'other' => q(Nigeriese naira),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nicaraguaanse córdoba),
				'one' => q(Nicaraguaanse córdoba),
				'other' => q(Nicaraguaanse córdoba),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Noorse kroon),
				'one' => q(Noorse kroon),
				'other' => q(Noorse kroon),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalese roepee),
				'one' => q(Nepalese roepee),
				'other' => q(Nepalese roepee),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Nieu-Seeland dollar),
				'one' => q(Nieu-Seeland dollar),
				'other' => q(Nieu-Seeland dollar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omaanse rial),
				'one' => q(Omaanse rial),
				'other' => q(Omaanse rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panamese balboa),
				'one' => q(Panamese balboa),
				'other' => q(Panamese balboa),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peruaanse sol),
				'one' => q(Peruaanse sol),
				'other' => q(Peruaanse sol),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papoea-Nieu-Guinese kina),
				'one' => q(Papoea-Nieu-Guinese kina),
				'other' => q(Papoea-Nieu-Guinese kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippynse peso),
				'one' => q(Filippynse peso),
				'other' => q(Filippynse peso),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistanse roepee),
				'one' => q(Pakistanse roepee),
				'other' => q(Pakistanse roepee),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Poolse zloty),
				'one' => q(Poolse zloty),
				'other' => q(Poolse zloty),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguaanse guarani),
				'one' => q(Paraguaanse guarani),
				'other' => q(Paraguaanse guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katarrese rial),
				'one' => q(Katarese rial),
				'other' => q(Katarese rial),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Roemeense leu),
				'one' => q(Roemeense leu),
				'other' => q(Roemeense leu),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbiese dinar),
				'one' => q(Serbiese dinar),
				'other' => q(Serbiese dinar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Russiese roebel),
				'one' => q(Russiese roebel),
				'other' => q(Russiese roebel),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Rwandiese frank),
				'one' => q(Rwandiese frank),
				'other' => q(Rwandiese frank),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saoedi-Arabiese riyal),
				'one' => q(Saoedi-Arabiese riyal),
				'other' => q(Saoedi-Arabiese riyal),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Salomonseilande dollar),
				'one' => q(Salomonseilande dollar),
				'other' => q(Salomonseilande dollar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seychellese rupee),
				'one' => q(Seychellese rupee),
				'other' => q(Seychellese rupee),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Soedannese pond),
				'one' => q(Soedannese pond),
				'other' => q(Soedannese pond),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Soedannese pond \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Sweedse kroon),
				'one' => q(Sweedse kroon),
				'other' => q(Sweedse kroon),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapoer dollar),
				'one' => q(Singapoer dollar),
				'other' => q(Singapoer dollar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Sint Helena pond),
				'one' => q(Sint Helena pond),
				'other' => q(Sint Helena pond),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra Leoniese leone),
				'one' => q(Sierra Leoniese leone),
				'other' => q(Sierra Leoniese leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somaliese sjieling),
				'one' => q(Somaliese sjieling),
				'other' => q(Somaliese sjieling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinaamse dollar),
				'one' => q(Surinaamse dollar),
				'other' => q(Surinaamse dollar),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Suid-Soedanese pond),
				'one' => q(Suid-Soedanese pond),
				'other' => q(Suid-Soedanese pond),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(São Tomé en Príncipe dobra \(1977–2017\)),
				'one' => q(São Tomé en Príncipe dobra \(1977–2017\)),
				'other' => q(São Tomé en Príncipe dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(São Tomé en Príncipe dobra),
				'one' => q(São Tomé en Príncipe dobra),
				'other' => q(São Tomé en Príncipe dobra),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Siriese pond),
				'one' => q(Siriese pond),
				'other' => q(Siriese pond),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Swazilandse lilangeni),
				'one' => q(Swazilandse lilangeni),
				'other' => q(Swazilandse lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thaise baht),
				'one' => q(Thaise baht),
				'other' => q(Thaise baht),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tadjikse roebel),
				'one' => q(Tadjikse roebel),
				'other' => q(Tadjikse roebel),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmeense manat),
				'one' => q(Turkmeense manat),
				'other' => q(Turkmeense manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunisiese dinar),
				'one' => q(Tunisiese dinar),
				'other' => q(Tunisiese dinar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tongaanse pa’anga),
				'one' => q(Tongaanse pa’anga),
				'other' => q(Tongaanse pa’anga),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkse lier \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkse lier),
				'one' => q(Turkse lier),
				'other' => q(Turkse lier),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad en Tobago dollar),
				'one' => q(Trinidad en Tobago dollar),
				'other' => q(Trinidad en Tobago dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nuwe Taiwanese dollar),
				'one' => q(Nuwe Taiwanese dollar),
				'other' => q(Nuwe Taiwanese dollar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzaniese sjieling),
				'one' => q(Tanzaniese sjieling),
				'other' => q(Tanzaniese sjieling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Oekraïnse hriwna),
				'one' => q(Oekraïnse hriwna),
				'other' => q(Oekraïnse hriwna),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Ugandese sjieling),
				'one' => q(Ugandese sjieling),
				'other' => q(Ugandese sjieling),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Amerikaanse dollar),
				'one' => q(Amerikaanse dollar),
				'other' => q(Amerikaanse dollar),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguaanse peso),
				'one' => q(Uruguaanse peso),
				'other' => q(Uruguaanse peso),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Oezbekiese som),
				'one' => q(Oezbekiese som),
				'other' => q(Oezbekiese som),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezolaanse bolivar),
				'one' => q(Venezolaanse bolívar \(2008–2018\)),
				'other' => q(Venezolaanse bolívare \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Venezolaanse Bolívar),
				'one' => q(Venezolaanse bolívar),
				'other' => q(Venezolaanse bolívare),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Viëtnamese dong),
				'one' => q(Viëtnamese dong),
				'other' => q(Viëtnamese dong),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatuse vatu),
				'one' => q(Vanuatuse vatu),
				'other' => q(Vanuatuse vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoaanse tala),
				'one' => q(Samoaanse tala),
				'other' => q(Samoaanse tala),
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
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Oos-Karibbiese dollar),
				'one' => q(Oos-Karibbiese dollar),
				'other' => q(Oos-Karibbiese dollar),
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
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-frank),
				'one' => q(CFP-frank),
				'other' => q(CFP-frank),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(onbekende geldeenheid),
				'one' => q(\(onbekende geldeenheid\)),
				'other' => q(\(onbekende geldeenheid\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemenitiese rial),
				'one' => q(Jemenitiese rial),
				'other' => q(Jemenitiese rial),
			},
		},
		'ZAR' => {
			symbol => 'R',
			display_name => {
				'currency' => q(Suid-Afrikaanse rand),
				'one' => q(Suid-Afrikaanse rand),
				'other' => q(Suid-Afrikaanse rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiese kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambiese kwacha),
				'one' => q(Zambiese kwacha),
				'other' => q(Zambiese kwacha),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwiese dollar),
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
							'Jan.',
							'Feb.',
							'Mrt.',
							'Apr.',
							'Mei',
							'Jun.',
							'Jul.',
							'Aug.',
							'Sep.',
							'Okt.',
							'Nov.',
							'Des.'
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
							'Januarie',
							'Februarie',
							'Maart',
							'April',
							'Mei',
							'Junie',
							'Julie',
							'Augustus',
							'September',
							'Oktober',
							'November',
							'Desember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan.',
							'Feb.',
							'Mrt.',
							'Apr.',
							'Mei',
							'Jun.',
							'Jul.',
							'Aug.',
							'Sep.',
							'Okt.',
							'Nov.',
							'Des.'
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
							'Januarie',
							'Februarie',
							'Maart',
							'April',
							'Mei',
							'Junie',
							'Julie',
							'Augustus',
							'September',
							'Oktober',
							'November',
							'Desember'
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
						mon => 'Ma.',
						tue => 'Di.',
						wed => 'Wo.',
						thu => 'Do.',
						fri => 'Vr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Ma.',
						tue => 'Di.',
						wed => 'Wo.',
						thu => 'Do.',
						fri => 'Vr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Maandag',
						tue => 'Dinsdag',
						wed => 'Woensdag',
						thu => 'Donderdag',
						fri => 'Vrydag',
						sat => 'Saterdag',
						sun => 'Sondag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Ma.',
						tue => 'Di.',
						wed => 'Wo.',
						thu => 'Do.',
						fri => 'Vr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Ma.',
						tue => 'Di.',
						wed => 'Wo.',
						thu => 'Do.',
						fri => 'Vr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Maandag',
						tue => 'Dinsdag',
						wed => 'Woensdag',
						thu => 'Donderdag',
						fri => 'Vrydag',
						sat => 'Saterdag',
						sun => 'Sondag'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ste kwartaal',
						1 => '2de kwartaal',
						2 => '3de kwartaal',
						3 => '4de kwartaal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ste kwartaal',
						1 => '2de kwartaal',
						2 => '3de kwartaal',
						3 => '4de kwartaal'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					'afternoon1' => q{die middag},
					'am' => q{vm.},
					'evening1' => q{die aand},
					'midnight' => q{middernag},
					'morning1' => q{die oggend},
					'night1' => q{die nag},
					'pm' => q{nm.},
				},
				'narrow' => {
					'afternoon1' => q{m},
					'am' => q{v},
					'evening1' => q{a},
					'midnight' => q{mn},
					'morning1' => q{o},
					'night1' => q{n},
					'pm' => q{n},
				},
				'wide' => {
					'afternoon1' => q{die middag},
					'am' => q{vm.},
					'evening1' => q{die aand},
					'midnight' => q{middernag},
					'morning1' => q{die oggend},
					'night1' => q{die nag},
					'pm' => q{nm.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{middag},
					'am' => q{vm.},
					'evening1' => q{aand},
					'midnight' => q{middernag},
					'morning1' => q{oggend},
					'night1' => q{nag},
					'pm' => q{nm.},
				},
				'narrow' => {
					'afternoon1' => q{m},
					'am' => q{v},
					'evening1' => q{a},
					'midnight' => q{mn},
					'morning1' => q{o},
					'night1' => q{n},
					'pm' => q{n},
				},
				'wide' => {
					'afternoon1' => q{middag},
					'am' => q{vm.},
					'evening1' => q{aand},
					'midnight' => q{middernag},
					'morning1' => q{oggend},
					'night1' => q{nag},
					'pm' => q{nm.},
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
				'0' => 'v.C.',
				'1' => 'n.C.'
			},
			narrow => {
				'0' => 'v.C.',
				'1' => 'n.C.'
			},
			wide => {
				'0' => 'voor Christus',
				'1' => 'na Christus'
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
			'full' => q{EEEE dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{y-MM-dd},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{h B},
			Bhm => q{hh:mm B},
			Bhms => q{hh:mm:ss B},
			E => q{ccc},
			EBhm => q{E hh:mm B},
			EBhms => q{E hh:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E M/d},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
			Ed => q{E d},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E dd MMM y G},
			GyMMMd => q{dd MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMW => q{'week' W 'van' MMM},
			MMMMd => q{d MMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E y-MM-dd},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'week' w 'van' Y},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm a – h:mm a v},
				m => q{h:mm a – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y},
				d => q{E d/M/y – E d/M/y},
				y => q{E d/M/y – E d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
		regionFormat => q({0}-tyd),
		regionFormat => q({0}-dagligtyd),
		regionFormat => q({0}-standaardtyd),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan-tyd#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
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
			exemplarCity => q#Kaïro#,
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
			exemplarCity => q#Djiboeti#,
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
			exemplarCity => q#Kartoem#,
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
			exemplarCity => q#Mogadisjoe#,
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
				'standard' => q#Sentraal-Afrika-tyd#,
			},
			short => {
				'standard' => q#CAT#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oos-Afrika-tyd#,
			},
			short => {
				'standard' => q#EAT#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Suid-Afrika-standaardtyd#,
			},
			short => {
				'standard' => q#SAST#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wes-Afrika-somertyd#,
				'generic' => q#Wes-Afrika-tyd#,
				'standard' => q#Wes-Afrika-standaardtyd#,
			},
			short => {
				'daylight' => q#WAST#,
				'generic' => q#WAT#,
				'standard' => q#WAT#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-dagligtyd#,
				'generic' => q#Alaska-tyd#,
				'standard' => q#Alaska-standaardtyd#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amasone-somertyd#,
				'generic' => q#Amasone-tyd#,
				'standard' => q#Amasone-standaardtyd#,
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
			exemplarCity => q#Belize#,
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
			exemplarCity => q#Cambridgebaai#,
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
			exemplarCity => q#Kaaiman#,
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
			exemplarCity => q#Costa Rica#,
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
			exemplarCity => q#Glacebaai#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goosebaai#,
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
			exemplarCity => q#Meksikostad#,
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
			exemplarCity => q#Beulah, Noord-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Noord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Noord-Dakota#,
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
			exemplarCity => q#Rainyrivier#,
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
			exemplarCity => q#Sint Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sint Vincent#,
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
			exemplarCity => q#Thunderbaai#,
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
				'daylight' => q#Noord-Amerikaanse sentrale dagligtyd#,
				'generic' => q#Noord-Amerikaanse sentrale tyd#,
				'standard' => q#Noord-Amerikaanse sentrale standaardtyd#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Noord-Amerikaanse oostelike dagligtyd#,
				'generic' => q#Noord-Amerikaanse oostelike tyd#,
				'standard' => q#Noord-Amerikaanse oostelike standaardtyd#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Noord-Amerikaanse berg-dagligtyd#,
				'generic' => q#Noord-Amerikaanse bergtyd#,
				'standard' => q#Noord-Amerikaanse berg-standaardtyd#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pasifiese dagligtyd#,
				'generic' => q#Pasifiese tyd#,
				'standard' => q#Pasifiese standaardtyd#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-somertyd#,
				'generic' => q#Anadyr-tyd#,
				'standard' => q#Anadyr-standaardtyd#,
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
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia-dagligtyd#,
				'generic' => q#Apia-tyd#,
				'standard' => q#Apia-standaardtyd#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabiese dagligtyd#,
				'generic' => q#Arabiese tyd#,
				'standard' => q#Arabiese standaardtyd#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinië-somertyd#,
				'generic' => q#Argentinië-tyd#,
				'standard' => q#Argentinië-standaardtyd#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Wes-Argentinië-somertyd#,
				'generic' => q#Wes-Argentinië-tyd#,
				'standard' => q#Wes-Argentinië-standaardtyd#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenië-somertyd#,
				'generic' => q#Armenië-tyd#,
				'standard' => q#Armenië-standaardtyd#,
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
			exemplarCity => q#Asjchabad#,
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
			exemplarCity => q#Bakoe#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beiroet#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Broenei#,
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
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Doebai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
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
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Djakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kaboel#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatsji#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandoe#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Koeala-Loempoer#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koeweit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
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
			exemplarCity => q#Muskat#,
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
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riaad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Tsji Minhstad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoel#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapoer#,
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
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
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
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakoetsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantiese dagligtyd#,
				'generic' => q#Atlantiese tyd#,
				'standard' => q#Atlantiese standaardtyd#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asore#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarie#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Suid-Georgië#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint Helena#,
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
				'daylight' => q#Sentraal-Australiese dagligtyd#,
				'generic' => q#Sentraal-Australiese tyd#,
				'standard' => q#Sentraal-Australiese standaardtyd#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Sentraal-westelike Australiese dagligtyd#,
				'generic' => q#Sentraal-westelike Australiese tyd#,
				'standard' => q#Sentraal-westelike Australiese standaard-tyd#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oostelike Australiese dagligtyd#,
				'generic' => q#Oostelike Australiese tyd#,
				'standard' => q#Oostelike Australiese standaardtyd#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Westelike Australiese dagligtyd#,
				'generic' => q#Westelike Australiese tyd#,
				'standard' => q#Westelike Australiese standaardtyd#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbeidjan-somertyd#,
				'generic' => q#Aserbeidjan-tyd#,
				'standard' => q#Aserbeidjan-standaardtyd#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Asore-somertyd#,
				'generic' => q#Asore-tyd#,
				'standard' => q#Asore-standaardtyd#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesj-somertyd#,
				'generic' => q#Bangladesj-tyd#,
				'standard' => q#Bangladesj-standaardtyd#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhoetan-tyd#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia-tyd#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia-somertyd#,
				'generic' => q#Brasilia-tyd#,
				'standard' => q#Brasilia-standaardtyd#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Broenei Darussalam-tyd#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kaap Verde-somertyd#,
				'generic' => q#Kaap Verde-tyd#,
				'standard' => q#Kaap Verde-standaardtyd#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-standaardtyd#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham-dagligtyd#,
				'generic' => q#Chatham-tyd#,
				'standard' => q#Chatham-standaardtyd#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chili-somertyd#,
				'generic' => q#Chili-tyd#,
				'standard' => q#Chili-standaardtyd#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China-dagligtyd#,
				'generic' => q#China-tyd#,
				'standard' => q#China-standaardtyd#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan-somertyd#,
				'generic' => q#Choibalsan-tyd#,
				'standard' => q#Choibalsan-standaardtyd#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmaseiland-tyd#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokoseilande-tyd#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombië-somertyd#,
				'generic' => q#Colombië-tyd#,
				'standard' => q#Colombië-standaardtyd#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookeilande-halfsomertyd#,
				'generic' => q#Cookeilande-tyd#,
				'standard' => q#Cookeilande-standaardtyd#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba-dagligtyd#,
				'generic' => q#Kuba-tyd#,
				'standard' => q#Kuba-standaardtyd#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-tyd#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville-tyd#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oos-Timor-tyd#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Paaseiland-somertyd#,
				'generic' => q#Paaseiland-tyd#,
				'standard' => q#Paaseiland-standaardtyd#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador-tyd#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Gekoördineerde universele tyd#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Onbekende stad#,
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
			exemplarCity => q#Athene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlyn#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Boekarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Boedapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Ierse standaardtyd#,
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
			exemplarCity => q#Eiland Man#,
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
			exemplarCity => q#Kiëf#,
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
			exemplarCity => q#Londen#,
			long => {
				'daylight' => q#Britse somertyd#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskou#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parys#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rome#,
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
			exemplarCity => q#Saratof#,
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
			exemplarCity => q#Stockholm#,
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
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikaanstad#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wene#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warskou#,
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
				'daylight' => q#Sentraal-Europese somertyd#,
				'generic' => q#Sentraal-Europese tyd#,
				'standard' => q#Sentraal-Europese standaardtyd#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oos-Europese somertyd#,
				'generic' => q#Oos-Europese tyd#,
				'standard' => q#Oos-Europese standaardtyd#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Verder-oos-Europese tyd#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wes-Europese somertyd#,
				'generic' => q#Wes-Europese tyd#,
				'standard' => q#Wes-Europese standaardtyd#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandeilande-somertyd#,
				'generic' => q#Falklandeilande-tyd#,
				'standard' => q#Falklandeilande-standaardtyd#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidji-somertyd#,
				'generic' => q#Fidji-tyd#,
				'standard' => q#Fidji-standaardtyd#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frans-Guiana-tyd#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Franse Suider- en Antarktiese tyd#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich-tyd#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos-tyd#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier-tyd#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgië-somertyd#,
				'generic' => q#Georgië-tyd#,
				'standard' => q#Georgië-standaardtyd#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberteilande-tyd#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oos-Groenland-somertyd#,
				'generic' => q#Oos-Groenland-tyd#,
				'standard' => q#Oos-Groenland-standaardtyd#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Wes-Groenland-somertyd#,
				'generic' => q#Wes-Groenland-tyd#,
				'standard' => q#Wes-Groenland-standaardtyd#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Persiese Golf-standaardtyd#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana-tyd#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleoete-dagligtyd#,
				'generic' => q#Hawaii-Aleoete-tyd#,
				'standard' => q#Hawaii-Aleoete-standaardtyd#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkong-somertyd#,
				'generic' => q#Hongkong-tyd#,
				'standard' => q#Hongkong-standaardtyd#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd-somertyd#,
				'generic' => q#Hovd-tyd#,
				'standard' => q#Hovd-standaardtyd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indië-standaardtyd#,
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
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comore#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maledive#,
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
				'standard' => q#Indiese Oseaan-tyd#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indosjina-tyd#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Sentraal-Indonesiese tyd#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oos-Indonesië-tyd#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Wes-Indonesië-tyd#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran-dagligtyd#,
				'generic' => q#Iran-tyd#,
				'standard' => q#Iran-standaardtyd#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk-somertyd#,
				'generic' => q#Irkutsk-tyd#,
				'standard' => q#Irkutsk-standaardtyd#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel-dagligtyd#,
				'generic' => q#Israel-tyd#,
				'standard' => q#Israel-standaardtyd#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan-dagligtyd#,
				'generic' => q#Japan-tyd#,
				'standard' => q#Japan-standaardtyd#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamchatski-somertyd#,
				'generic' => q#Petropavlovsk-Kamchatski-tyd#,
				'standard' => q#Petropavlovsk-Kamchatski-standaardtyd#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oos-Kazakstan-tyd#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Wes-Kazakstan-tyd#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreaanse dagligtyd#,
				'generic' => q#Koreaanse tyd#,
				'standard' => q#Koreaanse standaardtyd#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae-tyd#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-somertyd#,
				'generic' => q#Krasnojarsk-tyd#,
				'standard' => q#Krasnojarsk-standaardtyd#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan-tyd#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line-eilande-tyd#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe-dagligtyd#,
				'generic' => q#Lord Howe-tyd#,
				'standard' => q#Lord Howe-standaardtyd#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie-eiland-tyd#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-somertyd#,
				'generic' => q#Magadan-tyd#,
				'standard' => q#Magadan-standaardtyd#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Maleisië-tyd#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maledive-tyd#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas-tyd#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalleilande-tyd#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius-somertyd#,
				'generic' => q#Mauritius-tyd#,
				'standard' => q#Mauritius-standaardtyd#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-tyd#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Noordwes-Meksiko-dagligtyd#,
				'generic' => q#Noordwes-Meksiko-tyd#,
				'standard' => q#Noordwes-Meksiko-standaardtyd#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksikaanse Pasifiese dagligtyd#,
				'generic' => q#Meksikaanse Pasifiese tyd#,
				'standard' => q#Meksikaanse Pasifiese standaardtyd#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar-somertyd#,
				'generic' => q#Ulaanbaatar-tyd#,
				'standard' => q#Ulaanbaatar-standaardtyd#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskou-somertyd#,
				'generic' => q#Moskou-tyd#,
				'standard' => q#Moskou-standaardtyd#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mianmar-tyd#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru-tyd#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal-tyd#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nieu-Kaledonië-somertyd#,
				'generic' => q#Nieu-Kaledonië-tyd#,
				'standard' => q#Nieu-Kaledonië-standaardtyd#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nieu-Seeland-dagligtyd#,
				'generic' => q#Nieu-Seeland-tyd#,
				'standard' => q#Nieu-Seeland-standaardtyd#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland-dagligtyd#,
				'generic' => q#Newfoundland-tyd#,
				'standard' => q#Newfoundland-standaardtyd#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue-tyd#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolkeiland-tyd#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-somertyd#,
				'generic' => q#Fernando de Noronha-tyd#,
				'standard' => q#Fernando de Noronha-standaardtyd#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk-somertyd#,
				'generic' => q#Novosibirsk-tyd#,
				'standard' => q#Novosibirsk-standaardtyd#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-somertyd#,
				'generic' => q#Omsk-tyd#,
				'standard' => q#Omsk-standaardtyd#,
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
			exemplarCity => q#Paas#,
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
			exemplarCity => q#Fidji#,
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
			exemplarCity => q#Nouméa#,
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
			exemplarCity => q#Mata-Utu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan-somertyd#,
				'generic' => q#Pakistan-tyd#,
				'standard' => q#Pakistan-standaardtyd#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau-tyd#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papoea-Nieu-Guinee-tyd#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay-somertyd#,
				'generic' => q#Paraguay-tyd#,
				'standard' => q#Paraguay-standaardtyd#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru-somertyd#,
				'generic' => q#Peru-tyd#,
				'standard' => q#Peru-standaardtyd#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippynse somertyd#,
				'generic' => q#Filippynse tyd#,
				'standard' => q#Filippynse standaardtyd#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fenikseilande-tyd#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sint-Pierre en Miquelon-dagligtyd#,
				'generic' => q#Sint-Pierre en Miquelon-tyd#,
				'standard' => q#Sint-Pierre en Miquelon-standaardtyd#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn-tyd#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape-tyd#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang-tyd#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion-tyd#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-tyd#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin-somertyd#,
				'generic' => q#Sakhalin-tyd#,
				'standard' => q#Sakhalin-standaardtyd#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-dagligtyd#,
				'generic' => q#Samara-tyd#,
				'standard' => q#Samara-standaardtyd#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa-dagligtyd#,
				'generic' => q#Samoa-tyd#,
				'standard' => q#Samoa-standaardtyd#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelle-tyd#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapoer-standaardtyd#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonseilande-tyd#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Suid-Georgië-tyd#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname-tyd#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-tyd#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti-tyd#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei-dagligtyd#,
				'generic' => q#Taipei-tyd#,
				'standard' => q#Taipei-standaardtyd#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadjikistan-tyd#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-tyd#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga-somertyd#,
				'generic' => q#Tonga-tyd#,
				'standard' => q#Tonga-standaardtyd#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-tyd#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan-somertyd#,
				'generic' => q#Turkmenistan-tyd#,
				'standard' => q#Turkmenistan-standaardtyd#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu-tyd#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay-somertyd#,
				'generic' => q#Uruguay-tyd#,
				'standard' => q#Uruguay-standaardtyd#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oesbekistan-somertyd#,
				'generic' => q#Oesbekistan-tyd#,
				'standard' => q#Oesbekistan-standaardtyd#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu-somertyd#,
				'generic' => q#Vanuatu-tyd#,
				'standard' => q#Vanuatu-standaardtyd#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela-tyd#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostok-somertyd#,
				'generic' => q#Wladiwostok-tyd#,
				'standard' => q#Wladiwostok-standaardtyd#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd-somertyd#,
				'generic' => q#Wolgograd-tyd#,
				'standard' => q#Wolgograd-standaardtyd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok-tyd#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake-eiland-tyd#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis en Futuna-tyd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakoetsk-somertyd#,
				'generic' => q#Jakoetsk-tyd#,
				'standard' => q#Jakoetsk-standaardtyd#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg-somertyd#,
				'generic' => q#Jekaterinburg-tyd#,
				'standard' => q#Jekaterinburg-standaardtyd#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
