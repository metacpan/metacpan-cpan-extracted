=head1

Locale::CLDR::Locales::Gl - Package for language Galician

=cut

package Locale::CLDR::Locales::Gl;
# This file auto generated from Data\common\main\gl.xml
#	on Fri 29 Apr  7:05:42 pm GMT

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
				'ab' => 'abkhazo',
 				'ach' => 'acoli',
 				'af' => 'afrikaans',
 				'agq' => 'agq',
 				'ak' => 'akán',
 				'am' => 'amárico',
 				'an' => 'aragonés',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe estándar moderno',
 				'arc' => 'arameo',
 				'arn' => 'mapuche',
 				'as' => 'assamés',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'ay' => 'aimará',
 				'az' => 'acerbaixano',
 				'az@alt=short' => 'azerí',
 				'ba' => 'baskir',
 				'be' => 'bielorruso',
 				'bem' => 'bemba',
 				'bez' => 'bez',
 				'bg' => 'búlgaro',
 				'bgn' => 'Baluchi occidental',
 				'bm' => 'bm',
 				'bn' => 'bengalí',
 				'bo' => 'tibetano',
 				'br' => 'bretón',
 				'brx' => 'brx',
 				'bs' => 'bosnio',
 				'ca' => 'catalán',
 				'ce' => 'Checheno',
 				'cgg' => 'kiga',
 				'chr' => 'cheroqui',
 				'ckb' => 'curdo soraní',
 				'co' => 'corso',
 				'cs' => 'checo',
 				'cu' => 'eslavo eclesiástico',
 				'cv' => 'Chuvash',
 				'cy' => 'galés',
 				'da' => 'dinamarqués',
 				'dav' => 'taita',
 				'de' => 'alemán',
 				'de_AT' => 'alemán de austria',
 				'de_CH' => 'alto alemán suízo',
 				'dje' => 'zarma',
 				'dsb' => 'dsb',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'ebu' => 'embu',
 				'ee' => 'ewé',
 				'efi' => 'ibibio',
 				'egy' => 'exipcio antigo',
 				'el' => 'grego',
 				'en' => 'inglés',
 				'en_AU' => 'inglés australiano',
 				'en_CA' => 'inglés canadiano',
 				'en_GB' => 'inglés británico',
 				'en_GB@alt=short' => 'inglés R.U.',
 				'en_US' => 'inglés dos Estados Unidos',
 				'en_US@alt=short' => 'inglés EUA',
 				'eo' => 'esperanto',
 				'es' => 'español',
 				'es_419' => 'español latinoamericano',
 				'es_ES' => 'castelán',
 				'es_MX' => 'español de México',
 				'et' => 'estoniano',
 				'eu' => 'éuscaro',
 				'fa' => 'persa',
 				'fi' => 'finés',
 				'fil' => 'filipino',
 				'fj' => 'fixiano',
 				'fo' => 'faroés',
 				'fr' => 'francés',
 				'fr_CA' => 'francés canadiano',
 				'fr_CH' => 'francés suízo',
 				'fy' => 'frisón',
 				'ga' => 'irlandés',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gd' => 'gaélico escocés',
 				'gl' => 'galego',
 				'gn' => 'guaraní',
 				'grc' => 'grego antigo',
 				'gsw' => 'alemán suízo',
 				'gu' => 'guxaratiano',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'ha' => 'hausa',
 				'haw' => 'hawaiano',
 				'he' => 'hebreo',
 				'hi' => 'hindi',
 				'hr' => 'croata',
 				'hsb' => 'hsb',
 				'ht' => 'haitiano',
 				'hu' => 'húngaro',
 				'hy' => 'armenio',
 				'ia' => 'interlingua',
 				'id' => 'indonesio',
 				'ig' => 'ibo',
 				'ii' => 'yi sichuanés',
 				'is' => 'islandés',
 				'it' => 'italiano',
 				'iu' => 'iu',
 				'ja' => 'xaponés',
 				'jgo' => 'ngomba',
 				'jmc' => 'mapache',
 				'jv' => 'xavanés',
 				'ka' => 'xeorxiano',
 				'kab' => 'kabile',
 				'kam' => 'kamba',
 				'kde' => 'makonde',
 				'kea' => 'caboverdiano',
 				'kg' => 'kongo',
 				'khq' => 'koyra Chiini',
 				'ki' => 'kikuyu',
 				'kk' => 'casaco',
 				'kl' => 'kl',
 				'kln' => 'kln',
 				'km' => 'cambodiano',
 				'kn' => 'kannada',
 				'ko' => 'coreano',
 				'koi' => 'komi permio',
 				'kok' => 'konkani',
 				'ks' => 'cachemir',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ku' => 'kurdo',
 				'kw' => 'kw',
 				'ky' => 'quirguiz',
 				'la' => 'latín',
 				'lag' => 'Langi',
 				'lb' => 'luxemburgués',
 				'lg' => 'ganda',
 				'lkt' => 'Lakota',
 				'ln' => 'lingala',
 				'lo' => 'laotiano',
 				'loz' => 'lozi',
 				'lrc' => 'Lurí do norte',
 				'lt' => 'lituano',
 				'lu' => 'luba-Katanga',
 				'lua' => 'luba-lulua',
 				'luo' => 'luo',
 				'luy' => 'luyia',
 				'lv' => 'letón',
 				'mas' => 'masai',
 				'mer' => 'meru',
 				'mfe' => 'crioulo mauritano',
 				'mg' => 'malgaxe',
 				'mgh' => 'mgh',
 				'mgo' => 'mgo',
 				'mi' => 'maorí',
 				'mk' => 'macedonio',
 				'ml' => 'malabar',
 				'mn' => 'mongol',
 				'moh' => 'mohawk',
 				'mr' => 'marathi',
 				'ms' => 'malaio',
 				'mt' => 'maltés',
 				'mua' => 'mundang',
 				'mul' => 'varias linguas',
 				'my' => 'birmano',
 				'mzn' => 'Mazandaraní',
 				'naq' => 'naq',
 				'nb' => 'noruegués bokmal',
 				'nd' => 'ndebele do norte',
 				'nds' => 'Baixo alemán',
 				'nds_NL' => 'Baixo saxón',
 				'ne' => 'nepalí',
 				'nl' => 'holandés',
 				'nl_BE' => 'flamenco',
 				'nmg' => 'nmg',
 				'nn' => 'noruegués nynorsk',
 				'no' => 'noruegués',
 				'nqo' => 'nqo',
 				'nso' => 'sesotho sa leboa',
 				'nus' => 'nus',
 				'ny' => 'chewa',
 				'nyn' => 'nyankole',
 				'oc' => 'occitano',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osetio',
 				'pa' => 'punjabi',
 				'pl' => 'polaco',
 				'ps' => 'paxtún',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués brasileiro',
 				'pt_PT' => 'portugués europeo',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romanés',
 				'rof' => 'rombo',
 				'ru' => 'ruso',
 				'rw' => 'ruandés',
 				'rwk' => 'rwk',
 				'sa' => 'sánscrito',
 				'saq' => 'saq',
 				'sbp' => 'sbp',
 				'sd' => 'sindhi',
 				'sdh' => 'Kurdo meridional',
 				'se' => 'sami do norte',
 				'seh' => 'sena',
 				'ses' => 'ses',
 				'sg' => 'sango',
 				'sh' => 'serbocroata',
 				'shi' => 'tachelhit',
 				'si' => 'cingalés',
 				'sk' => 'eslovaco',
 				'sl' => 'esloveno',
 				'sm' => 'samoano',
 				'sma' => 'sma',
 				'smj' => 'smj',
 				'smn' => 'smn',
 				'sms' => 'sms',
 				'sn' => 'shona',
 				'so' => 'somalí',
 				'sq' => 'albanés',
 				'sr' => 'serbio',
 				'ss' => 'swati',
 				'st' => 'sesoto',
 				'su' => 'sondanés',
 				'sv' => 'sueco',
 				'sw' => 'swahili',
 				'sw_CD' => 'swc',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'teo' => 'teso',
 				'tet' => 'tetún',
 				'tg' => 'taxico',
 				'th' => 'tailandés',
 				'ti' => 'tigriña',
 				'tk' => 'turcomano',
 				'tl' => 'tagalo',
 				'tlh' => 'klingon',
 				'tn' => 'tswana',
 				'to' => 'tonganés',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'ts' => 'xitsonga',
 				'tt' => 'tártaro',
 				'tum' => 'tumbuka',
 				'tw' => 'twi',
 				'twq' => 'twq',
 				'ty' => 'tahitiano',
 				'tzm' => 'tzm',
 				'ug' => 'uigur',
 				'uk' => 'ucraíno',
 				'und' => 'Lingua descoñecida',
 				'ur' => 'urdú',
 				'uz' => 'uzbeco',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamita',
 				'vun' => 'vunjo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'wólof',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yi' => 'yiddish',
 				'yo' => 'ioruba',
 				'zgh' => 'tamazight de Marrocos estándar',
 				'zh' => 'chinés',
 				'zh_Hans' => 'chinés simplificado',
 				'zh_Hant' => 'chinés tradicional',
 				'zu' => 'zulú',
 				'zxx' => 'sen contido lingüístico',

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
			'Arab' => 'Árabe',
 			'Arab@alt=variant' => 'perso-árabe',
 			'Armn' => 'Armenio',
 			'Beng' => 'Bengalí',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cans' => 'Silabario aborixe canadiano unificado',
 			'Cyrl' => 'Cirílico',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Etíope',
 			'Geor' => 'Xeorxiano',
 			'Grek' => 'Grego',
 			'Gujr' => 'guxaratí',
 			'Guru' => 'Gurmukhi',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Simplificado',
 			'Hans@alt=stand-alone' => 'Han simplificado',
 			'Hant' => 'Tradicional',
 			'Hant@alt=stand-alone' => 'Han tradicional',
 			'Hebr' => 'Hebreo',
 			'Hira' => 'Hiragana',
 			'Jpan' => 'Xaponés',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Camboxano',
 			'Knda' => 'canarés',
 			'Kore' => 'Coreano',
 			'Laoo' => 'Laosiano',
 			'Latn' => 'Latino',
 			'Mlym' => 'Malabar',
 			'Mong' => 'Mongol',
 			'Mymr' => 'Birmania',
 			'Orya' => 'Oriya',
 			'Sinh' => 'Cingalés',
 			'Taml' => 'Támil',
 			'Telu' => 'Telugú',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Tailandés',
 			'Tibt' => 'Tibetano',
 			'Zsym' => 'Símbolos',
 			'Zxxx' => 'Non escrita',
 			'Zyyy' => 'Común',
 			'Zzzz' => 'Escritura descoñecida',

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
 			'005' => 'Sudamérica',
 			'009' => 'Oceanía',
 			'011' => 'África Occidental',
 			'013' => 'América Central',
 			'014' => 'África Oriental',
 			'015' => 'África Septentrional',
 			'017' => 'África Central',
 			'018' => 'África Meridional',
 			'019' => 'América',
 			'021' => 'América do Norte',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Sul de Asia',
 			'035' => 'Sureste Asiático',
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
 			'154' => 'Europa Septentrional',
 			'155' => 'Europa Occidental',
 			'419' => 'América Latina',
 			'AC' => 'Illa de Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Árabes Unidos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antiga e Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártida',
 			'AR' => 'Arxentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Illas Aland',
 			'AZ' => 'Acerbaixán',
 			'BA' => 'Bosnia e Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélxica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'San Bartolomé',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribe neerlandés',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bután',
 			'BV' => 'Illa Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Bielorrusia',
 			'BZ' => 'Belice',
 			'CA' => 'Canadá',
 			'CC' => 'Illas Cocos (Keeling)',
 			'CD' => 'República Democrática do Congo',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'Congo',
 			'CG@alt=variant' => 'Congo (RC)',
 			'CH' => 'Suíza',
 			'CI' => 'Costa de Marfil',
 			'CI@alt=variant' => 'Costa do Marfil',
 			'CK' => 'Illas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Illa Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Illa Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'República Checa',
 			'DE' => 'Alemaña',
 			'DG' => 'Diego García',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Arxelia',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Exipto',
 			'EH' => 'Sáhara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Unión Europea',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fixi',
 			'FK' => 'Illas Malvinas',
 			'FK@alt=variant' => 'Illas Malvinas (Falkland)',
 			'FM' => 'Micronesia',
 			'FO' => 'Illas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reino Unido',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Granada',
 			'GE' => 'Xeorxia',
 			'GF' => 'Güiana Francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Xibraltar',
 			'GL' => 'Grenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Xeorxia do Sur e Illas Sandwich',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Güiana',
 			'HK' => 'Hong Kong RAE de China',
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
 			'IN' => 'India',
 			'IO' => 'Territorio Británico do Océano Índico',
 			'IQ' => 'Iraq',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Xamaica',
 			'JO' => 'Xordania',
 			'JP' => 'Xapón',
 			'KE' => 'Kenya',
 			'KG' => 'Quirguicistán',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'San Cristovo e Nevis',
 			'KP' => 'Corea do Norte',
 			'KR' => 'Corea do Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Illas Caimán',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
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
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'San Martiño',
 			'MG' => 'Madagascar',
 			'MH' => 'Illas Marshall',
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (ARIM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau RAE de China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Illas Marianas do norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malaui',
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
 			'NZ' => 'Nova Celandia',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Francesa',
 			'PG' => 'Papúa Nova Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistán',
 			'PL' => 'Polonia',
 			'PM' => 'San Pedro e Miguelón',
 			'PN' => 'Illas Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Territorios palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Qatar',
 			'QO' => 'Oceanía Distante',
 			'RE' => 'Reunión',
 			'RO' => 'Romanía',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Illas Salomón',
 			'SC' => 'Seixeles',
 			'SD' => 'Sudán',
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
 			'SR' => 'Surinam',
 			'SS' => 'Sudán do sur',
 			'ST' => 'San Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Suacilandia',
 			'TA' => 'Tristán da Cunha',
 			'TC' => 'Illas Turks e Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Franceses do Sul',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Taxiquistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trindade e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraína',
 			'UG' => 'Uganda',
 			'UM' => 'Illas Menores Distantes dos EUA.',
 			'US' => 'Estados Unidos de América',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Cidade do Vaticano',
 			'VC' => 'San Vicente e Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Illas Virxes Británicas',
 			'VI' => 'Illas Virxes Estadounidenses',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Iemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudáfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Cimbabue',
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
			'calendar' => 'Calendario',
 			'colalternate' => 'Ignorar clasificación de símbolos',
 			'colbackwards' => 'Clasificación de acentos invertida',
 			'colcasefirst' => 'Orde de maiúsculas/minúsculas',
 			'colcaselevel' => 'Clasificación que distingue entre maiúsculas e minúsculas',
 			'colhiraganaquaternary' => 'Clasificación Kana',
 			'collation' => 'Orde de clasificación',
 			'colnormalization' => 'Clasificación normalizada',
 			'colnumeric' => 'Clasificación numérica',
 			'colstrength' => 'Forza de clasificación',
 			'currency' => 'Moeda',
 			'hc' => 'Ciclo horario (12 vs. 24)',
 			'lb' => 'Estilo de quebra de liña',
 			'ms' => 'Sistema de unidades',
 			'numbers' => 'Números',
 			'timezone' => 'Fuso horario',
 			'va' => 'Variante local',
 			'variabletop' => 'Clasificar como símbolos',
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
 				'buddhist' => q{Calendario budista},
 				'chinese' => q{Calendario chinés},
 				'coptic' => q{Calendario cóptico},
 				'dangi' => q{Calendario dangi},
 				'ethiopic' => q{Calendario etíope},
 				'ethiopic-amete-alem' => q{Calendario Amete Alem etíope},
 				'gregorian' => q{Calendario gregoriano},
 				'hebrew' => q{Calendario hebreo},
 				'indian' => q{Calendario nacional indio},
 				'islamic' => q{Calendario islámico},
 				'islamic-civil' => q{Calendario islámico (civil, tabular)},
 				'islamic-rgsa' => q{Calendario islámico (Arabia Saudita,},
 				'iso8601' => q{Calendario ISO-8601},
 				'japanese' => q{Calendario xaponés},
 				'persian' => q{Calendario persa},
 				'roc' => q{Calendario Minguo},
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
 			'colhiraganaquaternary' => {
 				'no' => q{Clasificar Kana por separado},
 				'yes' => q{Clasificar Kana de modo diferente},
 			},
 			'collation' => {
 				'big5han' => q{Orde de clasificación chinesa tradicional - Big5},
 				'dictionary' => q{Criterio de ordenación do dicionario},
 				'ducet' => q{Criterio de ordenación Unicode predeterminado},
 				'gb2312han' => q{orde de clasifcación chinesa simplificada - GB2312},
 				'phonebook' => q{orde de clasificación da guía telefónica},
 				'phonetic' => q{Orde de clasificación fonética},
 				'pinyin' => q{Orde de clasificación pinyin},
 				'reformed' => q{Criterio de ordenación reformado},
 				'search' => q{Busca de uso xeral},
 				'searchjl' => q{Clasificar por consonante inicial hangul},
 				'standard' => q{Criterio de ordenación estándar},
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
 			'hc' => {
 				'h11' => q{Sistema de 12 horas (0–11)},
 				'h12' => q{Sistema de 12 horas (1–12)},
 				'h23' => q{Sistema de 24 horas (0–23)},
 				'h24' => q{Sistema de 24 horas (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Estilo de quebra de liña separada},
 				'normal' => q{Estilo de quebra de liña normal},
 				'strict' => q{Estilo de quebra de liña estrita},
 			},
 			'ms' => {
 				'metric' => q{Sistema métrico},
 				'uksystem' => q{Sistema imperial de unidades},
 				'ussystem' => q{Sistema de unidades dos EUA},
 			},
 			'numbers' => {
 				'arab' => q{Díxitos do árabe oriental},
 				'arabext' => q{Díxitos arábicos orientais},
 				'armn' => q{Números armenios},
 				'armnlow' => q{Números armenios en minúscula},
 				'beng' => q{Díxitos bengalís},
 				'deva' => q{Díxitos devanagari},
 				'ethi' => q{Números etíopes},
 				'finance' => q{Números financeiros},
 				'fullwide' => q{Díxitos de ancho completo},
 				'geor' => q{Números xeorxianos},
 				'grek' => q{Números gregos},
 				'greklow' => q{Números gregos en minúscula},
 				'gujr' => q{Díxitos guxarati},
 				'guru' => q{Díxitos do gurmukhi},
 				'hanidec' => q{Números decimais chineses},
 				'hans' => q{Números chineses simplificados},
 				'hansfin' => q{Números financeiros chineses simplificados},
 				'hant' => q{Números do chinés tradicional},
 				'hantfin' => q{Números financeiros do chinés tradicional},
 				'hebr' => q{Números hebreos},
 				'jpan' => q{Números xaponeses},
 				'jpanfin' => q{Números financeiros xaponeses},
 				'khmr' => q{Díxitos do camboxano},
 				'knda' => q{Díxitos do kannadés},
 				'laoo' => q{Díxitos laosianos},
 				'latn' => q{Díxitos occidentais},
 				'mlym' => q{Díxitos malabares},
 				'mong' => q{Díxitos mongoles},
 				'mymr' => q{Díxitos birmanos},
 				'native' => q{Díxitos orixinais},
 				'orya' => q{Díxitos oriya},
 				'roman' => q{Números romanos},
 				'romanlow' => q{Números romanos en minúsculas},
 				'taml' => q{Números támil},
 				'tamldec' => q{Díxitos do támil},
 				'telu' => q{Díxitos do telugú},
 				'thai' => q{Díxitos tailandeses},
 				'tibt' => q{Díxitos tibetanos},
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
 			'US' => q{americano},

		}
	},
);

has 'display_name_transform_name' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'bgn' => 'BGN',
 			'numeric' => 'Numérico',
 			'tone' => 'Ton',
 			'ungegn' => 'UNGEGN',
 			'x-accents' => 'Acentos',
 			'x-fullwidth' => 'Ancho completo',
 			'x-halfwidth' => 'Ancho medio',
 			'x-jamo' => 'Jamo',
 			'x-pinyin' => 'Pinyin',
 			'x-publishing' => 'Publicación',

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
			auxiliary => qr{(?^u:[ª à â ä ã ç è ê ë ì î ï º ò ô ö õ ù û])},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{(?^u:[a á b c d e é f g h i í j k l m n ñ o ó p q r s t u ú ü v w x y z])},
			punctuation => qr{(?^u:[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″])},
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
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acres pés),
						'one' => q({0} acre pé),
						'other' => q({0} acres pés),
					},
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					'arc-minute' => {
						'name' => q(arcominutos),
						'one' => q({0} arcominuto),
						'other' => q({0} arcominutos),
					},
					'arc-second' => {
						'name' => q(arcosegundos),
						'one' => q({0} arcosegundo),
						'other' => q({0} arcosegundos),
					},
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidad astronómica),
						'other' => q({0} unidades astronómicas),
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
						'name' => q(Calorías),
						'one' => q({0} Caloría),
						'other' => q({0} Calorías),
					},
					'foot' => {
						'name' => q(pé),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					'g-force' => {
						'name' => q(forza G),
						'one' => q({0} forza G),
						'other' => q({0} forzas G),
					},
					'gallon' => {
						'name' => q(galóns),
						'one' => q({0} galón),
						'other' => q({0} galóns),
						'per' => q({0} por galón),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'name' => q(polgada),
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
						'name' => q(nó),
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
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
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
						'name' => q(millas por galón),
						'one' => q({0} milla por galón),
						'other' => q({0} millas por galón),
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
					'per' => {
						'1' => q({0} por {1}),
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
						'name' => q(revolución),
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
						'one' => q({0} pé carado),
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
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					'ton' => {
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
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
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
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
						'name' => q(días),
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
						'name' => q(hora),
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
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
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
						'name' => q(miliseg),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'month' => {
						'name' => q(mes),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(seg),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(sem),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'year' => {
						'name' => q(anos),
						'one' => q({0} a),
						'other' => q({0} a),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(acres pés),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcomin),
						'one' => q({0} arcomin),
						'other' => q({0} arcomin),
					},
					'arc-second' => {
						'name' => q(arcoseg),
						'one' => q({0} arcoseg),
						'other' => q({0} arcoseg),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
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
						'name' => q(quilate),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(g. Celsius),
						'one' => q({0} g Celsius),
						'other' => q({0} g Celsius),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cent),
						'one' => q({0} cent),
						'other' => q({0} cent),
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
						'name' => q(pés³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(polgadas³),
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
						'name' => q(iardas³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cuncas),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
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
						'name' => q(º),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(pé),
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
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
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
						'name' => q(gramos),
						'one' => q({0} gram),
						'other' => q({0} gram),
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
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} ph),
					},
					'inch' => {
						'name' => q(polgadas),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(in Hg),
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
						'one' => q({0} ct),
						'other' => q({0} ct),
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
						'name' => q(quilog),
						'one' => q({0} quilog),
						'other' => q({0} quilog),
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
						'name' => q(quilóm),
						'one' => q({0} quilóm),
						'other' => q({0} quilóm),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/hora),
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
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(anos luz),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					'liter' => {
						'name' => q(lit),
						'one' => q({0} lit),
						'other' => q({0} lit),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lux),
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
						'name' => q(met),
						'one' => q({0} met),
						'other' => q({0} met),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metros/seg),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(metros/seg²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
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
						'name' => q(millas/galón),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(millas/hora),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliamp),
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
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(milím),
						'one' => q({0} milím),
						'other' => q({0} milím),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(miliseg),
						'one' => q({0} miliseg),
						'other' => q({0} miliseg),
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
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanoseg.),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
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
						'name' => q(onza troy),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pársecs),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
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
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
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
						'name' => q(seg),
						'one' => q({0} seg),
						'other' => q({0} seg),
						'per' => q({0} ps),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0} por cm²),
					},
					'square-foot' => {
						'name' => q(pé²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(polgadas²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0} por in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(metros²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0} por m²),
					},
					'square-mile' => {
						'name' => q(millas²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'square-yard' => {
						'name' => q(iardas²),
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
						'name' => q(toneladas),
						'one' => q({0} t),
						'other' => q({0} t),
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
						'name' => q(semanas),
						'one' => q({0} sem),
						'other' => q({0} sem),
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
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0k M',
					'other' => '0k M',
				},
				'10000000000' => {
					'one' => '00k M',
					'other' => '00k M',
				},
				'100000000000' => {
					'one' => '000k M',
					'other' => '000k M',
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
					'' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
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
					'one' => '0 mil millóns',
					'other' => '0 mil millóns',
				},
				'10000000000' => {
					'one' => '00 mil millóns',
					'other' => '00 mil millóns',
				},
				'100000000000' => {
					'one' => '000 mil millóns',
					'other' => '000 mil millóns',
				},
				'1000000000000' => {
					'one' => '0 billóns',
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0k M',
					'other' => '0k M',
				},
				'10000000000' => {
					'one' => '00k M',
					'other' => '00k M',
				},
				'100000000000' => {
					'one' => '000k M',
					'other' => '000k M',
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
					'' => '#,##0%',
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
				'currency' => q(Kwanza angoleño),
				'one' => q(kwanza ngoleño),
				'other' => q(kwanzas angoleños),
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
			symbol => '$A',
			display_name => {
				'currency' => q(Dólar australiano),
				'one' => q(dólar australiano),
				'other' => q(dólares australianos),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florín arubeño),
				'one' => q(florín arubeño),
				'other' => q(floríns arubeños),
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
				'currency' => q(Taka de Bangladesh),
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
				'currency' => q(Lev búlgaro),
				'one' => q(lev búlgaro),
				'other' => q(levs búlgaros),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar de Baréin),
				'one' => q(dinar de Baréin),
				'other' => q(dinares de Baréin),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franco burundés),
				'one' => q(franco burundés),
				'other' => q(francos burundeses),
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
			symbol => '$R',
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
				'currency' => q(Pula botsuano),
				'one' => q(pula botsuano),
				'other' => q(pulas botsuanos),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rublo bielorruso),
				'one' => q(rublo bielorruso),
				'other' => q(rublos bielorrusos),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dólar beliceño),
				'one' => q(dólar beliceño),
				'other' => q(dólares beliceños),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(Dólar canadiano),
				'one' => q(dólar canadiano),
				'other' => q(dólares canadianos),
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
				'currency' => q(Colón costarricense),
				'one' => q(colón costarricense),
				'other' => q(colóns costarricenses),
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
				'currency' => q(Dólar fixiano),
				'one' => q(dólar fixiano),
				'other' => q(dólares fixianos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Libra das Malvinas),
				'one' => q(libra de Malvinas),
				'other' => q(libras de Malvinas),
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
				'currency' => q(Cedi de Gana),
				'one' => q(cedi de Gana),
				'other' => q(cedis de Gana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Libra de Xibraltar),
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
			symbol => '$HK',
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
				'other' => q(novos shequeis israelíes),
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
			symbol => '¥JP',
			display_name => {
				'currency' => q(Ien xaponés),
				'one' => q(ien xaponés),
				'other' => q(iens xaponeses),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Chelín kenyano),
				'one' => q(chelín kenyano),
				'other' => q(chelíns kenyanos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som quirguizo),
				'one' => q(som quirguizo),
				'other' => q(soms quirguizos),
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
				'other' => q(dinares kuwaitíes),
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
				'currency' => q(Kiat birmano),
				'one' => q(kiat birmano),
				'other' => q(kiats birmanos),
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
				'currency' => q(Ouguiya mauritano),
				'one' => q(ouguiya mauritano),
				'other' => q(ouguiyasmauritanos),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia de Mauricio),
				'one' => q(rupia de Mauricio),
				'other' => q(rupias de Mauricio),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rupia maldiva),
				'one' => q(rupia maldiva),
				'other' => q(rupias maldivas),
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
				'currency' => q(Córdoba de ouro nicaragüense),
				'one' => q(córdoba de ouro nicaragüense),
				'other' => q(córdobas de ouro nicaragüense),
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
				'other' => q(dólares neozelandés),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial omaní),
				'one' => q(rial omaní),
				'other' => q(riais omaníes),
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
				'currency' => q(Sol novo peruano),
				'one' => q(sol novo peruano),
				'other' => q(soles novos peruanos),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol peruano),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina de Papúa Nova Guinea),
				'one' => q(kina de Papúa Nova Guinea),
				'other' => q(kinas de Papúa Nova Guinea),
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
				'other' => q(rupias paquistaníes),
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
				'other' => q(riais qataríes),
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
				'one' => q(leones de Serra Leoa),
				'other' => q(leones de Serra Leoa),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Chelín somalí),
				'one' => q(chelín somalí),
				'other' => q(chelíns somalíes),
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
				'currency' => q(Dobra de San Tomé e Príncipe),
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
				'currency' => q(Libra siria),
				'one' => q(libra siria),
				'other' => q(libras sirias),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilanxeni de Suacilandia),
				'one' => q(lilanxeni de Suacilandia),
				'other' => q(lilanxeni de Suacilandia),
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
				'currency' => q(Somoni taxico),
				'one' => q(somoni taxico),
				'other' => q(somonis taxicos),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat turcomano),
				'one' => q(manat turcomano),
				'other' => q(manats turcomanos),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar tunesino),
				'one' => q(dinar tunesino),
				'other' => q(dinares tunesinos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga de Tonga),
				'one' => q(paʻanga de Tonga),
				'other' => q(pa’anga de Tonga),
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
				'currency' => q(Dólar de Trinidade e Tobago),
				'one' => q(dólar de Trinidade e Tobago),
				'other' => q(dólares de Trinidade e Tobago),
			},
		},
		'TWD' => {
			symbol => '$NT',
			display_name => {
				'currency' => q(Novo dólar taiwanés),
				'one' => q(novo dólar taiwanés),
				'other' => q(novos dólares taiwaneses),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Chelín tanzano),
				'one' => q(chelín tanzano),
				'other' => q(chelíns tanzanos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Grivna ucraína),
				'one' => q(grivna ucraína),
				'other' => q(grivnas ucraínas),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Chelín ugandés),
				'one' => q(chelín ugandés),
				'other' => q(chelíns ugandeses),
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
				'currency' => q(Vatu vanuatense),
				'one' => q(vatu vanuatense),
				'other' => q(vatus vanuatenses),
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
				'currency' => q(Franco CFA BEAC),
				'one' => q(franco CFA BEAC),
				'other' => q(francos CFA BEAC),
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
				'currency' => q(Dólar Caribe-Leste),
				'one' => q(dólar Caribe-Leste),
				'other' => q(dólares Caribe-Leste),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franco CFA BCEAO),
				'one' => q(franco CFA BCEAO),
				'other' => q(francos CFA BCEAO),
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
				'currency' => q(Unidade monetaria descoñecida),
				'one' => q(\(unidade monetaria descoñecida\)),
				'other' => q(\(unidades monetarias descoñecidas\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial iemení),
				'one' => q(rial iemení),
				'other' => q(riais iemeníes),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand sudafricano),
				'one' => q(rand sudafricano),
				'other' => q(rands sudafricanos),
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
							'xan',
							'feb',
							'mar',
							'abr',
							'mai',
							'xuñ',
							'xul',
							'ago',
							'set',
							'out',
							'nov',
							'dec'
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
							'Xan',
							'Feb',
							'Mar',
							'Abr',
							'Mai',
							'Xuñ',
							'Xul',
							'Ago',
							'Set',
							'Out',
							'Nov',
							'Dec'
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
						tue => 'mar',
						wed => 'mér',
						thu => 'xov',
						fri => 'ven',
						sat => 'sáb',
						sun => 'dom'
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
						mon => 'luns',
						tue => 'mt',
						wed => 'mc',
						thu => 'xv',
						fri => 've',
						sat => 'sáb',
						sun => 'dom'
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
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mér',
						thu => 'Xov',
						fri => 'Ven',
						sat => 'Sáb',
						sun => 'Dom'
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
						mon => 'Luns',
						tue => 'Mt',
						wed => 'Mc',
						thu => 'Xv',
						fri => 'Ven',
						sat => 'Sáb',
						sun => 'Dom'
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
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
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
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
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
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2100
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2100
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
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
					'afternoon1' => q{da mediodía},
					'evening1' => q{da tarde},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'morning1' => q{da mañá},
					'night1' => q{da noite},
					'midnight' => q{da noite},
					'morning2' => q{da mañá},
				},
				'wide' => {
					'night1' => q{da noite},
					'morning1' => q{da mañá},
					'midnight' => q{da noite},
					'morning2' => q{da mañá},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'afternoon1' => q{da mediodía},
					'evening1' => q{da tarde},
				},
				'narrow' => {
					'night1' => q{da noite},
					'morning1' => q{da mañá},
					'midnight' => q{da noite},
					'morning2' => q{da mañá},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'afternoon1' => q{da mediodía},
					'evening1' => q{da tarde},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'evening1' => q{tarde},
					'afternoon1' => q{mediodía},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'midnight' => q{medianoite},
					'morning1' => q{madrugada},
					'night1' => q{noite},
					'morning2' => q{mañá},
				},
				'narrow' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'evening1' => q{tarde},
					'afternoon1' => q{mediodía},
					'midnight' => q{medianoite},
					'morning1' => q{madrugada},
					'night1' => q{noite},
					'morning2' => q{mañá},
				},
				'wide' => {
					'afternoon1' => q{mediodía},
					'evening1' => q{tarde},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'morning1' => q{madrugada},
					'night1' => q{noite},
					'midnight' => q{medianoite},
					'morning2' => q{mañá},
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
			'full' => q{EEEE dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{d MMM, y},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			E => q{ccc},
			Ed => q{d E},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{G y},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{G y},
			yyyyM => q{GGGGG M/y},
			yyyyMEd => q{GGGGG E, d/M/y},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G E, d MMM y},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{G d, MMM y},
			yyyyMd => q{GGGGG d/M/y},
			yyyyQQQ => q{G QQQ y},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d-M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yMd => q{d/M/y},
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
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
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
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d–d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
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
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d–d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
		regionFormat => q(Horario de {0}),
		regionFormat => q(Horario de verán de {0}),
		regionFormat => q(Horario estándar de {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q(Horario de Afganistán),
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
			exemplarCity => q#Asmak#,
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
			exemplarCity => q#Cairo#,
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
			exemplarCity => q#Dacar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Xibutí#,
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
			exemplarCity => q#Xamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugú#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnez#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(Horario de África Central),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(Horario de África Oriental),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(Horario estándar de Sudáfrica),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(Horario de verán de África Occidental),
				'generic' => q(Horario de África Occidental),
				'standard' => q(Horario estándar de África Occidental),
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q(Horario de verán de Alasca),
				'generic' => q(Horario de Alasca),
				'standard' => q(Horario estándar de Alasca),
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q(Horario de verán do Amazonas),
				'generic' => q(Horario do Amazonas),
				'standard' => q(Horario estándar do Amazonas),
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
			exemplarCity => q#La Rioja#,
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
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baía de Bandeiras#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#Belice#,
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
			exemplarCity => q#Bos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Abadía de Cambridge#,
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
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#O Salvador#,
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
			exemplarCity => q#Gran Turca#,
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
			exemplarCity => q#Habana#,
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
			exemplarCity => q#Petersburgo, Indiana#,
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
			exemplarCity => q#La Paz#,
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
			exemplarCity => q#Monterrei#,
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
			exemplarCity => q#Beulah, Dakota do Norte#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota do Norte#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota do Norte#,
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
			exemplarCity => q#Santarem#,
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
			exemplarCity => q#San Bartolomé#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristovo#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#San Tomé#,
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
				'daylight' => q(Horario de verán da zona central),
				'generic' => q(Horario central),
				'standard' => q(Horario estándar central),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(Horario de verán de América Oriental),
				'generic' => q(Horario de América Oriental),
				'standard' => q(Horario estándar América Oriental),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(Horario de verán das montañas americanas),
				'generic' => q(Horario das montañas americanas),
				'standard' => q(Horario estándar das montañas americanas),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(Horario de verán do Pacífico),
				'generic' => q(Horario do Pacífico),
				'standard' => q(Horario estándar do Pacífico),
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q(Horario de verán de Anadir),
				'generic' => q(Horario de Anadir),
				'standard' => q(Horario estándar de Anadir),
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
				'daylight' => q(Horario de verán de Apia),
				'generic' => q(Horario de Apia),
				'standard' => q(Horario estándar de Apia),
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q(Horario de verán árabe),
				'generic' => q(Horario árabe),
				'standard' => q(Horario estándar árabe),
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q(Horario de verán de Arxentina),
				'generic' => q(Horario de Arxentina),
				'standard' => q(Horario estándar de Arxentina),
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q(Horario de verán de Arxentina Occidental),
				'generic' => q(Horario de Arxentina Occidental),
				'standard' => q(Horario estándar de Arxentina Occidental),
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q(Horario de verán de Armenia),
				'generic' => q(Horario de Armenia),
				'standard' => q(Horario estándar de Armenia),
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
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
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
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
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
			exemplarCity => q#Jaiapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
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
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
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
			exemplarCity => q#Mascat#,
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
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
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
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timbu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Toquio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulán Bátor#,
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
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ecaterinburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Iereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q(Horario de verán do Atlántico),
				'generic' => q(Horario do Atlántico),
				'standard' => q(Horario estándar do Atlántico),
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
			exemplarCity => q#Faroe#,
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
			exemplarCity => q#Adelaide#,
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
				'daylight' => q(Horario de verán de Australia Central),
				'generic' => q(Horario de Australia Central),
				'standard' => q(Horario estándar de Australia Central),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(Horario de verán de Australia Occidental Central),
				'generic' => q(Horario de Australia Occidental Central),
				'standard' => q(Horario estándar de Australia Occidental Central),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(Horario de verán de Australia Oriental),
				'generic' => q(Horario de Australia Oriental),
				'standard' => q(Horario estándar de Australia Oriental),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(Horario de verán de Australia Occidental),
				'generic' => q(Horario de Australia Occidental),
				'standard' => q(Horario estándar de Australia Occidental),
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q(Horario de verán de Acerbaixán),
				'generic' => q(Horario de Acerbaixán),
				'standard' => q(Horario estándar de Acerbaixán),
			},
		},
		'Azores' => {
			long => {
				'daylight' => q(Horario de verán das Azores),
				'generic' => q(Horario das Azores),
				'standard' => q(Horario estándar das Azores),
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q(Horario de verán de Bangladesh),
				'generic' => q(Horario de Bangladesh),
				'standard' => q(Horario estándar de Bangladesh),
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q(Horario de Bután),
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q(Horario de Bolivia),
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q(Horario de verán de Brasilia),
				'generic' => q(Horario de Brasilia),
				'standard' => q(Horario estándar de Brasilia),
			},
		},
		'Brunei' => {
			long => {
				'standard' => q(Horario de Brunei Darussalam),
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q(Horario de verán de Cabo Verde),
				'generic' => q(Horario de Cabo Verde),
				'standard' => q(Horario estándar de Cabo Verde),
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q(Horario estándar de Chamorro),
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q(Horario de verán de Chatham),
				'generic' => q(Horario de Chatham),
				'standard' => q(Horario estándar de Chatham),
			},
		},
		'Chile' => {
			long => {
				'daylight' => q(Horario de verán de Chile),
				'generic' => q(Horario de Chile),
				'standard' => q(Horario estándar de Chile),
			},
		},
		'China' => {
			long => {
				'daylight' => q(Horario de verán de China),
				'generic' => q(Horario de China),
				'standard' => q(Horario estándar de China),
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q(Horario de verán de Choibalsan),
				'generic' => q(Horario de Choibalsan),
				'standard' => q(Horario estándar de Choibalsan),
			},
		},
		'Christmas' => {
			long => {
				'standard' => q(Horario da Illa de Nadal),
			},
		},
		'Cocos' => {
			long => {
				'standard' => q(Horario das Illas Cocos),
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q(Horario de verán de Colombia),
				'generic' => q(Horario de Colombia),
				'standard' => q(Horario estándar de Colombia),
			},
		},
		'Cook' => {
			long => {
				'daylight' => q(Horario de verán medio das Illas Cook),
				'generic' => q(Horario das Illas Cook),
				'standard' => q(Horario estándar das Illas Cook),
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q(Horario de verán de Cuba),
				'generic' => q(Horario de Cuba),
				'standard' => q(Horario estándar de Cuba),
			},
		},
		'Davis' => {
			long => {
				'standard' => q(Horario de Davis),
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q(Horario de Dumont-d’Urville),
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q(Horario de Timor Leste),
			},
		},
		'Easter' => {
			long => {
				'daylight' => q(Horario de verán da Illa de Pascua),
				'generic' => q(Horario da Illa de Pascua),
				'standard' => q(Horario estándar da Illa de Pascua),
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q(Horario de Ecuador),
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
		'Europe/Athens' => {
			exemplarCity => q#Athens#,
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
			exemplarCity => q#Copenhaguen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublín#,
			long => {
				'daylight' => q(Horario estándar irlandés),
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Xibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernesei#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Illa de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estanbul#,
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
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q(Horario de verán británico),
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
			exemplarCity => q#Rome#,
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
			exemplarCity => q#Talín#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
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
			exemplarCity => q#Zúric#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q(Horario de verán de Europa Central),
				'generic' => q(Horario de Europa Central),
				'standard' => q(Horario estándar de Europa Central),
			},
			short => {
				'daylight' => q(CEST),
				'generic' => q(CET),
				'standard' => q(CET),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(Horario de verán de Europa Oriental),
				'generic' => q(Horario de Europa Oriental),
				'standard' => q(Horario estándar de Europa Oriental),
			},
			short => {
				'daylight' => q(EEST),
				'generic' => q(EET),
				'standard' => q(EET),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(Horario de Kaliningrado),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(Horario de verán de Europa Occidental),
				'generic' => q(Horario de Europa Occidental),
				'standard' => q(Horario estándar de Europa Occidental),
			},
			short => {
				'daylight' => q(WEST),
				'generic' => q(WET),
				'standard' => q(WET),
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q(Horario de verán das Illas Malvinas),
				'generic' => q(Horario das Illas Malvinas),
				'standard' => q(Horario estándar das Illas Malvinas),
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q(Horario de verán de Fidxi),
				'generic' => q(Horario de Fidxi),
				'standard' => q(Horario estándar de Fidxi),
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q(Horario da Güiana Francesa),
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q(Horario das Terras Austrais e Antárticas Francesas),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(Horario do meridiano de Greenwich),
			},
			short => {
				'standard' => q(GMT),
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q(Horario das Galápagos),
			},
		},
		'Gambier' => {
			long => {
				'standard' => q(Horario de Gambier),
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q(Horario de verán de Xeorxia),
				'generic' => q(Horario de Xeorxia),
				'standard' => q(Horario estándar de Xeorxia),
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q(Horario das Illas Gilbert),
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q(Horario de verán de Grenlandia Oriental),
				'generic' => q(Horario de Grenlandia Oriental),
				'standard' => q(Horario estándar de Grenlandia Oriental),
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q(Horario de verán de Grenlandia Occidental),
				'generic' => q(Horario de Grenlandia Occidental),
				'standard' => q(Horario estándar de Grenlandia Occidental),
			},
		},
		'Gulf' => {
			long => {
				'standard' => q(Horario estándar do Golfo),
			},
		},
		'Guyana' => {
			long => {
				'standard' => q(Horario da Güiana),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(Horario de verán de Hawai-Aleutiano),
				'generic' => q(Horario de Hawai-Aleutiano),
				'standard' => q(Horario estándar de Hawai-Aleutiano),
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q(Horario de verán de Hong Kong),
				'generic' => q(Horario de Hong Kong),
				'standard' => q(Horario estándar de Hong Kong),
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q(Horario de verán de Hovd),
				'generic' => q(Horario de Hovd),
				'standard' => q(Horario estándar de Hovd),
			},
		},
		'India' => {
			long => {
				'standard' => q(Horario estándar da India),
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
			exemplarCity => q#Mahe#,
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
				'standard' => q(Horario do Océano Índico),
			},
		},
		'Indochina' => {
			long => {
				'standard' => q(Horario de Indochina),
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q(Horario de Indonesia Central),
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q(Horario de Indonesia Oriental),
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q(Horario de Indonesia Occidental),
			},
		},
		'Iran' => {
			long => {
				'daylight' => q(Horario de verán de Irán),
				'generic' => q(Horario de Irán),
				'standard' => q(Horario estándar de Irán),
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q(Horario de verán de Irkutsk),
				'generic' => q(Horario de Irkutsk),
				'standard' => q(Horario estándar de Irkutsk),
			},
		},
		'Israel' => {
			long => {
				'daylight' => q(Horario de verán de Israel),
				'generic' => q(Horario de Israel),
				'standard' => q(Horario estándar de Israel),
			},
		},
		'Japan' => {
			long => {
				'daylight' => q(Horario de verán de Xapón),
				'generic' => q(Horario de Xapón),
				'standard' => q(Horario estándar de Xapón),
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q(Horario de verán de Petropávlovsk-Kamchatski),
				'generic' => q(Horario de Petropávlovsk-Kamchatski),
				'standard' => q(Horario estándar de Petropávlovsk-Kamchatski),
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q(Horario de Casaquistán este),
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q(Horario de Casaquistán oeste),
			},
		},
		'Korea' => {
			long => {
				'daylight' => q(Horario de verán de Corea),
				'generic' => q(Horario de Corea),
				'standard' => q(Horario estándar de Corea),
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q(Horario de Kosrae),
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q(Horario de verán de Krasnoyarsk),
				'generic' => q(Horario de Krasnoyarsk),
				'standard' => q(Horario estándar de Krasnoyarsk),
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q(Horario de Quirguicistán),
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q(Horario das Illas da Liña),
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q(Horario de verán de Lord Howe),
				'generic' => q(Horario de Lord Howe),
				'standard' => q(Horario estándar de Lord Howe),
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q(Horario da Illa Macquarie),
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q(Horario de verán de Magadán),
				'generic' => q(Horario de Magadán),
				'standard' => q(Horario estándar de Magadán),
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q(Horario de Malaisia),
			},
		},
		'Maldives' => {
			long => {
				'standard' => q(Horario das Maldivas),
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q(Horario das Marquesas),
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q(Horario das Illas Marshall),
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q(Horario de verán de Mauricio),
				'generic' => q(Horario de Mauricio),
				'standard' => q(Horario estándar de Mauricio),
			},
		},
		'Mawson' => {
			long => {
				'standard' => q(Horario de Mawson),
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q(Horario de verán de México Noroeste),
				'generic' => q(Horario de México Noroeste),
				'standard' => q(Horario estándar de México Noroeste),
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q(Horario de verán do Pacífico mexicano),
				'generic' => q(Horario do Pacífico mexicano),
				'standard' => q(Horario estándar do Pacífico mexicano),
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q(Horario de verán de Ulán Bátor),
				'generic' => q(Horario de Ulán Bátor),
				'standard' => q(Horario estándar de Ulán Bátor),
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q(Horario de verán de Moscova),
				'generic' => q(Horario de Moscova),
				'standard' => q(Horario estándar de Moscova),
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q(Horario de Birmania),
			},
		},
		'Nauru' => {
			long => {
				'standard' => q(Horario de Nauru),
			},
		},
		'Nepal' => {
			long => {
				'standard' => q(Horario de Nepal),
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q(Horario de verán de Nova Caledonia),
				'generic' => q(Horario de Nova Caledonia),
				'standard' => q(Horario estándar de Nova Caledonia),
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q(Horario de verán de Nova Celandia),
				'generic' => q(Horario de Nova Celandia),
				'standard' => q(Horario estándar de Nova Celandia),
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q(Horario de verán de Terranova),
				'generic' => q(Horario de Terranova),
				'standard' => q(Horario estándar de Terranova),
			},
		},
		'Niue' => {
			long => {
				'standard' => q(Horario de Niue),
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q(Horario das Illas Norfolk),
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q(Horario de verán de Fernando de Noronha),
				'generic' => q(Horario de Fernando de Noronha),
				'standard' => q(Horario estándar de Fernando de Noronha),
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q(Horario de verán de Novosibirsk),
				'generic' => q(Horario de Novosibirsk),
				'standard' => q(Horario estándar de Novosibirsk),
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q(Horario de verán de Omsk),
				'generic' => q(Horario de Omsk),
				'standard' => q(Horario estándar de Omsk),
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
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
			exemplarCity => q#Saipán#,
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
				'daylight' => q(Horario de verán de Paquistán),
				'generic' => q(Horario de Paquistán),
				'standard' => q(Horario estándar de Paquistán),
			},
		},
		'Palau' => {
			long => {
				'standard' => q(Horario de Palau),
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q(Horario de Papúa Nova Guinea),
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q(Horario de verán de Paraguai),
				'generic' => q(Horario de Paraguai),
				'standard' => q(Horario estándar de Paraguai),
			},
		},
		'Peru' => {
			long => {
				'daylight' => q(Horario de verán de Perú),
				'generic' => q(Horario de Perú),
				'standard' => q(Horario estándar de Perú),
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q(Horario de verán de Filipinas),
				'generic' => q(Horario de Filipinas),
				'standard' => q(Horario estándar de Filipinas),
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q(Horario das Illas Fénix),
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q(Horario de verán de San Pedro e Miguelón),
				'generic' => q(Horario de San Pedro e Miguelón),
				'standard' => q(Horario estándar de San Pedro e Miguelón),
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q(Horario de Pitcairn),
			},
		},
		'Ponape' => {
			long => {
				'standard' => q(Horario de Pohnpei),
			},
		},
		'Reunion' => {
			long => {
				'standard' => q(Horario de Reunión),
			},
		},
		'Rothera' => {
			long => {
				'standard' => q(Horario de Rothera),
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q(Horario de verán de Sakhalin),
				'generic' => q(Horario de Sakhalin),
				'standard' => q(Horario estándar de Sakhalín),
			},
		},
		'Samara' => {
			long => {
				'daylight' => q(Horario de verán de Samara),
				'generic' => q(Horario de Samara),
				'standard' => q(Horario estándar de Samara),
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q(Horario de verán de Samoa),
				'generic' => q(Horario de Samoa),
				'standard' => q(Horario estándar de Samoa),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(Horario das Seixeles),
			},
		},
		'Singapore' => {
			long => {
				'standard' => q(Horario estándar de Singapur),
			},
		},
		'Solomon' => {
			long => {
				'standard' => q(Horario das Illas Salomón),
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q(Horario de Xeorxia do Sur),
			},
		},
		'Suriname' => {
			long => {
				'standard' => q(Horario de Surinam),
			},
		},
		'Syowa' => {
			long => {
				'standard' => q(Horario de Syowa),
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q(Horario de Tahití),
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q(Horario de verán de Taipei),
				'generic' => q(Horario de Taipei),
				'standard' => q(Horario estándar de Taipei),
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q(Horario de Taxiquistán),
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q(Horario de Toquelau),
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q(Horario de verán de Tonga),
				'generic' => q(Horario de Tonga),
				'standard' => q(Horario estándar de Tonga),
			},
		},
		'Truk' => {
			long => {
				'standard' => q(Horario de Chuuk),
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q(Horario de verán de Turcomenistán),
				'generic' => q(Horario de Turcomenistán),
				'standard' => q(Horario estándar de Turcomenistán),
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q(Horario de Tuvalu),
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q(Horario de verán de Uruguai),
				'generic' => q(Horario de Uruguai),
				'standard' => q(Horario estándar de Uruguai),
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q(Horario de verán de Usbequistán),
				'generic' => q(Horario de Usbequistán),
				'standard' => q(Horario estándar de Usbequistán),
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q(Horario de verán de Vanuatu),
				'generic' => q(Horario de Vanuatu),
				'standard' => q(Horario estándar de Vanuatu),
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q(Horario de Venezuela),
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q(Horario de verán de Vladivostok),
				'generic' => q(Horario de Vladivostok),
				'standard' => q(Horario estándar de Vladivostok),
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q(Horario de verán de Volgogrado),
				'generic' => q(Horario de Volgogrado),
				'standard' => q(Horario estándar de Volgogrado),
			},
		},
		'Vostok' => {
			long => {
				'standard' => q(Horario de Vostok),
			},
		},
		'Wake' => {
			long => {
				'standard' => q(Horario da Illa Wake),
			},
		},
		'Wallis' => {
			long => {
				'standard' => q(Horario de Wallis e Futuna),
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q(Horario de verán de Iakutsk),
				'generic' => q(Horario de Iakutsk),
				'standard' => q(Horario estándar de Iakutsk),
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q(Horario de verán de Ekaterimburgo),
				'generic' => q(Horario de Ekaterimburgo),
				'standard' => q(Horario estándar de Ekaterimburgo),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
