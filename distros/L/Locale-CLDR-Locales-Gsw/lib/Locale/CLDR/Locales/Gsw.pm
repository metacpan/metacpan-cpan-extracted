=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gsw - Package for language Swiss German

=cut

package Locale::CLDR::Locales::Gsw;
# This file auto generated from Data\common\main\gsw.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Afar',
 				'ab' => 'Abchasisch',
 				'ace' => 'Aceh',
 				'ach' => 'Acholi',
 				'ada' => 'Adangme',
 				'ady' => 'Adygai',
 				'ae' => 'Avestisch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadisch',
 				'ale' => 'Aleutisch',
 				'alt' => 'Süüd-Altaisch',
 				'am' => 'Amharisch',
 				'an' => 'Aragonesisch',
 				'ang' => 'Altänglisch',
 				'anp' => 'Angika',
 				'ar' => 'Arabisch',
 				'arc' => 'Aramääisch',
 				'arn' => 'Araukanisch',
 				'arp' => 'Arapaho',
 				'arw' => 'Arawak',
 				'as' => 'Assamesisch',
 				'asa' => 'Asu (Tanzania)',
 				'ast' => 'Aschturianisch',
 				'av' => 'Awarisch',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschanisch',
 				'ba' => 'Baschkirisch',
 				'bal' => 'Belutschisch',
 				'ban' => 'Balinesisch',
 				'bas' => 'Basaa',
 				'be' => 'Wiissrussisch',
 				'bej' => 'Bedauye',
 				'bem' => 'Bemba',
 				'bez' => 'Bena (Tanzania)',
 				'bg' => 'Bulgaarisch',
 				'bho' => 'Bhodschpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikolisch',
 				'bin' => 'Bini',
 				'bla' => 'Blackfoot-Schpraach',
 				'bm' => 'Bambara',
 				'bn' => 'Bengalisch',
 				'bo' => 'Tibeetisch',
 				'br' => 'Brötoonisch',
 				'bra' => 'Braj-Bhakha',
 				'bs' => 'Bosnisch',
 				'bua' => 'Burjatisch',
 				'bug' => 'Bugineesisch',
 				'byn' => 'Blin',
 				'ca' => 'Katalaanisch',
 				'cad' => 'Caddo',
 				'car' => 'Kariibisch',
 				'cch' => 'Atsam',
 				'ce' => 'Tschetscheenisch',
 				'ceb' => 'Cebuano',
 				'ch' => 'Chamorro',
 				'chb' => 'Tschibtscha',
 				'chg' => 'Tschagataisch',
 				'chk' => 'Trukesisch',
 				'chm' => 'Tscheremissisch',
 				'chn' => 'Chinook',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'co' => 'Korsisch',
 				'cop' => 'Koptisch',
 				'cr' => 'Cree',
 				'crh' => 'Krimtatarisch',
 				'cs' => 'Tschechisch',
 				'csb' => 'Kaschubisch',
 				'cu' => 'Chileslawisch',
 				'cv' => 'Tschuwaschisch',
 				'cy' => 'Walisisch',
 				'da' => 'Tänisch',
 				'dak' => 'Takota',
 				'dar' => 'Targiinisch',
 				'de' => 'Tüütsch',
 				'de_AT' => 'Öschtriichischs Tüütsch',
 				'de_CH' => 'Schwiizer Hochtüütsch',
 				'del' => 'Delaware-Schpraach',
 				'den' => 'Slavey',
 				'dgr' => 'Togrib',
 				'din' => 'Tinka',
 				'doi' => 'Togri',
 				'dsb' => 'Nidersorbisch',
 				'dua' => 'Tuala',
 				'dum' => 'Mittelniderländisch',
 				'dv' => 'Malediivisch',
 				'dyu' => 'Tiula',
 				'dz' => 'Dschongkha',
 				'ee' => 'Ewe',
 				'efi' => 'Efikisch',
 				'egy' => 'Altägyptisch',
 				'eka' => 'Ekajuk',
 				'el' => 'Griechisch',
 				'elx' => 'Elamisch',
 				'en' => 'Änglisch',
 				'en_AU' => 'Auschtralischs Änglisch',
 				'en_CA' => 'Kanadischs Änglisch',
 				'en_GB' => 'Britischs Änglisch',
 				'en_US' => 'Amerikanischs Änglisch',
 				'enm' => 'Mittelänglisch',
 				'eo' => 'Eschperanto',
 				'es' => 'Schpanisch',
 				'es_419' => 'Latiinamerikanischs Schpanisch',
 				'es_ES' => 'Ibeerischs Schpanisch',
 				'et' => 'Eestnisch',
 				'eu' => 'Baskisch',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persisch',
 				'fan' => 'Pangwe-Schpraach',
 				'fat' => 'Fanti-Schpraach',
 				'ff' => 'Ful',
 				'fi' => 'Finnisch',
 				'fil' => 'Filipino',
 				'fj' => 'Fidschianisch',
 				'fo' => 'Färöisch',
 				'fon' => 'Fon',
 				'fr' => 'Französisch',
 				'fr_CA' => 'Kanadischs Französisch',
 				'fr_CH' => 'Schwiizer Französisch',
 				'frm' => 'Mittelfranzösisch',
 				'fro' => 'Altfranzösisch',
 				'frr' => 'Nordfriesisch',
 				'frs' => 'Oschtfriesisch',
 				'fur' => 'Friulisch',
 				'fy' => 'Friesisch',
 				'ga' => 'Iirisch',
 				'gaa' => 'Ga',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gd' => 'Schottisch-Gäälisch',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertesisch',
 				'gl' => 'Galizisch',
 				'gmh' => 'Mittelhochtüütsch',
 				'gn' => 'Guarani',
 				'goh' => 'Althochtüütsch',
 				'gon' => 'Gondi',
 				'gor' => 'Mongondou',
 				'got' => 'Gotisch',
 				'grb' => 'Grebo',
 				'grc' => 'Altgriechisch',
 				'gsw' => 'Schwiizertüütsch',
 				'gu' => 'Gujarati',
 				'gv' => 'Manx-Gäälisch',
 				'gwi' => 'Kutchinisch',
 				'ha' => 'Haussa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaiianisch',
 				'he' => 'Hebräisch',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynonisch',
 				'hit' => 'Hethitisch',
 				'hmn' => 'Miao',
 				'ho' => 'Hiri-Motu',
 				'hr' => 'Kroazisch',
 				'hsb' => 'Obersorbisch',
 				'ht' => 'Haitisch',
 				'hu' => 'Ungarisch',
 				'hup' => 'Hupa',
 				'hy' => 'Armenisch',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Ibanisch',
 				'id' => 'Indonesisch',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sezuanischs Yi',
 				'ik' => 'Inupiak',
 				'ilo' => 'Ilokano',
 				'inh' => 'Inguschisch',
 				'io' => 'Ido',
 				'is' => 'Iisländisch',
 				'it' => 'Italiänisch',
 				'iu' => 'Inukitut',
 				'ja' => 'Japanisch',
 				'jbo' => 'Lojbanisch',
 				'jpr' => 'Jüüdisch-Persisch',
 				'jrb' => 'Jüüdisch-Arabisch',
 				'jv' => 'Javanisch',
 				'ka' => 'Georgisch',
 				'kaa' => 'Karakalpakisch',
 				'kab' => 'Kabylisch',
 				'kac' => 'Kachin-Schpraach',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardinisch',
 				'kcg' => 'Tyap',
 				'kea' => 'Kabuverdianu',
 				'kfo' => 'Koro',
 				'kg' => 'Kongolesisch',
 				'kha' => 'Khasisch',
 				'kho' => 'Sakisch',
 				'ki' => 'Kikuyu-Schpraach',
 				'kj' => 'Kwanyama',
 				'kk' => 'Kasachisch',
 				'kl' => 'Gröönländisch',
 				'km' => 'Kambodschanisch',
 				'kmb' => 'Kimbundu-Schpraach',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaanisch',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeanisch',
 				'kpe' => 'Kpelle-Schpraach',
 				'kr' => 'Kanuri-Schpraach',
 				'krc' => 'Karatschaiisch-Balkarisch',
 				'krl' => 'Karelisch',
 				'kru' => 'Oraon-Schpraach',
 				'ks' => 'Kaschmirisch',
 				'ku' => 'Kurdisch',
 				'kum' => 'Kumükisch',
 				'kut' => 'Kutenai-Schpraach',
 				'kv' => 'Komi-Schpraach',
 				'kw' => 'Kornisch',
 				'ky' => 'Kirgiisisch',
 				'la' => 'Latiin',
 				'lad' => 'Ladino',
 				'lah' => 'Lahndanisch',
 				'lam' => 'Lambanisch',
 				'lb' => 'Luxemburgisch',
 				'lez' => 'Lesgisch',
 				'lg' => 'Ganda-Schpraach',
 				'li' => 'Limburgisch',
 				'ln' => 'Lingala',
 				'lo' => 'Laozisch',
 				'lol' => 'Mongo',
 				'loz' => 'Rotse-Schpraach',
 				'lt' => 'Litauisch',
 				'lu' => 'Luba',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno-Schpraach',
 				'lun' => 'Lunda-Schpraach',
 				'luo' => 'Luo-Schpraach',
 				'lus' => 'Lushai-Schpraach',
 				'luy' => 'Olulujia',
 				'lv' => 'Lettisch',
 				'mad' => 'Maduresisch',
 				'mag' => 'Khotta',
 				'mai' => 'Maithili',
 				'mak' => 'Makassarisch',
 				'man' => 'Manding-Schpraach',
 				'mas' => 'Massai-Schpraach',
 				'mdf' => 'Mokschamordwinisch',
 				'mdr' => 'Mandaresisch',
 				'men' => 'Mende-Schpraach',
 				'mg' => 'Madagassisch',
 				'mga' => 'Mittelirisch',
 				'mh' => 'Marschallesisch',
 				'mi' => 'Maori',
 				'mic' => 'Micmac-Schpraach',
 				'min' => 'Minangkabau-Schpraach',
 				'mk' => 'Mazedonisch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolisch',
 				'mnc' => 'Mandschurisch',
 				'mni' => 'Meithei-Schpraach',
 				'moh' => 'Mohawk-Schpraach',
 				'mos' => 'Mossi-Schpraach',
 				'mr' => 'Marathi',
 				'ms' => 'Malaiisch',
 				'mt' => 'Maltesisch',
 				'mul' => 'Mehrschpraachig',
 				'mus' => 'Muskogee-Schpraach',
 				'mwl' => 'Mirandesisch',
 				'mwr' => 'Marwarisch',
 				'my' => 'Birmanisch',
 				'myv' => 'Erzya',
 				'na' => 'Nauruisch',
 				'nap' => 'Neapolitanisch',
 				'nb' => 'Norwegisch Bokmål',
 				'nd' => 'Nord-Ndebele-Schpraach',
 				'nds' => 'Nidertüütsch',
 				'ne' => 'Nepalesisch',
 				'new' => 'Newarisch',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias-Schpraach',
 				'niu' => 'Niue-Schpraach',
 				'nl' => 'Niderländisch',
 				'nl_BE' => 'Fläämisch',
 				'nn' => 'Norwegisch Nynorsk',
 				'no' => 'Norwegisch',
 				'nog' => 'Nogaisch',
 				'non' => 'Altnordisch',
 				'nqo' => 'N’Ko',
 				'nr' => 'Süüd-Ndebele-Schpraach',
 				'nso' => 'Nord-Sotho-Schpraach',
 				'nv' => 'Navajo-Schpraach',
 				'nwc' => 'Alt-Newari',
 				'ny' => 'Chewa-Schpraach',
 				'nym' => 'Nyamwezi-Schpraach',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Okzitanisch',
 				'oj' => 'Ojibwa-Schpraach',
 				'om' => 'Oromo',
 				'or' => 'Orija',
 				'os' => 'Ossezisch',
 				'osa' => 'Osage-Schpraach',
 				'ota' => 'Osmanisch',
 				'pa' => 'Pandschabisch',
 				'pag' => 'Pangasinanisch',
 				'pal' => 'Mittelpersisch',
 				'pam' => 'Pampanggan-Schpraach',
 				'pap' => 'Papiamento',
 				'pau' => 'Palau',
 				'peo' => 'Altpersisch',
 				'phn' => 'Phönikisch',
 				'pi' => 'Pali',
 				'pl' => 'Polnisch',
 				'pon' => 'Ponapeanisch',
 				'pro' => 'Altprovenzalisch',
 				'ps' => 'Paschtu',
 				'pt' => 'Portugiisisch',
 				'pt_BR' => 'Brasilianischs Portugiisisch',
 				'pt_PT' => 'Iberischs Portugiisisch',
 				'qu' => 'Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Oschterinsel-Schpraach',
 				'rar' => 'Rarotonganisch',
 				'rm' => 'Rätoromanisch',
 				'rn' => 'Rundi-Schpraach',
 				'ro' => 'Rumänisch',
 				'ro_MD' => 'Moldawisch',
 				'rom' => 'Zigüünerschpraach',
 				'ru' => 'Russisch',
 				'rup' => 'Aromunisch',
 				'rw' => 'Ruandisch',
 				'sa' => 'Sanschkrit',
 				'sad' => 'Sandawe-Schpraach',
 				'sah' => 'Jakutisch',
 				'sam' => 'Samaritanisch',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'sc' => 'Sardisch',
 				'scn' => 'Sizilianisch',
 				'sco' => 'Schottisch',
 				'sd' => 'Sindhi',
 				'se' => 'Nord-Samisch',
 				'sel' => 'Selkupisch',
 				'sg' => 'Sango',
 				'sga' => 'Altirisch',
 				'sh' => 'Serbo-Kroatisch',
 				'shn' => 'Schan-Schpraach',
 				'si' => 'Singhalesisch',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowakisch',
 				'sl' => 'Slowenisch',
 				'sm' => 'Samoanisch',
 				'sma' => 'Süüd-Samisch',
 				'smj' => 'Lule-Samisch',
 				'smn' => 'Inari-Samisch',
 				'sms' => 'Skolt-Samisch',
 				'sn' => 'Schhona',
 				'snk' => 'Soninke-Schpraach',
 				'so' => 'Somali',
 				'sog' => 'Sogdisch',
 				'sq' => 'Albanisch',
 				'sr' => 'Serbisch',
 				'srn' => 'Srananisch',
 				'srr' => 'Serer-Schpraach',
 				'ss' => 'Swazi',
 				'st' => 'Süüd-Sotho-Schpraach',
 				'su' => 'Sundanesisch',
 				'suk' => 'Sukuma-Schpraach',
 				'sus' => 'Susu',
 				'sux' => 'Sumerisch',
 				'sv' => 'Schwedisch',
 				'sw' => 'Suaheli',
 				'swb' => 'Shimaorisch',
 				'syc' => 'Altsyrisch',
 				'syr' => 'Syrisch',
 				'ta' => 'Tamilisch',
 				'te' => 'Telugu',
 				'tem' => 'Temne',
 				'ter' => 'Tereno-Schpraach',
 				'tet' => 'Tetum-Schpraach',
 				'tg' => 'Tadschikisch',
 				'th' => 'Thailändisch',
 				'ti' => 'Tigrinja',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv-Schpraach',
 				'tk' => 'Turkmenisch',
 				'tkl' => 'Tokelauanisch',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingonisch',
 				'tli' => 'Tlingit-Schpraach',
 				'tmh' => 'Tamaseq',
 				'tn' => 'Tswana-Schpraach',
 				'to' => 'Tongaisch',
 				'tog' => 'Tsonga-Schpraach',
 				'tpi' => 'Neumelanesisch',
 				'tr' => 'Türkisch',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshian-Schpraach',
 				'tt' => 'Tatarisch',
 				'tum' => 'Tumbuka-Schpraach',
 				'tvl' => 'Elliceanisch',
 				'tw' => 'Twi',
 				'ty' => 'Tahitisch',
 				'tyv' => 'Tuwinisch',
 				'udm' => 'Udmurtisch',
 				'ug' => 'Uigurisch',
 				'uga' => 'Ugaritisch',
 				'uk' => 'Ukrainisch',
 				'umb' => 'Mbundu-Schpraach',
 				'und' => 'Unbeschtimmti Schpraach',
 				'ur' => 'Urdu',
 				'uz' => 'Usbekisch',
 				'vai' => 'Vai-Schpraach',
 				've' => 'Venda-Schpraach',
 				'vi' => 'Vietnamesisch',
 				'vo' => 'Volapük',
 				'vot' => 'Wotisch',
 				'wa' => 'Wallonisch',
 				'wal' => 'Walamo-Schpraach',
 				'war' => 'Waray',
 				'was' => 'Washo-Schpraach',
 				'wo' => 'Wolof',
 				'xal' => 'Kalmückisch',
 				'xh' => 'Xhosa',
 				'yao' => 'Yao-Schpraach',
 				'yap' => 'Yapesisch',
 				'yi' => 'Jiddisch',
 				'yo' => 'Yoruba',
 				'yue' => 'Kantonesisch',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotekisch',
 				'zbl' => 'Bliss-Symbool',
 				'zen' => 'Zenaga',
 				'zh' => 'Chineesisch',
 				'zh_Hans' => 'Veräifachts Chineesisch',
 				'zh_Hant' => 'Tradizionells Chineesisch',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni-Schpraach',
 				'zxx' => 'Kän schpraachliche Inhalt',
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
			'Arab' => 'Arabisch',
 			'Armn' => 'Armenisch',
 			'Avst' => 'Aveschtisch',
 			'Bali' => 'Balinesisch',
 			'Batk' => 'Battakisch',
 			'Beng' => 'Bengalisch',
 			'Blis' => 'Bliss-Symbool',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Blindäschrift',
 			'Bugi' => 'Buginesisch',
 			'Buhd' => 'Buhid',
 			'Cans' => 'UCAS',
 			'Cari' => 'Karisch',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptisch',
 			'Cprt' => 'Zypriotisch',
 			'Cyrl' => 'Kyrillisch',
 			'Cyrs' => 'Altchileslawisch',
 			'Deva' => 'Tövanagaari',
 			'Dsrt' => 'Teseret',
 			'Egyd' => 'Temozisch-Ägüptisch',
 			'Egyh' => 'Hiraazisch-Ägüptisch',
 			'Egyp' => 'Ägüptischi Hiroglüüfe',
 			'Ethi' => 'Äzioopisch',
 			'Geok' => 'Ghutsuri',
 			'Geor' => 'Georgisch',
 			'Glag' => 'Glagolitisch',
 			'Goth' => 'Gotisch',
 			'Grek' => 'Griechisch',
 			'Gujr' => 'Guscharati',
 			'Guru' => 'Gurmukhi',
 			'Hang' => 'Hangul',
 			'Hani' => 'Chineesisch',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Veräifachti Chineesischi Schrift',
 			'Hant' => 'Tradizionelli Chineesischi Schrift',
 			'Hebr' => 'Hebräisch',
 			'Hira' => 'Hiragana',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana oder Hiragana',
 			'Hung' => 'Altungarisch',
 			'Inds' => 'Indus-Schrift',
 			'Ital' => 'Altitalisch',
 			'Java' => 'Javanesisch',
 			'Jpan' => 'Japanisch',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreanisch',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laotisch',
 			'Latf' => 'Latiinisch - Fraktur-Variante',
 			'Latg' => 'Latiinisch - Gäälischi Variante',
 			'Latn' => 'Latiinisch',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lyci' => 'Lykisch',
 			'Lydi' => 'Lydisch',
 			'Mand' => 'Mandäisch',
 			'Mani' => 'Manichäisch',
 			'Maya' => 'Maya-Hieroglyphä',
 			'Mero' => 'Meroitisch',
 			'Mlym' => 'Malaysisch',
 			'Mong' => 'Mongolisch',
 			'Moon' => 'Moon',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Burmesisch',
 			'Nkoo' => 'N’Ko',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orchon-Runä',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmanisch',
 			'Perm' => 'Altpermisch',
 			'Phag' => 'Phags-pa',
 			'Phlv' => 'Pahlavi',
 			'Phnx' => 'Phönizisch',
 			'Plrd' => 'Pollard Phonetisch',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runäschrift',
 			'Samr' => 'Samaritanisch',
 			'Sara' => 'Sarati',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Gebäärdeschpraach',
 			'Shaw' => 'Shaw-Alphabet',
 			'Sinh' => 'Singhalesisch',
 			'Sund' => 'Sundanesisch',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syrisch',
 			'Syre' => 'Syrisch - Eschtrangelo-Variante',
 			'Syrj' => 'Weschtsyrisch',
 			'Syrn' => 'Oschtsyrisch',
 			'Tagb' => 'Tagbanwa',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue',
 			'Taml' => 'Tamilisch',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibeetisch',
 			'Ugar' => 'Ugaritisch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Sichtbari Schpraach',
 			'Xpeo' => 'Altpersisch',
 			'Xsux' => 'Sumerisch-akkadischi Keilschrift',
 			'Yiii' => 'Yi',
 			'Zinh' => 'G’eerbtä Schriftwärt',
 			'Zxxx' => 'Schriftlosi Schpraach',
 			'Zyyy' => 'Unbeschtimmt',
 			'Zzzz' => 'Uncodiirti Schrift',

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
			'001' => 'Wält',
 			'002' => 'Afrika',
 			'003' => 'Nordameerika',
 			'005' => 'Süüdameerika',
 			'009' => 'Ozeaanie',
 			'011' => 'Weschtafrika',
 			'013' => 'Mittelameerika',
 			'014' => 'Oschtafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Zentraalafrika',
 			'018' => 'Süüdlichs Afrika',
 			'019' => 'Nord-, Mittel- und Süüdameerika',
 			'021' => 'Nördlichs Ameerika',
 			'029' => 'Karibik',
 			'030' => 'Oschtaasie',
 			'034' => 'Süüdaasie',
 			'035' => 'Süüdoschtaasie',
 			'039' => 'Süüdeuropa',
 			'053' => 'Auschtraalie und Nöiseeland',
 			'054' => 'Melaneesie',
 			'057' => 'Mikroneesischs Inselgebiet',
 			'061' => 'Polineesie',
 			'142' => 'Aasie',
 			'143' => 'Zentraalaasie',
 			'145' => 'Weschtaasie',
 			'150' => 'Euroopa',
 			'151' => 'Oschteuroopa',
 			'154' => 'Nordeuroopa',
 			'155' => 'Weschteuroopa',
 			'419' => 'Latiinameerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Veräinigti Arabischi Emirate',
 			'AF' => 'Afganischtan',
 			'AG' => 'Antigua und Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albaanie',
 			'AM' => 'Armeenie',
 			'AO' => 'Angoola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentiinie',
 			'AS' => 'Amerikaanisch-Samoa',
 			'AT' => 'Ööschtriich',
 			'AU' => 'Auschtraalie',
 			'AW' => 'Aruba',
 			'AX' => 'Aaland-Insle',
 			'AZ' => 'Aserbäidschan',
 			'BA' => 'Bosnie und Herzegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belgie',
 			'BF' => 'Burkina Faaso',
 			'BG' => 'Bulgaarie',
 			'BH' => 'Bachräin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthelemi',
 			'BM' => 'Bermuuda',
 			'BN' => 'Brunäi Tarussalam',
 			'BO' => 'Boliivie',
 			'BR' => 'Brasilie',
 			'BS' => 'Bahaamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet-Insle',
 			'BW' => 'Botswana',
 			'BY' => 'Wiissrussland',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos-Insle',
 			'CD' => 'Temokraatischi Republik Kongo',
 			'CD@alt=variant' => 'Kongo-Kinshasa',
 			'CF' => 'Zentraalafrikaanischi Republik',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Kongo-Brazzaville',
 			'CH' => 'Schwiiz',
 			'CI' => 'Elfebäiküschte',
 			'CK' => 'Cook-Insle',
 			'CL' => 'Tschile',
 			'CM' => 'Kamerun',
 			'CN' => 'Chiina',
 			'CO' => 'Kolumbie',
 			'CP' => 'Clipperton',
 			'CR' => 'Coschta Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CX' => 'Wienachts-Insle',
 			'CY' => 'Zypere',
 			'CZ' => 'Tschechischi Republik',
 			'DE' => 'Tüütschland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Tschibuuti',
 			'DK' => 'Tänemark',
 			'DM' => 'Tominica',
 			'DO' => 'Tominikaanischi Republik',
 			'DZ' => 'Algeerie',
 			'EA' => 'Ceuta und Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Eestland',
 			'EG' => 'Ägüpte',
 			'EH' => 'Weschtsahara',
 			'ER' => 'Äritreea',
 			'ES' => 'Schpanie',
 			'ET' => 'Äthiopie',
 			'EU' => 'Europääischi Unioon',
 			'FI' => 'Finnland',
 			'FJ' => 'Fitschi',
 			'FK' => 'Falkland-Insle',
 			'FM' => 'Mikroneesie',
 			'FO' => 'Färöer',
 			'FR' => 'Frankriich',
 			'GA' => 'Gabun',
 			'GB' => 'Veräinigts Chönigriich',
 			'GD' => 'Grenada',
 			'GE' => 'Geoorgie',
 			'GF' => 'Französisch-Guäjaana',
 			'GG' => 'Gäärnsi',
 			'GH' => 'Gaana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Gröönland',
 			'GM' => 'Gambia',
 			'GN' => 'Gineea',
 			'GP' => 'Guadälup',
 			'GQ' => 'Äquatoriaalgineea',
 			'GR' => 'Griecheland',
 			'GS' => 'Süüdgeorgie und d’süüdlichi Sändwitsch-Insle',
 			'GT' => 'Guatemaala',
 			'GU' => 'Guam',
 			'GW' => 'Gineea-Bissau',
 			'GY' => 'Guäjaana',
 			'HK' => 'Sonderverwaltigszone Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Höörd- und MäcDonald-Insle',
 			'HN' => 'Honduras',
 			'HR' => 'Kroaazie',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Canarische Eilanden',
 			'ID' => 'Indoneesie',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Insle vo Män',
 			'IN' => 'Indie',
 			'IO' => 'Britischs Territoorium im Indische Oozean',
 			'IQ' => 'Iraak',
 			'IR' => 'Iraan',
 			'IS' => 'Iisland',
 			'IT' => 'Itaalie',
 			'JE' => 'Dschörsi',
 			'JM' => 'Dschamäika',
 			'JO' => 'Jordaanie',
 			'JP' => 'Japan',
 			'KE' => 'Keenia',
 			'KG' => 'Kirgiisischtan',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribaati',
 			'KM' => 'Komoore',
 			'KN' => 'St. Kitts und Niuwis',
 			'KP' => 'Demokraatischi Volksrepublik Koreea',
 			'KR' => 'Republik Koreea',
 			'KW' => 'Kuwäit',
 			'KY' => 'Käimän-Insle',
 			'KZ' => 'Kasachschtan',
 			'LA' => 'Laaos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lutschiia',
 			'LI' => 'Liächteschtäi',
 			'LK' => 'Schri Lanka',
 			'LR' => 'Libeeria',
 			'LS' => 'Lesooto',
 			'LT' => 'Littaue',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettland',
 			'LY' => 'Lüübie',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Republik Moldau',
 			'ME' => 'Monteneegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaschkar',
 			'MH' => 'Marshallinsle',
 			'ML' => 'Maali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolei',
 			'MO' => 'Sonderverwaltigszone Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nördlichi Mariaane',
 			'MQ' => 'Martinigg',
 			'MR' => 'Mauretaanie',
 			'MS' => 'Moosörrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauriizius',
 			'MV' => 'Malediiwe',
 			'MW' => 'Malaawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Maläisia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namiibia',
 			'NC' => 'Nöikaledoonie',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk-Insle',
 			'NG' => 'Nigeeria',
 			'NI' => 'Nicaraagua',
 			'NL' => 'Holland',
 			'NO' => 'Norweege',
 			'NP' => 'Neepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nöiseeland',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Französisch-Polineesie',
 			'PG' => 'Papua-Neuguinea',
 			'PH' => 'Philippiine',
 			'PK' => 'Pakischtan',
 			'PL' => 'Poole',
 			'PM' => 'St. Pierr und Miggelo',
 			'PN' => 'Pitggäärn',
 			'PR' => 'Puerto Riggo',
 			'PS' => 'Paläschtinänsischi Gebiet',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Ggatar',
 			'QO' => 'Üssers Ozeaanie',
 			'RE' => 'Reünioon',
 			'RO' => 'Rumäänie',
 			'RS' => 'Särbie',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Araabie',
 			'SB' => 'Salomoone',
 			'SC' => 'Seischälle',
 			'SD' => 'Sudan',
 			'SE' => 'Schweede',
 			'SG' => 'Singapuur',
 			'SH' => 'St. Helena',
 			'SI' => 'Sloweenie',
 			'SJ' => 'Svalbard und Jaan Määie',
 			'SK' => 'Slowakäi',
 			'SL' => 'Sierra Leoone',
 			'SM' => 'San Mariino',
 			'SN' => 'Senegal',
 			'SO' => 'Somaalie',
 			'SR' => 'Surinam',
 			'ST' => 'Sao Tome und Prinssipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Süürie',
 			'SZ' => 'Swasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Törks- und Gaiggos-Insle',
 			'TD' => 'Tschad',
 			'TF' => 'Französischi Süüd- und Antarktisgebiet',
 			'TG' => 'Toogo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadschikischtan',
 			'TK' => 'Tokelau',
 			'TL' => 'Oschttimor',
 			'TM' => 'Turkmeenischtan',
 			'TN' => 'Tuneesie',
 			'TO' => 'Tonga',
 			'TR' => 'Türggei',
 			'TT' => 'Trinidad und Tobaago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansaniia',
 			'UA' => 'Ukraiine',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikanisch-Ozeaanie',
 			'US' => 'Veräinigti Schtaate',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uschbeekischtan',
 			'VA' => 'Vatikanstadt',
 			'VC' => 'St. Vincent und d’Grönadiine',
 			'VE' => 'Venezueela',
 			'VG' => 'Britischi Jungfere-Insle',
 			'VI' => 'Amerikaanischi Jungfere-Insle',
 			'VN' => 'Wietnam',
 			'VU' => 'Wanuatu',
 			'WF' => 'Wallis und Futuuna',
 			'WS' => 'Samooa',
 			'YE' => 'Jeeme',
 			'YT' => 'Majott',
 			'ZA' => 'Süüdafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Unbekannti oder ungültigi Regioon',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Alti tüütschi Rächtschriibig',
 			'1994' => 'Schtandardisierti Resianischi Rächtschriibig',
 			'1996' => 'Nööi tüütschi Rächtschriibig',
 			'1606NICT' => 'Schpaats Mittelfranzösisch',
 			'AREVELA' => 'Oschtarmeenisch',
 			'AREVMDA' => 'Weschtarmeenisch',
 			'BAKU1926' => 'Äinheitlichs Türggischs Alfabeet',
 			'BISKE' => 'Bela-Tialäkt',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'Foneetisch (IPA)',
 			'FONUPA' => 'Foneetisch (UPA)',
 			'LIPAW' => 'Lipowaz-Mundart',
 			'MONOTON' => 'Monotonisch',
 			'NEDIS' => 'Natisone-Mundart',
 			'NJIVA' => 'Njiva-Mundart',
 			'OSOJS' => 'Osojane-Mundart',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Politonisch',
 			'POSIX' => 'Posix',
 			'REVISED' => 'Nööi Rächtschriibig',
 			'ROZAJ' => 'Resianisch',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schottischs Schtandardänglisch',
 			'SCOUSE' => 'Scouse-Mundart',
 			'SOLBA' => 'Solbica-Mundart',
 			'TARASK' => 'Taraskievica-Rächtschriibig',
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
			'calendar' => 'Kaländer',
 			'collation' => 'Sortiirig',
 			'currency' => 'Wäährig',

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
 				'buddhist' => q{Buddhischtisch Kaländer},
 				'chinese' => q{Chineesisch Kaländer},
 				'gregorian' => q{Gregoriaanisch Kaländer},
 				'hebrew' => q{Hebrääisch Kaländer},
 				'indian' => q{Indisch Nationaalkaländer},
 				'islamic' => q{Islaamisch Kaländer},
 				'islamic-civil' => q{Bürgerlich islaamisch Kaländer},
 				'japanese' => q{Japaanisch Kaländer},
 				'roc' => q{Kaländer vor Republik Chiina},
 			},
 			'collation' => {
 				'big5han' => q{Tradizionells Chineesisch - Big5},
 				'gb2312han' => q{Veräifachts Chineesisch - GB2312},
 				'phonebook' => q{Telifonbuech-Sortiirregle},
 				'pinyin' => q{Pinyin-Sortiirregle},
 				'stroke' => q{Strichfolg},
 				'traditional' => q{Tradizionelli Sortiir-Regle},
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
			'metric' => q{metrisch},
 			'US' => q{angloamerikaanisch},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Schpraach: {0}',
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
			auxiliary => qr{[áàăâåā æ ç éèĕêëē íìĭîïī ñ óòŏôøō œ úùŭûū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aä b c d e f g h i j k l m n oö p q r s t uü v w x y z]},
			numbers => qr{[. ’ % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‹},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}-fachi Erdbeschlünigung),
						'other' => q({0}-fachi Erdbeschlünigung),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}-fachi Erdbeschlünigung),
						'other' => q({0}-fachi Erdbeschlünigung),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunde),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunde),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} Acre),
						'other' => q({0} Acre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} Acre),
						'other' => q({0} Acre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} Quadratfuess),
						'other' => q({0} Quadratfuess),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} Quadratfuess),
						'other' => q({0} Quadratfuess),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeile),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeile),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} Taag),
						'other' => q({0} Tääg),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} Taag),
						'other' => q({0} Tääg),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} Schtund),
						'other' => q({0} Schtunde),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} Schtund),
						'other' => q({0} Schtunde),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunde),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunde),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} Minuute),
						'other' => q({0} Minuute),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} Minuute),
						'other' => q({0} Minuute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} Monet),
						'other' => q({0} Mönet),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} Monet),
						'other' => q({0} Mönet),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunde),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} Wuche),
						'other' => q({0} Wuche),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} Wuche),
						'other' => q({0} Wuche),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} Jahr),
						'other' => q({0} Jahr),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} Jahr),
						'other' => q({0} Jahr),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} Meter),
						'other' => q({0} Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} Meter),
						'other' => q({0} Meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} Meile),
						'other' => q({0} Meile),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} Meile),
						'other' => q({0} Meile),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} Yard),
						'other' => q({0} Yard),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} Yard),
						'other' => q({0} Yard),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärke),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärke),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} Zoll Quecksilbersüüle),
						'other' => q({0} Zoll Quecksilbersüüle),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} Zoll Quecksilbersüüle),
						'other' => q({0} Zoll Quecksilbersüüle),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} Kilometer pro Stund),
						'other' => q({0} Kilometer pro Stund),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} Kilometer pro Stund),
						'other' => q({0} Kilometer pro Stund),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} Meile pro Stund),
						'other' => q({0} Meile pro Stund),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} Meile pro Stund),
						'other' => q({0} Meile pro Stund),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeile),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeile),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} Liter),
						'other' => q({0} Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} Liter),
						'other' => q({0} Liter),
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
					'duration-day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
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
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
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
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(-fachi Erdbeschlünigung),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(-fachi Erdbeschlünigung),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Winkelminute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Winkelminute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Winkelsekunde),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Winkelsekunde),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Grad),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Grad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Acre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Acre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(Hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(Hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(Quadratfuess),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(Quadratfuess),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(Quadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(Quadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(Quadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(Quadratmeile),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(Quadratmeile),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Tääg),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Tääg),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Schtunde),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Schtunde),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Millisekunde),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Millisekunde),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Minuute),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Minuute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mönet),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mönet),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sekunde),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sekunde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wuche),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wuche),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Jahr),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Jahr),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Zentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Zentimeter),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Fuess),
						'one' => q({0} Fuess),
						'other' => q({0} Fuess),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Fuess),
						'one' => q({0} Fuess),
						'other' => q({0} Fuess),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(Liechtjahr),
						'one' => q({0} Liechtjahr),
						'other' => q({0} Liechtjahr),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Liechtjahr),
						'one' => q({0} Liechtjahr),
						'other' => q({0} Liechtjahr),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(Meile),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(Meile),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(Millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(Millimeter),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Pikometer),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(Yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(Yard),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(Kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(Kilogramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(Unze),
						'one' => q({0} Unze),
						'other' => q({0} Unze),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(Unze),
						'one' => q({0} Unze),
						'other' => q({0} Unze),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(Kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(Kilowatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Watt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(Hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(Hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Zoll Quecksilbersüüle),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Zoll Quecksilbersüüle),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(Millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(Millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(Kilometer pro Stund),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Stund),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(Meter pro Sekunde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(Meile pro Stund),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(Meile pro Stund),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Grad Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Grad Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Grad Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Grad Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(Kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(Kubikmeile),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(Kubikmeile),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Liter),
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
	default		=> sub { qr'^(?i:näi|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} und {1}),
				2 => q({0} und {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'group' => q(’),
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
					'one' => '0 Tuusig',
					'other' => '0 Tuusig',
				},
				'10000' => {
					'one' => '00 Tuusig',
					'other' => '00 Tuusig',
				},
				'100000' => {
					'one' => '000 Tuusig',
					'other' => '000 Tuusig',
				},
				'1000000' => {
					'one' => '0 Millioon',
					'other' => '0 Millioone',
				},
				'10000000' => {
					'one' => '00 Millioon',
					'other' => '00 Millioone',
				},
				'100000000' => {
					'one' => '000 Millioon',
					'other' => '000 Millioone',
				},
				'1000000000' => {
					'one' => '0 Milliarde',
					'other' => '0 Milliarde',
				},
				'10000000000' => {
					'one' => '00 Milliarde',
					'other' => '00 Milliarde',
				},
				'100000000000' => {
					'one' => '000 Milliarde',
					'other' => '000 Milliarde',
				},
				'1000000000000' => {
					'one' => '0 Billioon',
					'other' => '0 Billioone',
				},
				'10000000000000' => {
					'one' => '00 Billioon',
					'other' => '00 Billioone',
				},
				'100000000000000' => {
					'one' => '000 Billioon',
					'other' => '000 Billioone',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 Tsg'.'',
					'other' => '0 Tsg'.'',
				},
				'10000' => {
					'one' => '00 Tsg'.'',
					'other' => '00 Tsg'.'',
				},
				'100000' => {
					'one' => '000 Tsg'.'',
					'other' => '000 Tsg'.'',
				},
				'1000000' => {
					'one' => '0 Mio'.'',
					'other' => '0 Mio'.'',
				},
				'10000000' => {
					'one' => '00 Mio'.'',
					'other' => '00 Mio'.'',
				},
				'100000000' => {
					'one' => '000 Mio'.'',
					'other' => '000 Mio'.'',
				},
				'1000000000' => {
					'one' => '0 Mrd'.'',
					'other' => '0 Mrd'.'',
				},
				'10000000000' => {
					'one' => '00 Mrd'.'',
					'other' => '00 Mrd'.'',
				},
				'100000000000' => {
					'one' => '000 Mrd'.'',
					'other' => '000 Mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 Bio'.'',
					'other' => '0 Bio'.'',
				},
				'10000000000000' => {
					'one' => '00 Bio'.'',
					'other' => '00 Bio'.'',
				},
				'100000000000000' => {
					'one' => '000 Bio'.'',
					'other' => '000 Bio'.'',
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
				'currency' => q(Andorranischi Peseete),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(UAE Dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niderländischi-Antille-Gulde),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolanische Kwanza \(1977–1990\)),
				'one' => q(Angolanischi Kwanza \(1977–1990\)),
				'other' => q(Angolanischi Kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Nöie Kwanza),
				'one' => q(Nöii Kwanza),
				'other' => q(Nöii Kwanza),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza Reajustado),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentinische Auschtral),
				'one' => q(Argentinischi Auschtral),
				'other' => q(Argentinischi Auschtral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinische Peso \(1983–1985\)),
				'one' => q(Argentinischi Peso \(1983–1985\)),
				'other' => q(Argentinischi Peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentinische Peso),
				'one' => q(Argentinische Peso),
				'other' => q(Argentinischi Pesos),
			},
		},
		'ATS' => {
			symbol => 'öS',
			display_name => {
				'currency' => q(Öschtriichische Schilling),
				'one' => q(Öschtriichischi Schilling),
				'other' => q(Öschtriichischi Schilling),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Auschtralische Dollar),
				'one' => q(Auschtralische Dollar),
				'other' => q(Auschtralischi Dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba Florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Aserbeidschanische Manat \(1993–2006\)),
				'one' => q(Aserbaidschanischi Manat \(1993–2006\)),
				'other' => q(Aserbaidschanischi Manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbeidschanische Manat),
				'one' => q(Aserbeidschanische Manat),
				'other' => q(Aserbeidschanischi Manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnie-und-Herzegowina-Dinar),
				'one' => q(Bosnie-und-Herzegowina-Dinär),
				'other' => q(Bosnie-und-Herzegowina-Dinär),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Konvertierbari Mark vo Bosnie und Herzegowina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados-Dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgische Franc \(konvertibel\)),
				'one' => q(Belgischi Franc \(konvertibel\)),
				'other' => q(Belgischi Franc \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgische Franc),
				'one' => q(Belgischi Franc),
				'other' => q(Belgischi Franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgische Finanz-Franc),
				'one' => q(Belgischi Finanz-Franc),
				'other' => q(Belgischi Finanz-Franc),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lew \(1962–1999\)),
				'one' => q(Lewa \(1962–1999\)),
				'other' => q(Lewa \(1962–1999\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarische Lew),
				'one' => q(Bulgarische Lew),
				'other' => q(Bulgarischi Lew),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrain-Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi-Franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-Dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei-Dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivianische Peso),
				'one' => q(Bolivianischi Peso),
				'other' => q(Bolivianischi Peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivianische Mvdol),
				'one' => q(Bolivianischi Mvdol),
				'other' => q(Bolivianischi Mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasilianische Cruzeiro Novo \(1967–1986\)),
				'one' => q(Brasilianischi Cruzeiro Novo \(1967–1986\)),
				'other' => q(Brasilianischi Cruzeiro Novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasilianische Cruzado),
				'one' => q(Brasilianischi Cruzado),
				'other' => q(Brasilianischi Cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasilianische Cruzeiro \(1990–1993\)),
				'one' => q(Brasilianischi Cruzeiro \(1990–1993\)),
				'other' => q(Brasilianischi Cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasilianische Real),
				'one' => q(Brasilianische Real),
				'other' => q(Brasilianischi Real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brasilianische Cruzado Novo),
				'one' => q(Brasilianischi Cruzado Novo),
				'other' => q(Brasilianischi Cruzado Novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasilianische Cruzeiro),
				'one' => q(Brasilianischi Cruzeiro),
				'other' => q(Brasilianischi Cruzeiro),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahama-Dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanische Ngultrum),
				'one' => q(Bhutanische Ngultrum),
				'other' => q(Bhutanischi Ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Birmanische Kyat),
				'one' => q(Birmanischi Kyat),
				'other' => q(Birmanischi Kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanische Pula),
				'one' => q(Botswanische Pula),
				'other' => q(Botswanischi Pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarus-Rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarus Rubel),
				'one' => q(Belarus-Rubel),
				'other' => q(Belarus-Rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarus Rubel \(2000–2016\)),
				'one' => q(Belarus-Rubel \(2000–2016\)),
				'other' => q(Belarus-Rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize-Dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanadische Dollar),
				'one' => q(Kanadische Dollar),
				'other' => q(Kanadischi Dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongolesische Franc),
				'one' => q(Kongolesische Franc),
				'other' => q(Kongolesischi Franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR-Euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Schwiizer Franke),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR-Franke),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Tschileenische Unidad de Fomento),
				'one' => q(Tschileenischi Unidades de Fomento),
				'other' => q(Tschileenischi Unidades de Fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Tschileenische Peso),
				'one' => q(Tschileenische Peso),
				'other' => q(Tschileenischi Pesos),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Renminbi Yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbianische Peso),
				'one' => q(Kolumbianische Peso),
				'other' => q(Kolumbianischi Pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rica Colon),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Alte Serbische Dinar),
				'one' => q(Alti Serbischi Dinar),
				'other' => q(Alti Serbischi Dinar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tschechoslowakischi Chroone),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubanische Peso),
				'one' => q(Kubanische Peso),
				'other' => q(Kubanischi Pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kap Verde Escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Zypere-Pfund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tschechischi Chroone),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(DDR-Mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Tüütschi Mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Dschibuti-Franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Tänischi Chroone),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Tominikanische Peso),
				'one' => q(Tominikanische Peso),
				'other' => q(Tominikanischi Pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algeerischi Dinar),
				'one' => q(Algeerische Dinar),
				'other' => q(Algeerischi Dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadorianische Sucre),
				'one' => q(Ecuadorianischi Sucre),
				'other' => q(Ecuadorianischi Sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Verrächnigsäiheit für EC),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Eestnischi Chroone),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ägüptischs Pfund),
				'one' => q(Ägüptische Pfund),
				'other' => q(Ägüptischi Pfund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreische Nakfa),
				'one' => q(Eritreische Nakfa),
				'other' => q(Eritreischi Nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Schpanischi Peseeta \(A–Kontene\)),
				'one' => q(Schpanischi Peseete \(A–Kontene\)),
				'other' => q(Schpanischi Peseete \(A–Kontene\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Schpanischi Peseeta \(konvertibel\)),
				'one' => q(Schpanischi Peseete \(konvertibel\)),
				'other' => q(Schpanischi Peseete \(konvertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Schpanischi Peseeta),
				'one' => q(Schpanischi Peseete),
				'other' => q(Schpanischi Peseete),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Äthiopische Birr),
				'one' => q(Äthiopische Birr),
				'other' => q(Äthiopischi Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnischi Mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi Dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland-Pfund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Französische Franc),
				'one' => q(Französischi Franc),
				'other' => q(Französischi Franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pfund Schtörling),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgische Kupon Larit),
				'one' => q(Georgischi Kupon Larit),
				'other' => q(Georgischi Kupon Larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgische Lari),
				'one' => q(Georgische Lari),
				'other' => q(Georgischi Lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanaische Cedi \(GHC\)),
				'one' => q(Ghanaischi Cedi \(GHC\)),
				'other' => q(Ghanaischi Cedi \(GHC\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaische Cedi \(GHS\)),
				'one' => q(Ghanaische Cedi \(GHS\)),
				'other' => q(Ghanaischi Cedi \(GHS\)),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar-Pfund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambische Dalasi),
				'one' => q(Gambische Dalasi),
				'other' => q(Gambischi Dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinea-Franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guineische Syli),
				'one' => q(Guineischi Syli),
				'other' => q(Guineischi Syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Äquatorialguinea-Ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Griechische Trachme),
				'one' => q(Griechischi Trachme),
				'other' => q(Griechischi Trachme),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugiisische Guinea Escudo),
				'one' => q(Portugiisischi Guinea Escudo),
				'other' => q(Portugiisischi Guinea Escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau-Peso),
				'one' => q(Guinea-Bissau-Pesos),
				'other' => q(Guinea-Bissau-Pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana-Dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-Dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroazische Dinar),
				'one' => q(Kroazischi Dinar),
				'other' => q(Kroazischi Dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesischi Rupie),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Iirischs Pfund),
				'one' => q(Iirischi Pfund),
				'other' => q(Iirischi Pfund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israelischs Pfund),
				'one' => q(Israelischi Pfund),
				'other' => q(Israelischi Pfund),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Schekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indischi Rupie),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irak-Dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Iisländischi Chroone),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiänischi Lira),
				'one' => q(Italienischi Lire),
				'other' => q(Italienischi Lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika-Dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaanische Dinar),
				'one' => q(Jordaanische Dinar),
				'other' => q(Jordaanischi Dinar),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenia-Schilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komore-Franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Nordkoreanische Won),
				'one' => q(Nordkoreanische Won),
				'other' => q(Nordkoreanischi Won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Süüdkoreanische Won),
				'one' => q(Süüdkoreanische Won),
				'other' => q(Süüdkoreanischi Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwait-Dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaiman-Dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libaneesischs Pfund),
				'one' => q(Libaneesischs Pfund),
				'other' => q(Libaneesischi Pfund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri-Lanka-Rupie),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiaanische Dollar),
				'one' => q(Liberiaanische Dollar),
				'other' => q(Liberiaanischi Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litauische Litas),
				'one' => q(Litauische Litas),
				'other' => q(Litauischi Litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litauische Talonas),
				'one' => q(Litauischi Talonas),
				'other' => q(Litauischi Talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxemburgische Franc \(konvertibel\)),
				'one' => q(Luxemburgischi Franc \(konvertibel\)),
				'other' => q(Luxemburgischi Franc \(konvertibel\)),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburgische Franc),
				'one' => q(Luxemburgischi Franc),
				'other' => q(Luxemburgischi Franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxemburgischer Finanz-Franc),
				'one' => q(Luxemburgischi Finanz-Franc),
				'other' => q(Luxemburgischi Finanz-Franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettische Lats),
				'one' => q(Lettische Lats),
				'other' => q(Lettischi Lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lettische Rubel),
				'one' => q(Lettischi Rubel),
				'other' => q(Lettischi Rubel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Lüübische Dinar),
				'one' => q(Lüübische Dinar),
				'other' => q(Lüübischi Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkanische Dirham),
				'one' => q(Marokkanische Dirham),
				'other' => q(Marokkanischi Dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkanischer Franc),
				'one' => q(Marokkanische Franc),
				'other' => q(Marokkanische Franc),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldau-Löi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaschkar-Ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaschkar-Franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malische Franc),
				'one' => q(Malischi Franc),
				'other' => q(Malischi Franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malteesischi Lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Malteesischs Pfund),
				'one' => q(Malteesischi Pfund),
				'other' => q(Malteesischi Pfund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Maurizius-Rupie),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Malediven-Rufiyaa),
				'one' => q(Malediven-Rufiyaa),
				'other' => q(Malediven-Rupien),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi-Kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexikanische Peso),
				'one' => q(Mexikanische Peso),
				'other' => q(Mexikanischi Pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexikanische Silber-Peso \(1861–1992\)),
				'one' => q(Mexikanischi Silber-Pesos \(MXP\)),
				'other' => q(Mexikanischi Silber-Pesos \(MXP\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexikanische Unidad de Inversion \(UDI\)),
				'one' => q(Mexikanischi Unidad de Inversion \(UDI\)),
				'other' => q(Mexikanischi Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysische Ringgit),
				'one' => q(Malaysische Ringgit),
				'other' => q(Malaysischi Ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mosambikanische Escudo),
				'one' => q(Mozambikanischi Escudo),
				'other' => q(Mozambikanischi Escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Alte Metical),
				'one' => q(Alti Metical),
				'other' => q(Alti Metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia-Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Cordoba),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaragua-Córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Holländische Gulde),
				'one' => q(Holländischi Gulde),
				'other' => q(Holländischi Gulde),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norweegischi Chroone),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepaleesischi Rupie),
				'one' => q(Nepalesischi Rupie),
				'other' => q(Nepalesischi Rupie),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Neuseeland-Dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Omani),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruanische Inti),
				'one' => q(Peruanischi Inti),
				'other' => q(Peruanischi Inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Philippiinische Peso),
				'one' => q(Philippiinische Peso),
				'other' => q(Philippiinischi Pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakischtanischi Rupie),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugiisische Escudo),
				'one' => q(Portugiisischi Escudo),
				'other' => q(Portugiisischi Escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar-Riyal),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesische Dollar),
				'one' => q(Rhodesischi Dollar),
				'other' => q(Rhodesischi Dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Löi),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumäänische Löi),
				'one' => q(Rumäänische Löi),
				'other' => q(Rumäänischi Löi),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbische Dinar),
				'one' => q(Serbische Dinar),
				'other' => q(Serbischi Dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russische Rubel),
				'one' => q(Russische Rubel),
				'other' => q(Russischi Rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russische Rubel \(alt\)),
				'one' => q(Russischi Rubel \(alt\)),
				'other' => q(Russischi Rubel \(alt\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda-Franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi-Riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomone-Dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyschelle-Rupie),
				'one' => q(Seyschelle-Rupie),
				'other' => q(Seyschelle-Rupien),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudaneesische Dinar),
				'one' => q(Sudaneesischi Dinar),
				'other' => q(Sudaneesischi Dinar),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudaneesischs Pfund),
				'one' => q(Sudaneesische Pfund),
				'other' => q(Sudaneesischi Pfund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudaneesischs Pfund \(alt\)),
				'one' => q(Sudaneesischi Pfund \(alt\)),
				'other' => q(Sudaneesischi Pfund \(alt\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Schweedischi Chroone),
				'one' => q(Schwedischi Chroone),
				'other' => q(Schwedischi Chroone),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapur-Dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St.-Helena-Pfund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowakischi Chroone),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalia-Schilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinamische Dollar),
				'one' => q(Surinamische Dollar),
				'other' => q(Surinamischi Dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamische Gulde),
				'one' => q(Surinamischi Gulde),
				'other' => q(Surinamischi Gulde),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Süüdsudaneesischs Pfund),
				'one' => q(Süüdsudaneesische Pfund),
				'other' => q(Süüdsudaneesischi Pfund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sowjetische Rubel),
				'one' => q(Sowjetischi Rubel),
				'other' => q(Sowjetischi Rubel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El-Salvador-Colon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Süürischs Pfund),
				'one' => q(Süürischs Pfund),
				'other' => q(Süürischi Pfund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadschikischtan-Rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadschikischtan-Somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmeenischtan-Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tuneesische Dinar),
				'one' => q(Tuneesische Dinar),
				'other' => q(Tuneesischi Dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor-Escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Türkischi Liire),
				'one' => q(Türkischi Liira \(1922–2005\)),
				'other' => q(Türkischi Liire \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Nöii Türkischi Liire),
				'one' => q(Nöii Türkischi Liira),
				'other' => q(Nöii Türkischi Liire),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad-und-Tobago-Dollar),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Nöii Taiwan-Dollar),
				'one' => q(Nöie Taiwan-Dollar),
				'other' => q(Nöii Taiwan-Dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansania-Schilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukraiinische Karbovanetz),
				'one' => q(Ukraiinischi Karbovanetz),
				'other' => q(Ukraiinischi Karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uganda-Schilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda-Schilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US Dollar \(Nöchschte Taag\)),
				'one' => q(US-Dollar \(Nöchschte Taag\)),
				'other' => q(US-Dollar \(Nöchschte Taag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US Dollar \(Gliiche Taag\)),
				'one' => q(US-Dollar \(Gliiche Taag\)),
				'other' => q(US-Dollar \(Gliiche Taag\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayische Nöie Peso \(1975–1993\)),
				'one' => q(Uruguayischi Nöii Pesos \(1975–1993\)),
				'other' => q(Uruguayischi Nöii Pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayische Peso),
				'one' => q(Uruguayische Peso),
				'other' => q(Uruguayischi Pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbeekischtan-Sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-Franc \(Äquatoriaal\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Silber),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Gold),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europääischi Rächnigseinheit),
				'one' => q(Europääischi Rächnigseinheite),
				'other' => q(Europääischi Rächnigseinheite),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europääischi Währigseinheit \(XBB\)),
				'one' => q(Europääischi Währigseinheite \(XBB\)),
				'other' => q(Europääischi Währigseinheite \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europääischi Rächnigseinheit \(XBC\)),
				'one' => q(Europääischi Rächnigseinheite \(XBC\)),
				'other' => q(Europääischi Rächnigseinheite \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europääischi Rächnigseinheit \(XBD\)),
				'one' => q(Europääischi Rächnigseinheite \(XBD\)),
				'other' => q(Europääischi Rächnigseinheite \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Oschtkaribische Dollar),
				'one' => q(Oschtkaribische Dollar),
				'other' => q(Oschtkaribischi Dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Sunderziäigsrächt),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Europääischi Währigseinheit \(XEU\)),
				'one' => q(Europääischi Währigseinheite \(XEU\)),
				'other' => q(Europääischi Währigseinheite \(XEU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Französische Gold-Franc),
				'one' => q(Französischi Gold-Franc),
				'other' => q(Französischi Gold-Franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Französische UIC-Franc),
				'one' => q(Französischi UIC-Franc),
				'other' => q(Französischi UIC-Franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-Franc \(Wescht\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-Franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-Funds),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Teschtwährig),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Unbekannti Währig),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jeme-Dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jeme-Rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslawische Dinar \(1966–1990\)),
				'one' => q(Jugoslawischi Dinar \(1966–1990\)),
				'other' => q(Jugoslawischi Dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Nöii Dinar),
				'one' => q(Nöie Dinar),
				'other' => q(Nöii Dinar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslawische Dinar \(konvertibel\)),
				'one' => q(Jugoslawischi Dinar \(konvertibel\)),
				'other' => q(Jugoslawischi Dinar \(konvertibel\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Nöie Zaire),
				'one' => q(Nöii Zaire),
				'other' => q(Nöii Zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar),
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
							'Jan',
							'Feb',
							'Mär',
							'Apr',
							'Mai',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Okt',
							'Nov',
							'Dez'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januar',
							'Februar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'Auguscht',
							'Septämber',
							'Oktoober',
							'Novämber',
							'Dezämber'
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
						mon => 'Mä.',
						tue => 'Zi.',
						wed => 'Mi.',
						thu => 'Du.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'Su.'
					},
					wide => {
						mon => 'Määntig',
						tue => 'Ziischtig',
						wed => 'Mittwuch',
						thu => 'Dunschtig',
						fri => 'Friitig',
						sat => 'Samschtig',
						sun => 'Sunntig'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1. Quartal',
						1 => '2. Quartal',
						2 => '3. Quartal',
						3 => '4. Quartal'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
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
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
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
					'afternoon1' => q{zmittag},
					'afternoon2' => q{am Namittag},
					'am' => q{vorm.},
					'evening1' => q{zaabig},
					'midnight' => q{Mitternacht},
					'morning1' => q{am Morge},
					'night1' => q{znacht},
					'pm' => q{nam.},
				},
				'wide' => {
					'am' => q{am Vormittag},
					'pm' => q{am Namittag},
				},
			},
			'stand-alone' => {
				'wide' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Namittag},
					'am' => q{Vormittag},
					'evening1' => q{Aabig},
					'midnight' => q{Mitternacht},
					'morning1' => q{Morge},
					'night1' => q{Nacht},
					'pm' => q{Namittag},
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
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
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.M.y},
		},
		'generic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.yy GGGGG},
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
		'buddhist' => {
		},
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
		'buddhist' => {
		},
		'generic' => {
		},
		'gregorian' => {
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
			H => q{H},
			MEd => q{E, d.M.},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			mmss => q{mm:ss},
			y => q{y},
			yM => q{y-M},
			yMEd => q{E, y-M-d},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMdd => q{dd.MM.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d.},
			H => q{H},
			MEd => q{E, d.M.},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			mmss => q{mm:ss},
			yM => q{y-M},
			yMEd => q{E, y-M-d},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMdd => q{dd.MM.y},
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
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
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
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MM – MM.y},
				y => q{MM.y – MM.y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'gregorian' => {
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
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
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MM – MM.y},
				y => q{MM.y – MM.y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Acre' => {
			long => {
				'daylight' => q#Acre-Summerziit#,
				'generic' => q#Acre-Ziit#,
				'standard' => q#Acre-Schtandardziit#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanischtan-Ziit#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dschibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadischu#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Zentralafrikanischi Ziit#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oschtafrikanischi Ziit#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Süüdafrikanischi ziit#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Weschtafrikanischi Summerziit#,
				'generic' => q#Weschtafrikanischi Ziit#,
				'standard' => q#Weschtafrikanischi Schtandardziit#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-Summerziit#,
				'generic' => q#Alaska-Ziit#,
				'standard' => q#Alaska-Schtandardziit#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty-Summerziit#,
				'generic' => q#Almaty-Ziit#,
				'standard' => q#Almaty-Schtandardziit#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas-Summerziit#,
				'generic' => q#Amazonas-Ziit#,
				'standard' => q#Amazonas-Schtandardziit#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaninsle#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-Schtadt#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Amerika-Zentraal Summerziit#,
				'generic' => q#Amerika-Zentraal Ziit#,
				'standard' => q#Amerika-Zentraal Schtandardziit#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont D’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Woschtok#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtschatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muschkat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipeh#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Baator#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erivan#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azore#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanare#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöer#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Süüd-Georgie#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unbekannt#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarescht#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kischinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopehage#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschgorod#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Züri#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mitteleuropäischi Summerziit#,
				'generic' => q#Mitteleuropäischi Ziit#,
				'standard' => q#Mitteleuropäischi Schtandardziit#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oschteuropäischi Summerziit#,
				'generic' => q#Oschteuropäischi Ziit#,
				'standard' => q#Oschteuropäischi Schtandardziit#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Weschteuropäischi Summerziit#,
				'generic' => q#Weschteuropäischi Ziit#,
				'standard' => q#Weschteuropäischi Schtandardziit#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Wienachts-Insle#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komore#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maledive#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskauer Summerziit#,
				'generic' => q#Moskauer Ziit#,
				'standard' => q#Moskauer Schtandardziit#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Oschterinsle#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
