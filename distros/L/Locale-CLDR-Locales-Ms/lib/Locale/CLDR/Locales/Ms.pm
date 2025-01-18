=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ms - Package for language Malay

=cut

package Locale::CLDR::Locales::Ms;
# This file auto generated from Data\common\main\ms.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−ke-→#,##0→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ke-=#,##0=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(No. 1),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ke-=#,##0=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ke-=#,##0=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(negatif →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(kosong),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← perpuluhan →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(satu),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dua),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tiga),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(empat),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(lima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(enam),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(tujuh),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(lapan),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(sembilan),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(sepuluh),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(sebelas),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ belas),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←← puluh[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(seratus[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←← ratus[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(seribu[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← ribu[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(sejuta[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← juta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← bilion[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← kuadrilion[ →→]),
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
					rule => q(negatif →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(kekosong),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(pertama),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ke=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ke=%spellout-cardinal=),
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
 				'ab' => 'Abkhazia',
 				'ace' => 'Aceh',
 				'ach' => 'Akoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'ae' => 'Avestan',
 				'aeb' => 'Arab Tunisia',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Altai Selatan',
 				'am' => 'Amharic',
 				'an' => 'Aragon',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Standard Moden',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'arq' => 'Arab Algeria',
 				'ars' => 'Arab Najdi',
 				'ary' => 'Arab Maghribi',
 				'arz' => 'Arab Mesir',
 				'as' => 'Assam',
 				'asa' => 'Asu',
 				'ast' => 'Asturia',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijan',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluchi',
 				'ban' => 'Bali',
 				'bas' => 'Basaa',
 				'bax' => 'Bamun',
 				'bbj' => 'Ghomala',
 				'be' => 'Belarus',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bg' => 'Bulgaria',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Balochi Barat',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'blo' => 'Anii',
 				'bm' => 'Bambara',
 				'bn' => 'Benggali',
 				'bo' => 'Tibet',
 				'bpy' => 'Bishnupriya',
 				'br' => 'Breton',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnia',
 				'bss' => 'Akoose',
 				'bua' => 'Buriat',
 				'bug' => 'Bugis',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Catalonia',
 				'cay' => 'Cayuga',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Kurdi Tengah',
 				'ckb@alt=menu' => 'Kurdi, Tengah',
 				'ckb@alt=variant' => 'Kurdi, Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsica',
 				'cop' => 'Coptic',
 				'crg' => 'Michif',
 				'crh' => 'Turki Krimea',
 				'crj' => 'Cree Tenggara',
 				'crk' => 'Plains Cree',
 				'crl' => 'Timur Laut Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'crs' => 'Perancis Seselwa Creole',
 				'cs' => 'Czech',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Slavik Gereja',
 				'cv' => 'Chuvash',
 				'cy' => 'Wales',
 				'da' => 'Denmark',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Jerman',
 				'de_AT' => 'Jerman Austria',
 				'de_CH' => 'Jerman Halus Switzerland',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbian Rendah',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Greek',
 				'en' => 'Inggeris',
 				'en_AU' => 'Inggeris Australia',
 				'en_CA' => 'Inggeris Kanada',
 				'en_GB' => 'Inggeris British',
 				'en_GB@alt=short' => 'Inggeris U.K.',
 				'en_US' => 'Inggeris AS',
 				'en_US@alt=short' => 'Inggeris A.S.',
 				'eo' => 'Esperanto',
 				'es' => 'Sepanyol',
 				'es_419' => 'Sepanyol Amerika Latin',
 				'es_ES' => 'Sepanyol Eropah',
 				'es_MX' => 'Sepanyol Mexico',
 				'et' => 'Estonia',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Parsi',
 				'fa_AF' => 'Dari',
 				'ff' => 'Fulah',
 				'fi' => 'Finland',
 				'fil' => 'Filipina',
 				'fj' => 'Fiji',
 				'fo' => 'Faroe',
 				'fon' => 'Fon',
 				'fr' => 'Perancis',
 				'fr_CA' => 'Perancis Kanada',
 				'fr_CH' => 'Perancis Switzerland',
 				'frc' => 'Perancis Cajun',
 				'frr' => 'Frisian Utara',
 				'fur' => 'Friulian',
 				'fy' => 'Frisian Barat',
 				'ga' => 'Ireland',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gan' => 'Cina Gan',
 				'gba' => 'Gbaya',
 				'gbz' => 'Zoroastrian Dari',
 				'gd' => 'Scots Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Kiribati',
 				'gl' => 'Galicia',
 				'glk' => 'Gilaki',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'grc' => 'Greek Purba',
 				'gsw' => 'Jerman Switzerland',
 				'gu' => 'Gujarat',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'hak' => 'Cina Hakka',
 				'haw' => 'Hawaii',
 				'hax' => 'Haida Selatan',
 				'he' => 'Ibrani',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Croatia',
 				'hsb' => 'Sorbian Atas',
 				'hsn' => 'Cina Xiang',
 				'ht' => 'Kreol Haiti',
 				'hu' => 'Hungary',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armenia',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesia',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Inuktitut Kanada Barat',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Iceland',
 				'it' => 'Itali',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jepun',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Jawa',
 				'ka' => 'Georgia',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardia',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Kikuya',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazakhstan',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korea',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelian',
 				'kru' => 'Kurukh',
 				'ks' => 'Kashmir',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colognian',
 				'ku' => 'Kurdish',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'kwk' => 'Kwak’wala',
 				'kxv' => 'Kuvi',
 				'ky' => 'Kirghiz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lb' => 'Luxembourg',
 				'lez' => 'Lezghian',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lij' => 'Liguria',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Laos',
 				'lou' => 'Kreol Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Utara',
 				'lsm' => 'Saamia',
 				'lt' => 'Lithuania',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvia',
 				'mad' => 'Madura',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masai',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasy',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshall',
 				'mi' => 'Maori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonia',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolia',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Melayu',
 				'mt' => 'Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Pelbagai Bahasa',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandese',
 				'my' => 'Burma',
 				'mye' => 'Myene',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nan' => 'Cina Min Nan',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Bokmal Norway',
 				'nd' => 'Ndebele Utara',
 				'nds' => 'Jerman Rendah',
 				'nds_NL' => 'Saxon Rendah',
 				'ne' => 'Nepal',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niu',
 				'nl' => 'Belanda',
 				'nl_BE' => 'Flemish',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nynorsk Norway',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norway',
 				'nog' => 'Nogai',
 				'nqo' => 'N’ko',
 				'nr' => 'Ndebele Selatan',
 				'nso' => 'Sotho Utara',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Occitania',
 				'ojb' => 'Ojibwa Barat Laut',
 				'ojc' => 'Ojibwa Tengah',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Ojibwa Barat',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossete',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Nigerian Pidgin',
 				'pis' => 'Pijin',
 				'pl' => 'Poland',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Prusia',
 				'ps' => 'Pashto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portugis',
 				'pt_BR' => 'Portugis Brazil',
 				'pt_PT' => 'Portugis Eropah',
 				'qu' => 'Quechua',
 				'quc' => 'Kʼicheʼ',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotonga',
 				'rhg' => 'Rohingya',
 				'rm' => 'Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Romania',
 				'ro_MD' => 'Moldavia',
 				'rof' => 'Rombo',
 				'ru' => 'Rusia',
 				'rup' => 'Aromanian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinia',
 				'scn' => 'Sicili',
 				'sco' => 'Scots',
 				'sd' => 'Sindhi',
 				'sdh' => 'Kurdish Selatan',
 				'se' => 'Sami Utara',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sh' => 'SerboCroatia',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'shu' => 'Arab Chadian',
 				'si' => 'Sinhala',
 				'sk' => 'Slovak',
 				'sl' => 'Slovenia',
 				'slh' => 'Lushootseed Selatan',
 				'sm' => 'Samoa',
 				'sma' => 'Sami Selatan',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sq' => 'Albania',
 				'sr' => 'Serbia',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Sotho Selatan',
 				'str' => 'Straits Salish',
 				'su' => 'Sunda',
 				'suk' => 'Sukuma',
 				'sv' => 'Sweden',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Congo Swahili',
 				'swb' => 'Comoria',
 				'syr' => 'Syriac',
 				'szl' => 'Silesia',
 				'ta' => 'Tamil',
 				'tce' => 'Tutchone Selatan',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tly' => 'Talysh',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tatar',
 				'ttm' => 'Tutchone Utara',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahiti',
 				'tyv' => 'Tuvinian',
 				'tzm' => 'Tamazight Atlas Tengah',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'ug@alt=variant' => 'Uighur',
 				'uk' => 'Ukraine',
 				'umb' => 'Umbundu',
 				'und' => 'Bahasa Tidak Diketahui',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbekistan',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Venetia',
 				'vi' => 'Vietnam',
 				'vmw' => 'Makhuwa',
 				'vo' => 'Volapük',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Cina Wu',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xnr' => 'Kangri',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonis',
 				'yue@alt=menu' => 'Cina, Kantonis',
 				'za' => 'Zhuang',
 				'zgh' => 'Tamazight Maghribi Standard',
 				'zh' => 'Cina',
 				'zh@alt=menu' => 'Cina, Mandarin',
 				'zh_Hans' => 'Cina Ringkas',
 				'zh_Hans@alt=long' => 'Cina Mandarin Ringkas',
 				'zh_Hant' => 'Cina Tradisional',
 				'zh_Hant@alt=long' => 'Cina Mandarin Tradisional',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Tiada kandungan linguistik',
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
 			'Aghb' => 'Kaukasia Albania',
 			'Arab@alt=variant' => 'Perso-Arab',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Aramia Imperial',
 			'Armn' => 'Armenia',
 			'Avst' => 'Avestan',
 			'Bali' => 'Bali',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Benggala',
 			'Bhks' => 'Bhaisuki',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Bugis',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Suku Kata Orang Asli Kanada Bersatu',
 			'Cari' => 'Carian',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Copt' => 'Coptic',
 			'Cprt' => 'Cypriot',
 			'Cyrl' => 'Cyril',
 			'Deva' => 'Devanagari',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Trengkas Duployan',
 			'Egyp' => 'Hiroglif Mesir',
 			'Elba' => 'Elbasan',
 			'Elym' => 'Elymaic',
 			'Ethi' => 'Ethiopia',
 			'Geor' => 'Georgia',
 			'Glag' => 'Glagolitik',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gonti',
 			'Goth' => 'Gothic',
 			'Gran' => 'Grantha',
 			'Grek' => 'Greek',
 			'Gujr' => 'Gujarat',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han dengan Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Ringkas',
 			'Hans@alt=stand-alone' => 'Han Ringkas',
 			'Hant' => 'Tradisional',
 			'Hant@alt=stand-alone' => 'Han Tradisional',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Hiroglif Anatoli',
 			'Hmng' => 'Pahawh Hmong',
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
 			'Hrkt' => 'Ejaan sukuan Jepun',
 			'Hung' => 'Hungary Lama',
 			'Ital' => 'Italik Lama',
 			'Java' => 'Jawa',
 			'Jpan' => 'Jepun',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korea',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'Lycia',
 			'Lydi' => 'Lydia',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandaean',
 			'Mani' => 'Manichaean',
 			'Marc' => 'Marchen',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Kursif Meroitic',
 			'Mero' => 'Meroitic',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Mongolia',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Myammar',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Arab Utara Lama',
 			'Nbat' => 'Nabataean',
 			'Nkoo' => 'N’ko',
 			'Nshu' => 'Nushu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oriya',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Permic Lama',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inskripsi Pahlavi',
 			'Phlp' => 'Pslater Pahlavi',
 			'Phnx' => 'Phoenicia',
 			'Plrd' => 'Fonetik Pollard',
 			'Prti' => 'Inskripsi Parthian',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi Rohingya',
 			'Runr' => 'Runic',
 			'Samr' => 'Samaritan',
 			'Sarb' => 'Arab Selatan Lama',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Tulisan Isyarat',
 			'Shaw' => 'Shavia',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Sinhala',
 			'Sogd' => 'Sogdia',
 			'Sogo' => 'Sogdia Lama',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sunda',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syria',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue Baharu',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Tibt' => 'Tibet',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritic',
 			'Vaii' => 'Vai',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Xpeo' => 'Parsi Lama',
 			'Xsux' => 'Aksara Paku Sumero-Akkadia',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Segi Empat Zanabazar',
 			'Zinh' => 'Diwarisi',
 			'Zmth' => 'Tatatanda matematik',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Tidak ditulis',
 			'Zyyy' => 'Lazim',
 			'Zzzz' => 'Tulisan Tidak Diketahui',

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
			'001' => 'Dunia',
 			'002' => 'Afrika',
 			'003' => 'Amerika Utara',
 			'005' => 'Amerika Selatan',
 			'009' => 'Oceania',
 			'011' => 'Afrika Barat',
 			'013' => 'Amerika Tengah',
 			'014' => 'Afrika Timur',
 			'015' => 'Afrika Utara',
 			'017' => 'Afrika Tengah',
 			'018' => 'Selatan Afrika',
 			'019' => 'Amerika',
 			'021' => 'Utara Amerika',
 			'029' => 'Caribbean',
 			'030' => 'Asia Timur',
 			'034' => 'Asia Selatan',
 			'035' => 'Asia Tenggara',
 			'039' => 'Eropah Selatan',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Wilayah Mikronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Tengah',
 			'145' => 'Asia Barat',
 			'150' => 'Eropah',
 			'151' => 'Eropah Timur',
 			'154' => 'Eropah Utara',
 			'155' => 'Eropah Barat',
 			'202' => 'Afrika Sub-Sahara',
 			'419' => 'Amerika Latin',
 			'AC' => 'Pulau Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Emiriah Arab Bersatu',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua dan Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartika',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Amerika',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Kepulauan Aland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia dan Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthelemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Belanda Caribbean',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Pulau Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kepulauan Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Republik Afrika Tengah',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republik)',
 			'CH' => 'Switzerland',
 			'CI' => 'Cote d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Kepulauan Cook',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Pulau Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curacao',
 			'CX' => 'Pulau Krismas',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Republik Czech',
 			'DE' => 'Jerman',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominica',
 			'DO' => 'Republik Dominica',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta dan Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Mesir',
 			'EH' => 'Sahara Barat',
 			'ER' => 'Eritrea',
 			'ES' => 'Sepanyol',
 			'ET' => 'Ethiopia',
 			'EU' => 'Kesatuan Eropah',
 			'EZ' => 'Zon Euro',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Kepulauan Falkland',
 			'FK@alt=variant' => 'Kepulauan Falkland (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Kepulauan Faroe',
 			'FR' => 'Perancis',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guiana Perancis',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea Khatulistiwa',
 			'GR' => 'Greece',
 			'GS' => 'Kepulauan Georgia Selatan & Sandwich Selatan',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Kepulauan Heard & McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungary',
 			'IC' => 'Kepulauan Canary',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Wilayah Lautan Hindi British',
 			'IO@alt=chagos' => 'Kepulauan Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Itali',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Jepun',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Kemboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Saint Kitts dan Nevis',
 			'KP' => 'Korea Utara',
 			'KR' => 'Korea Selatan',
 			'KW' => 'Kuwait',
 			'KY' => 'Kepulauan Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lubnan',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Maghribi',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Kepulauan Marshall',
 			'MK' => 'Macedonia Utara',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Kepulauan Mariana Utara',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Pulau Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Belanda',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Perancis',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Filipina',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'Saint Pierre dan Miquelon',
 			'PN' => 'Kepulauan Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Wilayah Palestin',
 			'PS@alt=short' => 'Palestin',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania Terpencil',
 			'RE' => 'Reunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arab Saudi',
 			'SB' => 'Kepulauan Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapura',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard dan Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudan Selatan',
 			'ST' => 'Sao Tome dan Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Kepulauan Turks dan Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Wilayah Selatan Perancis',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor Timur',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkiye',
 			'TR@alt=variant' => 'Turki',
 			'TT' => 'Trinidad dan Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Kepulauan Terpencil A.S.',
 			'UN' => 'Bangsa-bangsa Bersatu',
 			'UN@alt=short' => 'PBB',
 			'US' => 'Amerika Syarikat',
 			'US@alt=short' => 'A.S',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Kota Vatican',
 			'VC' => 'Saint Vincent dan Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Kepulauan Virgin British',
 			'VI' => 'Kepulauan Virgin A.S.',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis dan Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Aksen Pseudo',
 			'XB' => 'Bidi Pseudo',
 			'XK' => 'Kosovo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Selatan',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Wilayah Tidak Diketahui',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Sistem ejaan Jerman Tradisional',
 			'1994' => 'Sistem ejaan Resia standard',
 			'1996' => 'Sistem ejaan Jerman 1996',
 			'1606NICT' => 'Lewat Pertengahan Era Perancis hingga 1606',
 			'1694ACAD' => 'Awal Pertengahan Era Perancis',
 			'1959ACAD' => 'Akademik',
 			'ABL1943' => 'Perumusan sistem ejaan 1943',
 			'AKUAPEM' => 'AKUAPEM TWI',
 			'ALALC97' => 'Perumian ALA-LC, edisi 1997',
 			'ALUKU' => 'Dialek Aluku',
 			'AO1990' => 'Perjanjian Sistem Ejaan Bahasa Portugis 1990',
 			'ARANES' => 'ARAN',
 			'ASANTE' => 'ASANTE TWI',
 			'AUVERN' => 'AUVERGNAT',
 			'BAKU1926' => 'Abjad Latin Turki Disatukan',
 			'BALANKA' => 'Dialek Balanka Anii',
 			'BARLA' => 'Kumpulan dialek Barlavento Kabuverdianu',
 			'BASICENG' => 'ASAS INGGERIS',
 			'BAUDDHA' => 'BUDDHA',
 			'BISCAYAN' => 'BISCAYAN BISQUE',
 			'BISKE' => 'Dialek San Giorgio/Bila',
 			'BOHORIC' => 'Abjad Bohoric',
 			'BOONT' => 'Boontling',
 			'CISAUP' => 'CISALPINE',
 			'COLB1945' => 'Konvensyen Sistem Ejaan Portugis-Brazil 1945',
 			'CORNU' => 'INGGERIS CORNISH',
 			'CREISS' => 'OCCITAN CROISSANT',
 			'DAJNKO' => 'Abjad Dajnko',
 			'EKAVSK' => 'Serbia dengan sebutan Ekavia',
 			'EMODENG' => 'Inggeris Moden Awal',
 			'FONIPA' => 'Fonetik IPA',
 			'FONKIRSH' => 'ABJAD FONETIK ANTARABANGSA',
 			'FONNAPA' => 'ABJAD FONETIK AMERIKA UTARA',
 			'FONUPA' => 'Fonetik UPA',
 			'FONXSAMP' => 'TRANSKRIP X-SAMPA',
 			'GASCON' => 'OCCITAN GASCON',
 			'GRCLASS' => 'OCCITAN KLASIK',
 			'GRITAL' => 'ORTOGRAFI OCCITAN-ITALI',
 			'GRMISTR' => 'ORTOGRAFI MISTRALIA',
 			'HEPBURN' => 'Perumian Hepburn',
 			'HOGNORSK' => 'NORWAY TINGGI',
 			'HSISTEMO' => 'SERBIA IJEKAVIAN',
 			'IJEKAVSK' => 'Fon Serbia dengan sebutan Ijekavia',
 			'ITIHASA' => 'SANSKRIT EPIK',
 			'IVANCHOV' => 'ORTOGRAFI BULGARIA 1899',
 			'JAUER' => 'ROMANSH JAUER',
 			'JYUTPING' => 'KANTONIS ROMAN',
 			'KKCOR' => 'Sistem Ejaan Lazim',
 			'KOCIEWIE' => 'POLAND KOCIEWIE',
 			'KSCOR' => 'Sistem Ejaan Standard',
 			'LAUKIKA' => 'SANSKRIT KLASIK',
 			'LEMOSIN' => 'PERANCIS LIMOUSIN',
 			'LENGADOC' => 'OCCITAN LANGUEDOC',
 			'LIPAW' => 'Dialek Lipovaz Resia',
 			'LUNA1918' => 'ORTOGRAFI RUSIA SELEPAS 1917',
 			'METELKO' => 'Abjad Metelko',
 			'MONOTON' => 'Ekanada',
 			'NDYUKA' => 'Dialek Ndyuka',
 			'NEDIS' => 'Dialek Natisone',
 			'NEWFOUND' => 'INGGERIS NEWFOUNDLAND',
 			'NICARD' => 'OCCITAN NICARD',
 			'NJIVA' => 'Dialek Gniva/Njiva',
 			'NULIK' => 'Volapuk Moden',
 			'OSOJS' => 'Dialek Oseacco/Osojane',
 			'OXENDICT' => 'Ejaan Kamus Inggeris Oxford',
 			'PAHAWH2' => 'PAHAWH HMONG PERINGKAT KE-2',
 			'PAHAWH3' => 'PAHAWH HMONG PERINGKAT KE-3',
 			'PAHAWH4' => 'PAHAWH HMONG VERSI AKHIR',
 			'PAMAKA' => 'Dialek Pamaka',
 			'PETR1708' => 'ORTOGRAFI PETRINE',
 			'PINYIN' => 'Perumian Pinyin',
 			'POLYTON' => 'Banyak Nada',
 			'POSIX' => 'Komputer',
 			'PROVENC' => 'OCCITAN PROVENCE',
 			'PUTER' => 'ROMANSH PUTER',
 			'REVISED' => 'Sistem Ejaan Semakan',
 			'RIGIK' => 'Vopaluk Klasik',
 			'ROZAJ' => 'Resia',
 			'RUMGR' => 'RUMANTSCH GRISCHUN',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Inggeris Standard Scotland',
 			'SCOUSE' => 'INGGERIS LIVERPOOL',
 			'SIMPLE' => 'RINGKAS',
 			'SOLBA' => 'Dialek Stolvizza/Solbica',
 			'SOTAV' => 'Kumpulan dialek Sotavento Kabuverdianu',
 			'SPANGLIS' => 'iNGGERIS SEPANYOL',
 			'SURMIRAN' => 'ROMANSH SURMIRAN',
 			'SURSILV' => 'ROMANSH SURSILVAN',
 			'SUTSILV' => 'ROMANSH SUTSILVAN',
 			'TARASK' => 'Sistem ejaan Taraskievica',
 			'UCCOR' => 'Sistem Ejaan Bersatu',
 			'UCRCOR' => 'Sistem Ejaan Semakan Bersatu',
 			'ULSTER' => 'SCOTS ULSTER',
 			'UNIFON' => 'Abjad fonetik Unifon',
 			'VAIDIKA' => 'VEDIC SANSKRIT',
 			'VALENCIA' => 'Valencia',
 			'VALLADER' => 'ROMANSH VALLADER',
 			'VIVARAUP' => 'VIVARO-ALPINE',
 			'WADEGILE' => 'Perumian Wade-Giles',
 			'XSISTEMO' => 'X-SISTEM ESPERANTO',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendar',
 			'cf' => 'Format Mata Wang',
 			'colalternate' => 'Abaikan Pengisihan Simbol',
 			'colbackwards' => 'Pengisihan Aksen Terbalik',
 			'colcasefirst' => 'Penyusunan Huruf Besar/Huruf Kecil',
 			'colcaselevel' => 'Pengisihan Sensitif Atur',
 			'collation' => 'Tertib Isihan',
 			'colnormalization' => 'Pengisihan Ternormal',
 			'colnumeric' => 'Pengisihan Berangka',
 			'colstrength' => 'Kekuatan Pengisihan',
 			'currency' => 'Mata wang',
 			'hc' => 'Kitaran Jam (12 berbanding 24)',
 			'lb' => 'Gaya Pemisah Baris',
 			'ms' => 'Sistem Ukuran',
 			'numbers' => 'Nombor',
 			'timezone' => 'Zon Waktu',
 			'va' => 'Varian Tempat',
 			'x' => 'Penggunaan Peribadi',

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
 				'buddhist' => q{Kalendar Buddha},
 				'chinese' => q{Kalendar Cina},
 				'coptic' => q{Kalendar Qibti},
 				'dangi' => q{Kalendar Dangi},
 				'ethiopic' => q{Kalendar Ethiopia},
 				'ethiopic-amete-alem' => q{Kalendar Amete Alem Ethiopia},
 				'gregorian' => q{Kalendar Gregory},
 				'hebrew' => q{Kalendar Ibrani},
 				'indian' => q{Kalendar Kebangsaan India},
 				'islamic' => q{Kalendar Islam},
 				'islamic-civil' => q{Kalendar Sivil Islam},
 				'islamic-rgsa' => q{Kalendar Islam (Arab Saudi, cerapan)},
 				'islamic-tbla' => q{Kalendar Islam (jadual, zaman astronomi)},
 				'islamic-umalqura' => q{Kalendar Islam (Umm Al-Quran)},
 				'iso8601' => q{Kalendar ISO-8601},
 				'japanese' => q{Kalendar Jepun},
 				'persian' => q{Kalendar Parsi},
 				'roc' => q{Kalendar Minguo},
 			},
 			'cf' => {
 				'account' => q{Format Mata Wang Perakaunan},
 				'standard' => q{Format Mata Wang Standard},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Isih Simbol},
 				'shifted' => q{Isih Mengabaikan Simbol},
 			},
 			'colbackwards' => {
 				'no' => q{Isih Aksen Secara Biasa},
 				'yes' => q{Isih Aksen Terbalik},
 			},
 			'colcasefirst' => {
 				'lower' => q{Isih Huruf Kecil Dahulu},
 				'no' => q{Isih Urutan Atur Biasa},
 				'upper' => q{Isih Huruf Besar Dahulu},
 			},
 			'colcaselevel' => {
 				'no' => q{Isih Tidak Sensitif Atur},
 				'yes' => q{Isih Sensitif Atur},
 			},
 			'collation' => {
 				'big5han' => q{Aturan Isih Cina Tradisional - Big5},
 				'compat' => q{Tertib Isihan Sebelumnya},
 				'dictionary' => q{Aturan Isih Kamus},
 				'ducet' => q{Tertib Isih Unikod Lalai},
 				'emoji' => q{Aturan Isih Emoji},
 				'eor' => q{Peraturan Isihan Eropah},
 				'gb2312han' => q{Aturan Isih Bahasa Cina Ringkas - GB2312},
 				'phonebook' => q{Aturan Isih Buku Telefon},
 				'phonetic' => q{Urutan Isih Fonetik},
 				'pinyin' => q{Aturan Isih Pinyin},
 				'search' => q{Carian Tujuan Umum},
 				'searchjl' => q{Cari Mengikut Konsonan Awal Hangul},
 				'standard' => q{Tertib Isih Standard},
 				'stroke' => q{Aturan Isih Coretan},
 				'traditional' => q{Aturan Isih Tradisional},
 				'unihan' => q{Aturan Isih Coretan Radikal},
 				'zhuyin' => q{Aturan Isih Zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Isih Tanpa Penormalan},
 				'yes' => q{Isih Unikod Ternormal},
 			},
 			'colnumeric' => {
 				'no' => q{Isih Digit Secara Berasingan},
 				'yes' => q{Isih Digit Mengikut Nombor},
 			},
 			'colstrength' => {
 				'identical' => q{Isih Semua},
 				'primary' => q{Isih Huruf Asas Sahaja},
 				'quaternary' => q{Isih Aksen/Atur/Lebar/Kana},
 				'secondary' => q{Isih Aksen},
 				'tertiary' => q{Isih Aksen/Atur/Lebar},
 			},
 			'd0' => {
 				'fwidth' => q{Ke Kelebaran Penuh},
 				'hwidth' => q{Ke Kelebaran Separa},
 				'npinyin' => q{Bernombor},
 			},
 			'hc' => {
 				'h11' => q{Sistem 12 Jam (0–11)},
 				'h12' => q{Sistem 12 Jam (1–12)},
 				'h23' => q{Sistem 24 Jam (0–23)},
 				'h24' => q{Sistem 24 Jam (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Gaya Pemisah Baris Bebas},
 				'normal' => q{Gaya Pemisah Baris Biasa},
 				'strict' => q{Gaya Pemisah Baris Ketat},
 			},
 			'm0' => {
 				'bgn' => q{Transliterasi BGN AS},
 				'ungegn' => q{Transliterasi UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistem Metrik},
 				'uksystem' => q{Sistem Ukuran Imperial},
 				'ussystem' => q{Sistem Ukuran AS},
 			},
 			'numbers' => {
 				'ahom' => q{Digit Ahom},
 				'arab' => q{Digit Indi-Arab},
 				'arabext' => q{Digit Indi Arab Lanjutan},
 				'armn' => q{Angka Armenia},
 				'armnlow' => q{Angka Kecil Armenia},
 				'bali' => q{Digit Bali},
 				'beng' => q{Digit Benggali},
 				'brah' => q{Digit Brahmi},
 				'cakm' => q{Digit Chakma},
 				'cham' => q{Digit Cham},
 				'cyrl' => q{Digit Cyril},
 				'deva' => q{Digit Devanagari},
 				'ethi' => q{Angka Ethiopia},
 				'finance' => q{Angka Kewangan},
 				'fullwide' => q{Digit Lebar Penuh},
 				'geor' => q{Angka Georgia},
 				'gong' => q{Digit Gunjala Gondi},
 				'gonm' => q{Digit Masaram Gondi},
 				'grek' => q{Angka Greek},
 				'greklow' => q{Angka Huruf Kecil Greek},
 				'gujr' => q{Digit Gujarat},
 				'guru' => q{Digit Gurmukhi},
 				'hanidec' => q{Angka Perpuluhan Cina},
 				'hans' => q{Angka Cina Ringkas},
 				'hansfin' => q{Angka Kewangan Cina Ringkas},
 				'hant' => q{Angka Cina Tradisional},
 				'hantfin' => q{Angka Kewangan Cina Tradisional},
 				'hebr' => q{Angka Ibrani},
 				'hmng' => q{Digit Pahawh Hmong},
 				'hmnp' => q{Digit Nyiakeng Puachue Hmong},
 				'java' => q{Digit Jawa},
 				'jpan' => q{Angka Jepun},
 				'jpanfin' => q{Angka Kewangan Jepun},
 				'kali' => q{Digit Kayah Li},
 				'khmr' => q{Digit Khmer},
 				'knda' => q{Digit Kannada},
 				'lana' => q{Digit Tai Tham Hora},
 				'lanatham' => q{Digit Tai Tham Tham},
 				'laoo' => q{Digit Lao},
 				'latn' => q{Digit Barat},
 				'lepc' => q{Digit Lepcha},
 				'limb' => q{Digit Limbu},
 				'mathbold' => q{Digit Matematik Tebal},
 				'mathdbl' => q{Digit Matematik Dwilejang},
 				'mathmono' => q{Digit Matematik Monospace},
 				'mathsanb' => q{Digit Matematik San Serif Tebal},
 				'mathsans' => q{Digit Matematik San Serif},
 				'mlym' => q{Digit Malayalam},
 				'modi' => q{Digit Modi},
 				'mong' => q{Digit Mongolia},
 				'mroo' => q{Digit Mro},
 				'mtei' => q{Digit Meetei Mayek},
 				'mymr' => q{Digit Myammar},
 				'mymrshan' => q{Digit Myanmar Shan},
 				'mymrtlng' => q{Digit Myanmar Tai Laing},
 				'native' => q{Digit Asal},
 				'nkoo' => q{Digit N’Ko},
 				'olck' => q{Digit Ol Chiki},
 				'orya' => q{Digit Oriya},
 				'osma' => q{Digit Osmanya},
 				'rohg' => q{Digit Hanifi Rohingya},
 				'roman' => q{Angka Roman},
 				'romanlow' => q{Angka Huruf Kecil Roman},
 				'saur' => q{Digit Saurashtra},
 				'shrd' => q{Digit Sharada},
 				'sind' => q{Digit Khudawadi},
 				'sinh' => q{Digit Sinhala Lith},
 				'sora' => q{Digit Sora Sompeng},
 				'sund' => q{Digit Sunda},
 				'takr' => q{Digit Takri},
 				'talu' => q{Digit Tai Lue Baru},
 				'taml' => q{Angka Tamil Tradisional},
 				'tamldec' => q{Digit Tamil},
 				'telu' => q{Digit Telugu},
 				'thai' => q{Digit Thai},
 				'tibt' => q{Digit Tibet},
 				'tirh' => q{Digit Tirhuta},
 				'traditional' => q{Angka Tradisional},
 				'vaii' => q{Digit Vai},
 				'wara' => q{Digit Warang Citi},
 				'wcho' => q{Digit Wancho},
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
			'metric' => q{Metrik},
 			'US' => q{AS},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Bahasa: {0}',
 			'script' => 'Skrip: {0}',
 			'region' => 'Kawasan: {0}',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah mata angin),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah mata angin),
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
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
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
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quekto{0}),
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
						'other' => q({0} daya g),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} daya g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter sesaat ganda dua),
						'other' => q({0} meter sesaat ganda dua),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter sesaat ganda dua),
						'other' => q({0} meter sesaat ganda dua),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minit arka),
						'other' => q({0} minit arka),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minit arka),
						'other' => q({0} minit arka),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} setiap sentimeter persegi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} setiap sentimeter persegi),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} setiap inci persegi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} setiap inci persegi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} setiap meter persegi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} setiap meter persegi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0} batu persegi),
						'per' => q({0} setiap batu persegi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0} batu persegi),
						'per' => q({0} setiap batu persegi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ela persegi),
						'other' => q({0} ela persegi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ela persegi),
						'other' => q({0} ela persegi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram setiap desiliter),
						'other' => q({0} miligram setiap desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram setiap desiliter),
						'other' => q({0} miligram setiap desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol setiap liter),
						'other' => q({0} milimol setiap liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol setiap liter),
						'other' => q({0} milimol setiap liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} peratus),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} peratus),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} per seribu),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} per seribu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bahagian setiap juta),
						'other' => q({0} bahagian setiap juta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bahagian setiap juta),
						'other' => q({0} bahagian setiap juta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
						'other' => q({0} permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
						'other' => q({0} permyriad),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(bahagian per bilion),
						'other' => q({0} bahagian per bilion),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(bahagian per bilion),
						'other' => q({0} bahagian per bilion),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter setiap 100 kilometer),
						'other' => q({0} liter setiap 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter setiap 100 kilometer),
						'other' => q({0} liter setiap 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter sekilometer),
						'other' => q({0} liter sekilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter sekilometer),
						'other' => q({0} liter sekilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(batu segelen),
						'other' => q({0} batu segelen),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(batu segelen),
						'other' => q({0} batu segelen),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(batu setiap gelen Imp.),
						'other' => q({0} batu setiap gelen Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(batu setiap gelen Imp.),
						'other' => q({0} batu setiap gelen Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} timur),
						'north' => q({0} utara),
						'south' => q({0} selatan),
						'west' => q({0} barat),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} timur),
						'north' => q({0} utara),
						'south' => q({0} selatan),
						'west' => q({0} barat),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabait),
						'other' => q({0} gigabait),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabait),
						'other' => q({0} gigabait),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobait),
						'other' => q({0} kilobait),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobait),
						'other' => q({0} kilobait),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabait),
						'other' => q({0} megabait),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabait),
						'other' => q({0} megabait),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabait),
						'other' => q({0} petabait),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabait),
						'other' => q({0} petabait),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabait),
						'other' => q({0} terabait),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabait),
						'other' => q({0} terabait),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} setiap hari),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} setiap hari),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekad),
						'other' => q({0} dekad),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekad),
						'other' => q({0} dekad),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} jam),
						'per' => q({0} sejam),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} jam),
						'per' => q({0} sejam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosaat),
						'other' => q({0} mikrosaat),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosaat),
						'other' => q({0} mikrosaat),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0} milisaat),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0} milisaat),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} minit),
						'per' => q({0} setiap minit),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} minit),
						'per' => q({0} setiap minit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} bulan),
						'per' => q({0} setiap bulan),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} bulan),
						'per' => q({0} setiap bulan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q({0} nanosaat),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q({0} nanosaat),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0} setiap malam),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0} setiap malam),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(suku),
						'other' => q({0} suku),
						'per' => q({0}/suku),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(suku),
						'other' => q({0} suku),
						'per' => q({0}/suku),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0} sesaat),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0} sesaat),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} minggu),
						'per' => q({0} setiap minggu),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} minggu),
						'per' => q({0} setiap minggu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} tahun),
						'per' => q({0} setiap tahun),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} tahun),
						'per' => q({0} setiap tahun),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampere),
						'other' => q({0} miliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampere),
						'other' => q({0} miliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unit terma British),
						'other' => q({0} unit terma British),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unit terma British),
						'other' => q({0} unit terma British),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt jam),
						'other' => q({0} kilowatt jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt jam),
						'other' => q({0} kilowatt jam),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt jam setiap 100 kilometer),
						'other' => q({0} kilowatt jam setiap 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt jam setiap 100 kilometer),
						'other' => q({0} kilowatt jam setiap 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(paun daya),
						'other' => q({0} paun daya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(paun daya),
						'other' => q({0} paun daya),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(bintik sesentimeter),
						'other' => q({0} bintik sesentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(bintik sesentimeter),
						'other' => q({0} bintik sesentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(bintik seinci),
						'other' => q({0} bintik seinci),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(bintik seinci),
						'other' => q({0} bintik seinci),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipografi),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipografi),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel sesentimeter),
						'other' => q({0} piksel sesentimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel sesentimeter),
						'other' => q({0} piksel sesentimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel seinci),
						'other' => q({0} piksel seinci),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel seinci),
						'other' => q({0} piksel seinci),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} setiap sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} setiap sentimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius bumi),
						'other' => q({0} radius bumi),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius bumi),
						'other' => q({0} radius bumi),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'other' => q({0} fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'other' => q({0} fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0} kaki),
						'per' => q({0} sekaki),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0} kaki),
						'per' => q({0} sekaki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0} inci),
						'per' => q({0} seinci),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} inci),
						'per' => q({0} seinci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} setiap kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} setiap kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tahun cahaya),
						'other' => q({0} tahun cahaya),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tahun cahaya),
						'other' => q({0} tahun cahaya),
					},
					# Long Unit Identifier
					'length-meter' => {
						'other' => q({0} meter),
						'per' => q({0} setiap meter),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0} meter),
						'per' => q({0} setiap meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q({0} batu),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0} batu),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(batu-skandinavia),
						'other' => q({0} batu-skandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(batu-skandinavia),
						'other' => q({0} batu-skandinavia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(batu nautika),
						'other' => q({0} batu nautika),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(batu nautika),
						'other' => q({0} batu nautika),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} mata),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} mata),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(jejari solar),
						'other' => q({0} jejari solar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(jejari solar),
						'other' => q({0} jejari solar),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositi solar),
						'other' => q({0} luminositi solar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositi solar),
						'other' => q({0} luminositi solar),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Jisim bumi),
						'other' => q({0} Jisim bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Jisim bumi),
						'other' => q({0} Jisim bumi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} gram),
						'per' => q({0} setiap gram),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} gram),
						'per' => q({0} setiap gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'other' => q({0} kilogram),
						'per' => q({0} setiap kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'other' => q({0} kilogram),
						'per' => q({0} setiap kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0} auns),
						'per' => q({0} setiap auns),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0} auns),
						'per' => q({0} setiap auns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(auns troy),
						'other' => q({0} auns troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(auns troy),
						'other' => q({0} auns troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} paun),
						'per' => q({0} setiap paun),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} paun),
						'per' => q({0} setiap paun),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(jisim suria),
						'other' => q({0} jisim suria),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(jisim suria),
						'other' => q({0} jisim suria),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q({0} tan),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q({0} tan),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tan metrik),
						'other' => q({0} tan metrik),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tan metrik),
						'other' => q({0} tan metrik),
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
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kuasa kuda),
						'other' => q({0} kuasa kuda),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kuasa kuda),
						'other' => q({0} kuasa kuda),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} persegi),
						'other' => q({0} persegi),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} persegi),
						'other' => q({0} persegi),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} padu),
						'other' => q({0} padu),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} padu),
						'other' => q({0} padu),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopascal),
						'other' => q({0} hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopascal),
						'other' => q({0} hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inci raksa),
						'other' => q({0} inci raksa),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inci raksa),
						'other' => q({0} inci raksa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimeter raksa),
						'other' => q({0} milimeter raksa),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimeter raksa),
						'other' => q({0} milimeter raksa),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Pascal),
						'other' => q({0} Pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Pascal),
						'other' => q({0} Pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(paun seinci persegi),
						'other' => q({0} paun seinci persegi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(paun seinci persegi),
						'other' => q({0} paun seinci persegi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometer sejam),
						'other' => q({0} kilometer sejam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer sejam),
						'other' => q({0} kilometer sejam),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter sesaat),
						'other' => q({0} meter sesaat),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter sesaat),
						'other' => q({0} meter sesaat),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(batu sejam),
						'other' => q({0} batu sejam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(batu sejam),
						'other' => q({0} batu sejam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(darjah Celsius),
						'other' => q({0} darjah Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(darjah Celsius),
						'other' => q({0} darjah Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(darjah Fahrenheit),
						'other' => q({0} darjah Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(darjah Fahrenheit),
						'other' => q({0} darjah Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton meter),
						'other' => q({0} newton meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton meter),
						'other' => q({0} newton meter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(kaki paun),
						'other' => q({0} kaki paun),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(kaki paun),
						'other' => q({0} kaki paun),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekar-kaki),
						'other' => q({0} ekar-kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekar-kaki),
						'other' => q({0} ekar-kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tong),
						'other' => q({0} tong),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tong),
						'other' => q({0} tong),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(busyel),
						'other' => q({0} busyel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(busyel),
						'other' => q({0} busyel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentimeter padu),
						'other' => q({0} sentimeter padu),
						'per' => q({0} setiap sentimeter padu),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimeter padu),
						'other' => q({0} sentimeter padu),
						'per' => q({0} setiap sentimeter padu),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki padu),
						'other' => q({0} kaki padu),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki padu),
						'other' => q({0} kaki padu),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci padu),
						'other' => q({0} inci padu),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci padu),
						'other' => q({0} inci padu),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometer padu),
						'other' => q({0} kilometer padu),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometer padu),
						'other' => q({0} kilometer padu),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(meter padu),
						'other' => q({0} meter padu),
						'per' => q({0} setiap meter padu),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(meter padu),
						'other' => q({0} meter padu),
						'per' => q({0} setiap meter padu),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(batu padu),
						'other' => q({0} batu padu),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(batu padu),
						'other' => q({0} batu padu),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ela padu),
						'other' => q({0} ela padu),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ela padu),
						'other' => q({0} ela padu),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} cawan),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} cawan),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0} cawan metrik),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0} cawan metrik),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sudu desert),
						'other' => q({0} sudu desert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sudu desert),
						'other' => q({0} sudu desert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(sudu desert Imp.),
						'other' => q({0} sudu desert Imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(sudu desert Imp.),
						'other' => q({0} sudu desert Imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(auns cecair),
						'other' => q({0} auns cecair),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(auns cecair),
						'other' => q({0} auns cecair),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gelen),
						'other' => q({0} gelen),
						'per' => q({0} segelen),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gelen),
						'other' => q({0} gelen),
						'per' => q({0} segelen),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} liter),
						'per' => q({0} setiap liter),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} liter),
						'per' => q({0} setiap liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} pain),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} pain),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pain metrik),
						'other' => q({0} pain metrik),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pain metrik),
						'other' => q({0} pain metrik),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kuart Imp.),
						'other' => q({0} kuart Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kuart Imp.),
						'other' => q({0} kuart Imp.),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ka²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ka²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(bt²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(bt²),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
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
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0}/malam),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0}/malam),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(thn),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(thn),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'other' => q({0}kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'other' => q({0}kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'other' => q({0}kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'other' => q({0}kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'other' => q({0}terma US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'other' => q({0}terma US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ka),
						'other' => q({0}'),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ka),
						'other' => q({0}'),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'other' => q({0}"),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'other' => q({0}"),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'other' => q({0} t. chya),
					},
					# Core Unit Identifier
					'light-year' => {
						'other' => q({0} t. chya),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(bt),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(bt),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'other' => q({0}nm),
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
						'name' => q(mt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(mt),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'other' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0} auns),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0} auns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'other' => q({0} paun),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0} paun),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/j),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/j),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'other' => q({0} dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'other' => q({0} dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'other' => q({0}dr.fl.),
					},
					# Core Unit Identifier
					'dram' => {
						'other' => q({0}dr.fl.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0}galIm),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsp),
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(daya g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(daya g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(min arka),
						'other' => q({0} min arka),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(min arka),
						'other' => q({0} min arka),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(saat arka),
						'other' => q({0} saat arka),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(saat arka),
						'other' => q({0} saat arka),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(darjah),
						'other' => q({0} darjah),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(darjah),
						'other' => q({0} darjah),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ekar),
						'other' => q({0} ekar),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekar),
						'other' => q({0} ekar),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ka persegi),
						'other' => q({0} ka²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ka persegi),
						'other' => q({0} ka²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(batu persegi),
						'other' => q({0} bt²),
						'per' => q({0}/bt²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(batu persegi),
						'other' => q({0} bt²),
						'per' => q({0}/bt²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ela²),
						'other' => q({0} ela²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ela²),
						'other' => q({0} ela²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(peratus),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(peratus),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per seribu),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per seribu),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(bahagian/bilion),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(bahagian/bilion),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(batu/gal),
						'other' => q({0} bpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(batu/gal),
						'other' => q({0} bpg),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bait),
						'other' => q({0} bait),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bait),
						'other' => q({0} bait),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GBait),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBait),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kBait),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBait),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MBait),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBait),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TBait),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBait),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(hari),
						'other' => q({0} hari),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(hari),
						'other' => q({0} hari),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dkd),
						'other' => q({0} dkd),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dkd),
						'other' => q({0} dkd),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jam),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jam),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsaat),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsaat),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisaat),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisaat),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bulan),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosaat),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosaat),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0}/malam),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(malam),
						'other' => q({0} malam),
						'per' => q({0}/malam),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(sk),
						'other' => q({0} sk),
						'per' => q({0}/sk),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(sk),
						'other' => q({0} sk),
						'per' => q({0}/sk),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(saat),
						'other' => q({0} saat),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(saat),
						'other' => q({0} saat),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(minggu),
						'other' => q({0} mgu),
						'per' => q({0}/mgu),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(minggu),
						'other' => q({0} mgu),
						'per' => q({0}/mgu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(tahun),
						'other' => q({0} thn),
						'per' => q({0}/thn),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(tahun),
						'other' => q({0} thn),
						'per' => q({0}/thn),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamp),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(utB),
						'other' => q({0} utB),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(utB),
						'other' => q({0} utB),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
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
						'name' => q(terma US),
						'other' => q({0} terma US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(terma US),
						'other' => q({0} terma US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWj/100km),
						'other' => q({0} kWj/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWj/100km),
						'other' => q({0} kWj/100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(bintik),
						'other' => q({0} bintik),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(bintik),
						'other' => q({0} bintik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(kaki),
						'other' => q({0} ka),
						'per' => q({0}/ka),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} ka),
						'per' => q({0}/ka),
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
						'name' => q(inci),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inci),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} thn cahaya),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} thn cahaya),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmeter),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmeter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(batu),
						'other' => q({0} bt),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(batu),
						'other' => q({0} bt),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(btn),
						'other' => q({0} btn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(btn),
						'other' => q({0} btn),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(mata),
						'other' => q({0} mt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(mata),
						'other' => q({0} mt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ela),
						'other' => q({0} ela),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ela),
						'other' => q({0} ela),
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
						'name' => q(lumonisiti suria),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(lumonisiti suria),
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
					'mass-kilogram' => {
						'name' => q(kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(auns),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(auns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(paun),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(paun),
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
						'name' => q(tan),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tan),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} kmj),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} kmj),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(cahaya),
						'other' => q({0} cahaya),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/saat),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/saat),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(batu/jam),
						'other' => q({0} bsj),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(batu/jam),
						'other' => q({0} bsj),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(darjah C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(darjah C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(darjah F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(darjah F),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekar ka),
						'other' => q({0} ekar ka),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekar ka),
						'other' => q({0} ekar ka),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ka³),
						'other' => q({0} ka³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ka³),
						'other' => q({0} ka³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(bt³),
						'other' => q({0} bt³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(bt³),
						'other' => q({0} bt³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cawan),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cawan),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cawan metrik),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cawan metrik),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(titis),
						'other' => q({0} titis),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(titis),
						'other' => q({0} titis),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(cubit),
						'other' => q({0} cubit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(cubit),
						'other' => q({0} cubit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pain),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pain),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sudu besar),
						'other' => q({0} sudu besar),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sudu besar),
						'other' => q({0} sudu besar),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sudu teh),
						'other' => q({0} sudu teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sudu teh),
						'other' => q({0} sudu teh),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ya|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:tidak|t|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} dan {1}),
				2 => q({0} dan {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'decimal' => q(.),
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
					'other' => '0 ribu',
				},
				'10000' => {
					'other' => '00 ribu',
				},
				'100000' => {
					'other' => '000 ribu',
				},
				'1000000' => {
					'other' => '0 juta',
				},
				'10000000' => {
					'other' => '00 juta',
				},
				'100000000' => {
					'other' => '000 juta',
				},
				'1000000000' => {
					'other' => '0 bilion',
				},
				'10000000000' => {
					'other' => '00 bilion',
				},
				'100000000000' => {
					'other' => '000 bilion',
				},
				'1000000000000' => {
					'other' => '0 trilion',
				},
				'10000000000000' => {
					'other' => '00 trilion',
				},
				'100000000000000' => {
					'other' => '000 trilion',
				},
			},
			'short' => {
				'1000000' => {
					'other' => '0J',
				},
				'10000000' => {
					'other' => '00J',
				},
				'100000000' => {
					'other' => '000J',
				},
				'1000000000' => {
					'other' => '0B',
				},
				'10000000000' => {
					'other' => '00B',
				},
				'100000000000' => {
					'other' => '000B',
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
				'currency' => q(Dirham Emiriah Arab Bersatu),
				'other' => q(Dirham UAE),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Antillen Belanda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Boleh Tukar Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rubel Belarus baharu),
				'other' => q(Rubel Belarus),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rubel Belarus \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Belize),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Congo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Switzerland),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan China \(luar pesisir\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Cina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Colombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Boleh Tukar Cuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Republik Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominican),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Paun Mesir),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Paun Kepulauan Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Paun British),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Paun Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Syekel Baharu Israel),
				'other' => q(Syekel baharu Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Krona Iceland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Jordan),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Jepun),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Syiling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kyrgystani),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Kemboja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Comoria),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Korea Utara),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Korea Selatan),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar Kepulauan Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kazakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Paun Lubnan),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas Lithuania),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats Latvia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Maghribi),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Malagasy),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Franc Malagasy),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanma),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Peso Mexico),
			},
		},
		'MYR' => {
			symbol => 'RM',
			display_name => {
				'currency' => q(Ringgit Malaysia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mozambique),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical Mozambique \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metikal Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Norway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua New Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Filipina),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Poland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Qatar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Dolar Rhodesia),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel Rusia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar Kepulauan Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Paun Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Sweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paun Saint Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Syiling Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Paun Sudan selatan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra Sao Tome dan Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Sao Tome dan Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Paun Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swazi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht Thai),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Pa’anga Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turki),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar Trinidad dan Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dolar Taiwan Baru),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Syiling Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukraine),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Shilling Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Syiling Uganda),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(Dolar AS),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Uzbekistan),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolivar Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franc CFA BEAC),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Caribbean Timur),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA BCEAO),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mata Wang Tidak Diketahui),
				'other' => q(\(mata wang tidak diketahui\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yaman),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Afrika Selatan),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dolar Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Dolar Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Dolar Zimbabwe \(2008\)),
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
							'Jan',
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ogo',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Jn',
							'Fb',
							'Mc',
							'Ap',
							'Me',
							'Ju',
							'Jl',
							'Og',
							'Sp',
							'Ok',
							'Nv',
							'Ds'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Mac',
							'April',
							'Mei',
							'Jun',
							'Julai',
							'Ogos',
							'September',
							'Oktober',
							'November',
							'Disember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Jn',
							'Fe',
							'Mc',
							'Ap',
							'Me',
							'Ju',
							'Jl',
							'Og',
							'Sp',
							'Ok',
							'Nv',
							'Ds'
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
							'Jan',
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ogo',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Mac',
							'April',
							'Mei',
							'Jun',
							'Julai',
							'Ogos',
							'September',
							'Oktober',
							'November',
							'Disember'
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
							'O',
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jam. I',
							'Jam. II',
							'Rej.',
							'Syaa.',
							'Ram.',
							'Syaw.',
							'Zulk.',
							'Zulh.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharam',
							'Safar',
							'Rabiulawal',
							'Rabiulakhir',
							'Jamadilawal',
							'Jamadilakhir',
							'Rejab',
							'Syaaban',
							'Ramadan',
							'Syawal',
							'Zulkaedah',
							'Zulhijah'
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
						mon => 'Isn',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kha',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					short => {
						mon => 'Is',
						tue => 'Se',
						wed => 'Ra',
						thu => 'Kh',
						fri => 'Ju',
						sat => 'Sa',
						sun => 'Ah'
					},
					wide => {
						mon => 'Isnin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Khamis',
						fri => 'Jumaat',
						sat => 'Sabtu',
						sun => 'Ahad'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'I',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
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
					abbreviated => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					wide => {0 => 'Suku pertama',
						1 => 'Suku Ke-2',
						2 => 'Suku Ke-3',
						3 => 'Suku Ke-4'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
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
					'afternoon1' => q{tengah hari},
					'am' => q{PG},
					'evening1' => q{petang},
					'morning1' => q{pagi},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{PTG},
				},
				'wide' => {
					'afternoon1' => q{tengah hari},
					'evening1' => q{petang},
					'morning1' => q{tengah malam},
					'morning2' => q{pagi},
					'night1' => q{malam},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{tengah hari},
					'evening1' => q{petang},
					'morning1' => q{tengah malam},
					'morning2' => q{pagi},
					'night1' => q{malam},
				},
				'narrow' => {
					'afternoon1' => q{tengah hari},
					'evening1' => q{petang},
					'morning1' => q{pagi},
					'morning2' => q{pagi},
					'night1' => q{malam},
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
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'S.M.',
				'1' => 'TM'
			},
		},
		'hebrew' => {
		},
		'islamic' => {
			abbreviated => {
				'0' => 'H'
			},
			wide => {
				'0' => 'AH'
			},
		},
		'japanese' => {
		},
		'roc' => {
			narrow => {
				'0' => 'Sblm R.O.C'
			},
			wide => {
				'0' => 'Sebelum R.O.C'
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
			'full' => q{EEEE, d MMMM r(U)},
			'long' => q{d MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{d/M/r},
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/MM/yy},
		},
		'hebrew' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y GGGGG},
		},
		'islamic' => {
		},
		'japanese' => {
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
		},
		'japanese' => {
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
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d-M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'minggu' W 'daripada' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'minggu' w 'daripada' Y},
		},
		'hebrew' => {
			y => q{y},
		},
		'islamic' => {
			GyMd => q{d/M/y GGGGG},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMd => q{d/M/y GGGGG},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d–d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGG – E, dd-MM-y GGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E,d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Waktu {0}),
		regionFormat => q(Waktu Siang {0}),
		regionFormat => q(Waktu Piawai {0}),
		'Acre' => {
			long => {
				'daylight' => q#Waktu Musim Panas Acre#,
				'generic' => q#Waktu Acre#,
				'standard' => q#Waktu Piawai Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Waktu Afghanistan#,
			},
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaherah#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Waktu Afrika Tengah#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Waktu Afrika Timur#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Waktu Piawai Afrika Selatan#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Afrika Barat#,
				'generic' => q#Waktu Afrika Barat#,
				'standard' => q#Waktu Piawai Afrika Barat#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waktu Siang Alaska#,
				'generic' => q#Waktu Alaska#,
				'standard' => q#Waktu Piawai Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Waktu Musim Panas Almaty#,
				'generic' => q#Waktu Almaty#,
				'standard' => q#Waktu Piawai Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waktu Musim Panas Amazon#,
				'generic' => q#Waktu Amazon#,
				'standard' => q#Waktu Piawai Amazon#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Teluk Cambridge#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Teluk Glace#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Teluk Goose#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthelemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Waktu Siang Tengah#,
				'generic' => q#Waktu Pusat#,
				'standard' => q#Waktu Piawai Pusat#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waktu Siang Timur#,
				'generic' => q#Waktu Timur#,
				'standard' => q#Waktu Piawai Timur#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waktu Siang Pergunungan#,
				'generic' => q#Waktu Pergunungan#,
				'standard' => q#Waktu Piawai Pergunungan#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waktu Siang Pasifik#,
				'generic' => q#Waktu Pasifik#,
				'standard' => q#Waktu Piawai Pasifik#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Waktu Musim Panas Anadyr#,
				'generic' => q#Waktu Anadyr#,
				'standard' => q#Waktu Piawai Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Waktu Siang Apia#,
				'generic' => q#Waktu Apia#,
				'standard' => q#Waktu Piawai Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Waktu Musim Panas Aqtau#,
				'generic' => q#Waktu Aqtau#,
				'standard' => q#Waktu Standard Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Waktu Musim Panas Aqtobe#,
				'generic' => q#Waktu Aqtobe#,
				'standard' => q#Waktu Piawai Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waktu Siang Arab#,
				'generic' => q#Waktu Arab#,
				'standard' => q#Waktu Piawai Arab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waktu Musim Panas Argentina#,
				'generic' => q#Waktu Argentina#,
				'standard' => q#Waktu Piawai Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Argentina Barat#,
				'generic' => q#Waktu Argentina Barat#,
				'standard' => q#Waktu Piawai Argentina Barat#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Armenia#,
				'generic' => q#Waktu Armenia#,
				'standard' => q#Waktu Piawai Armenia#,
			},
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damsyik#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Baitulmuqaddis#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waktu Siang Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Piawai Atlantik#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Waktu Siang Australia Tengah#,
				'generic' => q#Waktu Australia Tengah#,
				'standard' => q#Waktu Piawai Australia Tengah#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waktu Siang Barat Tengah Australia#,
				'generic' => q#Waktu Barat Tengah Australia#,
				'standard' => q#Waktu Piawai Barat Tengah Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waktu Siang Australia Timur#,
				'generic' => q#Waktu Australia Timur#,
				'standard' => q#Waktu Piawai Timur Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waktu Siang Australia Barat#,
				'generic' => q#Waktu Australia Barat#,
				'standard' => q#Waktu Piawai Australia Barat#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Azerbaijan#,
				'generic' => q#Waktu Azerbaijan#,
				'standard' => q#Waktu Piawai Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Waktu Musim Panas Azores#,
				'generic' => q#Waktu Azores#,
				'standard' => q#Waktu Piawai Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waktu Musim Panas Bangladesh#,
				'generic' => q#Waktu Bangladesh#,
				'standard' => q#Waktu Piawai Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Waktu Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Waktu Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Brasilia#,
				'generic' => q#Waktu Brasilia#,
				'standard' => q#Waktu Piawai Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Waktu Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Waktu Musim Panas Tanjung Verde#,
				'generic' => q#Waktu Tanjung Verde#,
				'standard' => q#Waktu Piawai Tanjung Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Waktu Piawai Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Waktu Siang Chatham#,
				'generic' => q#Waktu Chatham#,
				'standard' => q#Waktu Piawai Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waktu Musim Panas Chile#,
				'generic' => q#Waktu Chile#,
				'standard' => q#Waktu Piawai Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Waktu Siang China#,
				'generic' => q#Waktu China#,
				'standard' => q#Waktu Piawai China#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Waktu Pulau Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waktu Kepulauan Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Colombia#,
				'generic' => q#Waktu Colombia#,
				'standard' => q#Waktu Piawai Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Waktu Musim Panas Separuh Kepulauan Cook#,
				'generic' => q#Waktu Kepulauan Cook#,
				'standard' => q#Waktu Piawai Kepulauan Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Waktu Siang Cuba#,
				'generic' => q#Waktu Cuba#,
				'standard' => q#Waktu Piawai Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Waktu Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Waktu Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Waktu Timor Timur#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pulau Easter#,
				'generic' => q#Waktu Pulau Easter#,
				'standard' => q#Waktu Piawai Pulau Easter#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Waktu Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waktu Universal Selaras#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Bandar Tidak Diketahui#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Waktu Piawai Ireland#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Waktu Musim Panas British#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropah Tengah#,
				'generic' => q#Waktu Eropah Tengah#,
				'standard' => q#Waktu Piawai Eropah Tengah#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropah Timur#,
				'generic' => q#Waktu Eropah Timur#,
				'standard' => q#Waktu Piawai Eropah Timur#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Waktu Eropah ceruk timur#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropah Barat#,
				'generic' => q#Waktu Eropah Barat#,
				'standard' => q#Waktu Piawai Eropah Barat#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Waktu Musim Panas Kepulauan Falkland#,
				'generic' => q#Waktu Kepulauan Falkland#,
				'standard' => q#Waktu Piawai Kepulauan Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Waktu Musim Panas Fiji#,
				'generic' => q#Waktu Fiji#,
				'standard' => q#Waktu Piawai Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Waktu Guyana Perancis#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waktu Perancis Selatan dan Antartika#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Waktu Min Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waktu Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Waktu Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Georgia#,
				'generic' => q#Waktu Georgia#,
				'standard' => q#Waktu Piawai Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Waktu Kepulauan Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Greenland Timur#,
				'generic' => q#Waktu Greenland Timur#,
				'standard' => q#Waktu Piawai Greenland Timur#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Greenland Barat#,
				'generic' => q#Waktu Greenland Barat#,
				'standard' => q#Waktu Piawai Greenland Barat#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waktu Piawai Teluk#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waktu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waktu Siang Hawaii-Aleutian#,
				'generic' => q#Waktu Hawaii-Aleutian#,
				'standard' => q#Waktu Piawai Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Waktu Musim Panas Hong Kong#,
				'generic' => q#Waktu Hong Kong#,
				'standard' => q#Waktu Piawai Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Waktu Musim Panas Hovd#,
				'generic' => q#Waktu Hovd#,
				'standard' => q#Waktu Piawai Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waktu Piawai India#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Waktu Lautan Hindi#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Waktu Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Waktu Indonesia Tengah#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Waktu Indonesia Timur#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waktu Indonesia Barat#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waktu Siang Iran#,
				'generic' => q#Waktu Iran#,
				'standard' => q#Waktu Piawai Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Irkutsk#,
				'generic' => q#Waktu Irkutsk#,
				'standard' => q#Waktu Piawai Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Waktu Siang Israel#,
				'generic' => q#Waktu Israel#,
				'standard' => q#Waktu Piawai Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Waktu Siang Jepun#,
				'generic' => q#Waktu Jepun#,
				'standard' => q#Waktu Piawai Jepun#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Waktu Musim Panas Petropavlovsk-Kamchatski#,
				'generic' => q#Waktu Petropavlovsk-Kamchatski#,
				'standard' => q#Waktu Piawai Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Waktu Kazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Waktu Kazakhstan Timur#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Waktu Kazakhstan Barat#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Waktu Siang Korea#,
				'generic' => q#Waktu Korea#,
				'standard' => q#Waktu Piawai Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Waktu Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Krasnoyarsk#,
				'generic' => q#Waktu Krasnoyarsk#,
				'standard' => q#Waktu Piawai Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waktu Kyrgystan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waktu Kepulauan Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Waktu Siang Lord Howe#,
				'generic' => q#Waktu Lord Howe#,
				'standard' => q#Waktu Piawai Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Waktu Musim Panas Macao#,
				'generic' => q#Waktu Macao#,
				'standard' => q#Waktu Piawai Macao#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Magadan#,
				'generic' => q#Waktu Magadan#,
				'standard' => q#Waktu Piawai Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Waktu Malaysia#,
			},
			short => {
				'standard' => q#MYT#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waktu Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waktu Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Waktu Kepulauan Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waktu Musim Panas Mauritius#,
				'generic' => q#Waktu Mauritius#,
				'standard' => q#Waktu Piawai Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Waktu Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waktu Siang Pasifik Mexico#,
				'generic' => q#Waktu Pasifik Mexico#,
				'standard' => q#Waktu Piawai Pasifik Mexico#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Ulan Bator#,
				'generic' => q#Waktu Ulan Bator#,
				'standard' => q#Waktu Piawai Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waktu Musim Panas Moscow#,
				'generic' => q#Waktu Moscow#,
				'standard' => q#Waktu Piawai Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Waktu Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Waktu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Waktu Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Waktu Musim Panas New Caledonia#,
				'generic' => q#Waktu New Caledonia#,
				'standard' => q#Waktu Piawai New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Waktu Siang New Zealand#,
				'generic' => q#Waktu New Zealand#,
				'standard' => q#Waktu Piawai New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Waktu Siang Newfoundland#,
				'generic' => q#Waktu Newfoundland#,
				'standard' => q#Waktu Piawai Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waktu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Waktu Siang Kepulauan Norfolk#,
				'generic' => q#Waktu Kepulauan Norfolk#,
				'standard' => q#Waktu Piawai Kepulauan Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Waktu Musim Panas Fernando de Noronha#,
				'generic' => q#Waktu Fernando de Noronha#,
				'standard' => q#Waktu Piawai Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Waktu Kepulauan Mariana Utara#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Novosibirsk#,
				'generic' => q#Waktu Novosibirsk#,
				'standard' => q#Waktu Piawai Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Omsk#,
				'generic' => q#Waktu Omsk#,
				'standard' => q#Waktu Piawai Omsk#,
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
				'daylight' => q#Waktu Musim Panas Pakistan#,
				'generic' => q#Waktu Pakistan#,
				'standard' => q#Waktu Piawai Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Waktu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Waktu Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Waktu Musim Panas Paraguay#,
				'generic' => q#Waktu Paraguay#,
				'standard' => q#Waktu Piawai Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Waktu Musim Panas Peru#,
				'generic' => q#Waktu Peru#,
				'standard' => q#Waktu Piawai Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Waktu Musim Panas Filipina#,
				'generic' => q#Waktu Filipina#,
				'standard' => q#Waktu Piawai Filipina#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Waktu Kepulauan Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Waktu Siang Saint Pierre dan Miquelon#,
				'generic' => q#Waktu Saint Pierre dan Miquelon#,
				'standard' => q#Waktu Piawai Saint Pierre dan Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Waktu Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Waktu Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Waktu Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Waktu Musim Panas Qyzylorda#,
				'generic' => q#Waktu Qyzylorda#,
				'standard' => q#Waktu Piawai Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Waktu Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Waktu Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Waktu Musim Panas Sakhalin#,
				'generic' => q#Waktu Sakhalin#,
				'standard' => q#Waktu Piawai Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Waktu Musim Panas Samara#,
				'generic' => q#Waktu Samara#,
				'standard' => q#Waktu Piawai Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Waktu Musim Panas Samoa#,
				'generic' => q#Waktu Samoa#,
				'standard' => q#Waktu Piawai Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waktu Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Waktu Piawai Singapura#,
			},
			short => {
				'standard' => q#SGT#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Waktu Kepulauan Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Waktu Georgia Selatan#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Waktu Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Waktu Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Waktu Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Waktu Siang Taipei#,
				'generic' => q#Waktu Taipei#,
				'standard' => q#Waktu Piawai Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Waktu Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Waktu Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Waktu Musim Panas Tonga#,
				'generic' => q#Waktu Tonga#,
				'standard' => q#Waktu Piawai Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Waktu Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Turkmenistan#,
				'generic' => q#Waktu Turkmenistan#,
				'standard' => q#Waktu Piawai Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Waktu Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Waktu Musim Panas Uruguay#,
				'generic' => q#Waktu Uruguay#,
				'standard' => q#Waktu Piawai Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Uzbekistan#,
				'generic' => q#Waktu Uzbekistan#,
				'standard' => q#Waktu Piawai Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waktu Musim Panas Vanuatu#,
				'generic' => q#Waktu Vanuatu#,
				'standard' => q#Waktu Piawai Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Waktu Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waktu Musim Panas Vladivostok#,
				'generic' => q#Waktu Vladivostok#,
				'standard' => q#Waktu Piawai Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Waktu Musim Panas Volgograd#,
				'generic' => q#Waktu Volgograd#,
				'standard' => q#Waktu Piawai Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waktu Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waktu Pulau Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Waktu Wallis dan Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Yakutsk#,
				'generic' => q#Waktu Yakutsk#,
				'standard' => q#Waktu Piawai Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Waktu Musim Panas Yekaterinburg#,
				'generic' => q#Waktu Yekaterinburg#,
				'standard' => q#Waktu Piawai Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Masa Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
