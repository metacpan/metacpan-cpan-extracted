=encoding utf8

=head1

Locale::CLDR::Locales::Gsw - Package for language Swiss German

=cut

package Locale::CLDR::Locales::Gsw;
# This file auto generated from Data\common\main\gsw.xml
#	on Sun  3 Feb  1:53:50 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
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
 				'root' => 'Root',
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
 			'Armi' => 'Armi',
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
 			'Cham' => 'Cham',
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
 			'MK' => 'Mazedoonie',
 			'MK@alt=variant' => 'Mazedoonie (EJRM)',
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
			auxiliary => qr{[á à ă â å ā æ ç é è ĕ ê ë ē í ì ĭ î ï ī ñ ó ò ŏ ô ø ō œ ú ù ŭ û ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ä b c d e f g h i j k l m n o ö p q r s t u ü v w x y z]},
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
						'name' => q(Acre),
						'one' => q({0} Acre),
						'other' => q({0} Acre),
					},
					'arc-minute' => {
						'name' => q(Winkelminute),
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminute),
					},
					'arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunde),
					},
					'celsius' => {
						'name' => q(Grad Celsius),
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
					},
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					'cubic-mile' => {
						'name' => q(Kubikmeile),
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeile),
					},
					'day' => {
						'name' => q(Tääg),
						'one' => q({0} Taag),
						'other' => q({0} Tääg),
					},
					'degree' => {
						'name' => q(Grad),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					'fahrenheit' => {
						'name' => q(Grad Fahrenheit),
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					'foot' => {
						'name' => q(Fuess),
						'one' => q({0} Fuess),
						'other' => q({0} Fuess),
					},
					'g-force' => {
						'name' => q(-fachi Erdbeschlünigung),
						'one' => q({0}-fachi Erdbeschlünigung),
						'other' => q({0}-fachi Erdbeschlünigung),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
					},
					'hectare' => {
						'name' => q(Hektar),
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					'hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					'horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärke),
					},
					'hour' => {
						'name' => q(Schtunde),
						'one' => q({0} Schtund),
						'other' => q({0} Schtunde),
					},
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					'inch-hg' => {
						'name' => q(Zoll Quecksilbersüüle),
						'one' => q({0} Zoll Quecksilbersüüle),
						'other' => q({0} Zoll Quecksilbersüüle),
					},
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
					},
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Stund),
						'one' => q({0} Kilometer pro Stund),
						'other' => q({0} Kilometer pro Stund),
					},
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					'light-year' => {
						'name' => q(Liechtjahr),
						'one' => q({0} Liechtjahr),
						'other' => q({0} Liechtjahr),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
					},
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					'mile' => {
						'name' => q(Meile),
						'one' => q({0} Meile),
						'other' => q({0} Meile),
					},
					'mile-per-hour' => {
						'name' => q(Meile pro Stund),
						'one' => q({0} Meile pro Stund),
						'other' => q({0} Meile pro Stund),
					},
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					'millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunde),
					},
					'minute' => {
						'name' => q(Minuute),
						'one' => q({0} Minuute),
						'other' => q({0} Minuute),
					},
					'month' => {
						'name' => q(Mönet),
						'one' => q({0} Monet),
						'other' => q({0} Mönet),
					},
					'ounce' => {
						'name' => q(Unze),
						'one' => q({0} Unze),
						'other' => q({0} Unze),
					},
					'per' => {
						'1' => q({0} pro {1}),
					},
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
					},
					'second' => {
						'name' => q(Sekunde),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunde),
					},
					'square-foot' => {
						'name' => q(Quadratfuess),
						'one' => q({0} Quadratfuess),
						'other' => q({0} Quadratfuess),
					},
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
					},
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
					},
					'square-mile' => {
						'name' => q(Quadratmeile),
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeile),
					},
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					'week' => {
						'name' => q(Wuche),
						'one' => q({0} Wuche),
						'other' => q({0} Wuche),
					},
					'yard' => {
						'name' => q(Yard),
						'one' => q({0} Yard),
						'other' => q({0} Yard),
					},
					'year' => {
						'name' => q(Jahr),
						'one' => q({0} Jahr),
						'other' => q({0} Jahr),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
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
						'one' => q({0} Fuess),
						'other' => q({0} Fuess),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gram' => {
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
					'horsepower' => {
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					'inch' => {
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'light-year' => {
						'one' => q({0} Liechtjahr),
						'other' => q({0} Liechtjahr),
					},
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'ounce' => {
						'one' => q({0} Unze),
						'other' => q({0} Unze),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pound' => {
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
					},
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(Acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'name' => q(Winkelminute),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(Grad Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'name' => q(Kubikmeile),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(Tääg),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'degree' => {
						'name' => q(Grad),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(Grad Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'name' => q(Fuess),
						'one' => q({0} Fuess),
						'other' => q({0} Fuess),
					},
					'g-force' => {
						'name' => q(-fachi Erdbeschlünigung),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'name' => q(Hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'name' => q(Schtunde),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					'inch-hg' => {
						'name' => q(Zoll Quecksilbersüüle),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Stund),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'name' => q(Liechtjahr),
						'one' => q({0} Liechtjahr),
						'other' => q({0} Liechtjahr),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'name' => q(Meile),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'name' => q(Meile pro Stund),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(Minuute),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(Mönet),
					},
					'ounce' => {
						'name' => q(Unze),
						'one' => q({0} Unze),
						'other' => q({0} Unze),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
					},
					'second' => {
						'name' => q(Sekunde),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-foot' => {
						'name' => q(Quadratfuess),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'name' => q(Quadratmeile),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(Wuche),
					},
					'yard' => {
						'name' => q(Yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(Jahr),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(’),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
				'one' => q(Andorranischi Peseete),
				'other' => q(Andorranischi Peseete),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(UAE Dirham),
				'one' => q(UAE Dirham),
				'other' => q(UAE Dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani \(1927–2002\)),
				'one' => q(Afghani \(1927–2002\)),
				'other' => q(Afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani),
				'one' => q(Afghani),
				'other' => q(Afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek),
				'one' => q(Lek),
				'other' => q(Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram),
				'one' => q(Dram),
				'other' => q(Dram),
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
				'one' => q(Kwanza Reajustado),
				'other' => q(Kwanza Reajustado),
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
				'one' => q(Aruba Florin),
				'other' => q(Aruba Florin),
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
				'one' => q(Barbados-Dollar),
				'other' => q(Barbados-Dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka),
				'one' => q(Taka),
				'other' => q(Taka),
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
				'one' => q(Bahrain-Dinar),
				'other' => q(Bahrain-Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi-Franc),
				'one' => q(Burundi-Franc),
				'other' => q(Burundi-Franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-Dollar),
				'one' => q(Bermuda-Dollar),
				'other' => q(Bermuda-Dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei-Dollar),
				'one' => q(Brunei-Dollar),
				'other' => q(Brunei-Dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(Boliviano),
				'other' => q(Boliviano),
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
				'one' => q(Bahama-Dollar),
				'other' => q(Bahama-Dollar),
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
				'one' => q(Belarus-Rubel \(1994–1999\)),
				'other' => q(Belarus-Rubel \(1994–1999\)),
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
			symbol => 'CHF',
			display_name => {
				'currency' => q(Schwiizer Franke),
				'one' => q(Schwiizer Franke),
				'other' => q(Schwiizer Franke),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR-Franke),
				'one' => q(WIR-Franke),
				'other' => q(WIR-Franke),
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
				'one' => q(Unidad de Valor Real),
				'other' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rica Colon),
				'one' => q(Costa Rica Colon),
				'other' => q(Costa Rica Colon),
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
				'one' => q(Tschechoslowakischi Chroone),
				'other' => q(Tschechoslowakischi Chroone),
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
				'one' => q(Kap Verde Escudo),
				'other' => q(Kap Verde Escudo),
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
				'one' => q(Tschechischi Chroone),
				'other' => q(Tschechischi Chroone),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(DDR-Mark),
				'one' => q(DDR-Mark),
				'other' => q(DDR-Mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Tüütschi Mark),
				'one' => q(Tüütschi Mark),
				'other' => q(Tüütschi Mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Dschibuti-Franc),
				'one' => q(Dschibuti-Franc),
				'other' => q(Dschibuti-Franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Tänischi Chroone),
				'one' => q(Tänischi Chroone),
				'other' => q(Tänischi Chroone),
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
				'one' => q(Verrächnigsäiheit für EC),
				'other' => q(Verrächnigsäiheit für EC),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Eestnischi Chroone),
				'one' => q(Eestnischi Chroone),
				'other' => q(Eestnischi Chroone),
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
				'one' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnischi Mark),
				'one' => q(Finnischi Mark),
				'other' => q(Finnischi Mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi Dollar),
				'one' => q(Fidschi Dollar),
				'other' => q(Fidschi Dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland-Pfund),
				'one' => q(Falkland-Pfund),
				'other' => q(Falkland-Pfund),
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
				'one' => q(Pfund Schtörling),
				'other' => q(Pfund Schtörling),
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
				'one' => q(Gibraltar-Pfund),
				'other' => q(Gibraltar-Pfund),
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
				'one' => q(Guinea-Franc),
				'other' => q(Guinea-Franc),
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
				'one' => q(Äquatorialguinea-Ekwele),
				'other' => q(Äquatorialguinea-Ekwele),
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
				'one' => q(Quetzal),
				'other' => q(Quetzal),
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
				'one' => q(Guyana-Dollar),
				'other' => q(Guyana-Dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-Dollar),
				'one' => q(Hongkong-Dollar),
				'other' => q(Hongkong-Dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira),
				'one' => q(Lempira),
				'other' => q(Lempira),
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
				'one' => q(Kuna),
				'other' => q(Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde),
				'one' => q(Gourde),
				'other' => q(Gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint),
				'one' => q(Forint),
				'other' => q(Forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesischi Rupie),
				'one' => q(Indonesischi Rupie),
				'other' => q(Indonesischi Rupie),
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
				'one' => q(Schekel),
				'other' => q(Schekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indischi Rupie),
				'one' => q(Indischi Rupie),
				'other' => q(Indischi Rupie),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irak-Dinar),
				'one' => q(Irak-Dinar),
				'other' => q(Irak-Dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial),
				'one' => q(Rial),
				'other' => q(Rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Iisländischi Chroone),
				'one' => q(Iisländischi Chroone),
				'other' => q(Iisländischi Chroone),
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
				'one' => q(Jamaika-Dollar),
				'other' => q(Jamaika-Dollar),
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
				'one' => q(Yen),
				'other' => q(Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenia-Schilling),
				'one' => q(Kenia-Schilling),
				'other' => q(Kenia-Schilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som),
				'one' => q(Som),
				'other' => q(Som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel),
				'one' => q(Riel),
				'other' => q(Riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komore-Franc),
				'one' => q(Komore-Franc),
				'other' => q(Komore-Franc),
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
				'one' => q(Kuwait-Dinar),
				'other' => q(Kuwait-Dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaiman-Dollar),
				'one' => q(Kaiman-Dollar),
				'other' => q(Kaiman-Dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge),
				'one' => q(Tenge),
				'other' => q(Tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip),
				'one' => q(Kip),
				'other' => q(Kip),
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
				'one' => q(Sri-Lanka-Rupie),
				'other' => q(Sri-Lanka-Rupie),
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
				'one' => q(Loti),
				'other' => q(Loti),
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
				'one' => q(Moldau-Löi),
				'other' => q(Moldau-Löi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaschkar-Ariary),
				'one' => q(Madagaschkar-Ariary),
				'other' => q(Madagaschkar-Ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaschkar-Franc),
				'one' => q(Madagaschkar-Franc),
				'other' => q(Madagaschkar-Franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar),
				'one' => q(Denar),
				'other' => q(Denar),
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
				'one' => q(Kyat),
				'other' => q(Kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik),
				'one' => q(Tugrik),
				'other' => q(Tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca),
				'one' => q(Pataca),
				'other' => q(Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya \(1973–2017\)),
				'one' => q(Ouguiya \(1973–2017\)),
				'other' => q(Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya),
				'one' => q(Ouguiya),
				'other' => q(Ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malteesischi Lira),
				'one' => q(Malteesischi Lira),
				'other' => q(Malteesischi Lira),
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
				'one' => q(Maurizius-Rupie),
				'other' => q(Maurizius-Rupie),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa),
				'one' => q(Rufiyaa),
				'other' => q(Rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi-Kwacha),
				'one' => q(Malawi-Kwacha),
				'other' => q(Malawi-Kwacha),
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
				'one' => q(Metical),
				'other' => q(Metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia-Dollar),
				'one' => q(Namibia-Dollar),
				'other' => q(Namibia-Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira),
				'one' => q(Naira),
				'other' => q(Naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Cordoba),
				'one' => q(Cordoba),
				'other' => q(Cordoba),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaragua-Córdoba),
				'one' => q(Nicaragua-Córdoba),
				'other' => q(Nicaragua-Córdoba),
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
				'one' => q(Norweegischi Chroone),
				'other' => q(Norweegischi Chroone),
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
				'one' => q(Neuseeland-Dollar),
				'other' => q(Neuseeland-Dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Omani),
				'one' => q(Rial Omani),
				'other' => q(Rial Omani),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa),
				'one' => q(Balboa),
				'other' => q(Balboa),
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
				'one' => q(Sol),
				'other' => q(Sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol \(1863–1965\)),
				'one' => q(Sol \(1863–1965\)),
				'other' => q(Sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina),
				'one' => q(Kina),
				'other' => q(Kina),
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
				'one' => q(Pakischtanischi Rupie),
				'other' => q(Pakischtanischi Rupie),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty),
				'one' => q(Zloty),
				'other' => q(Zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloty \(1950–1995\)),
				'one' => q(Zloty \(1950–1995\)),
				'other' => q(Zloty \(1950–1995\)),
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
				'one' => q(Guarani),
				'other' => q(Guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar-Riyal),
				'one' => q(Katar-Riyal),
				'other' => q(Katar-Riyal),
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
				'one' => q(Löi),
				'other' => q(Löi),
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
				'one' => q(Ruanda-Franc),
				'other' => q(Ruanda-Franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi-Riyal),
				'one' => q(Saudi-Riyal),
				'other' => q(Saudi-Riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomone-Dollar),
				'one' => q(Salomone-Dollar),
				'other' => q(Salomone-Dollar),
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
				'one' => q(Singapur-Dollar),
				'other' => q(Singapur-Dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St.-Helena-Pfund),
				'one' => q(St.-Helena-Pfund),
				'other' => q(St.-Helena-Pfund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar),
				'one' => q(Tolar),
				'other' => q(Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowakischi Chroone),
				'one' => q(Slowakischi Chroone),
				'other' => q(Slowakischi Chroone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone),
				'one' => q(Leone),
				'other' => q(Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalia-Schilling),
				'one' => q(Somalia-Schilling),
				'other' => q(Somalia-Schilling),
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
				'one' => q(Dobra \(1977–2017\)),
				'other' => q(Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra),
				'one' => q(Dobra),
				'other' => q(Dobra),
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
				'one' => q(El-Salvador-Colon),
				'other' => q(El-Salvador-Colon),
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
				'one' => q(Lilangeni),
				'other' => q(Lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht),
				'one' => q(Baht),
				'other' => q(Baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadschikischtan-Rubel),
				'one' => q(Tadschikischtan-Rubel),
				'other' => q(Tadschikischtan-Rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadschikischtan-Somoni),
				'one' => q(Tadschikischtan-Somoni),
				'other' => q(Tadschikischtan-Somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmeenischtan-Manat),
				'one' => q(Turkmeenischtan-Manat),
				'other' => q(Turkmeenischtan-Manat),
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
				'one' => q(Paʻanga),
				'other' => q(Paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor-Escudo),
				'one' => q(Timor-Escudo),
				'other' => q(Timor-Escudo),
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
				'one' => q(Trinidad-und-Tobago-Dollar),
				'other' => q(Trinidad-und-Tobago-Dollar),
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
				'one' => q(Tansania-Schilling),
				'other' => q(Tansania-Schilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia),
				'one' => q(Hryvnia),
				'other' => q(Hryvnia),
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
				'one' => q(Uganda-Schilling \(1966–1987\)),
				'other' => q(Uganda-Schilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda-Schilling),
				'one' => q(Uganda-Schilling),
				'other' => q(Uganda-Schilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
				'one' => q(US-Dollar),
				'other' => q(US-Dollar),
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
				'one' => q(Usbeekischtan-Sum),
				'other' => q(Usbeekischtan-Sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolivar \(1871–2008\)),
				'one' => q(Bolivar \(1871–2008\)),
				'other' => q(Bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolivar \(2008–2018\)),
				'one' => q(Bolivar \(2008–2018\)),
				'other' => q(Bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar),
				'one' => q(Bolivar),
				'other' => q(Bolivar),
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
				'one' => q(Vatu),
				'other' => q(Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala),
				'one' => q(Tala),
				'other' => q(Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-Franc \(Äquatoriaal\)),
				'one' => q(CFA-Franc \(Äquatoriaal\)),
				'other' => q(CFA-Franc \(Äquatoriaal\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Silber),
				'one' => q(Silber),
				'other' => q(Silber),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Gold),
				'one' => q(Gold),
				'other' => q(Gold),
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
				'one' => q(Sunderziäigsrächt),
				'other' => q(Sunderziäigsrächt),
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
				'one' => q(CFA-Franc \(Wescht\)),
				'other' => q(CFA-Franc \(Wescht\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
				'one' => q(Palladium),
				'other' => q(Palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-Franc),
				'one' => q(CFP-Franc),
				'other' => q(CFP-Franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platin),
				'one' => q(Platin),
				'other' => q(Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-Funds),
				'one' => q(RINET-Funds),
				'other' => q(RINET-Funds),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Teschtwährig),
				'one' => q(Teschtwährig),
				'other' => q(Teschtwährig),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Unbekannti Währig),
				'one' => q(Unbekannti Währig),
				'other' => q(Unbekannti Währig),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jeme-Dinar),
				'one' => q(Jeme-Dinar),
				'other' => q(Jeme-Dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jeme-Rial),
				'one' => q(Jeme-Rial),
				'other' => q(Jeme-Rial),
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
				'one' => q(Rand),
				'other' => q(Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha \(1968–2012\)),
				'one' => q(Kwacha \(1968–2012\)),
				'other' => q(Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha),
				'one' => q(Kwacha),
				'other' => q(Kwacha),
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
				'one' => q(Zaire),
				'other' => q(Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar),
				'one' => q(Simbabwe-Dollar),
				'other' => q(Simbabwe-Dollar),
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
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
					'midnight' => q{Mitternacht},
					'pm' => q{nam.},
					'afternoon2' => q{am Namittag},
					'am' => q{vorm.},
					'night1' => q{znacht},
					'evening1' => q{zaabig},
					'morning1' => q{am Morge},
					'afternoon1' => q{zmittag},
				},
				'wide' => {
					'evening1' => q{zaabig},
					'morning1' => q{am Morge},
					'afternoon1' => q{zmittag},
					'pm' => q{am Namittag},
					'midnight' => q{Mitternacht},
					'afternoon2' => q{am Namittag},
					'am' => q{am Vormittag},
					'night1' => q{znacht},
				},
			},
			'stand-alone' => {
				'wide' => {
					'night1' => q{Nacht},
					'midnight' => q{Mitternacht},
					'pm' => q{Namittag},
					'afternoon2' => q{Namittag},
					'am' => q{Vormittag},
					'afternoon1' => q{Mittag},
					'evening1' => q{Aabig},
					'morning1' => q{Morge},
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
			narrow => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
			wide => {
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
		'gregorian' => {
			Ed => q{E d.},
			H => q{H},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			d => q{d},
			mmss => q{mm:ss},
			ms => q{mm:ss},
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
		'generic' => {
			Ed => q{E d.},
			H => q{H},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			d => q{d},
			mmss => q{mm:ss},
			ms => q{mm:ss},
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
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
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
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MM – MM.y},
				y => q{MM.y – MM.y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
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
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
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
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MM – MM.y},
				y => q{MM.y – MM.y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
		fallbackFormat => q({1} ({0})),
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
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
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
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
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
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
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
