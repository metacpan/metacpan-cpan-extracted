=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gl - Package for language Galician

=cut

package Locale::CLDR::Locales::Gl;
# This file auto generated from Data\common\main\gl.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
 				'be' => 'belaruso',
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
 				'ccp' => 'chakma',
 				'ce' => 'checheno',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'chamorro',
 				'chk' => 'chuuk',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdo central',
 				'ckb@alt=variant' => 'sorani',
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
 				'doi' => 'dogri',
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
 				'en_US' => 'inglés estadounidense',
 				'eo' => 'esperanto',
 				'es' => 'español',
 				'es_419' => 'español de América',
 				'es_ES' => 'español de España',
 				'es_MX' => 'español de México',
 				'et' => 'estoniano',
 				'eu' => 'éuscaro',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'fa_AF' => 'dari',
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
 				'kk' => 'kazako',
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
 				'ny' => 'chewa',
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
 				'rhg' => 'rohingya',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romanés',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
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
 				'tk' => 'turkmeno',
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
 				'uz' => 'uzbeko',
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
 				'yue@alt=menu' => 'chinés cantonés',
 				'zgh' => 'tamazight marroquí estándar',
 				'zh' => 'chinés',
 				'zh@alt=menu' => 'chinés mandarín',
 				'zh_Hans' => 'chinés simplificado',
 				'zh_Hans@alt=long' => 'chinés mandarín simplificado',
 				'zh_Hant' => 'chinés tradicional',
 				'zh_Hant@alt=long' => 'chinés mandarín tradicional',
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
 			'Gujr' => 'guxarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han con bopomofo',
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
 			'Knda' => 'kannará',
 			'Kore' => 'coreano',
 			'Laoo' => 'laosiano',
 			'Latn' => 'latino',
 			'Mlym' => 'malabar',
 			'Mong' => 'mongol',
 			'Mymr' => 'birmano',
 			'Orya' => 'odiá',
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
 			'Zzzz' => 'sistema de escritura descoñecido',

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
 			'003' => 'América do Norte',
 			'005' => 'América do Sur',
 			'009' => 'Oceanía',
 			'011' => 'África Occidental',
 			'013' => 'América Central',
 			'014' => 'África Oriental',
 			'015' => 'África Setentrional',
 			'017' => 'África Central',
 			'018' => 'África Meridional',
 			'019' => 'América',
 			'021' => 'América Setentrional',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia Meridional',
 			'035' => 'Sueste Asiático',
 			'039' => 'Europa Meridional',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Rexión de Micronesia',
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
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Costa do Marfil',
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
 			'KZ' => 'Kazakistán',
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
 			'MK' => 'Macedonia do Norte',
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
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazilandia',
 			'TA' => 'Tristán da Cunha',
 			'TC' => 'Illas Turks e Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Austrais Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Taxiquistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
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
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Cidade do Vaticano',
 			'VC' => 'San Vicente e As Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Illas Virxes Británicas',
 			'VI' => 'Illas Virxes Estadounidenses',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudoacentos',
 			'XB' => 'Pseudobidireccional',
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
 			'colalternate' => 'ignorar ordenación de símbolos',
 			'colbackwards' => 'ordenación de acentos invertida',
 			'colcasefirst' => 'orde de maiúsculas/minúsculas',
 			'colcaselevel' => 'ordenación que distingue entre maiúsculas e minúsculas',
 			'collation' => 'criterio de ordenación',
 			'colnormalization' => 'ordenación normalizada',
 			'colnumeric' => 'ordenación numérica',
 			'colstrength' => 'forza de ordenación',
 			'currency' => 'moeda',
 			'hc' => 'ciclo horario (12 ou 24)',
 			'lb' => 'estilo de quebra de liña',
 			'ms' => 'sistema internacional de unidades',
 			'numbers' => 'números',
 			'timezone' => 'fuso horario',
 			'va' => 'variante rexional',
 			'x' => 'uso privado',

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
 				'loose' => q{estilo de quebra de liña flexible},
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
 				'arab' => q{díxitos indoarábigos},
 				'arabext' => q{díxitos indoarábigos ampliados},
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
 				'gujr' => q{díxitos guxaratis},
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
 				'knda' => q{díxitos kannarás},
 				'laoo' => q{díxitos laosianos},
 				'latn' => q{díxitos occidentais},
 				'mlym' => q{díxitos malabares},
 				'mong' => q{Díxitos mongoles},
 				'mymr' => q{díxitos birmanos},
 				'native' => q{Díxitos orixinais},
 				'orya' => q{díxitos do odiá},
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
 			'script' => 'Sistema de escritura: {0}',
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
			auxiliary => qr{[ª à ă â å ä ã ā æ ɑ ç è ĕ ê ë ē ì ĭ î ī º ò ŏ ô ö õ ø ō œ ù ŭ û ū]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á b c d e é f g h i í ï j k l m n ñ o ó p q r s t u ú ü v w x y z]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ¡ ? ¿ . … ' ‘ ’ " “ ” « » ( ) \[ \] § @ * / \\ \& # † ‡ ′ ″]},
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
					# Long Unit Identifier
					'' => {
						'name' => q(punto cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto cardinal),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(quibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(quibi{0}),
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
						'1' => q(xibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(xibi{0}),
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
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
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
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(fento{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(fento{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
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
						'1' => q(iocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(iocto{0}),
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
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
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
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
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
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
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
						'1' => q(xiga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(xiga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forzas G),
						'one' => q({0} forza G),
						'other' => q({0} forzas G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forzas G),
						'one' => q({0} forza G),
						'other' => q({0} forzas G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros por segundo cadrado),
						'one' => q({0} metro por segundo cadrado),
						'other' => q({0} metros por segundo cadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros por segundo cadrado),
						'one' => q({0} metro por segundo cadrado),
						'other' => q({0} metros por segundo cadrado),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiáns),
						'one' => q({0} radián),
						'other' => q({0} radiáns),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiáns),
						'one' => q({0} radián),
						'other' => q({0} radiáns),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolucións),
						'one' => q({0} revolución),
						'other' => q({0} revolucións),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolucións),
						'one' => q({0} revolución),
						'other' => q({0} revolucións),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} hectárea),
						'other' => q({0} hectáreas),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} hectárea),
						'other' => q({0} hectáreas),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centímetros cadrados),
						'one' => q({0} centímetro cadrado),
						'other' => q({0} centímetros cadrados),
						'per' => q({0} por centímetro cadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centímetros cadrados),
						'one' => q({0} centímetro cadrado),
						'other' => q({0} centímetros cadrados),
						'per' => q({0} por centímetro cadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pés cadrados),
						'one' => q({0} pé cadrado),
						'other' => q({0} pés cadrados),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pés cadrados),
						'one' => q({0} pé cadrado),
						'other' => q({0} pés cadrados),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(polgadas cadradas),
						'one' => q({0} polgada cadrada),
						'other' => q({0} polgadas cadradas),
						'per' => q({0} por polgada cadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(polgadas cadradas),
						'one' => q({0} polgada cadrada),
						'other' => q({0} polgadas cadradas),
						'per' => q({0} por polgada cadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(quilómetros cadrados),
						'one' => q({0} quilómetro cadrado),
						'other' => q({0} quilómetros cadrados),
						'per' => q({0} por quilómetro cadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(quilómetros cadrados),
						'one' => q({0} quilómetro cadrado),
						'other' => q({0} quilómetros cadrados),
						'per' => q({0} por quilómetro cadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metros cadrados),
						'one' => q({0} metro cadrado),
						'other' => q({0} metros cadrados),
						'per' => q({0} por metro cadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metros cadrados),
						'one' => q({0} metro cadrado),
						'other' => q({0} metros cadrados),
						'per' => q({0} por metro cadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(millas cadradas),
						'one' => q({0} milla cadrada),
						'other' => q({0} millas cadradas),
						'per' => q({0} por milla cadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(millas cadradas),
						'one' => q({0} milla cadrada),
						'other' => q({0} millas cadradas),
						'per' => q({0} por milla cadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iardas cadradas),
						'one' => q({0} iarda cadrada),
						'other' => q({0} iardas cadradas),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iardas cadradas),
						'one' => q({0} iarda cadrada),
						'other' => q({0} iardas cadradas),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(unidades),
						'one' => q({0} unidade),
						'other' => q({0} unidades),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(unidades),
						'one' => q({0} unidade),
						'other' => q({0} unidades),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
						'one' => q({0} miligramo por decilitro),
						'other' => q({0} miligramos por decilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
						'one' => q({0} miligramo por decilitro),
						'other' => q({0} miligramos por decilitro),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimoles por litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimoles por litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moles),
						'one' => q({0} mol),
						'other' => q({0} moles),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moles),
						'one' => q({0} mol),
						'other' => q({0} moles),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(tanto por cento),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(tanto por cento),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(tanto por mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(tanto por mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes por millón),
						'one' => q({0} parte por millón),
						'other' => q({0} partes por millón),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes por millón),
						'one' => q({0} parte por millón),
						'other' => q({0} partes por millón),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(tanto por dez mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(tanto por dez mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(millas por galón estadounidense),
						'one' => q({0} milla por galón estadounidense),
						'other' => q({0} millas por galón estadounidense),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(millas por galón estadounidense),
						'one' => q({0} milla por galón estadounidense),
						'other' => q({0} millas por galón estadounidense),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(millas por galón imperial),
						'one' => q({0} milla por galón imperial),
						'other' => q({0} millas por galón imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(millas por galón imperial),
						'one' => q({0} milla por galón imperial),
						'other' => q({0} millas por galón imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} leste),
						'north' => q({0} norte),
						'south' => q({0} sur),
						'west' => q({0} oeste),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} leste),
						'north' => q({0} norte),
						'south' => q({0} sur),
						'west' => q({0} oeste),
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
						'name' => q(xigabits),
						'one' => q({0} xigabit),
						'other' => q({0} xigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(xigabits),
						'one' => q({0} xigabit),
						'other' => q({0} xigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(xigabytes),
						'one' => q({0} xigabyte),
						'other' => q({0} xigabytes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(xigabytes),
						'one' => q({0} xigabyte),
						'other' => q({0} xigabytes),
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
					'duration-century' => {
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0} por día),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0} por día),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(décadas),
						'one' => q({0} década),
						'other' => q({0} décadas),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(décadas),
						'one' => q({0} década),
						'other' => q({0} décadas),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundo),
						'other' => q({0} microsegundos),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundo),
						'other' => q({0} microsegundos),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundos),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundos),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} por mes),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} por mes),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundos),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundos),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0} por ano),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0} por ano),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unidades térmicas británicas),
						'one' => q({0} unidade térmica británica),
						'other' => q({0} unidades térmicas británicas),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unidades térmicas británicas),
						'one' => q({0} unidade térmica británica),
						'other' => q({0} unidades térmicas británicas),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calorías),
						'one' => q({0} caloría),
						'other' => q({0} calorías),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calorías),
						'one' => q({0} caloría),
						'other' => q({0} calorías),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvolts),
						'one' => q({0} electronvolt),
						'other' => q({0} electronvolts),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvolts),
						'one' => q({0} electronvolt),
						'other' => q({0} electronvolts),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(quilocalorías),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocalorías),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(quilowatts hora),
						'one' => q({0} quilowatt hora),
						'other' => q({0} quilowatts hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(quilowatts hora),
						'one' => q({0} quilowatt hora),
						'other' => q({0} quilowatts hora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therms estadounidenses),
						'one' => q({0} therm estadounidense),
						'other' => q({0} therms estadounidenses),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therms estadounidenses),
						'one' => q({0} therm estadounidense),
						'other' => q({0} therms estadounidenses),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(quilowatts/hora por cen quilómetros),
						'one' => q({0} quilowatt/hora por cen quilómetros),
						'other' => q({0} quilowatts/hora por cen quilómetros),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(quilowatts/hora por cen quilómetros),
						'one' => q({0} quilowatt/hora por cen quilómetros),
						'other' => q({0} quilowatts/hora por cen quilómetros),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libras de forza),
						'one' => q({0} libra de forza),
						'other' => q({0} libras de forza),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libras de forza),
						'one' => q({0} libra de forza),
						'other' => q({0} libras de forza),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(xigahertzs),
						'one' => q({0} xigahertz),
						'other' => q({0} xigahertzs),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(xigahertzs),
						'one' => q({0} xigahertz),
						'other' => q({0} xigahertzs),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertzs),
						'one' => q({0} hertz),
						'other' => q({0} hertzs),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertzs),
						'one' => q({0} hertz),
						'other' => q({0} hertzs),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(quilohertzs),
						'one' => q({0} quilohertz),
						'other' => q({0} quilohertzs),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(quilohertzs),
						'one' => q({0} quilohertz),
						'other' => q({0} quilohertzs),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertzs),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzs),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertzs),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzs),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntos),
						'one' => q({0} punto),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntos),
						'one' => q({0} punto),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'one' => q({0} punto por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'one' => q({0} punto por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntos por polgada),
						'one' => q({0} punto por polgada),
						'other' => q({0} puntos por polgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntos por polgada),
						'one' => q({0} punto por polgada),
						'other' => q({0} puntos por polgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(cuadratíns),
						'one' => q({0} cuadratín),
						'other' => q({0} cuadratíns),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(cuadratíns),
						'one' => q({0} cuadratín),
						'other' => q({0} cuadratíns),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapíxeles),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeles),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapíxeles),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeles),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(píxeles),
						'one' => q({0} píxel),
						'other' => q({0} píxeles),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(píxeles),
						'one' => q({0} píxel),
						'other' => q({0} píxeles),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(píxeles por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeles por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(píxeles por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeles por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(píxeles por polgada),
						'one' => q({0} píxel por polgada),
						'other' => q({0} píxeles por polgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(píxeles por polgada),
						'one' => q({0} píxel por polgada),
						'other' => q({0} píxeles por polgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raio terrestre),
						'one' => q({0} raio terrestre),
						'other' => q({0} raios terrestres),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raio terrestre),
						'one' => q({0} raio terrestre),
						'other' => q({0} raios terrestres),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(brazas inglesas),
						'one' => q({0} braza inglesa),
						'other' => q({0} brazas inglesas),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(brazas inglesas),
						'one' => q({0} braza inglesa),
						'other' => q({0} brazas inglesas),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(polgadas),
						'one' => q({0} polgada),
						'other' => q({0} polgadas),
						'per' => q({0} por polgada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(polgadas),
						'one' => q({0} polgada),
						'other' => q({0} polgadas),
						'per' => q({0} por polgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anos luz),
						'one' => q({0} ano luz),
						'other' => q({0} anos luz),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anos luz),
						'one' => q({0} ano luz),
						'other' => q({0} anos luz),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(millas),
						'one' => q({0} milla),
						'other' => q({0} millas),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(millas),
						'one' => q({0} milla),
						'other' => q({0} millas),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milla escandinava),
						'one' => q({0} milla escandinava),
						'other' => q({0} millas escandinavas),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
						'one' => q({0} milla escandinava),
						'other' => q({0} millas escandinavas),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas náuticas),
						'one' => q({0} milla náutica),
						'other' => q({0} millas náuticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas náuticas),
						'one' => q({0} milla náutica),
						'other' => q({0} millas náuticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos tipográficos),
						'one' => q({0} punto tipográfico),
						'other' => q({0} puntos tipográficos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos tipográficos),
						'one' => q({0} punto tipográfico),
						'other' => q({0} puntos tipográficos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raios solares),
						'one' => q({0} raio solar),
						'other' => q({0} raios solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raios solares),
						'one' => q({0} raio solar),
						'other' => q({0} raios solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iardas),
						'one' => q({0} iarda),
						'other' => q({0} iardas),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iardas),
						'one' => q({0} iarda),
						'other' => q({0} iardas),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminosidades solares),
						'one' => q({0} luminosidade solar),
						'other' => q({0} luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminosidades solares),
						'one' => q({0} luminosidade solar),
						'other' => q({0} luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masas da Terra),
						'one' => q({0} masa da Terra),
						'other' => q({0} masas da Terra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masas da Terra),
						'one' => q({0} masa da Terra),
						'other' => q({0} masas da Terra),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} grans),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} grans),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} por gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} por gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(quilogramos),
						'one' => q({0} quilogramo),
						'other' => q({0} quilogramos),
						'per' => q({0} por quilogramo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(quilogramos),
						'one' => q({0} quilogramo),
						'other' => q({0} quilogramos),
						'per' => q({0} por quilogramo),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramo),
						'other' => q({0} microgramos),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramo),
						'other' => q({0} microgramos),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramos),
						'one' => q({0} miligramo),
						'other' => q({0} miligramos),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramos),
						'one' => q({0} miligramo),
						'other' => q({0} miligramos),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(onzas),
						'one' => q({0} onza),
						'other' => q({0} onzas),
						'per' => q({0} por onza),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(onzas),
						'one' => q({0} onza),
						'other' => q({0} onzas),
						'per' => q({0} por onza),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onzas troy),
						'one' => q({0} onza troy),
						'other' => q({0} onzas troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onzas troy),
						'one' => q({0} onza troy),
						'other' => q({0} onzas troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masas solares),
						'one' => q({0} masa solar),
						'other' => q({0} masas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masas solares),
						'one' => q({0} masa solar),
						'other' => q({0} masas solares),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(toneladas estadounidenses),
						'one' => q({0} tonelada estadounidense),
						'other' => q({0} toneladas estadounidenses),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(toneladas estadounidenses),
						'one' => q({0} tonelada estadounidense),
						'other' => q({0} toneladas estadounidenses),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(xigawatts),
						'one' => q({0} xigawatt),
						'other' => q({0} xigawatts),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(xigawatts),
						'one' => q({0} xigawatt),
						'other' => q({0} xigawatts),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cabalo de potencia),
						'one' => q({0} cabalo de potencia),
						'other' => q({0} cabalos de potencia),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cabalo de potencia),
						'one' => q({0} cabalo de potencia),
						'other' => q({0} cabalos de potencia),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} cadrado),
						'one' => q({0} cadrado),
						'other' => q({0} cadrados),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} cadrado),
						'one' => q({0} cadrado),
						'other' => q({0} cadrados),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} cúbico),
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} cúbico),
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosferas),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferas),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosferas),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferas),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bares),
						'one' => q({0} bar),
						'other' => q({0} bares),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bares),
						'one' => q({0} bar),
						'other' => q({0} bares),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(polgadas de mercurio),
						'one' => q({0} polgada de mercurio),
						'other' => q({0} polgadas de mercurio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(polgadas de mercurio),
						'one' => q({0} polgada de mercurio),
						'other' => q({0} polgadas de mercurio),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(quilopascais),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascais),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(quilopascais),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascais),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascais),
						'one' => q({0} megapascal),
						'other' => q({0} megapascais),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascais),
						'one' => q({0} megapascal),
						'other' => q({0} megapascais),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milímetros de mercurio),
						'one' => q({0} milímetro de mercurio),
						'other' => q({0} milímetros de mercurio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milímetros de mercurio),
						'one' => q({0} milímetro de mercurio),
						'other' => q({0} milímetros de mercurio),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascais),
						'one' => q({0} pascal),
						'other' => q({0} pascais),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascais),
						'one' => q({0} pascal),
						'other' => q({0} pascais),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libras por polgada cadrada),
						'one' => q({0} libra por polgada cadrada),
						'other' => q({0} libras por polgada cadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libras por polgada cadrada),
						'one' => q({0} libra por polgada cadrada),
						'other' => q({0} libras por polgada cadrada),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nós),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nós),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(millas por hora),
						'one' => q({0} milla por hora),
						'other' => q({0} millas por hora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(millas por hora),
						'one' => q({0} milla por hora),
						'other' => q({0} millas por hora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(graos Celsius),
						'one' => q({0} grao Celsius),
						'other' => q({0} graos Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graos Celsius),
						'one' => q({0} grao Celsius),
						'other' => q({0} graos Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graos Fahrenheit),
						'one' => q({0} grao Fahrenheit),
						'other' => q({0} graos Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graos Fahrenheit),
						'one' => q({0} grao Fahrenheit),
						'other' => q({0} graos Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(graos),
						'one' => q({0} grao),
						'other' => q({0} graos),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtons metro),
						'one' => q({0} newton metro),
						'other' => q({0} newtons metro),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtons metro),
						'one' => q({0} newton metro),
						'other' => q({0} newtons metro),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libras pés),
						'one' => q({0} libra pé),
						'other' => q({0} libras pés),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libras pés),
						'one' => q({0} libra pé),
						'other' => q({0} libras pés),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrís),
						'one' => q({0} barril),
						'other' => q({0} barrís),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrís),
						'one' => q({0} barril),
						'other' => q({0} barrís),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(polgadas cúbicas),
						'one' => q({0} polgada cúbica),
						'other' => q({0} polgadas cúbicas),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(polgadas cúbicas),
						'one' => q({0} polgada cúbica),
						'other' => q({0} polgadas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(millas cúbicas),
						'one' => q({0} milla cúbica),
						'other' => q({0} millas cúbicas),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(millas cúbicas),
						'one' => q({0} milla cúbica),
						'other' => q({0} millas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iardas cúbicas),
						'one' => q({0} iarda cúbica),
						'other' => q({0} iardas cúbicas),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iardas cúbicas),
						'one' => q({0} iarda cúbica),
						'other' => q({0} iardas cúbicas),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cuncas),
						'one' => q({0} cunca),
						'other' => q({0} cuncas),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cuncas),
						'one' => q({0} cunca),
						'other' => q({0} cuncas),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cuncas métricas),
						'one' => q({0} cunca métrica),
						'other' => q({0} cuncas métricas),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cuncas métricas),
						'one' => q({0} cunca métrica),
						'other' => q({0} cuncas métricas),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cullerada de sobremesa),
						'one' => q({0} cullerada de sobremesa),
						'other' => q({0} culleradas de sobremesa),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cullerada de sobremesa),
						'one' => q({0} cullerada de sobremesa),
						'other' => q({0} culleradas de sobremesa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cullerada de sobremesa imperial),
						'one' => q({0} cullerada de sobremesa imperial),
						'other' => q({0} culleradas de sobremesa imperiais),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cullerada de sobremesa imperial),
						'one' => q({0} cullerada de sobremesa imperial),
						'other' => q({0} culleradas de sobremesa imperiais),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma líquida),
						'one' => q({0} dracma líquida),
						'other' => q({0} dracmas líquidas),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma líquida),
						'one' => q({0} dracma líquida),
						'other' => q({0} dracmas líquidas),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(onzas líquidas imperiais),
						'one' => q({0} onza líquida imperial),
						'other' => q({0} onzas líquidas imperiais),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(onzas líquidas imperiais),
						'one' => q({0} onza líquida imperial),
						'other' => q({0} onzas líquidas imperiais),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galóns estadounidenses),
						'one' => q({0} galón estadounidense),
						'other' => q({0} galóns estadounidenses),
						'per' => q({0} por galón estadounidense),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galóns estadounidenses),
						'one' => q({0} galón estadounidense),
						'other' => q({0} galóns estadounidenses),
						'per' => q({0} por galón estadounidense),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galóns imperiais),
						'one' => q({0} galón imperial),
						'other' => q({0} galóns imperiais),
						'per' => q({0} por galón imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galóns imperiais),
						'one' => q({0} galón imperial),
						'other' => q({0} galóns imperiais),
						'per' => q({0} por galón imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medidor de cóctel),
						'one' => q({0} medidor de cóctel),
						'other' => q({0} medidores de cóctel),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medidor de cóctel),
						'one' => q({0} medidor de cóctel),
						'other' => q({0} medidores de cóctel),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(chisco),
						'one' => q({0} chisco),
						'other' => q({0} chiscos),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(chisco),
						'one' => q({0} chisco),
						'other' => q({0} chiscos),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintas),
						'one' => q({0} pinta),
						'other' => q({0} pintas),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintas),
						'one' => q({0} pinta),
						'other' => q({0} pintas),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pintas métricas),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintas métricas),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pintas métricas),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintas métricas),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuarto),
						'other' => q({0} cuartos),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuarto),
						'other' => q({0} cuartos),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(cuarto imperial),
						'one' => q({0} cuarto imperial),
						'other' => q({0} cuartos imperiais),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(cuarto imperial),
						'one' => q({0} cuarto imperial),
						'other' => q({0} cuartos imperiais),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(culleradas),
						'one' => q({0} cullerada),
						'other' => q({0} culleradas),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(culleradas),
						'one' => q({0} cullerada),
						'other' => q({0} culleradas),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(culleradiñas),
						'one' => q({0} culleradiña),
						'other' => q({0} culleradiñas),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(culleradiñas),
						'one' => q({0} culleradiña),
						'other' => q({0} culleradiñas),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(d{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(d{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(f{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(f{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(a{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(a{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(c{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(c{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(z{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(y{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(min),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(min),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(s),
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
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ude.),
						'one' => q({0} ude.),
						'other' => q({0} udes.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ude.),
						'one' => q({0} ude.),
						'other' => q({0} udes.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg EUA),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg EUA),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(día),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(día),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mes),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mes),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a.),
						'one' => q({0} a.),
						'other' => q({0} a.),
						'per' => q({0}/a.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a.),
						'one' => q({0} a.),
						'other' => q({0} a.),
						'per' => q({0}/a.),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
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
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(a.l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(a.l.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
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
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
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
					'light-candela' => {
						'one' => q({0} cd),
						'other' => q({0} cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0} cd),
						'other' => q({0} cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ct),
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
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
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
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
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
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
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
					'volume-quart' => {
						'name' => q(qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(cto. imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(cto. imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(d{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(d{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(f{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(f{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(a{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(a{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(c{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(c{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(z{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(y{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forzas G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forzas G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minutos),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutos),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segundos),
						'one' => q({0}′′),
						'other' => q({0}′′),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segundos),
						'one' => q({0}′′),
						'other' => q({0}′′),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiáns),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiáns),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectáreas),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ude.),
						'one' => q({0} ude.),
						'other' => q({0} udes.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ude.),
						'one' => q({0} ude.),
						'other' => q({0} udes.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(quilates),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(millas/galón EUA),
						'one' => q({0} mpg EUA),
						'other' => q({0} mpg EUA),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(millas/galón EUA),
						'one' => q({0} mpg EUA),
						'other' => q({0} mpg EUA),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(millas/gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(millas/gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} séc.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} séc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/día),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/día),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(déc.),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(déc.),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0}/mes),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0}/mes),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(quilojoule),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(quilojoule),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm U.S.),
						'one' => q({0} thm U.S.),
						'other' => q({0} thm U.S.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm U.S.),
						'one' => q({0} thm U.S.),
						'other' => q({0} thm U.S.),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
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
						'name' => q(libra forza),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra forza),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ptos.),
						'one' => q({0} ptos.),
						'other' => q({0} ptos.),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ptos.),
						'one' => q({0} ptos.),
						'other' => q({0} ptos.),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ppp),
						'one' => q({0} ppp),
						'other' => q({0} ppp),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ppp),
						'one' => q({0} ppp),
						'other' => q({0} ppp),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(brazas inglesas),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(brazas inglesas),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pés),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pés),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(polg.),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(polg.),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anos luz),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anos luz),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(millas),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(millas),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mi esc.),
						'one' => q({0} mi esc.),
						'other' => q({0} mi esc.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mi esc.),
						'one' => q({0} mi esc.),
						'other' => q({0} mi esc.),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raios solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raios solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iardas),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iardas),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quilates),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masas da Terra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masas da Terra),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} grans),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} grans),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramos),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramos),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libras),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libras),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masas solares),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn EUA),
						'one' => q({0} tn EUA),
						'other' => q({0} tn EUA),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn EUA),
						'one' => q({0} tn EUA),
						'other' => q({0} tn EUA),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nós),
						'one' => q({0} nós),
						'other' => q({0} nós),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nós),
						'one' => q({0} nós),
						'other' => q({0} nós),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(millas/hora),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(millas/hora),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(N⋅m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N⋅m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf ft),
						'one' => q({0} lbf ft),
						'other' => q({0} lbf ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf ft),
						'one' => q({0} lbf ft),
						'other' => q({0} lbf ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barril),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cuncas),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cuncas),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cuncas métr.),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cuncas métr.),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cull. sobr.),
						'one' => q({0} cull. sobr.),
						'other' => q({0} cull. sobr.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cull. sobr.),
						'one' => q({0} cull. sobr.),
						'other' => q({0} cull. sobr.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cull. sobr. imp.),
						'one' => q({0} cull. sobr. imp.),
						'other' => q({0} cull. sobr. imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cull. sobr. imp.),
						'one' => q({0} cull. sobr. imp.),
						'other' => q({0} cull. sobr. imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma),
						'one' => q({0} dracma),
						'other' => q({0} dracmas),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma),
						'one' => q({0} dracma),
						'other' => q({0} dracmas),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal EUA),
						'one' => q({0} gal EUA),
						'other' => q({0} gal EUA),
						'per' => q({0}/gal EUA),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal EUA),
						'one' => q({0} gal EUA),
						'other' => q({0} gal EUA),
						'per' => q({0}/gal EUA),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medidor),
						'one' => q({0} medidor),
						'other' => q({0} medidores),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medidor),
						'one' => q({0} medidor),
						'other' => q({0} medidores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litros),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litros),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(chisco),
						'one' => q({0} chisco),
						'other' => q({0} chiscos),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(chisco),
						'one' => q({0} chisco),
						'other' => q({0} chiscos),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintas),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintas),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(cuartos),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(cuarto imperial),
						'one' => q({0} cto. imp.),
						'other' => q({0} ctos. imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(cuarto imperial),
						'one' => q({0} cto. imp.),
						'other' => q({0} ctos. imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cull.),
						'one' => q({0} cull.),
						'other' => q({0} cull.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cull.),
						'one' => q({0} cull.),
						'other' => q({0} cull.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cullñs.),
						'one' => q({0} cullña.),
						'other' => q({0} cullñs.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cullñs.),
						'one' => q({0} cullña.),
						'other' => q({0} cullñs.),
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
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00000 M',
					'other' => '00000 M',
				},
				'100000000000' => {
					'one' => '000000 M',
					'other' => '000000 M',
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
					'one' => '0000 millóns',
					'other' => '0000 millóns',
				},
				'10000000000' => {
					'one' => '00000 millóns',
					'other' => '00000 millóns',
				},
				'100000000000' => {
					'one' => '000000 millóns',
					'other' => '000000 millóns',
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
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00000 M',
					'other' => '00000 M',
				},
				'100000000000' => {
					'one' => '000000 M',
					'other' => '000000 M',
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
				'currency' => q(dirham dos Emiratos Árabes Unidos),
				'one' => q(dirham dos Emiratos Árabes Unidos),
				'other' => q(dirhams dos Emiratos Árabes Unidos),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani afgán),
				'one' => q(afgani afgán),
				'other' => q(afganis afgáns),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(lek albanés),
				'one' => q(lek albanés),
				'other' => q(lekë albaneses),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram armenio),
				'one' => q(dram armenio),
				'other' => q(drams armenios),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(florín das Antillas Neerlandesas),
				'one' => q(florín das Antillas Neerlandesas),
				'other' => q(floríns das Antillas Neerlandesas),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(kwanza angolano),
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
				'currency' => q(peso arxentino),
				'one' => q(peso arxentino),
				'other' => q(pesos arxentinos),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(dólar australiano),
				'one' => q(dólar australiano),
				'other' => q(dólares australianos),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(florín de Aruba),
				'one' => q(florín de Aruba),
				'other' => q(floríns de Aruba),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(manat acerbaixano),
				'one' => q(manat acerbaixano),
				'other' => q(manats acerbaixanos),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(marco convertible de Bosnia e Hercegovina),
				'one' => q(marco convertible de Bosnia e Hercegovina),
				'other' => q(marcos convertibles de Bosnia e Hercegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dólar de Barbados),
				'one' => q(dólar de Barbados),
				'other' => q(dólares de Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(taka de Bangladesh),
				'one' => q(taka de Bangladesh),
				'other' => q(takas de Bangladesh),
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
				'currency' => q(lev búlgaro),
				'one' => q(lev búlgaro),
				'other' => q(leva búlgaros),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinar de Bahrain),
				'one' => q(dinar de Bahrain),
				'other' => q(dinares de Bahrain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(franco burundiano),
				'one' => q(franco burundiano),
				'other' => q(francos burundianos),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dólar bermudano),
				'one' => q(dólar bermudano),
				'other' => q(dólares bermudanos),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dólar de Brunei),
				'one' => q(dólar de Brunei),
				'other' => q(dólares de Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(boliviano),
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
				'currency' => q(real brasileiro),
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
				'currency' => q(dólar bahamés),
				'one' => q(dólar bahamés),
				'other' => q(dólares bahameses),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(ngultrum butanés),
				'one' => q(ngultrum butanés),
				'other' => q(ngultrums butaneses),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula botswaniano),
				'one' => q(pula botswaniano),
				'other' => q(pulas botswanianos),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(rublo belaruso),
				'one' => q(rublo belaruso),
				'other' => q(rublos belarusos),
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
				'currency' => q(dólar belizense),
				'one' => q(dólar belizense),
				'other' => q(dólares belizenses),
			},
		},
		'CAD' => {
			symbol => '$',
			display_name => {
				'currency' => q(dólar canadense),
				'one' => q(dólar canadense),
				'other' => q(dólares canadenses),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(franco congolés),
				'one' => q(franco congolés),
				'other' => q(francos congoleses),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franco suízo),
				'one' => q(franco suízo),
				'other' => q(francos suízos),
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
				'currency' => q(peso chileno),
				'one' => q(peso chileno),
				'other' => q(pesos chilenos),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(iuán chinés \(extracontinental\)),
				'one' => q(iuán chinés \(extracontinental\)),
				'other' => q(iuáns chineses \(extracontinentais\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(iuán chinés),
				'one' => q(iuán chinés),
				'other' => q(iuáns chineses),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombianos),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(colón costarriqueño),
				'one' => q(colón costarriqueño),
				'other' => q(colóns costarriqueños),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso cubano convertible),
				'one' => q(peso cubano convertible),
				'other' => q(pesos cubanos convertibles),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(escudo caboverdiano),
				'one' => q(escudo caboverdiano),
				'other' => q(escudos caboverdianos),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(coroa checa),
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
				'currency' => q(franco djibutiano),
				'one' => q(franco djibutiano),
				'other' => q(francos djibutianos),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(coroa dinamarquesa),
				'one' => q(coroa dinamarquesa),
				'other' => q(coroas dinamarquesas),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicanos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(dinar alxeriano),
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
				'currency' => q(libra exipcia),
				'one' => q(libra exipcia),
				'other' => q(libras exipcias),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(nakfa eritreo),
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
				'currency' => q(birr etíope),
				'one' => q(birr etíope),
				'other' => q(birres etíopes),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(dólar fixiano),
				'one' => q(dólar fixiano),
				'other' => q(dólares fixianos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(libra das Illas Malvinas),
				'one' => q(libra das Illas Malvinas),
				'other' => q(libras das Illas Malvinas),
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
				'currency' => q(libra esterlina),
				'one' => q(libra esterlina),
				'other' => q(libras esterlinas),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(lari xeorxiano),
				'one' => q(lari xeorxiano),
				'other' => q(laris xeorxianos),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi ghanés),
				'one' => q(cedi ghanés),
				'other' => q(cedis ghaneses),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(libra xibraltareña),
				'one' => q(libra xibraltareña),
				'other' => q(libras xibraltareñas),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi gambiano),
				'one' => q(dalasi gambiano),
				'other' => q(dalasis gambianos),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(franco guineano),
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
				'currency' => q(quetzal guatemalteco),
				'one' => q(quetzal guatemalteco),
				'other' => q(quetzais guatemaltecos),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(dólar güianés),
				'one' => q(dólar güianés),
				'other' => q(dólares güianeses),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(dólar de Hong Kong),
				'one' => q(dólar de Hong Kong),
				'other' => q(dólares de Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(lempira hondureño),
				'one' => q(lempira hondureño),
				'other' => q(lempiras hondureños),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunas croatas),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gourde haitiana),
				'one' => q(gourde haitiana),
				'other' => q(gourdes haitianas),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(florín húngaro),
				'one' => q(florín húngaro),
				'other' => q(floríns húngaros),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(rupia indonesia),
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
				'currency' => q(novo shequel israelí),
				'one' => q(novo shequel israelí),
				'other' => q(novos shequeis israelís),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(rupia india),
				'one' => q(rupia india),
				'other' => q(rupias indias),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinar iraquí),
				'one' => q(dinar iraquí),
				'other' => q(dinares iraquíes),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(rial iraniano),
				'one' => q(rial iraniano),
				'other' => q(riales iranianos),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(coroa islandesa),
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
				'currency' => q(dólar xamaicano),
				'one' => q(dólar xamaicano),
				'other' => q(dólares xamaicanos),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(dinar xordano),
				'one' => q(dinar xordano),
				'other' => q(dinares xordanos),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(ien xaponés),
				'one' => q(ien xaponés),
				'other' => q(iens xaponeses),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(xilin kenyano),
				'one' => q(xilin kenyano),
				'other' => q(xilins kenyanos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som kirguiz),
				'one' => q(som kirguiz),
				'other' => q(soms kirguiz),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel camboxano),
				'one' => q(riel camboxano),
				'other' => q(rieis camboxanos),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franco comoriano),
				'one' => q(franco comoriano),
				'other' => q(francos comorianos),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(won norcoreano),
				'one' => q(won norcoreano),
				'other' => q(wons norcoreanos),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(won surcoreano),
				'one' => q(won surcoreano),
				'other' => q(wons surcoreanos),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinar kuwaití),
				'one' => q(dinar kuwaití),
				'other' => q(dinares kuwaitís),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dólar das Illas Caimán),
				'one' => q(dólar das Illas Caimán),
				'other' => q(dólares das Illas Caimán),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tenge kazako),
				'one' => q(tenge kazako),
				'other' => q(tenges kazakos),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip laosiano),
				'one' => q(kip laosiano),
				'other' => q(kips laosianos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libra libanesa),
				'one' => q(libra libanesa),
				'other' => q(libras libanesas),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(rupia srilankesa),
				'one' => q(rupia srilankesa),
				'other' => q(rupias srilankesas),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dólar liberiano),
				'one' => q(dólar liberiano),
				'other' => q(dólares liberianos),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(loti de Lesoto),
				'one' => q(loti de Lesoto),
				'other' => q(lotis de Lesoto),
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
				'currency' => q(dinar libio),
				'one' => q(dinar libio),
				'other' => q(dinares libios),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(dirham marroquí),
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
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(lei moldavos),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(ariary malgaxe),
				'one' => q(ariary malgaxe),
				'other' => q(ariarys malgaxes),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(dinar macedonio),
				'one' => q(dinar macedonio),
				'other' => q(dinares macedonios),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat birmano),
				'one' => q(kyat birmano),
				'other' => q(kyats birmanos),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongois),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca macaense),
				'one' => q(pataca macaense),
				'other' => q(patacas macaenses),
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
				'currency' => q(ouguiya mauritano),
				'one' => q(ouguiya mauritano),
				'other' => q(ouguiyas mauritanos),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupias mauricianas),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rupia maldivana),
				'one' => q(rupia maldivana),
				'other' => q(rupias maldivanas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(kwacha de Malawi),
				'one' => q(kwacha de Malawi),
				'other' => q(kwachas de Malawi),
			},
		},
		'MXN' => {
			symbol => '$MX',
			display_name => {
				'currency' => q(peso mexicano),
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
				'currency' => q(ringgit malaio),
				'one' => q(ringgit malaio),
				'other' => q(ringgits malaios),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(metical mozambicano),
				'one' => q(metical mozambicano),
				'other' => q(meticais mozambicanos),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(dólar namibio),
				'one' => q(dólar namibio),
				'other' => q(dólares namibios),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira nixeriano),
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
				'currency' => q(córdoba nicaraguano),
				'one' => q(córdoba nicaraguano),
				'other' => q(córdobas nicaraguanos),
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
				'currency' => q(coroa norueguesa),
				'one' => q(coroa norueguesa),
				'other' => q(coroas norueguesas),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupias nepalesas),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(dólar neozelandés),
				'one' => q(dólar neozelandés),
				'other' => q(dólares neozelandeses),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(rial omaní),
				'one' => q(rial omaní),
				'other' => q(riais omanís),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(balboa panameño),
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
				'currency' => q(sol peruano),
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
				'currency' => q(kina de Papúa-Nova Guinea),
				'one' => q(kina de Papúa-Nova Guinea),
				'other' => q(kinas de Papúa-Nova Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipino),
				'one' => q(peso filipino),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(rupia paquistaní),
				'one' => q(rupia paquistaní),
				'other' => q(rupias paquistanís),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(zloty polaco),
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
				'currency' => q(guaraní paraguaio),
				'one' => q(guaraní paraguaio),
				'other' => q(guaranís paraguaios),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(rial qatarí),
				'one' => q(rial qatarí),
				'other' => q(riais qatarís),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(leu romanés),
				'one' => q(leu romanés),
				'other' => q(lei romaneses),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar serbio),
				'one' => q(dinar serbio),
				'other' => q(dinares serbios),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(rublo ruso),
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
				'currency' => q(franco ruandés),
				'one' => q(franco ruandés),
				'other' => q(francos ruandeses),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(rial saudita),
				'one' => q(rial saudita),
				'other' => q(riais sauditas),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dólar das Illas Salomón),
				'one' => q(dólar das Illas Salomón),
				'other' => q(dólares das Illas Salomón),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(rupia de Seychelles),
				'one' => q(rupia de Seychelles),
				'other' => q(rupias de Seychelles),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(libra sudanesa),
				'one' => q(libra sudanesa),
				'other' => q(libras sudanesas),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(coroa sueca),
				'one' => q(coroa sueca),
				'other' => q(coroas suecas),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dólar de Singapur),
				'one' => q(dólar de Singapur),
				'other' => q(dólares de Singapur),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(libra de Santa Helena),
				'one' => q(libra de Santa Helena),
				'other' => q(libras de Santa Helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone de Serra Leoa),
				'one' => q(leone de Serra Leoa),
				'other' => q(leones de Serra Leoa),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(xilin somalí),
				'one' => q(xilin somalí),
				'other' => q(xilins somalís),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(dólar surinamés),
				'one' => q(dólar surinamés),
				'other' => q(dólares surinamés),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(libra sursudanesa),
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
				'currency' => q(dobra de San Tomé e Príncipe),
				'one' => q(dobra de San Tomé e Príncipe),
				'other' => q(dobras de San Tomé e Príncipe),
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
				'currency' => q(libra siria),
				'one' => q(libra siria),
				'other' => q(libras sirias),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni de Swazilandia),
				'one' => q(lilangeni de Swazilandia),
				'other' => q(lilangenis de Swazilandia),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bahts tailandeses),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(somoni taxiquistano),
				'one' => q(somoni taxiquistano),
				'other' => q(somonis taxiquistanos),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(manat turkmeno),
				'one' => q(manat turkmeno),
				'other' => q(manats turkmenos),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunisiano),
				'one' => q(dinar tunisiano),
				'other' => q(dinares tunisianos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(paʻanga tongano),
				'one' => q(paʻanga tongano),
				'other' => q(pa’angas tonganos),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(liras turcas),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dólar trinitense),
				'one' => q(dólar trinitense),
				'other' => q(dólares trinitenses),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(novo dólar taiwanés),
				'one' => q(novo dólar taiwanés),
				'other' => q(novos dólares taiwaneses),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(xilin tanzano),
				'one' => q(xilin tanzano),
				'other' => q(xilins tanzanos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(hrivna ucraína),
				'one' => q(hrivna ucraína),
				'other' => q(hrivnas ucraínas),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(xilin ugandés),
				'one' => q(xilin ugandés),
				'other' => q(xilins ugandeses),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(dólar estadounidense),
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
				'currency' => q(peso uruguaio),
				'one' => q(peso uruguaio),
				'other' => q(pesos uruguaios),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(som uzbeko),
				'one' => q(som uzbeko),
				'other' => q(soms uzbekos),
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
				'currency' => q(bolívar venezolano),
				'one' => q(bolívar venezolano),
				'other' => q(bolívares venezolanos),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dongs vietnamitas),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu vanuatiano),
				'one' => q(vatu vanuatiano),
				'other' => q(vatus vanuatianos),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala samoano),
				'one' => q(tala samoano),
				'other' => q(talas samoanos),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(franco CFA \(BEAC\)),
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
			symbol => 'XCD',
			display_name => {
				'currency' => q(dólar do Caribe Oriental),
				'one' => q(dólar do Caribe Oriental),
				'other' => q(dólares do Caribe Oriental),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(franco CFA \(BCEAO\)),
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
				'currency' => q(franco CFP),
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
				'currency' => q(moeda descoñecida),
				'one' => q(\(moeda descoñecida\)),
				'other' => q(\(moedas descoñecidas\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(rial iemení),
				'one' => q(rial iemení),
				'other' => q(riais iemenís),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(rand surafricano),
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
				'currency' => q(kwacha zambiano),
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
			'full' => q{EEEE, d 'de' MMMM 'de' Y G},
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
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			GyMd => q{d/M/y GGGGG},
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
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM 'de' y G},
			yyyyMMMEd => q{E, d 'de' MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d 'de' MMM 'de' y G},
			yyyyMd => q{d/M/y GGGGG},
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
			GyMMMd => q{d 'de' MMM 'de' y G},
			GyMd => q{d/M/y GGGGG},
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
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMM => q{MMMM 'de' y},
			yMMMd => q{d 'de' MMM 'de' y},
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
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM 'de' y G – MMM 'de' y G},
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			GyMMMEd => {
				G => q{E, d 'de' MMM 'de' y G – E, d 'de' MMM 'de' y G},
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
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
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
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
				y => q{y–y G},
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
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
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
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM 'de' y G – MMM 'de' y G},
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			GyMMMEd => {
				G => q{E, d 'de' MMM 'de' y G – E, d 'de' MMM 'de' y G},
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
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
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
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
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d–d 'de' MMMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
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
				'standard' => q#Horario de África Meridional#,
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
			exemplarCity => q#Illas Caimán#,
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
				'daylight' => q#Horario de verán do leste, América do Norte#,
				'generic' => q#Horario do leste, América do Norte#,
				'standard' => q#Horario estándar do leste, América do Norte#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Horario de verán da montaña, América do Norte#,
				'generic' => q#Horario da montaña, América do Norte#,
				'standard' => q#Horario estándar da montaña, América do Norte#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Horario de verán do Pacífico, América do Norte#,
				'generic' => q#Horario do Pacífico, América do Norte#,
				'standard' => q#Horario estándar do Pacífico, América do Norte#,
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
			exemplarCity => q#Showa#,
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
		'Asia/Qostanay' => {
			exemplarCity => q#Qostanai#,
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
			exemplarCity => q#Sakhalín#,
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
			exemplarCity => q#Ürümqi#,
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
			exemplarCity => q#Illas Bermudas#,
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
				'daylight' => q#Horario de verán dos Azores#,
				'generic' => q#Horario dos Azores#,
				'standard' => q#Horario estándar dos Azores#,
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
				'standard' => q#Horario da Illa Christmas#,
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
			exemplarCity => q#Ámsterdam#,
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
			exemplarCity => q#Saraievo#,
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
			exemplarCity => q#Uzghorod#,
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
				'daylight' => q#Horario de verán de Fixi#,
				'generic' => q#Horario de Fixi#,
				'standard' => q#Horario estándar de Fixi#,
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
				'standard' => q#Horario do Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Horario da Güiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Horario de verán de Hawai-illas Aleutianas#,
				'generic' => q#Horario de Hawai-illas Aleutianas#,
				'standard' => q#Horario estándar de Hawai-illas Aleutianas#,
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
				'standard' => q#Horario da India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Illa Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comores#,
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
				'standard' => q#Horario de Kazakistán Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Horario de Kazakistán Occidental#,
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
				'daylight' => q#Horario de verán de Krasnoiarsk#,
				'generic' => q#Horario de Krasnoiarsk#,
				'standard' => q#Horario estándar de Krasnoiarsk#,
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
				'standard' => q#Horario de Myanmar#,
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
				'daylight' => q#Horario de verán de Terra Nova#,
				'generic' => q#Horario de Terra Nova#,
				'standard' => q#Horario estándar de Terra Nova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Horario de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Horario de verán da Illa Norfolk#,
				'generic' => q#Horario da Illa Norfolk#,
				'standard' => q#Horario estándar da Illa Norfolk#,
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
			exemplarCity => q#Fixi#,
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
				'daylight' => q#Horario de verán do Paraguai#,
				'generic' => q#Horario do Paraguai#,
				'standard' => q#Horario estándar do Paraguai#,
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
				'daylight' => q#Horario de verán de Sakhalín#,
				'generic' => q#Horario de Sakhalín#,
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
				'standard' => q#Horario de Singapur#,
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
				'daylight' => q#Horario de verán de Turkmenistán#,
				'generic' => q#Horario de Turkmenistán#,
				'standard' => q#Horario estándar de Turkmenistán#,
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
				'daylight' => q#Horario de verán de Uzbekistán#,
				'generic' => q#Horario de Uzbekistán#,
				'standard' => q#Horario estándar de Uzbekistán#,
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
		'Yukon' => {
			long => {
				'standard' => q#Horario de Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
