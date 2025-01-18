=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Rm - Package for language Romansh

=cut

package Locale::CLDR::Locales::Rm;
# This file auto generated from Data\common\main\rm.xml
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
				'aa' => 'afar',
 				'ab' => 'abchasian',
 				'ace' => 'aceh',
 				'ach' => 'acoli',
 				'ada' => 'andangme',
 				'ady' => 'adygai',
 				'ae' => 'avestic',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'accadic',
 				'ale' => 'aleutic',
 				'alt' => 'altaic dal sid',
 				'am' => 'amaric',
 				'an' => 'aragonais',
 				'ang' => 'englais vegl',
 				'anp' => 'angika',
 				'ar' => 'arab',
 				'ar_001' => 'arab modern standardisà',
 				'arc' => 'arameic',
 				'arn' => 'araucanic',
 				'arp' => 'arapaho',
 				'arw' => 'arawak',
 				'as' => 'assami',
 				'asa' => 'asu',
 				'ast' => 'asturian',
 				'av' => 'avaric',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'aserbeidschanic',
 				'ba' => 'baschkir',
 				'bal' => 'belutschi',
 				'ban' => 'balinais',
 				'bas' => 'basaa',
 				'be' => 'bieloruss',
 				'bej' => 'bedscha',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgar',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengal',
 				'bo' => 'tibetan',
 				'br' => 'breton',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosniac',
 				'bua' => 'buriat',
 				'bug' => 'bugi',
 				'byn' => 'blin',
 				'ca' => 'catalan',
 				'cad' => 'caddo',
 				'car' => 'caribic',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'tschetschen',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'tschagataic',
 				'chk' => 'chuukais',
 				'chm' => 'mari',
 				'chn' => 'patuà chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'curd central',
 				'ckb@alt=menu' => 'curd, central',
 				'ckb@alt=variant' => 'curd, sorani',
 				'co' => 'cors',
 				'cop' => 'coptic',
 				'cr' => 'cree',
 				'crh' => 'tirc crimean',
 				'cs' => 'tschec',
 				'csb' => 'kaschubic',
 				'cu' => 'slav da baselgia',
 				'cv' => 'tschuvasch',
 				'cy' => 'kimric',
 				'da' => 'danais',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tudestg',
 				'de_AT' => 'tudestg austriac',
 				'de_CH' => 'tudestg da scrittira svizzer',
 				'del' => 'delaware',
 				'den' => 'slavey',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'bass sorb',
 				'dua' => 'duala',
 				'dum' => 'ollandais mesaun',
 				'dv' => 'maledivic',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'diula',
 				'dz' => 'dzongkha',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'egipzian vegl',
 				'eka' => 'ekajuk',
 				'el' => 'grec',
 				'elx' => 'elamitic',
 				'en' => 'englais',
 				'en_AU' => 'englais australian',
 				'en_CA' => 'englais canadais',
 				'en_GB' => 'englais britannic',
 				'en_GB@alt=short' => 'englais GB',
 				'en_US' => 'englais american',
 				'en_US@alt=short' => 'englais USA',
 				'enm' => 'englais mesaun',
 				'eo' => 'esperanto',
 				'es' => 'spagnol',
 				'es_419' => 'spagnol latinamerican',
 				'es_ES' => 'spagnol europeic',
 				'es_MX' => 'spagnol mexican',
 				'et' => 'eston',
 				'eu' => 'basc',
 				'ewo' => 'ewondo',
 				'fa' => 'persian',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandais',
 				'fil' => 'filippino',
 				'fj' => 'fidschian',
 				'fo' => 'feroais',
 				'fon' => 'fon',
 				'fr' => 'franzos',
 				'fr_CA' => 'franzos canadais',
 				'fr_CH' => 'franzos svizzer',
 				'frm' => 'franzos mesaun',
 				'fro' => 'franzos vegl',
 				'frr' => 'fris dal nord',
 				'frs' => 'fris da l’ost',
 				'fur' => 'friulan',
 				'fy' => 'fris',
 				'ga' => 'irlandais',
 				'gaa' => 'ga',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'gaelic scot',
 				'gez' => 'geez',
 				'gil' => 'gilbertais',
 				'gl' => 'galician',
 				'gmh' => 'tudestg mesaun',
 				'gn' => 'guarani',
 				'goh' => 'vegl tudestg da scrittira',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotic',
 				'grb' => 'grebo',
 				'grc' => 'grec vegl',
 				'gsw' => 'tudestg svizzer',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichʼin',
 				'ha' => 'haussa',
 				'hai' => 'haida',
 				'haw' => 'hawaian',
 				'he' => 'ebraic',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hit' => 'ettitic',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croat',
 				'hsb' => 'aut sorb',
 				'ht' => 'creol haitian',
 				'hu' => 'ungarais',
 				'hup' => 'hupa',
 				'hy' => 'armen',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'id' => 'indonais',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiak',
 				'ilo' => 'ilocano',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandais',
 				'it' => 'talian',
 				'iu' => 'inuktitut',
 				'ja' => 'giapunais',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'giudaic-persian',
 				'jrb' => 'giudaic-arab',
 				'jv' => 'javanais',
 				'ka' => 'georgian',
 				'kaa' => 'karakalpak',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardic',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'cabverdian',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'khasi',
 				'kho' => 'khotanais',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'casac',
 				'kkj' => 'kako',
 				'kl' => 'grönlandais',
 				'kln' => 'kalenjin',
 				'km' => 'cambodschan',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'corean',
 				'kok' => 'konkani',
 				'kos' => 'kosraean',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'carelian',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'colognais',
 				'ku' => 'curd',
 				'kum' => 'kumuk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornic',
 				'ky' => 'kirghis',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgais',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgais',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laot',
 				'lol' => 'lomongo',
 				'loz' => 'lozi',
 				'lrc' => 'luri dal nord',
 				'lt' => 'lituan',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'letton',
 				'mad' => 'madurais',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makassar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malagassi',
 				'mga' => 'irlandais mesaun',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marschallais',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedon',
 				'ml' => 'malayalam',
 				'mn' => 'mongolic',
 				'mnc' => 'manchu',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malaic',
 				'mt' => 'maltais',
 				'mua' => 'mundang',
 				'mul' => 'pluriling',
 				'mus' => 'creek',
 				'mwl' => 'mirandais',
 				'mwr' => 'marwari',
 				'my' => 'birman',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nap' => 'neapolitan',
 				'naq' => 'nama',
 				'nb' => 'norvegais bokmål',
 				'nd' => 'ndebele dal nord',
 				'nds' => 'bass tudestg',
 				'ne' => 'nepalais',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'nl' => 'ollandais',
 				'nl_BE' => 'flam',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegiais nynorsk',
 				'nnh' => 'ngienboon',
 				'no' => 'norvegiais',
 				'nog' => 'nogai',
 				'non' => 'nordic vegl',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele dal sid',
 				'nso' => 'sotho dal nord',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari classic',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitan',
 				'oj' => 'ojibwa',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'ossetic',
 				'osa' => 'osage',
 				'ota' => 'tirc ottoman',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcm' => 'pidgin nigerian',
 				'peo' => 'persian vegl',
 				'phn' => 'fenizian',
 				'pi' => 'pali',
 				'pl' => 'polac',
 				'pon' => 'ponapean',
 				'prg' => 'prussian',
 				'pro' => 'provenzal vegl',
 				'ps' => 'paschto',
 				'pt' => 'portugais',
 				'pt_BR' => 'portugais brasilian',
 				'pt_PT' => 'portugais europeic',
 				'qu' => 'quechua',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rm' => 'rumantsch',
 				'rn' => 'rundi',
 				'ro' => 'rumen',
 				'ro_MD' => 'moldav',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'ru' => 'russ',
 				'rup' => 'aromunic',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakut',
 				'sam' => 'arameic samaritan',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sbp' => 'sangu',
 				'sc' => 'sard',
 				'scn' => 'sicilian',
 				'sco' => 'scot',
 				'sd' => 'sindhi',
 				'se' => 'sami dal nord',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'irlandais vegl',
 				'sh' => 'serbo-croat',
 				'shi' => 'tachelit',
 				'shn' => 'shan',
 				'si' => 'singalais',
 				'sid' => 'sidamo',
 				'sk' => 'slovac',
 				'sl' => 'sloven',
 				'sm' => 'samoan',
 				'sma' => 'sami dal sid',
 				'smj' => 'sami lule',
 				'smn' => 'sami inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdian',
 				'sq' => 'albanais',
 				'sr' => 'serb',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swazi',
 				'st' => 'sotho dal sid',
 				'su' => 'sundanais',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeric',
 				'sv' => 'svedais',
 				'sw' => 'suahili',
 				'sw_CD' => 'suahili dal Congo',
 				'syc' => 'siric classic',
 				'syr' => 'siric',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadjik',
 				'th' => 'tailandais',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turkmen',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonic',
 				'tli' => 'tlingit',
 				'tmh' => 'tamasheq',
 				'tn' => 'tswana',
 				'to' => 'tonga',
 				'tog' => 'lingua tsonga',
 				'tpi' => 'tok pisin',
 				'tr' => 'tirc',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatar',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitian',
 				'tyv' => 'tuvinian',
 				'tzm' => 'tamazight',
 				'udm' => 'udmurt',
 				'ug' => 'uiguric',
 				'uga' => 'ugaritic',
 				'uk' => 'ucranais',
 				'umb' => 'mbundu',
 				'und' => 'lingua nunenconuschenta',
 				'ur' => 'urdu',
 				'uz' => 'usbec',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamais',
 				'vo' => 'volapuk',
 				'vot' => 'votic',
 				'vun' => 'vunjo',
 				'wa' => 'vallon',
 				'wae' => 'gualser',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wo' => 'wolof',
 				'xal' => 'kalmuk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapais',
 				'yav' => 'yangben',
 				'yi' => 'jiddic',
 				'yo' => 'yoruba',
 				'yue' => 'cantonais',
 				'yue@alt=menu' => 'chinais, cantonais',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'simbols da Bliss',
 				'zen' => 'zenaga',
 				'zgh' => 'marocan tamazight standardisà',
 				'zh' => 'chinais',
 				'zh@alt=menu' => 'chinais, mandarin',
 				'zh_Hans' => 'chinais simplifitgà',
 				'zh_Hans@alt=long' => 'chinais mandarin simplifitgà',
 				'zh_Hant' => 'chinais tradiziunal',
 				'zh_Hant@alt=long' => 'chinais mandarin tradiziunal',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'nagins cuntegns linguistics',
 				'zza' => 'zaza',

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
			'Adlm' => 'adlam',
 			'Aghb' => 'albanais dal Caucasus',
 			'Ahom' => 'ahom',
 			'Arab' => 'arab',
 			'Aran' => 'nastaliq',
 			'Armi' => 'arameic imperial',
 			'Armn' => 'armen',
 			'Avst' => 'avestic',
 			'Bali' => 'balinais',
 			'Bamu' => 'bamun',
 			'Batk' => 'batak',
 			'Beng' => 'bengal',
 			'Blis' => 'simbols da Bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'scrittira da Braille',
 			'Bugi' => 'buginais',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'simbols autoctons canadais unifitgads',
 			'Cari' => 'carian',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'coptic',
 			'Cprt' => 'cipriot',
 			'Cyrl' => 'cirillic',
 			'Cyrs' => 'slav da baselgia vegl',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'stenografia da Duployé',
 			'Egyd' => 'egipzian demotic',
 			'Egyh' => 'egipzian ieratic',
 			'Egyp' => 'ieroglifas egipzianas',
 			'Elba' => 'elbasan',
 			'Elym' => 'elimeic',
 			'Ethi' => 'etiopic',
 			'Geok' => 'kutsuri',
 			'Geor' => 'georgian',
 			'Glag' => 'glagolitic',
 			'Goth' => 'gotic',
 			'Grek' => 'grec',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han cun bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'simplifitgà',
 			'Hans@alt=stand-alone' => 'han simplifitgà',
 			'Hant' => 'tradiziunal',
 			'Hant@alt=stand-alone' => 'han tradiziunal',
 			'Hebr' => 'ebraic',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawn hmong',
 			'Hrkt' => 'scrittira da silbas giapunaisa',
 			'Hung' => 'ungarais vegl',
 			'Inds' => 'indus',
 			'Ital' => 'italic vegl',
 			'Jamo' => 'jamo',
 			'Java' => 'javanais',
 			'Jpan' => 'giapunais',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer/cambodschan',
 			'Knda' => 'kannada',
 			'Kore' => 'corean',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laot',
 			'Latf' => 'latin (scrittira gotica)',
 			'Latg' => 'latin (scrittira gaelica)',
 			'Latn' => 'latin',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'linear A',
 			'Linb' => 'linear B',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'lichic',
 			'Lydi' => 'lidic',
 			'Mand' => 'mandaic',
 			'Mani' => 'manicheic',
 			'Maya' => 'ieroglifas maya',
 			'Mero' => 'meroitic',
 			'Mlym' => 'malaisian',
 			'Mong' => 'mongolic',
 			'Moon' => 'moon',
 			'Mtei' => 'meetei mayek',
 			'Mymr' => 'burmais',
 			'Narb' => 'arab vegl dal nord',
 			'Nbat' => 'nabateic',
 			'Newa' => 'newari',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'scrittira da dunnas',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osge' => 'osage',
 			'Osma' => 'osman',
 			'Palm' => 'palmiren',
 			'Perm' => 'permic vegl',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi dad inscripziuns',
 			'Phlp' => 'pahlavi da psalms',
 			'Phlv' => 'pahlavi da cudeschs',
 			'Phnx' => 'fenizian',
 			'Plrd' => 'fonetica da Pollard',
 			'Prti' => 'partic dad inscripziuns',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runic',
 			'Samr' => 'samaritan',
 			'Sara' => 'sarati',
 			'Sarb' => 'arab vegl dal sid',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'lingua da segns',
 			'Shaw' => 'shavian',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudabadic',
 			'Sinh' => 'singalais',
 			'Sogd' => 'sogdian',
 			'Sogo' => 'sogdian vegl',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyombo',
 			'Sund' => 'sundanais',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siric',
 			'Syre' => 'siric estrangelo',
 			'Syrj' => 'siric dal vest',
 			'Syrn' => 'siric da l’ost',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue',
 			'Taml' => 'tamil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandais',
 			'Tibt' => 'tibetan',
 			'Ugar' => 'ugaritic',
 			'Vaii' => 'vaii',
 			'Visp' => 'alfabet visibel',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wancho',
 			'Xpeo' => 'persian vegl',
 			'Xsux' => 'scrittira a cugn sumeric-accadica',
 			'Yezi' => 'jesid',
 			'Yiii' => 'yi',
 			'Zanb' => 'quadrats da Zanabazar',
 			'Zinh' => 'ertà',
 			'Zmth' => 'notaziun matematica',
 			'Zsye' => 'emojis',
 			'Zsym' => 'simbols',
 			'Zxxx' => 'betg scrit',
 			'Zyyy' => 'betg determinà',
 			'Zzzz' => 'scrittira nunenconuschenta',

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
			'001' => 'mund',
 			'002' => 'Africa',
 			'003' => 'America dal Nord',
 			'005' => 'America dal Sid',
 			'009' => 'Oceania',
 			'011' => 'Africa dal Vest',
 			'013' => 'America Centrala',
 			'014' => 'Africa da l’Ost',
 			'015' => 'Africa dal Nord',
 			'017' => 'Africa Centrala',
 			'018' => 'Africa Meridiunala',
 			'019' => 'americas',
 			'021' => 'Amercia dal Nord',
 			'029' => 'Caribica',
 			'030' => 'Asia da l’Ost',
 			'034' => 'Asia dal Sid',
 			'035' => 'Asia dal Sidost',
 			'039' => 'Europa dal Sid',
 			'053' => 'Australia e Nova Zelanda',
 			'054' => 'Melanesia',
 			'057' => 'Regiun Micronesica',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Centrala',
 			'145' => 'Asia dal Vest',
 			'150' => 'Europa',
 			'151' => 'Europa Orientala',
 			'154' => 'Europa dal Nord',
 			'155' => 'Europa dal Vest',
 			'202' => 'Africa Subsaharica',
 			'419' => 'America Latina',
 			'AC' => 'Insla d’Ascensiun',
 			'AD' => 'Andorra',
 			'AE' => 'Emirats Arabs Unids',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentinia',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Inslas Aland',
 			'AZ' => 'Aserbaidschan',
 			'BA' => 'Bosnia ed Erzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Son Barthélemy',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Antillas Ollandaisas',
 			'BR' => 'Brasilia',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Insla Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Inslas Cocos',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Republica Centralafricana',
 			'CG' => 'Congo',
 			'CG@alt=variant' => 'Congo (republica)',
 			'CH' => 'Svizra',
 			'CI' => 'Costa d’Ivur',
 			'CK' => 'Inslas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Columbia',
 			'CP' => 'Insla da Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap Verd',
 			'CW' => 'Curaçao',
 			'CX' => 'Insla da Nadal',
 			'CY' => 'Cipra',
 			'CZ' => 'Tschechia',
 			'CZ@alt=variant' => 'Republica Tscheca',
 			'DE' => 'Germania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dschibuti',
 			'DK' => 'Danemarc',
 			'DM' => 'Dominica',
 			'DO' => 'Republica Dominicana',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipta',
 			'EH' => 'Sahara Occidentala',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Uniun Europeica',
 			'EZ' => 'zona da l’euro',
 			'FI' => 'Finlanda',
 			'FJ' => 'Fidschi',
 			'FK' => 'Inslas dal Falkland',
 			'FK@alt=variant' => 'Inslas Falkland',
 			'FM' => 'Micronesia',
 			'FO' => 'Inslas Feroe',
 			'FR' => 'Frantscha',
 			'GA' => 'Gabun',
 			'GB' => 'Reginavel Unì',
 			'GB@alt=short' => 'GB',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana Franzosa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönlanda',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea Equatoriala',
 			'GR' => 'Grezia',
 			'GS' => 'Georgia dal Sid e las Inslas Sandwich dal Sid',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Regiun d’administraziun speziala da Hongkong, China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Inslas da Heard e da McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croazia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungaria',
 			'IC' => 'Inslas Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Insla da Man',
 			'IN' => 'India',
 			'IO' => 'Territori Britannic en l’Ocean Indic',
 			'IQ' => 'Irac',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamaica',
 			'JO' => 'Jordania',
 			'JP' => 'Giapun',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Cambodscha',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoras',
 			'KN' => 'Saint Kitts e Nevis',
 			'KP' => 'Corea dal Nord',
 			'KR' => 'Corea dal Sid',
 			'KW' => 'Kuwait',
 			'KY' => 'Inslas Cayman',
 			'KZ' => 'Kasachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettonia',
 			'LY' => 'Libia',
 			'MA' => 'Maroc',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Inslas da Marshall',
 			'MK' => 'Macedonia dal Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Regiun d’administraziun speziala Macao, China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Inslas Mariannas dal Nord',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaisia',
 			'MZ' => 'Mosambic',
 			'NA' => 'Namibia',
 			'NC' => 'Nova Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Insla Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Pajais Bass',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelanda',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Franzosa',
 			'PG' => 'Papua Nova Guinea',
 			'PH' => 'Filippinas',
 			'PK' => 'Pakistan',
 			'PL' => 'Pologna',
 			'PM' => 'Saint Pierre e Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territori Palestinais',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'Oceania Periferica',
 			'RE' => 'Réunion',
 			'RO' => 'Rumenia',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Inslas Salomonas',
 			'SC' => 'Seychellas',
 			'SD' => 'Sudan',
 			'SE' => 'Svezia',
 			'SG' => 'Singapur',
 			'SH' => 'Sontg’Elena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovachia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudan dal Sid',
 			'ST' => 'São Tomé & Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Inslas Turks e Caicos',
 			'TD' => 'Tschad',
 			'TF' => 'Territoris Franzos Meridiunals',
 			'TG' => 'Togo',
 			'TH' => 'Tailanda',
 			'TJ' => 'Tadschikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor da l’Ost',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesia',
 			'TO' => 'Tonga',
 			'TR' => 'Tirchia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Inslas Pitschnas Perifericas dals Stadis Unids da l’America',
 			'UN' => 'Naziuns Unidas',
 			'US' => 'Stadis Unids da l’America',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Citad dal Vatican',
 			'VC' => 'Saint Vincent e las Grenadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Inslas Virginas Britannicas',
 			'VI' => 'Inslas Virginas Americanas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis & Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'accents pseudo',
 			'XB' => 'pseudo-bidirecziunal',
 			'XK' => 'Cosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Africa dal Sid',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'regiun nunenconuschenta',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia tudestga tradiziunala',
 			'1994' => 'ortografia standardisada da Resia',
 			'1996' => 'nova ortografia tudestga',
 			'1606NICT' => 'franzos mesaun tardiv (fin 1606)',
 			'1694ACAD' => 'franzos modern tempriv (a partir da 1694)',
 			'AREVELA' => 'armen oriental',
 			'AREVMDA' => 'armen occidental',
 			'BAKU1926' => 'alfabet tirc unifitgà',
 			'BISKE' => 'dialect da San Giorgio',
 			'BOONT' => 'dialect boontling',
 			'FONIPA' => 'alfabet fonetic internaziunal (IPA)',
 			'FONUPA' => 'alfabet fonetic da l’Ural (UPA)',
 			'LIPAW' => 'dialect lipovaz da Resia',
 			'MONOTON' => 'monotonic',
 			'NEDIS' => 'dialect da Natisone',
 			'NJIVA' => 'dialect da Gniva',
 			'OSOJS' => 'dialect da Oscacco',
 			'POLYTON' => 'politonic',
 			'POSIX' => 'computer',
 			'REVISED' => 'ortografia revedida',
 			'ROZAJ' => 'dialect da Resia',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'englais da standard scot',
 			'SCOUSE' => 'dialect scouse',
 			'SOLBA' => 'dialect da Stolvizza',
 			'TARASK' => 'ortografia taraskievica',
 			'VALENCIA' => 'valencian',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'chalender',
 			'cf' => 'format da valuta',
 			'collation' => 'zavrada',
 			'currency' => 'valuta',
 			'hc' => 'ciclus da las uras',
 			'lb' => 'stil da sigl da lingia',
 			'ms' => 'sistem da mesira',
 			'numbers' => 'dumbers',

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
 				'buddhist' => q{chalender budistic},
 				'chinese' => q{chalender chinais},
 				'coptic' => q{chalender coptic},
 				'dangi' => q{chalender dangi},
 				'ethiopic' => q{chalender etiopic},
 				'gregorian' => q{chalender gregorian},
 				'hebrew' => q{chalender ebraic},
 				'indian' => q{chalender naziunal indic},
 				'islamic' => q{chalender islamic},
 				'islamic-civil' => q{chalender islamic civil},
 				'islamic-rgsa' => q{chalender islamic (Arabia Saudita)},
 				'islamic-umalqura' => q{chalender islamic (Umm al-Qura)},
 				'iso8601' => q{chalender tenor ISO 8601},
 				'japanese' => q{chalender giapunais},
 				'persian' => q{chalender persian},
 				'roc' => q{chalender da la Republica Chinaisa},
 			},
 			'cf' => {
 				'account' => q{format da valuta per la contabilitad},
 				'standard' => q{format da valuta da standard},
 			},
 			'collation' => {
 				'big5han' => q{chinaisa tradiziunala - Big5},
 				'ducet' => q{zavrada unicode standard},
 				'gb2312han' => q{chinaisa simplifitgada - GB2312},
 				'phonebook' => q{cudesch da telefon},
 				'pinyin' => q{Pinyin},
 				'search' => q{tschertga generala},
 				'standard' => q{zavrada da standard},
 				'stroke' => q{urden dals stritgs},
 				'traditional' => q{reglas tradiziunalas},
 			},
 			'hc' => {
 				'h11' => q{sistem da 12 uras (0–11)},
 				'h12' => q{sistem da 12 uras (1–12)},
 				'h23' => q{sistem da 24 uras (0–23)},
 				'h24' => q{sistem da 24 uras (1–24)},
 			},
 			'lb' => {
 				'loose' => q{stil da sigl da lingia liber},
 				'normal' => q{stil da sigl da lingia normal},
 				'strict' => q{stil da sigl da lingia strict},
 			},
 			'ms' => {
 				'metric' => q{sistem metric},
 				'uksystem' => q{sistem da mesira imperial},
 				'ussystem' => q{sistem da mesira US},
 			},
 			'numbers' => {
 				'arab' => q{cifras indic-arabas},
 				'armn' => q{dumbers armens},
 				'beng' => q{cifras bengalas},
 				'geor' => q{dumbers georgians},
 				'latn' => q{cifras occidentalas},
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
			'metric' => q{metric},
 			'UK' => q{englais},
 			'US' => q{american},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingua: {0}',
 			'script' => 'Scrittira: {0}',
 			'region' => 'Regiun: {0}',

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
			auxiliary => qr{[áăâåäā æ ç ĕêëē íĭîïī ñ óŏôöøō œ úŭûüū ÿ]},
			index => ['AÀ', 'B', 'C', 'D', 'EÉÈ', 'F', 'G', 'H', 'IÌ', 'J', 'K', 'L', 'M', 'N', 'OÒ', 'P', 'Q', 'R', 'S', 'T', 'UÙ', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aà b c d eéè f g h iì j k l m n oò p q r s t uù v w x y z]},
			numbers => qr{[. ’ % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['AÀ', 'B', 'C', 'D', 'EÉÈ', 'F', 'G', 'H', 'IÌ', 'J', 'K', 'L', 'M', 'N', 'OÒ', 'P', 'Q', 'R', 'S', 'T', 'UÙ', 'V', 'W', 'X', 'Y', 'Z'], };
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
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} sid),
						'west' => q({0} vest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} sid),
						'west' => q({0} vest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisecundas),
						'one' => q({0} millisecunda),
						'other' => q({0} millisecundas),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisecundas),
						'one' => q({0} millisecunda),
						'other' => q({0} millisecundas),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} minuta),
						'other' => q({0} minutas),
						'per' => q({0} per minuta),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} minuta),
						'other' => q({0} minutas),
						'per' => q({0} per minuta),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} secunda),
						'other' => q({0} secundas),
						'per' => q({0} per secunda),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} secunda),
						'other' => q({0} secundas),
						'per' => q({0} per secunda),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimeters),
						'one' => q({0} centimeter),
						'other' => q({0} centimeters),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimeters),
						'one' => q({0} centimeter),
						'other' => q({0} centimeters),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometers),
						'one' => q({0} kilometer),
						'other' => q({0} kilometers),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometers),
						'one' => q({0} kilometer),
						'other' => q({0} kilometers),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} meter),
						'other' => q({0} meters),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} meter),
						'other' => q({0} meters),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeters),
						'one' => q({0} millimeter),
						'other' => q({0} millimeters),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeters),
						'one' => q({0} millimeter),
						'other' => q({0} millimeters),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} grams),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} grams),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilograms),
						'one' => q({0} kilogram),
						'other' => q({0} kilograms),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilograms),
						'one' => q({0} kilogram),
						'other' => q({0} kilograms),
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
					'speed-kilometer-per-hour' => {
						'name' => q(kilometers per ura),
						'one' => q({0} kilometer per ura),
						'other' => q({0} kilometers per ura),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometers per ura),
						'one' => q({0} kilometer per ura),
						'other' => q({0} kilometers per ura),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grads celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grads celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grads celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grads celsius),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(di),
						'one' => q({0} dis),
						'other' => q({0} dis),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(di),
						'one' => q({0} dis),
						'other' => q({0} dis),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ura),
						'one' => q({0} uras),
						'other' => q({0} uras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ura),
						'one' => q({0} uras),
						'other' => q({0} uras),
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
						'name' => q(min),
						'one' => q({0} mins.),
						'other' => q({0} mins.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} mins.),
						'other' => q({0} mins.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sec),
						'one' => q({0} secs.),
						'other' => q({0} secs.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sec),
						'one' => q({0} secs.),
						'other' => q({0} secs.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(emna),
						'one' => q({0} emnas),
						'other' => q({0} emnas),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(emna),
						'one' => q({0} emnas),
						'other' => q({0} emnas),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(onn),
						'one' => q({0} onns),
						'other' => q({0} onns),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(onn),
						'one' => q({0} onns),
						'other' => q({0} onns),
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
						'name' => q(meter),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meter),
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
					'mass-gram' => {
						'name' => q(gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
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
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} fl oz imp),
						'other' => q({0} fl oz imp),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} fl oz imp),
						'other' => q({0} fl oz imp),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} gal imp),
						'other' => q({0} gal imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} gal imp),
						'other' => q({0} gal imp),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direcziun),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direcziun),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
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
					'duration-day' => {
						'name' => q(dis),
						'one' => q({0} di),
						'other' => q({0} dis),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dis),
						'one' => q({0} di),
						'other' => q({0} dis),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(uras),
						'one' => q({0} ura),
						'other' => q({0} uras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(uras),
						'one' => q({0} ura),
						'other' => q({0} uras),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutas),
						'one' => q({0} min.),
						'other' => q({0} mins.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutas),
						'one' => q({0} min.),
						'other' => q({0} mins.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mais),
						'one' => q({0} mais),
						'other' => q({0} mais),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mais),
						'one' => q({0} mais),
						'other' => q({0} mais),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(secundas),
						'one' => q({0} sec.),
						'other' => q({0} secs.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(secundas),
						'one' => q({0} sec.),
						'other' => q({0} secs.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(emnas),
						'one' => q({0} emna),
						'other' => q({0} emnas),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(emnas),
						'one' => q({0} emna),
						'other' => q({0} emnas),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(onns),
						'one' => q({0} onn),
						'other' => q({0} onns),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(onns),
						'one' => q({0} onn),
						'other' => q({0} onns),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meters),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meters),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grams),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grams),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/ura),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/ura),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liters),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liters),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:gea|g|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
				'currency' => q(peseta andorrana),
				'one' => q(peseta andorrana),
				'other' => q(pesetas andorranas),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham dals Emirats Arabs Unids),
				'one' => q(dirham dals Emirats Arabs Unids),
				'other' => q(dirhams dals Emirats Arabs Unids),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgani afgan \(1927–2002\)),
				'one' => q(afgani afgan \(1927–2002\)),
				'other' => q(afganis afgans \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani afgan),
				'one' => q(afgani afgan),
				'other' => q(afganis afgans),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanais \(1947–1961\)),
				'one' => q(lek albanais \(1947–1961\)),
				'other' => q(leks albanais \(1947–1961\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanais),
				'one' => q(lek albanais),
				'other' => q(leks albanais),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armen),
				'one' => q(dram armen),
				'other' => q(drams armens),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(flurin da las Antillas Ollandaisas),
				'one' => q(flurin da las Antillas Ollandaisas),
				'other' => q(flurins da las Antillas Ollandaisas),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolan),
				'one' => q(kwanza angolan),
				'other' => q(kwanzas angolans),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolan \(1977–1991\)),
				'one' => q(kwanza angolan \(1977–1991\)),
				'other' => q(kwanzas angolans \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nov kwanza angolan \(1990–2000\)),
				'one' => q(nov kwanza angolan \(1990–2000\)),
				'other' => q(novs kwanzas angolans \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolan reagiustà \(1995–1999\)),
				'one' => q(kwanza angolan reagiustà \(1995–1999\)),
				'other' => q(kwanzas angolans reagiustads \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentin),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(peso argentin ley),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso argentin moneda nacional),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentin \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentin),
				'one' => q(pesos argentins),
				'other' => q(pesos argentins),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(schilling austriac),
				'one' => q(schilling austriac),
				'other' => q(schillings austriacs),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dollar australian),
				'one' => q(dollar australian),
				'other' => q(dollars australians),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(flurin da l’Aruba),
				'one' => q(flurins da l’Aruba),
				'other' => q(flurins da l’Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat aserbaidschan \(1993–2006\)),
				'one' => q(manat aserbaidschan \(1993–2006\)),
				'other' => q(manats aserbaidschans \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat aserbaidschan),
				'one' => q(manat aserbaidschan),
				'other' => q(manats aserbaidschans),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar da la Bosnia-Erzegovina \(1992–1994\)),
				'one' => q(dinar da la Bosnia-Erzegovina \(1992–1994\)),
				'other' => q(dinars da la Bosnia-Erzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marc convertibel da la Bosnia-Erzegovina),
				'one' => q(marc convertibel da la Bosnia-Erzegovina),
				'other' => q(marcs convertibel da la Bosnia-Erzegovina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nov dinar da la Bosnia-Erzegovina \(1994–1997\)),
				'one' => q(nov dinar da la Bosnia-Erzegovina \(1994–1997\)),
				'other' => q(novs dinars da la Bosnia-Erzegovina \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollar da Barbados),
				'one' => q(dollars da Barbados),
				'other' => q(dollars da Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladais),
				'one' => q(taka bangladais),
				'other' => q(takas bangladais),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franc beltg \(convertibel\)),
				'one' => q(franc beltg \(convertibel\)),
				'other' => q(francs beltgs \(convertibels\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franc beltg),
				'one' => q(franc beltg),
				'other' => q(francs beltgs),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franc beltg \(finanzial\)),
				'one' => q(franc beltg \(finanzial\)),
				'other' => q(francs beltgs \(finanzial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev bulgar dir),
				'one' => q(lev bulgar dir),
				'other' => q(levs bulgars dirs),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev bulgar socialistic),
				'one' => q(lev bulgar socialistic),
				'other' => q(levs bulgars socialistics),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bulgar),
				'one' => q(lev bulgar),
				'other' => q(levs bulgars),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(lev bulgar \(1879–1952\)),
				'one' => q(lev bulgar \(1879–1952\)),
				'other' => q(levs bulgars \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar dal Bahrain),
				'one' => q(dinar dal Bahrain),
				'other' => q(dinars dal Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc dal Burundi),
				'one' => q(franc dal Burundi),
				'other' => q(francs dal Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dollar da las Bermudas),
				'one' => q(dollars da las Bermudas),
				'other' => q(dollars da las Bermudas),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dollar dal Brunei),
				'one' => q(dollar dal Brunei),
				'other' => q(dollars dal Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano bolivian),
				'one' => q(boliviano bolivian),
				'other' => q(bolivianos bolivians),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(vegl boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso bolivian),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol bolivian),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(cruzeiro novo brasilian \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brasilian),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brasilian \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasilian),
				'one' => q(real brasilian),
				'other' => q(reals brasilians),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(cruzado novo brasilian),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brasilian),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(vegl cruzeiro brasilian),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dollar da las Bahamas),
				'one' => q(dollars da las Bahamas),
				'other' => q(dollars da las Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum butanais),
				'one' => q(ngultrum butanais),
				'other' => q(ngultrums butanais),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat burmais),
				'one' => q(kyat burmais),
				'other' => q(kyats burmais),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula da la Botswana),
				'one' => q(pula da la Botswana),
				'other' => q(pulas da la Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(rubel bieloruss \(1994–1999\)),
				'one' => q(rubel bieloruss \(1994–1999\)),
				'other' => q(rubels bieloruss \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rubel bieloruss),
				'one' => q(rubel bieloruss),
				'other' => q(rubels bieloruss),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rubel bieloruss \(2000–2016\)),
				'one' => q(rubel bieloruss \(2000–2016\)),
				'other' => q(rubels bieloruss \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dollar dal Belize),
				'one' => q(dollars dal Belize),
				'other' => q(dollars dal Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dollar canadais),
				'one' => q(dollar canadais),
				'other' => q(dollars canadais),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolais),
				'one' => q(franc congolais),
				'other' => q(francs congolais),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro WIR),
				'one' => q(euro WIR),
				'other' => q(euros WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franc svizzer),
				'one' => q(franc svizzer),
				'other' => q(francs svizzers),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(franc WIR),
				'one' => q(franc WIR),
				'other' => q(francs WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(escudo chilen),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unidades de fomento chilenas),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso chilen),
				'one' => q(pesos chilens),
				'other' => q(pesos chilens),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan chinais \(offshore\)),
				'one' => q(yuan chinais \(offshore\)),
				'other' => q(yuans chinais \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dollar da la banca populara chinaisa),
				'one' => q(dollar da la banca populara chinaisa),
				'other' => q(dollars da la banca populara chinaisa),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan chinais),
				'one' => q(yuan chinais),
				'other' => q(yuans chinais),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso columbian),
				'one' => q(pesos columbians),
				'other' => q(pesos columbians),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidad de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colon da la Costa Rica),
				'one' => q(colons da la Costa Rica),
				'other' => q(colons da la Costa Rica),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar serb \(2002–2006\)),
				'one' => q(dinar serb \(2002–2006\)),
				'other' => q(dinars serbs \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(cruna tschecoslovaca),
				'one' => q(cruna tschecoslovaca),
				'other' => q(crunas tschecoslovacas),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cuban convertibel),
				'one' => q(peso cuban convertibel),
				'other' => q(pesos cubans convertibels),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cuban),
				'one' => q(pesos cubans),
				'other' => q(pesos cubans),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo dal Cap Verd),
				'one' => q(escudo dal Cap Verd),
				'other' => q(escudos dal Cap Verd),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(glivra cipriota),
				'one' => q(glivra cipriota),
				'other' => q(glivras cipriotas),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(cruna tscheca),
				'one' => q(cruna tcheca),
				'other' => q(crunas tschecas),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(marc da la Germania da l’Ost),
				'one' => q(marc da la Germania da l’Ost),
				'other' => q(marcs da la Germania da l’Ost),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marc tudestg),
				'one' => q(marc tudestg),
				'other' => q(marcs tudestgs),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc dal Dschibuti),
				'one' => q(franc dal Dschibuti),
				'other' => q(francs dal Dschibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(cruna danaisa),
				'one' => q(cruna danaisa),
				'other' => q(crunas danaisas),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
				'one' => q(pesos dominicans),
				'other' => q(pesos dominicans),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerian),
				'one' => q(dinar algerian),
				'other' => q(dinars algerians),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre equadorian),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unitad da scuntrada da l’Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(cruna estona),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(glivra egipziana),
				'one' => q(glivra egipziana),
				'other' => q(glivras egipzianas),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreic),
				'one' => q(nakfa eritreic),
				'other' => q(nakfas eritreics),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta spagnola \(conto A\)),
				'one' => q(peseta spagnola \(conto A\)),
				'other' => q(pesetas spagnolas \(conto A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta spagnola \(conto convertibel\)),
				'one' => q(peseta spagnola \(conto convertibel\)),
				'other' => q(pesetas spagnolas \(conto convertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta spagnola),
				'one' => q(peseta spagnola),
				'other' => q(pesetas spagnolas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiopic),
				'one' => q(birr etiopic),
				'other' => q(birrs etiopics),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marc finlandais),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dollar dal Fidschi),
				'one' => q(dollar dal Fidschi),
				'other' => q(dollars dal Fidschi),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(glivra dal Falkland),
				'one' => q(glivras dal Falkland),
				'other' => q(glivras dal Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franc franzos),
				'one' => q(franc franzos),
				'other' => q(francs franzos),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(glivra britannica),
				'one' => q(glivra britannica),
				'other' => q(glivras britannicas),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgian),
				'one' => q(kupon larit georgian),
				'other' => q(kupon larits georgians),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgian),
				'one' => q(lari georgian),
				'other' => q(laris georgians),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanais \(1979–2007\)),
				'one' => q(cedi ghanais \(1979–2007\)),
				'other' => q(cedis ghanais \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanais),
				'one' => q(cedi ghanais),
				'other' => q(cedis ghanais),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(glivra da Gibraltar),
				'one' => q(glivra da Gibraltar),
				'other' => q(glivras da Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambic),
				'one' => q(dalasi gambic),
				'other' => q(dalasis gambics),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc da la Guinea),
				'one' => q(franc da la Guinea),
				'other' => q(francs da la Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli da la Guinea),
				'one' => q(sylis da la Guinea),
				'other' => q(sylis da la Guinea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele da la Guinea Equatoriala),
				'one' => q(ekweles da la Guinea Equatoriala),
				'other' => q(ekweles da la Guinea Equatoriala),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drachma greca),
				'one' => q(drachma greca),
				'other' => q(drachmas grecas),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal da la Guatemala),
				'one' => q(quetzals da la Guatemala),
				'other' => q(quetzals da la Guatemala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escudo da la Guinea Portugaisa),
				'one' => q(escudos da la Guinea Portugaisa),
				'other' => q(escudos da la Guinea Portugaisa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso da la Guinea-Bissau),
				'one' => q(peso da la Guinea-Bissau),
				'other' => q(pesos da la Guinea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollar da la Guyana),
				'one' => q(dollars da la Guyana),
				'other' => q(dollars da la Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dollar da Hongkong),
				'one' => q(dollar da Hongkong),
				'other' => q(dollars da Hongkong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira hondurian),
				'one' => q(lempira hondurian),
				'other' => q(lempiras hondurians),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croat),
				'one' => q(dinar croat),
				'other' => q(dinars croats),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunas croatas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitian),
				'one' => q(gourdes haitians),
				'other' => q(gourdes haitians),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint ungarais),
				'one' => q(forint ungarais),
				'other' => q(forints ungarais),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonaisa),
				'one' => q(rupia indonaisa),
				'other' => q(rupias indonaisas),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(glivra indonaisa),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(glivra israeliana),
				'one' => q(glivra israeliana),
				'other' => q(glivras israelianas),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(schekel israelian \(1980–1985\)),
				'one' => q(schekel israelian \(1980–1985\)),
				'other' => q(schekels israelians \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nov schekel israelian),
				'one' => q(nov schekel israelian),
				'other' => q(novs schekels israelians),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia indica),
				'one' => q(rupia indica),
				'other' => q(rupias indicas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar iracais),
				'one' => q(dinar iracais),
				'other' => q(dinars iracais),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranais),
				'one' => q(rial iranais),
				'other' => q(rials iranais),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(veglia cruna islandaisa),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(cruna islandaisa),
				'one' => q(cruna islandaisa),
				'other' => q(crunas islandaisas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira taliana),
				'one' => q(lira taliana),
				'other' => q(liras talianas),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dollar giamaican),
				'one' => q(dollar giamaican),
				'other' => q(dollars giamaicans),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordanic),
				'one' => q(dinar jordanic),
				'other' => q(dinars jordanics),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen giapunais),
				'one' => q(yen giapunais),
				'other' => q(yens giapunais),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(schilling kenian),
				'one' => q(schilling kenian),
				'other' => q(schillings kenians),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirgis),
				'one' => q(som kirgis),
				'other' => q(soms kirgis),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambodschan),
				'one' => q(riel cambodschan),
				'other' => q(riels cambodschans),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franc comorian),
				'one' => q(franc comorian),
				'other' => q(francs comorians),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won da la Corea dal Nord),
				'one' => q(won da la Corea dal Nord),
				'other' => q(wons da la Corea dal Nord),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan da la Corea dal Sid \(1953–1962\)),
				'one' => q(hwan da la Corea dal Sid \(1953–1962\)),
				'other' => q(hwans da la Corea dal Sid \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(won da la Corea dal Sid \(1945–1953\)),
				'one' => q(won da la Corea dal Sid \(1945–1953\)),
				'other' => q(wons da la Corea dal Sid \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won da la Corea dal Sid),
				'one' => q(won da la Corea dal Sid),
				'other' => q(wons da la Corea dal Sid),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar dal Kuwait),
				'one' => q(dinar dal Kuwait),
				'other' => q(dinars dal Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dollar da las Inslas Cayman),
				'one' => q(dollar da las Inslas Cayman),
				'other' => q(dollars da las Inslas Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kasac),
				'one' => q(tenge kasac),
				'other' => q(tenges kasacs),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laot),
				'one' => q(kip laot),
				'other' => q(kips laots),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(glivra libanaisa),
				'one' => q(glivra libanaisa),
				'other' => q(glivras libanaisas),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia da la Sri Lanka),
				'one' => q(rupia da la Sri Lanka),
				'other' => q(rupias da la Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollar liberian),
				'one' => q(dollar liberian),
				'other' => q(dollars liberians),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti dal Lesotho),
				'one' => q(loti dal Lesotho),
				'other' => q(lotis dal Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituan),
				'one' => q(litas lituans),
				'other' => q(litas lituans),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituan),
				'one' => q(talonas lituan),
				'other' => q(talonas lituans),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertibel luxemburgais),
				'one' => q(francs convertibels luxemburgais),
				'other' => q(francs convertibels luxemburgais),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxemburgais),
				'one' => q(franc luxemburgais),
				'other' => q(francs luxemburgais),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc finanzial luxemburgais),
				'one' => q(franc finanzial luxemburgais),
				'other' => q(francs finanzials luxemburgais),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats letton),
				'one' => q(lats letton),
				'other' => q(lats lettons),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rubel letton),
				'one' => q(rubel letton),
				'other' => q(rubels lettons),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libic),
				'one' => q(dinar libic),
				'other' => q(dinars libics),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocan),
				'one' => q(dirham marocan),
				'other' => q(dirhams marocans),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franc marocan),
				'one' => q(franc marocan),
				'other' => q(francs marocans),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(franc monegass),
				'one' => q(franc monegass),
				'other' => q(francs monegass),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(cupon moldav),
				'one' => q(cupon moldav),
				'other' => q(cupons moldavs),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldav),
				'one' => q(leu moldav),
				'other' => q(leus moldavs),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary madagasc),
				'one' => q(ariary madagasc),
				'other' => q(ariarys madagascs),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franc madagasc),
				'one' => q(franc madagasc),
				'other' => q(francs madagascs),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinar macedon),
				'one' => q(dinar macedon),
				'other' => q(dinars macedons),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(dinar macedon \(1992–1993\)),
				'one' => q(dinar macedon \(1992–1993\)),
				'other' => q(dinars macedons \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franc dal Mali),
				'one' => q(franc dal Mali),
				'other' => q(francs dal Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat dal Myanmar),
				'one' => q(kyat dal Myanmar),
				'other' => q(kyats dal Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongolic),
				'one' => q(tugrik mongolic),
				'other' => q(tugriks mongolics),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca dal Macao),
				'one' => q(pataca dal Macao),
				'other' => q(patacas dal Macao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya da la Mauretania \(1973–2017\)),
				'one' => q(ouguiya da la Mauretania \(1973–2017\)),
				'other' => q(ouguiyas da la Mauretania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya da la Mauretania),
				'one' => q(ouguiya da la Mauretania),
				'other' => q(ouguiyas da la Mauretania),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltaisa),
				'one' => q(lira maltaisa),
				'other' => q(liras maltaisas),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(glivra maltaisa),
				'one' => q(glivra maltaisa),
				'other' => q(glivras maltaisas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia dal Mauritius),
				'one' => q(rupia dal Mauritius),
				'other' => q(rupias dal Mauritius),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(rupia da las Maledivas \(1947–1981\)),
				'one' => q(rupia da las Maledivas \(1947–1981\)),
				'other' => q(rupias da las Maledivas \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa da las Maledivas),
				'one' => q(rufiyaa da las Maledivas),
				'other' => q(rufiyaas da las Maledivas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha dal Malawi),
				'one' => q(kwacha dal Malawi),
				'other' => q(kwachas dal Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso mexican),
				'one' => q(peso mexican),
				'other' => q(pesos mexicans),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso d’argient mexican \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unidad de inversion mexicana \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malaisic),
				'one' => q(ringgit malaisic),
				'other' => q(ringgits malaisics),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo dal Mosambic),
				'one' => q(escudo dal Mosambic),
				'other' => q(escudos dal Mosambic),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metical dal Mosambic \(1980–2006\)),
				'one' => q(metical dal Mosambic \(1980–2006\)),
				'other' => q(meticals dal Mosambic \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical dal Mosambic),
				'one' => q(metical dal Mosambic),
				'other' => q(meticals dal Mosambic),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dollar namibian),
				'one' => q(dollar namibian),
				'other' => q(dollars namibians),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(nairas nigerianas),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba nicaraguan),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaraguan),
				'one' => q(córdoba nicaraguan),
				'other' => q(córdobas nicaraguans),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(flurin ollandais),
				'one' => q(flurin ollandais),
				'other' => q(flurins ollandais),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(cruna norvegiaisa),
				'one' => q(cruna norvegiaisa),
				'other' => q(crunas norvegiaisas),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalaisa),
				'one' => q(rupia nepalaisa),
				'other' => q(rupias nepalaisas),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dollar da la Nova Zelanda),
				'one' => q(dollar da la Nova Zelanda),
				'other' => q(dollars da la Nova Zelanda),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial da l’Oman),
				'one' => q(rial da l’Oman),
				'other' => q(rials da l’Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa dal Panama),
				'one' => q(balboas dal Panama),
				'other' => q(balboas dal Panama),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruan),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruan),
				'one' => q(soles peruans),
				'other' => q(soles peruans),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruan \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina da la Papua Nova Guinea),
				'one' => q(kina da la Papua Nova Guinea),
				'other' => q(kinas da la Papua Nova Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(peso filippin),
				'one' => q(peso filippin),
				'other' => q(pesos filippins),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistana),
				'one' => q(rupia pakistana),
				'other' => q(rupias pakistanas),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polac),
				'one' => q(zloty polac),
				'other' => q(zlotys polacs),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty polac \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo portugais),
				'one' => q(escudo portugais),
				'other' => q(escudos portugais),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani paraguaian),
				'one' => q(guaranis paraguaians),
				'other' => q(guaranis paraguaians),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial da Katar),
				'one' => q(rial da Katar),
				'other' => q(rials da Katar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dollar rodesian),
				'one' => q(dollars rodesians),
				'other' => q(dollars rodesians),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu rumen \(1952–2006\)),
				'one' => q(leu rumen \(1952–2006\)),
				'other' => q(leus rumens \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu rumen),
				'one' => q(leu rumen),
				'other' => q(leus rumens),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serb),
				'one' => q(dinar serb),
				'other' => q(dinars serbs),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rubel russ),
				'one' => q(rubel russ),
				'other' => q(rubels russ),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rubel russ \(vegl\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franc ruandais),
				'one' => q(franc ruandais),
				'other' => q(francs ruandais),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal saudit),
				'one' => q(riyal saudit),
				'other' => q(riyals saudits),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollar da las Inslas da Salomon),
				'one' => q(dollar da las Inslas da Salomon),
				'other' => q(dollars da las Inslas da Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia da las Seychellas),
				'one' => q(rupia da las Seychellas),
				'other' => q(rupias da las Seychellas),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanais \(1992–2007\)),
				'one' => q(dinar sudanais \(1992–2007\)),
				'other' => q(dinars sudanais \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(glivra sudanaisa),
				'one' => q(glivra sudanaisa),
				'other' => q(glivras sudanaisas),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(glivra sudanaisa \(1957–1998\)),
				'one' => q(glivra sudanaisa \(1957–1998\)),
				'other' => q(glivras sudanaisas \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(cruna svedaisa),
				'one' => q(cruna svedaisa),
				'other' => q(crunas svedaisas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dollar dal Singapur),
				'one' => q(dollar dal Singapur),
				'other' => q(dollars dal Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(glivra da Sontg’Elena),
				'one' => q(glivra da Sontg’Elena),
				'other' => q(glivras da Sontg’Elena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar sloven),
				'one' => q(tolar sloven),
				'other' => q(tolars slovens),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(cruna slovaca),
				'one' => q(cruna slovaca),
				'other' => q(crunas slovacas),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone da la Sierra Leone),
				'one' => q(leone da la Sierra Leone),
				'other' => q(leones da la Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone da la Sierra Leone \(1964—2022\)),
				'one' => q(leone da la Sierra Leone \(1964—2022\)),
				'other' => q(leones da la Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(schilling somalian),
				'one' => q(schilling somalian),
				'other' => q(schillings somalians),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dollar surinam),
				'one' => q(dollars surinams),
				'other' => q(dollars surinams),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(flurin surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(glivra sidsudanaisa),
				'one' => q(glivra sidsudanaisa),
				'other' => q(glivras sidsudanaisas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra da São Tomé e Principe \(1977–2017\)),
				'one' => q(dobra da São Tomé e Príncipe \(1977–2017\)),
				'other' => q(dobras da São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra da São Tomé e Principe),
				'one' => q(dobra da São Tomé e Príncipe),
				'other' => q(dobras da São Tomé e Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rubel sovietic),
				'one' => q(rubel sovietic),
				'other' => q(rubels sovietics),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colon da l’El Salvador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(glivra siriana),
				'one' => q(glivra siriana),
				'other' => q(glivras sirianas),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni dal Swaziland),
				'one' => q(lilangeni dal Swaziland),
				'other' => q(emalangenis dal Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandais),
				'one' => q(baht tailandais),
				'other' => q(bahts tailandais),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rubel tadschic),
				'one' => q(rubel tadschic),
				'other' => q(rubels tadschics),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tadschic),
				'one' => q(somoni tadschic),
				'other' => q(somonis tadschics),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmen \(1993–2009\)),
				'one' => q(manat turkmen \(1993–2009\)),
				'other' => q(manats turkmens \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmen),
				'one' => q(manat turkmen),
				'other' => q(manats turkmens),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunesian),
				'one' => q(dinar tunesian),
				'other' => q(dinars tunesians),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga da Tonga),
				'one' => q(paʻanga da Tonga),
				'other' => q(pa’angas da Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo dal Timor),
				'one' => q(escudo dal Timor),
				'other' => q(escudos dal Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira tirca \(1922–2005\)),
				'one' => q(lira tirca \(1922–2005\)),
				'other' => q(liras tircas \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lira tirca),
				'one' => q(lira tirca),
				'other' => q(liras tircas),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dollar da Trinidad e Tobago),
				'one' => q(dollars da Trinidad e Tobago),
				'other' => q(dollars da Trinidad e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(nov dollar taiwanais),
				'one' => q(nov dollar taiwanais),
				'other' => q(novs dollars taiwanais),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(schilling tansanian),
				'one' => q(schilling tansanian),
				'other' => q(schillings tansanians),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ucranaisa),
				'one' => q(hryvnia ucranaisa),
				'other' => q(hryvnias ucranaisas),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanets ucranais),
				'one' => q(karbovanets ucranais),
				'other' => q(karbovantsiv ucranais),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(schilling ugandais \(1966–1987\)),
				'one' => q(schilling ugandais \(1966–1987\)),
				'other' => q(schillings ugandais \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(schilling ugandais),
				'one' => q(schilling ugandais),
				'other' => q(schillings ugandais),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(dollar da l’USA),
				'one' => q(dollar da l’USA),
				'other' => q(dollars da l’USA),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dollar dals Stadis Unids da l’America \(proxim di\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dollar dals Stadis Unids da l’America \(medem di\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso da l’Uruguay \(unidades indexadas\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(nov peso da l’Uruguay \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso da l’Uruguay),
				'one' => q(peso da l’Uruguai),
				'other' => q(pesos da l’Uruguai),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som usbec),
				'one' => q(som usbec),
				'other' => q(soms usbecs),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar venezuelan \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar venezuelan \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar venezuelan),
				'one' => q(bolívar venezuelan),
				'other' => q(bolívars venezuelans),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamais),
				'one' => q(dong vietnamais),
				'other' => q(dongs vietnamais),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong vietnamais \(1978–1985\)),
				'one' => q(dong vietnamais \(1978–1985\)),
				'other' => q(dongs vietnamais \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu dal Vanuatu),
				'one' => q(vatu dal Vanuatu),
				'other' => q(vatus dal Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala da la Samoa),
				'one' => q(tala da la Samoa),
				'other' => q(talas da la Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA da l’Africa Centrala),
				'one' => q(franc CFA da l’Africa Centrala),
				'other' => q(francs CFA da l’Africa Centrala),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(argient),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(aur),
				'one' => q(unza d’aur),
				'other' => q(unzas d’aur),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unitad europeica cumponida),
				'one' => q(unitads europeicas cumponidas),
				'other' => q(unitads europeicas cumponidas),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unitad dal quint europeica \(XBC\)),
				'one' => q(unitad dal quint europeica \(XBC\)),
				'other' => q(unitads dal quint europeicas \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unitad dal quint europeica \(XBD\)),
				'one' => q(unitads dal quint europeicas \(XBD\)),
				'other' => q(unitads dal quint europeicas \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dollar da la Caribica Orientala),
				'one' => q(dollar da la Caribica Orientala),
				'other' => q(dollars da la Caribica Orientala),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(dretgs da prelevaziun spezials),
				'one' => q(dretg da prelevaziun spezial),
				'other' => q(dretgs da prelevaziun spezials),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unitad monetara europeica),
				'one' => q(unitad monetara europeica),
				'other' => q(unitads monetaras europeicas),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc d’aur franzos),
				'one' => q(francs d’aur franzos),
				'other' => q(francs d’aur franzos),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC franzos),
				'one' => q(francs UIC franzos),
				'other' => q(francs UIC franzos),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA da l’Africa dal Vest),
				'one' => q(franc CFA da l’Africa dal Vest),
				'other' => q(francs CFA da l’Africa dal Vest),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladi),
				'one' => q(unza da palladi),
				'other' => q(unzas da palladi),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franc CFP),
				'one' => q(franc CFP),
				'other' => q(francs CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platin),
				'one' => q(unza da platin),
				'other' => q(unzas da platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fonds RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(zutger),
				'one' => q(zutger),
				'other' => q(zutgers),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(code per verifitgar la valuta),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(valuta nunenconuschenta),
				'one' => q(\(unitad nunenconuschenta da la valuta\)),
				'other' => q(\(valuta nunenconuschenta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar jemenit),
				'one' => q(dinar jemenit),
				'other' => q(dinars jemenits),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial jemenit),
				'one' => q(rial jemenit),
				'other' => q(rials jemenits),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar jugoslav dir \(1966–1990\)),
				'one' => q(dinar jugoslav dir \(1966–1990\)),
				'other' => q(dinars jugoslavs dirs \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(nov dinar jugoslav \(1994–2002\)),
				'one' => q(nov dinar jugoslav \(1994–2002\)),
				'other' => q(novs dinars jugoslavs \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar jugoslav convertibel \(1990–1992\)),
				'one' => q(dinar jugoslav convertibel \(1990–1992\)),
				'other' => q(dinars jugoslavs convertibels \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar jugoslav refurmà \(1992–1993\)),
				'one' => q(dinar jugoslav refurmà \(1992–1993\)),
				'other' => q(dinars jugoslavs refurmads \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sidafrican \(finanzial\)),
				'one' => q(rand sidafrican \(finanzial\)),
				'other' => q(rands sidafricans \(finanzial\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sidafrican),
				'one' => q(rand sidafrican),
				'other' => q(rands sidafricans),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha da la Sambia \(1968–2012\)),
				'one' => q(kwacha da la Sambia \(1968–2012\)),
				'other' => q(kwachas da la Sambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha da la sambia),
				'one' => q(kwacha da la Sambia),
				'other' => q(kwachas da la Sambia),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nov zaire dal Zaire \(1993–1998\)),
				'one' => q(nov zaire dal Zaire \(1993–1998\)),
				'other' => q(novs zaires dal Zaire \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire dal Zaire),
				'one' => q(zaire dal Zaire \(1971–1993\)),
				'other' => q(zaires dal Zaire \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dollar dal Simbabwe \(1980–2008\)),
				'one' => q(dollar dal Simbabwe \(1980–2008\)),
				'other' => q(dollars dal Simbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dollar dal Simbabwe \(2009\)),
				'one' => q(dollar dal Simbabwe \(2009\)),
				'other' => q(dollars dal Simbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dollar dal Simbabwe \(2008\)),
				'one' => q(dollar dal Simbabwe \(2008\)),
				'other' => q(dollars dal Simbabwe \(2008\)),
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
							'schan.',
							'favr.',
							'mars',
							'avr.',
							'matg',
							'zercl.',
							'fan.',
							'avust',
							'sett.',
							'oct.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'da schaner',
							'da favrer',
							'da mars',
							'd’avrigl',
							'da matg',
							'da zercladur',
							'da fanadur',
							'd’avust',
							'da settember',
							'd’october',
							'da november',
							'da december'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'S',
							'F',
							'M',
							'A',
							'M',
							'Z',
							'F',
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
							'schaner',
							'favrer',
							'mars',
							'avrigl',
							'matg',
							'zercladur',
							'fanadur',
							'avust',
							'settember',
							'october',
							'november',
							'december'
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
						mon => 'gli',
						tue => 'ma',
						wed => 'me',
						thu => 'gie',
						fri => 've',
						sat => 'so',
						sun => 'du'
					},
					wide => {
						mon => 'glindesdi',
						tue => 'mardi',
						wed => 'mesemna',
						thu => 'gievgia',
						fri => 'venderdi',
						sat => 'sonda',
						sun => 'dumengia'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'G',
						tue => 'M',
						wed => 'M',
						thu => 'G',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1. quartal',
						1 => '2. quartal',
						2 => '3. quartal',
						3 => '4. quartal'
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
				'0' => 'av. Cr.',
				'1' => 's. Cr.'
			},
			wide => {
				'0' => 'avant Cristus',
				'1' => 'suenter Cristus'
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
			'full' => q{EEEE, 'ils' d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd-MM-y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, 'ils' d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{dd-MM-y},
			'short' => q{dd-MM-yy},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, dd-MM-y GGGGG},
			GyMMMMEd => q{E, d MMMM y G},
			GyMMMMd => q{d MMMM y G},
			GyMMMd => q{dd-MM-y GGGGG},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			MEd => q{E, dd-MM},
			MMMEd => q{E, dd-MM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{dd-MM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			y => q{y G},
			yM => q{MM-y GGGGG},
			yMEd => q{E, dd-MM-y GGGGG},
			yMMM => q{LLL y G},
			yMMMEd => q{E, dd-MM-y GGGGG},
			yMMMM => q{LLLL y G},
			yMMMMEd => q{E, d MMMM y G},
			yMMMMd => q{d MMMM y G},
			yMMMd => q{dd-MM-y GGGGG},
			yQQQ => q{QQQ y G},
			yQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, dd-MM-y GGGGG},
			GyMMMMEd => q{E, d MMMM y G},
			GyMMMMd => q{d MMMM y G},
			GyMMMd => q{dd-MM-y GGGGG},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E, dd-MM},
			MMMEd => q{E, dd-MM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{W. 'emna' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{dd-MM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{LL-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{LLL y},
			yMMMEd => q{E, dd-MM-y},
			yMMMM => q{LLLL y},
			yMMMMEd => q{E, d MMMM y},
			yMMMMd => q{d MMMM y},
			yMMMd => q{dd-MM-y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'emna' 'dal' Y},
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
				M => q{LL–LL},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMMEd => {
				M => q{E, d MMMM – E, d MMMM},
				d => q{E, d. – E, d MMMM},
			},
			MMMMd => {
				M => q{d MMMM – d MMMM},
				d => q{d.–d MMMM},
			},
			MMMd => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
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
				y => q{y–y G},
			},
			yM => {
				M => q{LL-y – LL-y GGGGG},
				y => q{LL-y – LL-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{LLL–LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM y G},
				d => q{E, d. – E, d MMMM y G},
				y => q{E, d MMMM y – E, d MMMM y G},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM y G},
				d => q{d.–d MMMM y G},
				y => q{d MMMM y – d MMMM y G},
			},
			yMMMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
			M => {
				M => q{LL–LL},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMMEd => {
				M => q{E, d MMMM – E, d MMMM},
				d => q{E, d. – E, d MMMM},
			},
			MMMMd => {
				M => q{d MMMM – d MMMM},
				d => q{d.–d MMMM},
			},
			MMMd => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
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
				M => q{LL-y – LL-y},
				y => q{LL-y – LL-y},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y},
				d => q{E, dd-MM-y – E, dd-MM-y},
				y => q{E, dd-MM-y – E, dd-MM-y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y},
				d => q{E, dd-MM-y – E, dd-MM-y},
				y => q{E, dd-MM-y – E, dd-MM-y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM y},
				d => q{E, d. – E, d MMMM y},
				y => q{E, d MMMM y – E, d MMMM y},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM y},
				d => q{d.–d MMMM y},
				y => q{d MMMM y – d MMMM y},
			},
			yMMMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(temp: {0}),
		regionFormat => q(temp da stad: {0}),
		regionFormat => q(temp normal: {0}),
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
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
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadischu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Alasca#,
		},
		'America/Anguilla' => {
			exemplarCity => q#The Valley#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan, Argentinia#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaïa#,
		},
		'America/Aruba' => {
			exemplarCity => q#Oranjestad#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#Belmopan#,
		},
		'America/Cayman' => {
			exemplarCity => q#Inslas Cayman#,
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
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Godthab' => {
			exemplarCity => q#Godthåb#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Cockburn Town#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Basse-Terre#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Giamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#San Salvador de Jujuy#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Citad da Mexico#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Saint Pierre#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Brades#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#North Dakota (Central)#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#North Dakota (New Salem)#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America/Tortola' => {
			exemplarCity => q#Road Town#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Temp da stad central#,
				'generic' => q#Temp central#,
				'standard' => q#Temp da standard central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Temp da stad oriental#,
				'generic' => q#Temp oriental#,
				'standard' => q#Temp da standard oriental#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Temp da stad da muntogna#,
				'generic' => q#Temp da muntogna#,
				'standard' => q#Temp da standard da muntogna#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Temp da stad pacific#,
				'generic' => q#Temp pacific#,
				'standard' => q#Temp da standard pacific#,
			},
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mac Murdo#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bandar Seri Begawan#,
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
		'Asia/Karachi' => {
			exemplarCity => q#Karatschi#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macassar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Citad da Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Temp da stad atlantic#,
				'generic' => q#Temp atlantic#,
				'standard' => q#Temp da standard atlantic#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoras#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Inslas Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cap Verd#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Inslas Feroe#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia dal Sid#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sontg’elena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Port Stanley#,
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Temp universal coordinà#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#citad nunenconuschenta#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Saint Peter Port#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Douglas#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Saint Helier#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#temp da stad britannic#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscau#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Turitg#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Temp da stad da l’Europa Centrala#,
				'generic' => q#Temp da l’Europa Centrala#,
				'standard' => q#Temp da standard da l’Europa Centrala#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Temp da stad da l’Europa Orientala#,
				'generic' => q#Temp da l’Europa Orientala#,
				'standard' => q#Temp da standard da l’Europa Orientala#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Temp da stad da l’Europa dal Vest#,
				'generic' => q#Temp da l’Europa dal Vest#,
				'standard' => q#Temp da standard da l’Europa dal Vest#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Temp Greenwich#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Flying Fish Cove#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#West Island#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoras#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Insla da Pasca#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Rikitea#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Honiara#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Hagåtña#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Tofol#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Yaren#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Alofi#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Kingston#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Melekok#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Palikir#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#South Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Nukuʻalofa#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Weno#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Matāʻutu#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
