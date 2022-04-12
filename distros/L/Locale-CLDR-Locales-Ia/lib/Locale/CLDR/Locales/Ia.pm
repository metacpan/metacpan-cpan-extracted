=encoding utf8

=head1

Locale::CLDR::Locales::Ia - Package for language Interlingua

=cut

package Locale::CLDR::Locales::Ia;
# This file auto generated from Data/common/main/ia.xml
#	on Mon 11 Apr  5:30:20 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
 				'ab' => 'abkhazo',
 				'ace' => 'acehnese',
 				'ada' => 'adangme',
 				'ady' => 'adygeano',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'ale' => 'aleuto',
 				'alt' => 'altai del sud',
 				'am' => 'amharico',
 				'an' => 'aragonese',
 				'anp' => 'angika',
 				'ar' => 'arabe',
 				'ar_001' => 'arabe standard moderne',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'as' => 'assamese',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'av' => 'avaro',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaidzhano',
 				'az@alt=short' => 'azeri',
 				'ba' => 'bashkir',
 				'ban' => 'balinese',
 				'bas' => 'basaa',
 				'be' => 'bielorusso',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgaro',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengalese',
 				'bo' => 'tibetano',
 				'br' => 'breton',
 				'brx' => 'bodo',
 				'bs' => 'bosniaco',
 				'bug' => 'buginese',
 				'byn' => 'blin',
 				'ca' => 'catalano',
 				'ce' => 'checheno',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdo central',
 				'co' => 'corso',
 				'crs' => 'creolo seychellese',
 				'cs' => 'checo',
 				'cu' => 'slavo ecclesiastic',
 				'cv' => 'chuvash',
 				'cy' => 'gallese',
 				'da' => 'danese',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'germano',
 				'de_AT' => 'germano austriac',
 				'de_CH' => 'alte germano suisse',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'dsb' => 'basse sorabo',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'greco',
 				'en' => 'anglese',
 				'en_AU' => 'anglese australian',
 				'en_CA' => 'anglese canadian',
 				'en_GB' => 'anglese britannic',
 				'en_GB@alt=short' => 'anglese (GB)',
 				'en_US' => 'anglese american',
 				'en_US@alt=short' => 'anglese (SUA)',
 				'eo' => 'esperanto',
 				'es' => 'espaniol',
 				'es_419' => 'espaniol latinoamerican',
 				'es_ES' => 'espaniol europee',
 				'es_MX' => 'espaniol mexican',
 				'et' => 'estoniano',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'ff' => 'fula',
 				'fi' => 'finnese',
 				'fil' => 'filipino',
 				'fj' => 'fijiano',
 				'fo' => 'feroese',
 				'fon' => 'fon',
 				'fr' => 'francese',
 				'fr_CA' => 'francese canadian',
 				'fr_CH' => 'francese suisse',
 				'fur' => 'friulano',
 				'fy' => 'frison occidental',
 				'ga' => 'irlandese',
 				'gaa' => 'ga',
 				'gd' => 'gaelico scotese',
 				'gez' => 'ge’ez',
 				'gil' => 'gilbertese',
 				'gl' => 'galleco',
 				'gn' => 'guarani',
 				'gor' => 'gorontalo',
 				'gsw' => 'germano suisse',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'mannese',
 				'gwi' => 'gwich’in',
 				'ha' => 'hausa',
 				'haw' => 'hawaiano',
 				'he' => 'hebreo',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hmn' => 'hmong',
 				'hr' => 'croato',
 				'hsb' => 'alte sorabo',
 				'ht' => 'creolo haitian',
 				'hu' => 'hungaro',
 				'hup' => 'hupa',
 				'hy' => 'armeniano',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesiano',
 				'ie' => 'Interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi de Sichuan',
 				'ilo' => 'ilocano',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandese',
 				'it' => 'italiano',
 				'iu' => 'inuktitut',
 				'ja' => 'japonese',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javanese',
 				'ka' => 'georgiano',
 				'kab' => 'kabylo',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'cabardiano',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'capoverdiano',
 				'kfo' => 'koro',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakh',
 				'kkj' => 'kako',
 				'kl' => 'groenlandese',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'coreano',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkaro',
 				'krl' => 'careliano',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'coloniese',
 				'ku' => 'kurdo',
 				'kum' => 'kumyko',
 				'kv' => 'komi',
 				'kw' => 'cornico',
 				'ky' => 'kirghizo',
 				'la' => 'latino',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lb' => 'luxemburgese',
 				'lez' => 'lezghiano',
 				'lg' => 'luganda',
 				'li' => 'limburgese',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laotiano',
 				'loz' => 'lozi',
 				'lrc' => 'luri del nord',
 				'lt' => 'lithuano',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letton',
 				'mad' => 'madurese',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'macassarese',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meri',
 				'mfe' => 'creolo mauritian',
 				'mg' => 'malgache',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'metaʼ',
 				'mh' => 'marshallese',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedone',
 				'ml' => 'malayalam',
 				'mn' => 'mongol',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malay',
 				'mt' => 'maltese',
 				'mua' => 'mundang',
 				'mul' => 'plure linguas',
 				'mus' => 'creek',
 				'mwl' => 'mirandese',
 				'my' => 'birmano',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nap' => 'napolitano',
 				'naq' => 'nama',
 				'nb' => 'norvegiano bokmål',
 				'nd' => 'ndebele del nord',
 				'ne' => 'nepalese',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'nieuano',
 				'nl' => 'nederlandese',
 				'nl_BE' => 'flamingo',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegiano nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegiano',
 				'nog' => 'nogai',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele del sud',
 				'nso' => 'sotho del nord',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'occitano',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osseto',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauano',
 				'pcm' => 'pidgin nigerian',
 				'pl' => 'polonese',
 				'prg' => 'prussiano',
 				'ps' => 'pashto',
 				'pt' => 'portugese',
 				'pt_BR' => 'portugese de Brasil',
 				'pt_PT' => 'portugese de Portugal',
 				'qu' => 'quechua',
 				'quc' => 'kʼicheʼ',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongano',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romaniano',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
 				'root' => 'radice',
 				'ru' => 'russo',
 				'rup' => 'aromaniano',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrito',
 				'sad' => 'sandawe',
 				'sah' => 'yakuto',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siciliano',
 				'sco' => 'scotese',
 				'sd' => 'sindhi',
 				'se' => 'sami del nord',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sh' => 'serbocroate',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'si' => 'cingalese',
 				'sk' => 'slovaco',
 				'sl' => 'sloveno',
 				'sm' => 'samoano',
 				'sma' => 'sami del sud',
 				'smj' => 'sami de Lule',
 				'smn' => 'sami de Inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sq' => 'albanese',
 				'sr' => 'serbo',
 				'srn' => 'sranan tongo',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sotho del sud',
 				'su' => 'sundanese',
 				'suk' => 'sukuma',
 				'sv' => 'svedese',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili del Congo',
 				'swb' => 'comoriano',
 				'syr' => 'syriaco',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tajiko',
 				'th' => 'thai',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tk' => 'turkmeno',
 				'tlh' => 'klingon',
 				'tn' => 'tswana',
 				'to' => 'tongano',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tataro',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluano',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiano',
 				'tyv' => 'tuvano',
 				'tzm' => 'tamazight del Atlas Central',
 				'udm' => 'udmurto',
 				'ug' => 'uighur',
 				'uk' => 'ukrainiano',
 				'umb' => 'umbundu',
 				'und' => 'lingua incognite',
 				'ur' => 'urdu',
 				'uz' => 'uzbeko',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamese',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'wallon',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'wo' => 'wolof',
 				'xal' => 'calmuco',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yue' => 'cantonese',
 				'zgh' => 'tamazight marocchin standard',
 				'zh' => 'chinese',
 				'zh_Hans' => 'chinese simplificate',
 				'zh_Hant' => 'chinese traditional',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'sin contento linguistic',
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
			'Arab' => 'arabe',
 			'Armn' => 'armenian',
 			'Beng' => 'bengalese',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cyrl' => 'cyrillic',
 			'Deva' => 'devanagari',
 			'Ethi' => 'ethiope',
 			'Geor' => 'georgian',
 			'Grek' => 'grec',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han con bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'simplificate',
 			'Hans@alt=stand-alone' => 'han simplificate',
 			'Hant' => 'traditional',
 			'Hant@alt=stand-alone' => 'han traditional',
 			'Hebr' => 'hebraic',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'syllabarios japonese',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japonese',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'corean',
 			'Laoo' => 'lao',
 			'Latn' => 'latin',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongol',
 			'Mymr' => 'birman',
 			'Orya' => 'orya',
 			'Sinh' => 'cingalese',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandese',
 			'Tibt' => 'tibetano',
 			'Zmth' => 'notation mathematic',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symbolos',
 			'Zxxx' => 'non scripte',
 			'Zyyy' => 'commun',
 			'Zzzz' => 'scriptura incognite',

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
			'001' => 'Mundo',
 			'002' => 'Africa',
 			'003' => 'America del Nord',
 			'005' => 'America del Sud',
 			'009' => 'Oceania',
 			'011' => 'Africa occidental',
 			'013' => 'America central',
 			'014' => 'Africa oriental',
 			'015' => 'Africa septentrional',
 			'017' => 'Africa central',
 			'018' => 'Africa meridional',
 			'019' => 'Americas',
 			'021' => 'America septentrional',
 			'029' => 'Caribes',
 			'030' => 'Asia oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Asia del sud-est',
 			'039' => 'Europa meridional',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Region micronesian',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Asia central',
 			'145' => 'Asia occidental',
 			'150' => 'Europa',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'202' => 'Africa subsaharian',
 			'419' => 'America latin',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Arabe Unite',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa american',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AX' => 'Insulas Åland',
 			'AZ' => 'Azerbaidzhan',
 			'BA' => 'Bosnia e Herzegovina',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BM' => 'Bermuda',
 			'BO' => 'Bolivia',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Insula de Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CF' => 'Republica African Central',
 			'CG' => 'Congo',
 			'CH' => 'Suissa',
 			'CK' => 'Insulas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CX' => 'Insula de Natal',
 			'CY' => 'Cypro',
 			'CZ' => 'Chechia',
 			'CZ@alt=variant' => 'Republica Chec',
 			'DE' => 'Germania',
 			'DK' => 'Danmark',
 			'DO' => 'Republica Dominican',
 			'DZ' => 'Algeria',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypto',
 			'EH' => 'Sahara occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'Espania',
 			'ET' => 'Ethiopia',
 			'EU' => 'Union Europee',
 			'EZ' => 'Zona euro',
 			'FI' => 'Finlandia',
 			'FM' => 'Micronesia',
 			'FO' => 'Insulas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabon',
 			'GB' => 'Regno Unite',
 			'GB@alt=short' => 'GB',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana francese',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GQ' => 'Guinea equatorial',
 			'GR' => 'Grecia',
 			'GT' => 'Guatemala',
 			'GW' => 'Guinea-Bissau',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Insula de Man',
 			'IN' => 'India',
 			'IO' => 'Territorio oceanic britanno-indian',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JO' => 'Jordania',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
 			'KH' => 'Cambodgia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Sancte Christophoro e Nevis',
 			'KP' => 'Corea del Nord',
 			'KR' => 'Corea del Sud',
 			'KY' => 'Insulas de Caiman',
 			'KZ' => 'Kazakhstan',
 			'LB' => 'Libano',
 			'LC' => 'Sancte Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettonia',
 			'LY' => 'Libya',
 			'MA' => 'Marocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MG' => 'Madagascar',
 			'MH' => 'Insulas Marshall',
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (ARYM)',
 			'ML' => 'Mali',
 			'MM' => 'Birmania/Myanmar',
 			'MN' => 'Mongolia',
 			'MP' => 'Insulas Marianna del Nord',
 			'MR' => 'Mauritania',
 			'MT' => 'Malta',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nove Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Insula Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederlandia',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NZ' => 'Nove Zelanda',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polynesia francese',
 			'PG' => 'Papua Nove Guinea',
 			'PH' => 'Philippinas',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'St. Pierre e Miquelon',
 			'PT' => 'Portugal',
 			'PY' => 'Paraguay',
 			'QO' => 'Oceania remote',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Insulas Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Svedia',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovachia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan del Sud',
 			'SV' => 'El Salvador',
 			'SY' => 'Syria',
 			'SZ' => 'Swazilandia',
 			'TC' => 'Insulas Turcos e Caicos',
 			'TD' => 'Tchad',
 			'TF' => 'Territorios meridional francese',
 			'TG' => 'Togo',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tadzhikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor del Est',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UN' => 'Nationes Unite',
 			'US' => 'Statos Unite',
 			'US@alt=short' => 'SUA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Citate del Vaticano',
 			'VC' => 'Sancte Vincente e le Grenadinas',
 			'VE' => 'Venezuela',
 			'VU' => 'Vanuatu',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'ZA' => 'Sudafrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Region incognite',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'calendario',
 			'cf' => 'formato de moneta',
 			'collation' => 'ordinamento',
 			'currency' => 'moneta',
 			'hc' => 'cyclo horari (12 o 24)',
 			'lb' => 'stilo de salto de linea',
 			'ms' => 'systema de mesura',
 			'numbers' => 'numeros',

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
 				'buddhist' => q{calendario buddhista},
 				'chinese' => q{calendario chinese},
 				'dangi' => q{calendario dangi},
 				'ethiopic' => q{calendario ethiope},
 				'gregorian' => q{calendario gregorian},
 				'hebrew' => q{calendario hebraic},
 				'islamic' => q{calendario islamic},
 				'iso8601' => q{calendario ISO-8601},
 				'japanese' => q{calendario japonese},
 				'persian' => q{calendario persa},
 				'roc' => q{calendario del Republica de China},
 			},
 			'cf' => {
 				'account' => q{formato de moneta pro contabilitate},
 				'standard' => q{formato de moneta standard},
 			},
 			'collation' => {
 				'ducet' => q{ordinamento Unicode predefinite},
 				'search' => q{recerca generic},
 				'standard' => q{ordinamento standard},
 			},
 			'hc' => {
 				'h11' => q{systema de 12 horas (0–11)},
 				'h12' => q{systema de 12 horas (1–12)},
 				'h23' => q{systema de 24 horas (0–23)},
 				'h24' => q{systema de 24 horas (1–24)},
 			},
 			'lb' => {
 				'loose' => q{stilo de salto de linea flexibile},
 				'normal' => q{stilo de salto de linea normal},
 				'strict' => q{stilo de salto de linea stricte},
 			},
 			'ms' => {
 				'metric' => q{systema metric},
 				'uksystem' => q{systema de mesura imperial},
 				'ussystem' => q{systema de mesura statounitese},
 			},
 			'numbers' => {
 				'arab' => q{cifras indo-arabe},
 				'arabext' => q{cifras indo-arabe extendite},
 				'armn' => q{cifras armenie},
 				'armnlow' => q{cifras armenie minuscule},
 				'beng' => q{cifras bengalese},
 				'deva' => q{cifras devanagari},
 				'ethi' => q{cifras ethiope},
 				'fullwide' => q{cifras a latitude integre},
 				'geor' => q{cifras georgian},
 				'grek' => q{cifras grec},
 				'greklow' => q{cifras grec minuscule},
 				'gujr' => q{cifras gujarati},
 				'guru' => q{cifras gurmukhi},
 				'hanidec' => q{cifras decimal chinese},
 				'hans' => q{cifras chinese simplificate},
 				'hansfin' => q{cifras financiari chinese simplificate},
 				'hant' => q{cifras chinese traditional},
 				'hantfin' => q{cifras financiari chinese traditional},
 				'hebr' => q{cifras hebraic},
 				'jpan' => q{cifras japonese},
 				'jpanfin' => q{cifras financiari japonese},
 				'khmr' => q{cifras khmer},
 				'knda' => q{cifras kannada},
 				'laoo' => q{cifras lao},
 				'latn' => q{cifras occidental},
 				'mlym' => q{cifras malayalam},
 				'mymr' => q{cifras birman},
 				'orya' => q{cifras oriya},
 				'roman' => q{cifras roman},
 				'romanlow' => q{cifras roman minuscule},
 				'taml' => q{cifras tamil traditional},
 				'tamldec' => q{cifras tamil},
 				'telu' => q{cifras telugu},
 				'thai' => q{cifras thailandese},
 				'tibt' => q{cifras tibetan},
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
 			'UK' => q{britannic},
 			'US' => q{statounitese},

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
 			'script' => 'Scriptura: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[á à ă â å ä ã ā æ ç é è ĕ ê ë ē í ì ĭ î ï ī ñ ó ò ŏ ô ö ø ō œ ú ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c {ch} d e f g h i j k l m n o p {ph} q r s t u v w x y z]},
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
	default		=> qq{‘},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'hh:mm',
				hms => 'hh:mm:ss',
				ms => 'mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'' => {
						'name' => q(direction cardinal),
					},
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acres),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-pedes),
						'one' => q({0} acre-pedes),
						'other' => q({0} acre-pedes),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} amperes),
						'other' => q({0} amperes),
					},
					'arc-minute' => {
						'name' => q(minutas de arco),
						'one' => q({0} minutas de arco),
						'other' => q({0} minutas de arco),
					},
					'arc-second' => {
						'name' => q(secundas de arco),
						'one' => q({0} secundas de arco),
						'other' => q({0} secundas de arco),
					},
					'astronomical-unit' => {
						'name' => q(unitates astronomic),
						'one' => q({0} unitates astronomic),
						'other' => q({0} unitates astronomic),
					},
					'atmosphere' => {
						'name' => q(atmospheras),
						'one' => q({0} atmospheras),
						'other' => q({0} atmospheras),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bits),
						'other' => q({0} bits),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} bytes),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(calorias),
						'one' => q({0} calorias),
						'other' => q({0} calorias),
					},
					'carat' => {
						'name' => q(carates),
						'one' => q({0} carates),
						'other' => q({0} carates),
					},
					'celsius' => {
						'name' => q(grados Celcius),
						'one' => q({0} grados Celcius),
						'other' => q({0} grados Celcius),
					},
					'centiliter' => {
						'name' => q(centilitros),
						'one' => q({0} centilitros),
						'other' => q({0} centilitros),
					},
					'centimeter' => {
						'name' => q(centimetros),
						'one' => q({0} centimetros),
						'other' => q({0} centimetros),
						'per' => q({0} per centimetro),
					},
					'century' => {
						'name' => q(seculos),
						'one' => q({0} seculos),
						'other' => q({0} seculos),
					},
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} west),
					},
					'cubic-centimeter' => {
						'name' => q(centimetros cubic),
						'one' => q({0} centimetros cubic),
						'other' => q({0} centimetros cubic),
						'per' => q({0} per centimetro cubic),
					},
					'cubic-foot' => {
						'name' => q(pedes cubic),
						'one' => q({0} pedes cubic),
						'other' => q({0} pedes cubic),
					},
					'cubic-inch' => {
						'name' => q(inches cubic),
						'one' => q({0} inches cubic),
						'other' => q({0} inches cubic),
					},
					'cubic-kilometer' => {
						'name' => q(kilometros cubic),
						'one' => q({0} kilometros cubic),
						'other' => q({0} kilometros cubic),
					},
					'cubic-meter' => {
						'name' => q(metros cubic),
						'one' => q({0} metros cubic),
						'other' => q({0} metros cubic),
						'per' => q({0} per metro cubic),
					},
					'cubic-mile' => {
						'name' => q(millias cubic),
						'one' => q({0} millias cubic),
						'other' => q({0} millias cubic),
					},
					'cubic-yard' => {
						'name' => q(yards cubic),
						'one' => q({0} yards cubic),
						'other' => q({0} yards cubic),
					},
					'cup' => {
						'name' => q(tassas),
						'one' => q({0} tassas),
						'other' => q({0} tassas),
					},
					'cup-metric' => {
						'name' => q(tassas metric),
						'one' => q({0} tassas metric),
						'other' => q({0} tassas metric),
					},
					'day' => {
						'name' => q(dies),
						'one' => q({0} dies),
						'other' => q({0} dies),
						'per' => q({0} per die),
					},
					'deciliter' => {
						'name' => q(decilitros),
						'one' => q({0} decilitros),
						'other' => q({0} decilitros),
					},
					'decimeter' => {
						'name' => q(decimetros),
						'one' => q({0} decimetros),
						'other' => q({0} decimetros),
					},
					'degree' => {
						'name' => q(grados),
						'one' => q({0} grados),
						'other' => q({0} grados),
					},
					'fahrenheit' => {
						'name' => q(grados Fahrenheit),
						'one' => q({0} grados Fahrenheit),
						'other' => q({0} grados Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(uncias liquide),
						'one' => q({0} uncias liquide),
						'other' => q({0} uncias liquide),
					},
					'foodcalorie' => {
						'name' => q(kilocalorias),
						'one' => q({0} kilocalorias),
						'other' => q({0} kilocalorias),
					},
					'foot' => {
						'name' => q(pedes),
						'one' => q({0} pedes),
						'other' => q({0} pedes),
						'per' => q({0} per pede),
					},
					'g-force' => {
						'name' => q(fortia g),
						'one' => q({0} fortia g),
						'other' => q({0} fortia g),
					},
					'gallon' => {
						'name' => q(gallones),
						'one' => q({0} gallones),
						'other' => q({0} gallones),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(gallones imp.),
						'one' => q({0} gallones imp.),
						'other' => q({0} gallones imp.),
						'per' => q({0} per gallon imp.),
					},
					'generic' => {
						'name' => q(grados),
						'one' => q({0} grados),
						'other' => q({0} grados),
					},
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabits),
						'other' => q({0} gigabits),
					},
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabytes),
						'other' => q({0} gigabytes),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatts),
						'other' => q({0} gigawatts),
					},
					'gram' => {
						'name' => q(grammas),
						'one' => q({0} grammas),
						'other' => q({0} grammas),
						'per' => q({0} per gramma),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} hectares),
						'other' => q({0} hectares),
					},
					'hectoliter' => {
						'name' => q(hectolitros),
						'one' => q({0} hectolitros),
						'other' => q({0} hectolitros),
					},
					'hectopascal' => {
						'name' => q(hectopascales),
						'one' => q({0} hectopascales),
						'other' => q({0} hectopascales),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(cavallos-vapor),
						'one' => q({0} cavallos-vapor),
						'other' => q({0} cavallos-vapor),
					},
					'hour' => {
						'name' => q(horas),
						'one' => q({0} horas),
						'other' => q({0} horas),
						'per' => q({0} per hora),
					},
					'inch' => {
						'name' => q(pollices),
						'one' => q({0} pollices),
						'other' => q({0} pollices),
						'per' => q({0} per pollice),
					},
					'inch-hg' => {
						'name' => q(pollices de mercurio),
						'one' => q({0} pollices de mercurio),
						'other' => q({0} pollices de mercurio),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joules),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(carates),
						'one' => q({0} carates),
						'other' => q({0} carates),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobits),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobytes),
						'other' => q({0} kilobytes),
					},
					'kilocalorie' => {
						'name' => q(kilocalorias),
						'one' => q({0} kilocalorias),
						'other' => q({0} kilocalorias),
					},
					'kilogram' => {
						'name' => q(kilogrammas),
						'one' => q({0} kilogrammas),
						'other' => q({0} kilogrammas),
						'per' => q({0} per kilogramma),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoules),
						'other' => q({0} kilojoules),
					},
					'kilometer' => {
						'name' => q(kilometros),
						'one' => q({0} kilometros),
						'other' => q({0} kilometros),
						'per' => q({0} per kilometro),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometros per hora),
						'one' => q({0} kilometros per hora),
						'other' => q({0} kilometros per hora),
					},
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatts),
						'other' => q({0} kilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatthoras),
						'one' => q({0} kilowatthoras),
						'other' => q({0} kilowatthoras),
					},
					'knot' => {
						'name' => q(nodos),
						'one' => q({0} nodos),
						'other' => q({0} nodos),
					},
					'light-year' => {
						'name' => q(annos lumine),
						'one' => q({0} annos lumine),
						'other' => q({0} annos lumine),
					},
					'liter' => {
						'name' => q(litros),
						'one' => q({0} litros),
						'other' => q({0} litros),
						'per' => q({0} per litro),
					},
					'liter-per-100kilometers' => {
						'name' => q(litros per 100 kilometros),
						'one' => q({0} litros per 100 kilometros),
						'other' => q({0} litros per 100 kilometros),
					},
					'liter-per-kilometer' => {
						'name' => q(litros per kilometro),
						'one' => q({0} litros per kilometro),
						'other' => q({0} litros per kilometro),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabits),
						'other' => q({0} megabits),
					},
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabytes),
						'other' => q({0} megabytes),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitros),
						'other' => q({0} megalitros),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatts),
						'other' => q({0} megawatts),
					},
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metros),
						'other' => q({0} metros),
						'per' => q({0} per metro),
					},
					'meter-per-second' => {
						'name' => q(metros per secunda),
						'one' => q({0} metros per secunda),
						'other' => q({0} metros per secunda),
					},
					'meter-per-second-squared' => {
						'name' => q(metros per secunda quadrate),
						'one' => q({0} metros per secunda quadrate),
						'other' => q({0} metros per secunda quadrate),
					},
					'metric-ton' => {
						'name' => q(tonnas),
						'one' => q({0} tonnas),
						'other' => q({0} tonnas),
					},
					'microgram' => {
						'name' => q(microgrammas),
						'one' => q({0} microgrammas),
						'other' => q({0} microgrammas),
					},
					'micrometer' => {
						'name' => q(micrometros),
						'one' => q({0} micrometros),
						'other' => q({0} micrometros),
					},
					'microsecond' => {
						'name' => q(microsecundas),
						'one' => q({0} microsecundas),
						'other' => q({0} microsecundas),
					},
					'mile' => {
						'name' => q(millias),
						'one' => q({0} millias),
						'other' => q({0} millias),
					},
					'mile-per-gallon' => {
						'name' => q(millias per gallon),
						'one' => q({0} millias per gallon),
						'other' => q({0} millias per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(millias per gallon imperial),
						'one' => q({0} millias per gallon imperial),
						'other' => q({0} millias per gallon imperial),
					},
					'mile-per-hour' => {
						'name' => q(millias per hora),
						'one' => q({0} millias per hora),
						'other' => q({0} millias per hora),
					},
					'mile-scandinavian' => {
						'name' => q(millias scandinave),
						'one' => q({0} millias scandinave),
						'other' => q({0} millias scandinave),
					},
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliamperes),
						'other' => q({0} milliamperes),
					},
					'millibar' => {
						'name' => q(millibares),
						'one' => q({0} millibares),
						'other' => q({0} millibares),
					},
					'milligram' => {
						'name' => q(milligrammas),
						'one' => q({0} milligrammas),
						'other' => q({0} milligrammas),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrammas per decilitro),
						'one' => q({0} milligrammas per decilitro),
						'other' => q({0} milligrammas per decilitro),
					},
					'milliliter' => {
						'name' => q(millilitros),
						'one' => q({0} millilitros),
						'other' => q({0} millilitros),
					},
					'millimeter' => {
						'name' => q(millimetros),
						'one' => q({0} millimetros),
						'other' => q({0} millimetros),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimetros de mercurio),
						'one' => q({0} milimetros de mercurio),
						'other' => q({0} milimetros de mercurio),
					},
					'millimole-per-liter' => {
						'name' => q(millimoles per litro),
						'one' => q({0} millimoles per litro),
						'other' => q({0} millimoles per litro),
					},
					'millisecond' => {
						'name' => q(millisecundas),
						'one' => q({0} millisecundas),
						'other' => q({0} millisecundas),
					},
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatts),
						'other' => q({0} milliwatts),
					},
					'minute' => {
						'name' => q(minutas),
						'one' => q({0} minutas),
						'other' => q({0} minutas),
						'per' => q({0} per minuta),
					},
					'month' => {
						'name' => q(menses),
						'one' => q({0} menses),
						'other' => q({0} menses),
						'per' => q({0} per mense),
					},
					'nanometer' => {
						'name' => q(nanometros),
						'one' => q({0} nanometros),
						'other' => q({0} nanometros),
					},
					'nanosecond' => {
						'name' => q(nanosecundas),
						'one' => q({0} nanosecundas),
						'other' => q({0} nanosecundas),
					},
					'nautical-mile' => {
						'name' => q(millias nautic),
						'one' => q({0} millias nautic),
						'other' => q({0} millias nautic),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohms),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(uncias),
						'one' => q({0} uncias),
						'other' => q({0} uncias),
						'per' => q({0} per uncia),
					},
					'ounce-troy' => {
						'name' => q(uncias troy),
						'one' => q({0} uncias troy),
						'other' => q({0} uncias troy),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsecs),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(partes per million),
						'one' => q({0} partes per million),
						'other' => q({0} partes per million),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'percent' => {
						'name' => q(per cento),
						'one' => q({0} per cento),
						'other' => q({0} per cento),
					},
					'permille' => {
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabytes),
						'other' => q({0} petabytes),
					},
					'picometer' => {
						'name' => q(picometros),
						'one' => q({0} picometros),
						'other' => q({0} picometros),
					},
					'pint' => {
						'name' => q(pintas),
						'one' => q({0} pintas),
						'other' => q({0} pintas),
					},
					'pint-metric' => {
						'name' => q(pintas metric),
						'one' => q({0} pintas metric),
						'other' => q({0} pintas metric),
					},
					'point' => {
						'name' => q(punctos),
						'one' => q({0} punctos),
						'other' => q({0} punctos),
					},
					'pound' => {
						'name' => q(libras),
						'one' => q({0} libras),
						'other' => q({0} libras),
						'per' => q({0} per libra),
					},
					'pound-per-square-inch' => {
						'name' => q(libras per pollice quadrate),
						'one' => q({0} libras per pollice quadrate),
						'other' => q({0} libras per pollice quadrate),
					},
					'quart' => {
						'name' => q(quartos),
						'one' => q({0} quartos),
						'other' => q({0} quartos),
					},
					'radian' => {
						'name' => q(radianos),
						'one' => q({0} radianos),
						'other' => q({0} radianos),
					},
					'revolution' => {
						'name' => q(revolutiones),
						'one' => q({0} revolutiones),
						'other' => q({0} revolutiones),
					},
					'second' => {
						'name' => q(secundas),
						'one' => q({0} secundas),
						'other' => q({0} secundas),
						'per' => q({0} per secunda),
					},
					'square-centimeter' => {
						'name' => q(centimetros quadrate),
						'one' => q({0} centimetros quadrate),
						'other' => q({0} centimetros quadrate),
						'per' => q({0} per centimetro quadrate),
					},
					'square-foot' => {
						'name' => q(pedes quadrate),
						'one' => q({0} pedes quadrate),
						'other' => q({0} pedes quadrate),
					},
					'square-inch' => {
						'name' => q(pollices quadrate),
						'one' => q({0} pollices quadrate),
						'other' => q({0} pollices quadrate),
						'per' => q({0} per pollice quadrate),
					},
					'square-kilometer' => {
						'name' => q(kilometros quadrate),
						'one' => q({0} kilometros quadrate),
						'other' => q({0} kilometros quadrate),
						'per' => q({0} per kilometro quadrate),
					},
					'square-meter' => {
						'name' => q(metros quadrate),
						'one' => q({0} metros quadrate),
						'other' => q({0} metros quadrate),
						'per' => q({0} per metro quadrate),
					},
					'square-mile' => {
						'name' => q(millias quadrate),
						'one' => q({0} millias quadrate),
						'other' => q({0} millias quadrate),
						'per' => q({0} per millia quadrate),
					},
					'square-yard' => {
						'name' => q(yards quadrate),
						'one' => q({0} yards quadrate),
						'other' => q({0} yards quadrate),
					},
					'tablespoon' => {
						'name' => q(coclearatas a suppa),
						'one' => q({0} coclearatas a suppa),
						'other' => q({0} coclearatas a suppa),
					},
					'teaspoon' => {
						'name' => q(coclearatas a the),
						'one' => q({0} coclearatas a the),
						'other' => q({0} coclearatas a the),
					},
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabits),
						'other' => q({0} terabits),
					},
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabytes),
						'other' => q({0} terabytes),
					},
					'ton' => {
						'name' => q(tonnas curte),
						'one' => q({0} tonnas curte),
						'other' => q({0} tonnas curte),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volts),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watts),
						'other' => q({0} watts),
					},
					'week' => {
						'name' => q(septimanas),
						'one' => q({0} septimanas),
						'other' => q({0} septimanas),
						'per' => q({0} per septimana),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yards),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(annos),
						'one' => q({0} annos),
						'other' => q({0} annos),
						'per' => q({0} per anno),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(dir.),
					},
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
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'day' => {
						'name' => q(die),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hour' => {
						'name' => q(hora),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
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
						'name' => q(L),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(millisec),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'month' => {
						'name' => q(mense),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'week' => {
						'name' => q(sept.),
						'one' => q({0}sept),
						'other' => q({0}sept),
					},
					'year' => {
						'name' => q(an),
						'one' => q({0}an),
						'other' => q({0}an),
					},
				},
				'short' => {
					'' => {
						'name' => q(direction),
					},
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac pd),
						'one' => q({0} ac pd),
						'other' => q({0} ac pd),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(scl),
						'one' => q({0} scl),
						'other' => q({0} scl),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(pd³),
						'one' => q({0} pd³),
						'other' => q({0} pd³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(tas),
						'one' => q({0} tas),
						'other' => q({0} tas),
					},
					'cup-metric' => {
						'name' => q(tasm),
						'one' => q({0} tasm),
						'other' => q({0} tasm),
					},
					'day' => {
						'name' => q(dies),
						'one' => q({0} dies),
						'other' => q({0} dies),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'name' => q(oz liq),
						'one' => q({0} oz liq),
						'other' => q({0} oz liq),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(fortia g),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal imp),
						'one' => q({0} gal imp),
						'other' => q({0} gal imp),
						'per' => q({0}/gal imp),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					'hour' => {
						'name' => q(horas),
						'one' => q({0} hr),
						'other' => q({0} hr),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					'liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(millisec),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(menses),
						'one' => q({0} menses),
						'other' => q({0} menses),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(lb/in²),
						'one' => q({0} lb/in²),
						'other' => q({0} lb/in²),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} sec),
						'other' => q({0} sec),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(cocl. a suppa),
						'one' => q({0} cocl. a suppa),
						'other' => q({0} cocl. a suppa),
					},
					'teaspoon' => {
						'name' => q(cocl. a the),
						'one' => q({0} cocl. a the),
						'other' => q({0} cocl. a the),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(septimanas),
						'one' => q({0} sept),
						'other' => q({0} sept),
						'per' => q({0}/sept),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(annos),
						'one' => q({0} an),
						'other' => q({0} an),
						'per' => q({0}/an),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:si|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
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
	default		=> 2,
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
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mld',
					'other' => '0 mld',
				},
				'10000000000' => {
					'one' => '00 mld',
					'other' => '00 mld',
				},
				'100000000000' => {
					'one' => '000 mld',
					'other' => '000 mld',
				},
				'1000000000000' => {
					'one' => '0 bln',
					'other' => '0 bln',
				},
				'10000000000000' => {
					'one' => '00 bln',
					'other' => '00 bln',
				},
				'100000000000000' => {
					'one' => '000 bln',
					'other' => '000 bln',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 milles',
					'other' => '0 milles',
				},
				'10000' => {
					'one' => '00 milles',
					'other' => '00 milles',
				},
				'100000' => {
					'one' => '000 milles',
					'other' => '000 milles',
				},
				'1000000' => {
					'one' => '0 milliones',
					'other' => '0 milliones',
				},
				'10000000' => {
					'one' => '00 milliones',
					'other' => '00 milliones',
				},
				'100000000' => {
					'one' => '000 milliones',
					'other' => '000 milliones',
				},
				'1000000000' => {
					'one' => '0 milliardos',
					'other' => '0 milliardos',
				},
				'10000000000' => {
					'one' => '00 milliardos',
					'other' => '00 milliardos',
				},
				'100000000000' => {
					'one' => '000 milliardos',
					'other' => '000 milliardos',
				},
				'1000000000000' => {
					'one' => '0 billiones',
					'other' => '0 billiones',
				},
				'10000000000000' => {
					'one' => '00 billiones',
					'other' => '00 billiones',
				},
				'100000000000000' => {
					'one' => '000 billiones',
					'other' => '000 billiones',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mld',
					'other' => '0 mld',
				},
				'10000000000' => {
					'one' => '00 mld',
					'other' => '00 mld',
				},
				'100000000000' => {
					'one' => '000 mld',
					'other' => '000 mld',
				},
				'1000000000000' => {
					'one' => '0 bln',
					'other' => '0 bln',
				},
				'10000000000000' => {
					'one' => '00 bln',
					'other' => '00 bln',
				},
				'100000000000000' => {
					'one' => '000 bln',
					'other' => '000 bln',
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
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
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
		'ALL' => {
			display_name => {
				'currency' => q(lek albanese),
				'one' => q(lekë albanese),
				'other' => q(lekë albanese),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florino antillan),
				'one' => q(florinos antillan),
				'other' => q(florinos antillan),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolan),
				'one' => q(kwanzas angolan),
				'other' => q(kwanzas angolan),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentin),
				'one' => q(pesos argentin),
				'other' => q(pesos argentin),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dollar australian),
				'one' => q(dollares australian),
				'other' => q(dollares australian),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florino aruban),
				'one' => q(florinos aruban),
				'other' => q(florinos aruban),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marco convertibile de Bosnia-Herzegovina),
				'one' => q(marcos convertibile de Bosnia-Herzegovina),
				'other' => q(marcos convertibile de Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollar barbadian),
				'one' => q(dollares barbadian),
				'other' => q(dollares barbadian),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bulgare),
				'one' => q(leva bulgare),
				'other' => q(leva bulgare),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franco burundese),
				'one' => q(francos burundese),
				'other' => q(francos burundese),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dollar bermudan),
				'one' => q(dollares bermudan),
				'other' => q(dollares bermudan),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano bolivian),
				'one' => q(bolivianos bolivian),
				'other' => q(bolivianos bolivian),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasilian),
				'one' => q(reales brasilian),
				'other' => q(reales brasilian),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dollar bahamian),
				'one' => q(dollares bahamian),
				'other' => q(dollares bahamian),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula botswanese),
				'one' => q(pula botswanese),
				'other' => q(pula botswanese),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rublo bielorusse),
				'one' => q(rublos bielorusse),
				'other' => q(rublos bielorusse),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dollar belizan),
				'one' => q(dollares belizan),
				'other' => q(dollares belizan),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dollar canadian),
				'one' => q(dollares canadian),
				'other' => q(dollares canadian),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franco congolese),
				'one' => q(francos congolese),
				'other' => q(francos congolese),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franco suisse),
				'one' => q(francos suisse),
				'other' => q(francos suisse),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso chilen),
				'one' => q(pesos chilen),
				'other' => q(pesos chilen),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan chinese),
				'one' => q(yuan chinese),
				'other' => q(yuan chinese),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombian),
				'one' => q(pesos colombian),
				'other' => q(pesos colombian),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colon costarican),
				'one' => q(colones costarican),
				'other' => q(colones costarican),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cuban convertibile),
				'one' => q(pesos cuban convertibile),
				'other' => q(pesos cuban convertibile),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cuban),
				'one' => q(pesos cuban),
				'other' => q(pesos cuban),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo capoverdian),
				'one' => q(escudos capoverdian),
				'other' => q(escudos capoverdian),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona chec),
				'one' => q(coronas chec),
				'other' => q(coronas chec),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marco geman),
				'one' => q(marcos german),
				'other' => q(marcos german),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franco djibutian),
				'one' => q(francos djibutian),
				'other' => q(francos djibutian),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona danese),
				'one' => q(coronas danese),
				'other' => q(coronas danese),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
				'one' => q(pesos dominican),
				'other' => q(pesos dominican),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerin),
				'one' => q(dinares algerin),
				'other' => q(dinares algerin),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Corona estonian),
				'one' => q(coronas estonian),
				'other' => q(coronas estonian),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(libra egyptie),
				'one' => q(libras egyptie),
				'other' => q(libras egyptie),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritree),
				'one' => q(nakfas eritree),
				'other' => q(nakfas eritree),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr ethiope),
				'one' => q(birres ethiope),
				'other' => q(birres ethiope),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euros),
				'other' => q(euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Marco finnese),
				'one' => q(marcos finnese),
				'other' => q(marcos finnese),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dollar fijian),
				'one' => q(dollares fijian),
				'other' => q(dollares fijian),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(libra falklandese),
				'one' => q(libras falklandese),
				'other' => q(libras falklandese),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franco francese),
				'one' => q(francos francese),
				'other' => q(francos francese),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(libra sterling),
				'one' => q(libras sterling),
				'other' => q(libras sterling),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanese),
				'one' => q(cedis ghanese),
				'other' => q(cedis ghanese),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(libra de Gibraltar),
				'one' => q(libras de Gibraltar),
				'other' => q(libras de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambian),
				'one' => q(dalasis gambian),
				'other' => q(dalasis gambian),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franco guinean),
				'one' => q(francos guinean),
				'other' => q(francos guinean),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemaltec),
				'one' => q(quetzales guatemaltec),
				'other' => q(quetzales guatemaltec),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollar guyanese),
				'one' => q(dollares guyanese),
				'other' => q(dollares guyanese),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira hondurese),
				'one' => q(lempiras hondurese),
				'other' => q(lempiras hondurese),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croate),
				'one' => q(kunas croate),
				'other' => q(kunas croate),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitian),
				'one' => q(gourdes haitian),
				'other' => q(gourdes haitian),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint hungare),
				'one' => q(forintes hungare),
				'other' => q(forintes hungare),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Libra irlandese),
				'one' => q(libras irlandese),
				'other' => q(libras irlandese),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia indian),
				'one' => q(rupias indian),
				'other' => q(rupias indian),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona islandese),
				'one' => q(coronas islandese),
				'other' => q(coronas islandese),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dollar jamaican),
				'one' => q(dollares jamaican),
				'other' => q(dollares jamaican),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen japonese),
				'one' => q(yen japonese),
				'other' => q(yen japonese),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shilling kenyan),
				'one' => q(shillings kenyan),
				'other' => q(shillings kenyan),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franco comorian),
				'one' => q(francos comorian),
				'other' => q(francos comorian),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dollar del Insulas Caiman),
				'one' => q(dollares del Insulas Caiman),
				'other' => q(dollares del Insulas Caiman),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollar liberian),
				'one' => q(dollares liberian),
				'other' => q(dollares liberian),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libyc),
				'one' => q(dinares libyc),
				'other' => q(dinares libyc),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocchin),
				'one' => q(dirhams marocchin),
				'other' => q(dirhams marocchin),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldave),
				'one' => q(lei moldave),
				'other' => q(lei moldave),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgache),
				'one' => q(ariary malgache),
				'other' => q(ariary malgache),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(denar macedonie),
				'one' => q(denari macedonie),
				'other' => q(denari macedonie),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya mauritan \(1973–2017\)),
				'one' => q(ouguiyas mauritan \(1973–2017\)),
				'other' => q(ouguiyas mauritan \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritan),
				'one' => q(ouguiyas mauritan),
				'other' => q(ouguiyas mauritan),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauritian),
				'one' => q(rupias mauritian),
				'other' => q(rupias mauritian),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawian),
				'one' => q(kwacha malawian),
				'other' => q(kwacha malawian),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso mexican),
				'one' => q(pesos mexican),
				'other' => q(pesos mexican),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambican),
				'one' => q(meticales mozambican),
				'other' => q(meticales mozambican),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dollar namibian),
				'one' => q(dollares namibian),
				'other' => q(dollares namibian),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigerian),
				'one' => q(nairas nigerian),
				'other' => q(nairas nigerian),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(cordoba nicaraguan),
				'one' => q(cordobas nicaraguan),
				'other' => q(cordobas nicaraguan),
			},
		},
		'NLG' => {
			symbol => 'ƒ',
			display_name => {
				'currency' => q(Florino nederlandese),
				'one' => q(florinos nederlandese),
				'other' => q(florinos nederlandese),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corona norvegian),
				'one' => q(coronas norvegian),
				'other' => q(coronas norvegian),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dollar neozelandese),
				'one' => q(dollares neozelandese),
				'other' => q(dollares neozelandese),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panamen),
				'one' => q(balboas panamen),
				'other' => q(balboas panamen),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruvian),
				'one' => q(soles peruvian),
				'other' => q(soles peruvian),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papuan),
				'one' => q(kinas papuan),
				'other' => q(kinas papuan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polonese),
				'one' => q(zlotys polonese),
				'other' => q(zlotys polonese),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani paraguayan),
				'one' => q(guaranis paraguayan),
				'other' => q(guaranis paraguayan),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu romanian),
				'one' => q(lei romanian),
				'other' => q(lei romanian),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbe),
				'one' => q(dinares serbe),
				'other' => q(dinares serbe),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(rublo russe),
				'one' => q(rublos russe),
				'other' => q(rublos russe),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franco ruandese),
				'one' => q(francos ruandese),
				'other' => q(francos ruandese),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollar del insulas Salomon),
				'one' => q(dollares del insulas Salomon),
				'other' => q(dollares del insulas Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia seychellese),
				'one' => q(rupias seychellese),
				'other' => q(rupias seychellese),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(libra sudanese),
				'one' => q(libras sudanese),
				'other' => q(libras sudanese),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona svedese),
				'one' => q(coronas svedese),
				'other' => q(coronas svedese),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(libra de St. Helena),
				'one' => q(libras de St. Helena),
				'other' => q(libras de St. Helena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone sierraleonese),
				'one' => q(leones sierraleonese),
				'other' => q(leones sierraleonese),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilling somali),
				'one' => q(shillings somali),
				'other' => q(shillings somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dollar surinamese),
				'one' => q(dollares surinamese),
				'other' => q(dollares surinamese),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(libra sud-sudanese),
				'one' => q(libras sud-sudanese),
				'other' => q(libras sud-sudanese),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de São Tomé e Príncipe),
				'one' => q(dobras de São Tomé e Príncipe),
				'other' => q(dobras de São Tomé e Príncipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni swazilandese),
				'one' => q(emalangeni swazilandese),
				'other' => q(emalangeni swazilandese),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisian),
				'one' => q(dinares tunisian),
				'other' => q(dinares tunisian),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga tongan),
				'one' => q(paʻangas tongan),
				'other' => q(paʻangas tongan),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dollar de Trinidad e Tobago),
				'one' => q(dollares de Trinidad e Tobago),
				'other' => q(dollares de Trinidad e Tobago),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(shilling tanzanian),
				'one' => q(shillings tanzanian),
				'other' => q(shillings tanzanian),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ukrainian),
				'one' => q(hryvni ukrainian),
				'other' => q(hryvni ukrainian),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shilling ugandese),
				'one' => q(shillings ugandese),
				'other' => q(shillings ugandese),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dollar statounitese),
				'one' => q(dollares statounitese),
				'other' => q(dollares statounitese),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguayan),
				'one' => q(pesos uruguayan),
				'other' => q(pesos uruguayan),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar venezuelan \(2008–2018\)),
				'one' => q(bolivares venezuelan \(2008–2018\)),
				'other' => q(bolivares venezuelan \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolivar venezuelan),
				'one' => q(bolivares venezuelan),
				'other' => q(bolivares venezuelan),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu vanuatuan),
				'one' => q(vatus vanuatuan),
				'other' => q(vatus vanuatuan),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoan),
				'one' => q(talas samoan),
				'other' => q(talas samoan),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA de Africa Central),
				'one' => q(francos CFA de Africa Central),
				'other' => q(francos CFA de Africa Central),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dollar del Caribes Oriental),
				'one' => q(dollares del Caribes Oriental),
				'other' => q(dollares del Caribes Oriental),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA de Africa Occidental),
				'one' => q(francos CFA de Africa Occidental),
				'other' => q(francos CFA de Africa Occidental),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(francos CFP),
				'other' => q(francos CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneta incognite),
				'one' => q(\(moneta incognite\)),
				'other' => q(\(moneta incognite\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafrican),
				'one' => q(rand sudafrican),
				'other' => q(rand sudafrican),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambian),
				'one' => q(kwacha zambian),
				'other' => q(kwacha zambian),
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
							'jan',
							'feb',
							'mar',
							'apr',
							'mai',
							'jun',
							'jul',
							'aug',
							'sep',
							'oct',
							'nov',
							'dec'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'j',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januario',
							'februario',
							'martio',
							'april',
							'maio',
							'junio',
							'julio',
							'augusto',
							'septembre',
							'octobre',
							'novembre',
							'decembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'feb',
							'mar',
							'apr',
							'mai',
							'jun',
							'jul',
							'aug',
							'sep',
							'oct',
							'nov',
							'dec'
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
							'januario',
							'februario',
							'martio',
							'april',
							'maio',
							'junio',
							'julio',
							'augusto',
							'septembre',
							'octobre',
							'novembre',
							'decembre'
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
						mon => 'lun',
						tue => 'mar',
						wed => 'mer',
						thu => 'jov',
						fri => 'ven',
						sat => 'sab',
						sun => 'dom'
					},
					narrow => {
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'j',
						fri => 'v',
						sat => 's',
						sun => 'd'
					},
					short => {
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'jo',
						fri => 've',
						sat => 'sa',
						sun => 'do'
					},
					wide => {
						mon => 'lunedi',
						tue => 'martedi',
						wed => 'mercuridi',
						thu => 'jovedi',
						fri => 'venerdi',
						sat => 'sabbato',
						sun => 'dominica'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'lun',
						tue => 'mar',
						wed => 'mer',
						thu => 'jov',
						fri => 'ven',
						sat => 'sab',
						sun => 'dom'
					},
					narrow => {
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'j',
						fri => 'v',
						sat => 's',
						sun => 'd'
					},
					short => {
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'jo',
						fri => 've',
						sat => 'sa',
						sun => 'do'
					},
					wide => {
						mon => 'lunedi',
						tue => 'martedi',
						wed => 'mercuridi',
						thu => 'jovedi',
						fri => 'venerdi',
						sat => 'sabbato',
						sun => 'dominica'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1me trimestre',
						1 => '2nde trimestre',
						2 => '3tie trimestre',
						3 => '4te trimestre'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1me trimestre',
						1 => '2nde trimestre',
						2 => '3tie trimestre',
						3 => '4te trimestre'
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
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.Chr.',
				'1' => 'p.Chr.'
			},
			wide => {
				'0' => 'ante Christo',
				'1' => 'post Christo'
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
			'full' => q{EEEE 'le' d 'de' MMMM y G},
			'long' => q{d 'de' MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE 'le' d 'de' MMMM y},
			'long' => q{d 'de' MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-y},
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
			'full' => q{{1} 'a' {0}},
			'long' => q{{1} 'a' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'a' {0}},
			'long' => q{{1} 'a' {0}},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E dd-MM},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM-y GGGGG},
			yyyyMEd => q{E dd-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E dd-MM},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMW => q{'septimana' W 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{'septimana' w 'de' Y},
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
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y GGGGG},
				d => q{E dd-MM-y – E dd-MM-y GGGGG},
				y => q{E dd-MM-y – E dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
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
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y},
				d => q{E dd-MM-y – E dd-MM-y},
				y => q{E dd-MM-y – E dd-MM-y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
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
		regionFormat => q(hora de {0}),
		regionFormat => q(hora estive de {0}),
		regionFormat => q(hora normal de {0}),
		fallbackFormat => q({1} ({0})),
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Alaska' => {
			long => {
				'daylight' => q#hora estive de Alaska#,
				'generic' => q#hora de Alaska#,
				'standard' => q#hora normal de Alaska#,
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
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
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
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
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
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
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
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
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
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
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
			exemplarCity => q#Citate de Mexico#,
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
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#Nove York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota del Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota del Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota del Nord#,
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
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rico#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sancte Bartholomeo#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sancte Johannes de Terranova#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sancte Christophoro#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sancte Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sancte Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sancte Vincente#,
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
				'daylight' => q#hora estive central#,
				'generic' => q#hora central#,
				'standard' => q#hora normal central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#hora estive del est#,
				'generic' => q#hora del est#,
				'standard' => q#hora normal del est#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora estive del montanias#,
				'generic' => q#hora del montanias#,
				'standard' => q#hora normal del montanias#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#hora estive pacific#,
				'generic' => q#hora pacific#,
				'standard' => q#hora normal pacific#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
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
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#hora estive atlantic#,
				'generic' => q#hora atlantic#,
				'standard' => q#hora normal atlantic#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Capo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Azores' => {
			long => {
				'daylight' => q#hora estive del Azores#,
				'generic' => q#hora del Azores#,
				'standard' => q#hora normal del Azores#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#hora estive de Cuba#,
				'generic' => q#hora de Cuba#,
				'standard' => q#hora normal de Cuba#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Universal Tempore Coordinate#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Citate incognite#,
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
			exemplarCity => q#Athenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
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
				'daylight' => q#Hora estive irlandese#,
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
			exemplarCity => q#Insula de Man#,
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
			exemplarCity => q#Lisbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Hora estive britannic#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
			exemplarCity => q#Moscova#,
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
			exemplarCity => q#Praga#,
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
			exemplarCity => q#Tirana#,
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
			exemplarCity => q#Vaticano#,
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
			exemplarCity => q#Varsovia#,
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
				'daylight' => q#hora estive de Europa central#,
				'generic' => q#hora de Europa central#,
				'standard' => q#hora normal de Europa central#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora estive de Europa oriental#,
				'generic' => q#hora de Europa oriental#,
				'standard' => q#hora normal de Europa oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#hora de Europa ultra-oriental#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora estive de Europa occidental#,
				'generic' => q#hora de Europa occidental#,
				'standard' => q#hora normal de Europa occidental#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#hora medie de Greenwich#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#hora estive de Groenlandia oriental#,
				'generic' => q#hora de Groenlandia oriental#,
				'standard' => q#hora normal de Groenlandia oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#hora estive de Groenlandia occidental#,
				'generic' => q#hora de Groenlandia occidental#,
				'standard' => q#hora normal de Groenlandia occidental#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#hora estive de Hawaii-Aleutianas#,
				'generic' => q#hora de Hawaii-Aleutianas#,
				'standard' => q#hora normal de Hawaii-Aleutianas#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotta#,
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#hora estive de Irkutsk#,
				'generic' => q#hora de Irkutsk#,
				'standard' => q#hora normal de Irkutsk#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#hora estive de Krasnoyarsk#,
				'generic' => q#hora de Krasnoyarsk#,
				'standard' => q#hora normal de Krasnoyarsk#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#hora estive de Magadan#,
				'generic' => q#hora de Magadan#,
				'standard' => q#hora normal de Magadan#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#hora estive del nordwest de Mexico#,
				'generic' => q#hora del nordwest de Mexico#,
				'standard' => q#hora normal del nordwest de Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#hora estive del Pacifico mexican#,
				'generic' => q#hora del Pacifico mexican#,
				'standard' => q#hora normal del Pacifico mexican#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#hora estive de Moscova#,
				'generic' => q#hora de Moscova#,
				'standard' => q#hora normal de Moscova#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#hora estive de Terranova#,
				'generic' => q#hora de Terranova#,
				'standard' => q#hora normal de Terranova#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#hora estive de Novosibirsk#,
				'generic' => q#hora de Novosibirsk#,
				'standard' => q#hora normal de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#hora estive de Omsk#,
				'generic' => q#hora de Omsk#,
				'standard' => q#hora normal de Omsk#,
			},
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Insula Pitcairn#,
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#hora estive de Saint-Pierre e Miquelon#,
				'generic' => q#hora de Saint-Pierre e Miquelon#,
				'standard' => q#hora normal de Saint-Pierre e Miquelon#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#hora estive de Sachalin#,
				'generic' => q#hora de Sachalin#,
				'standard' => q#hora normal de Sachalin#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#hora estive de Vladivostok#,
				'generic' => q#hora de Vladivostok#,
				'standard' => q#hora normal de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#hora estive de Volgograd#,
				'generic' => q#hora de Volgograd#,
				'standard' => q#hora normal de Volgograd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#hora estive de Yakutsk#,
				'generic' => q#hora de Yakutsk#,
				'standard' => q#hora normal de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#hora estive de Ekaterinburg#,
				'generic' => q#hora de Ekaterinburg#,
				'standard' => q#hora normal de Ekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
