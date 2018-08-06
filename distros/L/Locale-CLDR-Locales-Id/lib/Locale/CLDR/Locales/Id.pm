=head1

Locale::CLDR::Locales::Id - Package for language Indonesian

=cut

package Locale::CLDR::Locales::Id;
# This file auto generated from Data\common\main\id.xml
#	on Sun  5 Aug  6:05:29 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
		use bignum;
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
					rule => q(delapan),
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
					rule => q(←← miliar[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← triliun[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← kuadriliun[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
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
					rule => q(ke=%spellout-cardinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
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
 				'ab' => 'Abkhaz',
 				'ace' => 'Aceh',
 				'ach' => 'Acoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adygei',
 				'ae' => 'Avesta',
 				'aeb' => 'Arab Tunisia',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadia',
 				'akz' => 'Alabama',
 				'ale' => 'Aleut',
 				'alt' => 'Altai Selatan',
 				'am' => 'Amharik',
 				'an' => 'Aragon',
 				'ang' => 'Inggris Kuno',
 				'anp' => 'Angika',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Standar Modern',
 				'arc' => 'Aram',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'arq' => 'Arab Aljazair',
 				'ars' => 'Arab Najdi',
 				'arw' => 'Arawak',
 				'ary' => 'Arab Maroko',
 				'arz' => 'Arab Mesir',
 				'as' => 'Assam',
 				'asa' => 'Asu',
 				'ase' => 'Bahasa Isyarat Amerika',
 				'ast' => 'Asturia',
 				'av' => 'Avar',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijani',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluchi',
 				'ban' => 'Bali',
 				'bar' => 'Bavaria',
 				'bas' => 'Basa',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Belarusia',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bg' => 'Bulgaria',
 				'bgn' => 'Balochi Barat',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjar',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibet',
 				'br' => 'Breton',
 				'bra' => 'Braj',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnia',
 				'bss' => 'Akoose',
 				'bua' => 'Buriat',
 				'bug' => 'Bugis',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Katalan',
 				'cad' => 'Kado',
 				'car' => 'Karib',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Kiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Chuuke',
 				'chm' => 'Mari',
 				'chn' => 'Jargon Chinook',
 				'cho' => 'Koktaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Kurdi Sorani',
 				'co' => 'Korsika',
 				'cop' => 'Koptik',
 				'cr' => 'Kree',
 				'crh' => 'Tatar Krimea',
 				'crs' => 'Seselwa Kreol Prancis',
 				'cs' => 'Cheska',
 				'csb' => 'Kashubia',
 				'cu' => 'Bahasa Gereja Slavonia',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Dansk',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Jerman',
 				'de_CH' => 'Jerman Tinggi (Swiss)',
 				'del' => 'Delaware',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbia Hilir',
 				'dua' => 'Duala',
 				'dum' => 'Belanda Abad Pertengahan',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Mesir Kuno',
 				'eka' => 'Ekajuk',
 				'el' => 'Yunani',
 				'elx' => 'Elam',
 				'en' => 'Inggris',
 				'en_GB' => 'Inggris (Inggris)',
 				'en_GB@alt=short' => 'Inggris (U.K.)',
 				'en_US@alt=short' => 'Inggris (A.S.)',
 				'enm' => 'Inggris Abad Pertengahan',
 				'eo' => 'Esperanto',
 				'es' => 'Spanyol',
 				'es_ES' => 'Spanyol (Eropa)',
 				'et' => 'Esti',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persia',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fula',
 				'fi' => 'Suomi',
 				'fil' => 'Filipino',
 				'fj' => 'Fiji',
 				'fo' => 'Faroe',
 				'fon' => 'Fon',
 				'fr' => 'Prancis',
 				'frc' => 'Prancis Cajun',
 				'frm' => 'Prancis Abad Pertengahan',
 				'fro' => 'Prancis Kuno',
 				'frp' => 'Arpitan',
 				'frr' => 'Frisia Utara',
 				'frs' => 'Frisia Timur',
 				'fur' => 'Friuli',
 				'fy' => 'Frisia Barat',
 				'ga' => 'Irlandia',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gd' => 'Gaelik Skotlandia',
 				'gez' => 'Geez',
 				'gil' => 'Gilbert',
 				'gl' => 'Galisia',
 				'glk' => 'Gilaki',
 				'gmh' => 'Jerman Abad Pertengahan',
 				'gn' => 'Guarani',
 				'goh' => 'Jerman Kuno',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gotik',
 				'grb' => 'Grebo',
 				'grc' => 'Yunani Kuno',
 				'gsw' => 'Jerman (Swiss)',
 				'gu' => 'Gujarat',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwich’in',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaii',
 				'he' => 'Ibrani',
 				'hi' => 'Hindi',
 				'hif' => 'Hindi Fiji',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hitit',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Kroasia',
 				'hsb' => 'Sorbia Hulu',
 				'ht' => 'Kreol Haiti',
 				'hu' => 'Hungaria',
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
 				'ik' => 'Inupiak',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingushetia',
 				'io' => 'Ido',
 				'is' => 'Islandia',
 				'it' => 'Italia',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jepang',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Ibrani-Persia',
 				'jrb' => 'Ibrani-Arab',
 				'jv' => 'Jawa',
 				'ka' => 'Georgia',
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardi',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kha' => 'Khasi',
 				'kho' => 'Khotan',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazakh',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korea',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani',
 				'kos' => 'Kosre',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachai Balkar',
 				'kri' => 'Krio',
 				'krl' => 'Karelia',
 				'kru' => 'Kuruk',
 				'ks' => 'Kashmir',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Dialek Kolsch',
 				'ku' => 'Kurdi',
 				'kum' => 'Kumyk',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Kornish',
 				'ky' => 'Kirgiz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luksemburg',
 				'lez' => 'Lezghia',
 				'lg' => 'Ganda',
 				'li' => 'Limburgia',
 				'lij' => 'Liguria',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lol' => 'Mongo',
 				'lou' => 'Kreol Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Utara',
 				'lt' => 'Lituavi',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvi',
 				'lzz' => 'Laz',
 				'mad' => 'Madura',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisien',
 				'mg' => 'Malagasi',
 				'mga' => 'Irlandia Abad Pertengahan',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshall',
 				'mi' => 'Maori',
 				'mic' => 'Mikmak',
 				'min' => 'Minangkabau',
 				'mk' => 'Makedonia',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolia',
 				'mnc' => 'Manchuria',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Melayu',
 				'mt' => 'Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Beberapa Bahasa',
 				'mus' => 'Bahasa Muskogee',
 				'mwl' => 'Miranda',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Burma',
 				'mye' => 'Myene',
 				'myv' => 'Eryza',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Bokmål Norwegia',
 				'nd' => 'Ndebele Utara',
 				'nds' => 'Jerman Rendah',
 				'ne' => 'Nepali',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuea',
 				'nl' => 'Belanda',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nynorsk Norwegia',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegia',
 				'nog' => 'Nogai',
 				'non' => 'Norse Kuno',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele Selatan',
 				'nso' => 'Sotho Utara',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Newari Klasik',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Ositania',
 				'oj' => 'Ojibwa',
 				'om' => 'Oromo',
 				'or' => 'Oriya',
 				'os' => 'Ossetia',
 				'osa' => 'Osage',
 				'ota' => 'Turki Osmani',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasina',
 				'pal' => 'Pahlevi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palau',
 				'pcm' => 'Pidgin Nigeria',
 				'pdc' => 'Jerman Pennsylvania',
 				'peo' => 'Persia Kuno',
 				'phn' => 'Funisia',
 				'pi' => 'Pali',
 				'pl' => 'Polski',
 				'pon' => 'Pohnpeia',
 				'prg' => 'Prusia',
 				'pro' => 'Provencal Lama',
 				'ps' => 'Pashto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portugis',
 				'pt_PT' => 'Portugis (Eropa)',
 				'qu' => 'Quechua',
 				'quc' => 'Kʼicheʼ',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotonga',
 				'rm' => 'Reto-Roman',
 				'rn' => 'Rundi',
 				'ro' => 'Rumania',
 				'ro_MD' => 'Moldavia',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'root' => 'Root',
 				'rtm' => 'Rotuma',
 				'ru' => 'Rusia',
 				'rup' => 'Aromania',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskerta',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'sam' => 'Aram Samaria',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'sba' => 'Ngambai',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinia',
 				'scn' => 'Sisilia',
 				'sco' => 'Skotlandia',
 				'sd' => 'Sindhi',
 				'sdh' => 'Kurdi Selatan',
 				'se' => 'Sami Utara',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkup',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Irlandia Kuno',
 				'sh' => 'Serbo-Kroasia',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'shu' => 'Arab Suwa',
 				'si' => 'Sinhala',
 				'sid' => 'Sidamo',
 				'sk' => 'Slovak',
 				'sl' => 'Sloven',
 				'sli' => 'Silesia Rendah',
 				'sly' => 'Selayar',
 				'sm' => 'Samoa',
 				'sma' => 'Sami Selatan',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalia',
 				'sog' => 'Sogdien',
 				'sq' => 'Albania',
 				'sr' => 'Serbia',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serer',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Sotho Selatan',
 				'su' => 'Sunda',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Sumeria',
 				'sv' => 'Swedia',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Swahili (Kongo)',
 				'swb' => 'Komoria',
 				'syc' => 'Suriah Klasik',
 				'syr' => 'Suriah',
 				'szl' => 'Silesia',
 				'ta' => 'Tamil',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetun',
 				'tg' => 'Tajik',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmen',
 				'tkl' => 'Tokelau',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshia',
 				'tt' => 'Tatar',
 				'ttt' => 'Tat Muslim',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahiti',
 				'tyv' => 'Tuvinia',
 				'tzm' => 'Tamazight Maroko Tengah',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'ug@alt=variant' => 'Uighur',
 				'uga' => 'Ugarit',
 				'uk' => 'Ukraina',
 				'umb' => 'Umbundu',
 				'und' => 'Bahasa Tidak Dikenal',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Venesia',
 				'vi' => 'Vietnam',
 				'vo' => 'Volapuk',
 				'vot' => 'Votia',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Walamo',
 				'war' => 'Warai',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'xal' => 'Kalmuk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapois',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yue' => 'Kanton',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotek',
 				'zbl' => 'Blissymbol',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamazight Maroko Standar',
 				'zh' => 'Tionghoa',
 				'zh_Hans' => 'Tionghoa (Aksara Sederhana)',
 				'zh_Hant' => 'Tionghoa (Aksara Tradisional)',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Tidak ada konten linguistik',
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
			'Afak' => 'Afaka',
 			'Aghb' => 'Albania Kaukasia',
 			'Arab' => 'Arab',
 			'Arab@alt=variant' => 'Arab Persia',
 			'Armi' => 'Aram Imperial',
 			'Armn' => 'Armenia',
 			'Avst' => 'Avesta',
 			'Bali' => 'Bali',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengali',
 			'Blis' => 'Blissymbol',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Bugis',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Simbol Aborigin Kanada Kesatuan',
 			'Cari' => 'Karia',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptik',
 			'Cprt' => 'Siprus',
 			'Cyrl' => 'Sirilik',
 			'Cyrs' => 'Gereja Slavonia Sirilik Lama',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Stenografi Duployan',
 			'Egyd' => 'Demotik Mesir',
 			'Egyh' => 'Hieratik Mesir',
 			'Egyp' => 'Hieroglip Mesir',
 			'Ethi' => 'Etiopia',
 			'Geok' => 'Georgian Khutsuri',
 			'Geor' => 'Georgia',
 			'Glag' => 'Glagolitic',
 			'Goth' => 'Gothic',
 			'Gran' => 'Grantha',
 			'Grek' => 'Yunani',
 			'Gujr' => 'Gujarat',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Hanb',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Sederhana',
 			'Hans@alt=stand-alone' => 'Han Sederhana',
 			'Hant' => 'Tradisional',
 			'Hant@alt=stand-alone' => 'Han Tradisional',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Hieroglif Anatolia',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana atau Hiragana',
 			'Hung' => 'Hungaria Kuno',
 			'Inds' => 'Indus',
 			'Ital' => 'Italia Lama',
 			'Jamo' => 'Jamo',
 			'Java' => 'Jawa',
 			'Jpan' => 'Jepang',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korea',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laos',
 			'Latf' => 'Latin Fraktur',
 			'Latg' => 'Latin Gaelik',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Lisu',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycia',
 			'Lydi' => 'Lydia',
 			'Mand' => 'Mandae',
 			'Mani' => 'Manikhei',
 			'Maya' => 'Hieroglip Maya',
 			'Mend' => 'Mende',
 			'Merc' => 'Kursif Meroitik',
 			'Mero' => 'Meroitik',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Mongolia',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Myanmar',
 			'Narb' => 'Arab Utara Kuno',
 			'Nbat' => 'Nabataea',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nushu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Chiki Lama',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmira',
 			'Perm' => 'Permik Kuno',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Pahlevi',
 			'Phlp' => 'Mazmur Pahlevi',
 			'Phlv' => 'Kitab Pahlevi',
 			'Phnx' => 'Phoenix',
 			'Plrd' => 'Fonetik Pollard',
 			'Prti' => 'Prasasti Parthia',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runik',
 			'Samr' => 'Samaria',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Arab Selatan Kuno',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Tulisan Isyarat',
 			'Shaw' => 'Shavia',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Sinhala',
 			'Sora' => 'Sora Sompeng',
 			'Sund' => 'Sunda',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Suriah',
 			'Syre' => 'Suriah Estrangelo',
 			'Syrj' => 'Suriah Barat',
 			'Syrn' => 'Suriah Timur',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue Baru',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tenghwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibet',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritik',
 			'Vaii' => 'Vai',
 			'Visp' => 'Ucapan Terlihat',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Persia Kuno',
 			'Xsux' => 'Cuneiform Sumero-Akkadia',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Warisan',
 			'Zmth' => 'Notasi Matematika',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Tidak Tertulis',
 			'Zyyy' => 'Umum',
 			'Zzzz' => 'Skrip Tak Dikenal',

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
 			'009' => 'Oseania',
 			'011' => 'Afrika Bagian Barat',
 			'013' => 'Amerika Tengah',
 			'014' => 'Afrika Bagian Timur',
 			'015' => 'Afrika Bagian Utara',
 			'017' => 'Afrika Bagian Tengah',
 			'018' => 'Afrika Bagian Selatan',
 			'019' => 'Amerika',
 			'021' => 'Amerika Bagian Utara',
 			'029' => 'Kepulauan Karibia',
 			'030' => 'Asia Bagian Timur',
 			'034' => 'Asia Bagian Selatan',
 			'035' => 'Asia Tenggara',
 			'039' => 'Eropa Bagian Selatan',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Wilayah Mikronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Tengah',
 			'145' => 'Asia Bagian Barat',
 			'150' => 'Eropa',
 			'151' => 'Eropa Bagian Timur',
 			'154' => 'Eropa Bagian Utara',
 			'155' => 'Eropa Bagian Barat',
 			'202' => 'Afrika Sub-Sahara',
 			'419' => 'Amerika Latin',
 			'AC' => 'Pulau Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Uni Emirat Arab',
 			'AF' => 'Afganistan',
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
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Belanda Karibia',
 			'BR' => 'Brasil',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Pulau Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kepulauan Cocos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Kongo (RDK)',
 			'CF' => 'Republik Afrika Tengah',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republik)',
 			'CH' => 'Swiss',
 			'CI' => 'Pantai Gading',
 			'CK' => 'Kepulauan Cook',
 			'CL' => 'Cile',
 			'CM' => 'Kamerun',
 			'CN' => 'Tiongkok',
 			'CO' => 'Kolombia',
 			'CP' => 'Pulau Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Tanjung Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Pulau Christmas',
 			'CY' => 'Siprus',
 			'CZ' => 'Ceko',
 			'CZ@alt=variant' => 'Republik Ceko',
 			'DE' => 'Jerman',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominika',
 			'DO' => 'Republik Dominika',
 			'DZ' => 'Aljazair',
 			'EA' => 'Ceuta dan Melilla',
 			'EC' => 'Ekuador',
 			'EE' => 'Estonia',
 			'EG' => 'Mesir',
 			'EH' => 'Sahara Barat',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanyol',
 			'ET' => 'Etiopia',
 			'EU' => 'Uni Eropa',
 			'EZ' => 'Zona Euro',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiji',
 			'FK' => 'Kepulauan Malvinas',
 			'FK@alt=variant' => 'Kepulauan Malvinas (Falkland)',
 			'FM' => 'Mikronesia',
 			'FO' => 'Kepulauan Faroe',
 			'FR' => 'Prancis',
 			'GA' => 'Gabon',
 			'GB' => 'Inggris Raya',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana Prancis',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grinlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea Ekuatorial',
 			'GR' => 'Yunani',
 			'GS' => 'Georgia Selatan & Kep. Sandwich Selatan',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR Tiongkok',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Pulau Heard dan Kepulauan McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Kepulauan Canary',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlandia',
 			'IL' => 'Israel',
 			'IM' => 'Pulau Man',
 			'IN' => 'India',
 			'IO' => 'Wilayah Inggris di Samudra Hindia',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordania',
 			'JP' => 'Jepang',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kamboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Saint Kitts dan Nevis',
 			'KP' => 'Korea Utara',
 			'KR' => 'Korea Selatan',
 			'KW' => 'Kuwait',
 			'KY' => 'Kepulauan Cayman',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libia',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Kepulauan Marshall',
 			'MK' => 'Makedonia',
 			'MK@alt=variant' => 'Makedonia (BRY)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Makau SAR Tiongkok',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Kepulauan Mariana Utara',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maladewa',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledonia Baru',
 			'NE' => 'Niger',
 			'NF' => 'Kepulauan Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Belanda',
 			'NO' => 'Norwegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Selandia Baru',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Prancis',
 			'PG' => 'Papua Nugini',
 			'PH' => 'Filipina',
 			'PK' => 'Pakistan',
 			'PL' => 'Polandia',
 			'PM' => 'Saint Pierre dan Miquelon',
 			'PN' => 'Kepulauan Pitcairn',
 			'PR' => 'Puerto Riko',
 			'PS' => 'Wilayah Palestina',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oseania Luar',
 			'RE' => 'Réunion',
 			'RO' => 'Rumania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arab Saudi',
 			'SB' => 'Kepulauan Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Swedia',
 			'SG' => 'Singapura',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Kepulauan Svalbard dan Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Selatan',
 			'ST' => 'Sao Tome dan Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Suriah',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Kepulauan Turks dan Caicos',
 			'TD' => 'Cad',
 			'TF' => 'Wilayah Kutub Selatan Prancis',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TM' => 'Turkimenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad dan Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Kepulauan Terluar A.S.',
 			'UN' => 'Perserikatan Bangsa-Bangsa',
 			'UN@alt=short' => 'PBB',
 			'US' => 'Amerika Serikat',
 			'US@alt=short' => 'A.S.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Saint Vincent dan Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Kepulauan Virgin Inggris',
 			'VI' => 'Kepulauan Virgin A.S.',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Kepulauan Wallis dan Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Selatan',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Wilayah Tidak Dikenal',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Ortografi Jerman Tradisional',
 			'1994' => 'Ortografi Resia Standar',
 			'1996' => 'Ortografi Jerman 1996',
 			'1606NICT' => 'Prancis Pertengahan Akhir sampai 1606',
 			'1694ACAD' => 'Prancis Modern Awal',
 			'1959ACAD' => 'Akademik',
 			'ALALC97' => 'ALA-LC Latin, edisi 1997',
 			'ALUKU' => 'Dialek Aluku',
 			'AREVELA' => 'Armenia Timur',
 			'AREVMDA' => 'Armenia Barat',
 			'BAKU1926' => 'Alfabet Latin Turki Terpadu',
 			'BAUDDHA' => 'BAUDDHA',
 			'BISCAYAN' => 'BISKAY',
 			'BISKE' => 'Dialek San Giorgio/Bila',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'Fonetik IPA',
 			'FONUPA' => 'Fonetik UPA',
 			'FONXSAMP' => 'FONXSAMP',
 			'HEPBURN' => 'Hepburn Latin',
 			'HOGNORSK' => 'NORWEDIA TINGGI',
 			'ITIHASA' => 'ITIHASA',
 			'JAUER' => 'JAUER',
 			'JYUTPING' => 'JYUTPING',
 			'KKCOR' => 'Ortografi Umum',
 			'LAUKIKA' => 'LAUKIKA',
 			'LIPAW' => 'Dialek Lipovaz Resia',
 			'LUNA1918' => 'LUNA1918',
 			'MONOTON' => 'Monoton',
 			'NDYUKA' => 'Dialek Ndyuka',
 			'NEDIS' => 'Dialek Natiso',
 			'NJIVA' => 'Dialek Gniva/Njiva',
 			'OSOJS' => 'Dialek Oseacco/Osojane',
 			'PAMAKA' => 'Dialek Pamaka',
 			'PETR1708' => 'PETR1708',
 			'PINYIN' => 'Pinyin Latin',
 			'POLYTON' => 'Politon',
 			'POSIX' => 'Komputer',
 			'PUTER' => 'PUTER',
 			'REVISED' => 'Ortografi Revisi',
 			'ROZAJ' => 'Resia',
 			'RUMGR' => 'RUMGR',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Inggris Standar Skotlandia',
 			'SCOUSE' => 'Skaus',
 			'SOLBA' => 'Dialek Stolvizza/Solbica',
 			'SURMIRAN' => 'SURMIRAN',
 			'SURSILV' => 'SURSILV',
 			'SUTSILV' => 'SUTSILV',
 			'TARASK' => 'Ortografi Taraskievica',
 			'UCCOR' => 'Ortografi Terpadu',
 			'UCRCOR' => 'Ortografi Revisi Terpadu',
 			'ULSTER' => 'ULSTER',
 			'VAIDIKA' => 'VAIDIKA',
 			'VALENCIA' => 'Valencia',
 			'VALLADER' => 'VALLADER',
 			'WADEGILE' => 'Wade-Giles Latin',

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
 			'cf' => 'Format Mata Uang',
 			'colalternate' => 'Penyortiran Abaikan Simbol',
 			'colbackwards' => 'Penyortiran Aksen Terbalik',
 			'colcasefirst' => 'Pengurutan Huruf Besar/Huruf Kecil',
 			'colcaselevel' => 'Penyortiran Peka Huruf Besar',
 			'collation' => 'Aturan Pengurutan',
 			'colnormalization' => 'Penyortiran Dinormalisasi',
 			'colnumeric' => 'Penyortiran Numerik',
 			'colstrength' => 'Kekuatan Penyortiran',
 			'currency' => 'Mata Uang',
 			'hc' => 'Siklus Jam (12 vs 24)',
 			'lb' => 'Gaya Pemisah Baris',
 			'ms' => 'Sistem Pengukuran',
 			'numbers' => 'Angka',
 			'timezone' => 'Zona Waktu',
 			'va' => 'Varian Lokal',
 			'x' => 'Penggunaan Pribadi',

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
 				'buddhist' => q{Kalender Buddha},
 				'chinese' => q{Kalender Tionghoa},
 				'coptic' => q{Kalender Koptik},
 				'dangi' => q{Kalender Dangi},
 				'ethiopic' => q{Kalender Etiopia},
 				'ethiopic-amete-alem' => q{Kalender Amete Alem Etiopia},
 				'gregorian' => q{Kalender Gregorian},
 				'hebrew' => q{Kalender Ibrani},
 				'indian' => q{Kalender Nasional India},
 				'islamic' => q{Kalender Islam},
 				'islamic-civil' => q{Kalender Sipil Islam},
 				'islamic-rgsa' => q{Kalender Islam (Arab Saudi, penglihatan)},
 				'islamic-umalqura' => q{Kalender Islam (Umm al-Qura)},
 				'iso8601' => q{Kalender ISO-8601},
 				'japanese' => q{Kalender Jepang},
 				'persian' => q{Kalender Persia},
 				'roc' => q{Kalendar Minguo},
 			},
 			'cf' => {
 				'account' => q{Format Mata Uang Akuntansi},
 				'standard' => q{Format Mata Uang Standar},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sortir Simbol},
 				'shifted' => q{Sortir Abaikan Simbol},
 			},
 			'colbackwards' => {
 				'no' => q{Sortir Aksen Secara Normal},
 				'yes' => q{Sortir Aksen Terbalik},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sortir Huruf Kecil Dahulu},
 				'no' => q{Sortir Urutan Ukuran Huruf Normal},
 				'upper' => q{Sortir Huruf Besar Dahulu},
 			},
 			'colcaselevel' => {
 				'no' => q{Sortir Tidak Peka Huruf Besar},
 				'yes' => q{Sortir Peka Huruf Besar},
 			},
 			'collation' => {
 				'big5han' => q{Urutan Sortir Tionghoa Tradisional - Big5},
 				'compat' => q{Aturan Pengurutan Sebelumnya, untuk kompatibilitas},
 				'dictionary' => q{Urutan Sortir Kamus},
 				'ducet' => q{Aturan Pengurutan Unicode Default},
 				'eor' => q{Aturan Pengurutan Eropa},
 				'gb2312han' => q{Urutan Sortir Tionghoa Aks. Sederhana - GB2312},
 				'phonebook' => q{Urutan Sortir Buku Telepon},
 				'phonetic' => q{Urutan Sortir Fonetik},
 				'pinyin' => q{Urutan Sortir Pinyin},
 				'reformed' => q{Urutan Sortir yang Diubah Bentuknya},
 				'search' => q{Pencarian Tujuan Umum},
 				'searchjl' => q{Pencarian Menurut Konsonan Awal Hangul},
 				'standard' => q{Aturan Pengurutan Standar},
 				'stroke' => q{Urutan Sortir Guratan},
 				'traditional' => q{Urutan Sortir Tradisional},
 				'unihan' => q{Urutan Sortir Guratan Radikal},
 			},
 			'colnormalization' => {
 				'no' => q{Sortir Tanpa Normalisasi},
 				'yes' => q{Sortir Unicode Dinormalisasi},
 			},
 			'colnumeric' => {
 				'no' => q{Sortir Digit Satu Per Satu},
 				'yes' => q{Sortir Digit Secara Numerik},
 			},
 			'colstrength' => {
 				'identical' => q{Sortir Semua},
 				'primary' => q{Sortir Huruf Dasar Saja},
 				'quaternary' => q{Sortir Aksen/Ukuran Huruf/Lebar/Kana},
 				'secondary' => q{Sortir Aksen},
 				'tertiary' => q{Sortir Aksen/Ukuran Huruf/Lebar},
 			},
 			'd0' => {
 				'fwidth' => q{Lebar penuh},
 				'hwidth' => q{Lebar separuh},
 				'npinyin' => q{Angka},
 			},
 			'hc' => {
 				'h11' => q{Sistem 12 Jam (0–11)},
 				'h12' => q{Sistem 12 Jam (1–12)},
 				'h23' => q{Sistem 24 Jam (0–23)},
 				'h24' => q{Sistem 24 Jam (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Gaya Pemisah Baris Renggang},
 				'normal' => q{Gaya Pemisah Baris Normal},
 				'strict' => q{Gaya Pemisah Baris Rapat},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistem Metrik},
 				'uksystem' => q{Sistem Pengukuran Imperial},
 				'ussystem' => q{Sistem Pengukuran A.S.},
 			},
 			'numbers' => {
 				'arab' => q{Angka Arab Timur},
 				'arabext' => q{Angka Arab Timur Diperluas},
 				'armn' => q{Angka Armenia},
 				'armnlow' => q{Angka Huruf Kecil Armenia},
 				'bali' => q{Angka Bali},
 				'beng' => q{Angka Bengali},
 				'cham' => q{Angka Cham},
 				'deva' => q{Angka Devanagari},
 				'ethi' => q{Angka Etiopia},
 				'finance' => q{Angka Finansial},
 				'fullwide' => q{Angka Lebar Penuh},
 				'geor' => q{Angka Georgia},
 				'grek' => q{Angka Yunani},
 				'greklow' => q{Angka Yunani Huruf Kecil},
 				'gujr' => q{Angka Gujarat},
 				'guru' => q{Angka Gurmukhi},
 				'hanidec' => q{Angka Desimal Tionghoa},
 				'hans' => q{Angka Tionghoa Sederhana},
 				'hansfin' => q{Angka Keuangan Tionghoa Sederhana},
 				'hant' => q{Angka Tionghoa Tradisional},
 				'hantfin' => q{Angka Keuangan Tionghoa Tradisional},
 				'hebr' => q{Angka Ibrani},
 				'java' => q{Angka Jawa},
 				'jpan' => q{Angka Jepang},
 				'jpanfin' => q{Angka Keuangan Jepang},
 				'kali' => q{Angka Kayah Li},
 				'khmr' => q{Angka Khmer},
 				'knda' => q{Angka Kannada},
 				'lana' => q{Angka Tai Tham Hora},
 				'lanatham' => q{Angka Tai Tham Tham},
 				'laoo' => q{Angka Laos},
 				'latn' => q{Angka Latin},
 				'lepc' => q{Angka Lepcha},
 				'limb' => q{Angka Limbu},
 				'mlym' => q{Angka Malayalam},
 				'mong' => q{Angka Mongolia},
 				'mtei' => q{Angka Meetei Mayek},
 				'mymr' => q{Angka Myanmar},
 				'mymrshan' => q{Angka Myanmar Shan},
 				'native' => q{Digit Asli},
 				'nkoo' => q{Angka N’Ko},
 				'olck' => q{Angka Ol Chiki},
 				'orya' => q{Angka Oriya},
 				'roman' => q{Angka Romawi},
 				'romanlow' => q{Angka Huruf Kecil Romawi},
 				'saur' => q{Angka Saurashtra},
 				'sund' => q{Angka Sunda},
 				'talu' => q{Angka Tai Lue Baru},
 				'taml' => q{Angka Tamil Tradisional},
 				'tamldec' => q{Angka Tamil},
 				'telu' => q{Angka Telugu},
 				'thai' => q{Angka Thai},
 				'tibt' => q{Angka Tibet},
 				'traditional' => q{Angka Tradisional},
 				'vaii' => q{Angka Vai},
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
 			'UK' => q{BR},
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
 			'region' => 'Wilayah: {0}',

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
			auxiliary => qr{[å]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ “ ” ( ) \[ \] /]},
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
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(acre),
						'other' => q({0} acre),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(menit busur),
						'other' => q({0} menit busur),
					},
					'arc-second' => {
						'name' => q(detik busur),
						'other' => q({0} detik busur),
					},
					'astronomical-unit' => {
						'name' => q(satuan astronomi),
						'other' => q({0} satuan astronomi),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
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
						'name' => q(derajat Celsius),
						'other' => q({0} derajat Celsius),
					},
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0}T),
						'north' => q({0}U),
						'south' => q({0}S),
						'west' => q({0}B),
					},
					'cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} per sentimeter kubik),
					},
					'cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					'cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					'cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					'cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} per meter kubik),
					},
					'cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					'cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					'cup' => {
						'name' => q(cup),
						'other' => q({0} cup),
					},
					'cup-metric' => {
						'name' => q(metric cup),
						'other' => q({0} metric cup),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0} hari),
						'per' => q({0} per hari),
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
						'name' => q(derajat),
						'other' => q({0} derajat),
					},
					'fahrenheit' => {
						'name' => q(derajat Fahrenheit),
						'other' => q({0} derajat Fahrenheit),
					},
					'fathom' => {
						'name' => q(depa),
						'other' => q({0} depa),
					},
					'fluid-ounce' => {
						'name' => q(fluid ounce),
						'other' => q({0} fluid ounce),
					},
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0} per kaki),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0} furlong),
					},
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} g-force),
					},
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} per galon),
					},
					'gallon-imperial' => {
						'name' => q(galon Imp.),
						'other' => q({0} galon Imp.),
						'per' => q({0} per galon Imp.),
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
						'name' => q(gigabyte),
						'other' => q({0} gigabyte),
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
						'per' => q({0} per gram),
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
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					'hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(daya kuda),
						'other' => q({0} daya kuda),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0} per jam),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} per inci),
					},
					'inch-hg' => {
						'name' => q(inci merkuri),
						'other' => q({0} inci merkuri),
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
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
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
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per jam),
						'other' => q({0} kilometer per jam),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
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
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'other' => q({0} liter per kilometer),
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
						'name' => q(megabyte),
						'other' => q({0} megabyte),
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
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meter per detik),
						'other' => q({0} meter per detik),
					},
					'meter-per-second-squared' => {
						'name' => q(meter per detik persegi),
						'other' => q({0} meter per detik persegi),
					},
					'metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
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
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil per galon),
						'other' => q({0} mil per galon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil per galon Imp.),
						'other' => q({0} mil per galon Imp.),
					},
					'mile-per-hour' => {
						'name' => q(mil per jam),
						'other' => q({0} mil per jam),
					},
					'mile-scandinavian' => {
						'name' => q(mil skandinavia),
						'other' => q({0} mil skandinavia),
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
						'name' => q(milligram per desiliter),
						'other' => q({0} milligram per desiliter),
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
						'name' => q(milimeter merkuri),
						'other' => q({0} milimeter merkuri),
					},
					'millimole-per-liter' => {
						'name' => q(millimole per liter),
						'other' => q({0} millimole per liter),
					},
					'millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} per menit),
					},
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bulan),
						'per' => q({0} per bulan),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					'nautical-mile' => {
						'name' => q(mil laut),
						'other' => q({0} mil laut),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0} per ons),
					},
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					'parsec' => {
						'name' => q(parsec),
						'other' => q({0} parsec),
					},
					'part-per-million' => {
						'name' => q(bagian per juta),
						'other' => q({0} bagian per juta),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metric pint),
						'other' => q({0} metric pint),
					},
					'point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0} per pon),
					},
					'pound-per-square-inch' => {
						'name' => q(pon per inci persegi),
						'other' => q({0} pon per inci persegi),
					},
					'quart' => {
						'name' => q(quart),
						'other' => q({0} quart),
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
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} per detik),
					},
					'square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} per sentimeter persegi),
					},
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					'square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} per inci persegi),
					},
					'square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
						'per' => q({0} per kilometer persegi),
					},
					'square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} per meter persegi),
					},
					'square-mile' => {
						'name' => q(mil persegi),
						'other' => q({0} mil persegi),
						'per' => q({0} per mil persegi),
					},
					'square-yard' => {
						'name' => q(yard persegi),
						'other' => q({0} yard persegi),
					},
					'stone' => {
						'name' => q(st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(sendok makan),
						'other' => q({0} sendok makan),
					},
					'teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
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
						'per' => q({0} per minggu),
					},
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(tahun),
						'other' => q({0} tahun),
						'per' => q({0} per tahun),
					},
				},
				'narrow' => {
					'acre' => {
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'other' => q({0}′),
					},
					'arc-second' => {
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0}sa),
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
						'name' => q(cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0}T),
						'north' => q({0}U),
						'south' => q({0}S),
						'west' => q({0}B),
					},
					'cubic-kilometer' => {
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0}hr),
						'per' => q({0}/hr),
					},
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0}dm),
					},
					'degree' => {
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(depa),
						'other' => q({0}dp),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} ft),
						'per' => q({0}/kaki),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0}fur),
					},
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} g),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0}g),
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
						'other' => q({0}j),
						'per' => q({0}/j),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(″ Hg),
						'other' => q({0} inHg),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					'kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0}kph),
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
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0}L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0}L/100km),
					},
					'meter' => {
						'name' => q(meter),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/d),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/d²),
						'other' => q({0}m/d²),
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
						'other' => q({0}µm),
					},
					'microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'name' => q(mi/j),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0}smi),
					},
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'other' => q({0} mmHg),
					},
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0}md),
					},
					'minute' => {
						'name' => q(mnt),
						'other' => q({0}mnt),
						'per' => q({0}/mnt),
					},
					'month' => {
						'name' => q(bulan),
						'other' => q({0}bln),
						'per' => q({0}/bln),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} ndtk),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0}nmi),
					},
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsec),
						'other' => q({0}pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'point' => {
						'name' => q(p),
						'other' => q({0}p),
					},
					'pound' => {
						'name' => q(pon),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(dtk),
						'other' => q({0}dtk),
						'per' => q({0}/dtk),
					},
					'square-foot' => {
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'other' => q({0} km²),
					},
					'square-meter' => {
						'other' => q({0} m²),
					},
					'square-mile' => {
						'other' => q({0} mi²),
					},
					'stone' => {
						'name' => q(stone),
						'other' => q({0} st),
					},
					'ton' => {
						'name' => q(ton),
						'other' => q({0} tn),
					},
					'watt' => {
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(mgg),
						'other' => q({0}mgg),
						'per' => q({0}/mgg),
					},
					'yard' => {
						'name' => q(yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(thn),
						'other' => q({0}thn),
						'per' => q({0}/thn),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acre),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(mnt busur),
						'other' => q({0} mnt busur),
					},
					'arc-second' => {
						'name' => q(dtk busur),
						'other' => q({0} dtk busur),
					},
					'astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0} sa),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
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
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0}T),
						'north' => q({0}U),
						'south' => q({0}S),
						'west' => q({0}B),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(inci³),
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
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(hari),
						'other' => q({0} hr),
						'per' => q({0}/hr),
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
						'name' => q(derajat),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(dp),
						'other' => q({0} dp),
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
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlong),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal Imp.),
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
						'name' => q(GByte),
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
						'name' => q(in Hg),
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
						'name' => q(kByte),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kg),
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
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} kph),
					},
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} ly),
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
						'name' => q(MByte),
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
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					'meter-per-second-squared' => {
						'name' => q(meter/dtk²),
						'other' => q({0} m/dtk²),
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
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/gal Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0} mph),
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
						'name' => q(millimol/liter),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
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
						'name' => q(nanodtk),
						'other' => q({0} ndtk),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz troy),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsec),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(bagian/juta),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pint),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					'pound' => {
						'name' => q(pon),
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
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} ft²),
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
						'name' => q(meter²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mil persegi),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stone),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(sdm),
						'other' => q({0} sdm),
					},
					'teaspoon' => {
						'name' => q(sdt),
						'other' => q({0} sdt),
					},
					'terabit' => {
						'name' => q(Tbit),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TByte),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(ton),
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
						'other' => q({0} mgg),
						'per' => q({0}/mgg),
					},
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yd),
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
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(.),
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
					'other' => '0 rb',
				},
				'10000' => {
					'other' => '00 rb',
				},
				'100000' => {
					'other' => '000 rb',
				},
				'1000000' => {
					'other' => '0 jt',
				},
				'10000000' => {
					'other' => '00 jt',
				},
				'100000000' => {
					'other' => '000 jt',
				},
				'1000000000' => {
					'other' => '0 M',
				},
				'10000000000' => {
					'other' => '00 M',
				},
				'100000000000' => {
					'other' => '000 M',
				},
				'1000000000000' => {
					'other' => '0 T',
				},
				'10000000000000' => {
					'other' => '00 T',
				},
				'100000000000000' => {
					'other' => '000 T',
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
					'other' => '0 miliar',
				},
				'10000000000' => {
					'other' => '00 miliar',
				},
				'100000000000' => {
					'other' => '000 miliar',
				},
				'1000000000000' => {
					'other' => '0 triliun',
				},
				'10000000000000' => {
					'other' => '00 triliun',
				},
				'100000000000000' => {
					'other' => '000 triliun',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 rb',
				},
				'10000' => {
					'other' => '00 rb',
				},
				'100000' => {
					'other' => '000 rb',
				},
				'1000000' => {
					'other' => '0 jt',
				},
				'10000000' => {
					'other' => '00 jt',
				},
				'100000000' => {
					'other' => '000 jt',
				},
				'1000000000' => {
					'other' => '0 M',
				},
				'10000000000' => {
					'other' => '00 M',
				},
				'100000000000' => {
					'other' => '000 M',
				},
				'1000000000000' => {
					'other' => '0 T',
				},
				'10000000000000' => {
					'other' => '00 T',
				},
				'100000000000000' => {
					'other' => '000 T',
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
		'ADP' => {
			symbol => 'ADP',
			display_name => {
				'currency' => q(Peseta Andorra),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham Uni Emirat Arab),
				'other' => q(Dirham Uni Emirat Arab),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afgani Afganistan \(1927–2002\)),
				'other' => q(Afgani Afganistan \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgani Afganistan),
				'other' => q(Afgani Afganistan),
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
				'currency' => q(Guilder Antilla Belanda),
				'other' => q(Guilder Antilla Belanda),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza Angola),
				'other' => q(Kwanza Angola),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(Kwanza Angola \(1977–1991\)),
				'other' => q(Kwanza Angola \(1977–1991\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(Kwanza Baru Angola \(1990–2000\)),
				'other' => q(Kwanza Baru Angola \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(Kwanza Angola yang Disesuaikan Lagi \(1995–1999\)),
				'other' => q(Kwanza Angola yang Disesuaikan Lagi \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(Austral Argentina),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(Peso Ley Argentina \(1970–1983\)),
				'other' => q(Peso Ley Argentina \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(Peso Argentina \(1881–1970\)),
				'other' => q(Peso Argentina \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(Peso Argentina \(1983–1985\)),
				'other' => q(Peso Argentina \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso Argentina),
				'other' => q(Peso Argentina),
			},
		},
		'ATS' => {
			symbol => 'ATS',
			display_name => {
				'currency' => q(Schilling Austria),
			},
		},
		'AUD' => {
			symbol => 'AU$',
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
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(Manat Azerbaijan \(1993–2006\)),
				'other' => q(Manat Azerbaijan \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'other' => q(Manat Azerbaijan),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(Dinar Bosnia-Herzegovina \(1992–1994\)),
				'other' => q(Dinar Bosnia-Herzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Mark Konvertibel Bosnia-Herzegovina),
				'other' => q(Mark Konvertibel Bosnia-Herzegovina),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(Dinar Baru Bosnia-Herzegovina \(1994–1997\)),
				'other' => q(Dinar Baru Bosnia-Herzegovina \(1994–1997\)),
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
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(Franc Belgia \(konvertibel\)),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(Franc Belgia),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(Franc Belgia \(keuangan\)),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(Hard Lev Bulgaria),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(Socialist Lev Bulgaria),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev Bulgaria),
				'other' => q(Lev Bulgaria),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(Lev Bulgaria \(1879–1952\)),
				'other' => q(Lev Bulgaria \(1879–1952\)),
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
				'currency' => q(Boliviano),
				'other' => q(Boliviano),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(Boliviano Bolivia \(1863–1963\)),
				'other' => q(Boliviano Bolivia \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(Peso Bolivia),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(Mvdol Bolivia),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(Cruzeiro Baru Brasil \(1967–1986\)),
				'other' => q(Cruzeiro Baru Brasil \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(Cruzado Brasil \(1986–1989\)),
				'other' => q(Cruzado Brasil \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1990–1993\)),
				'other' => q(Cruzeiro Brasil \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real Brasil),
				'other' => q(Real Brasil),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(Cruzado Baru Brasil \(1989–1990\)),
				'other' => q(Cruzado Baru Brasil \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1993–1994\)),
				'other' => q(Cruzeiro Brasil \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1942–1967\)),
				'other' => q(Cruzeiro Brasil \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dolar Bahama),
				'other' => q(Dolar Bahama),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'other' => q(Ngultrum Bhutan),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(Kyat Burma),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula Botswana),
				'other' => q(Pula Botswana),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(Rubel Baru Belarus \(1994–1999\)),
				'other' => q(Rubel Baru Belarus \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rubel Belarusia),
				'other' => q(Rubel Belarusia),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rubel Belarusia \(2000–2016\)),
				'other' => q(Rubel Belarusia \(2000–2016\)),
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
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dolar Kanada),
				'other' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franc Kongo),
				'other' => q(Franc Kongo),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(Euro WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franc Swiss),
				'other' => q(Franc Swiss),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(Franc WIR),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(Escudo Cile),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(Satuan Hitung \(UF\) Cile),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso Cile),
				'other' => q(Peso Cile),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuan Tiongkok \(luar negeri\)),
				'other' => q(Yuan Tiongkok \(luar negeri\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan Tiongkok),
				'other' => q(Yuan Tiongkok),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso Kolombia),
				'other' => q(Peso Kolombia),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(Unit Nilai Nyata Kolombia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colon Kosta Rika),
				'other' => q(Colon Kosta Rika),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(Dinar Serbia \(2002–2006\)),
				'other' => q(Dinar Serbia \(2002–2006\)),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(Hard Koruna Cheska),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso Konvertibel Kuba),
				'other' => q(Peso Konvertibel Kuba),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso Kuba),
				'other' => q(Peso Kuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
				'other' => q(Escudo Tanjung Verde),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(Pound Siprus),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Koruna Cheska),
				'other' => q(Koruna Cheska),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(Mark Jerman Timur),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(Mark Jerman),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franc Jibuti),
				'other' => q(Franc Jibuti),
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
				'currency' => q(Peso Dominika),
				'other' => q(Peso Dominika),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar Algeria),
				'other' => q(Dinar Algeria),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(Sucre Ekuador),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(Satuan Nilai Tetap Ekuador),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(Kroon Estonia),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Pound Mesir),
				'other' => q(Pound Mesir),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa Eritrea),
				'other' => q(Nakfa Eritrea),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(Peseta Spanyol \(akun\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(Peseta Spanyol \(konvertibel\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Peseta Spanyol),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr Etiopia),
				'other' => q(Birr Etiopia),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(Markka Finlandia),
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
				'currency' => q(Pound Kepulauan Falkland),
				'other' => q(Pound Kepulauan Falkland),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(Franc Prancis),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Pound Inggris),
				'other' => q(Pound Inggris),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(Kupon Larit Georgia),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari Georgia),
				'other' => q(Lari Georgia),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Cedi Ghana \(1979–2007\)),
				'other' => q(Cedi Ghana \(1979–2007\)),
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
				'currency' => q(Pound Gibraltar),
				'other' => q(Pound Gibraltar),
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
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(Syli Guinea),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(Ekuele Guinea Ekuatorial),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(Drachma Yunani),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'other' => q(Quetzal Guatemala),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(Escudo Guinea Portugal),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Peso Guinea-Bissau),
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
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(Dinar Kroasia),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna Kroasia),
				'other' => q(Kuna Kroasia),
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
				'currency' => q(Forint Hungaria),
				'other' => q(Forint Hungaria),
			},
		},
		'IDR' => {
			symbol => 'Rp',
			display_name => {
				'currency' => q(Rupiah Indonesia),
				'other' => q(Rupiah Indonesia),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(Pound Irlandia),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(Pound Israel),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Shekel Israel),
				'other' => q(Shekel Israel \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Shekel Baru Israel),
				'other' => q(Shekel Baru Israel),
			},
		},
		'INR' => {
			symbol => 'Rs',
			display_name => {
				'currency' => q(Rupee India),
				'other' => q(Rupee India),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar Irak),
				'other' => q(Dinar Irak),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial Iran),
				'other' => q(Rial Iran),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Krona Islandia \(1918–1981\)),
				'other' => q(Krona Islandia \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Krona Islandia),
				'other' => q(Krona Islandia),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(Lira Italia),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dolar Jamaika),
				'other' => q(Dolar Jamaika),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar Yordania),
				'other' => q(Dinar Yordania),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen Jepang),
				'other' => q(Yen Jepang),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Shilling Kenya),
				'other' => q(Shilling Kenya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som Kirgistan),
				'other' => q(Som Kirgistan),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel Kamboja),
				'other' => q(Riel Kamboja),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franc Komoro),
				'other' => q(Franc Komoro),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won Korea Utara),
				'other' => q(Won Korea Utara),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(Hwan Korea Selatan \(1953–1962\)),
				'other' => q(Hwan Korea Selatan \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(Won Korea Selatan \(1945–1953\)),
				'other' => q(Won Korea Selatan \(1945–1953\)),
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
				'currency' => q(Tenge Kazakstan),
				'other' => q(Tenge Kazakstan),
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
				'currency' => q(Pound Lebanon),
				'other' => q(Pound Lebanon),
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
			symbol => 'LSL',
			display_name => {
				'currency' => q(Loti Lesotho),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas Lituania),
				'other' => q(Litas Lituania),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(Talonas Lituania),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(Franc Konvertibel Luksemburg),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(Franc Luksemburg),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(Financial Franc Luksemburg),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats Latvia),
				'other' => q(Lats Latvia),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(Rubel Latvia),
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
				'currency' => q(Dirham Maroko),
				'other' => q(Dirham Maroko),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(Franc Maroko),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(Franc Monegasque),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(Cupon Moldova),
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
				'currency' => q(Ariary Madagaskar),
				'other' => q(Ariary Madagaskar),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(Franc Malagasi),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar Makedonia),
				'other' => q(Denar Makedonia),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(Denar Makedonia \(1992–1993\)),
				'other' => q(Denar Makedonia \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(Franc Mali),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat Myanmar),
				'other' => q(Kyat Myanmar),
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
				'currency' => q(Pataca Makau),
				'other' => q(Pataca Makau),
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
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(Ouguiya Mauritania),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(Lira Malta),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(Pound Malta),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupee Mauritius),
				'other' => q(Rupee Mauritius),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rufiyaa Maladewa \(1947–1981\)),
				'other' => q(Rufiyaa Maladewa \(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa Maladewa),
				'other' => q(Rufiyaa Maladewa),
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
			symbol => 'MX$',
			display_name => {
				'currency' => q(Peso Meksiko),
				'other' => q(Peso Meksiko),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Peso Silver Meksiko \(1861–1992\)),
				'other' => q(Peso Perak Meksiko),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Unit Investasi Meksiko),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'other' => q(Ringgit Malaysia),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(Escudo Mozambik),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(Metical Mozambik \(1980–2006\)),
				'other' => q(Metical Mozambik \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical Mozambik),
				'other' => q(Metical Mozambik),
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
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(Cordoba Nikaragua \(1988–1991\)),
				'other' => q(Cordoba Nikaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Cordoba Nikaragua),
				'other' => q(Cordoba Nikaragua),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(Guilder Belanda),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Krone Norwegia),
				'other' => q(Krone Norwegia),
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
				'currency' => q(Dolar Selandia Baru),
				'other' => q(Dolar Selandia Baru),
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
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(Inti Peru),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol Peru),
				'other' => q(Sol Peru),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(Sol Peru \(1863–1965\)),
				'other' => q(Sol Peru \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina Papua Nugini),
				'other' => q(Kina Papua Nugini),
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
				'currency' => q(Polandia Zloty),
				'other' => q(Polandia Zloty),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(Zloty Polandia \(1950–1995\)),
				'other' => q(Zloty Polandia \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(Escudo Portugal),
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
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(Dolar Rhodesia),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(Leu Rumania \(1952–2006\)),
				'other' => q(Leu Rumania \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu Rumania),
				'other' => q(Leu Rumania),
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
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(Rubel Rusia \(1991–1998\)),
				'other' => q(Rubel Rusia \(1991–1998\)),
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
				'currency' => q(Riyal Arab Saudi),
				'other' => q(Riyal Arab Saudi),
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
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(Dinar Sudan \(1992–2007\)),
				'other' => q(Dinar Sudan \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Pound Sudan),
				'other' => q(Pound Sudan),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(Pound Sudan \(1957–1998\)),
				'other' => q(Pound Sudan \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Krona Swedia),
				'other' => q(Krona Swedia),
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
				'currency' => q(Pound Saint Helena),
				'other' => q(Pound Saint Helena),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(Tolar Slovenia),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(Koruna Slovakia),
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
				'currency' => q(Shilling Somalia),
				'other' => q(Shilling Somalia),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dolar Suriname),
				'other' => q(Dolar Suriname),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(Guilder Suriname),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Pound Sudan Selatan),
				'other' => q(Pound Sudan Selatan),
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
			symbol => 'Db',
			display_name => {
				'currency' => q(Dobra Sao Tome dan Principe),
				'other' => q(Dobra Sao Tome dan Principe),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(Rubel Soviet),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(Colon El Savador),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Pound Suriah),
				'other' => q(Pound Suriah),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni Swaziland),
				'other' => q(Lilangeni Swaziland),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht Thailand),
				'other' => q(Baht Thailand),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(Rubel Tajikistan),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'other' => q(Somoni Tajikistan),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(Manat Turkmenistan \(1993–2009\)),
				'other' => q(Manat Turkmenistan \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat Turkimenistan),
				'other' => q(Manat Turkimenistan),
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
				'currency' => q(Paʻanga Tonga),
				'other' => q(Paʻanga Tonga),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Escudo Timor),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(Lira Turki \(1922–2005\)),
				'other' => q(Lira Turki \(1922–2005\)),
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
				'currency' => q(Dolar Baru Taiwan),
				'other' => q(Dolar Baru Taiwan),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Shilling Tanzania),
				'other' => q(Shilling Tanzania),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hryvnia Ukraina),
				'other' => q(Hryvnia Ukraina),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(Karbovanet Ukraina),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Shilling Uganda \(1966–1987\)),
				'other' => q(Shilling Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilling Uganda),
				'other' => q(Shilling Uganda),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dolar Amerika Serikat),
				'other' => q(Dolar Amerika Serikat),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(Dolar AS \(Hari berikutnya\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(Dolar AS \(Hari yang sama\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(Peso Uruguay \(Unit Diindeks\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(Peso Uruguay \(1975–1993\)),
				'other' => q(Peso Uruguay \(1975–1993\)),
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
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Bolivar Venezuela \(1871–2008\)),
				'other' => q(Bolivar Venezuela \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
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
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(Dong Vietnam \(1978–1985\)),
				'other' => q(Dong Vietnam \(1978–1985\)),
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
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(Silver),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(Emas),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Unit Gabungan Eropa),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Unit Keuangan Eropa),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(Satuan Hitung Eropa \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(Satuan Hitung Eropa \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dolar Karibia Timur),
				'other' => q(Dolar Karibia Timur),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(Hak Khusus Menggambar),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(Satuan Mata Uang Eropa),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(Franc Gold Perancis),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franc UIC Perancis),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franc CFA BCEAO),
				'other' => q(Franc CFA BCEAO),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(Palladium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Franc CFP),
				'other' => q(Franc CFP),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(Platinum),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(Dana RINET),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(Kode Mata Uang Pengujian),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Mata Uang Tidak Dikenal),
				'other' => q(\(mata uang tidak dikenal\)),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(Dinar Yaman),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial Yaman),
				'other' => q(Rial Yaman),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(Hard Dinar Yugoslavia \(1966–1990\)),
				'other' => q(Dinar Keras Yugoslavia),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(Dinar Baru Yugoslavia \(1994–2002\)),
				'other' => q(Dinar Baru Yugoslavia \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(Dinar Konvertibel Yugoslavia \(1990–1992\)),
				'other' => q(Dinar Konvertibel Yugoslavia \(1990–1992\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(Dinar Reformasi Yugoslavia \(1992–1993\)),
				'other' => q(Dinar Reformasi Yugoslavia \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(Rand Afrika Selatan \(Keuangan\)),
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
				'other' => q(Kwacha Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha Zambia),
				'other' => q(Kwacha Zambia),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(Zaire Baru Zaire \(1993–1998\)),
				'other' => q(Zaire Baru Zaire \(1993–1998\)),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(Zaire Zaire \(1971–1993\)),
				'other' => q(Zaire Zaire \(1971–1993\)),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(Dolar Zimbabwe \(1980–2008\)),
				'other' => q(Dolar Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Dolar Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
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
							'Mar',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Agt',
							'Sep',
							'Okt',
							'Nov',
							'Des'
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
							'Januari',
							'Februari',
							'Maret',
							'April',
							'Mei',
							'Juni',
							'Juli',
							'Agustus',
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Agt',
							'Sep',
							'Okt',
							'Nov',
							'Des'
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
							'Januari',
							'Februari',
							'Maret',
							'April',
							'Mei',
							'Juni',
							'Juli',
							'Agustus',
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
							'Syaw.',
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
							'Sya’ban',
							'Ramadhan',
							'Syawal',
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
							'Syaw.',
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
							'Sya’ban',
							'Ramadhan',
							'Syawal',
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
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Min'
					},
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'M'
					},
					short => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Min'
					},
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
						sat => 'Sabtu',
						sun => 'Minggu'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Min'
					},
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'M'
					},
					short => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Min'
					},
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
						sat => 'Sabtu',
						sun => 'Minggu'
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
					wide => {0 => 'Kuartal ke-1',
						1 => 'Kuartal ke-2',
						2 => 'Kuartal ke-3',
						3 => 'Kuartal ke-4'
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
					wide => {0 => 'Kuartal ke-1',
						1 => 'Kuartal ke-2',
						2 => 'Kuartal ke-3',
						3 => 'Kuartal ke-4'
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
			if ($_ eq 'japanese') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'morning1' if $time >= 0
						&& $time < 1000;
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
					'am' => q{AM},
					'afternoon1' => q{siang},
					'evening1' => q{sore},
					'morning1' => q{pagi},
					'noon' => q{tengah hari},
					'pm' => q{PM},
					'midnight' => q{tengah malam},
					'night1' => q{malam},
				},
				'narrow' => {
					'noon' => q{tengah hari},
					'am' => q{AM},
					'morning1' => q{pagi},
					'evening1' => q{sore},
					'afternoon1' => q{siang},
					'night1' => q{malam},
					'pm' => q{PM},
					'midnight' => q{tengah malam},
				},
				'wide' => {
					'midnight' => q{tengah malam},
					'pm' => q{PM},
					'night1' => q{malam},
					'evening1' => q{sore},
					'afternoon1' => q{siang},
					'morning1' => q{pagi},
					'am' => q{AM},
					'noon' => q{tengah hari},
				},
			},
			'stand-alone' => {
				'wide' => {
					'midnight' => q{tengah malam},
					'pm' => q{PM},
					'night1' => q{malam},
					'afternoon1' => q{siang},
					'evening1' => q{sore},
					'morning1' => q{pagi},
					'am' => q{AM},
					'noon' => q{tengah hari},
				},
				'narrow' => {
					'noon' => q{tengah hari},
					'evening1' => q{sore},
					'afternoon1' => q{siang},
					'morning1' => q{pagi},
					'am' => q{AM},
					'night1' => q{malam},
					'midnight' => q{tengah malam},
					'pm' => q{PM},
				},
				'abbreviated' => {
					'noon' => q{tengah hari},
					'morning1' => q{pagi},
					'evening1' => q{sore},
					'afternoon1' => q{siang},
					'am' => q{AM},
					'night1' => q{malam},
					'midnight' => q{tengah malam},
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
		'dangi' => {
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
				'0' => 'SM',
				'1' => 'M'
			},
			narrow => {
				'0' => 'SM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Sebelum Masehi',
				'1' => 'Masehi'
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
				'0' => 'SAKA'
			},
			narrow => {
				'0' => 'SAKA'
			},
			wide => {
				'0' => 'SAKA'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'H'
			},
			narrow => {
				'0' => 'H'
			},
			wide => {
				'0' => 'H'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749-749)',
				'12' => 'Tempyō-shōhō (749-757)',
				'13' => 'Tempyō-hōji (757-765)',
				'14' => 'Temphō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saiko (854–857)',
				'26' => 'Tennan (857–859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Genkei (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kampyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Shōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten-en (973-976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Ei-en (987-989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eiho (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kaho (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Shōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hoen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Tenyō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hogen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin-an (1166-1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryuku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Shōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Shōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tempuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En-ō (1239-1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun-ō (1260-1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun-ei (1264-1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkei (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkyō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Kareki (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kemmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun-an (1444-1449)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenmon (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenwa (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Hōryaku (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An-ei (1772-1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man-en (1860-1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
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
				'0' => 'Sebelum R.O.C.',
				'1' => 'R.O.C.'
			},
			narrow => {
				'0' => 'Sebelum R.O.C.',
				'1' => 'R.O.C.'
			},
			wide => {
				'0' => 'Sebelum R.O.C.',
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
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'chinese' => {
			'full' => q{EEEE, U MMMM dd},
			'long' => q{U MMMM d},
			'medium' => q{U MMM d},
			'short' => q{y-M-d},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, dd MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'japanese' => {
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
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
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
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
			'full' => q{{1} 'pukul' {0}},
			'long' => q{{1} 'pukul' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{{1} 'pukul' {0}},
			'long' => q{{1} 'pukul' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			'full' => q{{1} 'pukul' {0}},
			'long' => q{{1} 'pukul' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'japanese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			E => q{ccc},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			E => q{ccc},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			Hmsv => q{HH.mm.ss v},
			Hmv => q{HH.mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'minggu' 'ke'-W MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss. a v},
			hmv => q{h.mm a v},
			ms => q{mm.ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'minggu' 'ke'-w Y},
		},
		'buddhist' => {
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
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{G y},
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
		'japanese' => {
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{G y},
		},
		'islamic' => {
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
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
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
		'roc' => {
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{G y},
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
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
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
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
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
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
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
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
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
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y – y},
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
		'buddhist' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH.mm – HH.mm},
				m => q{HH.mm – HH.mm},
			},
			Hmv => {
				H => q{HH.mm – HH.mm v},
				m => q{HH.mm – HH.mm v},
			},
			Hv => {
				H => q{HH – HH v},
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
				h => q{h – h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm – h.mm a},
				m => q{h.mm – h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm – h.mm a v},
				m => q{h.mm – h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
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
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'islamic' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH.mm – HH.mm},
				m => q{HH.mm – HH.mm},
			},
			Hmv => {
				H => q{HH.mm – HH.mm v},
				m => q{HH.mm – HH.mm v},
			},
			Hv => {
				H => q{HH – HH v},
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
				h => q{h – h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm – h.mm a},
				m => q{h.mm – h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm – h.mm a v},
				m => q{h.mm – h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
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
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(mulai musim semi),
						1 => q(air hujan),
						2 => q(serangga bangun),
						3 => q(ekuinoks musim semi),
						5 => q(hujan butiran),
						6 => q(mulai musim panas),
						12 => q(mulai musim gugur),
						13 => q(akhir panas),
						14 => q(white dew),
						15 => q(ekuinoks musim gugur),
						16 => q(embun dingin),
						17 => q(embun beku turun),
						18 => q(mulai musim dingin),
						19 => q(mulai turun salju),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
		},
		'dangi' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(mulai musim semi),
						1 => q(air hujan),
						2 => q(serangga bangun),
						3 => q(ekuinoks musim semi),
						5 => q(hujan butiran),
						6 => q(mulai musim panas),
						12 => q(mulai musim gugur),
						13 => q(akhir panas),
						14 => q(embun putih),
						15 => q(ekuinoks musim gugur),
						16 => q(embun dingin),
						17 => q(embun beku turun),
						19 => q(mulai turun salju),
					},
					'wide' => {
						0 => q(mulai musim semi),
						1 => q(air hujan),
						2 => q(serangga bangun),
						3 => q(ekuinoks musim semi),
						5 => q(hujan butiran),
						6 => q(mulai musim panas),
						12 => q(mulai musim gugur),
						13 => q(akhir panas),
						14 => q(embun putih),
						15 => q(ekuinoks musim gugur),
						16 => q(embun dingin),
						17 => q(embun beku turun),
						19 => q(mulai turun salju),
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
		hourFormat => q(+HH.mm;-HH.mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Waktu {0}),
		regionFormat => q(Waktu Musim Panas {0}),
		regionFormat => q(Waktu Standar {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Waktu Musim Panas Acre#,
				'generic' => q#Waktu Acre#,
				'standard' => q#Waktu Standar Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Waktu Afganistan#,
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
			exemplarCity => q#Aljir#,
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
			exemplarCity => q#Kairo#,
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
				'standard' => q#Waktu Standar Afrika Selatan#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Afrika Barat#,
				'generic' => q#Waktu Afrika Barat#,
				'standard' => q#Waktu Standar Afrika Barat#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waktu Musim Panas Alaska#,
				'generic' => q#Waktu Alaska#,
				'standard' => q#Waktu Standar Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Waktu Musim Panas Almaty#,
				'generic' => q#Waktu Almaty#,
				'standard' => q#Waktu Standar Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waktu Musim Panas Amazon#,
				'generic' => q#Waktu Amazon#,
				'standard' => q#Waktu Standar Amazon#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
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
			exemplarCity => q#Dominika#,
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
			exemplarCity => q#Martinik#,
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
			exemplarCity => q#Beulah, Dakota Utara#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota Utara#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota Utara#,
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
				'daylight' => q#Waktu Musim Panas Tengah#,
				'generic' => q#Waktu Tengah#,
				'standard' => q#Waktu Standar Tengah#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Timur#,
				'generic' => q#Waktu Timur#,
				'standard' => q#Waktu Standar Timur#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pegunungan#,
				'generic' => q#Waktu Pegunungan#,
				'standard' => q#Waktu Standar Pegunungan#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pasifik#,
				'generic' => q#Waktu Pasifik#,
				'standard' => q#Waktu Standar Pasifik#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Waktu Musim Panas Anadyr#,
				'generic' => q#Waktu Anadyr#,
				'standard' => q#Waktu Standar Anadyr#,
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
				'daylight' => q#Waktu Musim Panas Apia#,
				'generic' => q#Waktu Apia#,
				'standard' => q#Waktu Standar Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Waktu Musim Panas Aqtau#,
				'generic' => q#Waktu Aqtau#,
				'standard' => q#Waktu Standar Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Waktu Musim Panas Aqtobe#,
				'generic' => q#Waktu Aqtobe#,
				'standard' => q#Waktu Standar Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waktu Musim Panas Arab#,
				'generic' => q#Waktu Arab#,
				'standard' => q#Waktu Standar Arab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waktu Musim Panas Argentina#,
				'generic' => q#Waktu Argentina#,
				'standard' => q#Waktu Standar Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Argentina Bagian Barat#,
				'generic' => q#Waktu Argentina Bagian Barat#,
				'standard' => q#Waktu Standar Argentina Bagian Barat#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Armenia#,
				'generic' => q#Waktu Armenia#,
				'standard' => q#Waktu Standar Armenia#,
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
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
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
			exemplarCity => q#Kolombo#,
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
			exemplarCity => q#Yerusalem#,
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
			exemplarCity => q#Makau#,
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
			exemplarCity => q#Nikosia#,
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
				'daylight' => q#Waktu Musim Panas Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Standar Atlantik#,
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
			exemplarCity => q#Tanjung Verde#,
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
			exemplarCity => q#Georgia Selatan#,
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
				'daylight' => q#Waktu Musim Panas Tengah Australia#,
				'generic' => q#Waktu Tengah Australia#,
				'standard' => q#Waktu Standar Tengah Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Barat Tengah Australia#,
				'generic' => q#Waktu Barat Tengah Australia#,
				'standard' => q#Waktu Standar Barat Tengah Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Timur Australia#,
				'generic' => q#Waktu Timur Australia#,
				'standard' => q#Waktu Standar Timur Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Barat Australia#,
				'generic' => q#Waktu Barat Australia#,
				'standard' => q#Waktu Standar Barat Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Azerbaijan#,
				'generic' => q#Waktu Azerbaijan#,
				'standard' => q#Waktu Standar Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Waktu Musim Panas Azores#,
				'generic' => q#Waktu Azores#,
				'standard' => q#Waktu Standar Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waktu Musim Panas Bangladesh#,
				'generic' => q#Waktu Bangladesh#,
				'standard' => q#Waktu Standar Bangladesh#,
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
				'daylight' => q#Waktu Musim Panas Brasil#,
				'generic' => q#Waktu Brasil#,
				'standard' => q#Waktu Standar Brasil#,
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
				'standard' => q#Waktu Standar Tanjung Verde#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Waktu Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Waktu Standar Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Waktu Musim Panas Chatham#,
				'generic' => q#Waktu Chatham#,
				'standard' => q#Waktu Standar Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waktu Musim Panas Cile#,
				'generic' => q#Waktu Cile#,
				'standard' => q#Waktu Standar Cile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Waktu Musim Panas Tiongkok#,
				'generic' => q#Waktu Tiongkok#,
				'standard' => q#Waktu Standar Tiongkok#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Choibalsan#,
				'generic' => q#Waktu Choibalsan#,
				'standard' => q#Waktu Standar Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Waktu Pulau Natal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waktu Kepulauan Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Kolombia#,
				'generic' => q#Waktu Kolombia#,
				'standard' => q#Waktu Standar Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Waktu Tengah Musim Panas Kep. Cook#,
				'generic' => q#Waktu Kep. Cook#,
				'standard' => q#Waktu Standar Kep. Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Waktu Musim Panas Kuba#,
				'generic' => q#Waktu Kuba#,
				'standard' => q#Waktu Standar Kuba#,
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
				'standard' => q#Waktu Timor Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pulau Paskah#,
				'generic' => q#Waktu Pulau Paskah#,
				'standard' => q#Waktu Standar Pulau Paskah#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Waktu Ekuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waktu Universal Terkoordinasi#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Tidak Dikenal#,
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
			exemplarCity => q#Athena#,
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
			exemplarCity => q#Kishinev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Waktu Standar Irlandia#,
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
			exemplarCity => q#Pulau Man#,
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
				'daylight' => q#Waktu Musim Panas Inggris#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
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
			exemplarCity => q#Moskwa#,
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
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
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
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wina#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsawa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizhia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropa Tengah#,
				'generic' => q#Waktu Eropa Tengah#,
				'standard' => q#Waktu Standar Eropa Tengah#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropa Timur#,
				'generic' => q#Waktu Eropa Timur#,
				'standard' => q#Waktu Standar Eropa Timur#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Waktu Eropa Timur Jauh#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Eropa Barat#,
				'generic' => q#Waktu Eropa Barat#,
				'standard' => q#Waktu Standar Eropa Barat#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Waktu Musim Panas Kepulauan Falkland#,
				'generic' => q#Waktu Kepulauan Falkland#,
				'standard' => q#Waktu Standar Kepulauan Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Waktu Musim Panas Fiji#,
				'generic' => q#Waktu Fiji#,
				'standard' => q#Waktu Standar Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Waktu Guyana Prancis#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waktu Wilayah Selatan dan Antarktika Prancis#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
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
				'standard' => q#Waktu Standar Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Waktu Kep. Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Greenland Timur#,
				'generic' => q#Waktu Greenland Timur#,
				'standard' => q#Waktu Standar Greenland Timur#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waktu Musim Panas Greenland Barat#,
				'generic' => q#Waktu Greenland Barat#,
				'standard' => q#Waktu Standar Greenland Barat#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Waktu Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waktu Standar Teluk#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waktu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waktu Musim Panas Hawaii-Aleutian#,
				'generic' => q#Waktu Hawaii-Aleutian#,
				'standard' => q#Waktu Standar Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Waktu Musim Panas Hong Kong#,
				'generic' => q#Waktu Hong Kong#,
				'standard' => q#Waktu Standar Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Waktu Musim Panas Hovd#,
				'generic' => q#Waktu Hovd#,
				'standard' => q#Waktu Standar Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waktu India#,
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
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maladewa#,
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
				'standard' => q#Waktu Samudera Hindia#,
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
			short => {
				'standard' => q#WITA#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Waktu Indonesia Timur#,
			},
			short => {
				'standard' => q#WIT#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waktu Indonesia Barat#,
			},
			short => {
				'standard' => q#WIB#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waktu Musim Panas Iran#,
				'generic' => q#Waktu Iran#,
				'standard' => q#Waktu Standar Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Irkutsk#,
				'generic' => q#Waktu Irkutsk#,
				'standard' => q#Waktu Standar Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Waktu Musim Panas Israel#,
				'generic' => q#Waktu Israel#,
				'standard' => q#Waktu Standar Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Jepang#,
				'generic' => q#Waktu Jepang#,
				'standard' => q#Waktu Standar Jepang#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Waktu Musim Panas Petropavlovsk-Kamchatski#,
				'generic' => q#Waktu Petropavlovsk-Kamchatsky#,
				'standard' => q#Waktu Standar Petropavlovsk-Kamchatsky#,
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
				'daylight' => q#Waktu Musim Panas Korea#,
				'generic' => q#Waktu Korea#,
				'standard' => q#Waktu Standar Korea#,
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
				'standard' => q#Waktu Standar Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waktu Kirghizia#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Waktu Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waktu Kep. Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Waktu Musim Panas Lord Howe#,
				'generic' => q#Waktu Lord Howe#,
				'standard' => q#Waktu Standar Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Waktu Musim Panas Makau#,
				'generic' => q#Waktu Makau#,
				'standard' => q#Waktu Standar Makau#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Waktu Kepulauan Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Magadan#,
				'generic' => q#Waktu Magadan#,
				'standard' => q#Waktu Standar Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Waktu Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waktu Maladewa#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waktu Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Waktu Kep. Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waktu Musim Panas Mauritius#,
				'generic' => q#Waktu Mauritius#,
				'standard' => q#Waktu Standar Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Waktu Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Waktu Musim Panas Meksiko Barat Laut#,
				'generic' => q#Waktu Meksiko Barat Laut#,
				'standard' => q#Waktu Standar Meksiko Barat Laut#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pasifik Meksiko#,
				'generic' => q#Waktu Pasifik Meksiko#,
				'standard' => q#Waktu Standar Pasifik Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Waktu Musim Panas Ulan Bator#,
				'generic' => q#Waktu Ulan Bator#,
				'standard' => q#Waktu Standar Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waktu Musim Panas Moskwa#,
				'generic' => q#Waktu Moskwa#,
				'standard' => q#Waktu Standar Moskwa#,
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
				'daylight' => q#Waktu Musim Panas Kaledonia Baru#,
				'generic' => q#Waktu Kaledonia Baru#,
				'standard' => q#Waktu Standar Kaledonia Baru#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Waktu Musim Panas Selandia Baru#,
				'generic' => q#Waktu Selandia Baru#,
				'standard' => q#Waktu Standar Selandia Baru#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Waktu Musim Panas Newfoundland#,
				'generic' => q#Waktu Newfoundland#,
				'standard' => q#Waktu Standar Newfoundland#,
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
				'standard' => q#Waktu Standar Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Waktu Kep. Mariana Utara#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Novosibirsk#,
				'generic' => q#Waktu Novosibirsk#,
				'standard' => q#Waktu Standar Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Omsk#,
				'generic' => q#Waktu Omsk#,
				'standard' => q#Waktu Standar Omsk#,
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
			exemplarCity => q#Guadalkanal#,
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
				'standard' => q#Waktu Standar Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Waktu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Waktu Papua Nugini#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Waktu Musim Panas Paraguay#,
				'generic' => q#Waktu Paraguay#,
				'standard' => q#Waktu Standar Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Waktu Musim Panas Peru#,
				'generic' => q#Waktu Peru#,
				'standard' => q#Waktu Standar Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Waktu Musim Panas Filipina#,
				'generic' => q#Waktu Filipina#,
				'standard' => q#Waktu Standar Filipina#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Waktu Kepulauan Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Waktu Musim Panas Saint Pierre dan Miquelon#,
				'generic' => q#Waktu Saint Pierre dan Miquelon#,
				'standard' => q#Waktu Standar Saint Pierre dan Miquelon#,
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
				'standard' => q#Waktu Standar Qyzylorda#,
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
				'standard' => q#Waktu Standar Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Waktu Musim Panas Samara#,
				'generic' => q#Waktu Samara#,
				'standard' => q#Waktu Standar Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Waktu Musim Panas Samoa#,
				'generic' => q#Waktu Samoa#,
				'standard' => q#Waktu Standar Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waktu Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Waktu Standar Singapura#,
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
				'daylight' => q#Waktu Musim Panas Taipei#,
				'generic' => q#Waktu Taipei#,
				'standard' => q#Waktu Standar Taipei#,
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
				'standard' => q#Waktu Standar Tonga#,
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
				'standard' => q#Waktu Standar Turkmenistan#,
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
				'standard' => q#Waktu Standar Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waktu Musim Panas Uzbekistan#,
				'generic' => q#Waktu Uzbekistan#,
				'standard' => q#Waktu Standar Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waktu Musim Panas Vanuatu#,
				'generic' => q#Waktu Vanuatu#,
				'standard' => q#Waktu Standar Vanuatu#,
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
				'standard' => q#Waktu Standar Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Waktu Musim Panas Volgograd#,
				'generic' => q#Waktu Volgograd#,
				'standard' => q#Waktu Standar Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waktu Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waktu Kepulauan Wake#,
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
				'standard' => q#Waktu Standar Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Waktu Musim Panas Yekaterinburg#,
				'generic' => q#Waktu Yekaterinburg#,
				'standard' => q#Waktu Standar Yekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
