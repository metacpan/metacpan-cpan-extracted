=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ms - Package for language Malay

=cut

package Locale::CLDR::Locales::Ms;
# This file auto generated from Data\common\main\ms.xml
#	on Tue  5 Dec  1:22:10 pm GMT

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
				'max' => {
					base_value => q(0),
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
					rule => q(←← titik →→),
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
					rule => q(←← juta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← milyar[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← bilyun[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← bilyar[ →→]),
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
 				'bgn' => 'Balochi Barat',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Benggala',
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
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Kurdi Sorani',
 				'co' => 'Corsica',
 				'cop' => 'Coptic',
 				'crh' => 'Turki Krimea',
 				'crs' => 'Perancis Seselwa Creole',
 				'cs' => 'Czech',
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
 				'gu' => 'Gujerat',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hak' => 'Cina Hakka',
 				'haw' => 'Hawaii',
 				'he' => 'Ibrani',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Croatia',
 				'hsb' => 'Sorbian Atas',
 				'hsn' => 'Cina Xiang',
 				'ht' => 'Haiti',
 				'hu' => 'Hungary',
 				'hup' => 'Hupa',
 				'hy' => 'Armenia',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesia',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
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
 				'ky' => 'Kirghiz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lb' => 'Luxembourg',
 				'lez' => 'Lezghian',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Laos',
 				'lou' => 'Kreol Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Utara',
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
 				'nb' => 'Bokmål Norway',
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
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossete',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Nigerian Pidgin',
 				'pl' => 'Poland',
 				'prg' => 'Prusia',
 				'ps' => 'Pashto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portugis',
 				'pt_BR' => 'Portugis Brazil',
 				'pt_PT' => 'Portugis Eropah',
 				'qu' => 'Quechua',
 				'quc' => 'Kʼicheʼ',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotonga',
 				'rm' => 'Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Romania',
 				'ro_MD' => 'Moldavia',
 				'rof' => 'Rombo',
 				'root' => 'Root',
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
 				'su' => 'Sunda',
 				'suk' => 'Sukuma',
 				'sv' => 'Sweden',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Congo Swahili',
 				'swb' => 'Comoria',
 				'syr' => 'Syriac',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tly' => 'Talysh',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tatar',
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
 				'vi' => 'Vietnam',
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
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yue' => 'Kantonis',
 				'zgh' => 'Tamazight Maghribi Standard',
 				'zh' => 'Cina',
 				'zh_Hans' => 'Cina Ringkas',
 				'zh_Hant' => 'Cina Tradisional',
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
			'Arab' => 'Arab',
 			'Arab@alt=variant' => 'Perso-Arab',
 			'Armn' => 'Armenia',
 			'Bali' => 'Bali',
 			'Bamu' => 'Bamu',
 			'Beng' => 'Benggala',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cans' => 'Cans',
 			'Cyrl' => 'Cyril',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopia',
 			'Geor' => 'Georgia',
 			'Grek' => 'Greek',
 			'Gujr' => 'Gujarat',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han dengan Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Ringkas',
 			'Hans@alt=stand-alone' => 'Han Ringkas',
 			'Hant' => 'Tradisional',
 			'Hant@alt=stand-alone' => 'Han Tradisional',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Ejaan sukuan Jepun',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Jepun',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korea',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latin',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolia',
 			'Mymr' => 'Myammar',
 			'Orya' => 'Oriya',
 			'Sinh' => 'Sinhala',
 			'Taml' => 'Tamil',
 			'Telu' => 'Telugu',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibet',
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
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (FYROM)',
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
 			'SZ' => 'Swaziland',
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
 			'TR' => 'Turki',
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
			'POSIX' => 'Komputer',

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
 			'cf' => 'Format Mata wang',
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
 				'reformed' => q{Aturan Isih Pembaharuan},
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
 			'UK' => q{UK},
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
			main => qr{[a {ai} {au} b c d {dz} e f g h i j k {kh} l m n {ng} {ngg} {ny} o p q r s {sy} t {ts} u {ua} v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
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
					'' => {
						'name' => q(arah mata angin),
					},
					'acre' => {
						'name' => q(ekar),
						'other' => q({0} ekar),
					},
					'acre-foot' => {
						'name' => q(ekar-kaki),
						'other' => q({0} ekar-kaki),
					},
					'ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(minit arka),
						'other' => q({0} minit arka),
					},
					'arc-second' => {
						'name' => q(saat arka),
						'other' => q({0} saat arka),
					},
					'astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					'atmosphere' => {
						'name' => q(atmosfera),
						'other' => q({0} atmosfera),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bait),
						'other' => q({0} bait),
					},
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(darjah Celsius),
						'other' => q({0} darjah Celsius),
					},
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} setiap sentimeter),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0} timur),
						'north' => q({0} utara),
						'south' => q({0} selatan),
						'west' => q({0} barat),
					},
					'cubic-centimeter' => {
						'name' => q(sentimeter padu),
						'other' => q({0} sentimeter padu),
						'per' => q({0} setiap sentimeter padu),
					},
					'cubic-foot' => {
						'name' => q(kaki padu),
						'other' => q({0} kaki padu),
					},
					'cubic-inch' => {
						'name' => q(inci padu),
						'other' => q({0} inci padu),
					},
					'cubic-kilometer' => {
						'name' => q(kilometer padu),
						'other' => q({0} kilometer padu),
					},
					'cubic-meter' => {
						'name' => q(meter padu),
						'other' => q({0} meter padu),
						'per' => q({0} setiap meter padu),
					},
					'cubic-mile' => {
						'name' => q(batu padu),
						'other' => q({0} batu padu),
					},
					'cubic-yard' => {
						'name' => q(ela padu),
						'other' => q({0} ela padu),
					},
					'cup' => {
						'name' => q(cawan),
						'other' => q({0} cawan),
					},
					'cup-metric' => {
						'name' => q(cawan metrik),
						'other' => q({0} cawan metrik),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0} hari),
						'per' => q({0} setiap hari),
					},
					'deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					'decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					'degree' => {
						'name' => q(darjah),
						'other' => q({0} darjah),
					},
					'fahrenheit' => {
						'name' => q(darjah Fahrenheit),
						'other' => q({0} darjah Fahrenheit),
					},
					'fathom' => {
						'name' => q(fathom),
						'other' => q({0} fathom),
					},
					'fluid-ounce' => {
						'name' => q(auns cecair),
						'other' => q({0} auns cecair),
					},
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0} sekaki),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0} furlong),
					},
					'g-force' => {
						'name' => q(daya g),
						'other' => q({0} daya g),
					},
					'gallon' => {
						'name' => q(gelen),
						'other' => q({0} gelen),
						'per' => q({0} segelen),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabait),
						'other' => q({0} gigabait),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0} gram),
						'per' => q({0} setiap gram),
					},
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'other' => q({0} hektopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(kuasa kuda),
						'other' => q({0} kuasa kuda),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0} sejam),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} seinci),
					},
					'inch-hg' => {
						'name' => q(inci raksa),
						'other' => q({0} inci raksa),
					},
					'joule' => {
						'name' => q(joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobait),
						'other' => q({0} kilobait),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} setiap kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'other' => q({0} kilojoule),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} setiap kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer sejam),
						'other' => q({0} kilometer sejam),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt jam),
						'other' => q({0} kilowatt jam),
					},
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					'light-year' => {
						'name' => q(tahun cahaya),
						'other' => q({0} tahun cahaya),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} liter),
						'per' => q({0} setiap liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter setiap 100 kilometer),
						'other' => q({0} liter setiap 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter sekilometer),
						'other' => q({0} liter sekilometer),
					},
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabait),
						'other' => q({0} megabait),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} setiap meter),
					},
					'meter-per-second' => {
						'name' => q(meter sesaat),
						'other' => q({0} meter sesaat),
					},
					'meter-per-second-squared' => {
						'name' => q(meter sesaat ganda dua),
						'other' => q({0} meter sesaat ganda dua),
					},
					'metric-ton' => {
						'name' => q(metrik tan),
						'other' => q({0} metrik tan),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					'microsecond' => {
						'name' => q(mikrosaat),
						'other' => q({0} mikrosaat),
					},
					'mile' => {
						'name' => q(batu),
						'other' => q({0} batu),
					},
					'mile-per-gallon' => {
						'name' => q(batu segelen),
						'other' => q({0} batu segelen),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(batu setiap gelen Imp.),
						'other' => q({0} batu setiap gelen Imp.),
					},
					'mile-per-hour' => {
						'name' => q(batu sejam),
						'other' => q({0} batu sejam),
					},
					'mile-scandinavian' => {
						'name' => q(batu-skandinavia),
						'other' => q({0} batu-skandinavia),
					},
					'milliampere' => {
						'name' => q(miliampere),
						'other' => q({0} miliampere),
					},
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligram setiap desiliter),
						'other' => q({0} miligram setiap desiliter),
					},
					'milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					'millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimeter raksa),
						'other' => q({0} milimeter raksa),
					},
					'millimole-per-liter' => {
						'name' => q(milimol setiap liter),
						'other' => q({0} milimol setiap liter),
					},
					'millisecond' => {
						'name' => q(milisaat),
						'other' => q({0} milisaat),
					},
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					'minute' => {
						'name' => q(minit),
						'other' => q({0} minit),
						'per' => q({0} setiap minit),
					},
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bulan),
						'per' => q({0} setiap bulan),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanosaat),
						'other' => q({0} nanosaat),
					},
					'nautical-mile' => {
						'name' => q(batu nautika),
						'other' => q({0} batu nautika),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(auns),
						'other' => q({0} auns),
						'per' => q({0} setiap auns),
					},
					'ounce-troy' => {
						'name' => q(auns troy),
						'other' => q({0} auns troy),
					},
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(bahagian setiap juta),
						'other' => q({0} bahagian setiap juta),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'percent' => {
						'name' => q(peratus),
						'other' => q({0} peratus),
					},
					'permille' => {
						'name' => q(per seribu),
						'other' => q({0} per seribu),
					},
					'petabyte' => {
						'name' => q(petabait),
						'other' => q({0} petabait),
					},
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pain),
						'other' => q({0} pain),
					},
					'pint-metric' => {
						'name' => q(pain metrik),
						'other' => q({0} pain metrik),
					},
					'point' => {
						'name' => q(mata),
						'other' => q({0} mata),
					},
					'pound' => {
						'name' => q(paun),
						'other' => q({0} paun),
						'per' => q({0} setiap paun),
					},
					'pound-per-square-inch' => {
						'name' => q(paun seinci persegi),
						'other' => q({0} paun seinci persegi),
					},
					'quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					'radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					'revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					'second' => {
						'name' => q(saat),
						'other' => q({0} saat),
						'per' => q({0} sesaat),
					},
					'square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} setiap sentimeter persegi),
					},
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					'square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} setiap inci persegi),
					},
					'square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} setiap meter persegi),
					},
					'square-mile' => {
						'name' => q(batu persegi),
						'other' => q({0} batu persegi),
						'per' => q({0} setiap batu persegi),
					},
					'square-yard' => {
						'name' => q(ela persegi),
						'other' => q({0} ela persegi),
					},
					'stone' => {
						'name' => q(stone),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(sudu besar),
						'other' => q({0} sudu besar),
					},
					'teaspoon' => {
						'name' => q(sudu teh),
						'other' => q({0} sudu teh),
					},
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabait),
						'other' => q({0} terabait),
					},
					'ton' => {
						'name' => q(tan),
						'other' => q({0} tan),
					},
					'volt' => {
						'name' => q(volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(minggu),
						'other' => q({0} minggu),
						'per' => q({0} setiap minggu),
					},
					'yard' => {
						'name' => q(ela),
						'other' => q({0} ela),
					},
					'year' => {
						'name' => q(tahun),
						'other' => q({0} tahun),
						'per' => q({0} setiap tahun),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(arah),
					},
					'acre' => {
						'other' => q({0} ekar),
					},
					'arc-minute' => {
						'other' => q({0}′),
					},
					'arc-second' => {
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0} au),
					},
					'carat' => {
						'name' => q(karat),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-kilometer' => {
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'other' => q({0} bt³),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fathom),
						'other' => q({0} fth),
					},
					'foot' => {
						'name' => q(ka),
						'other' => q({0}'),
						'per' => q({0}/ka),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(daya g),
						'other' => q({0} g),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					'inch' => {
						'name' => q(in),
						'other' => q({0}"),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/j),
						'other' => q({0} kmj),
					},
					'kilowatt' => {
						'other' => q({0} kW),
					},
					'knot' => {
						'name' => q(kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} t. chya),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(meter),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsaat),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(bt),
						'other' => q({0} bt),
					},
					'mile-per-hour' => {
						'name' => q(batu/jam),
						'other' => q({0} bsj),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0} smi),
					},
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mb),
					},
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(milisaat),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(minit),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(btn),
						'other' => q({0} btn),
					},
					'ounce' => {
						'name' => q(auns),
						'other' => q({0} auns),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'point' => {
						'name' => q(mt),
						'other' => q({0} mt),
					},
					'pound' => {
						'name' => q(lb),
						'other' => q({0} paun),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(saat),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-foot' => {
						'other' => q({0} ka²),
					},
					'square-kilometer' => {
						'other' => q({0} km²),
					},
					'square-meter' => {
						'other' => q({0} m²),
					},
					'square-mile' => {
						'other' => q({0} bt²),
					},
					'stone' => {
						'name' => q(stone),
						'other' => q({0} st),
					},
					'ton' => {
						'name' => q(tan),
						'other' => q({0} tn),
					},
					'watt' => {
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(minggu),
						'other' => q({0} mgu),
						'per' => q({0}/mgu),
					},
					'yard' => {
						'name' => q(ela),
						'other' => q({0} ela),
					},
					'year' => {
						'name' => q(thn),
						'other' => q({0} thn),
						'per' => q({0}/thn),
					},
				},
				'short' => {
					'' => {
						'name' => q(arah),
					},
					'acre' => {
						'name' => q(ekar),
						'other' => q({0} ekar),
					},
					'acre-foot' => {
						'name' => q(ekar ka),
						'other' => q({0} ekar ka),
					},
					'ampere' => {
						'name' => q(amp),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(min arka),
						'other' => q({0} min arka),
					},
					'arc-second' => {
						'name' => q(saat arka),
						'other' => q({0} saat arka),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0} au),
					},
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bait),
						'other' => q({0} bait),
					},
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					'carat' => {
						'name' => q(karat),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(darjah C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ka³),
						'other' => q({0} ka³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(bt³),
						'other' => q({0} bt³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cawan),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(cawan metrik),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0} hari),
						'per' => q({0}/h),
					},
					'deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(darjah),
						'other' => q({0} darjah),
					},
					'fahrenheit' => {
						'name' => q(darjah F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fathom),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} ka),
						'per' => q({0}/ka),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(daya g),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GBait),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(joule),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kBait),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} kmj),
					},
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} thn cahaya),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MBait),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(meter/saat),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(meter/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmeter),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsaat),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(batu),
						'other' => q({0} bt),
					},
					'mile-per-gallon' => {
						'name' => q(batu/gal),
						'other' => q({0} bpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(batu/jam),
						'other' => q({0} bsj),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliamp),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(milisaat),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(minit),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosaat),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(btn),
						'other' => q({0} btn),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(auns),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz troy),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(peratus),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(per seribu),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pain),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(mata),
						'other' => q({0} mt),
					},
					'pound' => {
						'name' => q(paun),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radian),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(saat),
						'other' => q({0} saat),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ka persegi),
						'other' => q({0} ka²),
					},
					'square-inch' => {
						'name' => q(inci²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(batu persegi),
						'other' => q({0} bt²),
						'per' => q({0}/bt²),
					},
					'square-yard' => {
						'name' => q(ela²),
						'other' => q({0} ela²),
					},
					'stone' => {
						'name' => q(stone),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(sudu besar),
						'other' => q({0} sudu besar),
					},
					'teaspoon' => {
						'name' => q(sudu teh),
						'other' => q({0} sudu teh),
					},
					'terabit' => {
						'name' => q(Tbit),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TBait),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tan),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(minggu),
						'other' => q({0} mgu),
						'per' => q({0}/mgu),
					},
					'yard' => {
						'name' => q(ela),
						'other' => q({0} ela),
					},
					'year' => {
						'name' => q(tahun),
						'other' => q({0} thn),
						'per' => q({0}/thn),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} dan {1}),
				2 => q({0} dan {1}),
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
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
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
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
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
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
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
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
				'currency' => q(Dirham Emiriah Arab Bersatu),
				'other' => q(Dirham UAE),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghani Afghanistan),
				'other' => q(Afghani Afghanistan),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek Albania),
				'other' => q(Lek Albania),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram Armenia),
				'other' => q(Dram Armenia),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Guilder Antillen Belanda),
				'other' => q(Guilder Antillen Belanda),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza Angola),
				'other' => q(Kwanza Angola),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso Argentina),
				'other' => q(Peso Argentina),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dolar Australia),
				'other' => q(Dolar Australia),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florin Aruba),
				'other' => q(Florin Aruba),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'other' => q(Manat Azerbaijan),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Mark Boleh Tukar Bosnia-Herzegovina),
				'other' => q(Mark Boleh Tukar Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dolar Barbados),
				'other' => q(Dolar Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka Bangladesh),
				'other' => q(Taka Bangladesh),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev Bulgaria),
				'other' => q(Lev Bulgaria),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar Bahrain),
				'other' => q(Dinar Bahrain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franc Burundi),
				'other' => q(Franc Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dolar Bermuda),
				'other' => q(Dolar Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dolar Brunei),
				'other' => q(Dolar Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano Bolivia),
				'other' => q(Boliviano Bolivia),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real Brazil),
				'other' => q(Real Brazil),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dolar Bahamas),
				'other' => q(Dolar Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'other' => q(Ngultrum Bhutan),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula Botswana),
				'other' => q(Pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rubel Belarus baharu),
				'other' => q(rubel lama Belarus),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rubel Belarus \(2000–2016\)),
				'other' => q(Rubel Belarus),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dolar Belize),
				'other' => q(Dolar Belize),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Dolar Kanada),
				'other' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franc Congo),
				'other' => q(Franc Congo),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franc Switzerland),
				'other' => q(Franc Switzerland),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso Chile),
				'other' => q(Peso Chile),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuan China \(luar pesisir\)),
				'other' => q(Yuan China \(luar pesisir\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan Cina),
				'other' => q(Yuan Cina),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso Colombia),
				'other' => q(Peso Colombia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colon Costa Rica),
				'other' => q(Colon Costa Rica),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso Boleh Tukar Cuba),
				'other' => q(Peso Boleh Tukar Cuba),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso Cuba),
				'other' => q(Peso Cuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
				'other' => q(Escudo Tanjung Verde),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Koruna Republik Czech),
				'other' => q(Koruna Republik Czech),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franc Djibouti),
				'other' => q(Franc Djibouti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Krone Denmark),
				'other' => q(Krone Denmark),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso Dominican),
				'other' => q(Peso Dominican),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar Algeria),
				'other' => q(Dinar Algeria),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Paun Mesir),
				'other' => q(Paun Mesir),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(ERN),
				'other' => q(Nakfa Eritrea),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr Ethiopia),
				'other' => q(Birr Ethiopia),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dolar Fiji),
				'other' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Paun Kepulauan Falkland),
				'other' => q(Paun Kepulauan Falkland),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Paun British),
				'other' => q(Paun British),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari Georgia),
				'other' => q(Lari Georgia),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi Ghana),
				'other' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Paun Gibraltar),
				'other' => q(Paun Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi Gambia),
				'other' => q(Dalasi Gambia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Franc Guinea),
				'other' => q(Franc Guinea),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'other' => q(Quetzal Guatemala),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dolar Guyana),
				'other' => q(Dolar Guyana),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dolar Hong Kong),
				'other' => q(Dolar Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira Honduras),
				'other' => q(Lempira Honduras),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna Croatia),
				'other' => q(Kuna Croatia),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde Haiti),
				'other' => q(Gourde Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forint Hungary),
				'other' => q(Forint Hungary),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupiah Indonesia),
				'other' => q(Rupiah Indonesia),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Syekel Baharu Israel),
				'other' => q(Syekel baharu Israel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupee India),
				'other' => q(Rupee India),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar Iraq),
				'other' => q(Dinar Iraq),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial Iran),
				'other' => q(Rial Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Krona Iceland),
				'other' => q(Krona Iceland),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dolar Jamaica),
				'other' => q(Dolar Jamaica),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar Jordan),
				'other' => q(Dinar Jordan),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen Jepun),
				'other' => q(Yen Jepun),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Syiling Kenya),
				'other' => q(Syiling Kenya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som Kyrgystani),
				'other' => q(Som Kyrgystani),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel Kemboja),
				'other' => q(Riel Kemboja),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franc Comoria),
				'other' => q(Franc Comoria),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won Korea Utara),
				'other' => q(Won Korea Utara),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won Korea Selatan),
				'other' => q(Won Korea Selatan),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar Kuwait),
				'other' => q(Dinar Kuwait),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dolar Kepulauan Cayman),
				'other' => q(Dolar Kepulauan Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge Kazakhstan),
				'other' => q(Tenge Kazakhstan),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip Laos),
				'other' => q(Kip Laos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Paun Lubnan),
				'other' => q(Paun Lubnan),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupee Sri Lanka),
				'other' => q(Rupee Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dolar Liberia),
				'other' => q(Dolar Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Lesotho),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas Lithuania),
				'other' => q(Litas Lithuania),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats Latvia),
				'other' => q(Lats Latvia),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar Libya),
				'other' => q(Dinar Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirham Maghribi),
				'other' => q(Dirham Maghribi),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu Moldova),
				'other' => q(Leu Moldova),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariary Malagasy),
				'other' => q(Ariary Malagasy),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar Macedonia),
				'other' => q(Denar Macedonia),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat Myanma),
				'other' => q(Kyat Myanma),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik Mongolia),
				'other' => q(Tugrik Mongolia),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca Macau),
				'other' => q(Pataca Macau),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973–2017\)),
				'other' => q(Ouguiya Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(Ouguiya Mauritania),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupee Mauritius),
				'other' => q(Rupee Mauritius),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa Maldives),
				'other' => q(Rufiyaa Maldives),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha Malawi),
				'other' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Peso Mexico),
				'other' => q(Peso Mexico),
			},
		},
		'MYR' => {
			symbol => 'RM',
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'other' => q(Ringgit Malaysia),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metikal Mozambique),
				'other' => q(Metikal Mozambique),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dolar Namibia),
				'other' => q(Dolar Namibia),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira Nigeria),
				'other' => q(Naira Nigeria),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Cordoba Nicaragua),
				'other' => q(Cordoba Nicaragua),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Krone Norway),
				'other' => q(Krone Norway),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupee Nepal),
				'other' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dolar New Zealand),
				'other' => q(Dolar New Zealand),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial Oman),
				'other' => q(Rial Oman),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(Balboa Panama),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol Peru),
				'other' => q(Sol Peru),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina Papua New Guinea),
				'other' => q(Kina Papua New Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Filipina),
				'other' => q(Peso Filipina),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupee Pakistan),
				'other' => q(Rupee Pakistan),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty Poland),
				'other' => q(Zloty Poland),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani Paraguay),
				'other' => q(Guarani Paraguay),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial Qatar),
				'other' => q(Rial Qatar),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu Romania),
				'other' => q(Leu Romania),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar Serbia),
				'other' => q(Dinar Serbia),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rubel Rusia),
				'other' => q(Rubel Rusia),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franc Rwanda),
				'other' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal Saudi),
				'other' => q(Riyal Saudi),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dolar Kepulauan Solomon),
				'other' => q(Dolar Kepulauan Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupee Seychelles),
				'other' => q(Rupee Seychelles),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Paun Sudan),
				'other' => q(Paun Sudan),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Krona Sweden),
				'other' => q(Krona Sweden),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dolar Singapura),
				'other' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Paun Saint Helena),
				'other' => q(Paun Saint Helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone Sierra Leone),
				'other' => q(Leone Sierra Leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Syiling Somali),
				'other' => q(Syiling Somali),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dolar Surinam),
				'other' => q(Dolar Surinam),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Paun Sudan selatan),
				'other' => q(Paun Sudan selatan),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra Sao Tome dan Principe \(1977–2017\)),
				'other' => q(Dobra Sao Tome dan Principe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra Sao Tome dan Principe),
				'other' => q(Dobra Sao Tome dan Principe),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Paun Syria),
				'other' => q(Paun Syria),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni Swazi),
				'other' => q(Lilangeni Swazi),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Baht Thai),
				'other' => q(Baht Thai),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'other' => q(Somoni Tajikistan),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat Turkmenistan),
				'other' => q(Manat Turkmenistan),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar Tunisia),
				'other' => q(Dinar Tunisia),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Pa’anga Tonga),
				'other' => q(Pa’anga Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira Turki),
				'other' => q(Lira Turki),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dolar Trinidad dan Tobago),
				'other' => q(Dolar Trinidad dan Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dolar Taiwan Baru),
				'other' => q(Dolar Taiwan Baru),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Syiling Tanzania),
				'other' => q(Syiling Tanzania),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hryvnia Ukraine),
				'other' => q(Hryvnia Ukraine),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Syiling Uganda),
				'other' => q(Syiling Uganda),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(Dolar AS),
				'other' => q(Dolar AS),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso Uruguay),
				'other' => q(Peso Uruguay),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som Uzbekistan),
				'other' => q(Som Uzbekistan),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolivar Venezuela \(2008–2018\)),
				'other' => q(Bolivar Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolivar Venezuela),
				'other' => q(Bolivar Venezuela),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong Vietnam),
				'other' => q(Dong Vietnam),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(Vatu Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala Samoa),
				'other' => q(Tala Samoa),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Franc CFA BEAC),
				'other' => q(Franc CFA BEAC),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dolar Caribbean Timur),
				'other' => q(Dolar Caribbean Timur),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franc CFA BCEAO),
				'other' => q(Franc CFA BCEAO),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Franc CFP),
				'other' => q(Franc CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mata Wang Tidak Diketahui),
				'other' => q(\(mata wang tidak diketahui\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial Yaman),
				'other' => q(Rial Yaman),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand Afrika Selatan),
				'other' => q(Rand Afrika Selatan),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Kwacha Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha Zambia),
				'other' => q(Kwacha Zambia),
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
			},
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
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
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
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
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
					narrow => {
						mon => 'I',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
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
					abbreviated => {
						mon => 'Isn',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kha',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					narrow => {
						mon => 'I',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Suku pertama',
						1 => 'Suku Ke-2',
						2 => 'Suku Ke-3',
						3 => 'Suku Ke-4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'coptic') {
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
			if ($_ eq 'ethiopic') {
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
			if ($_ eq 'ethiopic-amete-alem') {
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
			if ($_ eq 'indian') {
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
			if ($_ eq 'persian') {
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
				'narrow' => {
					'afternoon1' => q{tengah hari},
					'am' => q{a},
					'evening1' => q{petang},
					'morning1' => q{pagi},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{tengah hari},
					'am' => q{PG},
					'evening1' => q{petang},
					'morning1' => q{tengah malam},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{PTG},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{tengah hari},
					'am' => q{PG},
					'evening1' => q{petang},
					'morning1' => q{tengah malam},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{PTG},
				},
				'narrow' => {
					'afternoon1' => q{tengah hari},
					'am' => q{a},
					'evening1' => q{petang},
					'morning1' => q{pagi},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{tengah hari},
					'am' => q{PG},
					'evening1' => q{petang},
					'morning1' => q{tengah malam},
					'morning2' => q{pagi},
					'night1' => q{malam},
					'pm' => q{PTG},
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
				'0' => 'BE'
			},
			narrow => {
				'0' => 'BE'
			},
			wide => {
				'0' => 'BE'
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
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => 'ERA0'
			},
			narrow => {
				'0' => 'ERA0'
			},
			wide => {
				'0' => 'ERA0'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'S.M.',
				'1' => 'TM'
			},
			narrow => {
				'0' => 'S.M.',
				'1' => 'TM'
			},
			wide => {
				'0' => 'S.M.',
				'1' => 'TM'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'AM'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'AH'
			},
		},
		'japanese' => {
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Before R.O.C.',
				'1' => 'R.O.C.'
			},
			narrow => {
				'0' => 'Sblm R.O.C',
				'1' => 'R.O.C.'
			},
			wide => {
				'0' => 'Sebelum R.O.C',
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
			'full' => q{EEEE, d MMMM r(U)},
			'long' => q{d MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{d/M/r},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
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
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y GGGGG},
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
		'ethiopic-amete-alem' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'ethiopic-amete-alem' => {
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
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d-M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d-M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'week' w 'of' Y},
		},
		'hebrew' => {
			E => q{ccc},
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
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
				M => q{d MMM – d MMM, y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
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
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'hebrew' => {
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
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
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
				M => q{d MMM – d MMM, y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
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
		regionFormat => q(Waktu {0}),
		regionFormat => q(Waktu Siang {0}),
		regionFormat => q(Waktu Piawai {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Waktu Afghanistan#,
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
			exemplarCity => q#Kaherah#,
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
			exemplarCity => q#Djibouti#,
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
			exemplarCity => q#Sao Tome#,
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
		'Amazon' => {
			long => {
				'daylight' => q#Waktu Musim Panas Amazon#,
				'generic' => q#Waktu Amazon#,
				'standard' => q#Waktu Piawai Amazon#,
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
			exemplarCity => q#Asuncion#,
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
			exemplarCity => q#Teluk Cambridge#,
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
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
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
			exemplarCity => q#Teluk Glace#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Teluk Goose#,
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
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Sungai Rainy#,
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
			exemplarCity => q#Saint Barthelemy#,
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
				'daylight' => q#Waktu Hari Siang Pergunungan#,
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
				'daylight' => q#Waktu Siang Apia#,
				'generic' => q#Waktu Apia#,
				'standard' => q#Waktu Piawai Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waktu Siang Arab#,
				'generic' => q#Waktu Arab#,
				'standard' => q#Waktu Piawai Arab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
			exemplarCity => q#Bahrain#,
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
			exemplarCity => q#Damsyik#,
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
			exemplarCity => q#Gaza#,
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
			exemplarCity => q#Baitulmuqaddis#,
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
			exemplarCity => q#Kuwait#,
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
			exemplarCity => q#Yangon#,
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
			exemplarCity => q#Singapura#,
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
				'daylight' => q#Waktu Siang Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Piawai Atlantik#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cape Verde#,
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
			exemplarCity => q#South Georgia#,
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
		'Choibalsan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Choibalsan#,
				'generic' => q#Waktu Choibalsan#,
				'standard' => q#Waktu Piawai Choibalsan#,
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
			exemplarCity => q#Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
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
			exemplarCity => q#Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Waktu Piawai Ireland#,
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
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Waktu Musim Panas British#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembourg#,
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
			exemplarCity => q#Moscow#,
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
			exemplarCity => q#Prague#,
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
			exemplarCity => q#Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
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
			exemplarCity => q#Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
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
		'Macquarie' => {
			long => {
				'standard' => q#Waktu Pulau Macquarie#,
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
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Waktu Siang Barat Laut Mexico#,
				'generic' => q#Waktu Barat Laut Mexico#,
				'standard' => q#Waktu Piawai Barat Laut Mexico#,
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
				'standard' => q#Waktu Kepulauan Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Waktu Musim Panas Fernando de Noronha#,
				'generic' => q#Waktu Fernando de Noronha#,
				'standard' => q#Waktu Piawai Fernando de Noronha#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
