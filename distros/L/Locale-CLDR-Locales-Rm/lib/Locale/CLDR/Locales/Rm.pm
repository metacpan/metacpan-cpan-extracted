=head1

Locale::CLDR::Locales::Rm - Package for language Romansh

=cut

package Locale::CLDR::Locales::Rm;
# This file auto generated from Data\common\main\rm.xml
#	on Fri 29 Apr  7:22:10 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
				'aa' => 'afar',
 				'ab' => 'abchasian',
 				'ace' => 'aceh',
 				'ach' => 'acoli',
 				'ada' => 'andangme',
 				'ady' => 'adygai',
 				'ae' => 'avestic',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
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
 				'arc' => 'arameic',
 				'arn' => 'araucanic',
 				'arp' => 'arapaho',
 				'arw' => 'arawak',
 				'as' => 'assami',
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
 				'bs' => 'bosniac',
 				'bua' => 'buriat',
 				'bug' => 'bugi',
 				'byn' => 'blin',
 				'ca' => 'catalan',
 				'cad' => 'caddo',
 				'car' => 'caribic',
 				'cch' => 'atsam',
 				'ce' => 'tschetschen',
 				'ceb' => 'cebuano',
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
 				'de' => 'tudestg',
 				'de_AT' => 'tudestg austriac',
 				'del' => 'delaware',
 				'den' => 'slavey',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'doi' => 'dogri',
 				'dsb' => 'bass sorb',
 				'dua' => 'duala',
 				'dum' => 'ollandais mesaun',
 				'dv' => 'maledivic',
 				'dyu' => 'diula',
 				'dz' => 'dzongkha',
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
 				'en_GB@alt=short' => 'englais (GB)',
 				'en_US' => 'englais american',
 				'en_US@alt=short' => 'englais (US)',
 				'enm' => 'englais mesaun',
 				'eo' => 'esperanto',
 				'es' => 'spagnol',
 				'es_419' => 'spagnol latinamerican',
 				'es_ES' => 'spagnol iberic',
 				'es_MX' => 'spagnol mexican',
 				'et' => 'eston',
 				'eu' => 'basc',
 				'ewo' => 'ewondo',
 				'fa' => 'persian',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandais',
 				'fil' => 'filippino',
 				'fj' => 'fidschian',
 				'fo' => 'ferrais',
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
 				'ht' => 'haitian',
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
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'khasi',
 				'kho' => 'khotanais',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'casac',
 				'kl' => 'grönlandais',
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
 				'ku' => 'curd',
 				'kum' => 'kumuk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornic',
 				'ky' => 'kirghis',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgais',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgais',
 				'ln' => 'lingala',
 				'lo' => 'laot',
 				'lol' => 'lomongo',
 				'loz' => 'lozi',
 				'lt' => 'lituan',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
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
 				'mg' => 'malagassi',
 				'mga' => 'irlandais mesaun',
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
 				'mul' => 'pluriling',
 				'mus' => 'creek',
 				'mwl' => 'mirandais',
 				'mwr' => 'marwari',
 				'my' => 'birman',
 				'myv' => 'erzya',
 				'na' => 'nauru',
 				'nap' => 'neapolitan',
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
 				'nn' => 'norvegiais nynorsk',
 				'no' => 'norvegiais',
 				'nog' => 'nogai',
 				'non' => 'nordic vegl',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele dal sid',
 				'nso' => 'sotho dal nord',
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
 				'peo' => 'persian vegl',
 				'phn' => 'fenizian',
 				'pi' => 'pali',
 				'pl' => 'polac',
 				'pon' => 'ponapean',
 				'pro' => 'provenzal vegl',
 				'ps' => 'paschto',
 				'pt' => 'portugais',
 				'pt_BR' => 'portugais brasilian',
 				'pt_PT' => 'portugais iberian',
 				'qu' => 'quechua',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rm' => 'rumantsch',
 				'rn' => 'rundi',
 				'ro' => 'rumen',
 				'ro_MD' => 'moldav',
 				'rom' => 'romani',
 				'ru' => 'russ',
 				'rup' => 'aromunic',
 				'rw' => 'kinyarwanda',
 				'sa' => 'sanscrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakut',
 				'sam' => 'arameic samaritan',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sc' => 'sard',
 				'scn' => 'sicilian',
 				'sco' => 'scot',
 				'sd' => 'sindhi',
 				'se' => 'sami dal nord',
 				'sel' => 'selkup',
 				'sg' => 'sango',
 				'sga' => 'irlandais vegl',
 				'sh' => 'serbo-croat',
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
 				'syc' => 'siric classic',
 				'syr' => 'siric',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
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
 				'ty' => 'tahitian',
 				'tyv' => 'tuvinian',
 				'udm' => 'udmurt',
 				'ug' => 'uiguric',
 				'uga' => 'ugaritic',
 				'uk' => 'ucranais',
 				'umb' => 'mbundu',
 				'und' => 'linguas betg determinadas',
 				'ur' => 'urdu',
 				'uz' => 'usbec',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamais',
 				'vo' => 'volapuk',
 				'vot' => 'votic',
 				'wa' => 'vallon',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wo' => 'wolof',
 				'xal' => 'kalmuk',
 				'xh' => 'xhosa',
 				'yao' => 'yao',
 				'yap' => 'yapais',
 				'yi' => 'jiddic',
 				'yo' => 'yoruba',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'simbols da Bliss',
 				'zen' => 'zenaga',
 				'zh' => 'chinais',
 				'zh_Hans' => 'chinais simplifitgà',
 				'zh_Hant' => 'chinais tradiziunal',
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
			'Arab' => 'arab',
 			'Armi' => 'arameic imperial',
 			'Armn' => 'armen',
 			'Avst' => 'avestic',
 			'Bali' => 'balinais',
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
 			'Egyd' => 'egipzian demotic',
 			'Egyh' => 'egipzian ieratic',
 			'Egyp' => 'ieroglifas egipzianas',
 			'Ethi' => 'etiopic',
 			'Geok' => 'kutsuri',
 			'Geor' => 'georgian',
 			'Glag' => 'glagolitic',
 			'Goth' => 'gotic',
 			'Grek' => 'grec',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'scrittira chinaisa simplifitgada',
 			'Hant' => 'scrittira chinaisa tradiziunala',
 			'Hebr' => 'ebraic',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawn hmong',
 			'Hrkt' => 'katanaka u hiragana',
 			'Hung' => 'ungarais vegl',
 			'Inds' => 'indus',
 			'Ital' => 'italic vegl',
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
 			'Nkoo' => 'n’ko',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osma' => 'osman',
 			'Perm' => 'permic vegl',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi dad inscripziuns',
 			'Phlp' => 'pahlavi da psalms',
 			'Phlv' => 'pahlavi da cudeschs',
 			'Phnx' => 'fenizian',
 			'Plrd' => 'fonetica da Pollard',
 			'Prti' => 'partic dad inscripziuns',
 			'Rjng' => 'rejang',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runic',
 			'Samr' => 'samaritan',
 			'Sara' => 'sarati',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'lingua da segns',
 			'Shaw' => 'shavian',
 			'Sinh' => 'singalais',
 			'Sund' => 'sundanais',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siric',
 			'Syre' => 'siric estrangelo',
 			'Syrj' => 'siric dal vest',
 			'Syrn' => 'siric da l’ost',
 			'Tagb' => 'tagbanwa',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue',
 			'Taml' => 'tamil',
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
 			'Xpeo' => 'persian vegl',
 			'Xsux' => 'scrittira a cugn sumeric-accadica',
 			'Yiii' => 'yi',
 			'Zinh' => 'ertà',
 			'Zmth' => 'notaziun matematica',
 			'Zsym' => 'simbols',
 			'Zxxx' => 'linguas na scrittas',
 			'Zyyy' => 'betg determinà',
 			'Zzzz' => 'scrittira nunenconuschenta u nunvalaivla',

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
 			'019' => 'America dal Nord, America Centrala ed America dal Sid',
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
 			'419' => 'America Latina',
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
 			'BR' => 'Brasila',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Insla Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Inslas Cocos',
 			'CD' => 'Republica Democratica dal Congo',
 			'CF' => 'Republica Centralafricana',
 			'CG' => 'Congo',
 			'CH' => 'Svizra',
 			'CI' => 'Costa d’Ivur',
 			'CK' => 'Inslas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Columbia',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap Verd',
 			'CX' => 'Insla da Christmas',
 			'CY' => 'Cipra',
 			'CZ' => 'Republica Tscheca',
 			'DE' => 'Germania',
 			'DJ' => 'Dschibuti',
 			'DK' => 'Danemarc',
 			'DM' => 'Dominica',
 			'DO' => 'Republica Dominicana',
 			'DZ' => 'Algeria',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipta',
 			'EH' => 'Sahara Occidentala',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Uniun europeica',
 			'FI' => 'Finlanda',
 			'FJ' => 'Fidschi',
 			'FK' => 'Inslas dal Falkland',
 			'FM' => 'Micronesia',
 			'FO' => 'Inslas Feroe',
 			'FR' => 'Frantscha',
 			'GA' => 'Gabun',
 			'GB' => 'Reginavel Unì',
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
 			'HM' => 'Inslas da Heard e da McDonlad',
 			'HN' => 'Honduras',
 			'HR' => 'Croazia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungaria',
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
 			'KG' => 'Kirghisistan',
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
 			'MK' => 'Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MO' => 'Regiun d’administraziun speziala Macao, China',
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
 			'SB' => 'Salomonas',
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
 			'ST' => 'São Tomé e Principe',
 			'SV' => 'El Salvador',
 			'SY' => 'Siria',
 			'SZ' => 'Swaziland',
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
 			'UM' => 'Inslas pitschnas perifericas dals Stadis Unids da l’America',
 			'US' => 'Stadis Unids da l’America',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Citad dal Vatican',
 			'VC' => 'Saint Vincent e las Grenadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Inslas Verginas Britannicas',
 			'VI' => 'Inslas Verginas Americanas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Africa dal Sid',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Regiun betg encouschenta u nunvalaivla',

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
 			'collation' => 'zavrada',
 			'currency' => 'munaida',
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
 				'roc' => q{chalendar da la republica chinaisa},
 			},
 			'collation' => {
 				'big5han' => q{chinaisa tradiziunala - Big5},
 				'gb2312han' => q{chinaisa simplifitgada - GB2312},
 				'phonebook' => q{cudesch da telefon},
 				'pinyin' => q{Pinyin},
 				'standard' => q{zavrada da standard},
 				'stroke' => q{urden dals stritgs},
 				'traditional' => q{reglas tradiziunalas},
 			},
 			'numbers' => {
 				'armn' => q{dumbers armens},
 				'beng' => q{cifras bengalas},
 				'geor' => q{dumbers georgians},
 				'latn' => q{cifras europeicas},
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
			auxiliary => qr{(?^u:[á ă â å ä ā æ ç ĕ ê ë ē í ĭ î ï ī ñ ó ŏ ô ö ø ō œ ú ŭ û ü ū ÿ])},
			index => ['A', 'À', 'B', 'C', 'D', 'E', 'É', 'È', 'F', 'G', 'H', 'I', 'Ì', 'J', 'K', 'L', 'M', 'N', 'O', 'Ò', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ù', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{(?^u:[a à b c d e é è f g h i ì j k l m n o ò p q r s t u ù v w x y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'À', 'B', 'C', 'D', 'E', 'É', 'È', 'F', 'G', 'H', 'I', 'Ì', 'J', 'K', 'L', 'M', 'N', 'O', 'Ò', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ù', 'V', 'W', 'X', 'Y', 'Z'], };
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
					'celsius' => {
						'name' => q(grads celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grads celsius),
					},
					'centimeter' => {
						'name' => q(centimeters),
						'one' => q({0} centimeter),
						'other' => q({0} centimeters),
					},
					'day' => {
						'name' => q(dis),
						'one' => q({0} di),
						'other' => q({0} dis),
					},
					'gram' => {
						'name' => q(grams),
						'one' => q({0} gram),
						'other' => q({0} grams),
					},
					'hour' => {
						'name' => q(uras),
						'one' => q({0} ura),
						'other' => q({0} uras),
					},
					'kilogram' => {
						'name' => q(kilograms),
						'one' => q({0} kilogram),
						'other' => q({0} kilograms),
					},
					'kilometer' => {
						'name' => q(kilometers),
						'one' => q({0} kilometer),
						'other' => q({0} kilometers),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometers per ura),
						'one' => q({0} kilometer per ura),
						'other' => q({0} kilometers per ura),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} liter),
						'other' => q({0} liters),
					},
					'meter' => {
						'name' => q(meters),
						'one' => q({0} meter),
						'other' => q({0} meters),
					},
					'millimeter' => {
						'name' => q(millimeters),
						'one' => q({0} millimeter),
						'other' => q({0} millimeters),
					},
					'millisecond' => {
						'name' => q(millisecundas),
						'one' => q({0} millisecunda),
						'other' => q({0} millisecundas),
					},
					'minute' => {
						'name' => q(minutas),
						'one' => q({0} minuta),
						'other' => q({0} minutas),
					},
					'month' => {
						'name' => q(mais),
						'one' => q({0} mais),
						'other' => q({0} mais),
					},
					'second' => {
						'name' => q(secundas),
						'one' => q({0} secunda),
						'other' => q({0} secundas),
					},
					'week' => {
						'name' => q(emnas),
						'one' => q({0} emna),
						'other' => q({0} emnas),
					},
					'year' => {
						'name' => q(onns),
						'one' => q({0} onn),
						'other' => q({0} onns),
					},
				},
				'narrow' => {
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'day' => {
						'name' => q(di),
						'one' => q({0} dis),
						'other' => q({0} dis),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(ura),
						'one' => q({0} uras),
						'other' => q({0} uras),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} mins.),
						'other' => q({0} mins.),
					},
					'month' => {
						'name' => q(mais),
						'one' => q({0} mais),
						'other' => q({0} mais),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} secs.),
						'other' => q({0} secs.),
					},
					'week' => {
						'name' => q(emna),
						'one' => q({0} emnas),
						'other' => q({0} emnas),
					},
					'year' => {
						'name' => q(onn),
						'one' => q({0} onns),
						'other' => q({0} onns),
					},
				},
				'short' => {
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'day' => {
						'name' => q(dis),
						'one' => q({0} di),
						'other' => q({0} dis),
					},
					'gram' => {
						'name' => q(grams),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(uras),
						'one' => q({0} ura),
						'other' => q({0} uras),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'meter' => {
						'name' => q(meters),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(minutas),
						'one' => q({0} min.),
						'other' => q({0} mins.),
					},
					'month' => {
						'name' => q(mais),
						'one' => q({0} mais),
						'other' => q({0} mais),
					},
					'second' => {
						'name' => q(secundas),
						'one' => q({0} sec.),
						'other' => q({0} secs.),
					},
					'week' => {
						'name' => q(emnas),
						'one' => q({0} emna),
						'other' => q({0} emnas),
					},
					'year' => {
						'name' => q(onns),
						'one' => q({0} onn),
						'other' => q({0} onns),
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
				'standard' => {
					'' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##0 %',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'' => '#E0',
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
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham dals Emirats Arabs Unids),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanais \(1947–1961\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armen),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(flurin da las Antillas Olandaisas),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolan),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolan \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nov kwanza angolan),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolan reajustado),
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
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(schilling austriac),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(dollar australian),
				'one' => q(dollar australian),
				'other' => q(dollar australian),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(flurin da l’Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat aserbaidschanic \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat aserbaidschanic),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar da la Bosnia ed Erzegovina),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marc convertibel bosniac),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nov dinar da la Bosnia ed Erzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollar da Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladais),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franc beltg \(convertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franc beltg),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franc beltg \(finanzial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev bulgar),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev bulgar socialistic),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(nov lev bulgar),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(vegl lev bulgar),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar dal Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc dal Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dollar da las Bermudas),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dollar dal Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano),
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
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum butanais),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat burmais),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula da la Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nov rubel bieloruss \(1994–1999\)),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rubel bieloruss),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dollar dal Belize),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(dollar canadais),
				'one' => q(dollar canadais),
				'other' => q(dollar canadais),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolais),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franc svizzer),
				'one' => q(franc svizzer),
				'other' => q(franc svizzer),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(franc WIR),
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
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan renminbi chinais),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso columbian),
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
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(vegl dinar serb),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(cruna tschecoslovaca),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cuban),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo dal Cap Verd),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(glivra cipriota),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(cruna tscheca),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(marc da la Germania da l’Ost),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marc tudestg),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc dal Dschibuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(cruna danaisa),
				'one' => q(cruna danaisa),
				'other' => q(cruna danaisa),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerian),
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
			symbol => 'EEK',
			display_name => {
				'currency' => q(cruna estona),
				'one' => q(cruna estona),
				'other' => q(cruna estona),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(glivra egipziana),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreic),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta spagnola \(conto A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta spagnola \(conto convertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta spagnola),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiopic),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(marc finlandais),
				'one' => q(marc finlandais),
				'other' => q(marc finlandais),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dollar dal Fidschi),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(glivra dal Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franc franzos),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(glivra sterlina),
				'one' => q(glivra sterlina),
				'other' => q(glivra sterlina),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgian),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgian),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanais \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanais),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(glivra da Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambic),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc da la Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli da la Guinea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele da la Guinea Equatoriala),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drachma greca),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal da la Guatemala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escudo da la Guinea Portugaisa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso da la Guinea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollar da la Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dollar da Hongkong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(lempira hondurian),
				'one' => q(lempira hondurian),
				'other' => q(lempira hondurian),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croat),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitian),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint ungarais),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonaisa),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(glivra indonaisa),
				'one' => q(glivra indonaisa),
				'other' => q(glivra indonaisa),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(glivra israeliana),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(vegl sheqel israelian),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(sheqel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia indica),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar iracais),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranais),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(veglia cruna islandaisa),
				'one' => q(veglia cruna islandaisa),
				'other' => q(veglia cruna islandaisa),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(cruna islandaisa),
				'one' => q(cruna islandaisa),
				'other' => q(cruna islandaisa),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira taliana),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(dollar giamaican),
				'one' => q(dollar giamaican),
				'other' => q(dollar giamaican),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordanic),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen giapunais),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(schilling kenian),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghis),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambodschan),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franc comorian),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won da la Corea dal Nord),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan da la Corea dal Sid),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(vegl won da la Corea dal Sid),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won da la Corea dal Sid),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar dal Kuwait),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dollar da las Inslas Cayman),
				'one' => q(dollar da las Inslas Cayman),
				'other' => q(dollar da las Inslas Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge casac),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laot),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(glivra libanaisa),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia da la Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollar liberian),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti dal Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituan),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituan),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertibel luxemburgais),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxemburgais),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc finanzial luxemburgais),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats letton),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rubel letton),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libic),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocan),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franc marocan),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(franc monegas),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(cupon moldav),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldav),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary madagasc),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franc madagasc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinar da la Macedonia),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(vegl dinar macedon),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franc dal Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat dal Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongolic),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca dal Macao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya da la Mauretania),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltaisa),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(glivra maltaisa),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia dal Mauritius),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(rupia da las Maledivas),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa da las Maledivas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha dal Malawi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(peso mexican),
				'one' => q(peso mexican),
				'other' => q(peso mexican),
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
				'currency' => q(ringgit da la Malaisia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo dal mozambican),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(vegl metical mozambican),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical dal mozambican),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dollar namibian),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba nicaraguan),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(cordoba oro nicaraguan),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(flurin ollandais),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(cruna norvegiaisa),
				'one' => q(cruna norvegiaisa),
				'other' => q(cruna norvegiaisa),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalaisa),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dollar da la Nova Zelanda),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial da l’Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa dal Panama),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruan),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(nov sol peruan),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruan),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina da la Papua Nova Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(peso filippin),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistana),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(zloty polac),
				'one' => q(zloty polac),
				'other' => q(zloty polac),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty polac \(1950–1995\)),
				'one' => q(zloty polac \(1950–1995\)),
				'other' => q(zloty polac \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo portugais),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani paraguaian),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(riyal da Katar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dollar rodesian),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(vegl leu rumen),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu rumen),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serb),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(rubel russ \(nov\)),
				'one' => q(rubel russ \(nov\)),
				'other' => q(rubel russ \(nov\)),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(rubel russ \(vegl\)),
				'one' => q(rubel russ \(vegl\)),
				'other' => q(rubel russ \(vegl\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franc ruandais),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(riyal saudit),
				'one' => q(riyal saudit),
				'other' => q(riyal saudit),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollar da las Salomonas),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia da las Seychellas),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanais),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(glivra sudanaisa),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(glivra sudanaisa \(1956–2007\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(cruna svedaisa),
				'one' => q(cruna svedaisa),
				'other' => q(cruna svedaisa),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dollar dal Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(glivra da Sontg’Elena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar sloven),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(cruna slovaca),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone da la Sierra Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(schilling somalian),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dollar surinam),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(flurin surinam),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra da São Tomé e Principe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rubel sovietic),
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
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni dal Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandais),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rubel dal Tadschikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni dal Tadschikistan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmen),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunesian),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(pa’anga da Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo da Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira tirca),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(nova lira tirca),
				'one' => q(nova lira tirca),
				'other' => q(nova lira tirca),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dollar da Trinidad e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(nov dollar taiwanais),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(schilling tansanian),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ucranais),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanetz ucranais),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(schilling ucranais),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(schilling ugandais),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(dollar dals Stadis Unids da l’America),
				'one' => q(dollar dals Stadis Unids da l’America),
				'other' => q(dollar dals Stadis Unids da l’America),
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
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum usbec),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar venezuelan \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar venezuelan),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamais),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vegl dong vietnamais),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu dal Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala da la Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA BEAC),
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
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unitad europeica cumponida),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unitad dal quint europeica \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unitad dal quint europeica \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(dollar da la Caribica Orientala),
				'one' => q(dollar da la Caribica Orientala),
				'other' => q(dollar da la Caribica Orientala),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(dretgs da prelevaziun spezials),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(unitad monetara europeica),
				'one' => q(unitad monetara europeica),
				'other' => q(unitads monetaras europeicas),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc d’aur franzos),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC franzos),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladi),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franc CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fonds RINET),
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
				'one' => q(valuta nunenconuschenta),
				'other' => q(valuta nunenconuschenta),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar dal Jemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial dal Jemen),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar jugoslav \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(nov dinar jugoslav),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar jugoslav convertibel),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar jugoslav refurmà),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sidafrican \(finanzial\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sidafrican),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha da la sambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha da la sambia),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nov zaire dal Zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire dal Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dollar dal Simbabwe),
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
					wide => {0 => '1. quartal',
						1 => '2. quartal',
						2 => '3. quartal',
						3 => '4. quartal'
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
				'wide' => {
					'am' => q{am},
					'pm' => q{sm},
				},
				'abbreviated' => {
					'am' => q{am},
					'pm' => q{sm},
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
			'full' => q{EEEE, 'ils' d 'da' MMMM y G},
			'long' => q{d 'da' MMMM y G},
			'medium' => q{dd-MM-y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, 'ils' d 'da' MMMM y},
			'long' => q{d 'da' MMMM y},
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
			HHmm => q{HH:mm},
			HHmmss => q{HH:mm:ss},
			Hm => q{H:mm},
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
		'gregorian' => {
			Ed => q{E d.},
			H => q{H},
			HHmm => q{HH:mm},
			HHmmss => q{HH:mm:ss},
			Hm => q{H:mm},
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
		'generic' => {
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
			fallback => '{0} - {1}',
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
		'gregorian' => {
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
			fallback => '{0} - {1}',
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
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dschibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ayun#,
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
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Cayman' => {
			exemplarCity => q#Inslas Cayman#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#San José#,
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
		'America/Merida' => {
			exemplarCity => q#Mérida#,
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
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
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
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
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
		'Asia/Choibalsan' => {
			exemplarCity => q#Tschoibalsan#,
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
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
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
			exemplarCity => q#Ho Chi Minh#,
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
		'Etc/Unknown' => {
			exemplarCity => q#zona betg enconuschenta#,
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
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhaghen#,
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
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Citad dal Vatican#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Turitg#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Diego Garcia#,
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
		'Indian/Kerguelen' => {
			exemplarCity => q#Port-aux-Français#,
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
