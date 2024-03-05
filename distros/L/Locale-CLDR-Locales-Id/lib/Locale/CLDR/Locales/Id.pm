=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Id - Package for language Indonesian

=cut

package Locale::CLDR::Locales::Id;
# This file auto generated from Data\common\main\id.xml
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
 				'ann' => 'Obolo',
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
 				'atj' => 'Atikamekw',
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
 				'bgc' => 'Haryanvi',
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
 				'car' => 'Karibia',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ccp' => 'Chakma',
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
 				'ckb@alt=variant' => 'Kurdi, Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Korsika',
 				'cop' => 'Koptik',
 				'cr' => 'Kree',
 				'crg' => 'Michif',
 				'crh' => 'Tatar Krimea',
 				'crj' => 'East Cree Selatan',
 				'crk' => 'Cree Dataran',
 				'crl' => 'East Cree Utara',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'crs' => 'Seselwa Kreol Prancis',
 				'cs' => 'Cheska',
 				'csb' => 'Kashubia',
 				'csw' => 'Cree Rawa',
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
 				'en_GB' => 'Inggris (Britania)',
 				'en_GB@alt=short' => 'Inggris (UK)',
 				'enm' => 'Inggris Abad Pertengahan',
 				'eo' => 'Esperanto',
 				'es' => 'Spanyol',
 				'es_ES' => 'Spanyol (Eropa)',
 				'et' => 'Esti',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persia',
 				'fa_AF' => 'Persia Dari',
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
 				'hax' => 'Haida Selatan',
 				'he' => 'Ibrani',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
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
 				'ik' => 'Inupiak',
 				'ikt' => 'Inuktitut Kanada Barat',
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
 				'kgp' => 'Kaingang',
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
 				'kwk' => 'Kwakʼwala',
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
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lol' => 'Mongo',
 				'lou' => 'Kreol Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Utara',
 				'lsm' => 'Saamia',
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
 				'moe' => 'Innu-aimun',
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
 				'ojb' => 'Ojibwe Barat Laut',
 				'ojc' => 'Ojibwe Tengah',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Ojibwe Barat',
 				'oka' => 'Okanagan',
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
 				'pis' => 'Pijin',
 				'pl' => 'Polski',
 				'pon' => 'Pohnpeia',
 				'pqm' => 'Maliseet-Passamaquoddy',
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
 				'rhg' => 'Rohingya',
 				'rm' => 'Reto-Roman',
 				'rn' => 'Rundi',
 				'ro' => 'Rumania',
 				'ro_MD' => 'Moldavia',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
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
 				'slh' => 'Lushootseed Selatan',
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
 				'str' => 'Salish Selat',
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
 				'tce' => 'Tutchone Selatan',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetun',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
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
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshia',
 				'tt' => 'Tatar',
 				'ttm' => 'Tutchone Utara',
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
 				'wuu' => 'Wu Tionghoa',
 				'xal' => 'Kalmuk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapois',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kanton',
 				'yue@alt=menu' => 'Tionghoa, Kanton',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotek',
 				'zbl' => 'Blissymbol',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamazight Maroko Standar',
 				'zh' => 'Tionghoa',
 				'zh@alt=menu' => 'Tionghoa, Mandarin',
 				'zh_Hans@alt=long' => 'Tionghoa Mandarin (Sederhana)',
 				'zh_Hant@alt=long' => 'Tionghoa Mandarin (Tradisional)',
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
			'Adlm' => 'Adlam',
 			'Afak' => 'Afaka',
 			'Aghb' => 'Albania Kaukasia',
 			'Arab' => 'Arab',
 			'Arab@alt=variant' => 'Arab Persia',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Aram Imperial',
 			'Armn' => 'Armenia',
 			'Avst' => 'Avesta',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengali',
 			'Bhks' => 'Bhaiksuki',
 			'Blis' => 'Blissymbol',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Bugis',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Simbol Aborigin Kanada Kesatuan',
 			'Cari' => 'Karia',
 			'Cher' => 'Cherokee',
 			'Chrs' => 'Chorasmian',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptik',
 			'Cpmn' => 'Cypro-Minoan',
 			'Cprt' => 'Siprus',
 			'Cyrl' => 'Sirilik',
 			'Cyrs' => 'Gereja Slavonia Sirilik Lama',
 			'Deva' => 'Dewanagari',
 			'Diak' => 'Dives Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Stenografi Duployan',
 			'Egyd' => 'Demotik Mesir',
 			'Egyh' => 'Hieratik Mesir',
 			'Egyp' => 'Hieroglip Mesir',
 			'Elba' => 'Elbasan',
 			'Elym' => 'Elymaic',
 			'Ethi' => 'Etiopia',
 			'Geok' => 'Georgian Khutsuri',
 			'Geor' => 'Georgia',
 			'Glag' => 'Glagolitic',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gothic',
 			'Gran' => 'Grantha',
 			'Grek' => 'Yunani',
 			'Gujr' => 'Gujarat',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han dengan Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Sederhana',
 			'Hans@alt=stand-alone' => 'Han Sederhana',
 			'Hant' => 'Tradisional',
 			'Hant@alt=stand-alone' => 'Han Tradisional',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Hieroglif Anatolia',
 			'Hmng' => 'Pahawh Hmong',
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
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
 			'Kits' => 'Skrip kecil Khitan',
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
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycia',
 			'Lydi' => 'Lydia',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makassar',
 			'Mand' => 'Mandae',
 			'Mani' => 'Manikhei',
 			'Marc' => 'Marchen',
 			'Maya' => 'Hieroglip Maya',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Kursif Meroitik',
 			'Mero' => 'Meroitik',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolia',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Myanmar',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Arab Utara Kuno',
 			'Nbat' => 'Nabataea',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nushu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Chiki Lama',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oriya',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Ougr' => 'Uyghur Lama',
 			'Palm' => 'Palmira',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Permik Kuno',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Pahlevi',
 			'Phlp' => 'Mazmur Pahlevi',
 			'Phlv' => 'Kitab Pahlevi',
 			'Phnx' => 'Phoenix',
 			'Plrd' => 'Fonetik Pollard',
 			'Prti' => 'Prasasti Parthia',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi',
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
 			'Sogd' => 'Sogdian',
 			'Sogo' => 'Sogdian Lama',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
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
 			'Tnsa' => 'Tangsa',
 			'Toto' => 'Toto (txo)',
 			'Ugar' => 'Ugaritik',
 			'Vaii' => 'Vai',
 			'Visp' => 'Ucapan Terlihat',
 			'Vith' => 'Vithkuqi',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Persia Kuno',
 			'Xsux' => 'Cuneiform Sumero-Akkadia',
 			'Yezi' => 'Yezidi',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Zanabazar Square',
 			'Zinh' => 'Warisan',
 			'Zmth' => 'Notasi Matematika',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Tidak Tertulis',
 			'Zyyy' => 'Umum',
 			'Zzzz' => 'Skrip Tidak Dikenal',

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
 			'AQ' => 'Antarktika',
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
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Pantai Gading',
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
 			'CX' => 'Pulau Natal',
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
 			'FK' => 'Kepulauan Falkland',
 			'FK@alt=variant' => 'Kepulauan Falkland (Malvinas)',
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
 			'GL' => 'Greenland',
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
 			'HK' => 'Hong Kong DAK Tiongkok',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Pulau Heard dan Kepulauan McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Kepulauan Canaria',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlandia',
 			'IL' => 'Israel',
 			'IM' => 'Pulau Man',
 			'IN' => 'India',
 			'IO' => 'Wilayah Inggris di Samudra Hindia',
 			'IO@alt=chagos' => 'Kepulauan Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordania',
 			'JP' => 'Jepang',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgizstan',
 			'KH' => 'Kamboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Saint Kitts dan Nevis',
 			'KP' => 'Korea Utara',
 			'KR' => 'Korea Selatan',
 			'KW' => 'Kuwait',
 			'KY' => 'Kepulauan Cayman',
 			'KZ' => 'Kazakhstan',
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
 			'LY' => 'Libya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Kepulauan Marshall',
 			'MK' => 'Makedonia Utara',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Makau DAK Tiongkok',
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
 			'NZ@alt=variant' => 'Aotearoa (Selandia Baru)',
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
 			'SZ' => 'eSwatini',
 			'SZ@alt=variant' => 'Eswatini',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Kepulauan Turks dan Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Wilayah Selatan Prancis',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'Timor Timur',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TR@alt=variant' => 'Turkiye',
 			'TT' => 'Trinidad dan Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Kepulauan Terluar AS',
 			'UN' => 'Perserikatan Bangsa-Bangsa',
 			'UN@alt=short' => 'PBB',
 			'US' => 'Amerika Serikat',
 			'US@alt=short' => 'AS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Saint Vincent dan Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Kepulauan Virgin Britania Raya',
 			'VI' => 'Kepulauan Virgin Amerika Serikat',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Kepulauan Wallis dan Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Aksen Asing',
 			'XB' => 'Pseudo-Bidi',
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
 			'ABL1943' => 'Formulasi ortografi 1943',
 			'AKUAPEM' => 'AKUAPIM',
 			'ALALC97' => 'ALA-LC Latin, edisi 1997',
 			'ALUKU' => 'Dialek Aluku',
 			'AO1990' => 'Perjanjian Ortografi Bahasa Portugis 1990',
 			'ARANES' => 'ARAN',
 			'AREVELA' => 'Armenia Timur',
 			'AREVMDA' => 'Armenia Barat',
 			'ARKAIKA' => 'Arkaika',
 			'ASANTE' => 'Asante',
 			'AUVERN' => 'Auvern',
 			'BAKU1926' => 'Alfabet Latin Turki Terpadu',
 			'BALANKA' => 'Dialek Balanka Anii',
 			'BARLA' => 'Kelompok dialek Barlavento Kabuverdianu',
 			'BASICENG' => 'Basiceng',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'BISKAY',
 			'BISKE' => 'Dialek San Giorgio/Bila',
 			'BOHORIC' => 'Alfabet Bohorič',
 			'BOONT' => 'Boontling',
 			'BORNHOLM' => 'Bornholm',
 			'CISAUP' => 'Cisaup',
 			'COLB1945' => 'Konvensi Ortografi Portugis-Brasil 1945',
 			'CORNU' => 'Cornu',
 			'CREISS' => 'Creiss',
 			'DAJNKO' => 'Alfabet Dajnko',
 			'FONIPA' => 'Fonetik IPA',
 			'FONUPA' => 'Fonetik UPA',
 			'HEPBURN' => 'Hepburn Latin',
 			'HOGNORSK' => 'NORWEDIA TINGGI',
 			'KKCOR' => 'Ortografi Umum',
 			'LIPAW' => 'Dialek Lipovaz Resia',
 			'MONOTON' => 'Monoton',
 			'NDYUKA' => 'Dialek Ndyuka',
 			'NEDIS' => 'Dialek Natiso',
 			'NJIVA' => 'Dialek Gniva/Njiva',
 			'OSOJS' => 'Dialek Oseacco/Osojane',
 			'PAMAKA' => 'Dialek Pamaka',
 			'PINYIN' => 'Pinyin Latin',
 			'POLYTON' => 'Politon',
 			'POSIX' => 'Komputer',
 			'REVISED' => 'Ortografi Revisi',
 			'ROZAJ' => 'Resia',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Inggris Standar Skotlandia',
 			'SCOUSE' => 'Skaus',
 			'SOLBA' => 'Dialek Stolvizza/Solbica',
 			'TARASK' => 'Ortografi Taraskievica',
 			'UCCOR' => 'Ortografi Terpadu',
 			'UCRCOR' => 'Ortografi Revisi Terpadu',
 			'VALENCIA' => 'Valencia',
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
 			'colalternate' => 'Pengurutan Abaikan Simbol',
 			'colbackwards' => 'Pengurutan Aksen Terbalik',
 			'colcasefirst' => 'Pengurutan Huruf Besar/Huruf Kecil',
 			'colcaselevel' => 'Pengurutan Peka Huruf Besar',
 			'collation' => 'Aturan Pengurutan',
 			'colnormalization' => 'Pengurutan Dinormalisasi',
 			'colnumeric' => 'Pengurutan Numerik',
 			'colstrength' => 'Kekuatan Pengurutan',
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
 				'islamic-tbla' => q{Kalender Astronomi Islam},
 				'islamic-umalqura' => q{Kalender Islam (Umm al-Qura)},
 				'iso8601' => q{Kalender ISO-8601},
 				'japanese' => q{Kalender Jepang},
 				'persian' => q{Kalender Persia},
 				'roc' => q{Kalender Min-guo},
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
 				'big5han' => q{Aturan Pengurutan Tionghoa Tradisional - Big5},
 				'compat' => q{Aturan Pengurutan Sebelumnya, untuk kompatibilitas},
 				'dictionary' => q{Aturan Pengurutan Kamus},
 				'ducet' => q{Aturan Pengurutan Unicode Default},
 				'emoji' => q{Urutan Sortir Emoji},
 				'eor' => q{Aturan Pengurutan Eropa},
 				'gb2312han' => q{Aturan Pengurutan Tionghoa (Sederhana) - GB2312},
 				'phonebook' => q{Aturan Pengurutan Buku Telepon},
 				'phonetic' => q{Aturan Pengurutan Fonetik},
 				'pinyin' => q{Aturan Pengurutan Pinyin},
 				'reformed' => q{Aturan Pengurutan yang Diubah Bentuknya},
 				'search' => q{Pencarian Tujuan Umum},
 				'searchjl' => q{Pencarian Menurut Konsonan Awal Hangul},
 				'standard' => q{Aturan Pengurutan Standar},
 				'stroke' => q{Aturan Pengurutan Guratan},
 				'traditional' => q{Aturan Pengurutan Tradisional},
 				'unihan' => q{Aturan Pengurutan Guratan Radikal},
 				'zhuyin' => q{Aturan Pengurutan Zhuyin},
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
 				'bgn' => q{Transliterasi BGN AS},
 				'ungegn' => q{Transliterasi GEGN PBB},
 			},
 			'ms' => {
 				'metric' => q{Sistem Metrik},
 				'uksystem' => q{Sistem Pengukuran Imperial},
 				'ussystem' => q{Sistem Pengukuran AS},
 			},
 			'numbers' => {
 				'ahom' => q{Angka Ahom},
 				'arab' => q{Angka Arab Timur},
 				'arabext' => q{Angka Arab Timur Diperluas},
 				'armn' => q{Angka Armenia},
 				'armnlow' => q{Angka Huruf Kecil Armenia},
 				'bali' => q{Angka Bali},
 				'beng' => q{Angka Bengali},
 				'brah' => q{Angka Brahmi},
 				'cakm' => q{Angka Chakma},
 				'cham' => q{Angka Cham},
 				'cyrl' => q{Angka Sirilik},
 				'deva' => q{Angka Dewanagari},
 				'diak' => q{Angka Dives Akuru},
 				'ethi' => q{Angka Etiopia},
 				'finance' => q{Angka Finansial},
 				'fullwide' => q{Angka Lebar Penuh},
 				'geor' => q{Angka Georgia},
 				'gong' => q{Angka Gunjala Gondi},
 				'gonm' => q{Angka Masaram Gondi},
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
 				'hmng' => q{Angka Pahawh Hmong},
 				'hmnp' => q{Angka Nyiakeng Puachue Hmong},
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
 				'mathbold' => q{Angka Tebal Matematika},
 				'mathdbl' => q{Angka Double-Struck Matematika},
 				'mathmono' => q{Angka Monospace Matematika},
 				'mathsanb' => q{Angka Tebal Sans-Serif Matematika},
 				'mathsans' => q{Angka Sans-Serif Matematika},
 				'mlym' => q{Angka Malayalam},
 				'modi' => q{Angka Modi},
 				'mong' => q{Angka Mongolia},
 				'mroo' => q{Angka Mro},
 				'mtei' => q{Angka Meetei Mayek},
 				'mymr' => q{Angka Myanmar},
 				'mymrshan' => q{Angka Myanmar Shan},
 				'mymrtlng' => q{Angka Myanmar Tai Laing},
 				'native' => q{Angka Asli},
 				'nkoo' => q{Angka N’Ko},
 				'olck' => q{Angka Ol Chiki},
 				'orya' => q{Angka Oriya},
 				'osma' => q{Angka Osmanya},
 				'rohg' => q{Angka Hanifi Rohingya},
 				'roman' => q{Angka Romawi},
 				'romanlow' => q{Angka Huruf Kecil Romawi},
 				'saur' => q{Angka Saurashtra},
 				'shrd' => q{Angka Sharada},
 				'sind' => q{Angka Khudawadi},
 				'sinh' => q{Angka Sinhala Lith},
 				'sora' => q{Angka Sora Sompeng},
 				'sund' => q{Angka Sunda},
 				'takr' => q{Angka Takri},
 				'talu' => q{Angka Tai Lue Baru},
 				'taml' => q{Angka Tamil Tradisional},
 				'tamldec' => q{Angka Tamil},
 				'telu' => q{Angka Telugu},
 				'thai' => q{Angka Thai},
 				'tibt' => q{Angka Tibet},
 				'tirh' => q{Angka Tirhuta},
 				'traditional' => q{Angka Tradisional},
 				'vaii' => q{Angka Vai},
 				'wara' => q{Angka Warang Citi},
 				'wcho' => q{Angka Wancho},
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
			auxiliary => qr{[áàăâåäãā æ ç éèĕêëē íìĭîïī ñ óòŏôöøō œ úùŭûüū ÿ]},
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
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter per detik persegi),
						'other' => q({0} meter per detik persegi),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter per detik persegi),
						'other' => q({0} meter per detik persegi),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(menit busur),
						'other' => q({0} menit busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(menit busur),
						'other' => q({0} menit busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(detik busur),
						'other' => q({0} detik busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(detik busur),
						'other' => q({0} detik busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} derajat),
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
					'area-acre' => {
						'other' => q({0} ekar),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} ekar),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} hektare),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} hektare),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} per sentimeter persegi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} per sentimeter persegi),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0} kaki persegi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0} kaki persegi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} per inci persegi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} per inci persegi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
						'per' => q({0} per kilometer persegi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
						'per' => q({0} per kilometer persegi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} per meter persegi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} per meter persegi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0} mil persegi),
						'per' => q({0} per mil persegi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0} mil persegi),
						'per' => q({0} per mil persegi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard persegi),
						'other' => q({0} yard persegi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard persegi),
						'other' => q({0} yard persegi),
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
						'name' => q(milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} persen),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} persen),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} permil),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} permil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagian per juta),
						'other' => q({0} bagian per juta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagian per juta),
						'other' => q({0} bagian per juta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0} permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0} permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil per galon),
						'other' => q({0} mil per galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil per galon),
						'other' => q({0} mil per galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil per galon Imp.),
						'other' => q({0} mil per galon Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil per galon Imp.),
						'other' => q({0} mil per galon Imp.),
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
						'name' => q(gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte),
						'other' => q({0} gigabyte),
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
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
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
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
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
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} hari),
						'per' => q({0} per hari),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} hari),
						'per' => q({0} per hari),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekade),
						'other' => q({0} dekade),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekade),
						'other' => q({0} dekade),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} jam),
						'per' => q({0} per jam),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} jam),
						'per' => q({0} per jam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} per menit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} per menit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} bulan),
						'per' => q({0} per bulan),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} bulan),
						'per' => q({0} per bulan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kuartal),
						'other' => q({0} kuartal),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kuartal),
						'other' => q({0} kuartal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} per detik),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} per detik),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} minggu),
						'per' => q({0} per minggu),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} minggu),
						'per' => q({0} per minggu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} tahun),
						'per' => q({0} per tahun),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} tahun),
						'per' => q({0} per tahun),
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
						'name' => q(satuan panas Britania),
						'other' => q({0} satuan panas Britania),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(satuan panas Britania),
						'other' => q({0} satuan panas Britania),
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
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
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
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam per 100 kilometer),
						'other' => q({0} kilowatt-jam per 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam per 100 kilometer),
						'other' => q({0} kilowatt-jam per 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0} pound gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0} pound gaya),
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
						'name' => q(dot per sentimeter),
						'other' => q({0} dot per sentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dot per sentimeter),
						'other' => q({0} dot per sentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dot per inci),
						'other' => q({0} dot per inci),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dot per inci),
						'other' => q({0} dot per inci),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipografis),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipografis),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel per sentimeter),
						'other' => q({0} piksel per sentimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel per sentimeter),
						'other' => q({0} piksel per sentimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel per inci),
						'other' => q({0} piksel per inci),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel per inci),
						'other' => q({0} piksel per inci),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(satuan astronomi),
						'other' => q({0} satuan astronomi),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(satuan astronomi),
						'other' => q({0} satuan astronomi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} per sentimeter),
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
						'name' => q(jari-jari Bumi),
						'other' => q({0} jari-jari Bumi),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(jari-jari Bumi),
						'other' => q({0} jari-jari Bumi),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(depa),
						'other' => q({0} depa),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(depa),
						'other' => q({0} depa),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0} kaki),
						'per' => q({0} per kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0} kaki),
						'per' => q({0} per kaki),
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
						'per' => q({0} per inci),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} inci),
						'per' => q({0} per inci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
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
						'per' => q({0} per meter),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0} meter),
						'per' => q({0} per meter),
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
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil skandinavia),
						'other' => q({0} mil skandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil skandinavia),
						'other' => q({0} mil skandinavia),
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
						'name' => q(mil laut),
						'other' => q({0} mil laut),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mil laut),
						'other' => q({0} mil laut),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'other' => q({0} parsec),
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
						'other' => q({0} poin),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} poin),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} radius Matahari),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} radius Matahari),
					},
					# Long Unit Identifier
					'length-yard' => {
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
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
						'other' => q({0} luminositas matahari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} luminositas matahari),
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
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0} massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0} massa Bumi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
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
						'name' => q(ounce),
						'other' => q({0} ounce),
						'per' => q({0} per ounce),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ounce),
						'other' => q({0} ounce),
						'per' => q({0} per ounce),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} pound),
						'per' => q({0} per pound),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} pound),
						'per' => q({0} per pound),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0} massa Matahari),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0} massa Matahari),
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
						'name' => q(ton Amerika Serikat),
						'other' => q({0} ton Amerika Serikat),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton Amerika Serikat),
						'other' => q({0} ton Amerika Serikat),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
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
						'name' => q(daya kuda),
						'other' => q({0} daya kuda),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(daya kuda),
						'other' => q({0} daya kuda),
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
						'1' => q({0} kubik),
						'other' => q({0} kubik),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} kubik),
						'other' => q({0} kubik),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
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
						'name' => q(kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascal),
						'other' => q({0} megapascal),
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
						'name' => q(pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pound per inci persegi),
						'other' => q({0} pound per inci persegi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pound per inci persegi),
						'other' => q({0} pound per inci persegi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometer per jam),
						'other' => q({0} kilometer per jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer per jam),
						'other' => q({0} kilometer per jam),
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
					'speed-meter-per-second' => {
						'name' => q(meter per detik),
						'other' => q({0} meter per detik),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter per detik),
						'other' => q({0} meter per detik),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil per jam),
						'other' => q({0} mil per jam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil per jam),
						'other' => q({0} mil per jam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(derajat Celsius),
						'other' => q({0} derajat Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(derajat Celsius),
						'other' => q({0} derajat Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(derajat Fahrenheit),
						'other' => q({0} derajat Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(derajat Fahrenheit),
						'other' => q({0} derajat Fahrenheit),
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
						'name' => q(pound kaki),
						'other' => q({0} pound kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound kaki),
						'other' => q({0} pound kaki),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekar kaki),
						'other' => q({0} ekar kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekar kaki),
						'other' => q({0} ekar kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'other' => q({0} barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'other' => q({0} barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'other' => q({0} gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'other' => q({0} gantang),
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
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} per sentimeter kubik),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} per sentimeter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} per meter kubik),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} per meter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} cup),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} cup),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metric cup),
						'other' => q({0} metric cup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metric cup),
						'other' => q({0} metric cup),
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
						'name' => q(sendok dessert),
						'other' => q({0} sendok dessert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sendok dessert),
						'other' => q({0} sendok dessert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(sendok dessert Imp.),
						'other' => q({0} sendok dessert Imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(sendok dessert Imp.),
						'other' => q({0} sendok dessert Imp.),
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
						'name' => q(fluid ounce),
						'other' => q({0} fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fluid ounce),
						'other' => q({0} fluid ounce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} per galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} per galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galon Imp.),
						'other' => q({0} galon Imp.),
						'per' => q({0} per galon Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galon Imp.),
						'other' => q({0} galon Imp.),
						'per' => q({0} per galon Imp.),
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
					'volume-jigger' => {
						'name' => q(jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} liter),
						'per' => q({0} per liter),
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
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metric pint),
						'other' => q({0} metric pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metric pint),
						'other' => q({0} metric pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(quart Imp.),
						'other' => q({0} quart Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quart Imp.),
						'other' => q({0} quart Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sendok makan),
						'other' => q({0} sendok makan),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sendok makan),
						'other' => q({0} sendok makan),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/d²),
						'other' => q({0} m/d²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/d²),
						'other' => q({0} m/d²),
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
					'angle-radian' => {
						'name' => q(rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
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
						'name' => q(mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
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
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0} m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0} m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}T),
						'north' => q({0}U),
						'south' => q({0}S),
						'west' => q({0}B),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}T),
						'north' => q({0}U),
						'south' => q({0}S),
						'west' => q({0}B),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0}k),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0}k),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(mgg),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(mgg),
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
					'electric-milliampere' => {
						'name' => q(mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
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
					'length-fathom' => {
						'name' => q(depa),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(depa),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tc),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tc),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(p),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(p),
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
					'length-yard' => {
						'name' => q(yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
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
					'mass-dalton' => {
						'name' => q(Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'other' => q({0} gr),
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
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
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
					'speed-kilometer-per-hour' => {
						'other' => q({0}km/j),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q({0}km/j),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/dtk),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/dtk),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/j),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/j),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
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
						'other' => q({0} dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'other' => q({0} dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
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
					'volume-pint-metric' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp),
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
					'acceleration-meter-per-square-second' => {
						'name' => q(meter/dtk²),
						'other' => q({0} m/dtk²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter/dtk²),
						'other' => q({0} m/dtk²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mnt busur),
						'other' => q({0} mnt busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mnt busur),
						'other' => q({0} mnt busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(dtk busur),
						'other' => q({0} dtk busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(dtk busur),
						'other' => q({0} dtk busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derajat),
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
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekar),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektare),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektare),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki persegi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki persegi),
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
					'area-square-meter' => {
						'name' => q(meter²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meter²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil persegi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil persegi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
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
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(persen),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(persen),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagian/juta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagian/juta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
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
						'name' => q(mil/gal),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/gal Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} T),
						'north' => q({0} U),
						'south' => q({0} S),
						'west' => q({0} B),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} T),
						'north' => q({0} U),
						'south' => q({0} S),
						'west' => q({0} B),
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
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
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
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
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
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
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
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
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
						'other' => q({0} hr),
						'per' => q({0}/hr),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(hari),
						'other' => q({0} hr),
						'per' => q({0}/hr),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek),
						'other' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek),
						'other' => q({0} dek),
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
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
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
						'name' => q(nanodtk),
						'other' => q({0} ndtk),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} ndtk),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(krt),
						'other' => q({0} krt),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(krt),
						'other' => q({0} krt),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(minggu),
						'other' => q({0} mgg),
						'per' => q({0}/mgg),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(minggu),
						'other' => q({0} mgg),
						'per' => q({0}/mgg),
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
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
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
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
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
					'energy-kilowatt-hour' => {
						'name' => q(kW-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-jam),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therm AS),
						'other' => q({0} therm AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm AS),
						'other' => q({0} therm AS),
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
						'name' => q(pound gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound gaya),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dot),
						'other' => q({0} dot),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dot),
						'other' => q({0} dot),
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
					'graphics-megapixel' => {
						'name' => q(megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0} sa),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0} sa),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(dp),
						'other' => q({0} dp),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(dp),
						'other' => q({0} dp),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
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
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(thn cahaya),
						'other' => q({0} tc),
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
						'name' => q(mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radius Matahari),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radius Matahari),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
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
						'name' => q(luminositas matahari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositas matahari),
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
						'name' => q(massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massa Bumi),
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
						'name' => q(pound),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pound),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massa Matahari),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massa Matahari),
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
						'name' => q(ton AS),
						'other' => q({0} tn AS),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton AS),
						'other' => q({0} tn AS),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/j),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/j),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0} mpj),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0} mpj),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(gantang),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram cairan),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram cairan),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
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
					'volume-gallon-imperial' => {
						'name' => q(gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Imp.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(sloki),
						'other' => q({0} sloki),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(sloki),
						'other' => q({0} sloki),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(jumput),
						'other' => q({0} jumput),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(jumput),
						'other' => q({0} jumput),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sdm),
						'other' => q({0} sdm),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sdm),
						'other' => q({0} sdm),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sdt),
						'other' => q({0} sdt),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sdt),
						'other' => q({0} sdt),
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
				end => q({0}, dan {1}),
				2 => q({0} dan {1}),
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
			display_name => {
				'currency' => q(Peseta Andorra),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirham Uni Emirat Arab),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afgani Afganistan \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afgani Afganistan),
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
				'currency' => q(Guilder Antilla Belanda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kwanza Angola \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Kwanza Baru Angola \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza Angola yang Disesuaikan Lagi \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral Argentina),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Peso Ley Argentina \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Peso Argentina \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso Argentina \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentina),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Schilling Austria),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Dolar Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manat Azerbaijan \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dinar Bosnia-Herzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Konvertibel Bosnia-Herzegovina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Dinar Baru Bosnia-Herzegovina \(1994–1997\)),
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
		'BEC' => {
			display_name => {
				'currency' => q(Franc Belgia \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franc Belgia),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Franc Belgia \(keuangan\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Hard Lev Bulgaria),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Socialist Lev Bulgaria),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgaria),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev Bulgaria \(1879–1952\)),
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
				'currency' => q(Boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviano Bolivia \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso Bolivia),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol Bolivia),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro Baru Brasil \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado Brasil \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasil),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado Baru Brasil \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bahama),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat Burma),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Rubel Baru Belarus \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rubel Belarusia),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rubel Belarusia \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Kongo),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Euro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Swiss),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Franc WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Escudo Cile),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Satuan Hitung \(UF\) Cile),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Cile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Tiongkok \(luar negeri\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Tiongkok),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Kolombia),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unit Nilai Nyata Kolombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon Kosta Rika),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Dinar Serbia \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Hard Koruna Cheska),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Konvertibel Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Pound Siprus),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Ceko),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Mark Jerman Timur),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Mark Jerman),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Jibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Aljazair),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre Ekuador),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Satuan Nilai Tetap Ekuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kroon Estonia),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pound Mesir),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Peseta Spanyol \(akun\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Peseta Spanyol \(konvertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Peseta Spanyol),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Etiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Markka Finlandia),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pound Kepulauan Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franc Prancis),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound Inggris),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Kupon Larit Georgia),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi Ghana \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pound Gibraltar),
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
		'GNS' => {
			display_name => {
				'currency' => q(Syli Guinea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekuele Guinea Ekuatorial),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drachma Yunani),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Escudo Guinea Portugal),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso Guinea-Bissau),
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
		'HRD' => {
			display_name => {
				'currency' => q(Dinar Kroasia),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Kroasia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Hungaria),
			},
		},
		'IDR' => {
			symbol => 'Rp',
			display_name => {
				'currency' => q(Rupiah Indonesia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Pound Irlandia),
			},
		},
		'ILP' => {
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
			display_name => {
				'currency' => q(Shekel Baru Israel),
			},
		},
		'INR' => {
			symbol => 'Rs',
			display_name => {
				'currency' => q(Rupee India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Irak),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Krona Islandia \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Krona Islandia),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira Italia),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Yordania),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Jepang),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kirgizstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Kamboja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Korea Utara),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Hwan Korea Selatan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Won Korea Selatan \(1945–1953\)),
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
				'currency' => q(Pound Lebanon),
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
				'currency' => q(Litas Lituania),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Talonas Lituania),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Franc Konvertibel Luksemburg),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Franc Luksemburg),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Financial Franc Luksemburg),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats Latvia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rubel Latvia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Maroko),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Franc Maroko),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Franc Monegasque),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Cupon Moldova),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Madagaskar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Franc Malagasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Makedonia),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Denar Makedonia \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Franc Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Makau),
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
		'MTL' => {
			display_name => {
				'currency' => q(Lira Malta),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Pound Malta),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Mauritius),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rufiyaa Maladewa \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maladewa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Meksiko),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso Silver Meksiko \(1861–1992\)),
				'other' => q(Peso Perak Meksiko),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Unit Investasi Meksiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaysia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mozambik),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical Mozambik \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mozambik),
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
		'NIC' => {
			display_name => {
				'currency' => q(Cordoba Nikaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nikaragua),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Guilder Belanda),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Norwegia),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar Selandia Baru),
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
		'PEI' => {
			display_name => {
				'currency' => q(Inti Peru),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Peru),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol Peru \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Nugini),
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
				'currency' => q(Zloty Polandia),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloty Polandia \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Escudo Portugal),
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
		'ROL' => {
			display_name => {
				'currency' => q(Leu Rumania \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Rumania),
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
		'RUR' => {
			display_name => {
				'currency' => q(Rubel Rusia \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Arab Saudi),
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
		'SDD' => {
			display_name => {
				'currency' => q(Dinar Sudan \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pound Sudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pound Sudan \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Swedia),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pound Saint Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar Slovenia),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Koruna Slovakia),
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
				'currency' => q(Shilling Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Suriname),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Guilder Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pound Sudan Selatan),
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
		'SUR' => {
			display_name => {
				'currency' => q(Rubel Soviet),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colon El Savador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pound Suriah),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swaziland),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht Thailand),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Rubel Tajikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manat Turkmenistan \(1993–2009\)),
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
				'currency' => q(Paʻanga Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lira Turki \(1922–2005\)),
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
				'currency' => q(Dolar Baru Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukraina),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Karbovanet Ukraina),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Shilling Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolar Amerika Serikat),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dolar AS \(Hari berikutnya\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dolar AS \(Hari yang sama\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Peso Uruguay \(Unit Diindeks\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso Uruguay \(1975–1993\)),
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
		'VEB' => {
			display_name => {
				'currency' => q(Bolivar Venezuela \(1871–2008\)),
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
		'VNN' => {
			display_name => {
				'currency' => q(Dong Vietnam \(1978–1985\)),
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
				'currency' => q(Franc CFA Afrika Tengah),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Silver),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Emas),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Unit Gabungan Eropa),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Unit Keuangan Eropa),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Satuan Hitung Eropa \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Satuan Hitung Eropa \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Karibia Timur),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Hak Khusus Menggambar),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Satuan Mata Uang Eropa),
			},
		},
		'XFO' => {
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
			display_name => {
				'currency' => q(Franc CFA Afrika Barat),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinum),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(Dana RINET),
			},
		},
		'XTS' => {
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
			display_name => {
				'currency' => q(Dinar Yaman),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yaman),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Hard Dinar Yugoslavia \(1966–1990\)),
				'other' => q(Dinar Keras Yugoslavia),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Dinar Baru Yugoslavia \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinar Konvertibel Yugoslavia \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Dinar Reformasi Yugoslavia \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand Afrika Selatan \(Keuangan\)),
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
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire Baru Zaire \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire Zaire \(1971–1993\)),
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
							'Agu',
							'Sep',
							'Okt',
							'Nov',
							'Des'
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. Awal',
							'Rab. Akhir',
							'Jum. Awal',
							'Jum. Akhir',
							'Raj.',
							'Sya.',
							'Ram.',
							'Syaw.',
							'Zulka.',
							'Zulhi.'
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
							'Jumadilawal',
							'Jumadilakhir',
							'Rajab',
							'Syakban',
							'Ramadan',
							'Syawal',
							'Zulkaidah',
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
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'M'
					},
				},
			},
			'islamic' => {
				'format' => {
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1500;
					return 'evening1' if $time >= 1500
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 1000;
					return 'night1' if $time >= 1800
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
					'afternoon1' => q{siang},
					'evening1' => q{sore},
					'midnight' => q{tengah malam},
					'morning1' => q{pagi},
					'night1' => q{malam},
					'noon' => q{tengah hari},
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
				'0' => 'EB'
			},
			wide => {
				'0' => 'Era Buddhis'
			},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'SM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Sebelum Masehi',
				'1' => 'Masehi'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'SAKA'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'H'
			},
		},
		'japanese' => {
			abbreviated => {
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749-749)',
				'12' => 'Tempyō-shōhō (749-757)',
				'13' => 'Tempyō-hōji (757-765)',
				'14' => 'Temphō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'25' => 'Saiko (854–857)',
				'26' => 'Tennan (857–859)',
				'28' => 'Genkei (877–885)',
				'30' => 'Kampyō (889–898)',
				'34' => 'Shōhei (931–938)',
				'42' => 'Ten-en (973-976)',
				'47' => 'Ei-en (987-989)',
				'68' => 'Eiho (1081–1084)',
				'71' => 'Kaho (1094–1096)',
				'73' => 'Shōtoku (1097–1099)',
				'78' => 'Ten-ei (1110-1113)',
				'80' => 'Gen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'86' => 'Hoen (1135–1141)',
				'89' => 'Tenyō (1144–1145)',
				'93' => 'Hogen (1156–1159)',
				'99' => 'Nin-an (1166-1169)',
				'106' => 'Genryuku (1184–1185)',
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Shōgen (1207–1211)',
				'116' => 'Shōkyū (1219–1222)',
				'123' => 'Tempuku (1233–1234)',
				'127' => 'En-ō (1239-1240)',
				'135' => 'Bun-ō (1260-1261)',
				'137' => 'Bun-ei (1264-1275)',
				'146' => 'Enkei (1308–1311)',
				'151' => 'Genkyō (1321–1324)',
				'153' => 'Kareki (1326–1329)',
				'156' => 'Kemmu (1334–1336)',
				'174' => 'Bun-an (1444-1449)',
				'190' => 'Tenmon (1532–1555)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'206' => 'Tenwa (1681–1684)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Hōryaku (1751–1764)',
				'218' => 'An-ei (1772-1781)',
				'228' => 'Man-en (1860-1861)'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Sebelum R.O.C.'
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
		'dangi' => {
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
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
		},
		'indian' => {
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			Hmsv => q{HH.mm.ss v},
			Hmv => q{HH.mm v},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'minggu' 'ke'-W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss. a v},
			hmv => q{h.mm a v},
			ms => q{mm.ss},
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
			Hm => {
				H => q{HH.mm – HH.mm},
				m => q{HH.mm – HH.mm},
			},
			Hmv => {
				H => q{HH.mm – HH.mm v},
				m => q{HH.mm – HH.mm v},
			},
			M => {
				M => q{M – M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMd => {
				d => q{d – d MMM},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
			},
			hm => {
				h => q{h.mm – h.mm a},
				m => q{h.mm – h.mm a},
			},
			hmv => {
				h => q{h.mm – h.mm a v},
				m => q{h.mm – h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
			},
			yMMMd => {
				d => q{d – d MMM y G},
			},
		},
		'generic' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				B => q{h.mm B – h.mm B},
				h => q{h.mm – h.mm B},
				m => q{h.mm – h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
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
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH – HH},
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
				H => q{HH – HH v},
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
				h => q{h – h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				h => q{h – h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
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
				h => q{h – h B},
			},
			Bhm => {
				B => q{h.mm B – h.mm B},
				h => q{h.mm – h.mm B},
				m => q{h.mm – h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
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
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
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
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y – y},
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
		'islamic' => {
			Hm => {
				H => q{HH.mm – HH.mm},
				m => q{HH.mm – HH.mm},
			},
			Hmv => {
				H => q{HH.mm – HH.mm v},
				m => q{HH.mm – HH.mm v},
			},
			M => {
				M => q{M – M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMd => {
				d => q{d – d MMM},
			},
			d => {
				d => q{d – d},
			},
			hm => {
				h => q{h.mm – h.mm a},
				m => q{h.mm – h.mm a},
			},
			hmv => {
				h => q{h.mm – h.mm a v},
				m => q{h.mm – h.mm a v},
			},
			y => {
				y => q{y – y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
			},
			yMMMd => {
				d => q{d – d MMM y G},
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
					'abbreviated' => {
						0 => q(mulai musim semi),
						1 => q(air hujan),
						2 => q(serangga bangun),
						3 => q(ekuinoks musim semi),
						5 => q(hujan butiran),
						6 => q(mulai musim panas),
						12 => q(mulai musim gugur),
						13 => q(akhir panas),
						15 => q(ekuinoks musim gugur),
						16 => q(embun dingin),
						17 => q(embun beku turun),
						18 => q(mulai musim dingin),
						19 => q(mulai turun salju),
					},
				},
			},
		},
		'dangi' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						14 => q(embun putih),
					},
					'wide' => {
						14 => q(embun putih),
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
		regionFormat => q(Waktu {0}),
		regionFormat => q(Waktu Musim Panas {0}),
		regionFormat => q(Waktu Standar {0}),
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
		'Africa/Algiers' => {
			exemplarCity => q#Aljir#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
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
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
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
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad Juarez#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
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
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Waktu Musim Panas Tengah#,
				'generic' => q#Waktu Tengah#,
				'standard' => q#Waktu Standar Tengah#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Panas Timur#,
				'generic' => q#Waktu Timur#,
				'standard' => q#Waktu Standar Timur#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pegunungan#,
				'generic' => q#Waktu Pegunungan#,
				'standard' => q#Waktu Standar Pegunungan#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pasifik#,
				'generic' => q#Waktu Pasifik#,
				'standard' => q#Waktu Standar Pasifik#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Waktu Musim Panas Anadyr#,
				'generic' => q#Waktu Anadyr#,
				'standard' => q#Waktu Standar Anadyr#,
			},
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
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waktu Musim Panas Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Standar Atlantik#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Tanjung Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Selatan#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
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
			short => {
				'daylight' => q#CDT (Kuba)#,
				'generic' => q#CT (Kuba)#,
				'standard' => q#CST (Kuba)#,
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
			exemplarCity => q#Kota Tidak Dikenal#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kishinev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Waktu Standar Irlandia#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Pulau Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Waktu Musim Panas Inggris#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wina#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsawa#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizhia#,
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
			short => {
				'daylight' => q#EGDT#,
				'generic' => q#EGT#,
				'standard' => q#EGST#,
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
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
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
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maladewa#,
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
				'standard' => q#Waktu Kirgizstan#,
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
				'daylight' => q#Waktu Musim Panas Moskow#,
				'generic' => q#Waktu Moskow#,
				'standard' => q#Waktu Standar Moskow#,
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
			short => {
				'daylight' => q#NDT#,
				'generic' => q#NT#,
				'standard' => q#NST#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waktu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Waktu Musim Panas Pulau Norfolk#,
				'generic' => q#Waktu Pulau Norfolk#,
				'standard' => q#Waktu Standar Pulau Norfolk#,
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
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalkanal#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
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
			short => {
				'daylight' => q#PMDT#,
				'generic' => q#PMT#,
				'standard' => q#PMST#,
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
		'Yukon' => {
			long => {
				'standard' => q#Waktu Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
