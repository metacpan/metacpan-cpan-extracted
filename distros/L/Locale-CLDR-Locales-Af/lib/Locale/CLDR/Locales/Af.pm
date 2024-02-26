=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Af - Package for language Afrikaans

=cut

package Locale::CLDR::Locales::Af;
# This file auto generated from Data\common\main\af.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Arabies',
 				'ar_001' => 'Moderne Standaardarabies',
 				'arc' => 'Aramees',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'ars' => 'Najdi-Arabies',
 				'as' => 'Assamees',
 				'asa' => 'Asu',
 				'ast' => 'Asturies',
 				'atj' => 'Atikamekw',
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
 				'bgc' => 'Haryanvi',
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
 				'cay' => 'Cayuga',
 				'ccp' => 'Tsjaakma',
 				'ce' => 'Tsjetsjeens',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Kiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chuukees',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokees',
 				'chy' => 'Cheyennees',
 				'ckb' => 'Sorani',
 				'ckb@alt=variant' => 'Koerdies Sorani',
 				'clc' => 'Tzilkotin',
 				'co' => 'Korsikaans',
 				'cop' => 'Kopties',
 				'crg' => 'Michif',
 				'crj' => 'Suidoos-Cree',
 				'crk' => 'Laagvlakte-Cree',
 				'crl' => 'Noordoos-Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina-Algonkin',
 				'crs' => 'Seselwa Franskreools',
 				'cs' => 'Tsjeggies',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Kerkslawies',
 				'cv' => 'Chuvash',
 				'cy' => 'Wallies',
 				'da' => 'Deens',
 				'dak' => 'Dakotaans',
 				'dar' => 'Dakota',
 				'dav' => 'Taita',
 				'de' => 'Duits',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
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
 				'en_US' => 'Engels (VSA)',
 				'eo' => 'Esperanto',
 				'es' => 'Spaans',
 				'et' => 'Estnies',
 				'eu' => 'Baskies',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persies',
 				'fa_AF' => 'Dari',
 				'ff' => 'Fulah',
 				'fi' => 'Fins',
 				'fil' => 'Filippyns',
 				'fj' => 'Fidjiaans',
 				'fo' => 'Faroëes',
 				'fon' => 'Fon',
 				'fr' => 'Frans',
 				'frc' => 'Cajun',
 				'frr' => 'Noord-Fries',
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
 				'hai' => 'Haida',
 				'hak' => 'Hakka-Sjinees',
 				'haw' => 'Hawais',
 				'hax' => 'Suid-Haida',
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
 				'hur' => 'Halkomelem',
 				'hy' => 'Armeens',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Ibanees',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesies',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Wes-Kanadese Inoektitoet',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Yslands',
 				'it' => 'Italiaans',
 				'iu' => 'Inoektitoet',
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
 				'kgp' => 'Kaingang',
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
 				'kwk' => 'Kwak’wala',
 				'ky' => 'Kirgisies',
 				'la' => 'Latyn',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lb' => 'Luxemburgs',
 				'lez' => 'Lezghies',
 				'lg' => 'Ganda',
 				'li' => 'Limburgs',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingaals',
 				'lo' => 'Lao',
 				'lou' => 'Louisiana Kreool',
 				'loz' => 'Lozi',
 				'lrc' => 'Noord-Luri',
 				'lsm' => 'Saamia',
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
 				'moe' => 'Innu-aimun',
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
 				'nds' => 'Nederduits',
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
 				'ojb' => 'Noordwes-Ojibwa',
 				'ojc' => 'Sentraal-Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Wes-Ojibwa',
 				'oka' => 'Okanagan',
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
 				'pis' => 'Pijin',
 				'pl' => 'Pools',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Pruisies',
 				'ps' => 'Pasjtoe',
 				'pt' => 'Portugees',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongaans',
 				'rhg' => 'Rohingya',
 				'rm' => 'Reto-Romaans',
 				'rn' => 'Rundi',
 				'ro' => 'Roemeens',
 				'rof' => 'Rombo',
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
 				'slh' => 'Suid-Lushootseed',
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
 				'str' => 'Straits Salish',
 				'su' => 'Sundanees',
 				'suk' => 'Sukuma',
 				'sv' => 'Sweeds',
 				'sw' => 'Swahili',
 				'swb' => 'Comoraans',
 				'syr' => 'Siries',
 				'ta' => 'Tamil',
 				'tce' => 'Suid-Tutchone',
 				'te' => 'Teloegoe',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetoem',
 				'tg' => 'Tadjiks',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmeens',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Tongaans',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turks',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tataars',
 				'ttm' => 'Noord-Tutchone',
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
 				'und' => 'Onbekende taal',
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
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonees',
 				'yue@alt=menu' => 'Kantonese Chinees',
 				'zgh' => 'Standaard Marokkaanse Tamazight',
 				'zh' => 'Chinees',
 				'zh@alt=menu' => 'Mandarynse Chinees',
 				'zh_Hans@alt=long' => 'Mandarynse Chinees (Vereenvoudigd)',
 				'zh_Hant@alt=long' => 'Mandarynse Chinees (Tradisioneel)',
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
			'Adlm' => 'Adlam',
 			'Arab' => 'Arabies',
 			'Arab@alt=variant' => 'Perso-Arabies',
 			'Aran' => 'Nastaliq',
 			'Armn' => 'Armeens',
 			'Beng' => 'Bengaals',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Verenigde Kanadese Inheemse Lettergreepskrif',
 			'Cher' => 'Cherokee',
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
 			'Hanb' => 'Han met Bopomofo',
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
 			'Mtei' => 'Meitei-Majek',
 			'Mymr' => 'Mianmar',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Oriya',
 			'Phnx' => 'Fenisieses',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Sinhala',
 			'Sund' => 'Soendanees',
 			'Syrc' => 'Siries',
 			'Taml' => 'Tamil',
 			'Telu' => 'Teloegoe',
 			'Tfng' => 'Tifinagh',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibettaans',
 			'Ugar' => 'Ugaritieses',
 			'Vaii' => 'Vai',
 			'Visp' => 'Visible Speech-karakters',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Wiskundige notasie',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbole',
 			'Zxxx' => 'Ongeskrewe',
 			'Zyyy' => 'Gemeenskaplik',
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
 			'CN' => 'China',
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
 			'HK' => 'Hongkong SAS China',
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
 			'MK' => 'Noord-Macedonië',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birma)',
 			'MN' => 'Mongolië',
 			'MO' => 'Macau SAS China',
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
 			'PS' => 'Palestynse Grondgebiede',
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
 			'SJ' => 'Spitsbergen en Jan Mayen',
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
 			'SZ' => 'Eswatini',
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
 			'XA' => 'Pseudoaksente',
 			'XB' => 'Pseudotweerigting',
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
 			'colalternate' => 'Ignoreer simboolrangskikking',
 			'colbackwards' => 'Omgekeerde aksentrangskikking',
 			'colcasefirst' => 'Hoofletter-/kleinletter-rangskikking',
 			'colcaselevel' => 'Kassensitiewe rangskikking',
 			'collation' => 'Rangskikvolgorde',
 			'colnormalization' => 'Genormaliseerde rangskikking',
 			'colnumeric' => 'Numeriese rangskikking',
 			'colstrength' => 'Rangskiksterkte',
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
 				'chinese' => q{Chinese kalender},
 				'coptic' => q{Koptiese kalender},
 				'dangi' => q{Dangi-kalender},
 				'ethiopic' => q{Etiopiese kalender},
 				'ethiopic-amete-alem' => q{Etiopiese Amete Alem-kalender},
 				'gregorian' => q{Gregoriaanse kalender},
 				'hebrew' => q{Hebreeuse kalender},
 				'indian' => q{Indiese nasionale kalender},
 				'islamic' => q{Islamitiese kalender},
 				'islamic-civil' => q{Islamitiese siviele kalender},
 				'islamic-umalqura' => q{Islamitiese kalender (Umm al-Qura)},
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
 				'cakm' => q{Chakma-syfers},
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
 				'java' => q{Javaanse syfers},
 				'jpan' => q{Japannese syfers},
 				'jpanfin' => q{Japannese finansiële syfers},
 				'khmr' => q{Khmer-syfers},
 				'knda' => q{Kannada-syfers},
 				'laoo' => q{Lao-syfers},
 				'latn' => q{Westerse syfers},
 				'mlym' => q{Malabaarse syfers},
 				'mong' => q{Mongoliese syfers},
 				'mtei' => q{Meetei Mayak-syfers},
 				'mymr' => q{Mianmar-syfers},
 				'native' => q{Inheemse syfers},
 				'olck' => q{Ol Chiki-syfers},
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
			auxiliary => qr{[àåäã æ ç íì óò úùü ý]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aáâ b c d eéèêë f g h iîï j k l m n oôö p q r s t uû v w x y z]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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
					# Long Unit Identifier
					'' => {
						'name' => q(kompasrigting),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kompasrigting),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
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
						'one' => q({0} swaartekrag),
						'other' => q({0} swaartekrag),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} swaartekrag),
						'other' => q({0} swaartekrag),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter per vierkante sekonde),
						'one' => q({0} meter per vierkante sekonde),
						'other' => q({0} meter per vierkante sekonde),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter per vierkante sekonde),
						'one' => q({0} meter per vierkante sekonde),
						'other' => q({0} meter per vierkante sekonde),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} boogminuut),
						'other' => q({0} boogminute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} boogminuut),
						'other' => q({0} boogminute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} boogsekonde),
						'other' => q({0} boogsekondes),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} boogsekonde),
						'other' => q({0} boogsekondes),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} graad),
						'other' => q({0} grade),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} graad),
						'other' => q({0} grade),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radiaal),
						'other' => q({0} radiale),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radiaal),
						'other' => q({0} radiale),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(omwenteling),
						'one' => q({0} omwenteling),
						'other' => q({0} omwentelings),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(omwenteling),
						'one' => q({0} omwenteling),
						'other' => q({0} omwentelings),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hektaar),
						'other' => q({0} hektaar),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hektaar),
						'other' => q({0} hektaar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(vierkante sentimeter),
						'one' => q({0} vierkante sentimeter),
						'other' => q({0} vierkante sentimeter),
						'per' => q({0} per vierkante sentimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(vierkante sentimeter),
						'one' => q({0} vierkante sentimeter),
						'other' => q({0} vierkante sentimeter),
						'per' => q({0} per vierkante sentimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(vierkante duim),
						'one' => q({0} vierkante duim),
						'other' => q({0} vierkante duim),
						'per' => q({0} per vierkante duim),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(vierkante duim),
						'one' => q({0} vierkante duim),
						'other' => q({0} vierkante duim),
						'per' => q({0} per vierkante duim),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(vierkante myl),
						'one' => q({0} vierkante myl),
						'other' => q({0} vierkante myl),
						'per' => q({0} per vierkante myl),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(vierkante myl),
						'one' => q({0} vierkante myl),
						'other' => q({0} vierkante myl),
						'per' => q({0} per vierkante myl),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(vierkante jaart),
						'one' => q({0} vierkante jaart),
						'other' => q({0} vierkante jaart),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(vierkante jaart),
						'one' => q({0} vierkante jaart),
						'other' => q({0} vierkante jaart),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(items),
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(items),
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(persent),
						'one' => q({0} persent),
						'other' => q({0} persent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(persent),
						'one' => q({0} persent),
						'other' => q({0} persent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} per duisend),
						'other' => q({0} per duisend),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} per duisend),
						'other' => q({0} per duisend),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(dele per miljoen),
						'one' => q({0} deel per miljoen),
						'other' => q({0} dele per miljoen),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(dele per miljoen),
						'one' => q({0} deel per miljoen),
						'other' => q({0} dele per miljoen),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} per tienduisend),
						'other' => q({0} per tienduisend),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} per tienduisend),
						'other' => q({0} per tienduisend),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(myl per VSA-gelling),
						'one' => q({0} myl per VSA-gelling),
						'other' => q({0} myl per VSA-gelling),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(myl per VSA-gelling),
						'one' => q({0} myl per VSA-gelling),
						'other' => q({0} myl per VSA-gelling),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(myl per Britse gelling),
						'one' => q({0} myl per Britse gelling),
						'other' => q({0} myl per Britse gelling),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(myl per Britse gelling),
						'one' => q({0} myl per Britse gelling),
						'other' => q({0} myl per Britse gelling),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} oos),
						'north' => q({0} noord),
						'south' => q({0} suid),
						'west' => q({0} wes),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} oos),
						'north' => q({0} noord),
						'south' => q({0} suid),
						'west' => q({0} wes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabis),
						'one' => q({0} gigabis),
						'other' => q({0} gigabis),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabis),
						'one' => q({0} gigabis),
						'other' => q({0} gigabis),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigagreep),
						'one' => q({0} gigagreep),
						'other' => q({0} gigagreep),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigagreep),
						'one' => q({0} gigagreep),
						'other' => q({0} gigagreep),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobis),
						'one' => q({0} kilobis),
						'other' => q({0} kilobis),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobis),
						'one' => q({0} kilobis),
						'other' => q({0} kilobis),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilogreep),
						'one' => q({0} kilogreep),
						'other' => q({0} kilogreep),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilogreep),
						'one' => q({0} kilogreep),
						'other' => q({0} kilogreep),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabis),
						'one' => q({0} megabis),
						'other' => q({0} megabis),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabis),
						'one' => q({0} megabis),
						'other' => q({0} megabis),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megagreep),
						'one' => q({0} megagreep),
						'other' => q({0} megagreep),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megagreep),
						'one' => q({0} megagreep),
						'other' => q({0} megagreep),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petagreep),
						'one' => q({0} petagreep),
						'other' => q({0} petagreep),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petagreep),
						'one' => q({0} petagreep),
						'other' => q({0} petagreep),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabis),
						'one' => q({0} terabis),
						'other' => q({0} terabis),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabis),
						'one' => q({0} terabis),
						'other' => q({0} terabis),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(teragreep),
						'one' => q({0} teragreep),
						'other' => q({0} teragreep),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(teragreep),
						'one' => q({0} teragreep),
						'other' => q({0} teragreep),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(eeu),
						'one' => q({0} eeu),
						'other' => q({0} eeue),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(eeu),
						'one' => q({0} eeu),
						'other' => q({0} eeue),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} per dag),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} per dag),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekades),
						'one' => q({0} dekade),
						'other' => q({0} dekades),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekades),
						'one' => q({0} dekade),
						'other' => q({0} dekades),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0} per uur),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0} per uur),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekondes),
						'one' => q({0} mikrosekonde),
						'other' => q({0} mikrosekondes),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekondes),
						'one' => q({0} mikrosekonde),
						'other' => q({0} mikrosekondes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekondes),
						'one' => q({0} millisekonde),
						'other' => q({0} millisekondes),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekondes),
						'one' => q({0} millisekonde),
						'other' => q({0} millisekondes),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minute),
						'one' => q({0} minuut),
						'other' => q({0} minute),
						'per' => q({0} per minuut),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minute),
						'one' => q({0} minuut),
						'other' => q({0} minute),
						'per' => q({0} per minuut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} maand),
						'other' => q({0} maande),
						'per' => q({0}/maand),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} maand),
						'other' => q({0} maande),
						'per' => q({0}/maand),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekondes),
						'one' => q({0} nanosekonde),
						'other' => q({0} nanosekondes),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekondes),
						'one' => q({0} nanosekonde),
						'other' => q({0} nanosekondes),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwartale),
						'one' => q({0} kwartaal),
						'other' => q({0} kwartale),
						'per' => q({0}/kwartaal),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwartale),
						'one' => q({0} kwartaal),
						'other' => q({0} kwartale),
						'per' => q({0}/kwartaal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekondes),
						'one' => q({0} sekonde),
						'other' => q({0} sekondes),
						'per' => q({0} per sekonde),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekondes),
						'one' => q({0} sekonde),
						'other' => q({0} sekondes),
						'per' => q({0} per sekonde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} week),
						'other' => q({0} weke),
						'per' => q({0} per week),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} week),
						'other' => q({0} weke),
						'per' => q({0} per week),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
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
						'name' => q(Britse termiese eenhede),
						'one' => q({0} Britse termiese eenheid),
						'other' => q({0} Britse termiese eenhede),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Britse termiese eenhede),
						'one' => q({0} Britse termiese eenheid),
						'other' => q({0} Britse termiese eenhede),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalorieë),
						'one' => q({0} kalorie),
						'other' => q({0} kalorieë),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalorieë),
						'one' => q({0} kalorie),
						'other' => q({0} kalorieë),
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
					'energy-foodcalorie' => {
						'name' => q(Kalorieë),
						'one' => q({0} kalorie),
						'other' => q({0} kalorieë),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalorieë),
						'one' => q({0} kalorie),
						'other' => q({0} kalorieë),
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
						'name' => q(kilokalorieë),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorieë),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalorieë),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorieë),
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
						'name' => q(kilowatt-uur),
						'one' => q({0} kilowatt-uur),
						'other' => q({0} kilowatt-uur),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-uur),
						'one' => q({0} kilowatt-uur),
						'other' => q({0} kilowatt-uur),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(VSA- termiese eenhede),
						'one' => q({0} VSA- termiese eenheid),
						'other' => q({0} VSA- termiese eenhede),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(VSA- termiese eenhede),
						'one' => q({0} VSA- termiese eenheid),
						'other' => q({0} VSA- termiese eenhede),
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
						'one' => q({0} pondkrag),
						'other' => q({0} pondkrag),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} pondkrag),
						'other' => q({0} pondkrag),
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
					'graphics-dot' => {
						'one' => q({0} stippel),
						'other' => q({0} stippels),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} stippel),
						'other' => q({0} stippels),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(stippels per sentimeter),
						'one' => q({0} stippel per sentimeter),
						'other' => q({0} stippels per sentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(stippels per sentimeter),
						'one' => q({0} stippel per sentimeter),
						'other' => q({0} stippels per sentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(stippels per duim),
						'one' => q({0} stippel per duim),
						'other' => q({0} stippels per duim),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(stippels per duim),
						'one' => q({0} stippel per duim),
						'other' => q({0} stippels per duim),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografiese em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografiese em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapieksel),
						'other' => q({0} megapieksels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapieksel),
						'other' => q({0} megapieksels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} pieksel),
						'other' => q({0} pieksels),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} pieksel),
						'other' => q({0} pieksels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pieksels per sentimeter),
						'one' => q({0} pieksel per sentimeter),
						'other' => q({0} pieksels per sentimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pieksels per sentimeter),
						'one' => q({0} pieksel per sentimeter),
						'other' => q({0} pieksels per sentimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pieksels per duim),
						'one' => q({0} pieksel per duim),
						'other' => q({0} pieksels per duim),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pieksels per duim),
						'one' => q({0} pieksel per duim),
						'other' => q({0} pieksels per duim),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiese eenhede),
						'one' => q({0} astronomiese eenheid),
						'other' => q({0} astronomiese eenhede),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiese eenhede),
						'one' => q({0} astronomiese eenheid),
						'other' => q({0} astronomiese eenhede),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'one' => q({0} sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'one' => q({0} sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(aardstraal),
						'one' => q({0} aardstraal),
						'other' => q({0} aardstraal),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(aardstraal),
						'one' => q({0} aardstraal),
						'other' => q({0} aardstraal),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0} per duim),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0} per duim),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} ligjaar),
						'other' => q({0} ligjare),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} ligjaar),
						'other' => q({0} ligjare),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Skandinawiese myl),
						'one' => q({0} Skandinawiese myl),
						'other' => q({0} Skandinawiese myl),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Skandinawiese myl),
						'one' => q({0} Skandinawiese myl),
						'other' => q({0} Skandinawiese myl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(seemyl),
						'one' => q({0} seemyl),
						'other' => q({0} seemyl),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(seemyl),
						'one' => q({0} seemyl),
						'other' => q({0} seemyl),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} punt),
						'other' => q({0} punte),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} punt),
						'other' => q({0} punte),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} sonradius),
						'other' => q({0} sonradiusse),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} sonradius),
						'other' => q({0} sonradiusse),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} jaart),
						'other' => q({0} jaart),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} jaart),
						'other' => q({0} jaart),
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
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} sonligsterkte),
						'other' => q({0} sonligsterkte),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} sonligsterkte),
						'other' => q({0} sonligsterkte),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} karaat),
						'other' => q({0} karaat),
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
						'one' => q({0} aardemassa),
						'other' => q({0} aardemassas),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} aardemassa),
						'other' => q({0} aardemassas),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(onse),
						'one' => q({0} ons),
						'other' => q({0} onse),
						'per' => q({0} per ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(onse),
						'one' => q({0} ons),
						'other' => q({0} onse),
						'per' => q({0} per ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy-onse),
						'one' => q({0} troy-ons),
						'other' => q({0} troy-onse),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy-onse),
						'one' => q({0} troy-ons),
						'other' => q({0} troy-onse),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} pond),
						'other' => q({0} pond),
						'per' => q({0} per pond),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} pond),
						'other' => q({0} pond),
						'per' => q({0} per pond),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} sonmassa),
						'other' => q({0} sonmassas),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} sonmassa),
						'other' => q({0} sonmassas),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} VSA-ton),
						'other' => q({0} VSA-ton),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} VSA-ton),
						'other' => q({0} VSA-ton),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrieke ton),
						'one' => q({0} metrieke ton),
						'other' => q({0} metrieke ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrieke ton),
						'one' => q({0} metrieke ton),
						'other' => q({0} metrieke ton),
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
						'name' => q(perdekrag),
						'one' => q({0} perdekrag),
						'other' => q({0} perdekrag),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(perdekrag),
						'one' => q({0} perdekrag),
						'other' => q({0} perdekrag),
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
						'1' => q(vierkante {0}),
						'one' => q(vierkante {0}),
						'other' => q(vierkante {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(vierkante {0}),
						'one' => q(vierkante {0}),
						'other' => q(vierkante {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kubieke {0}),
						'one' => q(kubieke {0}),
						'other' => q(kubieke {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubieke {0}),
						'one' => q(kubieke {0}),
						'other' => q(kubieke {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfere),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfere),
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
						'name' => q(duim kwik),
						'one' => q({0} duim kwik),
						'other' => q({0} duim kwik),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(duim kwik),
						'one' => q({0} duim kwik),
						'other' => q({0} duim kwik),
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
						'name' => q(millimeter kwik),
						'one' => q({0} millimeter kwik),
						'other' => q({0} millimeter kwik),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimeter kwik),
						'one' => q({0} millimeter kwik),
						'other' => q({0} millimeter kwik),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascals),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascals),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pond per vierkante duim),
						'one' => q({0} pond per vierkante duim),
						'other' => q({0} pond per vierkante duim),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pond per vierkante duim),
						'one' => q({0} pond per vierkante duim),
						'other' => q({0} pond per vierkante duim),
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
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knope),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knope),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter per sekonde),
						'one' => q({0} meter per sekonde),
						'other' => q({0} meter per sekonde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter per sekonde),
						'one' => q({0} meter per sekonde),
						'other' => q({0} meter per sekonde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} myl per uur),
						'other' => q({0} myl per uur),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} myl per uur),
						'other' => q({0} myl per uur),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grade Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} grade Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grade Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} grade Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grade Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} grade Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grade Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} grade Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} graad),
						'other' => q({0} graad),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} graad),
						'other' => q({0} graad),
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
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pondvoet),
						'one' => q({0} pondvoetkrag),
						'other' => q({0} pondvoet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pondvoet),
						'one' => q({0} pondvoetkrag),
						'other' => q({0} pondvoet),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} acre-voet),
						'other' => q({0} acre-voet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} acre-voet),
						'other' => q({0} acre-voet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(vate),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(vate),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliter),
						'one' => q({0} sentiliter),
						'other' => q({0} sentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliter),
						'one' => q({0} sentiliter),
						'other' => q({0} sentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kubieke sentimeters),
						'one' => q({0} kubieke sentimeter),
						'other' => q({0} kubieke sentimeters),
						'per' => q({0} per kubieke sentimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kubieke sentimeters),
						'one' => q({0} kubieke sentimeter),
						'other' => q({0} kubieke sentimeters),
						'per' => q({0} per kubieke sentimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} kubieke voet),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} kubieke voet),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubieke duime),
						'one' => q({0} kubieke duim),
						'other' => q({0} kubieke duim),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubieke duime),
						'one' => q({0} kubieke duim),
						'other' => q({0} kubieke duim),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubieke kilometers),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometers),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubieke kilometers),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometers),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kubieke meters),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meters),
						'per' => q({0} per kubieke meter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kubieke meters),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meters),
						'per' => q({0} per kubieke meter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubieke myle),
						'one' => q({0} kubieke myl),
						'other' => q({0} kubieke myle),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubieke myle),
						'one' => q({0} kubieke myl),
						'other' => q({0} kubieke myle),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubieke jaart),
						'one' => q({0} kubieke jaart),
						'other' => q({0} kubieke jaart),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubieke jaart),
						'one' => q({0} kubieke jaart),
						'other' => q({0} kubieke jaart),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koppies),
						'one' => q({0} koppie),
						'other' => q({0} koppies),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koppies),
						'one' => q({0} koppie),
						'other' => q({0} koppies),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrieke koppies),
						'one' => q({0} metrieke koppie),
						'other' => q({0} metrieke koppies),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrieke koppies),
						'one' => q({0} metrieke koppie),
						'other' => q({0} metrieke koppies),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessertlepel),
						'one' => q({0} dessertlepel),
						'other' => q({0} dessertlepel),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessertlepel),
						'one' => q({0} dessertlepel),
						'other' => q({0} dessertlepel),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Engelse dessertlepel),
						'one' => q({0} Engelse dessertlepel),
						'other' => q({0} Engelse dessertlepel),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Engelse dessertlepel),
						'one' => q({0} Engelse dessertlepel),
						'other' => q({0} Engelse dessertlepel),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dragme),
						'one' => q({0} dragme),
						'other' => q({0} dragme),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dragme),
						'one' => q({0} dragme),
						'other' => q({0} dragme),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(vloeistofons),
						'one' => q({0} vloeistofons),
						'other' => q({0} vloeistofons),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(vloeistofons),
						'one' => q({0} vloeistofons),
						'other' => q({0} vloeistofons),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. vloeistofonse),
						'one' => q({0} Imp. vloeistofons),
						'other' => q({0} Imp. vloeistofonse),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. vloeistofonse),
						'one' => q({0} Imp. vloeistofons),
						'other' => q({0} Imp. vloeistofonse),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gelling),
						'one' => q({0} gelling),
						'other' => q({0} gelling),
						'per' => q({0} per gelling),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gelling),
						'one' => q({0} gelling),
						'other' => q({0} gelling),
						'per' => q({0} per gelling),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Britse gelling),
						'one' => q({0} Britse gelling),
						'other' => q({0} Britse gelling),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Britse gelling),
						'one' => q({0} Britse gelling),
						'other' => q({0} Britse gelling),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliters),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliters),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliters),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliters),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliters),
						'one' => q({0} megaliter),
						'other' => q({0} megaliters),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliters),
						'one' => q({0} megaliter),
						'other' => q({0} megaliters),
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
						'one' => q({0} pint),
						'other' => q({0} pinte),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pint),
						'other' => q({0} pinte),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrieke pinte),
						'one' => q({0} metrieke pint),
						'other' => q({0} metrieke pinte),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrieke pinte),
						'one' => q({0} metrieke pint),
						'other' => q({0} metrieke pinte),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kwartgellings),
						'one' => q({0} kwartgelling),
						'other' => q({0} kwartgellings),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kwartgellings),
						'one' => q({0} kwartgelling),
						'other' => q({0} kwartgellings),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kwartgelling),
						'one' => q({0} Engelse kwartgelling),
						'other' => q({0} Engelse kwartgelling),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kwartgelling),
						'one' => q({0} Engelse kwartgelling),
						'other' => q({0} Engelse kwartgelling),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(eetlepels),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(eetlepels),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(teelepels),
						'one' => q({0} teelepel),
						'other' => q({0} teelepels),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(teelepels),
						'one' => q({0} teelepel),
						'other' => q({0} teelepels),
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
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(boogmin.),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(boogmin.),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(boogsek.),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(boogsek.),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gr.),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gr.),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad.),
						'one' => q({0}rad.),
						'other' => q({0}rad.),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad.),
						'one' => q({0}rad.),
						'other' => q({0}rad.),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0}omw.),
						'other' => q({0}omw.),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}omw.),
						'other' => q({0}omw.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0}donum),
						'other' => q({0}donum),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0}donum),
						'other' => q({0}donum),
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
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0}vt.²),
						'other' => q({0}vt.²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}vt.²),
						'other' => q({0}vt.²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}dm.²),
						'other' => q({0}dm.²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}dm.²),
						'other' => q({0}dm.²),
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
						'name' => q(meters²),
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meters²),
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}myl²),
						'other' => q({0}myl²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}myl²),
						'other' => q({0}myl²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}jt.²),
						'other' => q({0}jt.²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}jt.²),
						'other' => q({0}jt.²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0}item),
						'other' => q({0}item),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0}item),
						'other' => q({0}item),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}kar.),
						'other' => q({0}kar.),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}kar.),
						'other' => q({0}kar.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
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
						'name' => q(d.p.m.),
						'one' => q({0}d.p.m.),
						'other' => q({0} d.p.m.),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(d.p.m.),
						'one' => q({0}d.p.m.),
						'other' => q({0} d.p.m.),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}l/100 km),
						'other' => q({0}l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}l/100 km),
						'other' => q({0}l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(m.p.VSA-g.),
						'one' => q({0}m.p.g.),
						'other' => q({0}m.p.g.),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(m.p.VSA-g.),
						'one' => q({0}m.p.g.),
						'other' => q({0}m.p.g.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(m/Br.gell.),
						'one' => q({0}m/Br.g.),
						'other' => q({0}m/Br.g.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(m/Br.gell.),
						'one' => q({0}m/Br.g.),
						'other' => q({0}m/Br.g.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}bis),
						'other' => q({0}bis),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bis),
						'other' => q({0}bis),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0}greep),
						'other' => q({0}greep),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0}greep),
						'other' => q({0}greep),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}e.),
						'other' => q({0}e.),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}e.),
						'other' => q({0}e.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dag),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dag),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}dek.),
						'other' => q({0}dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}dek.),
						'other' => q({0}dek.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs.),
						'other' => q({0}μs.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs.),
						'other' => q({0}μs.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms.),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms.),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(maand),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(maand),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns.),
						'other' => q({0}ns.),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns.),
						'other' => q({0}ns.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(w.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(w.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(j.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(j.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}BTE),
						'other' => q({0}BTE),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}BTE),
						'other' => q({0}BTE),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}kal.),
						'other' => q({0}kal.),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}kal.),
						'other' => q({0}kal.),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}kal.),
						'other' => q({0}kal.),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}kal.),
						'other' => q({0}kal.),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kkal.),
						'other' => q({0}kkal.),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kkal.),
						'other' => q({0}kkal.),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}VSA-term.),
						'other' => q({0}VSA-term.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}VSA-term.),
						'other' => q({0}VSA-term.),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lb.-krag),
						'one' => q({0}lb.-krag),
						'other' => q({0}lb.-krag),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lb.-krag),
						'one' => q({0}lb.-krag),
						'other' => q({0}lb.-krag),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(stippel),
						'one' => q({0}stippel),
						'other' => q({0}stippel),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(stippel),
						'one' => q({0}stippel),
						'other' => q({0}stippel),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}vaam),
						'other' => q({0}vaam),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}vaam),
						'other' => q({0}vaam),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}vt.),
						'other' => q({0}vt.),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}vt.),
						'other' => q({0}vt.),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
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
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0}myl),
						'other' => q({0}myl),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}myl),
						'other' => q({0}myl),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}sm.),
						'other' => q({0}sm.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}sm.),
						'other' => q({0}sm.),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
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
					'length-point' => {
						'name' => q(pte.),
						'one' => q({0}pt.),
						'other' => q({0}pt.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pte.),
						'one' => q({0}pt.),
						'other' => q({0}pt.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0}jt.),
						'other' => q({0}jt.),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0}jt.),
						'other' => q({0}jt.),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0}kar.),
						'other' => q({0}kar.),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}kar.),
						'other' => q({0}kar.),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0}korrelg.),
						'other' => q({0}korrelg.),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}korrelg.),
						'other' => q({0}korrelg.),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
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
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}ng),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}ng),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}ons.),
						'other' => q({0}ons.),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}ons.),
						'other' => q({0}ons.),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ons.t.),
						'one' => q({0}ons.t.),
						'other' => q({0}ons.t.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ons.t.),
						'one' => q({0}ons.t.),
						'other' => q({0}ons.t.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}VSA-t.),
						'other' => q({0}VSA-t.),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}VSA-t.),
						'other' => q({0}VSA-t.),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}pk.),
						'other' => q({0}pk.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}pk.),
						'other' => q({0}pk.),
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
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
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
					'pressure-atmosphere' => {
						'one' => q({0}atm.),
						'other' => q({0}atm.),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm.),
						'other' => q({0}atm.),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
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
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}lb./vk.dm),
						'other' => q({0}lb./vk.dm),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}lb./vk.dm),
						'other' => q({0}lb./vk.dm),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn.),
						'other' => q({0}kn.),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn.),
						'other' => q({0}kn.),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s.),
						'one' => q({0}m/s.),
						'other' => q({0}m/s.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s.),
						'one' => q({0}m/s.),
						'other' => q({0}m/s.),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(myl/h),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(myl/h),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lb.vt.-kr),
						'other' => q({0}lb.vt.-kr),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lb.vt.-kr),
						'other' => q({0}lb.vt.-kr),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac.-vt.),
						'other' => q({0}ac.-vt.),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac.-vt.),
						'other' => q({0}ac.-vt.),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}vat),
						'other' => q({0}vate),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}vat),
						'other' => q({0}vate),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}sk.),
						'other' => q({0}sk.),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}sk.),
						'other' => q({0}sk.),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(vt³),
						'one' => q({0}vt³),
						'other' => q({0}vt³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(vt³),
						'one' => q({0}vt³),
						'other' => q({0}vt³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(dm³),
						'one' => q({0}dm³),
						'other' => q({0}dm³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(dm³),
						'one' => q({0}dm³),
						'other' => q({0}dm³),
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
					'volume-cubic-mile' => {
						'one' => q({0}myl³),
						'other' => q({0}myl³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}myl³),
						'other' => q({0}myl³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}jt.³),
						'other' => q({0}jt.³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}jt.³),
						'other' => q({0}jt.³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}kp),
						'other' => q({0}kp.),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}kp),
						'other' => q({0}kp.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}m.kop),
						'other' => q({0}m.kop),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}m.kop),
						'other' => q({0}m.kop),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0}dstlpl.),
						'other' => q({0}dstlpl.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}dstlpl.),
						'other' => q({0}dstlpl.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dlpl.Eng),
						'other' => q({0}dlpl.Eng),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dlpl.Eng),
						'other' => q({0}dlpl.Eng),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0}dr.vl.),
						'other' => q({0}dr.vl.),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0}dr.vl.),
						'other' => q({0}dr.vl.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}vl.oz.),
						'other' => q({0}vl.oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}vl.oz.),
						'other' => q({0}vl.oz.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp vl.oz.),
						'one' => q({0}Im.vl.oz.),
						'other' => q({0}Im.vl.oz.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp vl.oz.),
						'one' => q({0}Im.vl.oz.),
						'other' => q({0}Im.vl.oz.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0}gell.),
						'other' => q({0}gell.),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0}gell.),
						'other' => q({0}gell.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0}Br.gell.),
						'other' => q({0}Br.gell.),
						'per' => q({0}/Br.gell.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}Br.gell.),
						'other' => q({0}Br.gell.),
						'per' => q({0}/Br.gell.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0}sopie),
						'other' => q({0}sopies),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}sopie),
						'other' => q({0}sopies),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(kn.),
						'one' => q({0}kn.),
						'other' => q({0}kn.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(kn.),
						'one' => q({0}kn.),
						'other' => q({0}kn.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt.),
						'one' => q({0}pt.),
						'other' => q({0}pt.),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt.),
						'one' => q({0}pt.),
						'other' => q({0}pt.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt.),
						'one' => q({0}mpt.),
						'other' => q({0}mpt.),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt.),
						'one' => q({0}mpt.),
						'other' => q({0}mpt.),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}kw.gell.),
						'other' => q({0}kw.gell.),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}kw.gell.),
						'other' => q({0}kw.gell.),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}kw.Eng.),
						'other' => q({0}kw.Eng),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}kw.Eng.),
						'other' => q({0}kw.Eng),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}e.),
						'other' => q({0}e.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}e.),
						'other' => q({0}e.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tl.),
						'other' => q({0}tl.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tl.),
						'other' => q({0}tl.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(rigting),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(rigting),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(swaartekrag),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(swaartekrag),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(boogminute),
						'one' => q({0} boogmin.),
						'other' => q({0} boogmin.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(boogminute),
						'one' => q({0} boogmin.),
						'other' => q({0} boogmin.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(boogsekondes),
						'one' => q({0} boogsek.),
						'other' => q({0} boogsek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(boogsekondes),
						'one' => q({0} boogsek.),
						'other' => q({0} boogsek.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grade),
						'one' => q({0} gr.),
						'other' => q({0} gr.),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grade),
						'one' => q({0} gr.),
						'other' => q({0} gr.),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiale),
						'one' => q({0} rad.),
						'other' => q({0} rad.),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiale),
						'one' => q({0} rad.),
						'other' => q({0} rad.),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(omw.),
						'one' => q({0} omw.),
						'other' => q({0} omw.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(omw.),
						'one' => q({0} omw.),
						'other' => q({0} omw.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(donum),
						'one' => q({0} donum),
						'other' => q({0} donum),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(donum),
						'one' => q({0} donum),
						'other' => q({0} donum),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektaar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektaar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(vt.²),
						'one' => q({0} vt.²),
						'other' => q({0} vt.²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(vt.²),
						'one' => q({0} vt.²),
						'other' => q({0} vt.²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(duim²),
						'one' => q({0} dm.²),
						'other' => q({0} dm.²),
						'per' => q({0}/dm.²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(duim²),
						'one' => q({0} dm.²),
						'other' => q({0} dm.²),
						'per' => q({0}/dm.²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(myl²),
						'one' => q({0} myl²),
						'other' => q({0} myl²),
						'per' => q({0}/myl²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(myl²),
						'one' => q({0} myl²),
						'other' => q({0} myl²),
						'per' => q({0}/myl²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jaart²),
						'one' => q({0} jt.²),
						'other' => q({0} jt.²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jaart²),
						'one' => q({0} jt.²),
						'other' => q({0} jt.²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
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
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(percent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(percent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per duisend),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per duisend),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(dele/miljoen),
						'one' => q({0} d.p.m.),
						'other' => q({0} d.p.m.),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(dele/miljoen),
						'one' => q({0} d.p.m.),
						'other' => q({0} d.p.m.),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(per tienduisend),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(per tienduisend),
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
						'name' => q(liter/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(myl/VSA-gell.),
						'one' => q({0} m.p.VSA-g.),
						'other' => q({0} m.p.VSA-g.),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(myl/VSA-gell.),
						'one' => q({0} m.p.VSA-g.),
						'other' => q({0} m.p.VSA-g.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(myl/Br. gelling),
						'one' => q({0} myl/Br.g.),
						'other' => q({0} myl/Br.g.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(myl/Br. gelling),
						'one' => q({0} myl/Br.g.),
						'other' => q({0} myl/Br.g.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bis),
						'one' => q({0} bis),
						'other' => q({0} bis),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bis),
						'one' => q({0} bis),
						'other' => q({0} bis),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(greep),
						'one' => q({0} greep),
						'other' => q({0} greep),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(greep),
						'one' => q({0} greep),
						'other' => q({0} greep),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(e.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(e.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dae),
						'one' => q({0} dag),
						'other' => q({0} dae),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dae),
						'one' => q({0} dag),
						'other' => q({0} dae),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(uur),
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(uur),
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs.),
						'one' => q({0} μs.),
						'other' => q({0} μs.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs.),
						'one' => q({0} μs.),
						'other' => q({0} μs.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms.),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms.),
						'other' => q({0} ms),
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
						'name' => q(maande),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(maande),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns.),
						'one' => q({0} ns.),
						'other' => q({0} ns.),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns.),
						'one' => q({0} ns.),
						'other' => q({0} ns.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kwe.),
						'per' => q({0}/kw.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kwe.),
						'per' => q({0}/kw.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s.),
						'one' => q({0} s.),
						'other' => q({0} s.),
						'per' => q({0}/s.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s.),
						'one' => q({0} s.),
						'other' => q({0} s.),
						'per' => q({0}/s.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(weke),
						'one' => q({0} w.),
						'other' => q({0} w.),
						'per' => q({0}/w.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(weke),
						'one' => q({0} w.),
						'other' => q({0} w.),
						'per' => q({0}/w.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(jaar),
						'one' => q({0} j.),
						'other' => q({0} j.),
						'per' => q({0}/j.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jaar),
						'one' => q({0} j.),
						'other' => q({0} j.),
						'per' => q({0}/j.),
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
					'energy-british-thermal-unit' => {
						'name' => q(BTE),
						'one' => q({0} BTE),
						'other' => q({0} BTE),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTE),
						'one' => q({0} BTE),
						'other' => q({0} BTE),
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
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal.),
						'one' => q({0} kkal.),
						'other' => q({0} kkal.),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal.),
						'one' => q({0} kkal.),
						'other' => q({0} kkal.),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(VSA- termiese eenheid),
						'one' => q({0} VSA-term.),
						'other' => q({0} VSA-term.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(VSA- termiese eenheid),
						'one' => q({0} VSA-term.),
						'other' => q({0} VSA-term.),
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
					'force-pound-force' => {
						'name' => q(pondkrag),
						'one' => q({0} lb.-krag),
						'other' => q({0} lb.-krag),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pondkrag),
						'one' => q({0} lb.-krag),
						'other' => q({0} lb.-krag),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(stippels),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(stippels),
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
						'name' => q(megapieksels),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapieksels),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pieksels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pieksels),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(vaam),
						'one' => q({0} vaam),
						'other' => q({0} vaam),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(vaam),
						'one' => q({0} vaam),
						'other' => q({0} vaam),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(voet),
						'one' => q({0} vt.),
						'other' => q({0} vt.),
						'per' => q({0}/vt.),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(voet),
						'one' => q({0} vt.),
						'other' => q({0} vt.),
						'per' => q({0}/vt.),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur.),
						'other' => q({0} fur.),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur.),
						'other' => q({0} fur.),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(duim),
						'one' => q({0} duim),
						'other' => q({0} duim),
						'per' => q({0}/duim),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(duim),
						'one' => q({0} duim),
						'other' => q({0} duim),
						'per' => q({0}/duim),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ligjare),
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ligjare),
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(myl),
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(myl),
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sm.),
						'one' => q({0} sm.),
						'other' => q({0} sm.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sm.),
						'one' => q({0} sm.),
						'other' => q({0} sm.),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sonradiusse),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sonradiusse),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jaart),
						'one' => q({0} jt.),
						'other' => q({0} jt.),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jaart),
						'one' => q({0} jt.),
						'other' => q({0} jt.),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(sonligsterkte),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(sonligsterkte),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karaat),
						'one' => q({0} kar.),
						'other' => q({0} kar.),
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
						'name' => q(aardemassas),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(aardemassas),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(korrelgewig),
						'one' => q({0} korrelgewig),
						'other' => q({0} korrelgewig),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(korrelgewig),
						'one' => q({0} korrelgewig),
						'other' => q({0} korrelgewig),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ons.),
						'one' => q({0} ons.),
						'other' => q({0} ons.),
						'per' => q({0}/ons.),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ons.),
						'one' => q({0} ons.),
						'other' => q({0} ons.),
						'per' => q({0}/ons.),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy-ons),
						'one' => q({0} ons.t.),
						'other' => q({0} ons.t.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy-ons),
						'one' => q({0} ons.t.),
						'other' => q({0} ons.t.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pond),
						'one' => q({0} lb.),
						'other' => q({0} lb.),
						'per' => q({0}/lb.),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pond),
						'one' => q({0} lb.),
						'other' => q({0} lb.),
						'per' => q({0}/lb.),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sonmassas),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sonmassas),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(VSA-ton),
						'one' => q({0} VSA-t.),
						'other' => q({0} VSA-t.),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(VSA-ton),
						'one' => q({0} VSA-t.),
						'other' => q({0} VSA-t.),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(pk.),
						'one' => q({0} pk.),
						'other' => q({0} pk.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(pk.),
						'one' => q({0} pk.),
						'other' => q({0} pk.),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm.),
						'one' => q({0} atm.),
						'other' => q({0} atm.),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm.),
						'one' => q({0} atm.),
						'other' => q({0} atm.),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(duim Hg),
						'one' => q({0} duim Hg),
						'other' => q({0} duim Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(duim Hg),
						'one' => q({0} duim Hg),
						'other' => q({0} duim Hg),
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
					'pressure-pound-force-per-square-inch' => {
						'name' => q(lb./vk. duim),
						'one' => q({0} lb./vk.dm),
						'other' => q({0} lb./vk.dm),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(lb./vk. duim),
						'one' => q({0} lb./vk.dm),
						'other' => q({0} lb./vk.dm),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/uur),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/uur),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn.),
						'one' => q({0} kn.),
						'other' => q({0} kn.),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn.),
						'one' => q({0} kn.),
						'other' => q({0} kn.),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/s.),
						'one' => q({0} m/s.),
						'other' => q({0} m/s.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/s.),
						'one' => q({0} m/s.),
						'other' => q({0} m/s.),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(myl per uur),
						'one' => q({0} myl/h),
						'other' => q({0} myl/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(myl per uur),
						'one' => q({0} myl/h),
						'other' => q({0} myl/h),
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
					'torque-pound-force-foot' => {
						'name' => q(lb.vt.-krag),
						'one' => q({0} lb.vt.-krag),
						'other' => q({0} lb.vt.-krag),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lb.vt.-krag),
						'one' => q({0} lb.vt.-krag),
						'other' => q({0} lb.vt.-krag),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-voet),
						'one' => q({0} acre-vt.),
						'other' => q({0} acre-vt.),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-voet),
						'one' => q({0} acre-vt.),
						'other' => q({0} acre-vt.),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(vat),
						'one' => q({0} vat),
						'other' => q({0} vate),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(vat),
						'one' => q({0} vat),
						'other' => q({0} vate),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skepel),
						'one' => q({0} skepel),
						'other' => q({0} skepel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skepel),
						'one' => q({0} skepel),
						'other' => q({0} skepel),
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
						'name' => q(voet³),
						'one' => q({0} vt³),
						'other' => q({0} vt³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(voet³),
						'one' => q({0} vt³),
						'other' => q({0} vt³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(duime³),
						'one' => q({0} dm³),
						'other' => q({0} dm³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(duime³),
						'one' => q({0} dm³),
						'other' => q({0} dm³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(myl³),
						'one' => q({0} myl³),
						'other' => q({0} myl³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(myl³),
						'one' => q({0} myl³),
						'other' => q({0} myl³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jaart³),
						'one' => q({0} jt.³),
						'other' => q({0} jt.³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jaart³),
						'one' => q({0} jt.³),
						'other' => q({0} jt.³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koppie),
						'one' => q({0} kp.),
						'other' => q({0} kp.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koppie),
						'one' => q({0} kp.),
						'other' => q({0} kp.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(m. kop),
						'one' => q({0} m. kop),
						'other' => q({0} m. kop),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(m. kop),
						'one' => q({0} m. kop),
						'other' => q({0} m. kop),
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
						'name' => q(dstlpl.),
						'one' => q({0} dstlpl.),
						'other' => q({0} dstlpl.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dstlpl.),
						'one' => q({0} dstlpl.),
						'other' => q({0} dstlpl.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstlpl. Eng.),
						'one' => q({0} dstlpl. Eng.),
						'other' => q({0} dstlpl. Eng.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstlpl. Eng.),
						'one' => q({0} dstlpl. Eng.),
						'other' => q({0} dstlpl. Eng.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dragme vloeistof),
						'one' => q({0} dr. vl.),
						'other' => q({0} dr. vl.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dragme vloeistof),
						'one' => q({0} dr. vl.),
						'other' => q({0} dr. vl.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(druppel),
						'one' => q({0} druppel),
						'other' => q({0} druppels),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(druppel),
						'one' => q({0} druppel),
						'other' => q({0} druppels),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(vl.oz.),
						'one' => q({0} vl.oz.),
						'other' => q({0} vl.oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(vl.oz.),
						'one' => q({0} vl.oz.),
						'other' => q({0} vl.oz.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. vl.oz.),
						'one' => q({0} Imp. vl.oz.),
						'other' => q({0} Imp. vl.oz.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. vl.oz.),
						'one' => q({0} Imp. vl.oz.),
						'other' => q({0} Imp. vl.oz.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gell.),
						'one' => q({0} gell.),
						'other' => q({0} gell.),
						'per' => q({0}/gell.),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gell.),
						'one' => q({0} gell.),
						'other' => q({0} gell.),
						'per' => q({0}/gell.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Br. gell.),
						'one' => q({0} Br. gell.),
						'other' => q({0} Br. gell.),
						'per' => q({0}/Br. gell.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Br. gell.),
						'one' => q({0} Br. gell.),
						'other' => q({0} Br. gell.),
						'per' => q({0}/Br. gell.),
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
						'name' => q(sopie),
						'one' => q({0} sopie),
						'other' => q({0} sopies),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(sopie),
						'one' => q({0} sopie),
						'other' => q({0} sopies),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liters),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liters),
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
						'name' => q(knypie),
						'one' => q({0} knypie),
						'other' => q({0} knypie),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(knypie),
						'one' => q({0} knypie),
						'other' => q({0} knypie),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinte),
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt.),
						'one' => q({0} mpt.),
						'other' => q({0} mpt.),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt.),
						'one' => q({0} mpt.),
						'other' => q({0} mpt.),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kw.gell.),
						'one' => q({0} kw.gell.),
						'other' => q({0} kw.gell.),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kw.gell.),
						'one' => q({0} kw.gell.),
						'other' => q({0} kw.gell.),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kwart Eng.),
						'one' => q({0} kwart Eng.),
						'other' => q({0} kwart Eng.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kwart Eng.),
						'one' => q({0} kwart Eng.),
						'other' => q({0} kwart Eng.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(e.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(e.),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tl.),
						'one' => q({0} tl.),
						'other' => q({0} tl.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tl.),
						'one' => q({0} tl.),
						'other' => q({0} tl.),
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
				end => q({0} en {1}),
				2 => q({0} en {1}),
		} }
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
			display_name => {
				'currency' => q(Verenigde Arabiese Emirate-dirham),
				'one' => q(VAE-dirham),
				'other' => q(VAE-dirham),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afgaanse afgani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanese lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armeense dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Nederlands-Antilliaanse gulde),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolese kwanza),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentynse peso),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Australiese dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Arubaanse floryn),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbeidjaanse manat),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnies-Herzegowiniese omskakelbare marka),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados-dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladesjiese taka),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaarse lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreinse dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundiese frank),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Broeneise dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviaanse boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasilliaanse reaal),
				'one' => q(Brasillianse reaal),
				'other' => q(Brasillianse reaal),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamiaanse dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhoetanese ngoeltroem),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswana-pula),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarusiese roebel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belo-Russiese roebel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Beliziese dollar),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Kanadese dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongolese frank),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Switserse frank),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chileense peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese joean \(buiteland\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese joean),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombiaanse peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Ricaanse colón),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubaanse omskakelbare peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubaanse peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kaap Verdiese escudo),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tsjeggiese kroon),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboeti-frank),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Deense kroon),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikaanse peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algeriese dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egiptiese pond),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrese nakfa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiopiese birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidjiaanse dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland-eilandse pond),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britse pond),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgiese lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanese cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanese cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltarese pond),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiese dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinese frank),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinese syli),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalaanse quetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanese dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkongse dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondurese lempira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatiese kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haïtiaanse gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hongaarse florint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesiese roepia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israeliese nuwe sikkel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indiese roepee),
				'one' => q(Indiese rupee),
				'other' => q(Indiese rupee),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irakse dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranse rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Yslandse kroon),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiaanse lier),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaikaanse dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaniese dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japannese jen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniaanse sjieling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisiese som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodjaanse riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comoraanse frank),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Noord-Koreaanse won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Suid-Koreaanse won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Koeweitse dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman-eilandse dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakse tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laosiaanse kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanese pond),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankaanse roepee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiese dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litause litas),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettiese lats),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libiese dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkaanse dirham),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldowiese leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malgassiese ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedoniese denar),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Mianmese kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoolse toegrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macaose pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritaniese ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritaniese ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritiaanse roepee),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Malediviese rufia),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawiese kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Meksikaanse peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Maleisiese ringgit),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mosambiekse metical \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambiekse metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibiese dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriese naira),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguaanse córdoba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Noorse kroon),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese roepee),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Nieu-Seelandse dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omaanse rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamese balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruaanse sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papoea-Nieu-Guinese kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippynse peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistanse roepee),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poolse zloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguaanse guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katarrese rial),
				'one' => q(Katarese rial),
				'other' => q(Katarese rial),
			},
		},
		'RON' => {
			symbol => 'leu',
			display_name => {
				'currency' => q(Roemeense leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serwiese dinar),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Russiese roebel),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandese frank),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saoedi-Arabiese riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomonseilandse dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellese roepee),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Soedannese pond),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Soedannese pond \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweedse kroon),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapoer-dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sint Helena-pond),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leoniese leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leoniese leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somaliese sjieling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinaamse dollar),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Suid-Soedanese pond),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé en Príncipe dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé en Príncipe-dobra),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Siriese pond),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazilandse lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thaise baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadjikse somoni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmeense manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisiese dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaanse pa’anga),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkse lier \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkse lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad en Tobago-dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nuwe Taiwanese dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniese sjieling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Oekraïnse hriwna),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandese sjieling),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(VSA-dollar),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguaanse peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Oezbekiese som),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezolaanse bolivar),
				'one' => q(Venezolaanse bolívar \(2008–2018\)),
				'other' => q(Venezolaanse bolívare \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezolaanse bolívar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Viëtnamese dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatuse vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoaanse tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Sentraal Afrikaanse CFA-frank),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Oos-Karibiese dollar),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Wes-Afrikaanse CFA-frank),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-frank),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Onbekende geldeenheid),
				'one' => q(\(onbekende geldeenheid\)),
				'other' => q(\(onbekende geldeenheid\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemenitiese rial),
			},
		},
		'ZAR' => {
			symbol => 'R',
			display_name => {
				'currency' => q(Suid-Afrikaanse rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiese kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiese kwacha),
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
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'S',
						sun => 'S'
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
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{middag},
					'evening1' => q{aand},
					'morning1' => q{oggend},
					'night1' => q{nag},
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
			'short' => q{y-MM-dd GGGGG},
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
			Bhm => q{hh:mm B},
			Bhms => q{hh:mm:ss B},
			EBhm => q{E hh:mm B},
			EBhms => q{E hh:mm:ss B},
			Ed => q{E d},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E M/d},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
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
			Bhm => q{hh:mm B},
			Bhms => q{hh:mm:ss B},
			EBhm => q{E hh:mm B},
			EBhms => q{E hh:mm:ss B},
			Ed => q{E d},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E dd MMM y G},
			GyMMMd => q{dd MMM y G},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMW => q{'week' W 'van' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM-y},
			yMEd => q{E y-MM-dd},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{y-M GGGGG – y-M GGGGG},
				M => q{y-M – y-M GGGGG},
				y => q{y-M – y-M GGGGG},
			},
			GyMEd => {
				G => q{E d-M-y GGGGG – E d-M-y GGGGG},
				M => q{E d-M-y – E d-M-y GGGGG},
				d => q{E d-M-y – E d-M-y GGGGG},
				y => q{E d-M-y – E d-M-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d-M-y GGGGG – d-M-y GGGGG},
				M => q{d-M-y – d-M-y GGGGG},
				d => q{d-M-y – d-M-y GGGGG},
				y => q{d-M-y – d-M-y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{hh:mm B – hh:mm B},
				h => q{hh:mm B – hh:mm B},
				m => q{hh:mm–hh:mm},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{y-M GGGGG – y-M GGGGG},
				M => q{y-M – y-M GGGGG},
				y => q{y-M – y-M GGGGG},
			},
			GyMEd => {
				G => q{E y-M-d GGGGG – E y-M-d GGGGG},
				M => q{E y-M-d – E y-M-d GGGGG},
				d => q{E y-M-d – E y-M-d GGGGG},
				y => q{E y-M-d – E y-M-d GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{y-M-d GGGGG – y-M-d GGGGG},
				M => q{y-M-d – y-M-d GGGGG},
				d => q{y-M-d – y-M-d GGGGG},
				y => q{y-M-d – y-M-d GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm a – h:mm a v},
				m => q{h:mm a – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y},
				d => q{E d/M/y – E d/M/y},
				y => q{E d/M/y – E d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0}-tyd),
		regionFormat => q({0}-dagligtyd),
		regionFormat => q({0}-standaardtyd),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan-tyd#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaïro#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djiboeti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartoem#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadisjoe#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
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
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridgebaai#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaaiman#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glacebaai#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goosebaai#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksikostad#,
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
		'America/Rainy_River' => {
			exemplarCity => q#Rainyrivier#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
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
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunderbaai#,
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
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjchabad#,
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
		'Asia/Beirut' => {
			exemplarCity => q#Beiroet#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Broenei#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Doebai#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkoetsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Djakarta#,
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
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Koeala-Loempoer#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koeweit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riaad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Tsji Minhstad#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoel#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapoer#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
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
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarie#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaap Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Suid-Georgië#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
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
				'standard' => q#Bolivië-tyd#,
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
				'daylight' => q#Colombia-somertyd#,
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
		'Europe/Athens' => {
			exemplarCity => q#Athene#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlyn#,
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
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ierse standaardtyd#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Eiland Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiëf#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
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
		'Europe/Moscow' => {
			exemplarCity => q#Moskou#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parys#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratof#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikaanstad#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wene#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warskou#,
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
				'standard' => q#Guiana-tyd#,
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
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comore#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maledive#,
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
				'daylight' => q#Irkoetsk-somertyd#,
				'generic' => q#Irkoetsk-tyd#,
				'standard' => q#Irkoetsk-standaardtyd#,
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
				'daylight' => q#Norfolkeiland-dagligtyd#,
				'generic' => q#Norfolkeiland-tyd#,
				'standard' => q#Norfolkeiland-standaardtyd#,
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
		'Pacific/Easter' => {
			exemplarCity => q#Paas#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidji#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
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
		'Yukon' => {
			long => {
				'standard' => q#Yukontyd#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
