=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fy - Package for language Western Frisian

=cut

package Locale::CLDR::Locales::Fy;
# This file auto generated from Data\common\main\fy.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Afar',
 				'ab' => 'Abchazysk',
 				'ace' => 'Atjeesk',
 				'ach' => 'Akoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'ae' => 'Avestysk',
 				'af' => 'Afrikaansk',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadysk',
 				'ale' => 'Aleut',
 				'alt' => 'Sûd-Altaïsk',
 				'am' => 'Amhaarsk',
 				'an' => 'Aragoneesk',
 				'ang' => 'âldingelsk',
 				'anp' => 'Angika',
 				'ar' => 'Arabysk',
 				'ar_001' => 'Modern standert Arabysk',
 				'arc' => 'Arameesk',
 				'arn' => 'Araukaansk',
 				'arp' => 'Arapaho',
 				'arw' => 'Arawak',
 				'as' => 'Assameesk',
 				'asa' => 'Asu',
 				'ast' => 'Asturysk',
 				'av' => 'Avarysk',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbeidzjaansk',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Basjkiersk',
 				'bal' => 'Baloetsjysk',
 				'ban' => 'Balineesk',
 				'bas' => 'Basa',
 				'bax' => 'Bamoun',
 				'bbj' => 'Ghomala’',
 				'be' => 'Wyt-Russysk',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bg' => 'Bulgaarsk',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengaalsk',
 				'bo' => 'Tibetaansk',
 				'br' => 'Bretonsk',
 				'bra' => 'Braj',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnysk',
 				'bss' => 'Akoose',
 				'bua' => 'Buriat',
 				'bug' => 'Bugineesk',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Katalaansk',
 				'cad' => 'Kaddo',
 				'car' => 'Karibysk',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ce' => 'Tsjetsjeensk',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Chuukeesk',
 				'chm' => 'Mari',
 				'chn' => 'Chinook-jargon',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Soranî',
 				'co' => 'Korsikaansk',
 				'cop' => 'Koptysk',
 				'cr' => 'Cree',
 				'crh' => 'Krim-Tataarsk',
 				'cs' => 'Tsjechysk',
 				'csb' => 'Kasjoebysk',
 				'cu' => 'Kerkslavysk',
 				'cv' => 'Tsjoevasjysk',
 				'cy' => 'Welsk',
 				'da' => 'Deensk',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Dútsk',
 				'de_AT' => 'Eastenryks Dútsk',
 				'de_CH' => 'Switsersk Heechdútsk',
 				'del' => 'Delaware',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Nedersorbysk',
 				'dua' => 'Duala',
 				'dum' => 'Middelnederlânsk',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Aldegyptysk',
 				'eka' => 'Ekajuk',
 				'el' => 'Gryks',
 				'elx' => 'Elamitysk',
 				'en' => 'Ingelsk',
 				'en_AU' => 'Australysk Ingelsk',
 				'en_CA' => 'Kanadeesk Ingelsk',
 				'en_GB' => 'Britsk Ingelsk',
 				'en_US' => 'Amerikaansk Ingelsk',
 				'enm' => 'Middelingelsk',
 				'eo' => 'Esperanto',
 				'es' => 'Spaansk',
 				'es_419' => 'Latynsk-Amerikaansk Spaansk',
 				'es_ES' => 'Europeesk Spaansk',
 				'es_MX' => 'Meksikaansk Spaansk',
 				'et' => 'Estlânsk',
 				'eu' => 'Baskysk',
 				'ewo' => 'Ewondo',
 				'fa' => 'Perzysk',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fulah',
 				'fi' => 'Finsk',
 				'fil' => 'Filipynsk',
 				'fj' => 'Fijysk',
 				'fo' => 'Faeröersk',
 				'fon' => 'Fon',
 				'fr' => 'Frânsk',
 				'fr_CA' => 'Kanadeesk Frânsk',
 				'fr_CH' => 'Switserse Frânsk',
 				'frm' => 'Middelfrânsk',
 				'fro' => 'Aldfrânsk',
 				'frr' => 'Noard-Frysk',
 				'frs' => 'East-Frysk',
 				'fur' => 'Friulysk',
 				'fy' => 'Frysk',
 				'ga' => 'Iersk',
 				'gaa' => 'Ga',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gd' => 'Schotsk Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Gilberteesk',
 				'gl' => 'Galisysk',
 				'gmh' => 'Middelheechdútsk',
 				'gn' => 'Guaraní',
 				'goh' => 'Alsheechdútsk',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gothysk',
 				'grb' => 'Grebo',
 				'grc' => 'Aldgryks',
 				'gsw' => 'Switsers Dútsk',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manks',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaïaansk',
 				'he' => 'Hebreeuwsk',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hettitysk',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Kroatysk',
 				'hsb' => 'Oppersorbysk',
 				'ht' => 'Haïtiaansk',
 				'hu' => 'Hongaarsk',
 				'hup' => 'Hupa',
 				'hy' => 'Armeensk',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Yndonezysk',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'Inupiaq',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingoesj',
 				'io' => 'Ido',
 				'is' => 'Yslâns',
 				'it' => 'Italiaansk',
 				'iu' => 'Inuktitut',
 				'ja' => 'Japans',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Judeo-Perzysk',
 				'jrb' => 'Judeo-Arabysk',
 				'jv' => 'Javaansk',
 				'ka' => 'Georgysk',
 				'kaa' => 'Karakalpaks',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardysk',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kaapverdysk Creools',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kha' => 'Khasi',
 				'kho' => 'Khotaneesk',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazachs',
 				'kkj' => 'Kako',
 				'kl' => 'Grienlâns',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaansk',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeaansk',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelysk',
 				'kru' => 'Kurukh',
 				'ks' => 'Kasjmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kölsch',
 				'ku' => 'Koerdysk',
 				'kum' => 'Koemuks',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'ky' => 'Kirgizysk',
 				'la' => 'Latyn',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luxemburgs',
 				'lez' => 'Lezgysk',
 				'lg' => 'Ganda',
 				'li' => 'Limburgs',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Laotiaansk',
 				'lol' => 'Mongo',
 				'loz' => 'Lozi',
 				'lt' => 'Litouws',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Lushai',
 				'luy' => 'Luyia',
 				'lv' => 'Letlâns',
 				'mad' => 'Madurees',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makassaars',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasysk',
 				'mga' => 'Middeliers',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallees',
 				'mi' => 'Maori',
 				'mic' => 'Mi’kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonysk',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongools',
 				'mnc' => 'Mantsjoe',
 				'mni' => 'Manipoeri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Maleis',
 				'mt' => 'Maltees',
 				'mua' => 'Mundang',
 				'mul' => 'Meardere talen',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandees',
 				'mwr' => 'Marwari',
 				'my' => 'Birmees',
 				'mye' => 'Myene',
 				'myv' => 'Erzja',
 				'na' => 'Nauruaansk',
 				'nap' => 'Napolitaansk',
 				'naq' => 'Nama',
 				'nb' => 'Noors - Bokmål',
 				'nd' => 'Noard-Ndbele',
 				'nds' => 'Laagduits',
 				'ne' => 'Nepalees',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niueaansk',
 				'nl' => 'Nederlânsk',
 				'nl_BE' => 'Vlaams',
 				'nmg' => 'Ngumba',
 				'nn' => 'Noors - Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Noors',
 				'nog' => 'Nogai',
 				'non' => 'Aldnoarsk',
 				'nqo' => 'N’ko',
 				'nr' => 'Sûd-Ndbele',
 				'nso' => 'Noard-Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Klassiek Newari',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Occitaansk',
 				'oj' => 'Ojibwa',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetysk',
 				'osa' => 'Osage',
 				'ota' => 'Ottomaansk-Turks',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pal' => 'Pahlavi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiaments',
 				'pau' => 'Palauaansk',
 				'peo' => 'Aldperzysk',
 				'phn' => 'Foenisysk',
 				'pi' => 'Pali',
 				'pl' => 'Poalsk',
 				'pon' => 'Pohnpeiaansk',
 				'pro' => 'Aldprovençaals',
 				'ps' => 'Pasjtoe',
 				'ps@alt=variant' => 'Pashto',
 				'pt' => 'Portugeesk',
 				'pt_BR' => 'Brazyljaansk Portugees',
 				'pt_PT' => 'Europees Portugees',
 				'qu' => 'Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rm' => 'Reto-Romaansk',
 				'rn' => 'Kirundi',
 				'ro' => 'Roemeensk',
 				'ro_MD' => 'Moldavysk',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'ru' => 'Russysk',
 				'rup' => 'Aromaniaansk',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskriet',
 				'sad' => 'Sandawe',
 				'sah' => 'Jakoets',
 				'sam' => 'Samaritaansk-Arameesk',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinysk',
 				'scn' => 'Siciliaansk',
 				'sco' => 'Schots',
 				'sd' => 'Sindhi',
 				'se' => 'Noard-Samysk',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sel' => 'Selkup',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Aldyrsk',
 				'sh' => 'Servokroatysk',
 				'shi' => 'Tashelhiyt',
 				'shn' => 'Shan',
 				'shu' => 'Tsjadysk Arabysk',
 				'si' => 'Singalees',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowaaks',
 				'sl' => 'Sloveensk',
 				'sm' => 'Samoaansk',
 				'sma' => 'Sûd-Samysk',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalysk',
 				'sog' => 'Sogdysk',
 				'sq' => 'Albaneesk',
 				'sr' => 'Servysk',
 				'srn' => 'Sranantongo',
 				'srr' => 'Serer',
 				'ss' => 'Swazi',
 				'ssy' => 'Saho',
 				'st' => 'Sûd-Sotho',
 				'su' => 'Soendaneesk',
 				'suk' => 'Sukuma',
 				'sus' => 'Soesoe',
 				'sux' => 'Soemerysk',
 				'sv' => 'Zweeds',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Congo Swahili',
 				'swb' => 'Shimaore',
 				'syc' => 'Klassiek Syrysk',
 				'syr' => 'Syrysk',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetun',
 				'tg' => 'Tadzjieks',
 				'th' => 'Thais',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmeens',
 				'tkl' => 'Tokelaus',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tongaansk',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turks',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tataars',
 				'tum' => 'Toemboeka',
 				'tvl' => 'Tuvaluaansk',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitysk',
 				'tyv' => 'Tuvinysk',
 				'tzm' => 'Tamazight (Sintraal-Marokko)',
 				'udm' => 'Oedmoerts',
 				'ug' => 'Oeigoers',
 				'uga' => 'Oegaritysk',
 				'uk' => 'Oekraïens',
 				'umb' => 'Umbundu',
 				'und' => 'Onbekende taal',
 				'ur' => 'Urdu',
 				'uz' => 'Oezbeeks',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Vietnamees',
 				'vo' => 'Volapük',
 				'vot' => 'Votysk',
 				'vun' => 'Vunjo',
 				'wa' => 'Waals',
 				'wae' => 'Walser',
 				'wal' => 'Walamo',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wo' => 'Wolof',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapees',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddysk',
 				'yo' => 'Yoruba',
 				'yue' => 'Kantoneesk',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotec',
 				'zbl' => 'Blissymbolen',
 				'zen' => 'Zenaga',
 				'zgh' => 'Standert Marokkaanske Tamazight',
 				'zh' => 'Sineesk',
 				'zh_Hans' => 'Ferienfâldich Sineesk',
 				'zh_Hant' => 'Tradisjoneel Sineesk',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Gjin linguïstyske ynhâld',
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
			'Afak' => 'Defaka',
 			'Arab' => 'Arabysk',
 			'Arab@alt=variant' => 'Perso-Arabysk',
 			'Armi' => 'Keizerlijk Aramees',
 			'Armn' => 'Armeens',
 			'Avst' => 'Avestaansk',
 			'Bali' => 'Balineesk',
 			'Bamu' => 'Bamoun',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengalees',
 			'Blis' => 'Blissymbolen',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Bugineesk',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Verenigde Canadese Aboriginal-symbolen',
 			'Cari' => 'Karysk',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptysk',
 			'Cprt' => 'Syprysk',
 			'Cyrl' => 'Syrillysk',
 			'Cyrs' => 'Aldkerkslavysk Syrillysk',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployan snelschrift',
 			'Egyd' => 'Egyptysk demotysk',
 			'Egyh' => 'Egyptysk hiëratysk',
 			'Egyp' => 'Egyptyske hiërogliefen',
 			'Ethi' => 'Ethiopysk',
 			'Geok' => 'Georgysk Khutsuri',
 			'Geor' => 'Georgysk',
 			'Glag' => 'Glagolitysk',
 			'Goth' => 'Gothysk',
 			'Gran' => 'Grantha',
 			'Grek' => 'Grieks',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Ferienfâldigd',
 			'Hans@alt=stand-alone' => 'Ferienfâldigd Sineesk',
 			'Hant' => 'Traditjoneel',
 			'Hant@alt=stand-alone' => 'Traditjoneel Sineesk',
 			'Hebr' => 'Hebreeuwsk',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anatolyske hiërogliefen',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana of Hiragana',
 			'Hung' => 'Aldhongaars',
 			'Inds' => 'Indus',
 			'Ital' => 'Ald-italysk',
 			'Jamo' => 'Jamo',
 			'Java' => 'Javaansk',
 			'Jpan' => 'Japans',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreaansk',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latf' => 'Gotysk Latyn',
 			'Latg' => 'Gaelysk Latyn',
 			'Latn' => 'Latyn',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Lineair A',
 			'Linb' => 'Lineair B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycysk',
 			'Lydi' => 'Lydysk',
 			'Mand' => 'Mandaeans',
 			'Mani' => 'Manicheaansk',
 			'Maya' => 'Mayahiërogliefen',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitysk cursief',
 			'Mero' => 'Meroïtysk',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongools',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei',
 			'Mymr' => 'Myanmar',
 			'Narb' => 'Ald Noard-Arabysk',
 			'Nbat' => 'Nabateaansk',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Odia',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyreens',
 			'Perm' => 'Aldpermysk',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inscriptioneel Pahlavi',
 			'Phlp' => 'Psalmen Pahlavi',
 			'Phlv' => 'Boek Pahlavi',
 			'Phnx' => 'Foenicysk',
 			'Plrd' => 'Pollard-fonetysk',
 			'Prti' => 'Inscriptioneel Parthysk',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runic',
 			'Samr' => 'Samaritaansk',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Ald Sûd-Arabysk',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shavian',
 			'Shrd' => 'Sharada',
 			'Sind' => 'Sindhi',
 			'Sinh' => 'Sinhala',
 			'Sora' => 'Sora Sompeng',
 			'Sund' => 'Soendaneesk',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syriac',
 			'Syre' => 'Estrangelo Arameesk',
 			'Syrj' => 'West-Arameesk',
 			'Syrn' => 'East-Arameesk',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Nij Tai Lue',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thais',
 			'Tibt' => 'Tibetaansk',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritysk',
 			'Vaii' => 'Vai',
 			'Visp' => 'Sichtbere spraak',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Aldperzysk',
 			'Xsux' => 'Sumero-Akkadian Cuneiform',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Oergeërfd',
 			'Zmth' => 'Wiskundige notatie',
 			'Zsym' => 'Symbolen',
 			'Zxxx' => 'Ongeschreven',
 			'Zyyy' => 'Algemeen',
 			'Zzzz' => 'Onbekend schriftsysteem',

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
			'001' => 'Wrâld',
 			'002' => 'Afrika',
 			'003' => 'Noard-Amerika',
 			'005' => 'Sûd-Amerika',
 			'009' => 'Oceanië',
 			'011' => 'West-Afrika',
 			'013' => 'Midden-Amerika',
 			'014' => 'East-Afrika',
 			'015' => 'Noard-Afrika',
 			'017' => 'Sintraal-Afrika',
 			'018' => 'Sûdelijk Afrika',
 			'019' => 'Amerika',
 			'021' => 'Noardlik Amerika',
 			'029' => 'Karibysk gebiet',
 			'030' => 'East-Azië',
 			'034' => 'Sûd-Azië',
 			'035' => 'Sûdoost-Azië',
 			'039' => 'Sûd-Europa',
 			'053' => 'Australazië',
 			'054' => 'Melanesië',
 			'057' => 'Micronesyske regio',
 			'061' => 'Polynesië',
 			'142' => 'Azië',
 			'143' => 'Sintraal-Azië',
 			'145' => 'West-Azië',
 			'150' => 'Europa',
 			'151' => 'East-Europa',
 			'154' => 'Noard-Europa',
 			'155' => 'West-Europa',
 			'419' => 'Latynsk-Amearika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Verenigde Arabyske Emiraten',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua en Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanië',
 			'AM' => 'Armenië',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentinië',
 			'AS' => 'Amerikaansk Samoa',
 			'AT' => 'Eastenryk',
 			'AU' => 'Australië',
 			'AW' => 'Aruba',
 			'AX' => 'Ålân',
 			'AZ' => 'Azerbeidzjan',
 			'BA' => 'Bosnië en Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'België',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarije',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibysk Nederlân',
 			'BR' => 'Brazilië',
 			'BS' => 'Bahama’s',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouveteilân',
 			'BW' => 'Botswana',
 			'BY' => 'Wit-Ruslân',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Kokosilanen',
 			'CD' => 'Congo-Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Sintraal-Afrikaanske Republyk',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'Congo (Republyk)',
 			'CH' => 'Switserlân',
 			'CI' => 'Ivoorkust',
 			'CK' => 'Cookeilannen',
 			'CL' => 'Chili',
 			'CM' => 'Kameroen',
 			'CN' => 'Sina',
 			'CO' => 'Kolombia',
 			'CP' => 'Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kaapverdië',
 			'CW' => 'Curaçao',
 			'CX' => 'Krysteilan',
 			'CY' => 'Syprus',
 			'CZ' => 'Tsjechje',
 			'DE' => 'Dútslân',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denemarken',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikaanske Republyk',
 			'DZ' => 'Algerije',
 			'EA' => 'Ceuta en Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estlân',
 			'EG' => 'Egypte',
 			'EH' => 'Westelijke Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanje',
 			'ET' => 'Ethiopië',
 			'EU' => 'Europeeske Unie',
 			'FI' => 'Finlân',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklâneilannen',
 			'FK@alt=variant' => 'Falklâneilannen (Islas Malvinas)',
 			'FM' => 'Micronesië',
 			'FO' => 'Faeröer',
 			'FR' => 'Frankrijk',
 			'GA' => 'Gabon',
 			'GB' => 'Verenigd Koninkrijk',
 			'GB@alt=short' => 'VK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgië',
 			'GF' => 'Frans-Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grienlân',
 			'GM' => 'Gambia',
 			'GN' => 'Guinee',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatoriaal-Guinea',
 			'GR' => 'Grikelân',
 			'GS' => 'Sûd-Georgia en Sûdlike Sandwicheilannen',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinee-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong SAR van Sina',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard- en McDonaldeilannen',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatië',
 			'HT' => 'Haïti',
 			'HU' => 'Hongarije',
 			'IC' => 'Kanaryske Eilânnen',
 			'ID' => 'Yndonesië',
 			'IE' => 'Ierlân',
 			'IL' => 'Israël',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Britse Gebieden yn de Indyske Oseaan',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Yslân',
 			'IT' => 'Italië',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordanië',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizië',
 			'KH' => 'Cambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoren',
 			'KN' => 'Saint Kitts en Nevis',
 			'KP' => 'Noard-Korea',
 			'KR' => 'Sûd-Korea',
 			'KW' => 'Koeweit',
 			'KY' => 'Caymaneilannen',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litouwen',
 			'LU' => 'Luxemburg',
 			'LV' => 'Letlân',
 			'LY' => 'Libië',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavië',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madeiaskar',
 			'MH' => 'Marshalleilannen',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birma)',
 			'MN' => 'Mongolië',
 			'MO' => 'Macao SAR van Sina',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Noardlike Marianeneilannen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritanië',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiven',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Maleisië',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibië',
 			'NC' => 'Nij-Caledonië',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkeilân',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederlân',
 			'NO' => 'Noarwegen',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nij-Seelân',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frans-Polynesië',
 			'PG' => 'Papoea-Nij-Guinea',
 			'PH' => 'Filipijnen',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint-Pierre en Miquelon',
 			'PN' => 'Pitcairneilannen',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestynske gebieten',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oerig Oceanië',
 			'RE' => 'Réunion',
 			'RO' => 'Roemenië',
 			'RS' => 'Servië',
 			'RU' => 'Ruslân',
 			'RW' => 'Rwanda',
 			'SA' => 'Saoedi-Arabië',
 			'SB' => 'Salomonseilannen',
 			'SC' => 'Seychellen',
 			'SD' => 'Soedan',
 			'SE' => 'Zweden',
 			'SG' => 'Singapore',
 			'SH' => 'Sint-Helena',
 			'SI' => 'Slovenië',
 			'SJ' => 'Spitsbergen en Jan Mayen',
 			'SK' => 'Slowakije',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalië',
 			'SR' => 'Suriname',
 			'SS' => 'Sûd-Soedan',
 			'ST' => 'Sao Tomé en Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Syrië',
 			'SZ' => 'Swazilân',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- en Caicoseilannen',
 			'TD' => 'Tsjaad',
 			'TF' => 'Franse Gebieden in de zuidelijke Indyske Oseaan',
 			'TG' => 'Togo',
 			'TH' => 'Thailân',
 			'TJ' => 'Tadzjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'East-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesië',
 			'TO' => 'Tonga',
 			'TR' => 'Turkije',
 			'TT' => 'Trinidad en Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Oekraïne',
 			'UG' => 'Oeganda',
 			'UM' => 'Lyts ôflizzen eilannen fan de Ferienigde Staten',
 			'US' => 'Ferienigde Staten',
 			'US@alt=short' => 'VS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Oezbekistan',
 			'VA' => 'Vaticaanstêd',
 			'VC' => 'Saint Vincent en de Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Britse Maagdeneilannen',
 			'VI' => 'Amerikaanske Maagdeneilannen',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis en Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sûd-Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Unbekend gebiet',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Tradisjonele Dútske stavering',
 			'1994' => 'Standerdisearre Resiaansk stavering',
 			'1996' => 'Dútske stavering van 1996',
 			'1606NICT' => 'Let Middelfrânske oant 1606',
 			'1694ACAD' => 'Betiit modern Frâns',
 			'1959ACAD' => 'Akademysk',
 			'ALALC97' => 'Romanisering ALA-LC, editie 1997',
 			'ALUKU' => 'Aloekoe dialekt',
 			'AREVELA' => 'East-Armeensk',
 			'AREVMDA' => 'West-Armeensk',
 			'BAKU1926' => 'Eenvormig Turkse Latynse alfabet',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Biskajaansk',
 			'BISKE' => 'San Giorgio/Bila-dialekt',
 			'BOONT' => 'Boontling',
 			'DAJNKO' => 'Dajnko-alfabet',
 			'EMODENG' => 'Vroegmodern Engels',
 			'FONIPA' => 'Internationaal Fonetysk Alfabet',
 			'FONUPA' => 'Oeralysk Fonetysk Alfabet',
 			'FONXSAMP' => 'Fonxsamp',
 			'HEPBURN' => 'Hepburn-romanisering',
 			'HOGNORSK' => 'Hoognoors',
 			'ITIHASA' => 'Itihasa',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Algemiene stavering',
 			'KSCOR' => 'Standert stavering',
 			'LAUKIKA' => 'Laukika',
 			'LIPAW' => 'Het Lipovaz-dialekt van het Resiaansk',
 			'LUNA1918' => 'Luna1918',
 			'MONOTON' => 'Monotonaal',
 			'NDYUKA' => 'Ndyuka',
 			'NEDIS' => 'Natisone-dialekt',
 			'NJIVA' => 'Gniva/Njiva-dialekt',
 			'NULIK' => 'Modern Volapük',
 			'OSOJS' => 'Oseacco/Osojane-dialekt',
 			'PAMAKA' => 'Pamaka',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Polytonaal',
 			'POSIX' => 'Computer',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Wizige stavering',
 			'RIGIK' => 'Klassiek Volapük',
 			'ROZAJ' => 'Resiaansk',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schots standert-Engels',
 			'SCOUSE' => 'Liverpools (Scouse)',
 			'SOLBA' => 'Stolvizza/Solbica-dialekt',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilvan',
 			'SUTSILV' => 'Sutsilvan',
 			'TARASK' => 'Taraskievica-stavering',
 			'UCCOR' => 'Ienfoarmige stavering',
 			'UCRCOR' => 'Ienfoarmige stavering (hersjoen)',
 			'ULSTER' => 'Ulster',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valenciaansk',
 			'VALLADER' => 'Vallader',
 			'WADEGILE' => 'Wade-Giles-romanisering',

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
 			'colalternate' => 'sortearje van symbolen negeren',
 			'colbackwards' => 'Omgekeerd sortearje op accenten',
 			'colcasefirst' => 'Yndiele op haad/lytse letters',
 			'colcaselevel' => 'Haadlettergefoelich sortearje',
 			'collation' => 'Sortearfolgorde',
 			'colnormalization' => 'Genormaliseerd sortearje',
 			'colnumeric' => 'Numeriek sortearje',
 			'colstrength' => 'Sorteervoorrang',
 			'currency' => 'Valuta',
 			'numbers' => 'Sifers',
 			'timezone' => 'Tijdzone',
 			'va' => 'Landvariant',
 			'x' => 'Privégebruik',

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
 				'buddhist' => q{Boeddhistyske kalinder},
 				'chinese' => q{Sineeske kalinder},
 				'coptic' => q{Koptyske kalinder},
 				'ethiopic' => q{Ethiopyske kalinder},
 				'ethiopic-amete-alem' => q{Ethiopyske Amete Alem-kalinder},
 				'gregorian' => q{Gregoriaanske kalinder},
 				'hebrew' => q{Hebreeuwse kalinder},
 				'indian' => q{Indiase natjonale kalinder},
 				'islamic' => q{Islamityske kalinder},
 				'islamic-civil' => q{Islamityske kalinder (cyclysk)},
 				'japanese' => q{Japanske kalinder},
 				'persian' => q{Perzyske kalinder},
 				'roc' => q{Kalinder fan de Sineeske Republyk},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Symbolen sortearje},
 				'shifted' => q{Sortearje zonder symbolen},
 			},
 			'colbackwards' => {
 				'no' => q{Normaal sortearje neffens accenten},
 				'yes' => q{Omgekeerd sortearje op accenten},
 			},
 			'colcasefirst' => {
 				'lower' => q{Eerst sortearje op kleine letters},
 				'no' => q{Sortearfolgorde algemien haadletterbrûkme},
 				'upper' => q{Eerst sortearje op haadletters},
 			},
 			'colcaselevel' => {
 				'no' => q{Net haadlettergefoelich sortearje},
 				'yes' => q{Hoofdlettergevoelig sortearje},
 			},
 			'collation' => {
 				'big5han' => q{Tradisjonele-Sineeske soartear oarder - Big5},
 				'dictionary' => q{Wurdboeksortearfolgorde},
 				'ducet' => q{Standert Unikoade-sortearfolgorde},
 				'gb2312han' => q{Ferienfâldigde-Sineeske sortearfolgorde - GB2312},
 				'phonebook' => q{Telefoanboeksortearfolgorde},
 				'phonetic' => q{Fonetyske sortearfolgorde},
 				'pinyin' => q{Pinyinvolgorde},
 				'reformed' => q{Hersjoen sortearfolgorde},
 				'search' => q{Algemien sykje},
 				'searchjl' => q{Sykje op earste Hangul-medeklinker},
 				'standard' => q{standert sortearfolgorde},
 				'stroke' => q{Streeksortearfolgorde},
 				'traditional' => q{Tradisjonele sortearfolgorde},
 				'unihan' => q{Sortearfolgorde radicalen/strepen},
 			},
 			'colnormalization' => {
 				'no' => q{Sûnder normalisaasje sortearje},
 				'yes' => q{Unicode genormaliseerd sortearje},
 			},
 			'colnumeric' => {
 				'no' => q{Sifers apart sortearje},
 				'yes' => q{Sifers numeryk sortearje},
 			},
 			'colstrength' => {
 				'identical' => q{Alles sortearje},
 				'primary' => q{Allime sortearje neffens letters},
 				'quaternary' => q{sortearje neffens aksinten/haadletterbrûkme/breedte/Kana},
 				'secondary' => q{Sortearje op accenten},
 				'tertiary' => q{sortearje neffens aksinten/haadletterbrûkme/breedte},
 			},
 			'd0' => {
 				'fwidth' => q{Volledige breedte},
 				'hwidth' => q{Halve breedte},
 				'npinyin' => q{Numeriek},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'numbers' => {
 				'arab' => q{Arabysk-Indyske sifers},
 				'arabext' => q{Utwreide Arabysk-Indyske sifers},
 				'armn' => q{Armeense sifers},
 				'armnlow' => q{Kleine Armeense sifers},
 				'bali' => q{Balinese sifers},
 				'beng' => q{Bengaalse sifers},
 				'deva' => q{Devanagari sifers},
 				'ethi' => q{Ethiopyske sifers},
 				'finance' => q{Finansjele sifers},
 				'fullwide' => q{sifers met volledige breedte},
 				'geor' => q{Georgyske sifers},
 				'grek' => q{Griekse sifers},
 				'greklow' => q{Kleine Griekse sifers},
 				'gujr' => q{Gujarati sifers},
 				'guru' => q{Gurmukhi sifers},
 				'hanidec' => q{Sineeske desimale tallen},
 				'hans' => q{Ferienfâldigde Sineeske sifers},
 				'hansfin' => q{Ferienfâldigde Sineeske finansjele sifers},
 				'hant' => q{Traditjonele Sineeske sifers},
 				'hantfin' => q{Traditjonele Sineeske finansjele sifers},
 				'hebr' => q{Hebreeuwse sifers},
 				'java' => q{Javaanske sifers},
 				'jpan' => q{Japanske sifers},
 				'jpanfin' => q{Japanske finansjele sifers},
 				'khmr' => q{Khmer sifers},
 				'knda' => q{Kannada sifers},
 				'laoo' => q{Laotiaanske sifers},
 				'latn' => q{Westerse sifers},
 				'mlym' => q{Malayalam sifers},
 				'mong' => q{Mongoolse sifers},
 				'mymr' => q{Myanmarese sifers},
 				'native' => q{Binnenlânse sifers},
 				'orya' => q{Oriya sifers},
 				'roman' => q{Romeinske sifers},
 				'romanlow' => q{Lytse Romeinske sifers},
 				'taml' => q{Tradisjonele Tamil sifers},
 				'tamldec' => q{Tamil sifers},
 				'telu' => q{Telugu sifers},
 				'thai' => q{Thaise sifers},
 				'tibt' => q{Tibetaanske sifers},
 				'traditional' => q{Tradisjonele sifers},
 				'vaii' => q{Vai-sifers},
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
			'metric' => q{Metriek},
 			'UK' => q{Brits},
 			'US' => q{Amerikaansk},

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
 			'script' => 'Skrift: {0}',
 			'region' => 'Regio: {0}',

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
			auxiliary => qr{[æ ò ù]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Z'],
			main => qr{[aáàâä b c d eéèêë f g h iíïyý {ij}{íj́} j k l m n oóôö p r s t uúûü v w z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} G-kracht),
						'other' => q({0} G-krachten),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} G-kracht),
						'other' => q({0} G-krachten),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} boogminút),
						'other' => q({0} boogminuten),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} boogminút),
						'other' => q({0} boogminuten),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} boogsekonde),
						'other' => q({0} boogsekonden),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} boogsekonde),
						'other' => q({0} boogsekonden),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} booggraad),
						'other' => q({0} booggraden),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} booggraad),
						'other' => q({0} booggraden),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hektare),
						'other' => q({0} hektare),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hektare),
						'other' => q({0} hektare),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} fjouwerkante foet),
						'other' => q({0} fjouwerkante foet),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} fjouwerkante foet),
						'other' => q({0} fjouwerkante foet),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} fjouwerkante kilometer),
						'other' => q({0} fjouwerkante kilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} fjouwerkante kilometer),
						'other' => q({0} fjouwerkante kilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} fjouwerkante meter),
						'other' => q({0} fjouwerkante meter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} fjouwerkante meter),
						'other' => q({0} fjouwerkante meter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} fjouwerkante myl),
						'other' => q({0} fjouwerkante myl),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} fjouwerkante myl),
						'other' => q({0} fjouwerkante myl),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} millisekonde),
						'other' => q({0} millisekonden),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} millisekonde),
						'other' => q({0} millisekonden),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} minút),
						'other' => q({0} minuten),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} minút),
						'other' => q({0} minuten),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} moanne),
						'other' => q({0} moanneen),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} moanne),
						'other' => q({0} moanneen),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} sekonde),
						'other' => q({0} sekonden),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} sekonde),
						'other' => q({0} sekonden),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} wike),
						'other' => q({0} wiken),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} wike),
						'other' => q({0} wiken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} jier),
						'other' => q({0} jier),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} jier),
						'other' => q({0} jier),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} sentimeter),
						'other' => q({0} sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} sentimeter),
						'other' => q({0} sentimeter),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} foet),
						'other' => q({0} foet),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} foet),
						'other' => q({0} foet),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} tomme),
						'other' => q({0} tommen),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} tomme),
						'other' => q({0} tommen),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} ljochtjier),
						'other' => q({0} ljochtjier),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} ljochtjier),
						'other' => q({0} ljochtjier),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} meter),
						'other' => q({0} meter),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} meter),
						'other' => q({0} meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} myl),
						'other' => q({0} myl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
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
					'power-horsepower' => {
						'one' => q({0} hynstekrêft),
						'other' => q({0} hynstekrêften),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hynstekrêft),
						'other' => q({0} hynstekrêften),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
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
					'pressure-hectopascal' => {
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} kilometer de oere),
						'other' => q({0} kilometer de oere),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} kilometer de oere),
						'other' => q({0} kilometer de oere),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} meter de sekonde),
						'other' => q({0} meter de sekonde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} meter de sekonde),
						'other' => q({0} meter de sekonde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} myl de oere),
						'other' => q({0} myl de oere),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} myl de oere),
						'other' => q({0} myl de oere),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} graad Celsius),
						'other' => q({0} graden Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} graad Celsius),
						'other' => q({0} graden Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} graden Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} graden Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} kubike kilometer),
						'other' => q({0} kubike kilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} kubike kilometer),
						'other' => q({0} kubike kilometer),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} kubike myl),
						'other' => q({0} kubike myl),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} kubike myl),
						'other' => q({0} kubike myl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} liter),
						'other' => q({0} liter),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} liter),
						'other' => q({0} liter),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} u),
						'other' => q({0} u),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} u),
						'other' => q({0} u),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} w),
						'other' => q({0} w),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} w),
						'other' => q({0} w),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}"),
						'other' => q({0}"),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}"),
						'other' => q({0}"),
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
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G-krachten),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G-krachten),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(boogminuten),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(boogminuten),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(boogsekonden),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(boogsekonden),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(booggraden),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(booggraden),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ares),
						'one' => q({0} are),
						'other' => q({0} ares),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ares),
						'one' => q({0} are),
						'other' => q({0} ares),
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
						'name' => q(fjouwerkante foet),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fjouwerkante foet),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(fjouwerkante kilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(fjouwerkante kilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(fjouwerkante meter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(fjouwerkante meter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(fjouwerkante myl),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(fjouwerkante myl),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(deien),
						'one' => q({0} dei),
						'other' => q({0} deien),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(deien),
						'one' => q({0} dei),
						'other' => q({0} deien),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oere),
						'one' => q({0} oere),
						'other' => q({0} oere),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oere),
						'one' => q({0} oere),
						'other' => q({0} oere),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekonden),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekonden),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuten),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuten),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(moanneen),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(moanneen),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekonden),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekonden),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(wiken),
						'one' => q({0} wk),
						'other' => q({0} wkn),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(wiken),
						'one' => q({0} wk),
						'other' => q({0} wkn),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(jier),
						'one' => q({0} jr),
						'other' => q({0} jr),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jier),
						'one' => q({0} jr),
						'other' => q({0} jr),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(foet),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(foet),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tommen),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommen),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ljochtjier),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ljochtjier),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(myl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(myl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeter),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yards),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yards),
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
					'power-horsepower' => {
						'name' => q(hynstekrêften),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hynstekrêften),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometer de oere),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer de oere),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter de sekonde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter de sekonde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(myl de oere),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(myl de oere),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(graden Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graden Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graden Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graden Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubike kilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubike kilometer),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubike myl),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubike myl),
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
			'group' => q(.),
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
					'one' => '0 tûzen',
					'other' => '0 tûzen',
				},
				'10000' => {
					'one' => '00 tûzen',
					'other' => '00 tûzen',
				},
				'100000' => {
					'one' => '000 tûzen',
					'other' => '000 tûzen',
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
				'1000000' => {
					'one' => '0 mln'.'',
					'other' => '0 mln'.'',
				},
				'10000000' => {
					'one' => '00 mln'.'',
					'other' => '00 mln'.'',
				},
				'100000000' => {
					'one' => '000 mln'.'',
					'other' => '000 mln'.'',
				},
				'1000000000' => {
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'one' => '0 bln'.'',
					'other' => '0 bln'.'',
				},
				'10000000000000' => {
					'one' => '00 bln'.'',
					'other' => '00 bln'.'',
				},
				'100000000000000' => {
					'one' => '000 bln'.'',
					'other' => '000 bln'.'',
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
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ #,##0.00-',
						'positive' => '¤ #,##0.00',
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
				'currency' => q(Andorrese peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Verenigde Arabyske Emiraten-dirham),
				'one' => q(VAE-dirham),
				'other' => q(VAE-dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani \(1927–2002\)),
				'one' => q(Afghani \(AFA\)),
				'other' => q(Afghani \(AFA\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghaanske afghani),
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
				'currency' => q(Nederlânsk-Antilliaanske gûne),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolese kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolese kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolese nieuwe kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolese kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentynske austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentynske peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentynske peso \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentynske peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentynske peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Eastenrykse schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australyske dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Arubaanske gulden),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbeidzjaanske manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbeidzjaanske manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnyske dinar),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnyske convertibele mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Nije Bosnyske dinar \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadaanske dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bengalese taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgyske frank \(convertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgyske frank),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgyske frank \(finansjeel\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgaarse harde lev),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bulgaarse socialistyske lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaarse lev),
				'one' => q(Bulgaarse lev),
				'other' => q(Bulgaarse leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgaarse lev \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreinse dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundese frank),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Bruneise dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviaanske boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviaanske boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliviaanske peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviaanske mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Braziliaanske cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Braziliaanske cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Braziliaanske cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Braziliaanske real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Braziliaanske cruzado novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Braziliaanske cruzeiro),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Braziliaanske cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamaanske dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutaanske ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Birmese kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswaanske pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Wit-Russyske nieuwe roebel \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Wit-Russyske roebel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Wit-Russyske roebel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belizaanske dollar),
			},
		},
		'CAD' => {
			symbol => 'C$',
			display_name => {
				'currency' => q(Canadese dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese frank),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Zwitserse frank),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franc),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Sileenske escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Sileenske unidades de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Sileenske peso),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Sineeske yuan renminbi),
				'one' => q(Sineeske renminbi),
				'other' => q(Sineeske renminbi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolombiaanske peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costaricaanske colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Alde Servyske dinar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tsjechoslowaakse harde koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubaanske convertibele peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubaanske peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kaapverdyske escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Cyprysk pûn),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tsjechyske kroon),
				'one' => q(Tsjechyske kroon),
				'other' => q(Tsjechyske kronen),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(East-Dútske ostmark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Dútske mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutiaanske frank),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Deenske kroon),
				'one' => q(Deenske kroon),
				'other' => q(Deenske kronen),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikaanske peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerynske dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadoraanske sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ecuadoraanske unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estlânske kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptysk pûn),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrese nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spaanske peseta \(account A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spaanske peseta \(convertibele account\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spaanske peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopyske birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finse markka),
			},
		},
		'FJD' => {
			symbol => 'FJ$',
			display_name => {
				'currency' => q(Fiji-dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklâneilânske pûn),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franske franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Brits pûn),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgyske kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgyske lari),
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
				'currency' => q(Gibraltarees pûn),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiaanske dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinese franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinese syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Equatoriaal-Guinese ekwele guineana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Grykse drachme),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalteekse quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugees-Guinese escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinee-Bissause peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyaanske dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkongske dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondurese lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroatyske dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatyske kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haïtiaanske gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hongaarse forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesyske roepia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Ierske pûn),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israëlysk pûn),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israëlyske nieuwe shekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indiase roepie),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraakse dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iraanske rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Yslânske kroon),
				'one' => q(Yslânske kroon),
				'other' => q(Yslânske kronen),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiaanske lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaikaanske dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaanske dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanse yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniaanske shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgizyske som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodjaanske riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komorese frank),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Noard-Koreaanske won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Sûd-Koreaanske hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Alde Sûd-Koreaanske won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Sûd-Koreaanske won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Koeweitse dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Caymaneilânske dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazachstaanske tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotiaanske kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libaneeske pûn),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankaanske roepie),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiaanske dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesothaanske loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litouwse litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litouwse talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Lúksemboargske convertibele franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Lúksemboargske frank),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Lúksemboargske finansjele franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Letse lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Letse roebel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyske dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkaanske dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkaanske franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegaskyske frank),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldavyske cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldavyske leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagassyske ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Malagassyske franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonyske denar),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Macedonyske denar \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malinese franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmarese kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoalske tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macause pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritaanske ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritaanske ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltese lire),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltees pûn),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritiaanske roepie),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivyske rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawyske kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksikaanske peso),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksikaanske sulveren peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Meksikaanske unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Maleisyske ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambikaanske escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Alde Mozambikaanske metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambikaanske metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibyske dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriaanske naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguaanske córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguaanske córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Nederlânske gûne),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Noarske kroon),
				'one' => q(Noarske kroon),
				'other' => q(Noarske kronen),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese roepie),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Nij-Seelânske dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omaanske rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamese balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruaanske inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruaanske sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruaanske sol \(1863–1985\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papuaanske kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Filipynske peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistaanske roepie),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poalske zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poalske zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugeeske escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayaanske guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katarese rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesyske dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Alde Roemeenske leu),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Roemeenske leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Servyske dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russyske roebel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russyske roebel \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandese frank),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saoedi-Arabyske riyal),
			},
		},
		'SBD' => {
			symbol => 'SI$',
			display_name => {
				'currency' => q(Salomon-dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychelse roepie),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Soedaneeske dinar),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Soedaneeske pûn),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Soedaneeske pûn \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweedske kroon),
				'one' => q(Sweedske kroon),
				'other' => q(Sweedske kronen),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singaporese dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sint-Heleenske pûn),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloveenske tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowaakse koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierraleoonse leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierraleoonse leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalyske shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinaamske dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinaamske gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Sûd-Soedaneeske pûn),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Santomese dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Santomese dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovjet-roebel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadoraanske colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrysk pûn),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazyske lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thaise baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadzjikistaanske roebel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadzjikistaanske somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmeense manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmeense manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunesyske dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaanske paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorese escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkse lire),
				'one' => q(Alde Turkse lira),
				'other' => q(Alde Turkse lira),
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
			display_name => {
				'currency' => q(Nije Taiwanese dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniaanske shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Oekraïense hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Oekraïense karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Oegandese shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Oegandese shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Amerikaanske dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Amerikaanske dollar \(folgjende dei\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Amerikaanske dollar \(zelfde dei\)),
				'one' => q(Amerikaanske dollar \(Selfde dei\)),
				'other' => q(Amerikaanske dollar \(Selfde dei\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayaanske peso en geïndexeerde eenheden),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayaanske peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayaanske peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Oezbekistaanske sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Fenezolaanske bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Fenezolaanske bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Fenezolaanske bolivar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Fietnameeske dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Alde Fietnameeske dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatuaanske vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoaanske tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-frank),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Sulver),
				'one' => q(Troy ounce sulver),
				'other' => q(Troy ounces sulver),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Goud),
				'one' => q(Troy ounce goud),
				'other' => q(Troy ounces goud),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europeeske gearfoege ienheid),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europeeske monetaire ienheid),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europeeske rekkenienheid \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europeeske rekkenienheid \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(East-Karibyske dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Special Drawing Rights),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(European Currency Unit),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franse gouden franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franse UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-franc BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
				'one' => q(Troy ounce palladium),
				'other' => q(Troy ounces palladium),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP-franc),
				'one' => q(CFP-franc),
				'other' => q(CFP-frank),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platina),
				'one' => q(Troy ounce platina),
				'other' => q(Troy ounces platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fondsen),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Valutacode voor testdoeleinden),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB-rekkenienheid),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Unbekende muntienheid),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenityske dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemenityske rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Joegoslavyske harde dinar),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Joegoslavyske noviy-dinar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Joegoslavyske convertibele dinar),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Joegoslavyske herfoarme dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Sûd-Afrikaanske rand \(finansjeel\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Sûd-Afrikaanske rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Sambiaanske kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Sambiaanske kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Saïreeske nije Saïre),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Saïreeske Saïre),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabwaanske dollar),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Simbabwaanske dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Simbabwaanske dollar \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'Tut',
							'Babah',
							'Hatur',
							'Kiyahk',
							'Tubah',
							'Amshir',
							'Baramhat',
							'Baramundah',
							'Bashans',
							'Ba’unah',
							'Abib',
							'Misra',
							'Nasi'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					wide => {
						nonleap => [
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahsas',
							'T’er',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Genbot',
							'Säne',
							'Hamle',
							'Nähase',
							'Pagumän'
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
							'Mrt',
							'Apr',
							'Mai',
							'Jun',
							'Jul',
							'Aug',
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
							'Jannewaris',
							'Febrewaris',
							'Maart',
							'April',
							'Maaie',
							'Juny',
							'July',
							'Augustus',
							'Septimber',
							'Oktober',
							'Novimber',
							'Desimber'
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
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'Tisjrie',
							'Chesjwan',
							'Kislev',
							'Tevet',
							'Sjevat',
							'Adar A',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tammoez',
							'Av',
							'Elloel'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					wide => {
						nonleap => [
							'Chaitra',
							'Vaishakha',
							'Jyeshtha',
							'Aashaadha',
							'Shraavana',
							'Bhaadrapada',
							'Ashvina',
							'Kaartika',
							'Agrahayana',
							'Pausha',
							'Maagha',
							'Phaalguna'
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
							'Moeh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Joem. I',
							'Joem. II',
							'Raj.',
							'Sja.',
							'Ram.',
							'Sjaw.',
							'Doe al k.',
							'Doe al h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Moeharram',
							'Safar',
							'Rabiʻa al awal',
							'Rabiʻa al thani',
							'Joemadʻal awal',
							'Joemadʻal thani',
							'Rajab',
							'Sjaʻaban',
							'Ramadan',
							'Sjawal',
							'Doe al kaʻaba',
							'Doe al hizja'
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
						mon => 'mo',
						tue => 'ti',
						wed => 'wo',
						thu => 'to',
						fri => 'fr',
						sat => 'so',
						sun => 'si'
					},
					wide => {
						mon => 'moandei',
						tue => 'tiisdei',
						wed => 'woansdei',
						thu => 'tongersdei',
						fri => 'freed',
						sat => 'sneon',
						sun => 'snein'
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
					wide => {0 => '1e fearnsjier',
						1 => '2e fearnsjier',
						2 => '3e fearnsjier',
						3 => '4e fearnsjier'
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'n.Kr.'
			},
			narrow => {
				'0' => 'f.K.',
				'1' => 'n.K.'
			},
			wide => {
				'0' => 'Foar Kristus',
				'1' => 'nei Kristus'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'SAKA'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'Saʻna Hizjria'
			},
		},
		'roc' => {
			abbreviated => {
				'1' => 'Minguo'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'full' => q{EEEE d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{dd-MM-yy},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
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
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'chinese' => {
			Ed => q{E d},
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E d MMM U},
			GyMMMd => q{d MMM U},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{U},
			yyyy => q{U},
			yyyyM => q{M-y},
			yyyyMEd => q{E d-M-y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E d MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMd => q{d MMM U},
			yyyyMd => q{d-M-y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'generic' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMW => q{'wike' W 'fan' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M-y},
			yMEd => q{E d-M-y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d-M-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'wike' w 'fan' Y},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
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
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
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
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y},
				d => q{E dd-MM-y – E dd-MM-y},
				y => q{E dd-MM-y – E dd-MM-y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
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
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
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
					'wide' => {
						0 => q(begjin fan de maitiid),
						1 => q(reinwetter),
						2 => q(ynsekten ûntweitsje),
						3 => q(maitiidpunt),
						4 => q(ljocht en helder),
						6 => q(begjien fan de simmer),
						9 => q(simmerpunt),
						10 => q(waarm),
						11 => q(hjit),
						12 => q(begjin fan de hjerst),
						13 => q(ein fan de hjittens),
						14 => q(wite dauwe),
						15 => q(hjerstpunt),
						16 => q(kâlde dauwe),
						17 => q(earste froast),
						18 => q(begjin fan de winter),
						19 => q(lichte snie),
						20 => q(swiere snie),
						21 => q(winterpunt),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Rôt),
						1 => q(Okse),
						2 => q(Tiger),
						3 => q(Knyn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Hynder),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Hoanne),
						10 => q(Hûn),
						11 => q(Baarch),
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
		regionFormat => q({0}-tiid),
		regionFormat => q(Zomertiid {0}),
		regionFormat => q(Standaardtiid {0}),
		'Acre' => {
			long => {
				'daylight' => q#Acre-simmertiid#,
				'generic' => q#Acre-tiid#,
				'standard' => q#Acre-standerttiid#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghaanske tiid#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Caïro#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoem#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Sintraal-Afrikaanske tiid#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#East-Afrikaanske tiid#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Sûd-Afrikaanske tiid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#West-Afrikaanske simmertiid#,
				'generic' => q#West-Afrikaanske tiid#,
				'standard' => q#West-Afrikaanske standerttiid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-simmertiid#,
				'generic' => q#Alaska-tiid#,
				'standard' => q#Alaska-standerttiid#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Alma-Ata-simmertiid#,
				'generic' => q#Alma-Ata-tiid#,
				'standard' => q#Alma-Ata-standerttiid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazone-simmertiid#,
				'generic' => q#Amazone-tiid#,
				'standard' => q#Amazone-standerttiid#,
			},
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Beneden Prinsen Kwartier#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico-stad#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Noard-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Noard-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Noard-Dakota#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pôrto Velho#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central-simmertiid#,
				'generic' => q#Central-tiid#,
				'standard' => q#Central-standerttiid#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern-simmertiid#,
				'generic' => q#Eastern-tiid#,
				'standard' => q#Eastern-standerttiid#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain-simmertiid#,
				'generic' => q#Mountain-tiid#,
				'standard' => q#Mountain-standerttiid#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pasifik-simmertiid#,
				'generic' => q#Pasifik-tiid#,
				'standard' => q#Pasifik-standerttiid#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-simmertiid#,
				'generic' => q#Anadyr-tiid#,
				'standard' => q#Anadyr-standerttiid#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau-simmertiid#,
				'generic' => q#Aqtau-tiid#,
				'standard' => q#Aqtau-standerttiid#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtöbe-simmertiid#,
				'generic' => q#Aqtöbe-tiid#,
				'standard' => q#Aqtöbe-standerttiid#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabyske simmertiid#,
				'generic' => q#Arabyske tiid#,
				'standard' => q#Arabyske standerttiid#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentynske simmertiid#,
				'generic' => q#Argentynske tiid#,
				'standard' => q#Argentynske standerttiid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#West-Argentynske simmertiid#,
				'generic' => q#West-Argentynske tiid#,
				'standard' => q#West-Argentynske standerttiid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeense simmertiid#,
				'generic' => q#Armeense tiid#,
				'standard' => q#Armeense standerttiid#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma-Ata#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
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
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusjanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkoetsk#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koeweit#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manilla#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom-Penh#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minhstad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sjanghai#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakoetsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinenburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic-simmertiid#,
				'generic' => q#Atlantic-tiid#,
				'standard' => q#Atlantic-standerttiid#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaryske Eilannen#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaapverdië#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faeröer#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sûd-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint-Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Midden-Australyske simmertiid#,
				'generic' => q#Midden-Australyske tiid#,
				'standard' => q#Midden-Australyske standerttiid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Midden-Australyske westelijke simmertiid#,
				'generic' => q#Midden-Australyske westelijke tiid#,
				'standard' => q#Midden-Australyske westelijke standerttiid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#East-Australyske simmertiid#,
				'generic' => q#East-Australyske tiid#,
				'standard' => q#East-Australyske standerttiid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#West-Australyske simmertiid#,
				'generic' => q#West-Australyske tiid#,
				'standard' => q#West-Australyske standerttiid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbeidzjaanske simmertiid#,
				'generic' => q#Azerbeidzjaanske tiid#,
				'standard' => q#Azerbeidzjaanske standerttiid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoren-simmertiid#,
				'generic' => q#Azoren-tiid#,
				'standard' => q#Azoren-standerttiid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bengalese simmertiid#,
				'generic' => q#Bengalese tiid#,
				'standard' => q#Bengalese standerttiid#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutaanske tiid#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviaanske tiid#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brazyljaanske simmertiid#,
				'generic' => q#Brazyljaanske tiid#,
				'standard' => q#Brazyljaanske standerttiid#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneise tiid#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kaapverdyske simmertiid#,
				'generic' => q#Kaapverdyske tiid#,
				'standard' => q#Kaapverdyske standerttiid#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-tiid#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham simmertiid#,
				'generic' => q#Chatham tiid#,
				'standard' => q#Chatham standerttiid#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Sileenske simmertiid#,
				'generic' => q#Sileenske tiid#,
				'standard' => q#Sileenske standerttiid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Sineeske simmertiid#,
				'generic' => q#Sineeske tiid#,
				'standard' => q#Sineeske standerttiid#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tsjojbalsan simmertiid#,
				'generic' => q#Tsjojbalsan tiid#,
				'standard' => q#Tsjojbalsan standerttiid#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Krysteilânske tiid#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokoseilânske tiid#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolombiaanske simmertiid#,
				'generic' => q#Kolombiaanske tiid#,
				'standard' => q#Kolombiaanske standerttiid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookeilânse halve simmertiid#,
				'generic' => q#Cookeilânse tiid#,
				'standard' => q#Cookeilânse standerttiid#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubaanske simmertiid#,
				'generic' => q#Kubaanske tiid#,
				'standard' => q#Kubaanske standerttiid#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis tiid#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville tiid#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#East-Timorese tiid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Peaskeeilânske simmertiid#,
				'generic' => q#Peaskeeilânske tiid#,
				'standard' => q#Peaskeeilânske standerttiid#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadoraanske tiid#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unbekende stêd#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
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
				'daylight' => q#Ierse simmertiid#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinky#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanboel#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			exemplarCity => q#Londen#,
			long => {
				'daylight' => q#Britse simmertiid#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskou#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parys#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praach#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Oezjhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Fatikaanstêd#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wenen#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Midden-Europeeske simmertiid#,
				'generic' => q#Midden-Europeeske tiid#,
				'standard' => q#Midden-Europeeske standerttiid#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#East-Europeeske simmertiid#,
				'generic' => q#East-Europeeske tiid#,
				'standard' => q#East-Europeeske standerttiid#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#West-Europeeske simmertiid#,
				'generic' => q#West-Europeeske tiid#,
				'standard' => q#West-Europeeske standerttiid#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklâneilânske simmertiid#,
				'generic' => q#Falklâneilânske tiid#,
				'standard' => q#Falklâneilânske standerttiid#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fijyske simmertiid#,
				'generic' => q#Fijyske tiid#,
				'standard' => q#Fijyske standerttiid#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frâns-Guyaanske tiid#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Frânske Súdlike en Antarctyske tiid#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagoseilânske tiid#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiereilânske tiid#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgyske simmertiid#,
				'generic' => q#Georgyske tiid#,
				'standard' => q#Georgyske standerttiid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberteilânske tiid#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#East-Groenlânske simmertiid#,
				'generic' => q#East-Groenlânske tiid#,
				'standard' => q#East-Groenlânske standerttiid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West-Groenlânske simmertiid#,
				'generic' => q#West-Groenlânske tiid#,
				'standard' => q#West-Groenlânske standerttiid#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamese standerttiid#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golf standerttiid#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyaanske tiid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleoetyske simmertiid#,
				'generic' => q#Hawaii-Aleoetyske tiid#,
				'standard' => q#Hawaii-Aleoetyske standerttiid#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongse simmertiid#,
				'generic' => q#Hongkongse tiid#,
				'standard' => q#Hongkongse standerttiid#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd simmertiid#,
				'generic' => q#Hovd tiid#,
				'standard' => q#Hovd standerttiid#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Yndiaaske tiid#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagosarchipel#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krysteilân#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocoseilannen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiven#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Yndyske Oceaan-tiid#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Yndochinese tiid#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Sintraal-Yndonezyske tiid#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#East-Yndonezyske tiid#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#West-Yndonezyske tiid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iraanske simmertiid#,
				'generic' => q#Iraanske tiid#,
				'standard' => q#Iraanske standerttiid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkoetsk-simmertiid#,
				'generic' => q#Irkoetsk-tiid#,
				'standard' => q#Irkoetsk-standerttiid#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israëlyske simmertiid#,
				'generic' => q#Israëlyske tiid#,
				'standard' => q#Israëlyske standerttiid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japanske simmertiid#,
				'generic' => q#Japanske tiid#,
				'standard' => q#Japanske standerttiid#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamtsjatski-simmertiid#,
				'generic' => q#Petropavlovsk-Kamtsjatski-tiid#,
				'standard' => q#Petropavlovsk-Kamtsjatski-standerttiid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#East-Kazachse tiid#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West-Kazachse tiid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreaanske simmertiid#,
				'generic' => q#Koreaanske tiid#,
				'standard' => q#Koreaanske standerttiid#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraese tiid#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-simmertiid#,
				'generic' => q#Krasnojarsk-tiid#,
				'standard' => q#Krasnojarsk-standerttiid#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgizyske tiid#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka-tiid#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line-eilânske tiid#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe-eilânske simmertiid#,
				'generic' => q#Lord Howe-eilânske tiid#,
				'standard' => q#Lord Howe-eilânske standerttiid#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macause simmertiid#,
				'generic' => q#Macause tiid#,
				'standard' => q#Macause standerttiid#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie-eilânske tiid#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-simmertiid#,
				'generic' => q#Magadan-tiid#,
				'standard' => q#Magadan-standerttiid#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Maleisyske tiid#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivyske tiid#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesaseilânske tiid#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalleilânske tiid#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritiaanske simmertiid#,
				'generic' => q#Mauritiaanske tiid#,
				'standard' => q#Mauritiaanske standerttiid#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson tiid#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar simmertiid#,
				'generic' => q#Ulaanbaatar tiid#,
				'standard' => q#Ulaanbaatar standerttiid#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskou-simmertiid#,
				'generic' => q#Moskou-tiid#,
				'standard' => q#Moskou-standerttiid#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarese tiid#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruaanske tiid#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalese tiid#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nij-Kaledonyske simmertiid#,
				'generic' => q#Nij-Kaledonyske tiid#,
				'standard' => q#Nij-Kaledonyske standerttiid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nij-Seelânske simmertiid#,
				'generic' => q#Nij-Seelânske tiid#,
				'standard' => q#Nij-Seelânske standerttiid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlânske-simmertiid#,
				'generic' => q#Newfoundlânske-tiid#,
				'standard' => q#Newfoundlânske-standerttiid#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuese tiid#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolkeilânske simmertiid#,
				'generic' => q#Norfolkeilânske tiid#,
				'standard' => q#Norfolkeilânske standerttiid#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-simmertiid#,
				'generic' => q#Fernando de Noronha-tiid#,
				'standard' => q#Fernando de Noronha-standerttiid#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Noardlike Mariaanske tiid#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk-simmertiid#,
				'generic' => q#Novosibirsk-tiid#,
				'standard' => q#Novosibirsk-standerttiid#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-simmertiid#,
				'generic' => q#Omsk-tiid#,
				'standard' => q#Omsk-standerttiid#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Peaskeeilân#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury-eilân#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambiereilannen#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesaseilannen#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistaanske simmertiid#,
				'generic' => q#Pakistaanske tiid#,
				'standard' => q#Pakistaanske standerttiid#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Belause tiid#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papoea-Nij-Guineeske tiid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayaanske simmertiid#,
				'generic' => q#Paraguayaanske tiid#,
				'standard' => q#Paraguayaanske standerttiid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruaanske simmertiid#,
				'generic' => q#Peruaanske tiid#,
				'standard' => q#Peruaanske standerttiid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipijnse simmertiid#,
				'generic' => q#Filipijnse tiid#,
				'standard' => q#Filipijnse standerttiid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixeilânske tiid#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint Pierre en Miquelon-simmertiid#,
				'generic' => q#Saint Pierre en Miquelon-tiid#,
				'standard' => q#Saint Pierre en Miquelon-standerttiid#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairneillânske tiid#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pohnpei tiid#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylorda-simmertiid#,
				'generic' => q#Qyzylorda-tiid#,
				'standard' => q#Qyzylorda-standerttiid#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunionse tiid#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera tiid#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin-simmertiid#,
				'generic' => q#Sachalin-tiid#,
				'standard' => q#Sachalin-standerttiid#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-simmertiid#,
				'generic' => q#Samara-tiid#,
				'standard' => q#Samara-standerttiid#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoaanske simmertiid#,
				'generic' => q#Samoaanske tiid#,
				'standard' => q#Samoaanske standerttiid#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelse tiid#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singaporese standerttiid#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonseilânske tiid#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Sûd-Georgyske tiid#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinaamske tiid#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa tiid#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiaanske tiid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei simmertiid#,
				'generic' => q#Taipei tiid#,
				'standard' => q#Taipei standerttiid#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadzjiekse tiid#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-eilânske tiid#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongaanske simmertiid#,
				'generic' => q#Tongaanske tiid#,
				'standard' => q#Tongaanske standerttiid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukse tiid#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmeense simmertiid#,
				'generic' => q#Turkmeense tiid#,
				'standard' => q#Turkmeense standerttiid#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvaluaanske tiid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayaanske simmertiid#,
				'generic' => q#Uruguayaanske tiid#,
				'standard' => q#Uruguayaanske standerttiid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oezbeekse simmertiid#,
				'generic' => q#Oezbeekse tiid#,
				'standard' => q#Oezbeekse standerttiid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatuaanske simmertiid#,
				'generic' => q#Vanuatuaanske tiid#,
				'standard' => q#Vanuatuaanske standerttiid#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Fenezolaanske tiid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok-simmertiid#,
				'generic' => q#Vladivostok-tiid#,
				'standard' => q#Vladivostok-standerttiid#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd-simmertiid#,
				'generic' => q#Wolgograd-tiid#,
				'standard' => q#Wolgograd-standerttiid#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok tiid#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake-eilânske tiid#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis en Futunase tiid#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakoetsk-simmertiid#,
				'generic' => q#Jakoetsk-tiid#,
				'standard' => q#Jakoetsk-standerttiid#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinenburg-simmertiid#,
				'generic' => q#Jekaterinenburg-tiid#,
				'standard' => q#Jekaterinenburg-standerttiid#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
