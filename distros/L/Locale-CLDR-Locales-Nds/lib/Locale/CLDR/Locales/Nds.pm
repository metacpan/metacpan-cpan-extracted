=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nds - Package for language Low German

=cut

package Locale::CLDR::Locales::Nds;
# This file auto generated from Data\common\main\nds.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Afar',
 				'ab' => 'Abchaasch',
 				'ace' => 'Aceh',
 				'ach' => 'Acholi',
 				'ada' => 'Adangme',
 				'ady' => 'Adygeisch',
 				'ae' => 'Avestsch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadsch',
 				'ale' => 'Aleutsch',
 				'alt' => 'Süüd-Altaisch',
 				'am' => 'Amhaarsch',
 				'an' => 'Aragoneesch',
 				'ang' => 'Ooldengelsch',
 				'anp' => 'Angika',
 				'ar' => 'Araabsch',
 				'ar_001' => 'Standardaraabsch',
 				'arc' => 'Aramääsch',
 				'arn' => 'Araukaansch',
 				'arp' => 'Arapaho',
 				'arw' => 'Arawak-Spraken',
 				'as' => 'Assameesch',
 				'ast' => 'Asturiaansch',
 				'av' => 'Awaarsch',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschaansch',
 				'ba' => 'Baschkiersch',
 				'bal' => 'Belutschisch',
 				'ban' => 'Balineesch',
 				'bas' => 'Basaa',
 				'be' => 'Wittruss’sch',
 				'bej' => 'Bedscha',
 				'bem' => 'Bemba',
 				'bg' => 'Bulgaarsch',
 				'bho' => 'Bhodschpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengaalsch',
 				'bo' => 'Tibeetsch',
 				'br' => 'Bretoonsch',
 				'bra' => 'Braj-Bhakha',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnisch',
 				'bua' => 'Burjaatsch',
 				'bug' => 'Bugineesch',
 				'byn' => 'Blin',
 				'ca' => 'Katalaansch',
 				'cad' => 'Caddo',
 				'car' => 'Kariebsche Spraken',
 				'cch' => 'Atsam',
 				'ce' => 'Tschetscheensch',
 				'ceb' => 'Cebuano',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha-Spraken',
 				'chg' => 'Tschagataisch',
 				'chk' => 'Trukeesch',
 				'chm' => 'Mari',
 				'chn' => 'Chinook',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokeesch',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Zentraalkurdsch',
 				'co' => 'Koorssch',
 				'cop' => 'Koptsch',
 				'cr' => 'Cree',
 				'crh' => 'Krimtataarsch',
 				'cs' => 'Tschech’sch',
 				'csb' => 'Kaschuubsch',
 				'cu' => 'Karkenslaavsch',
 				'cv' => 'Tschuwasch’sch',
 				'cy' => 'Waliesch',
 				'da' => 'Däänsch',
 				'dak' => 'Dakota',
 				'dar' => 'Dargiensch',
 				'de' => 'Hoochdüütsch',
 				'de_AT' => 'Öösterrieksch Hoochdüütsch',
 				'de_CH' => 'Swiezer Hoochdüütsch',
 				'del' => 'Delaware',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'doi' => 'Dogri',
 				'dsb' => 'Neddersorbsch',
 				'dua' => 'Duala',
 				'dum' => 'Middelnedderlandsch',
 				'dv' => 'Maledievsch',
 				'dyu' => 'Dyula',
 				'dz' => 'Bhutaansch',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Ägyptsch',
 				'eka' => 'Ekajuk',
 				'el' => 'Greeksch',
 				'elx' => 'Elaamsch',
 				'en' => 'Engelsch',
 				'en_AU' => 'Austraalsch Engelsch',
 				'en_CA' => 'Kanaadsch Engelsch',
 				'en_GB' => 'Brietsch Engelsch',
 				'en_GB@alt=short' => 'Engelsch (GB)',
 				'en_US' => 'Amerikaansch Engelsch',
 				'en_US@alt=short' => 'Engelsch (US)',
 				'enm' => 'Middelengelsch',
 				'eo' => 'Esperanto',
 				'es' => 'Spaansch',
 				'es_419' => 'Latienamerikaansch Spaansch',
 				'es_ES' => 'Ibeersch Spaansch',
 				'es_MX' => 'Mexikaansch Spaansch',
 				'et' => 'Eestlannsch',
 				'eu' => 'Basksch',
 				'ewo' => 'Ewondo',
 				'fa' => 'Pers’sch',
 				'fan' => 'Pangwe',
 				'fat' => 'Fanti',
 				'ff' => 'Ful',
 				'fi' => 'Finnsch',
 				'fil' => 'Philippiensch',
 				'fj' => 'Fidschiaansch',
 				'fo' => 'Färöösch',
 				'fon' => 'Fon',
 				'fr' => 'Franzöösch',
 				'fr_CA' => 'Kanaadsch Franzöösch',
 				'fr_CH' => 'Swiezer Franzöösch',
 				'frm' => 'Middelfranzöösch',
 				'fro' => 'Ooldfranzöösch',
 				'frr' => 'Noordfreesch',
 				'frs' => 'Saterfreesch',
 				'fur' => 'Friuulsch',
 				'fy' => 'Westfreesch',
 				'ga' => 'Iersch',
 				'gaa' => 'Ga',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gd' => 'Schottsch Gäälsch',
 				'gez' => 'Geez',
 				'gil' => 'Gilberteesch',
 				'gl' => 'Galizsch',
 				'gmh' => 'Middelhoochdüütsch',
 				'gn' => 'Guarani',
 				'goh' => 'Ooldhoochdüütsch',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gootsch',
 				'grb' => 'Grebo',
 				'grc' => 'Ooldgreeksch',
 				'gsw' => 'Swiezerdüütsch',
 				'gu' => 'Gudscharati',
 				'gv' => 'Manx',
 				'gwi' => 'Kutchin',
 				'ha' => 'Haussa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaiiaansch',
 				'he' => 'Hebrääsch',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hethitsch',
 				'hmn' => 'Miao-Spraken',
 				'ho' => 'Hiri-Motu',
 				'hr' => 'Kroaatsch',
 				'hsb' => 'Böversorbsch',
 				'ht' => 'Haitiaansch',
 				'hu' => 'Ungaarsch',
 				'hup' => 'Hupa',
 				'hy' => 'Armeensch',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'id' => 'Indoneesch',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'Inupiak',
 				'ilo' => 'Ilokano',
 				'inh' => 'Ingusch’sch',
 				'io' => 'Ido',
 				'is' => 'Ieslannsch',
 				'it' => 'Italieensch',
 				'iu' => 'Inuktitut',
 				'ja' => 'Japaansch',
 				'jbo' => 'Lojban',
 				'jpr' => 'Jöödsch-Pers’sch',
 				'jrb' => 'Jöödsch-Araabsch',
 				'jv' => 'Javaansch',
 				'ka' => 'Georgsch',
 				'kaa' => 'Karakalpaksch',
 				'kab' => 'Kabyylsch',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardiensch',
 				'kcg' => 'Tyap',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kha' => 'Khasi',
 				'kho' => 'Saaksch',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kwanyama',
 				'kk' => 'Kasach’sch',
 				'kl' => 'Gröönlannsch',
 				'km' => 'Kambodschaansch',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaansch',
 				'koi' => 'Komipermjaksch',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeaansch',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuursch',
 				'krc' => 'Karatschaisch-Balkaarsch',
 				'krl' => 'Kareelsch',
 				'kru' => 'Oraon',
 				'ks' => 'Kaschmiersch',
 				'ku' => 'Kurdsch',
 				'kum' => 'Kumücksch',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Koornsch',
 				'ky' => 'Kirgiesch',
 				'la' => 'Latiensch',
 				'lad' => 'Ladiensch',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luxemborgsch',
 				'lez' => 'Lesgisch',
 				'lg' => 'Luganda',
 				'li' => 'Limborgsch',
 				'ln' => 'Lingala',
 				'lo' => 'Laootsch',
 				'lol' => 'Mongo',
 				'loz' => 'Rotse',
 				'lt' => 'Litausch',
 				'lu' => 'Luba',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Lushai',
 				'lv' => 'Lettsch',
 				'mad' => 'Madureesch',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makassarsch',
 				'man' => 'Manding',
 				'mas' => 'Massai',
 				'mdf' => 'Mokscha',
 				'mdr' => 'Mandareesch',
 				'men' => 'Mende',
 				'mg' => 'Madagassisch',
 				'mga' => 'Middeliersch',
 				'mh' => 'Marschalleesch',
 				'mi' => 'Maori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Mazedoonsch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoolsch',
 				'mnc' => 'Mandschuursch',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Malaisch',
 				'mt' => 'Malteesch',
 				'mul' => 'Mehrsprakig',
 				'mus' => 'Muskogee-Spraken',
 				'mwl' => 'Mirandeesch',
 				'mwr' => 'Marwari',
 				'my' => 'Birmaansch',
 				'myv' => 'Erzya',
 				'na' => 'Nauruusch',
 				'nap' => 'Neapolitaansch',
 				'nb' => 'Norweegsch Bokmål',
 				'nd' => 'Noord-Ndebele',
 				'nds' => 'Neddersass’sch',
 				'ne' => 'Nepaleesch',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niue',
 				'nl' => 'Nedderlandsch',
 				'nl_BE' => 'Fläämsch',
 				'nn' => 'Norweegsch Nynorsk',
 				'no' => 'Norweegsch',
 				'nog' => 'Nogai',
 				'non' => 'Ooldnoorsch',
 				'nqo' => 'N’Ko',
 				'nr' => 'Süüd-Ndebele',
 				'nso' => 'Noord-Sotho',
 				'nv' => 'Navajo',
 				'nwc' => 'Oold-Newari',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Okzitaansch',
 				'oj' => 'Ojibwa',
 				'om' => 'Oromo',
 				'or' => 'Orija',
 				'os' => 'Ossetsch',
 				'osa' => 'Osage',
 				'ota' => 'Osmaansch',
 				'pa' => 'Pandschaabsch',
 				'pag' => 'Pangasinan',
 				'pal' => 'Middelpers’sch',
 				'pam' => 'Pampanggan',
 				'pap' => 'Papiamento',
 				'pau' => 'Palausch',
 				'peo' => 'Ooldpers’sch',
 				'phn' => 'Phönieksch',
 				'pi' => 'Pali',
 				'pl' => 'Poolsch',
 				'pon' => 'Ponapeaansch',
 				'pro' => 'Ooldprovenzaalsch',
 				'ps' => 'Paschtu',
 				'pt' => 'Portugeesch',
 				'pt_BR' => 'Brasiliaansch Portugeesch',
 				'pt_PT' => 'Ibeersch Portugeesch',
 				'qu' => 'Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Oosterinsel-Spraak',
 				'rar' => 'Rarotongaansch',
 				'rm' => 'Rätoromaansch',
 				'rn' => 'Rundi',
 				'ro' => 'Rumäänsch',
 				'ro_MD' => 'Moldaawsch',
 				'rom' => 'Romani',
 				'ru' => 'Russ’sch',
 				'rup' => 'Aromuunsch',
 				'rw' => 'Ruandsch',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Jakuutsch',
 				'sam' => 'Samaritaansch',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'sc' => 'Sardsch',
 				'scn' => 'Siziliaansch',
 				'sco' => 'Schottsch',
 				'sd' => 'Sindhi',
 				'se' => 'Noord-Saamsch',
 				'sel' => 'Selkupsch',
 				'sg' => 'Sango',
 				'sga' => 'Oold-Iersch',
 				'shn' => 'Schan',
 				'si' => 'Singhaleesch',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowaaksch',
 				'sl' => 'Sloweensch',
 				'sm' => 'Samoaansch',
 				'sma' => 'Süüd-Lappsch',
 				'smj' => 'Lule-Lappsch',
 				'smn' => 'Inari-Lappsch',
 				'sms' => 'Skolt-Lappsch',
 				'sn' => 'Schona',
 				'snk' => 'Soninke',
 				'so' => 'Somaalsch',
 				'sog' => 'Sogdisch',
 				'sq' => 'Albaansch',
 				'sr' => 'Serbsch',
 				'srn' => 'Surinaamsch',
 				'srr' => 'Serer',
 				'ss' => 'Swazi',
 				'st' => 'Süüd-Sotho',
 				'su' => 'Sundaneesch',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Sumersch',
 				'sv' => 'Sweedsch',
 				'sw' => 'Suaheli',
 				'syc' => 'Oold-Syyrsch',
 				'syr' => 'Syyrsch',
 				'ta' => 'Tamilsch',
 				'te' => 'Telugu',
 				'tem' => 'Temne',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Tadschiksch',
 				'th' => 'Thailannsch',
 				'ti' => 'Tigrinja',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmeensch',
 				'tkl' => 'Tokelausch',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingoonsch',
 				'tli' => 'Tlingit',
 				'tmh' => 'Tamaschek',
 				'tn' => 'Tswana',
 				'to' => 'Tongaasch',
 				'tog' => 'Tonga (Nyasa)',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Törksch',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tataarsch',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Elliceaansch',
 				'tw' => 'Twi',
 				'ty' => 'Tahitsch',
 				'tyv' => 'Tuwinsch',
 				'udm' => 'Udmurtsch',
 				'ug' => 'Uiguursch',
 				'uga' => 'Ugaritsch',
 				'uk' => 'Ukrainsch',
 				'umb' => 'Mbundu',
 				'und' => 'Nich begäng Spraak',
 				'ur' => 'Urdu',
 				'uz' => 'Usbeeksch',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Vietnameesch',
 				'vo' => 'Volapük',
 				'vot' => 'Wootsch',
 				'wa' => 'Walloonsch',
 				'wal' => 'Walamo',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wo' => 'Wolof',
 				'xal' => 'Kalmücksch',
 				'xh' => 'Xhosa',
 				'yao' => 'Yao',
 				'yap' => 'Yapeesch',
 				'yi' => 'Jiddisch',
 				'yo' => 'Yoruba',
 				'za' => 'Zhuang',
 				'zap' => 'Zapoteeksch',
 				'zbl' => 'Bliss-Symbolen',
 				'zen' => 'Zenaga',
 				'zh' => 'Chineesch',
 				'zh_Hans' => 'Vereenfacht Chineesch',
 				'zh_Hant' => 'Traditschonell Chineesch',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Keen Spraakinhold',
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
			'Arab' => 'Araabsch',
 			'Armi' => 'Rieksaramääsch',
 			'Armn' => 'Armeensch',
 			'Avst' => 'Avestsch',
 			'Bali' => 'Balineesch',
 			'Batk' => 'Bataksch',
 			'Beng' => 'Bengaalsch',
 			'Blis' => 'Bliss-Symbolen',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Blinnenschrift',
 			'Bugi' => 'Bugineesch',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Vereenheidlicht Kanaadsch Sülvenschrift',
 			'Cari' => 'Kaarsch',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptsch',
 			'Cprt' => 'Zypriootsch',
 			'Cyrl' => 'Kyrillsch',
 			'Cyrs' => 'Ooldkarkenslaavsch',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Egyd' => 'Demootsch',
 			'Egyh' => 'Hieraatsch',
 			'Egyp' => 'Ägyptsche Hieroglyphen',
 			'Ethi' => 'Äthioopsch',
 			'Geok' => 'Khutsuri',
 			'Geor' => 'Georgsch',
 			'Glag' => 'Glagolietsch',
 			'Goth' => 'Gootsch',
 			'Grek' => 'Greeksch',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hang' => 'Hangul',
 			'Hani' => 'Chineesch',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Vereenfacht',
 			'Hans@alt=stand-alone' => 'Vereenfacht Chineesch',
 			'Hant' => 'Traditschonell',
 			'Hant@alt=stand-alone' => 'Traditschonell Chineesch',
 			'Hebr' => 'Hebrääsch',
 			'Hira' => 'Hiragana',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana oder Hiragana',
 			'Hung' => 'Ooldungaarsch',
 			'Inds' => 'Indus',
 			'Ital' => 'Oolditaalsch',
 			'Java' => 'Javaneesch',
 			'Jpan' => 'Japaansch',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreaansch',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laootsch',
 			'Latf' => 'Latiensch (Fraktur)',
 			'Latg' => 'Latiensch (Gäälsch)',
 			'Latn' => 'Latiensch',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lyci' => 'Lyyksch',
 			'Lydi' => 'Lyydsch',
 			'Mand' => 'Mandääsch',
 			'Mani' => 'Manichääsch',
 			'Maya' => 'Maya-Hieroglyphen',
 			'Mero' => 'Meroitsch',
 			'Mlym' => 'Malaysch',
 			'Mong' => 'Mongoolsch',
 			'Moon' => 'Moon',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Birmaansch',
 			'Nkoo' => 'N’Ko',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orchon-Runen',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmaansch',
 			'Perm' => 'Ooldpermsch',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inschriften-Pahlavi',
 			'Phlp' => 'Psalter-Pahlavi',
 			'Phlv' => 'Book-Pahlavi',
 			'Phnx' => 'Phönieksch',
 			'Plrd' => 'Pollard-Phönieksch',
 			'Prti' => 'Inschriften-Parthsch',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runenschrift',
 			'Samr' => 'Samarietsch',
 			'Sara' => 'Sarati',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shaw-Alphabet',
 			'Sinh' => 'Singhaleesch',
 			'Sund' => 'Sundaneesch',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syyrsch',
 			'Syre' => 'Estrangelo-Syyrsch',
 			'Syrj' => 'West-Syyrsch',
 			'Syrn' => 'Oost-Syyrsch',
 			'Tagb' => 'Tagbanwa',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue',
 			'Taml' => 'Tamilsch',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibeetsch',
 			'Ugar' => 'Ugarietsch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Visible Speech',
 			'Xpeo' => 'Ooldpers’sch',
 			'Xsux' => 'Sumeroakkadsch Kielschrift',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Arvt Schriftweert',
 			'Zmth' => 'Mathemaatsch Teken',
 			'Zsym' => 'Symbolen',
 			'Zxxx' => 'Nich schreven',
 			'Zyyy' => 'Unbestimmt',
 			'Zzzz' => 'Nich begäng Schrift',

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
			'001' => 'Welt',
 			'002' => 'Afrika',
 			'003' => 'Noordamerika',
 			'005' => 'Süüdamerika',
 			'009' => 'Ozeanien',
 			'011' => 'Westafrika',
 			'013' => 'Middelamerika',
 			'014' => 'Oostafrika',
 			'015' => 'Noordafrika',
 			'017' => 'Zentralafrika',
 			'018' => 'Süüdlich Afrika',
 			'019' => 'Amerika',
 			'029' => 'Karibik',
 			'030' => 'Oostasien',
 			'034' => 'Süüdasien',
 			'035' => 'Süüdoostasien',
 			'039' => 'Süüdeuropa',
 			'053' => 'Australien un Neeseeland',
 			'054' => 'Melanesien',
 			'061' => 'Polynesien',
 			'142' => 'Asien',
 			'143' => 'Zentralasien',
 			'145' => 'Westasien',
 			'150' => 'Europa',
 			'151' => 'Oosteuropa',
 			'154' => 'Noordeuropa',
 			'155' => 'Westeuropa',
 			'419' => 'Latienamerika',
 			'AD' => 'Andorra',
 			'AE' => 'Vereenigte Araabsche Emiraten',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua un Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanien',
 			'AM' => 'Armenien',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinien',
 			'AS' => 'Amerikaansch-Samoa',
 			'AT' => 'Öösterriek',
 			'AU' => 'Australien',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandeilannen',
 			'AZ' => 'Aserbaidschan',
 			'BA' => 'Bosnien un Herzegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belgien',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarien',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei Darussalam',
 			'BO' => 'Bolivien',
 			'BR' => 'Brasilien',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet-Eiland',
 			'BW' => 'Botswana',
 			'BY' => 'Wittrussland',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos-Eilannen',
 			'CD' => 'Demokraatsche Republik Kongo',
 			'CF' => 'Zentralafrikaansche Republik',
 			'CG' => 'Republik Kongo',
 			'CH' => 'Swiez',
 			'CI' => 'Elfenbeenküst',
 			'CK' => 'Cook-Eilannen',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbien',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CX' => 'Wiehnachtseiland',
 			'CY' => 'Zypern',
 			'CZ' => 'Tschechien',
 			'DE' => 'Düütschland',
 			'DJ' => 'Dschibuti',
 			'DK' => 'Däänmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaansche Republik',
 			'DZ' => 'Algerien',
 			'EC' => 'Ecuador',
 			'EE' => 'Eestland',
 			'EG' => 'Ägypten',
 			'EH' => 'Westsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanien',
 			'ET' => 'Äthiopien',
 			'EU' => 'Europääsche Union',
 			'FI' => 'Finnland',
 			'FJ' => 'Fidschi',
 			'FK' => 'Falkland-Eilannen',
 			'FM' => 'Mikronesien',
 			'FO' => 'Färöer',
 			'FR' => 'Frankriek',
 			'GA' => 'Gabun',
 			'GB' => 'Grootbritannien',
 			'GD' => 'Grenada',
 			'GE' => 'Georgien',
 			'GF' => 'Franzöösch-Guayana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Gröönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Äquatorialguinea',
 			'GR' => 'Grekenland',
 			'GS' => 'Süüdgeorgien un de Südlichen Sandwich-Eilannen',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Sünnerverwaltensrebeet Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard- un McDonald-Eilannen',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'ID' => 'Indonesien',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Insel Man',
 			'IN' => 'Indien',
 			'IO' => 'Britisch Rebeed in’n Indischen Ozean',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Iesland',
 			'IT' => 'Italien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordanien',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoren',
 			'KN' => 'St. Kitts un Nevis',
 			'KP' => 'Noordkorea',
 			'KR' => 'Söödkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Kaiman-Eilannen',
 			'KZ' => 'Kasachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtensteen',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxemborg',
 			'LV' => 'Lettland',
 			'LY' => 'Libyen',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldawien',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall-Eilannen',
 			'MK' => 'Makedonien',
 			'ML' => 'Mali',
 			'MM' => 'Birma',
 			'MN' => 'Mongolei',
 			'MO' => 'Sünnerverwaltensrebeed Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nöördliche Marianen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediven',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Neekaledonien',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nedderlannen',
 			'NO' => 'Norwegen',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neeseeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Franzöösch-Polynesien',
 			'PG' => 'Papua-Neeguinea',
 			'PH' => 'Philippinen',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'St. Pierre un Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palästinensische Rebeden',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Büter Ozeanien',
 			'RE' => 'Reunion',
 			'RO' => 'Rumänien',
 			'RS' => 'Serbien',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabien',
 			'SB' => 'Salomonen',
 			'SC' => 'Seychellen',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Slowenien',
 			'SJ' => 'Svalbard un Jan Mayen',
 			'SK' => 'Slowakei',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'ST' => 'São Tomé un Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Syrien',
 			'SZ' => 'Swasiland',
 			'TC' => 'Turks- un Caicosinseln',
 			'TD' => 'Tschad',
 			'TF' => 'Franzöösche Süüd- un Antarktisrebeden',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadschikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Oosttimor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesien',
 			'TO' => 'Tonga',
 			'TR' => 'Törkei',
 			'TT' => 'Trinidad un Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikaansch-Ozeanien',
 			'US' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'St. Vincent un de Grenadinen',
 			'VE' => 'Venezuela',
 			'VG' => 'Brietsche Jumfern-Eilannen',
 			'VI' => 'Amerikaansche Jumfern-Eilannen',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis un Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Söödafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Nich begäng Regioon',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Ole düütsche Rechtschrievung',
 			'1994' => 'Standardiseert Resiaansch Rechtschrievung',
 			'1996' => 'Ne’e düütsche Rechtschrievung',
 			'1606NICT' => 'Laat Middelfranzöösch bet 1606',
 			'1694ACAD' => 'Fröh Neefranzöösch',
 			'AREVELA' => 'Oostarmeensch',
 			'AREVMDA' => 'Westarmeensch',
 			'BAKU1926' => 'Vereenheitlicht Törksch Latienalphabet',
 			'BISKE' => 'San Giorgio-/Bila-Dialekt',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'Phoneetsch (IPA)',
 			'FONUPA' => 'Phoneetsch (UPA)',
 			'LIPAW' => 'Lipovaz-Dialekt vun dat Resiaansche',
 			'MONOTON' => 'Monotoonsch',
 			'NEDIS' => 'Natisone-Dialekt',
 			'NJIVA' => 'Gniva-/Njiva-Dialekt',
 			'OSOJS' => 'Oseacco-/Osojane-Dialekt',
 			'POLYTON' => 'Polytoonsch',
 			'POSIX' => 'Computer',
 			'REVISED' => 'Överarbeidt Rechtschrievung',
 			'ROZAJ' => 'Resiaansch',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schottsch Standard-Engelsch',
 			'SCOUSE' => 'Scouse',
 			'SOLBA' => 'Stolvizza-/Solbica-Dialekt',
 			'TARASK' => 'Taraskievica-Rechtschrievung',
 			'VALENCIA' => 'Valenziaansch',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Klenner',
 			'collation' => 'Bookstaven-Folgreeg',
 			'currency' => 'Geldteken',
 			'numbers' => 'Tallen',

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
 				'buddhist' => q{Buddhistisch Klenner},
 				'chinese' => q{Chineesch Klenner},
 				'gregorian' => q{Gregoriaansch Klenner},
 				'hebrew' => q{Hebrääsch Klenner},
 				'indian' => q{Indsch Nationalklenner},
 				'islamic' => q{Islaamsch Klenner},
 				'islamic-civil' => q{Islaamsch Zivilklenner},
 				'iso8601' => q{ISO-8601-Klenner},
 				'japanese' => q{Japaansch Klenner},
 				'roc' => q{Klenner vun de Republik China},
 			},
 			'collation' => {
 				'big5han' => q{Traditschonell Chineesch Sorteerregeln - Big5},
 				'gb2312han' => q{Vereenfacht Chineesch Sorteerregeln - GB2312},
 				'phonebook' => q{Telefonbook-Sorteerregeln},
 				'pinyin' => q{Pinyin-Sorteerregeln},
 				'standard' => q{Standard-Sorteerreeg},
 				'stroke' => q{Streekfolg},
 				'traditional' => q{Traditschonelle Sorteerregeln},
 			},
 			'numbers' => {
 				'latn' => q{Araabsch Tallen},
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
			'metric' => q{Metersch},
 			'UK' => q{Engelsch},
 			'US' => q{US-amerikaansch},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Spraak: {0}',
 			'script' => 'Schrift: {0}',
 			'region' => 'Regioon: {0}',

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
			auxiliary => qr{[áàăâā æ ç éèĕêëęē íìĭîïī ñ óòŏôøō œ úùŭûū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'ẞ', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aåä b c d e f g h i j k l m n oö p q r s t uü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'ẞ', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h.mm',
				hms => 'h.mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Daag),
						'other' => q({0} Daag),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Daag),
						'other' => q({0} Daag),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Stünnen),
						'other' => q({0} Stünnen),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Stünnen),
						'other' => q({0} Stünnen),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Millisekunnen),
						'other' => q({0} Millisekunnen),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Millisekunnen),
						'other' => q({0} Millisekunnen),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Minuten),
						'other' => q({0} Minuten),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Minuten),
						'other' => q({0} Minuten),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Maanden),
						'other' => q({0} Maanden),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Maanden),
						'other' => q({0} Maanden),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sekunnen),
						'other' => q({0} Sekunnen),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sekunnen),
						'other' => q({0} Sekunnen),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Weken),
						'other' => q({0} Weken),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Weken),
						'other' => q({0} Weken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Johr),
						'other' => q({0} Johren),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Johr),
						'other' => q({0} Johren),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Zentimeters),
						'other' => q({0} Zentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Zentimeters),
						'other' => q({0} Zentimeter),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kilometers),
						'other' => q({0} Kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kilometers),
						'other' => q({0} Kilometer),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Meters),
						'other' => q({0} Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Meters),
						'other' => q({0} Meter),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(Millimeters),
						'other' => q({0} Millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(Millimeters),
						'other' => q({0} Millimeter),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(Kilogramm),
						'other' => q({0} Kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(Kilogramm),
						'other' => q({0} Kilogramm),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(Kilometers per Stünn),
						'other' => q({0} Kilometer per Stünn),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(Kilometers per Stünn),
						'other' => q({0} Kilometer per Stünn),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Graad Celsius),
						'other' => q({0} Graad Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Graad Celsius),
						'other' => q({0} Graad Celsius),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Liters),
						'other' => q({0} Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Liters),
						'other' => q({0} Liter),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'other' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'other' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(M.),
						'other' => q({0}M.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(M.),
						'other' => q({0}M.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(W.),
						'other' => q({0}W.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(W.),
						'other' => q({0}W.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'other' => q({0}a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'other' => q({0}a),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'other' => q({0}l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dg.),
						'other' => q({0} Dg.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dg.),
						'other' => q({0} Dg.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Stn.),
						'other' => q({0} Stn.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Stn.),
						'other' => q({0} Stn.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Min.),
						'other' => q({0} Min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Min.),
						'other' => q({0} Min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mnd.),
						'other' => q({0} Mnd.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mnd.),
						'other' => q({0} Mnd.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sek.),
						'other' => q({0} Sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sek.),
						'other' => q({0} Sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wk.),
						'other' => q({0} Wk.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wk.),
						'other' => q({0} Wk.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(J.),
						'other' => q({0} J.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(J.),
						'other' => q({0} J.),
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
					'mass-gram' => {
						'name' => q(Gramm),
						'other' => q({0} Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gramm),
						'other' => q({0} Gramm),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°Cels.),
						'other' => q({0}°Cels.),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°Cels.),
						'other' => q({0}°Cels.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(L),
						'other' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(L),
						'other' => q({0} L),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|j|yes|y)$' }
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
				end => q({0} un {1}),
				2 => q({0} un {1}),
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
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Austraalsch Dollar),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasiliaansch Real),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanaadsch Dollar),
				'other' => q(Kanada-Dollar),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiezer Franken),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chineesch Yuan),
				'other' => q(Renminbi),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Däänsch Kroon),
				'other' => q(Däänsch Kronen),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britsch Pund Sterling),
				'other' => q(Engelsch Pund),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-Dollar),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indoneesch Rupje),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indsch Rupje),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japaansch Yen),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Söödkoreansch Won),
				'other' => q(Koreaansch Won),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexikaansch Peso),
				'other' => q(Mexiko-Peso),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norweegsch Kroon),
				'other' => q(Norweegsch Kronen),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poolsch Zloty),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russ’sch Ruvel),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudsch Rial),
				'other' => q(Saudiaraabsch Rial),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweedsch Kroon),
				'other' => q(Sweedsch Kronen),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thailannsch Baht),
				'other' => q(Thai-Baht),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Törksch Lira),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nieg Taiwan-Dollar),
				'other' => q(Taiwan-Dollar),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
				'other' => q(Dollar),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nich begäng Geldsoort),
				'other' => q(\(nich begäng Geldsoort\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Söödafrikaansch Rand),
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
							'März',
							'Apr.',
							'Mai',
							'Juni',
							'Juli',
							'Aug.',
							'Sep.',
							'Okt.',
							'Nov.',
							'Dez.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januaar',
							'Februaar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktover',
							'November',
							'Dezember'
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
						wed => 'Mi.',
						thu => 'Du.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'Sü.'
					},
					wide => {
						mon => 'Maandag',
						tue => 'Dingsdag',
						wed => 'Middeweken',
						thu => 'Dunnersdag',
						fri => 'Freedag',
						sat => 'Sünnavend',
						sun => 'Sünndag'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'M',
						thu => 'D',
						fri => 'F',
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
					abbreviated => {0 => 'Q.1',
						1 => 'Q.2',
						2 => 'Q.3',
						3 => 'Q.4'
					},
					wide => {0 => '1. Quartaal',
						1 => '2. Quartaal',
						2 => '3. Quartaal',
						3 => '4. Quartaal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q. I',
						1 => 'Q. II',
						2 => 'Q. III',
						3 => 'Q. IV'
					},
					narrow => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					'am' => q{vm},
					'pm' => q{nm},
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
				'0' => 'v.Chr.',
				'1' => 'n.Chr.'
			},
			narrow => {
				'0' => 'vC',
				'1' => 'nC'
			},
			wide => {
				'0' => 'vör Christus',
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
			'full' => q{EEEE, 'de' d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, 'de' d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{d.MM.yy},
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
			'full' => q{'Klock' H.mm:ss (zzzz)},
			'long' => q{'Klock' H.mm:ss (z)},
			'medium' => q{'Klock' H.mm:ss},
			'short' => q{'Kl'. H.mm},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			MEd => q{E, d. M.},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, 'Kl'. HH.mm},
			EHms => q{E, 'Kl'. HH.mm:ss},
			Ed => q{E d.},
			Ehm => q{E, 'Kl'. h.mm a},
			Ehms => q{E, 'Kl'. h.mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{'Klock' H},
			Hm => q{'Kl'. H.mm},
			Hms => q{'Klock' H.mm:ss},
			Hmsv => q{'Klock' H.mm:ss v},
			MEd => q{E, d. M.},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
			h => q{'Klock' h a},
			hm => q{'Kl'. h.mm a},
			hms => q{'Klock' h.mm:ss a},
			hmsv => q{'Klock' h.mm:ss a v},
			ms => q{m:ss},
			yM => q{MM/y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} ({1})',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
			},
			d => {
				d => q{d.–d.},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM–MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y GGGGG},
				d => q{E, d. – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y GGGGG},
				d => q{d.–d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{'Kl'. H – H},
			},
			Hm => {
				H => q{'Kl'. H.mm – H.mm},
				m => q{'Kl'. H.mm – H.mm},
			},
			Hmv => {
				H => q{'Kl'. H.mm – H.mm (v)},
				m => q{'Kl'. H.mm – H.mm (v)},
			},
			Hv => {
				H => q{'Kl'. H – H (v)},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
			},
			d => {
				d => q{d.–d.},
			},
			h => {
				a => q{'Kl'. h a – h a},
				h => q{'Kl'. h – h a},
			},
			hm => {
				a => q{'Kl'. h.mm a – 'Kl'. h.mm a},
				h => q{'Kl'. h.mm – h.mm a},
				m => q{'Kl'. h.mm – h.mm a},
			},
			hmv => {
				a => q{'Kl'. h.mm – h.mm a (v)},
				h => q{'Kl'. h.mm – h.mm a (v)},
				m => q{'Kl'. h.mm – h.mm a (v)},
			},
			hv => {
				a => q{'Kl'. h a – h a (v)},
				h => q{'Kl'. h – h a (v)},
			},
			yM => {
				M => q{MM–MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y},
				d => q{E, d. – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d.M.–d.M.y},
				d => q{d.–d.M.y},
				y => q{d.M.y – d.M.y},
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
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q({0}-Tiet),
		regionFormat => q({0}-Summertiet),
		regionFormat => q({0}-Standardtiet),
		'Africa_Central' => {
			long => {
				'standard' => q#Zentraalafrikaansch Tiet#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oostafrikaansch Tiet#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Söödafrikaansch Tiet#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Westafrikaansch Summertiet#,
				'generic' => q#Westafrikaansch Tiet#,
				'standard' => q#Westafrikaansch Standardtiet#,
			},
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-Stadt#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Noord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Noord-Dakota#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Noordamerikaansch zentraal Summertiet#,
				'generic' => q#Noordamerikaansch Zentraaltiet#,
				'standard' => q#Noordamerikaansch zentraal Standardtiet#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Noordamerikaansch oosten Summertiet#,
				'generic' => q#Noordamerikaansch oosten Tiet#,
				'standard' => q#Noordamerikaansch oosten Standardtiet#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Noordamerikaansch Barg-Summertiet#,
				'generic' => q#Noordamerikaansch Bargtiet#,
				'standard' => q#Noordamerikaansch Barg-Standardtiet#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Noordamerikaansch Pazifik-Summertiet#,
				'generic' => q#Noordamerikaansch Pazifiktiet#,
				'standard' => q#Noordamerikaansch Pazifik-Standardtiet#,
			},
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Arabian' => {
			long => {
				'daylight' => q#Araabsch Summertiet#,
				'generic' => q#Araabsch Tiet#,
				'standard' => q#Araabsch Standardtiet#,
			},
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamschatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbator#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinborg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Noordamerikaansch Atlantik-Summertiet#,
				'generic' => q#Noordamerikaansch Atlantiktiet#,
				'standard' => q#Noordamerikaansch Atlantik-Standardtiet#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaren#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Zentraalaustraalsch Summertiet#,
				'generic' => q#Zentraalaustraalsch Tiet#,
				'standard' => q#Zentraalaustraalsch Standardtiet#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Westzentraalaustraalsch Summertiet#,
				'generic' => q#Westzentraalaustraalsch Tiet#,
				'standard' => q#Westzentraalaustraalsch Standardtiet#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oostaustraalsch Summertiet#,
				'generic' => q#Oostaustraalsch Tiet#,
				'standard' => q#Oostaustraalsch Standardtiet#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Westaustraalsch Summertiet#,
				'generic' => q#Westaustraalsch Tiet#,
				'standard' => q#Westaustraalsch Standardtiet#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China-Summertiet#,
				'generic' => q#China-Tiet#,
				'standard' => q#China-Standardtiet#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Nich begäng#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Zentraaleuropääsch Summertiet#,
				'generic' => q#Zentraaleuropääsch Tiet#,
				'standard' => q#Zentraaleuropääsch Standardtiet#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oosteuropääsch Summertiet#,
				'generic' => q#Oosteuropääsch Tiet#,
				'standard' => q#Oosteuropääsch Standardtiet#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Westeuropääsch Summertiet#,
				'generic' => q#Westeuropääsch Tiet#,
				'standard' => q#Westeuropääsch Standardtiet#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Gröönwisch-Welttiet#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indien-Tiet#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Söödoostasiaatsch Tiet#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Indoneesch Zentraaltiet#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oostindoneesch Tiet#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Westindoneesch Tiet#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel-Summertiet#,
				'generic' => q#Israel-Tiet#,
				'standard' => q#Israel-Standardtiet#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japaansch Summertiet#,
				'generic' => q#Japaansch Tiet#,
				'standard' => q#Japaansch Standardtiet#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreaansch Summertiet#,
				'generic' => q#Koreaansch Tiet#,
				'standard' => q#Koreaansch Standardtiet#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskau-Summertiet#,
				'generic' => q#Moskau-Tiet#,
				'standard' => q#Moskau-Standardtiet#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
