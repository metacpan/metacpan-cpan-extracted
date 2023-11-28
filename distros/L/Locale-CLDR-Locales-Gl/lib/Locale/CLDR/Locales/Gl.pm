=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gl - Package for language Galician

=cut

package Locale::CLDR::Locales::Gl;
# This file auto generated from Data\common\main\gl.xml
#	on Sat  4 Nov  6:04:27 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

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
 				'ace' => 'achinés',
 				'ach' => 'acholí',
 				'ada' => 'adangme',
 				'ady' => 'adigueo',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'ale' => 'aleutiano',
 				'alt' => 'altai meridional',
 				'am' => 'amhárico',
 				'an' => 'aragonés',
 				'anp' => 'angika',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe estándar moderno',
 				'arc' => 'arameo',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'as' => 'assamés',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'av' => 'avar',
 				'awa' => 'awadhi',
 				'ay' => 'aimará',
 				'az' => 'acerbaixano',
 				'az@alt=short' => 'azerí',
 				'ba' => 'baxkir',
 				'ban' => 'balinés',
 				'bas' => 'basaa',
 				'be' => 'bielorruso',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'búlgaro',
 				'bgn' => 'baluchi occidental',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'siksiká',
 				'bm' => 'bambara',
 				'bn' => 'bengalí',
 				'bo' => 'tibetano',
 				'br' => 'bretón',
 				'brx' => 'bodo',
 				'bs' => 'bosníaco',
 				'bug' => 'buginés',
 				'byn' => 'blin',
 				'ca' => 'catalán',
 				'ce' => 'checheno',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'chamorro',
 				'chk' => 'chuuk',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdo soraní',
 				'co' => 'corso',
 				'crs' => 'seselwa (crioulo das Seychelles)',
 				'cs' => 'checo',
 				'cu' => 'eslavo eclesiástico',
 				'cv' => 'chuvaxo',
 				'cy' => 'galés',
 				'da' => 'dinamarqués',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'alemán',
 				'de_AT' => 'alemán austríaco',
 				'de_CH' => 'alto alemán suízo',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'dsb' => 'baixo sorbio',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'exipcio antigo',
 				'eka' => 'ekajuk',
 				'el' => 'grego',
 				'en' => 'inglés',
 				'en_AU' => 'inglés australiano',
 				'en_CA' => 'inglés canadense',
 				'en_GB' => 'inglés británico',
 				'en_GB@alt=short' => 'inglés (RU)',
 				'en_US' => 'inglés estadounidense',
 				'en_US@alt=short' => 'inglés (EUA)',
 				'eo' => 'esperanto',
 				'es' => 'español',
 				'es_419' => 'español de América',
 				'es_ES' => 'español de España',
 				'es_MX' => 'español de México',
 				'et' => 'estoniano',
 				'eu' => 'éuscaro',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'ff' => 'fula',
 				'fi' => 'finés',
 				'fil' => 'filipino',
 				'fj' => 'fixiano',
 				'fo' => 'feroés',
 				'fon' => 'fon',
 				'fr' => 'francés',
 				'fr_CA' => 'francés canadense',
 				'fr_CH' => 'francés suízo',
 				'fur' => 'friulano',
 				'fy' => 'frisón occidental',
 				'ga' => 'irlandés',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gd' => 'gaélico escocés',
 				'gez' => 'ge’ez',
 				'gil' => 'kiribatiano',
 				'gl' => 'galego',
 				'gn' => 'guaraní',
 				'gor' => 'gorontalo',
 				'grc' => 'grego antigo',
 				'gsw' => 'alemán suízo',
 				'gu' => 'guxarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'haw' => 'hawaiano',
 				'he' => 'hebreo',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hmn' => 'hmong',
 				'hr' => 'croata',
 				'hsb' => 'alto sorbio',
 				'ht' => 'crioulo haitiano',
 				'hu' => 'húngaro',
 				'hup' => 'hupa',
 				'hy' => 'armenio',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesio',
 				'ig' => 'igbo',
 				'ii' => 'yi sichuanés',
 				'ilo' => 'ilocano',
 				'inh' => 'inguxo',
 				'io' => 'ido',
 				'is' => 'islandés',
 				'it' => 'italiano',
 				'iu' => 'inuktitut',
 				'ja' => 'xaponés',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'xavanés',
 				'ka' => 'xeorxiano',
 				'kab' => 'cabila',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'cabardiano',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'caboverdiano',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'casaco',
 				'kkj' => 'kako',
 				'kl' => 'groenlandés',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannará',
 				'ko' => 'coreano',
 				'koi' => 'komi permio',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'carachaio-bálcara',
 				'krl' => 'carelio',
 				'kru' => 'kurukh',
 				'ks' => 'caxemirés',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurdo',
 				'kum' => 'kumyk',
 				'kv' => 'komi',
 				'kw' => 'córnico',
 				'ky' => 'kirguiz',
 				'la' => 'latín',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lb' => 'luxemburgués',
 				'lez' => 'lezguio',
 				'lg' => 'ganda',
 				'li' => 'limburgués',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laosiano',
 				'loz' => 'lozi',
 				'lrc' => 'luri setentrional',
 				'lt' => 'lituano',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letón',
 				'mad' => 'madurés',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'crioulo mauriciano',
 				'mg' => 'malgaxe',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshalés',
 				'mi' => 'maorí',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedonio',
 				'ml' => 'malabar',
 				'mn' => 'mongol',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malaio',
 				'mt' => 'maltés',
 				'mua' => 'mundang',
 				'mul' => 'varias linguas',
 				'mus' => 'creek',
 				'mwl' => 'mirandés',
 				'my' => 'birmano',
 				'myv' => 'erzya',
 				'mzn' => 'mazandaraní',
 				'na' => 'nauruano',
 				'nap' => 'napolitano',
 				'naq' => 'nama',
 				'nb' => 'noruegués bokmål',
 				'nd' => 'ndebele setentrional',
 				'nds' => 'baixo alemán',
 				'nds_NL' => 'baixo saxón',
 				'ne' => 'nepalí',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueano',
 				'nl' => 'neerlandés',
 				'nl_BE' => 'flamengo',
 				'nmg' => 'kwasio',
 				'nn' => 'noruegués nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'noruegués',
 				'nog' => 'nogai',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sesotho do norte',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'occitano',
 				'om' => 'oromo',
 				'or' => 'odiá',
 				'os' => 'ossetio',
 				'pa' => 'panxabí',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauano',
 				'pcm' => 'pidgin nixeriano',
 				'pl' => 'polaco',
 				'prg' => 'prusiano',
 				'ps' => 'paxto',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués do Brasil',
 				'pt_PT' => 'portugués de Portugal',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongano',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romanés',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
 				'root' => 'raíz',
 				'ru' => 'ruso',
 				'rup' => 'aromanés',
 				'rw' => 'kiñaruanda',
 				'rwk' => 'rwa',
 				'sa' => 'sánscrito',
 				'sad' => 'sandawe',
 				'sah' => 'iacuto',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siciliano',
 				'sco' => 'escocés',
 				'sd' => 'sindhi',
 				'sdh' => 'kurdo meridional',
 				'se' => 'saami setentrional',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sh' => 'serbocroata',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'si' => 'cingalés',
 				'sk' => 'eslovaco',
 				'sl' => 'esloveno',
 				'sm' => 'samoano',
 				'sma' => 'saami meridional',
 				'smj' => 'saami de Lule',
 				'smn' => 'saami de Inari',
 				'sms' => 'saami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalí',
 				'sq' => 'albanés',
 				'sr' => 'serbio',
 				'srn' => 'sranan tongo',
 				'ss' => 'suazi',
 				'ssy' => 'saho',
 				'st' => 'sesotho',
 				'su' => 'sundanés',
 				'suk' => 'sukuma',
 				'sv' => 'sueco',
 				'sw' => 'suahili',
 				'sw_CD' => 'suahili congolés',
 				'swb' => 'comoriano',
 				'syr' => 'siríaco',
 				'ta' => 'támil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'tet' => 'tetun',
 				'tg' => 'taxico',
 				'th' => 'tailandés',
 				'ti' => 'tigriña',
 				'tig' => 'tigré',
 				'tk' => 'turcomán',
 				'tl' => 'tagalo',
 				'tlh' => 'klingon',
 				'tn' => 'tswana',
 				'to' => 'tongano',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tártaro',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalés',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiano',
 				'tyv' => 'tuvaniano',
 				'tzm' => 'tamazight de Marrocos central',
 				'udm' => 'udmurto',
 				'ug' => 'uigur',
 				'uk' => 'ucraíno',
 				'umb' => 'umbundu',
 				'und' => 'lingua descoñecida',
 				'ur' => 'urdú',
 				'uz' => 'uzbeco',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamita',
 				'vo' => 'volapuk',
 				'vun' => 'vunjo',
 				'wa' => 'valón',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray-waray',
 				'wbp' => 'walrpiri',
 				'wo' => 'wólof',
 				'xal' => 'calmuco',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'ioruba',
 				'yue' => 'cantonés',
 				'zgh' => 'tamazight marroquí estándar',
 				'zh' => 'chinés',
 				'zh_Hans' => 'chinés simplificado',
 				'zh_Hant' => 'chinés tradicional',
 				'zu' => 'zulú',
 				'zun' => 'zuni',
 				'zxx' => 'sen contido lingüístico',
 				'zza' => 'zazaki',

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
			'Arab' => 'árabe',
 			'Arab@alt=variant' => 'perso-árabe',
 			'Armn' => 'armenio',
 			'Beng' => 'bengalí',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cans' => 'Silabario aborixe canadiano unificado',
 			'Cyrl' => 'cirílico',
 			'Deva' => 'devanágari',
 			'Ethi' => 'etíope',
 			'Geor' => 'xeorxiano',
 			'Grek' => 'grego',
 			'Gujr' => 'guxaratí',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'simplificado',
 			'Hans@alt=stand-alone' => 'han simplificado',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hebr' => 'hebreo',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'silabarios xaponeses',
 			'Jamo' => 'jamo',
 			'Jpan' => 'xaponés',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'canarés',
 			'Kore' => 'coreano',
 			'Laoo' => 'laosiano',
 			'Latn' => 'latino',
 			'Mlym' => 'malabar',
 			'Mong' => 'mongol',
 			'Mymr' => 'birmano',
 			'Orya' => 'oriá',
 			'Sinh' => 'cingalés',
 			'Taml' => 'támil',
 			'Telu' => 'telugu',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandés',
 			'Tibt' => 'tibetano',
 			'Zmth' => 'notación matemática',
 			'Zsye' => 'emojis',
 			'Zsym' => 'símbolos',
 			'Zxxx' => 'non escrito',
 			'Zyyy' => 'común',
 			'Zzzz' => 'alfabeto descoñecido',

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
 			'002' => 'África',
 			'003' => 'Norteamérica',
 			'005' => 'Suramérica',
 			'009' => 'Oceanía',
 			'011' => 'África Occidental',
 			'013' => 'América Central',
 			'014' => 'África Oriental',
 			'015' => 'África Setentrional',
 			'017' => 'África Central',
 			'018' => 'África Meridional',
 			'019' => 'América',
 			'021' => 'América do Norte',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia Meridional',
 			'035' => 'Sueste Asiático',
 			'039' => 'Europa Meridional',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Rexión da Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Central',
 			'145' => 'Asia Occidental',
 			'150' => 'Europa',
 			'151' => 'Europa do Leste',
 			'154' => 'Europa Setentrional',
 			'155' => 'Europa Occidental',
 			'202' => 'África subsahariana',
 			'419' => 'América Latina',
 			'AC' => 'Illa de Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Os Emiratos Árabes Unidos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'A Antártida',
 			'AR' => 'A Arxentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Illas Åland',
 			'AZ' => 'Acerbaixán',
 			'BA' => 'Bosnia e Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélxica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Illas Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribe Neerlandés',
 			'BR' => 'O Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bután',
 			'BV' => 'Illa Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarús',
 			'BZ' => 'Belize',
 			'CA' => 'O Canadá',
 			'CC' => 'Illas Cocos (Keeling)',
 			'CD' => 'República Democrática do Congo',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'República do Congo',
 			'CG@alt=variant' => 'Congo (RC)',
 			'CH' => 'Suíza',
 			'CI' => 'Costa do Marfil',
 			'CI@alt=variant' => 'CI',
 			'CK' => 'Illas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'A China',
 			'CO' => 'Colombia',
 			'CP' => 'Illa Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Illa Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'República Checa',
 			'DE' => 'Alemaña',
 			'DG' => 'Diego García',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Alxeria',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Exipto',
 			'EH' => 'O Sáhara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Unión Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fixi',
 			'FK' => 'Illas Malvinas',
 			'FK@alt=variant' => 'Illas Malvinas (Falkland)',
 			'FM' => 'Micronesia',
 			'FO' => 'Illas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'O Reino Unido',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Granada',
 			'GE' => 'Xeorxia',
 			'GF' => 'Güiana Francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Xibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Illas Xeorxia do Sur e Sandwich do Sur',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'A Guinea Bissau',
 			'GY' => 'Güiana',
 			'HK' => 'Hong Kong RAE da China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Illa Heard e Illas McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hungría',
 			'IC' => 'Illas Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Illa de Man',
 			'IN' => 'A India',
 			'IO' => 'Territorio Británico do Océano Índico',
 			'IQ' => 'Iraq',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Xamaica',
 			'JO' => 'Xordania',
 			'JP' => 'O Xapón',
 			'KE' => 'Kenya',
 			'KG' => 'Kirguizistán',
 			'KH' => 'Camboxa',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'Saint Kitts e Nevis',
 			'KP' => 'Corea do Norte',
 			'KR' => 'Corea do Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Illas Caimán',
 			'KZ' => 'Casaquistán',
 			'LA' => 'Laos',
 			'LB' => 'O Líbano',
 			'LC' => 'Santa Lucía',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marrocos',
 			'MC' => 'Mónaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Illas Marshall',
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (ARIM)',
 			'ML' => 'Malí',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau RAE da China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Illas Marianas do Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'México',
 			'MY' => 'Malaisia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nova Caledonia',
 			'NE' => 'Níxer',
 			'NF' => 'Illa Norfolk',
 			'NG' => 'Nixeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Baixos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelandia',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'O Perú',
 			'PF' => 'A Polinesia Francesa',
 			'PG' => 'Papúa-Nova Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistán',
 			'PL' => 'Polonia',
 			'PM' => 'Saint Pierre et Miquelon',
 			'PN' => 'Illas Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Territorios Palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'O Paraguai',
 			'QA' => 'Qatar',
 			'QO' => 'Territorios afastados de Oceanía',
 			'RE' => 'Reunión',
 			'RO' => 'Romanía',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Illas Salomón',
 			'SC' => 'Seychelles',
 			'SD' => 'O Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Serra Leoa',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'O Sudán do Sur',
 			'ST' => 'San Tomé e Príncipe',
 			'SV' => 'O Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Suazilandia',
 			'TA' => 'Tristán da Cunha',
 			'TC' => 'Illas Turks e Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Austrais Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Taxiquistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'TL',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraína',
 			'UG' => 'Uganda',
 			'UM' => 'Illas Menores Distantes dos Estados Unidos',
 			'UN' => 'Nacións Unidas',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Os Estados Unidos',
 			'US@alt=short' => 'EUA',
 			'UY' => 'O Uruguai',
 			'UZ' => 'Uzbequistán',
 			'VA' => 'Cidade do Vaticano',
 			'VC' => 'San Vicente e As Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Illas Virxes Británicas',
 			'VI' => 'Illas Virxes Estadounidenses',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'O Iemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suráfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Rexión descoñecida',

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
 			'cf' => 'formato de moeda',
 			'colalternate' => 'Ignorar clasificación de símbolos',
 			'colbackwards' => 'Clasificación de acentos invertida',
 			'colcasefirst' => 'Orde de maiúsculas/minúsculas',
 			'colcaselevel' => 'Clasificación que distingue entre maiúsculas e minúsculas',
 			'collation' => 'criterio de ordenación',
 			'colnormalization' => 'Clasificación normalizada',
 			'colnumeric' => 'Clasificación numérica',
 			'colstrength' => 'Forza de clasificación',
 			'currency' => 'moeda',
 			'hc' => 'ciclo horario (12 ou 24)',
 			'lb' => 'estilo de quebra de liña',
 			'ms' => 'sistema internacional de unidades',
 			'numbers' => 'números',
 			'timezone' => 'Fuso horario',
 			'va' => 'Variante local',
 			'x' => 'Uso privado',

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
 				'buddhist' => q{calendario budista},
 				'chinese' => q{calendario chinés},
 				'coptic' => q{Calendario cóptico},
 				'dangi' => q{calendario dangi},
 				'ethiopic' => q{calendario etíope},
 				'ethiopic-amete-alem' => q{Calendario Amete Alem etíope},
 				'gregorian' => q{calendario gregoriano},
 				'hebrew' => q{calendario hebreo},
 				'indian' => q{Calendario nacional indio},
 				'islamic' => q{calendario islámico},
 				'islamic-civil' => q{Calendario islámico (civil, tabular)},
 				'islamic-rgsa' => q{Calendario islámico (Arabia Saudita,},
 				'iso8601' => q{calendario ISO-8601},
 				'japanese' => q{calendario xaponés},
 				'persian' => q{calendario persa},
 				'roc' => q{calendario Minguo},
 			},
 			'cf' => {
 				'account' => q{formato de moeda contable},
 				'standard' => q{formato de moeda estándar},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Clasificar símbolos},
 				'shifted' => q{Clasificar ignorando símbolos},
 			},
 			'colbackwards' => {
 				'no' => q{Clasificar acentos con normalidade},
 				'yes' => q{Clasificar acentos invertidos},
 			},
 			'colcasefirst' => {
 				'lower' => q{Clasificar primeiro as minúsculas},
 				'no' => q{Clasificar orde de maiúsculas e minúsculas normal},
 				'upper' => q{Clasificar primeiro as maiúsculas},
 			},
 			'colcaselevel' => {
 				'no' => q{Clasificar sen distinguir entre maiúsculas e minúsculas},
 				'yes' => q{Clasificar distinguindo entre maiúsculas e minúsculas},
 			},
 			'collation' => {
 				'big5han' => q{Orde de clasificación chinesa tradicional - Big5},
 				'dictionary' => q{Criterio de ordenación do dicionario},
 				'ducet' => q{criterio de ordenación Unicode predeterminado},
 				'gb2312han' => q{orde de clasifcación chinesa simplificada - GB2312},
 				'phonebook' => q{orde de clasificación da guía telefónica},
 				'phonetic' => q{Orde de clasificación fonética},
 				'pinyin' => q{Orde de clasificación pinyin},
 				'reformed' => q{Criterio de ordenación reformado},
 				'search' => q{busca de carácter xeral},
 				'searchjl' => q{Clasificar por consonante inicial hangul},
 				'standard' => q{criterio de ordenación estándar},
 				'stroke' => q{Orde de clasificación polo número de trazos},
 				'traditional' => q{Orde de clasificación tradicional},
 				'unihan' => q{Criterio de ordenación radical-trazo},
 			},
 			'colnormalization' => {
 				'no' => q{Clasificar sen normalización},
 				'yes' => q{Clasificar Unicode normalizado},
 			},
 			'colnumeric' => {
 				'no' => q{Clasificar díxitos individualmente},
 				'yes' => q{Clasificar díxitos numericamente},
 			},
 			'colstrength' => {
 				'identical' => q{Clasificar todo},
 				'primary' => q{Clasificar só letras de base},
 				'quaternary' => q{Clasificar acentos/maiúsculas e minúsculas/ancho/kana},
 				'secondary' => q{Clasificar acentos},
 				'tertiary' => q{Clasificar acentos/maiúsculas e minúsculas/ancho},
 			},
 			'd0' => {
 				'fwidth' => q{ancho completo},
 				'hwidth' => q{ancho medio},
 				'npinyin' => q{Numérico},
 			},
 			'hc' => {
 				'h11' => q{sistema de 12 horas (0–11)},
 				'h12' => q{sistema de 12 horas (1–12)},
 				'h23' => q{sistema de 24 horas (0–23)},
 				'h24' => q{sistema de 24 horas (1–24)},
 			},
 			'lb' => {
 				'loose' => q{estilo de quebra de liña separada},
 				'normal' => q{estilo de quebra de liña normal},
 				'strict' => q{estilo de quebra de liña estrita},
 			},
 			'm0' => {
 				'bgn' => q{transliteración do BGN},
 				'ungegn' => q{transliteración do UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{sistema métrico decimal},
 				'uksystem' => q{sistema imperial de unidades},
 				'ussystem' => q{sistema estadounidense de unidades},
 			},
 			'numbers' => {
 				'arab' => q{díxitos arábigo-índicos},
 				'arabext' => q{díxitos arábigo-índicos ampliados},
 				'armn' => q{numeración armenia},
 				'armnlow' => q{numeración armenia en minúscula},
 				'beng' => q{díxitos bengalís},
 				'deva' => q{díxitos devanagáricos},
 				'ethi' => q{numeración etíope},
 				'finance' => q{Números financeiros},
 				'fullwide' => q{díxitos de ancho completo},
 				'geor' => q{numeración xeorxiana},
 				'grek' => q{numeración grega},
 				'greklow' => q{numeración grega en minúscula},
 				'gujr' => q{díxitos guxaratís},
 				'guru' => q{díxitos do gurmukhi},
 				'hanidec' => q{numeración decimal chinesa},
 				'hans' => q{numeración chinesa simplificada},
 				'hansfin' => q{numeración financeira chinesa simplificada},
 				'hant' => q{numeración chinesa tradicional},
 				'hantfin' => q{numeración financeira chinesa tradicional},
 				'hebr' => q{numeración hebrea},
 				'jpan' => q{numeración xaponesa},
 				'jpanfin' => q{numeración financeira xaponesa},
 				'khmr' => q{díxitos khmer},
 				'knda' => q{díxitos canareses},
 				'laoo' => q{díxitos laosianos},
 				'latn' => q{díxitos occidentais},
 				'mlym' => q{díxitos malabares},
 				'mong' => q{Díxitos mongoles},
 				'mymr' => q{díxitos birmanos},
 				'native' => q{Díxitos orixinais},
 				'orya' => q{díxitos do oriá},
 				'roman' => q{numeración romana},
 				'romanlow' => q{numeración romana en minúsculas},
 				'taml' => q{numeración támil tradicional},
 				'tamldec' => q{díxitos do támil},
 				'telu' => q{díxitos de telugu},
 				'thai' => q{díxitos tailandeses},
 				'tibt' => q{díxitos tibetanos},
 				'traditional' => q{Numeros tradicionais},
 				'vaii' => q{Díxitos Vai},
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
			'metric' => q{métrico decimal},
 			'UK' => q{británico},
 			'US' => q{estadounidense},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Idioma: {0}',
 			'script' => 'Alfabeto: {0}',
 			'region' => 'Rexión: {0}',

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
			auxiliary => qr{[ª à â å ä ã ç è ê ë ì î ï º ò ô ö õ ù û]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á b c d e é f g h i í j k l m n ñ o ó p q r s t u ú ü v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}… {1}',
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
						'name' => q(punto cardinal),
					},
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					'arc-minute' => {
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					'arc-second' => {
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					'atmosphere' => {
						'name' => q(atmosferas),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferas),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(calorías),
						'one' => q({0} caloría),
						'other' => q({0} calorías),
					},
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					'celsius' => {
						'name' => q(graos Celsius),
						'one' => q({0} grao Celsius),
						'other' => q({0} graos Celsius),
					},
					'centiliter' => {
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					'centimeter' => {
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					'century' => {
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					'cubic-centimeter' => {
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					'cubic-foot' => {
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					'cubic-inch' => {
						'name' => q(polgadas cúbicas),
						'one' => q({0} polgada cúbica),
						'other' => q({0} polgadas cúbicas),
					},
					'cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					'cubic-meter' => {
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					'cubic-mile' => {
						'name' => q(millas cúbicas),
						'one' => q({0} milla cúbica),
						'other' => q({0} millas cúbicas),
					},
					'cubic-yard' => {
						'name' => q(iardas cúbicas),
						'one' => q({0} iarda cúbica),
						'other' => q({0} iardas cúbicas),
					},
					'cup' => {
						'name' => q(cuncas),
						'one' => q({0} cunca),
						'other' => q({0} cuncas),
					},
					'cup-metric' => {
						'name' => q(cuncas métricas),
						'one' => q({0} cunca métrica),
						'other' => q({0} cuncas métricas),
					},
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0} por día),
					},
					'deciliter' => {
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					'decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					'degree' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					'fahrenheit' => {
						'name' => q(graos Fahrenheit),
						'one' => q({0} grao Fahrenheit),
						'other' => q({0} graos Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					'foodcalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					'foot' => {
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					'g-force' => {
						'name' => q(forzas G),
						'one' => q({0} forza G),
						'other' => q({0} forzas G),
					},
					'gallon' => {
						'name' => q(galóns estadounidenses),
						'one' => q({0} galón estadounidense),
						'other' => q({0} galóns estadounidenses),
						'per' => q({0} por galón estadounidense),
					},
					'gallon-imperial' => {
						'name' => q(galóns imperiais),
						'one' => q({0} galón imperial),
						'other' => q({0} galóns imperiais),
						'per' => q({0} por galón imperial),
					},
					'generic' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					'gigabit' => {
						'name' => q(xigabits),
						'one' => q({0} xigabit),
						'other' => q({0} xigabits),
					},
					'gigabyte' => {
						'name' => q(xigabytes),
						'one' => q({0} xigabyte),
						'other' => q({0} xigabytes),
					},
					'gigahertz' => {
						'name' => q(xigahertz),
						'one' => q({0} xigahertz),
						'other' => q({0} xigahertz),
					},
					'gigawatt' => {
						'name' => q(xigawatts),
						'one' => q({0} xigawatt),
						'other' => q({0} xigawatts),
					},
					'gram' => {
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} por gramo),
					},
					'hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} hectárea),
						'other' => q({0} hectáreas),
					},
					'hectoliter' => {
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					'hectopascal' => {
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(cabalo de potencia),
						'one' => q({0} cabalo de potencia),
						'other' => q({0} cabalos de potencia),
					},
					'hour' => {
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					'inch' => {
						'name' => q(polgadas),
						'one' => q({0} polgada),
						'other' => q({0} polgadas),
						'per' => q({0} por polgada),
					},
					'inch-hg' => {
						'name' => q(polgadas de mercurio),
						'one' => q({0} polgada de mercurio),
						'other' => q({0} polgadas de mercurio),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					'kelvin' => {
						'name' => q(graos Kelvin),
						'one' => q({0} grao Kelvin),
						'other' => q({0} graos Kelvin),
					},
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					'kilocalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					'kilogram' => {
						'name' => q(quilogramos),
						'one' => q({0} quilogramo),
						'other' => q({0} quilogramos),
						'per' => q({0} por quilogramo),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					'kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
					},
					'kilometer-per-hour' => {
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					'kilowatt' => {
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(quilowatts/hora),
						'one' => q({0} quilowatt/hora),
						'other' => q({0} quilowatts/hora),
					},
					'knot' => {
						'name' => q(nós),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					'light-year' => {
						'name' => q(anos luz),
						'one' => q({0} ano luz),
						'other' => q({0} anos luz),
					},
					'liter' => {
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					'liter-per-100kilometers' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					'liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					'lux' => {
						'name' => q(luxes),
						'one' => q({0} lux),
						'other' => q({0} luxes),
					},
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					'meter-per-second' => {
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					'meter-per-second-squared' => {
						'name' => q(metros por segundo cadrado),
						'one' => q({0} metro por segundo cadrado),
						'other' => q({0} metros por segundo cadrado),
					},
					'metric-ton' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					'microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramo),
						'other' => q({0} microgramos),
					},
					'micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					'microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundo),
						'other' => q({0} microsegundos),
					},
					'mile' => {
						'name' => q(millas),
						'one' => q({0} milla),
						'other' => q({0} millas),
					},
					'mile-per-gallon' => {
						'name' => q(millas por galón estadounidense),
						'one' => q({0} milla por galón estadounidense),
						'other' => q({0} millas por galón estadounidense),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(millas por galón imperial),
						'one' => q({0} milla por galón imperial),
						'other' => q({0} millas por galón imperial),
					},
					'mile-per-hour' => {
						'name' => q(millas por hora),
						'one' => q({0} milla por hora),
						'other' => q({0} millas por hora),
					},
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
						'one' => q({0} milla escandinava),
						'other' => q({0} millas escandinavas),
					},
					'milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					'millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					'milligram' => {
						'name' => q(miligramos),
						'one' => q({0} miligramo),
						'other' => q({0} miligramos),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligramos por decilitro),
						'one' => q({0} miligramo por decilitro),
						'other' => q({0} miligramos por decilitro),
					},
					'milliliter' => {
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					'millimeter' => {
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					'millimeter-of-mercury' => {
						'name' => q(milímetros de mercurio),
						'one' => q({0} milímetro de mercurio),
						'other' => q({0} milímetros de mercurio),
					},
					'millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimoles por litro),
					},
					'millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundos),
					},
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} por mes),
					},
					'nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					'nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundos),
					},
					'nautical-mile' => {
						'name' => q(millas náuticas),
						'one' => q({0} milla náutica),
						'other' => q({0} millas náuticas),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(onzas),
						'one' => q({0} onza),
						'other' => q({0} onzas),
						'per' => q({0} por onza),
					},
					'ounce-troy' => {
						'name' => q(onzas troy),
						'one' => q({0} onza troy),
						'other' => q({0} onzas troy),
					},
					'parsec' => {
						'name' => q(pársecs),
						'one' => q({0} pársec),
						'other' => q({0} pársecs),
					},
					'part-per-million' => {
						'name' => q(partes por millón),
						'one' => q({0} parte por millón),
						'other' => q({0} partes por millón),
					},
					'per' => {
						'1' => q({0} por {1}),
					},
					'percent' => {
						'name' => q(tanto por cento),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'permille' => {
						'name' => q(tanto por mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					'picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					'pint' => {
						'name' => q(pintas),
						'one' => q({0} pinta),
						'other' => q({0} pintas),
					},
					'pint-metric' => {
						'name' => q(pintas métricas),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintas métricas),
					},
					'point' => {
						'name' => q(puntos),
						'one' => q({0} punto),
						'other' => q({0} puntos),
					},
					'pound' => {
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					'pound-per-square-inch' => {
						'name' => q(libras por polgada cadrada),
						'one' => q({0} libra por polgada cadrada),
						'other' => q({0} libras por polgada cadrada),
					},
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuarto),
						'other' => q({0} cuartos),
					},
					'radian' => {
						'name' => q(radiáns),
						'one' => q({0} radián),
						'other' => q({0} radiáns),
					},
					'revolution' => {
						'name' => q(revoluciones),
						'one' => q({0} revolución),
						'other' => q({0} revolucións),
					},
					'second' => {
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					'square-centimeter' => {
						'name' => q(centímetros cadrados),
						'one' => q({0} centímetro cadrado),
						'other' => q({0} centímetros cadrados),
						'per' => q({0} por centímetro cadrado),
					},
					'square-foot' => {
						'name' => q(pés cadrados),
						'one' => q({0} pé cadrado),
						'other' => q({0} pés cadrados),
					},
					'square-inch' => {
						'name' => q(polgadas cadradas),
						'one' => q({0} polgada cadrada),
						'other' => q({0} polgadas cadradas),
						'per' => q({0} por polgada cadrada),
					},
					'square-kilometer' => {
						'name' => q(quilómetros cadrados),
						'one' => q({0} quilómetro cadrado),
						'other' => q({0} quilómetros cadrados),
						'per' => q({0} por quilómetro cadrado),
					},
					'square-meter' => {
						'name' => q(metros cadrados),
						'one' => q({0} metro cadrado),
						'other' => q({0} metros cadrados),
						'per' => q({0} por metro cadrado),
					},
					'square-mile' => {
						'name' => q(millas cadradas),
						'one' => q({0} milla cadrada),
						'other' => q({0} millas cadradas),
						'per' => q({0} por milla cadrada),
					},
					'square-yard' => {
						'name' => q(iardas cadradas),
						'one' => q({0} iarda cadrada),
						'other' => q({0} iardas cadradas),
					},
					'tablespoon' => {
						'name' => q(culleradas),
						'one' => q({0} cullerada),
						'other' => q({0} culleradas),
					},
					'teaspoon' => {
						'name' => q(culleriñas),
						'one' => q({0} culleriña),
						'other' => q({0} culleriñas),
					},
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					'ton' => {
						'name' => q(toneladas estadounidenses),
						'one' => q({0} tonelada estadounidense),
						'other' => q({0} toneladas estadounidenses),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					'week' => {
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					'yard' => {
						'name' => q(iardas),
						'one' => q({0} iarda),
						'other' => q({0} iardas),
					},
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0} por ano),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(dirección),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
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
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'meter' => {
						'name' => q(m),
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
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
					},
					'year' => {
						'name' => q(a.),
						'one' => q({0} a.),
						'other' => q({0} a.),
					},
				},
				'short' => {
					'' => {
						'name' => q(dirección),
					},
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(minutos),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(segundos),
						'one' => q({0}′′),
						'other' => q({0}′′),
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
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} CT),
						'other' => q({0} CT),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} séc.),
					},
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
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
						'name' => q(cuncas),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(cuncas métr.),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(días),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(pés),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(forzas G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal EUA),
						'one' => q({0} gal EUA),
						'other' => q({0} gal EUA),
						'per' => q({0}/gal EUA),
					},
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					'generic' => {
						'name' => q(graos),
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
						'name' => q(gramos),
						'one' => q({0} gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
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
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(polg.),
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
						'name' => q(joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} CT),
						'other' => q({0} CT),
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
						'name' => q(quilojoule),
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
						'name' => q(kW/h),
						'one' => q({0} kW/h),
						'other' => q({0} kW/h),
					},
					'knot' => {
						'name' => q(nós),
						'one' => q({0} nós),
						'other' => q({0} nós),
					},
					'light-year' => {
						'name' => q(anos luz),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					'liter' => {
						'name' => q(litros),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(litros/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(luxes),
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
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
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
						'one' => q({0} t),
						'other' => q({0} t),
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
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(millas),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(millas/galón EUA),
						'one' => q({0} mpg EUA),
						'other' => q({0} mpg EUA),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(millas/gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(millas/hora),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(mi esc.),
						'one' => q({0} mi esc.),
						'other' => q({0} mi esc.),
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
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
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
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
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
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0}/mes),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					'ohm' => {
						'name' => q(ohms),
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
						'name' => q(pársecs),
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
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
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
						'name' => q(pintas),
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
						'name' => q(libras),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radiáns),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
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
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
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
						'name' => q(tn EUA),
						'one' => q({0} tn EUA),
						'other' => q({0} tn EUA),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					'yard' => {
						'name' => q(iardas),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
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
	default		=> sub { qr'^(?i:non|n)$' }
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
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 millón',
					'other' => '0 millóns',
				},
				'10000000' => {
					'one' => '00 millóns',
					'other' => '00 millóns',
				},
				'100000000' => {
					'one' => '000 millóns',
					'other' => '000 millóns',
				},
				'1000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000000000' => {
					'one' => '0 billón',
					'other' => '0 billóns',
				},
				'10000000000000' => {
					'one' => '00 billóns',
					'other' => '00 billóns',
				},
				'100000000000000' => {
					'one' => '000 billóns',
					'other' => '000 billóns',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000000000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
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
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham dos Emiratos Árabes Unidos),
				'one' => q(dirham dos Emiratos Árabes Unidos),
				'other' => q(dirhams dos Emiratos Árabes Unidos),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgani afgano),
				'one' => q(afgani afgano),
				'other' => q(afganis afganos),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek albanés),
				'one' => q(lek albanés),
				'other' => q(leks albaneses),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram armenio),
				'one' => q(dram armenio),
				'other' => q(drams armenios),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Florín das Antillas Neerlandesas),
				'one' => q(florín das Antillas Neerlandesas),
				'other' => q(floríns das Antillas Neerlandesas),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza angolano),
				'one' => q(kwanza angolano),
				'other' => q(kwanzas angolanos),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso arxentino \(1983–1985\)),
				'one' => q(peso arxentino \(ARP\)),
				'other' => q(pesos arxentinos \(ARP\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso arxentino),
				'one' => q(peso arxentino),
				'other' => q(pesos arxentinos),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dólar australiano),
				'one' => q(dólar australiano),
				'other' => q(dólares australianos),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florín de Aruba),
				'one' => q(florín de Aruba),
				'other' => q(floríns de Aruba),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat acerbaixano),
				'one' => q(manat acerbaixano),
				'other' => q(manats acerbaixanos),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Marco convertible de Bosnia e Hercegovina),
				'one' => q(marco convertible de Bosnia e Hercegovina),
				'other' => q(marcos convertibles de Bosnia e Hercegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dólar de Barbados),
				'one' => q(dólar de Barbados),
				'other' => q(dólares de Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka de Bangladés),
				'one' => q(taka de Bangladés),
				'other' => q(takas de Bangladés),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Franco belga \(convertible\)),
				'one' => q(franco belga \(convertible\)),
				'other' => q(francos belgas \(convertibles\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franco belga),
				'one' => q(franco belga),
				'other' => q(francos belgas),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Franco belga \(financeiro\)),
				'one' => q(franco belga \(financeiro\)),
				'other' => q(francos belgas \(financeiros\)),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev búlgaro),
				'one' => q(lev búlgaro),
				'other' => q(levs búlgaros),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar de Bahrain),
				'one' => q(dinar de Bahrain),
				'other' => q(dinares de Bahrain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franco burundiano),
				'one' => q(franco burundiano),
				'other' => q(francos burundianos),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dólar das Bemudas),
				'one' => q(dólar das Bermudas),
				'other' => q(dólares das Bermudas),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dólar de Brunei),
				'one' => q(dólar de Brunei),
				'other' => q(dólares de Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(boliviano),
				'other' => q(bolivianos),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso boliviano),
				'one' => q(peso boliviano),
				'other' => q(pesos bolivianos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(MVDOL boliviano),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro novo brasileiro \(1967–1986\)),
				'one' => q(cruzeiro novo brasileiro),
				'other' => q(cruzeiros novos brasileiros),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado brasileiro),
				'one' => q(cruzado brasileiro),
				'other' => q(cruzados brasileiros),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro brasileiro \(1990–1993\)),
				'one' => q(cruzeiro brasileiro \(BRE\)),
				'other' => q(cruzeiros brasileiros \(BRE\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real brasileiro),
				'one' => q(real brasileiro),
				'other' => q(reais brasileiros),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado novo brasileiro),
				'one' => q(cruzado novo brasileiro),
				'other' => q(cruzados novos brasileiros),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro brasileiro),
				'one' => q(cruzeiro brasileiro),
				'other' => q(cruzeiros brasileiros),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dólar das Bahamas),
				'one' => q(dólar das Bahamas),
				'other' => q(dólares das Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum butanés),
				'one' => q(ngultrum butanés),
				'other' => q(ngultrums butaneses),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula botsuaniano),
				'one' => q(pula botsuaniano),
				'other' => q(pulas botsuanianos),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rublo bielorruso),
				'one' => q(rublo bielorruso),
				'other' => q(rublos bielorrusos),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rublo bielorruso \(2000–2016\)),
				'one' => q(rublo bielorruso \(2000–2016\)),
				'other' => q(rublos bielorrusos \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dólar belizense),
				'one' => q(dólar belizense),
				'other' => q(dólares belizenses),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dólar canadense),
				'one' => q(dólar canadense),
				'other' => q(dólares canadenses),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franco congolés),
				'one' => q(franco congolés),
				'other' => q(francos congoleses),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franco suízo),
				'one' => q(franco suízo),
				'other' => q(francos suizos),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Unidades de fomento chilenas),
				'one' => q(unidade de fomento chilena),
				'other' => q(unidades de fomento chilenas),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso chileno),
				'one' => q(peso chileno),
				'other' => q(pesos chilenos),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Iuán chinés \(extracontinental\)),
				'one' => q(iuán chinés \(extracontinental\)),
				'other' => q(iuáns chineses \(extracontinentais\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Iuán chinés),
				'one' => q(iuán chinés),
				'other' => q(iuáns chineses),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombianos),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colón costarriqueño),
				'one' => q(colón costarriqueño),
				'other' => q(colóns costarriqueños),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso cubano convertible),
				'one' => q(peso cubano convertible),
				'other' => q(pesos cubanos convertibles),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Escudo caboverdiano),
				'one' => q(escudo caboverdiano),
				'other' => q(escudos caboverdianos),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Coroa checa),
				'one' => q(coroa checa),
				'other' => q(coroas checas),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marco alemán),
				'one' => q(marco alemán),
				'other' => q(marcos alemáns),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franco xibutiano),
				'one' => q(franco xibutiano),
				'other' => q(francos xibutianos),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Coroa dinamarquesa),
				'one' => q(coroa dinamarquesa),
				'other' => q(coroas dinamarquesas),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicanos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar alxeriano),
				'one' => q(dinar alxeriano),
				'other' => q(dinares alxerianos),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre ecuatoriano),
				'one' => q(sucre ecuatoriano),
				'other' => q(sucres ecuatorianos),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Unidade de valor constante ecuatoriana),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Libra exipcia),
				'one' => q(libra exipcia),
				'other' => q(libras exipcias),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa eritreo),
				'one' => q(nakfa eritreo),
				'other' => q(nakfas eritreos),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Peseta española \(conta A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Peseta española \(conta convertible\)),
			},
		},
		'ESP' => {
			symbol => '₧',
			display_name => {
				'currency' => q(Peseta española),
				'one' => q(peseta),
				'other' => q(pesetas),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr etíope),
				'one' => q(birr etíope),
				'other' => q(birres etíopes),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dólar fidxiano),
				'one' => q(dólar fidxiano),
				'other' => q(dólares fidxianos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Libra das Malvinas),
				'one' => q(libra das Malvinas),
				'other' => q(libras das Malvinas),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franco francés),
				'one' => q(franco francés),
				'other' => q(francos franceses),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Libra esterlina),
				'one' => q(libra esterlina),
				'other' => q(libras esterlinas),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari xeorxiano),
				'one' => q(lari xeorxiano),
				'other' => q(laris xeorxianos),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi de Ghana),
				'one' => q(cedi de Ghana),
				'other' => q(cedis de Ghana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Libra xibraltareña),
				'one' => q(libra xibraltareña),
				'other' => q(libras xibraltareñas),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi gambiano),
				'one' => q(dalasi gambiano),
				'other' => q(dalasis gambianos),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Franco guineano),
				'one' => q(franco guineano),
				'other' => q(francos guineanos),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli guineano),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele guineana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Dracma grego),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal guatemalteco),
				'one' => q(quetzal guatemalteco),
				'other' => q(quetzal guatemaltecos),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dólar güianés),
				'one' => q(dólar güianés),
				'other' => q(dólares güianeses),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dólar de Hong Kong),
				'one' => q(dólar de Hong Kong),
				'other' => q(dólares de Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira hondureño),
				'one' => q(lempira hondureño),
				'other' => q(lempiras hondureños),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunas croatas),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde haitiano),
				'one' => q(gourde haitiano),
				'other' => q(gourdes haitianos),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Florín húngaro),
				'one' => q(florín húngaro),
				'other' => q(floríns húngaros),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupia indonesia),
				'one' => q(rupia indonesia),
				'other' => q(rupias indonesias),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Libra irlandesa),
				'one' => q(libra irlandesa),
				'other' => q(libras irlandesas),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Novo shequel israelí),
				'one' => q(novo shequel israelí),
				'other' => q(novos shequeis israelís),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia india),
				'one' => q(rupia india),
				'other' => q(rupias indias),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar iraquí),
				'one' => q(dinar iraquí),
				'other' => q(dinares iraquíes),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial iraniano),
				'one' => q(rial iraniano),
				'other' => q(riais iranianos),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Coroa islandesa),
				'one' => q(coroa islandesa),
				'other' => q(coroas islandesas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira italiana),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dólar xamaicano),
				'one' => q(dólar xamaicano),
				'other' => q(dólares xamaicanos),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar xordano),
				'one' => q(dinar xordano),
				'other' => q(dinares xordanos),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Ien xaponés),
				'one' => q(ien xaponés),
				'other' => q(iens xaponeses),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Xilin kenyano),
				'one' => q(xilin kenyano),
				'other' => q(xilins kenyanos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som quirguicistano),
				'one' => q(som quirguicistano),
				'other' => q(soms quirguicistanos),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel camboxano),
				'one' => q(riel camboxano),
				'other' => q(rieis camboxanos),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franco comoriano),
				'one' => q(franco comoriano),
				'other' => q(francos comorianos),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won norcoreano),
				'one' => q(won norcoreano),
				'other' => q(wons norcoreanos),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won surcoreano),
				'one' => q(won surcoreano),
				'other' => q(wons surcoreanos),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar kuwaití),
				'one' => q(dinar kuwaití),
				'other' => q(dinares kuwaitís),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dólar das Illas Caimán),
				'one' => q(dólar das Illas Caimán),
				'other' => q(dólares das Illas Caimán),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge casaco),
				'one' => q(tenge casaco),
				'other' => q(tenges casacos),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip laosiano),
				'one' => q(kip laosiano),
				'other' => q(kips laosianos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libra libanesa),
				'one' => q(libra libanesa),
				'other' => q(libras libanesas),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia de Sri Lanka),
				'one' => q(rupia de Sri Lanka),
				'other' => q(rupias de Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dólar liberiano),
				'one' => q(dólar liberiano),
				'other' => q(dólares liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti de Lesoto),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas lituana),
				'one' => q(litas lituana),
				'other' => q(litas lituanas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Franco convertible luxemburgués),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Franco luxemburgués),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Franco financeiro luxemburgués),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats letón),
				'one' => q(lats letón),
				'other' => q(lats letóns),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar libio),
				'one' => q(dinar libio),
				'other' => q(dinares libios),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirham marroquí),
				'one' => q(dirham marroquí),
				'other' => q(dirhams marroquís),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Franco marroquí),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(leus moldavos),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariary malgaxe),
				'one' => q(ariary malgaxe),
				'other' => q(ariarys malgaxes),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Dinar macedonio),
				'one' => q(dinar macedonio),
				'other' => q(dinares macedonios),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat birmano),
				'one' => q(kyat birmano),
				'other' => q(kyats birmanos),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongoles),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca de Macau),
				'one' => q(pataca de Macau),
				'other' => q(patacas de Macau),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ouguiya mauritano \(1973–2017\)),
				'one' => q(ouguiya mauritano \(1973–2017\)),
				'other' => q(ouguiyas mauritanos \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Ouguiya mauritano),
				'one' => q(ouguiya mauritano),
				'other' => q(ouguiyas mauritanos),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupias mauricianas),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rupia maldivana),
				'one' => q(rupia maldivana),
				'other' => q(rupias maldivanas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha de Malaui),
				'one' => q(kwacha de Malaui),
				'other' => q(kwachas de Malaui),
			},
		},
		'MXN' => {
			symbol => '$MX',
			display_name => {
				'currency' => q(Peso mexicano),
				'one' => q(peso mexicano),
				'other' => q(pesos mexicanos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso de prata mexicano \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Unidade de inversión mexicana),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringgit malaio),
				'one' => q(ringgit malaio),
				'other' => q(ringgits malaios),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical de Mozambique),
				'one' => q(metical de Mozambique),
				'other' => q(meticais de Mozambique),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dólar namibio),
				'one' => q(dólar namibio),
				'other' => q(dólares namibios),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira nixeriano),
				'one' => q(naira nixeriano),
				'other' => q(nairas nixerianos),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba nicaragüense),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Córdoba de ouro nicaraguano),
				'one' => q(córdoba de ouro nicaraguano),
				'other' => q(córdobas de ouro nicaraguanos),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Florín holandés),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Coroa norueguesa),
				'one' => q(coroa norueguesa),
				'other' => q(coroas norueguesas),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupias nepalesas),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dólar neozelandés),
				'one' => q(dólar neozelandés),
				'other' => q(dólares neozelandeses),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial omaní),
				'one' => q(rial omaní),
				'other' => q(riais omanís),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa panameño),
				'one' => q(balboa panameño),
				'other' => q(balboas panameños),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Inti peruano),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol peruano),
				'one' => q(sol peruano),
				'other' => q(soles peruanos),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol peruano \(1863–1965\)),
				'one' => q(sol peruano \(1863–1965\)),
				'other' => q(soles peruanos \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina de Papúa-Nova Guinea),
				'one' => q(kina de Papúa-Nova Guinea),
				'other' => q(kinas de Papúa-Nova Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso filipino),
				'one' => q(peso filipino),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia paquistaní),
				'one' => q(rupia paquistaní),
				'other' => q(rupias paquistanís),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty polaco),
				'one' => q(zloty polaco),
				'other' => q(zlotys polacos),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Escudo portugués),
				'one' => q(escudo portugués),
				'other' => q(escudos portugueses),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guaraní paraguaio),
				'one' => q(guaraní paraguaio),
				'other' => q(guaranís paraguaios),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial qatarí),
				'one' => q(rial qatarí),
				'other' => q(riais qatarís),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu romanés),
				'one' => q(leu romanés),
				'other' => q(leus romaneses),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar serbio),
				'one' => q(dinar serbio),
				'other' => q(dinares serbios),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rublo ruso),
				'one' => q(rublo ruso),
				'other' => q(rublos rusos),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rublo ruso \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franco ruandés),
				'one' => q(franco ruandés),
				'other' => q(francos ruandeses),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Rial saudita),
				'one' => q(rial saudita),
				'other' => q(riais sauditas),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dólar das Illas Salomón),
				'one' => q(dólar das Illas Salomón),
				'other' => q(dólares das Illas Salomón),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia de Seixeles),
				'one' => q(rupia de Seixeles),
				'other' => q(rupias de Seixeles),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Libra sudanesa),
				'one' => q(libra sudanesa),
				'other' => q(libras sudanesas),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Coroa sueca),
				'one' => q(coroa sueca),
				'other' => q(coroas suecas),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dólar de Singapur),
				'one' => q(dólar de Singapur),
				'other' => q(dólares de Singapur),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Libra de Santa Helena),
				'one' => q(libra de Santa Helena),
				'other' => q(libras de Santa Helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone de Serra Leoa),
				'one' => q(leone de Serra Leoa),
				'other' => q(leones de Serra Leoa),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Xilin somalí),
				'one' => q(xilin somalí),
				'other' => q(xilins somalíes),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dólar surinamés),
				'one' => q(dólar surinamés),
				'other' => q(dólares surinamés),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Libra sursudanesa),
				'one' => q(libra sursudanesa),
				'other' => q(libras sursudanesa),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
				'one' => q(dobra de São Tomé e Príncipe \(1977–2017\)),
				'other' => q(dobras de São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe),
				'one' => q(dobra de São Tomé e Príncipe),
				'other' => q(dobras de São Tomé e Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Rublo soviético),
				'one' => q(rublo soviético),
				'other' => q(rublos soviéticos),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colón salvadoreño),
				'one' => q(colón salvadoreño),
				'other' => q(colóns salvadoreños),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Libra siria),
				'one' => q(libra siria),
				'other' => q(libras sirias),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni de Suacilandia),
				'one' => q(lilangeni de Suacilandia),
				'other' => q(lilangenis de Suacilandia),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bahts tailandeses),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni taxiquistano),
				'one' => q(somoni taxiquistano),
				'other' => q(somonis taxiquistanos),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat turcomán),
				'one' => q(manat turcomán),
				'other' => q(manats turcománs),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar tunisiano),
				'one' => q(dinar tunisiano),
				'other' => q(dinares tunisianos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga de Tonga),
				'one' => q(paʻanga de Tonga),
				'other' => q(pa’angas de Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira turca),
				'one' => q(lira turca),
				'other' => q(liras turcas),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dólar de Trinidad e Tobago),
				'one' => q(dólar de Trinidad e Tobago),
				'other' => q(dólares de Trinidad e Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Novo dólar taiwanés),
				'one' => q(novo dólar taiwanés),
				'other' => q(novos dólares taiwaneses),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Xilin tanzano),
				'one' => q(xilin tanzano),
				'other' => q(xilins tanzanos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hrivna ucraína),
				'one' => q(hrivna ucraína),
				'other' => q(hrivnas ucraínas),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Xilin ugandés),
				'one' => q(xilin ugandés),
				'other' => q(xilins ugandeses),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dólar estadounidense),
				'one' => q(dólar estadounidense),
				'other' => q(dólares estadounidenses),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Peso en unidades indexadas uruguaio),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso uruguaio \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso uruguaio),
				'one' => q(peso uruguaio),
				'other' => q(pesos uruguaios),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som usbeco),
				'one' => q(som usbeco),
				'other' => q(soms usbecos),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar venezolano \(1871–2008\)),
				'one' => q(bolívar venezolano \(1871–2008\)),
				'other' => q(bolívares venezolanos \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolívar venezolano \(2008–2018\)),
				'one' => q(bolívar venezolano \(2008–2018\)),
				'other' => q(bolívares venezolanos \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolívar venezolano),
				'one' => q(bolívar venezolano),
				'other' => q(bolívares venezolanos),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dongs vietnamitas),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu vanuatiano),
				'one' => q(vatu vanuatiano),
				'other' => q(vatus vanuatianos),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala samoano),
				'one' => q(tala samoano),
				'other' => q(talas samoanos),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Franco CFA \(BEAC\)),
				'one' => q(franco CFA \(BEAC\)),
				'other' => q(francos CFA \(BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Prata),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Ouro),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dólar do Caribe Oriental),
				'one' => q(dólar do Caribe Oriental),
				'other' => q(dólares do Caribe Oriental),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franco CFA \(BCEAO\)),
				'one' => q(franco CFA \(BCEAO\)),
				'other' => q(francos CFA \(BCEAO\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladio),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Franco CFP),
				'one' => q(franco CFP),
				'other' => q(francos CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platino),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moeda descoñecida),
				'one' => q(\(moeda descoñecida\)),
				'other' => q(\(moedas descoñecidas\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial iemení),
				'one' => q(rial iemení),
				'other' => q(riais iemenís),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand surafricano),
				'one' => q(rand surafricano),
				'other' => q(rands surafricanos),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha zambiano \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha zambiano),
				'one' => q(kwacha zambiano),
				'other' => q(kwachas zambianos),
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
							'xan.',
							'feb.',
							'mar.',
							'abr.',
							'maio',
							'xuño',
							'xul.',
							'ago.',
							'set.',
							'out.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'x.',
							'f.',
							'm.',
							'a.',
							'm.',
							'x.',
							'x.',
							'a.',
							's.',
							'o.',
							'n.',
							'd.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'xaneiro',
							'febreiro',
							'marzo',
							'abril',
							'maio',
							'xuño',
							'xullo',
							'agosto',
							'setembro',
							'outubro',
							'novembro',
							'decembro'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Xan.',
							'Feb.',
							'Mar.',
							'Abr.',
							'Maio',
							'Xuño',
							'Xul.',
							'Ago.',
							'Set.',
							'Out.',
							'Nov.',
							'Dec.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'X',
							'F',
							'M',
							'A',
							'M',
							'X',
							'X',
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
							'Xaneiro',
							'Febreiro',
							'Marzo',
							'Abril',
							'Maio',
							'Xuño',
							'Xullo',
							'Agosto',
							'Setembro',
							'Outubro',
							'Novembro',
							'Decembro'
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
						mon => 'luns',
						tue => 'mar.',
						wed => 'mér.',
						thu => 'xov.',
						fri => 'ven.',
						sat => 'sáb.',
						sun => 'dom.'
					},
					narrow => {
						mon => 'l.',
						tue => 'm.',
						wed => 'm.',
						thu => 'x.',
						fri => 'v.',
						sat => 's.',
						sun => 'd.'
					},
					short => {
						mon => 'lu.',
						tue => 'ma.',
						wed => 'mé.',
						thu => 'xo.',
						fri => 've.',
						sat => 'sá.',
						sun => 'do.'
					},
					wide => {
						mon => 'luns',
						tue => 'martes',
						wed => 'mércores',
						thu => 'xoves',
						fri => 'venres',
						sat => 'sábado',
						sun => 'domingo'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Luns',
						tue => 'Mar.',
						wed => 'Mér.',
						thu => 'Xov.',
						fri => 'Ven.',
						sat => 'Sáb.',
						sun => 'Dom.'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'X',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'Lu',
						tue => 'Ma',
						wed => 'Mé',
						thu => 'Xo',
						fri => 'Ve',
						sat => 'Sá',
						sun => 'Do'
					},
					wide => {
						mon => 'Luns',
						tue => 'Martes',
						wed => 'Mércores',
						thu => 'Xoves',
						fri => 'Venres',
						sat => 'Sábado',
						sun => 'Domingo'
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
					wide => {0 => '1.º trimestre',
						1 => '2.º trimestre',
						2 => '3.º trimestre',
						3 => '4.º trimestre'
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
					wide => {0 => '1.º trimestre',
						1 => '2.º trimestre',
						2 => '3.º trimestre',
						3 => '4.º trimestre'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
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
					'afternoon1' => q{do mediodía},
					'am' => q{a.m.},
					'evening1' => q{da tarde},
					'midnight' => q{da noite},
					'morning1' => q{da madrugada},
					'morning2' => q{da mañá},
					'night1' => q{da noite},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{do mediodía},
					'am' => q{a.m.},
					'evening1' => q{da tarde},
					'midnight' => q{da noite},
					'morning1' => q{da madrugada},
					'morning2' => q{da mañá},
					'night1' => q{da noite},
					'pm' => q{p.m.},
				},
				'wide' => {
					'afternoon1' => q{do mediodía},
					'am' => q{a.m.},
					'evening1' => q{da tarde},
					'midnight' => q{da noite},
					'morning1' => q{da madrugada},
					'morning2' => q{da mañá},
					'night1' => q{da noite},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{mediodía},
					'am' => q{a.m.},
					'evening1' => q{tarde},
					'midnight' => q{medianoite},
					'morning1' => q{madrugada},
					'morning2' => q{mañá},
					'night1' => q{noite},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{mediodía},
					'am' => q{a.m.},
					'evening1' => q{tarde},
					'midnight' => q{medianoite},
					'morning1' => q{madrugada},
					'morning2' => q{mañá},
					'night1' => q{noite},
					'pm' => q{p.m.},
				},
				'wide' => {
					'afternoon1' => q{mediodía},
					'am' => q{a.m.},
					'evening1' => q{tarde},
					'midnight' => q{medianoite},
					'morning1' => q{madrugada},
					'morning2' => q{mañá},
					'night1' => q{noite},
					'pm' => q{p.m.},
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
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
			wide => {
				'0' => 'antes de Cristo',
				'1' => 'despois de Cristo'
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
			'full' => q{cccc, d 'de' MMMM 'de' Y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d 'de' MMM 'de' y},
			'short' => q{dd/MM/yy},
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
			'full' => q{{1} 'ás' {0}},
			'long' => q{{1} 'ás' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{0} 'do' {1}},
			'long' => q{{0} 'do' {1}},
			'medium' => q{{0}, {1}},
			'short' => q{{0}, {1}},
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
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{ccc, d 'de' MMM 'de' y G},
			GyMMMd => q{d /MM/y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM 'de' y},
			yMMMEd => q{E, d 'de' MMMM 'de' y},
			yMMMM => q{MMMM 'de' y},
			yMMMd => q{d 'de' MMMM 'de' y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{ccc, M/d/y GGGGG},
			yyyyMMM => q{MMM 'de' y G},
			yyyyMMMEd => q{ccc, d 'de' MMMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d 'de' MMMM 'de' y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMW => q{W.'ª' 'semana' 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM 'de' y},
			yMMMEd => q{EEE, d/MM/y},
			yMMMM => q{MMMM 'de' y},
			yMMMd => q{d/MM/y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{w.'ª' 'semana' 'de' Y},
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
				M => q{MMMM–MMMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d 'de' MMMM – d 'de' MMMM},
				d => q{d–d 'de' MMMM},
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
				M => q{M/y – M/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
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
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d 'de' MMM},
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
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y},
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y},
				d => q{d–d 'de' MMMM 'de' y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{dd/MM/y – dd/MM/y},
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
		regionFormat => q(Horario de: {0}),
		regionFormat => q(Horario de verán de: {0}),
		regionFormat => q(Horario estándar de: {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Horario de Afganistán#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alxer#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamaco#,
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
			exemplarCity => q#O Cairo#,
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
			exemplarCity => q#Djibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#O Aiún#,
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
			exemplarCity => q#Xohanesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartún#,
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
			exemplarCity => q#Lomé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaca#,
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
			exemplarCity => q#Mogadixo#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunes#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Horario de África Central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Horario de África Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Horario estándar de África do Sur#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Horario de verán de África Occidental#,
				'generic' => q#Horario de África Occidental#,
				'standard' => q#Horario estándar de África Occidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Horario de verán de Alasca#,
				'generic' => q#Horario de Alasca#,
				'standard' => q#Horario estándar de Alasca#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Horario de verán do Amazonas#,
				'generic' => q#Horario do Amazonas#,
				'standard' => q#Horario estándar do Amazonas#,
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
			exemplarCity => q#Antiga#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#A Rioxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
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
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
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
			exemplarCity => q#Bogotá#,
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
			exemplarCity => q#Cancún#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caiena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caimán#,
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
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
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
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#O Salvador#,
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
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Güiana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#A Habana#,
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
			exemplarCity => q#Indianápolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Xamaica#,
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
			exemplarCity => q#A Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Os Ánxeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
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
			exemplarCity => q#Martinica#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cidade de México#,
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
			exemplarCity => q#Nova York#,
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
			exemplarCity => q#Beulah, Dacota do Norte#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dacota do Norte#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dacota do Norte#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
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
			exemplarCity => q#Porto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Porto España#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rico#,
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
			exemplarCity => q#Río Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucía#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vicente#,
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
			exemplarCity => q#Tórtola#,
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
				'daylight' => q#Horario de verán central, Norteamérica#,
				'generic' => q#Horario central, Norteamérica#,
				'standard' => q#Horario estándar central, Norteamérica#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Horario de verán do leste, Norteamérica#,
				'generic' => q#Horario do leste, Norteamérica#,
				'standard' => q#Horario estándar do leste, Norteamérica#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Horario de verán da montaña, Norteamérica#,
				'generic' => q#Horario da montaña, Norteamérica#,
				'standard' => q#Horario estándar da montaña, Norteamérica#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Horario de verán do Pacífico, Norteamérica#,
				'generic' => q#Horario do Pacífico, Norteamérica#,
				'standard' => q#Horario estándar do Pacífico, Norteamérica#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Horario de verán de Anadir#,
				'generic' => q#Horario de Anadir#,
				'standard' => q#Horario estándar de Anadir#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urville#,
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
				'daylight' => q#Horario de verán de Apia#,
				'generic' => q#Horario de Apia#,
				'standard' => q#Horario estándar de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Horario de verán árabe#,
				'generic' => q#Horario árabe#,
				'standard' => q#Horario estándar árabe#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Horario de verán da Arxentina#,
				'generic' => q#Horario da Arxentina#,
				'standard' => q#Horario estándar da Arxentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Horario de verán da Arxentina Occidental#,
				'generic' => q#Horario da Arxentina Occidental#,
				'standard' => q#Horario estándar da Arxentina Occidental#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Horario de verán de Armenia#,
				'generic' => q#Horario de Armenia#,
				'standard' => q#Horario estándar de Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adén#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amán#,
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
			exemplarCity => q#Achkhabad#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bacú#,
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
			exemplarCity => q#Calcuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chitá#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
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
			exemplarCity => q#Hebrón#,
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
			exemplarCity => q#Iacarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Xerusalén#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Cabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
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
			exemplarCity => q#Mascate#,
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
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
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
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimbu#,
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
			exemplarCity => q#Iakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Iereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Horario de verán do Atlántico#,
				'generic' => q#Horario do Atlántico#,
				'standard' => q#Horario estándar do Atlántico#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Illas Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reiquiavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Xeorxia do Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
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
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Horario de verán de Australia Central#,
				'generic' => q#Horario de Australia Central#,
				'standard' => q#Horario estándar de Australia Central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Horario de verán de Australia Occidental Central#,
				'generic' => q#Horario de Australia Occidental Central#,
				'standard' => q#Horario estándar de Australia Occidental Central#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Horario de verán de Australia Oriental#,
				'generic' => q#Horario de Australia Oriental#,
				'standard' => q#Horario estándar de Australia Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Horario de verán de Australia Occidental#,
				'generic' => q#Horario de Australia Occidental#,
				'standard' => q#Horario estándar de Australia Occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Horario de verán de Acerbaixán#,
				'generic' => q#Horario de Acerbaixán#,
				'standard' => q#Horario estándar de Acerbaixán#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Horario de verán das Azores#,
				'generic' => q#Horario das Azores#,
				'standard' => q#Horario estándar das Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Horario de verán de Bangladesh#,
				'generic' => q#Horario de Bangladesh#,
				'standard' => q#Horario estándar de Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Horario de Bután#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Horario de Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Horario de verán de Brasilia#,
				'generic' => q#Horario de Brasilia#,
				'standard' => q#Horario estándar de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Horario de Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Horario de verán de Cabo Verde#,
				'generic' => q#Horario de Cabo Verde#,
				'standard' => q#Horario estándar de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Horario estándar chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Horario de verán de Chatham#,
				'generic' => q#Horario de Chatham#,
				'standard' => q#Horario estándar de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Horario de verán de Chile#,
				'generic' => q#Horario de Chile#,
				'standard' => q#Horario estándar de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Horario de verán da China#,
				'generic' => q#Horario da China#,
				'standard' => q#Horario estándar da China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Horario de verán de Choibalsan#,
				'generic' => q#Horario de Choibalsan#,
				'standard' => q#Horario estándar de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Horario da Illa de Nadal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Horario das Illas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Horario de verán de Colombia#,
				'generic' => q#Horario de Colombia#,
				'standard' => q#Horario estándar de Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Horario de verán medio das Illas Cook#,
				'generic' => q#Horario das Illas Cook#,
				'standard' => q#Horario estándar das Illas Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Horario de verán de Cuba#,
				'generic' => q#Horario de Cuba#,
				'standard' => q#Horario estándar de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Horario de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Horario de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Horario de Timor Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Horario de verán da Illa de Pascua#,
				'generic' => q#Horario da Illa de Pascua#,
				'standard' => q#Horario estándar da Illa de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Horario de Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Horario universal coordinado#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Cidade descoñecida#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Ámsterdan#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
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
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublín#,
			long => {
				'daylight' => q#Horario estándar irlandés#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Xibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinqui#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Illa de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Horario de verán británico#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
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
			exemplarCity => q#Mónaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscova#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
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
			exemplarCity => q#Saraxevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferópol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Úzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizhia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Horario de verán de Europa Central#,
				'generic' => q#Horario de Europa Central#,
				'standard' => q#Horario estándar de Europa Central#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Horario de verán de Europa Oriental#,
				'generic' => q#Horario de Europa Oriental#,
				'standard' => q#Horario estándar de Europa Oriental#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Horario do extremo leste europeo#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Horario de verán de Europa Occidental#,
				'generic' => q#Horario de Europa Occidental#,
				'standard' => q#Horario estándar de Europa Occidental#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Horario de verán das Illas Malvinas#,
				'generic' => q#Horario das Illas Malvinas#,
				'standard' => q#Horario estándar das Illas Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Horario de verán de Fidxi#,
				'generic' => q#Horario de Fidxi#,
				'standard' => q#Horario estándar de Fidxi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Horario da Güiana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Horario das Terras Austrais e Antárticas Francesas#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Horario do meridiano de Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Horario das Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Horario de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Horario de verán de Xeorxia#,
				'generic' => q#Horario de Xeorxia#,
				'standard' => q#Horario estándar de Xeorxia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Horario das Illas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Horario de verán de Groenlandia Oriental#,
				'generic' => q#Horario de Groenlandia Oriental#,
				'standard' => q#Horario estándar de Groenlandia Oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Horario de verán de Groenlandia Occidental#,
				'generic' => q#Horario de Groenlandia Occidental#,
				'standard' => q#Horario estándar de Groenlandia Occidental#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Horario estándar do Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Horario da Güiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Horario de verán de Hawai-Aleutiano#,
				'generic' => q#Horario de Hawai-Aleutiano#,
				'standard' => q#Horario estándar de Hawai-Aleutiano#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Horario de verán de Hong Kong#,
				'generic' => q#Horario de Hong Kong#,
				'standard' => q#Horario estándar de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Horario de verán de Hovd#,
				'generic' => q#Horario de Hovd#,
				'standard' => q#Horario estándar de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Horario estándar da India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Illa de Nadal#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Illas Comores#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunión#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Horario do Océano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Horario de Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Horario de Indonesia Central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Horario de Indonesia Oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Horario de Indonesia Occidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Horario de verán de Irán#,
				'generic' => q#Horario de Irán#,
				'standard' => q#Horario estándar de Irán#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Horario de verán de Irkutsk#,
				'generic' => q#Horario de Irkutsk#,
				'standard' => q#Horario estándar de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Horario de verán de Israel#,
				'generic' => q#Horario de Israel#,
				'standard' => q#Horario estándar de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Horario de verán do Xapón#,
				'generic' => q#Horario do Xapón#,
				'standard' => q#Horario estándar do Xapón#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Horario de verán de Petropávlovsk-Kamchatski#,
				'generic' => q#Horario de Petropávlovsk-Kamchatski#,
				'standard' => q#Horario estándar de Petropávlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Horario de Casaquistán Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Horario de Casaquistán Occidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Horario de verán de Corea#,
				'generic' => q#Horario de Corea#,
				'standard' => q#Horario estándar de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Horario de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Horario de verán de Krasnoyarsk#,
				'generic' => q#Horario de Krasnoyarsk#,
				'standard' => q#Horario estándar de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Horario de Kirguizistán#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Horario das Illas da Liña#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Horario de verán de Lord Howe#,
				'generic' => q#Horario de Lord Howe#,
				'standard' => q#Horario estándar de Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Horario da Illa Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Horario de verán de Magadan#,
				'generic' => q#Horario de Magadan#,
				'standard' => q#Horario estándar de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Horario de Malaisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Horario das Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Horario das Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Horario das Illas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Horario de verán de Mauricio#,
				'generic' => q#Horario de Mauricio#,
				'standard' => q#Horario estándar de Mauricio#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Horario de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Horario de verán do noroeste de México#,
				'generic' => q#Horario do noroeste de México#,
				'standard' => q#Horario estándar do noroeste de México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Horario de verán do Pacífico mexicano#,
				'generic' => q#Horario do Pacífico mexicano#,
				'standard' => q#Horario estándar do Pacífico mexicano#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Horario de verán de Ulaanbaatar#,
				'generic' => q#Horario de Ulaanbaatar#,
				'standard' => q#Horario estándar de Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Horario de verán de Moscova#,
				'generic' => q#Horario de Moscova#,
				'standard' => q#Horario estándar de Moscova#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Horario de Birmania#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Horario de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Horario de Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Horario de verán de Nova Caledonia#,
				'generic' => q#Horario de Nova Caledonia#,
				'standard' => q#Horario estándar de Nova Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Horario de verán de Nova Zelandia#,
				'generic' => q#Horario de Nova Zelandia#,
				'standard' => q#Horario estándar de Nova Zelandia#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Horario de verán de Terranova#,
				'generic' => q#Horario de Terranova#,
				'standard' => q#Horario estándar de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Horario de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Horario das Illas Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Horario de verán de Fernando de Noronha#,
				'generic' => q#Horario de Fernando de Noronha#,
				'standard' => q#Horario estándar de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Horario de verán de Novosibirsk#,
				'generic' => q#Horario de Novosibirsk#,
				'standard' => q#Horario estándar de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Horario de verán de Omsk#,
				'generic' => q#Horario de Omsk#,
				'standard' => q#Horario estándar de Omsk#,
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
			exemplarCity => q#Illa de Pascua#,
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
			exemplarCity => q#Fidxi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Illas Galápagos#,
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
			exemplarCity => q#Honolulú#,
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
			exemplarCity => q#Tahití#,
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
				'daylight' => q#Horario de verán de Paquistán#,
				'generic' => q#Horario de Paquistán#,
				'standard' => q#Horario estándar de Paquistán#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Horario de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Horario de Papúa-Nova Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Horario de verán de Paraguai#,
				'generic' => q#Horario de Paraguai#,
				'standard' => q#Horario estándar de Paraguai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Horario de verán do Perú#,
				'generic' => q#Horario do Perú#,
				'standard' => q#Horario estándar do Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Horario de verán de Filipinas#,
				'generic' => q#Horario de Filipinas#,
				'standard' => q#Horario estándar de Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Horario das Illas Fénix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Horario de verán de Saint Pierre et Miquelon#,
				'generic' => q#Horario de Saint Pierre et Miquelon#,
				'standard' => q#Horario estándar de Saint Pierre et Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Horario de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Horario de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Horario de Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Horario de Reunión#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Horario de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Horario de verán de Sakhalin#,
				'generic' => q#Horario de Sakhalin#,
				'standard' => q#Horario estándar de Sakhalín#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Horario de verán de Samara#,
				'generic' => q#Horario de Samara#,
				'standard' => q#Horario estándar de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Horario de verán de Samoa#,
				'generic' => q#Horario de Samoa#,
				'standard' => q#Horario estándar de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Horario das Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Horario estándar de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Horario das Illas Salomón#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Horario de Xeorxia do Sur#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Horario de Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Horario de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Horario de Tahití#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Horario de verán de Taipei#,
				'generic' => q#Horario de Taipei#,
				'standard' => q#Horario estándar de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Horario de Taxiquistán#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Horario de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Horario de verán de Tonga#,
				'generic' => q#Horario de Tonga#,
				'standard' => q#Horario estándar de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Horario de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Horario de verán de Turcomenistán#,
				'generic' => q#Horario de Turcomenistán#,
				'standard' => q#Horario estándar de Turcomenistán#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Horario de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Horario de verán do Uruguai#,
				'generic' => q#Horario do Uruguai#,
				'standard' => q#Horario estándar do Uruguai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Horario de verán de Uzbequistán#,
				'generic' => q#Horario de Uzbequistán#,
				'standard' => q#Horario estándar de Uzbequistán#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Horario de verán de Vanuatu#,
				'generic' => q#Horario de Vanuatu#,
				'standard' => q#Horario estándar de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Horario de Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Horario de verán de Vladivostok#,
				'generic' => q#Horario de Vladivostok#,
				'standard' => q#Horario estándar de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Horario de verán de Volgogrado#,
				'generic' => q#Horario de Volgogrado#,
				'standard' => q#Horario estándar de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Horario de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Horario da Illa Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Horario de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Horario de verán de Iakutsk#,
				'generic' => q#Horario de Iakutsk#,
				'standard' => q#Horario estándar de Iakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Horario de verán de Ekaterimburgo#,
				'generic' => q#Horario de Ekaterimburgo#,
				'standard' => q#Horario estándar de Ekaterimburgo#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
