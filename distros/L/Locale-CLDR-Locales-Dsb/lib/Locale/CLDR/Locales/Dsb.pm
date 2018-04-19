=head1

Locale::CLDR::Locales::Dsb - Package for language Lower Sorbian

=cut

package Locale::CLDR::Locales::Dsb;
# This file auto generated from Data\common\main\dsb.xml
#	on Fri 13 Apr  7:06:41 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'aa' => 'afaršćina',
 				'ab' => 'abchazšćina',
 				'af' => 'afrikans',
 				'agq' => 'aghem',
 				'ak' => 'akanšćina',
 				'am' => 'amharšćina',
 				'an' => 'aragonšćina',
 				'ang' => 'anglosaksojšćina',
 				'ar' => 'arabšćina',
 				'ar_001' => 'moderna wusokoarabšćina',
 				'arn' => 'arawkašćina',
 				'as' => 'asamšćina',
 				'asa' => 'pare',
 				'ast' => 'asturšćina',
 				'av' => 'awaršćina',
 				'ay' => 'aymaršćina',
 				'az' => 'azerbajdžanšćina',
 				'ba' => 'baškiršćina',
 				'be' => 'běłorušćina',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgaršćina',
 				'bi' => 'bislamšćina',
 				'bm' => 'bambara',
 				'bn' => 'bengalšćina',
 				'bo' => 'tibetšćina',
 				'br' => 'bretonšćina',
 				'brx' => 'bodo',
 				'bs' => 'bosnišćina',
 				'bug' => 'bugišćina',
 				'ca' => 'katanlanšćina',
 				'cgg' => 'chiga',
 				'ch' => 'čamoršćina',
 				'cho' => 'choctawšćina',
 				'chr' => 'cherokee',
 				'ckb' => 'sorani',
 				'co' => 'korsišćina',
 				'cr' => 'kri',
 				'cs' => 'češćina',
 				'cy' => 'walizišćina',
 				'da' => 'danšćina',
 				'dav' => 'taita',
 				'de' => 'nimšćina',
 				'de_AT' => 'awstriska nimšćina',
 				'de_CH' => 'šwicarska wusokonimšćina',
 				'dje' => 'zarma',
 				'dsb' => 'dolnoserbšćina',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'el' => 'grichišćina',
 				'en' => 'engelšćina',
 				'en_AU' => 'awstralska engelšćina',
 				'en_CA' => 'kanadiska engelšćina',
 				'en_GB' => 'britiska engelšćina',
 				'en_GB@alt=short' => 'UK-engelšćina',
 				'en_US' => 'ameriska engelšćina',
 				'en_US@alt=short' => 'US-engelšćina',
 				'eo' => 'esperanto',
 				'es' => 'špańšćina',
 				'es_419' => 'łatyńskoamerikańska špańšćina',
 				'es_ES' => 'europejska špańšćina',
 				'es_MX' => 'mexikańska špańšćina',
 				'et' => 'estišćina',
 				'eu' => 'baskišćina',
 				'fa' => 'persišćina',
 				'fi' => 'finšćina',
 				'fil' => 'filipinšćina',
 				'fj' => 'fidžišćina',
 				'fo' => 'ferejšćina',
 				'fr' => 'francojšćina',
 				'fr_CA' => 'kanadiska francojšćina',
 				'fr_CH' => 'šwicarska francojšćina',
 				'fy' => 'frizišćina',
 				'ga' => 'iršćina',
 				'gag' => 'gagauzšćina',
 				'gd' => 'šotišćina',
 				'gl' => 'galicišćina',
 				'gn' => 'guarani',
 				'got' => 'gotišćina',
 				'gsw' => 'šwicarska nimšćina',
 				'gu' => 'gudžaratšćina',
 				'guz' => 'gusii',
 				'gv' => 'manšćina',
 				'ha' => 'hausa',
 				'haw' => 'hawaiišćina',
 				'he' => 'hebrejšćina',
 				'hi' => 'hindišćina',
 				'hr' => 'chorwatšćina',
 				'hsb' => 'górnoserbšćina',
 				'ht' => 'haitišćina',
 				'hu' => 'hungoršćina',
 				'hy' => 'armeńšćina',
 				'ia' => 'interlingua',
 				'id' => 'indonešćina',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiak',
 				'io' => 'ido',
 				'is' => 'islandšćina',
 				'it' => 'italšćina',
 				'iu' => 'inuitšćina',
 				'ja' => 'japańšćina',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javašćina',
 				'ka' => 'georgišćina',
 				'kab' => 'kabylšćina',
 				'kam' => 'kamba',
 				'kde' => 'makonde',
 				'kea' => 'kapverdšćina',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kk' => 'kazachšćina',
 				'kl' => 'grönlandšćina',
 				'kln' => 'kalenjin',
 				'km' => 'kambodžanšćina',
 				'kn' => 'kannadšćina',
 				'ko' => 'korejańšćina',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkani',
 				'kri' => 'krio',
 				'ks' => 'kašmiršćina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ku' => 'kurdišćina',
 				'kw' => 'kornišćina',
 				'ky' => 'kirgišćina',
 				'la' => 'łatyńšćina',
 				'lag' => 'langi',
 				'lb' => 'luxemburgšćina',
 				'lg' => 'gandšćina',
 				'li' => 'limburšćina',
 				'lkt' => 'lakotšćina',
 				'ln' => 'lingala',
 				'lo' => 'laošćina',
 				'lt' => 'litawšćina',
 				'lu' => 'luba-katanga',
 				'luo' => 'luo',
 				'luy' => 'luhya',
 				'lv' => 'letišćina',
 				'mas' => 'masaišćina',
 				'mer' => 'meru',
 				'mfe' => 'mauriciska kreolšćina',
 				'mg' => 'malgašćina',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mi' => 'maorišćina',
 				'mk' => 'makedońšćina',
 				'ml' => 'malajamšćina',
 				'mn' => 'mongolšćina',
 				'moh' => 'mohawkšćina',
 				'mr' => 'maratišćina',
 				'ms' => 'malajšćina',
 				'mt' => 'maltašćina',
 				'mua' => 'mundang',
 				'mus' => 'krik',
 				'my' => 'burmašćina',
 				'na' => 'naurušćina',
 				'naq' => 'nama',
 				'nb' => 'norwegske bokmål',
 				'nd' => 'pódpołnocne ndebele',
 				'nds' => 'dolnonimšćina',
 				'ne' => 'nepalšćina',
 				'nl' => 'nižozemšćina',
 				'nl_BE' => 'flamšćina',
 				'nmg' => 'kwasio',
 				'nn' => 'norwegske nynorsk',
 				'no' => 'norwegšćina',
 				'nqo' => 'n’ko',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nyn' => 'nyankole',
 				'oc' => 'okcitanšćina',
 				'om' => 'oromo',
 				'or' => 'orojišćina',
 				'pa' => 'pandžabšćina',
 				'pl' => 'pólšćina',
 				'prg' => 'prusčina',
 				'ps' => 'paštunšćina',
 				'pt' => 'portugalšćina',
 				'pt_BR' => 'brazilska portugalšćina',
 				'pt_PT' => 'europejska portugalšćina',
 				'qu' => 'kečua',
 				'quc' => 'kʼicheʼ',
 				'rm' => 'retoromańšćina',
 				'rn' => 'kirundišćina',
 				'ro' => 'rumunšćina',
 				'ro_MD' => 'moldawišćina',
 				'rof' => 'rombo',
 				'ru' => 'rušćina',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'saq' => 'samburu',
 				'sbp' => 'sangu',
 				'sc' => 'sardinšćina',
 				'scn' => 'sicilianišćina',
 				'sd' => 'sindšćina',
 				'se' => 'lapšćina',
 				'seh' => 'sena',
 				'ses' => 'koyra senni',
 				'sg' => 'sango',
 				'sh' => 'serbochorwatšćina',
 				'shi' => 'tašelhit',
 				'si' => 'singalšćina',
 				'sk' => 'słowakšćina',
 				'sl' => 'słowjeńšćina',
 				'sm' => 'samošćina',
 				'sma' => 'pódpołdnjowa samišćina',
 				'smj' => 'lule-samišćina',
 				'smn' => 'inari-samišćina',
 				'sms' => 'skolt-samišćina',
 				'sn' => 'šonšćina',
 				'so' => 'somališćina',
 				'sq' => 'albanšćina',
 				'sr' => 'serbišćina',
 				'ss' => 'siswati',
 				'st' => 'pódpołdnjowa sotšćina (Sesotho)',
 				'stq' => 'saterfrizišćina',
 				'su' => 'sundanšćina',
 				'sv' => 'šwedšćina',
 				'sw' => 'swahilišćina',
 				'sw_CD' => 'kongojska swahilišćina',
 				'ta' => 'tamilšćina',
 				'te' => 'telugšćina',
 				'teo' => 'teso',
 				'tg' => 'tadžikišćina',
 				'th' => 'thailandšćina',
 				'ti' => 'tigrinja',
 				'tk' => 'turkmeńšćina',
 				'tl' => 'tagalog',
 				'tn' => 'tswana',
 				'to' => 'tonganšćina',
 				'tr' => 'turkojšćina',
 				'ts' => 'tsonga',
 				'tt' => 'tataršćina',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitišćina',
 				'tzm' => 'centralnoatlaski tamazight',
 				'ug' => 'ujguršćina',
 				'uk' => 'ukrainšćina',
 				'und' => 'njeznata rěc',
 				'ur' => 'urdušćina',
 				'uz' => 'usbekšćina',
 				'vai' => 'vai',
 				'vi' => 'vietnamšćina',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'walonšćina',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yi' => 'jidišćina',
 				'yo' => 'jorubšćina',
 				'za' => 'zhuang',
 				'zgh' => 'standardny marokkański tamazight',
 				'zh' => 'chinšćina',
 				'zh_Hans' => 'chinšćina (zjadnorjona)',
 				'zh_Hant' => 'chinšćina (tradicionalna)',
 				'zu' => 'zulu',
 				'zxx' => 'žedno rěcne wopśimjeśe',

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
			'Arab' => 'arabski',
 			'Armn' => 'armeński',
 			'Beng' => 'bengalski',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braillowe pismo',
 			'Cyrl' => 'kyriliski',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopiski',
 			'Geor' => 'georgiski',
 			'Grek' => 'grichiski',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'zjadnorjone',
 			'Hans@alt=stand-alone' => 'zjadnorjone han',
 			'Hant' => 'tradionalne',
 			'Hant@alt=stand-alone' => 'tradicionalne han',
 			'Hebr' => 'hebrejski',
 			'Hira' => 'hiragana',
 			'Jpan' => 'japański',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'korejski',
 			'Laoo' => 'laoski',
 			'Latn' => 'łatyński',
 			'Mlym' => 'malayalamski',
 			'Mong' => 'mongolski',
 			'Mymr' => 'burmaski',
 			'Orya' => 'oriya',
 			'Sinh' => 'singhaleski',
 			'Taml' => 'tamilski',
 			'Telu' => 'telugu',
 			'Thaa' => 'thaana',
 			'Thai' => 'thaiski',
 			'Tibt' => 'tibetski',
 			'Zsym' => 'symbole',
 			'Zxxx' => 'bźez pisma',
 			'Zyyy' => 'powšykne',
 			'Zzzz' => 'njeznate pismo',

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
			'001' => 'swět',
 			'002' => 'Afrika',
 			'003' => 'Pódpołnocna Amerika',
 			'005' => 'Pódpołdnjowa Amerika',
 			'009' => 'Oceaniska',
 			'011' => 'Pódwjacorna Afrika',
 			'013' => 'Srjejźna Amerika',
 			'014' => 'pódzajtšna Afrika',
 			'015' => 'pódpołnocna Afrika',
 			'017' => 'srjejźna Afrika',
 			'018' => 'pódpołdnjowa Afrika',
 			'019' => 'Amerika',
 			'021' => 'pódpołnocny ameriski kontinent',
 			'029' => 'Karibiska',
 			'030' => 'pódzajtšna Azija',
 			'034' => 'pódpołdnjowa Azija',
 			'035' => 'krotkozajtšna Azija',
 			'039' => 'pódpołdnjowa Europa',
 			'053' => 'Awstralazija',
 			'054' => 'Melaneziska',
 			'057' => 'Mikroneziska (kupowy region)',
 			'061' => 'Polyneziska',
 			'142' => 'Azija',
 			'143' => 'centralna Azija',
 			'145' => 'pódwjacorna Azija',
 			'150' => 'Europa',
 			'151' => 'pódzajtšna Europa',
 			'154' => 'pódpołnocna Europa',
 			'155' => 'pódwjacorna Europa',
 			'419' => 'Łatyńska Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Zjadnośone arabiske emiraty',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albańska',
 			'AM' => 'Armeńska',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinska',
 			'AS' => 'Ameriska Samoa',
 			'AT' => 'Awstriska',
 			'AU' => 'Awstralska',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbajdžan',
 			'BA' => 'Bosniska a Hercegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgiska',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarska',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermudy',
 			'BN' => 'Brunei',
 			'BO' => 'Boliwiska',
 			'BQ' => 'Karibiska Nižozemska',
 			'BR' => 'Brazilska',
 			'BS' => 'Bahamy',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetowa kupa',
 			'BW' => 'Botswana',
 			'BY' => 'Běłoruska',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosowe kupy',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (Demokratiska republika)',
 			'CF' => 'Centralnoafriska republika',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Šwicarska',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Słonowokósćowy pśibrjog',
 			'CK' => 'Cookowe kupy',
 			'CL' => 'Chilska',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbiska',
 			'CP' => 'Clippertonowa kupa',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Gódowne kupy',
 			'CY' => 'Cypriska',
 			'CZ' => 'Česka republika',
 			'DE' => 'Nimska',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Džibuti',
 			'DK' => 'Dańska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikańska republika',
 			'DZ' => 'Algeriska',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estniska',
 			'EG' => 'Egyptojska',
 			'EH' => 'Pódwjacorna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Špańska',
 			'ET' => 'Etiopiska',
 			'EU' => 'Europska unija',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandske kupy',
 			'FK@alt=variant' => 'Falklandske kupy (Malwiny)',
 			'FM' => 'Mikroneziska',
 			'FO' => 'Färöje',
 			'FR' => 'Francojska',
 			'GA' => 'Gabun',
 			'GB' => 'Zjadnośone kralejstwo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgiska',
 			'GF' => 'Francojska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönlandska',
 			'GM' => 'Gambija',
 			'GN' => 'Gineja',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekwatorialna Gineja',
 			'GR' => 'Grichiska',
 			'GS' => 'Pódpołdnjowa Georgiska a Pódpołdnjowe Sandwichowe kupy',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gineja-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Wósebna zastojnstwowa cona Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardowa kupa a McDonaldowe kupy',
 			'HN' => 'Honduras',
 			'HR' => 'Chorwatska',
 			'HT' => 'Haiti',
 			'HU' => 'Hungorska',
 			'IC' => 'Kanariske kupy',
 			'ID' => 'Indoneziska',
 			'IE' => 'Irska',
 			'IL' => 'Israel',
 			'IM' => 'Man',
 			'IN' => 'Indiska',
 			'IO' => 'Britiski indiskooceaniski teritorium',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandska',
 			'IT' => 'Italska',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordaniska',
 			'JP' => 'Japańska',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komory',
 			'KN' => 'St. Kitts a Nevis',
 			'KP' => 'Pódpołnocna Koreja',
 			'KR' => 'Pódpołdnjowa Koreja',
 			'KW' => 'Kuwait',
 			'KY' => 'Kajmaniske kupy',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesotho',
 			'LT' => 'Litawska',
 			'LU' => 'Luxemburgska',
 			'LV' => 'Letiska',
 			'LY' => 'Libyska',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldawska',
 			'ME' => 'Carna Góra',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallowe kupy',
 			'MK' => 'Makedońska',
 			'MK@alt=variant' => 'Makedońska (PRJ)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolska',
 			'MO' => 'Wósebna zastojnstwowa cona Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Pódpołnocne Mariany',
 			'MQ' => 'Martinique',
 			'MR' => 'Mawretańska',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediwy',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malajzija',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibija',
 			'NC' => 'Nowa Kaledoniska',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkowa kupa',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nižozemska',
 			'NO' => 'Norwegska',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nowoseelandska',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francojska Polyneziska',
 			'PG' => 'Papua-Neuguinea',
 			'PH' => 'Filipiny',
 			'PK' => 'Pakistan',
 			'PL' => 'Pólska',
 			'PM' => 'St. Pierre a Miquelon',
 			'PN' => 'Pitcairnowe kupy',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinski awtonomny teritorium',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalska',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'wenkowna Oceaniska',
 			'RE' => 'Réunion',
 			'RO' => 'Rumuńska',
 			'RS' => 'Serbiska',
 			'RU' => 'Ruska',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabiska',
 			'SB' => 'Salomony',
 			'SC' => 'Seychelle',
 			'SD' => 'Sudan',
 			'SE' => 'Šwedska',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Słowjeńska',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Słowakska',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinamska',
 			'SS' => 'Pódpołdnjowy Sudan',
 			'ST' => 'São Tomé a Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syriska',
 			'SZ' => 'Swasiska',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks a Caicos kupy',
 			'TD' => 'Čad',
 			'TF' => 'Francojski pódpołdnjowy a antarktiski teritorium',
 			'TG' => 'Togo',
 			'TH' => 'Thailandska',
 			'TJ' => 'Tadźikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Pódzajtšny Timor',
 			'TM' => 'Turkmeniska',
 			'TN' => 'Tuneziska',
 			'TO' => 'Tonga',
 			'TR' => 'Turkojska',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansanija',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ameriska Oceaniska',
 			'US' => 'Zjadnośone staty Ameriki',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikańske město',
 			'VC' => 'St. Vincent a Grenadiny',
 			'VE' => 'Venezuela',
 			'VG' => 'Britiske kněžniske kupy',
 			'VI' => 'Ameriske kněžniske kupy',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosowo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Pódpołdnjowa Afrika (Republika)',
 			'ZM' => 'Sambija',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'njeznaty region',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'kalender',
 			'collation' => 'sortěrowański slěd',
 			'currency' => 'pjenjeze',
 			'numbers' => 'licby',

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
 				'buddhist' => q{buddhistiski kalender},
 				'chinese' => q{chinski kalender},
 				'dangi' => q{dangi kalender},
 				'ethiopic' => q{etiopiski kalender},
 				'gregorian' => q{gregoriański kalender},
 				'hebrew' => q{žydojski kalender},
 				'islamic' => q{islamski kalender},
 				'iso8601' => q{iso-8601-kalender},
 				'japanese' => q{japański kalender},
 				'persian' => q{persiski kalender},
 				'roc' => q{kalender republiki China},
 			},
 			'collation' => {
 				'ducet' => q{sortěrowański slěd pó Unicoźe},
 				'search' => q{powšykne pytanje},
 				'standard' => q{standardny sortěrowański slěd},
 			},
 			'numbers' => {
 				'arab' => q{arabisko-indiske cyfry},
 				'arabext' => q{rozšyrjone arabisko-indiske cyfry},
 				'armn' => q{armeńske cyfry},
 				'armnlow' => q{armeńske cyfry małopisane},
 				'beng' => q{bengalske cyfry},
 				'deva' => q{devanagari-cyfry},
 				'ethi' => q{etiopiske cyfry},
 				'fullwide' => q{połnošyroke cyfry},
 				'geor' => q{georgiske cyfry},
 				'grek' => q{grichiske cyfry},
 				'greklow' => q{grichiske cyfry małopisane},
 				'gujr' => q{gujarati-cyfry},
 				'guru' => q{gurmukhi-cyfry},
 				'hanidec' => q{chinske decimalne licby},
 				'hans' => q{zjadnorjone chinske cyfry},
 				'hansfin' => q{zjadnorjone chinske financne cyfry},
 				'hant' => q{tradicionalne chinske cyfry},
 				'hantfin' => q{tradicionalne chinske financne cyfry},
 				'hebr' => q{hebrejske cyfry},
 				'jpan' => q{japańske cyfry},
 				'jpanfin' => q{japańske financne cyfry},
 				'khmr' => q{khmerske cyfry},
 				'knda' => q{kannada-cyfry},
 				'laoo' => q{laotiske cyfry},
 				'latn' => q{arabiske cyfry},
 				'mlym' => q{malayalamske cyfry},
 				'mymr' => q{burmaske cyfry},
 				'orya' => q{oriya-cyfry},
 				'roman' => q{romske cyfry},
 				'romanlow' => q{romske cyfry małopisane},
 				'taml' => q{tradicionalne tamilske cyfry},
 				'tamldec' => q{tamilske cyfry},
 				'telu' => q{telugu-cyfry},
 				'thai' => q{thaiske cyfry},
 				'tibt' => q{tibetske cyfry},
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
			'metric' => q{metriski},
 			'UK' => q{britiski},
 			'US' => q{ameriski},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Rěc: {0}',
 			'script' => 'Pismo: {0}',
 			'region' => 'Region: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[á à ă â å ä ã ą ā æ ç ď đ é è ĕ ê ë ė ę ē ğ í ì ĭ î ï İ ī ı ĺ ľ ň ñ ò ŏ ô ö ő ø ō œ ř ş ß ť ú ù ŭ û ů ü ű ū ý ÿ ż]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'E', 'F', 'G', 'H', '{Ch}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Ś', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ź'],
			main => qr{[a b c č ć d e ě f g h {ch} i j k ł l m n ń o ó p q r ŕ s š ś t u v w x y z ž ź]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'E', 'F', 'G', 'H', '{Ch}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Ś', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ź'], };
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
						'few' => q({0} akry),
						'name' => q(akry),
						'one' => q({0} aker),
						'other' => q({0} akrow),
						'two' => q({0} akra),
					},
					'acre-foot' => {
						'few' => q({0} aker-crjeje),
						'name' => q(aker-crjeje),
						'one' => q({0} aker-crjej),
						'other' => q({0} aker-crjej),
						'two' => q({0} aker-crjeja),
					},
					'ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} ampera),
					},
					'arc-minute' => {
						'few' => q({0} wobłukowe minuty),
						'name' => q(wobłukowe minuty),
						'one' => q({0} wobłukowa minuta),
						'other' => q({0} wobłukowych minutow),
						'two' => q({0} wobłukowej minuśe),
					},
					'arc-second' => {
						'few' => q({0} wobłukowe sekundy),
						'name' => q(wobłukowe sekundy),
						'one' => q({0} wobłukowa sekunda),
						'other' => q({0} wobłukowych sekundow),
						'two' => q({0} wobłukowej sekunźe),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomiske jadnotki),
						'name' => q(astronomiske jadnotki),
						'one' => q({0} astronomiska jadnotka),
						'other' => q({0} astronomiskich jadnotkow),
						'two' => q({0} astronomiskej jadnotce),
					},
					'bit' => {
						'few' => q({0} bity),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bita),
					},
					'byte' => {
						'few' => q({0} bytey),
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} bytea),
					},
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijow),
						'two' => q({0} kaloriji),
					},
					'carat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					'celsius' => {
						'few' => q({0} stopnje celsiusa),
						'name' => q(stopnje celsiusa),
						'one' => q({0} stopjeń celsiusa),
						'other' => q({0} stopnjow celsiusa),
						'two' => q({0} stopnja celsiusa),
					},
					'centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitra),
					},
					'centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'two' => q({0} centimetra),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'two' => q({0} kubiknej centimetra),
					},
					'cubic-foot' => {
						'few' => q({0} kubikne crjeje),
						'name' => q(kubikne crjeje),
						'one' => q({0} kubikny crjej),
						'other' => q({0} kubiknych crjejow),
						'two' => q({0} kubiknej crjeja),
					},
					'cubic-inch' => {
						'few' => q({0} kubikne cole),
						'name' => q(kubikne cole),
						'one' => q({0} kubikny col),
						'other' => q({0} kubiknych colow),
						'two' => q({0} kubiknej cola),
					},
					'cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometra),
					},
					'cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'two' => q({0} kubiknej metra),
					},
					'cubic-mile' => {
						'few' => q({0} kubikne mile),
						'name' => q(kubikne mile),
						'one' => q({0} kubikna mila),
						'other' => q({0} kubiknych milow),
						'two' => q({0} kubiknej mili),
					},
					'cubic-yard' => {
						'few' => q({0} kubikne yardy),
						'name' => q(kubikne yardy),
						'one' => q({0} kubikny yard),
						'other' => q({0} kubiknych yardow),
						'two' => q({0} kubiknej yarda),
					},
					'cup' => {
						'few' => q({0} taski),
						'name' => q(taski),
						'one' => q({0} taska),
						'other' => q({0} taskow),
						'two' => q({0} tasce),
					},
					'day' => {
						'few' => q({0} dny),
						'name' => q(dny),
						'one' => q({0} źeń),
						'other' => q({0} dnjow),
						'two' => q({0} dnja),
					},
					'deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitra),
					},
					'decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetra),
					},
					'degree' => {
						'few' => q({0} stopnje),
						'name' => q(wobłukowe stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopjenja),
					},
					'fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnja Fahrenheita),
					},
					'fluid-ounce' => {
						'few' => q({0} žydke unce),
						'name' => q(žydke unce),
						'one' => q({0} žydka unca),
						'other' => q({0} žydkych uncow),
						'two' => q({0} žydkej uncy),
					},
					'foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					'foot' => {
						'few' => q({0} crjeje),
						'name' => q(stopy),
						'one' => q({0} crjej),
						'other' => q({0} crjej),
						'two' => q({0} crjeja),
					},
					'g-force' => {
						'few' => q({0} jadnotki zemskego póspěšenja),
						'name' => q(jadnotki zemskego póspěšenja),
						'one' => q({0} jadnotka zemskego póspěšenja),
						'other' => q({0} jadnotkow zemskego póspěšenja),
						'two' => q({0} jadnotce zemskego póspěšenja),
					},
					'gallon' => {
						'few' => q({0} gallony),
						'name' => q(gallony),
						'one' => q({0} gallona),
						'other' => q({0} gallonow),
						'two' => q({0} gallonje),
					},
					'gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabita),
					},
					'gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabytea),
					},
					'gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertza),
					},
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawatta),
					},
					'gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'two' => q({0} grama),
					},
					'hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektara),
					},
					'hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitra),
					},
					'hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascala),
					},
					'hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertza),
					},
					'horsepower' => {
						'few' => q({0} kónjece mócy),
						'name' => q(kónjece mócy),
						'one' => q({0} kónjeca móc),
						'other' => q({0} kónjecych mócow),
						'two' => q({0} kónjecej mócy),
					},
					'hour' => {
						'few' => q({0} góźiny),
						'name' => q(góźiny),
						'one' => q({0} góźina),
						'other' => q({0} góźinow),
						'per' => q({0} na góźinu),
						'two' => q({0} góźinje),
					},
					'inch' => {
						'few' => q({0} cole),
						'name' => q(cole),
						'one' => q({0} col),
						'other' => q({0} colow),
						'two' => q({0} cola),
					},
					'inch-hg' => {
						'few' => q({0} cole słupika žywego slobra),
						'name' => q(cole žywoslobrowego słupika),
						'one' => q({0} col słupika žywego slobra),
						'other' => q({0} colow słupika žywego slobra),
						'two' => q({0} cola słupika žywego slobra),
					},
					'joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} joule),
					},
					'karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					'kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnja Kelvina),
					},
					'kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobita),
					},
					'kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobytea),
					},
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					'kilogram' => {
						'few' => q({0} kilogramy),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramow),
						'two' => q({0} kilograma),
					},
					'kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertza),
					},
					'kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
						'two' => q({0} kilojoule),
					},
					'kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'two' => q({0} kilometra),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometry na góźinu),
						'name' => q(kilometry na góźinu),
						'one' => q({0} kilometer na góźinu),
						'other' => q({0} kilometrow na góźinu),
						'two' => q({0} kilometra na góźinu),
					},
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowatta),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilowattowe góźiny),
						'name' => q(kilowattowe góźiny),
						'one' => q({0} kilowattowa góźina),
						'other' => q({0} kilowattowych góźin),
						'two' => q({0} kilowattowej góźinje),
					},
					'light-year' => {
						'few' => q({0} swětłowe lěta),
						'name' => q(swětłowe lěta),
						'one' => q({0} swětłowe lěto),
						'other' => q({0} swětłowych lět),
						'two' => q({0} swětłowej lěśe),
					},
					'liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'two' => q({0} litra),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litra na kilometer),
					},
					'lux' => {
						'few' => q({0} lux),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					'megabit' => {
						'few' => q({0} megabity),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabita),
					},
					'megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabytea),
					},
					'megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertza),
					},
					'megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitra),
					},
					'megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawatta),
					},
					'meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'two' => q({0} metra),
					},
					'meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metra na sekundu),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow kwadratnu sekundu),
						'two' => q({0} metra na kwadratnu sekundu),
					},
					'metric-ton' => {
						'few' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} tonow),
						'two' => q({0} tonje),
					},
					'microgram' => {
						'few' => q({0} mikrogramy),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramow),
						'two' => q({0} mikrograma),
					},
					'micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometra),
					},
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekunźe),
					},
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					'mile-per-gallon' => {
						'few' => q({0} mile na gallonu),
						'name' => q(mile na gallonu),
						'one' => q({0} mila na gallonu),
						'other' => q({0} milow na gallonu),
						'two' => q({0} mili na gallonu),
					},
					'mile-per-hour' => {
						'few' => q({0} mile na góźinu),
						'name' => q(mile na góźinu),
						'one' => q({0} mila na góźinu),
						'other' => q({0} milow na góźinu),
						'two' => q({0} mili na góźinu),
					},
					'milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliampera),
					},
					'millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibara),
					},
					'milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligrama),
					},
					'milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitra),
					},
					'millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetra),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetry słupika žywego slobra),
						'name' => q(milimetry słupika žywego slobra),
						'one' => q({0} milimeter słupika žywego slobra),
						'other' => q({0} milimetrow słupika žywego slobra),
						'two' => q({0} milimetra słupika žywego slobra),
					},
					'millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekunźe),
					},
					'milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwatta),
					},
					'minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'two' => q({0} minuśe),
					},
					'month' => {
						'few' => q({0} mjasecy),
						'name' => q(mjasecy),
						'one' => q({0} mjasec),
						'other' => q({0} mjasecow),
						'two' => q({0} mjaseca),
					},
					'nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometra),
					},
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekunźe),
					},
					'nautical-mile' => {
						'few' => q({0} nawtiske mile),
						'name' => q(nawtiske mile),
						'one' => q({0} nawtiska mila),
						'other' => q({0} nawtiskich milow),
						'two' => q({0} nawtiskej mili),
					},
					'ohm' => {
						'few' => q({0} ohmy),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohma),
					},
					'ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'two' => q({0} uncy),
					},
					'ounce-troy' => {
						'few' => q({0} troyske unce),
						'name' => q(troyske unce),
						'one' => q({0} troyska unca),
						'other' => q({0} troyskich uncow),
						'two' => q({0} troyskej uncy),
					},
					'parsec' => {
						'few' => q({0} parsec),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} parsec),
					},
					'picometer' => {
						'few' => q({0} pikometry),
						'name' => q(pikometry),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrow),
						'two' => q({0} pikometra),
					},
					'pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pinta),
					},
					'pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'two' => q({0} punta),
					},
					'pound-per-square-inch' => {
						'few' => q({0} punty na kwadratny col),
						'name' => q(punty na kwadratny col),
						'one' => q({0} punt na kwadratny col),
						'other' => q({0} puntow na kwadratny col),
						'two' => q({0} punta na kwadratny col),
					},
					'quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quarta),
					},
					'radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radianta),
					},
					'second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekunźe),
					},
					'square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'two' => q({0} kwadratnej centimetra),
					},
					'square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					'square-inch' => {
						'few' => q({0} kwadratne cole),
						'name' => q(kwadratne cole),
						'one' => q({0} kwadratny col),
						'other' => q({0} kwadratnych colow),
						'two' => q({0} kwadratnej cola),
					},
					'square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'two' => q({0} kwadratnej kilometra),
					},
					'square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'two' => q({0} kwadratnej metra),
					},
					'square-mile' => {
						'few' => q({0} kwadratne mile),
						'name' => q(kwadratne mile),
						'one' => q({0} kwadratna mila),
						'other' => q({0} kwadratnych milow),
						'two' => q({0} kwadratnej mili),
					},
					'square-yard' => {
						'few' => q({0} kwadratne yardy),
						'name' => q(kwadratne yardy),
						'one' => q({0} kwadratny yard),
						'other' => q({0} kwadratnych yardow),
						'two' => q({0} kwadratnej yarda),
					},
					'tablespoon' => {
						'few' => q({0} łžyce),
						'name' => q(łžyce),
						'one' => q({0} łžyca),
						'other' => q({0} łžycow),
						'two' => q({0} łžycy),
					},
					'teaspoon' => {
						'few' => q({0} łžycki),
						'name' => q(łžycki),
						'one' => q({0} łžycka),
						'other' => q({0} łžyckow),
						'two' => q({0} łžycce),
					},
					'terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabita),
					},
					'terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabytea),
					},
					'ton' => {
						'few' => q({0} ameriske tony),
						'name' => q(ameriske tony),
						'one' => q({0} ameriska tona),
						'other' => q({0} ameriskich tonow),
						'two' => q({0} ameriskej tonje),
					},
					'volt' => {
						'few' => q({0} volty),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltow),
						'two' => q({0} volta),
					},
					'watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} watta),
					},
					'week' => {
						'few' => q({0} tyźenje),
						'name' => q(tyźenje),
						'one' => q({0} tyźeń),
						'other' => q({0} tyźenjow),
						'two' => q({0} tyźenja),
					},
					'yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yarda),
					},
					'year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'two' => q({0} lěśe),
					},
				},
				'narrow' => {
					'acre' => {
						'few' => q({0} ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'two' => q({0} cm),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} ź),
						'other' => q({0} d),
						'two' => q({0} d),
					},
					'degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					'foot' => {
						'few' => q({0} ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'two' => q({0} ft),
					},
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					'horsepower' => {
						'few' => q({0} PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					'hour' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					'inch' => {
						'few' => q({0} in),
						'one' => q({0} in),
						'other' => q({0} in),
						'two' => q({0} in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'two' => q({0} kg),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'two' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					'light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'two' => q({0} l),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'two' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					'mile' => {
						'few' => q({0} mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-hour' => {
						'few' => q({0} mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'two' => q({0} min),
					},
					'month' => {
						'few' => q({0} mjas.),
						'name' => q(mjas.),
						'one' => q({0} mjas.),
						'other' => q({0} mjas.),
						'two' => q({0} mjas.),
					},
					'ounce' => {
						'few' => q({0} oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'two' => q({0} oz),
					},
					'picometer' => {
						'few' => q({0} pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'two' => q({0} lb),
					},
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'two' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'two' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					'week' => {
						'few' => q({0} tyź.),
						'name' => q(tyź.),
						'one' => q({0} tyź.),
						'other' => q({0} tyź.),
						'two' => q({0} tyź.),
					},
					'yard' => {
						'few' => q({0} yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'two' => q({0} l.),
					},
				},
				'short' => {
					'acre' => {
						'few' => q({0} ac),
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
						'two' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
						'two' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0} ′),
						'name' => q(′),
						'one' => q({0} ′),
						'other' => q({0} ′),
						'two' => q({0} ′),
					},
					'arc-second' => {
						'few' => q({0} ″),
						'name' => q(″),
						'one' => q({0} ″),
						'other' => q({0} ″),
						'two' => q({0} ″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
						'two' => q({0} au),
					},
					'bit' => {
						'few' => q({0} bit),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} bit),
					},
					'byte' => {
						'few' => q({0} byte),
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
						'two' => q({0} byte),
					},
					'calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} Kt),
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
						'two' => q({0} Kt),
					},
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'two' => q({0} cm),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'two' => q({0} cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
						'two' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
						'two' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'two' => q({0} m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
						'two' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
						'two' => q({0} c),
					},
					'day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} ź.),
						'other' => q({0} dn.),
						'two' => q({0} dn.),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					'degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					'fluid-ounce' => {
						'few' => q({0} fl. oz.),
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
						'two' => q({0} fl. oz.),
					},
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'two' => q({0} ft),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'two' => q({0} gal),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
						'two' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
						'two' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
						'two' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
						'two' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
						'two' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} PS),
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					'hour' => {
						'few' => q({0} góź.),
						'name' => q(góź.),
						'one' => q({0} góź.),
						'other' => q({0} góź.),
						'per' => q({0}/h),
						'two' => q({0} góź.),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'two' => q({0} in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'two' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
						'two' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
						'two' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
						'two' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
						'two' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'two' => q({0} kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
						'two' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
						'two' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'two' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
						'two' => q({0} kWh),
					},
					'light-year' => {
						'few' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'two' => q({0} l),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
						'two' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
						'two' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
						'two' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
						'two' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
						'two' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'two' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
						'two' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} μm),
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
						'two' => q({0} μm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					'mile-per-hour' => {
						'few' => q({0} mph),
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
						'two' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
						'two' => q({0} mm Hg),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
						'two' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'two' => q({0} min.),
					},
					'month' => {
						'few' => q({0} mjas.),
						'name' => q(mjas.),
						'one' => q({0} mjas.),
						'other' => q({0} mjas.),
						'two' => q({0} mjas.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
						'two' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
						'two' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'two' => q({0} oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz. tr.),
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
						'two' => q({0} oz. tr.),
					},
					'parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
						'two' => q({0} pc),
					},
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'two' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
						'two' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
						'two' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
						'two' => q({0} rad),
					},
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/s),
						'two' => q({0} sek.),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'two' => q({0} cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'two' => q({0} in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'two' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'two' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
						'two' => q({0} yd²),
					},
					'tablespoon' => {
						'few' => q({0} łž.),
						'name' => q(łž.),
						'one' => q({0} łž.),
						'other' => q({0} łž.),
						'two' => q({0} łž.),
					},
					'teaspoon' => {
						'few' => q({0} łžk.),
						'name' => q(łžk.),
						'one' => q({0} łžk.),
						'other' => q({0} łžk.),
						'two' => q({0} łžk.),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
						'two' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
						'two' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} tn),
						'name' => q(am.tony),
						'one' => q({0} tn),
						'other' => q({0} tn),
						'two' => q({0} tn),
					},
					'volt' => {
						'few' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
						'two' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					'week' => {
						'few' => q({0} tyź.),
						'name' => q(tyź.),
						'one' => q({0} tyź.),
						'other' => q({0} tyź.),
						'two' => q({0} tyź.),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'two' => q({0} l.),
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
	default		=> sub { qr'^(?i:ně|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} a {1}),
				2 => q({0}, {1}),
		} }
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
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(·),
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
					'few' => '0 tys'.'',
					'one' => '0 tys'.'',
					'other' => '0 tys'.'',
					'two' => '0 tys'.'',
				},
				'10000' => {
					'few' => '00 tys'.'',
					'one' => '00 tys'.'',
					'other' => '00 tys'.'',
					'two' => '00 tys'.'',
				},
				'100000' => {
					'few' => '000 tys'.'',
					'one' => '000 tys'.'',
					'other' => '000 tys'.'',
					'two' => '000 tys'.'',
				},
				'1000000' => {
					'few' => '0 mio'.'',
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
					'two' => '0 mio'.'',
				},
				'10000000' => {
					'few' => '00 mio'.'',
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
					'two' => '00 mio'.'',
				},
				'100000000' => {
					'few' => '000 mio'.'',
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
					'two' => '000 mio'.'',
				},
				'1000000000' => {
					'few' => '0 mrd'.'',
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
					'two' => '0 mrd'.'',
				},
				'10000000000' => {
					'few' => '00 mrd'.'',
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
					'two' => '00 mrd'.'',
				},
				'100000000000' => {
					'few' => '000 mrd'.'',
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
					'two' => '000 mrd'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
					'two' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
					'two' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
					'two' => '000 bil'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'few' => '0 tysac',
					'one' => '0 tysac',
					'other' => '0 tysac',
					'two' => '0 tysac',
				},
				'10000' => {
					'few' => '00 tysac',
					'one' => '00 tysac',
					'other' => '00 tysac',
					'two' => '00 tysac',
				},
				'100000' => {
					'few' => '000 tysac',
					'one' => '000 tysac',
					'other' => '000 tysac',
					'two' => '000 tysac',
				},
				'1000000' => {
					'few' => '0 miliony',
					'one' => '0 milion',
					'other' => '0 milionow',
					'two' => '0 miliona',
				},
				'10000000' => {
					'few' => '00 milionow',
					'one' => '00 milionow',
					'other' => '00 milionow',
					'two' => '00 milionow',
				},
				'100000000' => {
					'few' => '000 milionow',
					'one' => '000 milionow',
					'other' => '000 milionow',
					'two' => '000 milionow',
				},
				'1000000000' => {
					'few' => '0 miliardy',
					'one' => '0 miliarda',
					'other' => '0 miliardow',
					'two' => '0 miliarźe',
				},
				'10000000000' => {
					'few' => '00 miliardow',
					'one' => '00 miliardow',
					'other' => '00 miliardow',
					'two' => '00 miliardow',
				},
				'100000000000' => {
					'few' => '000 miliardow',
					'one' => '000 miliardow',
					'other' => '000 miliardow',
					'two' => '000 miliardow',
				},
				'1000000000000' => {
					'few' => '0 biliony',
					'one' => '0 bilion',
					'other' => '0 bilionow',
					'two' => '0 biliona',
				},
				'10000000000000' => {
					'few' => '00 bilionow',
					'one' => '00 bilionow',
					'other' => '00 bilionow',
					'two' => '00 bilionow',
				},
				'100000000000000' => {
					'few' => '000 bilionow',
					'one' => '000 bilionow',
					'other' => '000 bilionow',
					'two' => '000 bilionow',
				},
			},
			'short' => {
				'1000' => {
					'few' => '0 tys'.'',
					'one' => '0 tys'.'',
					'other' => '0 tys'.'',
					'two' => '0 tys'.'',
				},
				'10000' => {
					'few' => '00 tys'.'',
					'one' => '00 tys'.'',
					'other' => '00 tys'.'',
					'two' => '00 tys'.'',
				},
				'100000' => {
					'few' => '000 tys'.'',
					'one' => '000 tys'.'',
					'other' => '000 tys'.'',
					'two' => '000 tys'.'',
				},
				'1000000' => {
					'few' => '0 mio'.'',
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
					'two' => '0 mio'.'',
				},
				'10000000' => {
					'few' => '00 mio'.'',
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
					'two' => '00 mio'.'',
				},
				'100000000' => {
					'few' => '000 mio'.'',
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
					'two' => '000 mio'.'',
				},
				'1000000000' => {
					'few' => '0 mrd'.'',
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
					'two' => '0 mrd'.'',
				},
				'10000000000' => {
					'few' => '00 mrd'.'',
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
					'two' => '00 mrd'.'',
				},
				'100000000000' => {
					'few' => '000 mrd'.'',
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
					'two' => '000 mrd'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
					'two' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
					'two' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
					'two' => '000 bil'.'',
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
				'currency' => q(andorraska peseta),
				'few' => q(andorraske pesety),
				'one' => q(andorraska peseta),
				'other' => q(andorraskich pesetow),
				'two' => q(andorraskej peseśe),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(ZAE dirham),
				'few' => q(SAE dirhamy),
				'one' => q(ZAE dirham),
				'other' => q(SAE dirhamow),
				'two' => q(ZAE dirhama),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghaniski afgani),
				'few' => q(afghaniske afganije),
				'one' => q(afghaniski afgani),
				'other' => q(afghaniskich afganijow),
				'two' => q(afghaniskej afganija),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albański lek),
				'few' => q(albańske leki),
				'one' => q(albański lek),
				'other' => q(albańskich lekow),
				'two' => q(albańskej leka),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armeński dram),
				'few' => q(armeńske dramy),
				'one' => q(armeński dram),
				'other' => q(armeńskich dramow),
				'two' => q(armeńskej drama),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nižozemsko-antilski gulden),
				'few' => q(nižozemskoantilske guldeny),
				'one' => q(nižozemskoantilski gulden),
				'other' => q(nižozemskoantilskich guldenow),
				'two' => q(nižozemskoantilskej guldena),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolska kwanza),
				'few' => q(angolske kwanze),
				'one' => q(angolska kwanza),
				'other' => q(angolskich kwanzow),
				'two' => q(angolskej kwanzy),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolska kwanza \(1977–1990\)),
				'few' => q(angolske kwanze \(1977–1990\)),
				'one' => q(angolska kwanza \(1977–1990\)),
				'other' => q(angolskich kwanzow \(1977–1990\)),
				'two' => q(angolskej kwanzy \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolska nowa kwanza \(1990–2000\)),
				'few' => q(angolske nowe kwanze \(1990–2000\)),
				'one' => q(angolska nowa kwanza \(1990–2000\)),
				'other' => q(angolskich nowych kwanzow \(1990–2000\)),
				'two' => q(angolskej nowej kwanzy \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolska kwanza reajustado \(1995–1999\)),
				'few' => q(angolske kwanze reajustado \(1995–1999\)),
				'one' => q(angolska kwanza reajustado \(1995–1999\)),
				'other' => q(angolskich kwanzow reajustado \(1995–1999\)),
				'two' => q(angolskej kwanzy reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinski austral),
				'few' => q(argentinske australy),
				'one' => q(argentinski austral),
				'other' => q(argentinskich australow),
				'two' => q(argentinskej australa),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinski peso \(1983–1985\)),
				'few' => q(argentinske peso \(1983–1985\)),
				'one' => q(argentinski peso \(1983–1985\)),
				'other' => q(argentinskich peso \(1983–1985\)),
				'two' => q(argentinskej peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinski peso),
				'few' => q(argentinske peso),
				'one' => q(argentinski peso),
				'other' => q(argentinskich peso),
				'two' => q(argentinskej peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(rakuski šiling),
				'few' => q(rakuske šilingi),
				'one' => q(rakuski šiling),
				'other' => q(rakuskich šilingow),
				'two' => q(rakuskej šilinga),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(awstralski dolar),
				'few' => q(awstralske dolary),
				'one' => q(awstralski dolar),
				'other' => q(awstralskich dolarow),
				'two' => q(awstralskej dolara),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(aruba-florin),
				'few' => q(aruba-floriny),
				'one' => q(aruba-florin),
				'other' => q(aruba-florinow),
				'two' => q(aruba-florina),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdžaniski manat \(1993–2006\)),
				'few' => q(azerbajdžaniske manaty \(1993–2006\)),
				'one' => q(azerbajdžaniski manat \(1993–2006\)),
				'other' => q(azerbajdžaniskich manatow \(1993–2006\)),
				'two' => q(azerbajdžaniskej manata \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdžaniski manat),
				'few' => q(azerbajdžaniske manaty),
				'one' => q(azerbajdžaniski manat),
				'other' => q(azerbajdžaniskich manatow),
				'two' => q(azerbajdžaniskej manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosniski dinar),
				'few' => q(bosniske dinary),
				'one' => q(bosniski dinar),
				'other' => q(bosniskich dinarow),
				'two' => q(bosniskej dinara),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosniska konwertibelna marka),
				'few' => q(bosniske konwertibelne marki),
				'one' => q(bosniska konwertibelna marka),
				'other' => q(bosniskich konwertibelnych markow),
				'two' => q(bosniskej konwertibelnej marce),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoski dolar),
				'few' => q(barbadoske dolary),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskich dolarow),
				'two' => q(barbadoskej dolara),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladešska taka),
				'few' => q(bangladešske taki),
				'one' => q(bangladešska taka),
				'other' => q(bangladešskich takow),
				'two' => q(bangladešskej tace),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgiski frank \(konwertibelny\)),
				'few' => q(belgiske franki \(konwertibelne\)),
				'one' => q(belgiski frank \(konwertibelny\)),
				'other' => q(belgiskich frankow \(konwertibelnych\)),
				'two' => q(belgiskej franka \(konwertibelnej\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgiski frank),
				'few' => q(belgiske franki),
				'one' => q(belgiski frank),
				'other' => q(belgiskich frankow),
				'two' => q(belgiskej franka),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiski financny frank),
				'few' => q(belgiske financne franki),
				'one' => q(belgiski financny frank),
				'other' => q(belgiskich financnych frankow),
				'two' => q(belgiskej financnej franka),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarski lew \(1962–1999\)),
				'few' => q(bulgarske lewy \(1962–1999\)),
				'one' => q(bulgarski lew \(1962–1999\)),
				'other' => q(bulgarskich lewow \(1962–1999\)),
				'two' => q(bulgarskej lewa \(1962–1999\)),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bulgarski lew),
				'few' => q(bulgarske lewy),
				'one' => q(bulgarski lew),
				'other' => q(bulgarskich lewow),
				'two' => q(bulgarskej lewa),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainski dinar),
				'few' => q(bahrainske dinary),
				'one' => q(bahrainski dinar),
				'other' => q(bahrainskich dinarow),
				'two' => q(bahrainskej dinara),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiski frank),
				'few' => q(burundiske franki),
				'one' => q(burundiski frank),
				'other' => q(burundiskich frankow),
				'two' => q(burundiskej franka),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudaski dolar),
				'few' => q(bermudaske dolary),
				'one' => q(bermudaski dolar),
				'other' => q(bermudaskich dolarow),
				'two' => q(bermudaskej dolara),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiski dolar),
				'few' => q(bruneiske dolary),
				'one' => q(bruneiski dolar),
				'other' => q(bruneiskich dolarow),
				'two' => q(bruneiskej dolara),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliwiski boliviano),
				'few' => q(boliwiske boliviana),
				'one' => q(boliwiski boliviano),
				'other' => q(boliwiskich bolivianow),
				'two' => q(boliwiskej bolivianje),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliwiski peso),
				'few' => q(boliwiske peso),
				'one' => q(boliwiski peso),
				'other' => q(boliwiskich peso),
				'two' => q(boliwiskej peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliwiski mvdol),
				'few' => q(boliwiske mvdole),
				'one' => q(boliwiski mvdol),
				'other' => q(boliwiskich mvdolow),
				'two' => q(boliwiskej mvdola),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'few' => q(brazilske nowe cruzeiry \(1967–1986\)),
				'one' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'other' => q(brazilskich nowych cruzeirow \(1967–1986\)),
				'two' => q(brazilskej nowej cruzeira \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilski cruzado \(1986–1989\)),
				'few' => q(brazilske cruzada \(1986–1989\)),
				'one' => q(brazilski cruzado \(1986–1989\)),
				'other' => q(brazilskich cruzadow \(1986–1989\)),
				'two' => q(brazilskej cruzaźe \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1990–1993\)),
				'few' => q(brazilske cruzeira \(1990–1993\)),
				'one' => q(brazilski cruzeiro \(1990–1993\)),
				'other' => q(brazilskich cruzeirow \(1990–1993\)),
				'two' => q(brazilskej cruzeirje \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilske reale),
				'one' => q(brazilski real),
				'other' => q(brazilskich realow),
				'two' => q(brazilskej reala),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilski nowy cruzado \(1989–1990\)),
				'few' => q(brazilske nowe cruzada),
				'one' => q(brazilski nowy cruzado \(1989–1990\)),
				'other' => q(brazilskich nowych cruzadow),
				'two' => q(brazilskej nowej cruzaźe \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1993–1994\)),
				'few' => q(brazilske cruzeira \(1993–1994\)),
				'one' => q(brazilski cruzeiro \(1993–1994\)),
				'other' => q(brazilskich cruzeirow \(1993–1994\)),
				'two' => q(brazilskej cruzeirje \(1993–1994\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamaski dolar),
				'few' => q(bahamaske dolary),
				'one' => q(bahamaski dolar),
				'other' => q(bahamaskich dolarow),
				'two' => q(bahamaskej dolara),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutański ngultrum),
				'few' => q(bhutańske ngultrumy),
				'one' => q(bhutański ngultrum),
				'other' => q(bhutańskich ngultrumow),
				'two' => q(bhutańskej ngultruma),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmaski kyat),
				'few' => q(burmaske kyaty),
				'one' => q(burmaski kyat),
				'other' => q(burmaskich kyatow),
				'two' => q(burmaskej kyata),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswaniska pula),
				'few' => q(botswaniske pule),
				'one' => q(botswaniska pula),
				'other' => q(botswaniskich pulow),
				'two' => q(botswaniskej puli),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(běłoruski rubl \(1994–1999\)),
				'few' => q(běłoruske ruble \(1994–1999\)),
				'one' => q(běłoruski rubl \(1994–1999\)),
				'other' => q(běłoruskich rublow \(1994–1999\)),
				'two' => q(běłoruskej rubla \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(běłoruski rubl),
				'few' => q(běłoruske ruble),
				'one' => q(běłoruski rubl),
				'other' => q(běłoruskich rublow),
				'two' => q(běłoruskej rubla),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(běłoruski rubl \(2000–2016\)),
				'few' => q(běłoruske ruble \(2000–2016\)),
				'one' => q(běłoruski rubl \(2000–2016\)),
				'other' => q(běłoruskich rublow \(2000–2016\)),
				'two' => q(běłoruskej rubla \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizeski dolar),
				'few' => q(belizeske dolary),
				'one' => q(belizeski dolar),
				'other' => q(belizeskich dolarow),
				'two' => q(belizeskej dolara),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(kanadiski dolar),
				'few' => q(kanadiske dolary),
				'one' => q(kanadiski dolar),
				'other' => q(kanadiskich dolarow),
				'two' => q(kanadiskej dolara),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoski frank),
				'few' => q(kongoske franki),
				'one' => q(kongoski frank),
				'other' => q(kongoskich frankow),
				'two' => q(kongoskej franka),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(šwicarski frank),
				'few' => q(šwicarske franki),
				'one' => q(šwicarski frank),
				'other' => q(šwicarskich frankow),
				'two' => q(šwicarskej franka),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilski peso),
				'few' => q(chilske peso),
				'one' => q(chilski peso),
				'other' => q(chilskich peso),
				'two' => q(chilskej peso),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(chinski yuan),
				'few' => q(chinske yuany),
				'one' => q(chinski yuan),
				'other' => q(chinskich yuanow),
				'two' => q(chinskej yuana),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbiski peso),
				'few' => q(kolumbiske peso),
				'one' => q(kolumbiski peso),
				'other' => q(kolumbiskich peso),
				'two' => q(kolumbiskej peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kosta-rikański colón),
				'few' => q(kosta-rikańske colóny),
				'one' => q(kosta-rikański colón),
				'other' => q(kosta-rikańskich colónow),
				'two' => q(kosta-rikańskej colóna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubański konwertibelny peso),
				'few' => q(kubańske konwertibelne peso),
				'one' => q(kubański konwertibelny peso),
				'other' => q(kubańskich konwertibelnych peso),
				'two' => q(kubańskej konwertibelnej peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubański peso),
				'few' => q(kubańske peso),
				'one' => q(kubański peso),
				'other' => q(kubańskich peso),
				'two' => q(kubańskej peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdski escudo),
				'few' => q(kapverdske escuda),
				'one' => q(kapverdski escudo),
				'other' => q(kapverdskich escudow),
				'two' => q(kapverdskej escuźe),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(česka krona),
				'few' => q(česke krony),
				'one' => q(česka krona),
				'other' => q(českich kronow),
				'two' => q(českej kronje),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(dźibutiski frank),
				'few' => q(dźibutiske franki),
				'one' => q(dźibutiski frank),
				'other' => q(dźibutiskich frankow),
				'two' => q(dźibutiskej franka),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dańska krona),
				'few' => q(dańske krony),
				'one' => q(dańska krona),
				'other' => q(dańskich kronow),
				'two' => q(dańskej kronje),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikański peso),
				'few' => q(dominikańske peso),
				'one' => q(dominikański peso),
				'other' => q(dominikańskich peso),
				'two' => q(dominikańskej peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algeriski dinar),
				'few' => q(algeriske dinary),
				'one' => q(algeriski dinar),
				'other' => q(algeriskich dinarow),
				'two' => q(algeriskej dinara),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptojski punt),
				'few' => q(egyptojske punty),
				'one' => q(egyptojski punt),
				'other' => q(egyptojskich puntow),
				'two' => q(egyptojskej punta),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejska nakfa),
				'few' => q(eritrejske nakfy),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskich nakfow),
				'two' => q(eritrejskej nakfje),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopiski birr),
				'few' => q(etiopiske birry),
				'one' => q(etiopiski birr),
				'other' => q(etiopiskich birrow),
				'two' => q(etiopiskej birra),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'few' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
				'two' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidźiski dolar),
				'few' => q(fidźiske dolary),
				'one' => q(fidźiski dolar),
				'other' => q(fidźiskich dolarow),
				'two' => q(fidźiskej dolara),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandski punt),
				'few' => q(falklandske punty),
				'one' => q(falklandski punt),
				'other' => q(falklandskich puntow),
				'two' => q(falklandskej punta),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(britiski punt),
				'few' => q(britiske punty),
				'one' => q(britiski punt),
				'other' => q(britiskich puntow),
				'two' => q(britiskej punta),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgiski lari),
				'few' => q(georgiske lari),
				'one' => q(georgiski lari),
				'other' => q(georgiskich lari),
				'two' => q(georgiskej lari),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanaski cedi),
				'few' => q(ghanaske cedi),
				'one' => q(ghanaski cedi),
				'other' => q(ghanaskich cedi),
				'two' => q(ghanaskej cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltiski punt),
				'few' => q(gibraltiske punty),
				'one' => q(gibraltiski punt),
				'other' => q(gibraltiskich puntow),
				'two' => q(gibraltiskej punta),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiski dalasi),
				'few' => q(gambiske dalasi),
				'one' => q(gambiski dalasi),
				'other' => q(gambiskich dalasi),
				'two' => q(gambiskej dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineski frank),
				'few' => q(guineske franki),
				'one' => q(guineski frank),
				'other' => q(guineskich frankow),
				'two' => q(guineskej franka),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalski quetzal),
				'few' => q(guatemalske quetzale),
				'one' => q(guatemalski quetzal),
				'other' => q(guatemalskich quetzalow),
				'two' => q(guatemalskej quetzala),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau peso),
				'few' => q(Guinea-Bissau peso),
				'one' => q(Guinea-Bissau peso),
				'other' => q(Guinea-Bissau peso),
				'two' => q(Guinea-Bissau peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyański dolar),
				'few' => q(guyańske dolary),
				'one' => q(guyański dolar),
				'other' => q(guyańskich dolarow),
				'two' => q(guyańskej dolara),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(hongkongski dolar),
				'few' => q(hongkongske dolary),
				'one' => q(hongkongski dolar),
				'other' => q(hongkongskich dolarow),
				'two' => q(hongkongskej dolara),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraska lempira),
				'few' => q(honduraske lempiry),
				'one' => q(honduraska lempira),
				'other' => q(honduraskich lempirow),
				'two' => q(honduraskej lempirje),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(chorwatska kuna),
				'few' => q(chorwatske kuny),
				'one' => q(chorwatska kuna),
				'other' => q(chorwatskich kunow),
				'two' => q(chorwatskej kunje),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitiska gourda),
				'few' => q(haitiske gourdy),
				'one' => q(haitiska gourda),
				'other' => q(haitiskich gourdow),
				'two' => q(haitiskej gourźe),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(madźarski forint),
				'few' => q(madźarske forinty),
				'one' => q(madźarski forint),
				'other' => q(madźarskich forintow),
				'two' => q(madźarskej forinta),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indoneska rupija),
				'few' => q(indoneske rupije),
				'one' => q(indoneska rupija),
				'other' => q(indoneskich rupijow),
				'two' => q(indoneskej rupiji),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(israelski nowy šekel),
				'few' => q(israelske nowe šekele),
				'one' => q(israelski nowy šekel),
				'other' => q(israelskich nowych šekelow),
				'two' => q(israelskej nowej šekela),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indiska rupija),
				'few' => q(indiske rupije),
				'one' => q(indiska rupija),
				'other' => q(indiskich rupijow),
				'two' => q(indiskej rupiji),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakski dinar),
				'few' => q(irakske dinary),
				'one' => q(irakski dinar),
				'other' => q(irakskich dinarow),
				'two' => q(irakskej dinara),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(irański rial),
				'few' => q(irańske riale),
				'one' => q(irański rial),
				'other' => q(irańskich rialow),
				'two' => q(irańskej riala),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandska krona),
				'few' => q(islandske krony),
				'one' => q(islandska krona),
				'other' => q(islandskich kronow),
				'two' => q(islandskej kronje),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaiski dolar),
				'few' => q(jamaiske dolary),
				'one' => q(jamaiski dolar),
				'other' => q(jamaiskich dolarow),
				'two' => q(jamaiskej dolara),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordaniski dinar),
				'few' => q(jordaniske dinary),
				'one' => q(jordaniski dinar),
				'other' => q(jordaniskich dinarow),
				'two' => q(jordaniskej dinara),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japański yen),
				'few' => q(japańske yeny),
				'one' => q(japański yen),
				'other' => q(japańskich yenow),
				'two' => q(japańskej yena),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(keniaski šiling),
				'few' => q(keniaske šilingi),
				'one' => q(keniaski šiling),
				'other' => q(keniaskich šilingow),
				'two' => q(keniaskej šilinga),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiski som),
				'few' => q(kirgiske somy),
				'one' => q(kirgiski som),
				'other' => q(kirgiskich somow),
				'two' => q(kirgiskej soma),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodžaski riel),
				'few' => q(kambodžaske riele),
				'one' => q(kambodžaski riel),
				'other' => q(kambodžaskich rielow),
				'two' => q(kambodžaskej riela),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorski frank),
				'few' => q(komorske franki),
				'one' => q(komorski frank),
				'other' => q(komorskich frankow),
				'two' => q(komorskej franka),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(pódpołnocnokorejski won),
				'few' => q(pódpołnocnokorejske wony),
				'one' => q(pódpołnocnokorejski won),
				'other' => q(pódpołnocnokorejskich wonow),
				'two' => q(pódpołnocnokorejskej wona),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(pódpołdnjowokorejski won),
				'few' => q(pódpołdnjowokorejske wony),
				'one' => q(pódpołdnjowokorejski won),
				'other' => q(pódpołdnjowokorejskich wonow),
				'two' => q(pódpołdnjowokorejskej wona),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitski dinar),
				'few' => q(kuwaitske dinary),
				'one' => q(kuwaitski dinar),
				'other' => q(kuwaitskich dinarow),
				'two' => q(kuwaitskej dinara),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmaniski dolar),
				'few' => q(kajmaniske dolary),
				'one' => q(kajmaniski dolar),
				'other' => q(kajmaniskich dolarow),
				'two' => q(kajmaniskej dolara),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazachski tenge),
				'few' => q(kazachske tenge),
				'one' => q(kazachski tenge),
				'other' => q(kazachskich tenge),
				'two' => q(kazachskej tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoski kip),
				'few' => q(laoske kipy),
				'one' => q(laoski kip),
				'other' => q(laoskich kipow),
				'two' => q(laoskej kipa),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanoński punt),
				'few' => q(libanońske punty),
				'one' => q(libanoński punt),
				'other' => q(libanońskich puntow),
				'two' => q(libanońskej punta),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(sri-lankaska rupija),
				'few' => q(sri-lankaske rupije),
				'one' => q(sri-lankaska rupija),
				'other' => q(sri-lankaskich rupijow),
				'two' => q(sri-lankaskej rupiji),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiski dolar),
				'few' => q(liberiske dolary),
				'one' => q(liberiski dolar),
				'other' => q(liberiskich dolarow),
				'two' => q(liberiskej dolara),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litawski litas),
				'few' => q(litawske litasy),
				'one' => q(litawski litas),
				'other' => q(litawskich litasow),
				'two' => q(litawskej litasa),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(letiski lat),
				'few' => q(letiske laty),
				'one' => q(letiski lat),
				'other' => q(letiskich latow),
				'two' => q(letiskej lata),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyski dinar),
				'few' => q(libyske dinary),
				'one' => q(libyski dinar),
				'other' => q(libyskich dinarow),
				'two' => q(libyskej dinara),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkoski dirham),
				'few' => q(marokkoske dirhamy),
				'one' => q(marokkoski dirham),
				'other' => q(marokkoskich dirhamow),
				'two' => q(marokkoskej dirhama),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldawiski leu),
				'few' => q(moldawiske leu),
				'one' => q(moldawiski leu),
				'other' => q(moldawiskich leu),
				'two' => q(moldawiskej leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskarski ariary),
				'few' => q(madagaskarske ariary),
				'one' => q(madagaskarski ariary),
				'other' => q(madagaskarskich ariary),
				'two' => q(madagaskarskej ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedoński denar),
				'few' => q(makedońske denary),
				'one' => q(makedoński denar),
				'other' => q(makedońskich denarow),
				'two' => q(makedońskej denara),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarski kyat),
				'few' => q(myanmarske kyaty),
				'one' => q(myanmarski kyat),
				'other' => q(myanmarskich kyatow),
				'two' => q(myanmarskej kyata),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolske tugriki),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskich tugrikow),
				'two' => q(mongolskej tugrika),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macaoska pataca),
				'few' => q(macaoske pataca),
				'one' => q(macaoska pataca),
				'other' => q(macaoskich pataca),
				'two' => q(macaoskej pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauretański ouguiya),
				'few' => q(mauretańske ouguiya),
				'one' => q(mauretański ouguiya),
				'other' => q(mauretański ouguiya),
				'two' => q(mauretańskej ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauriciska rupija),
				'few' => q(mauriciske rupije),
				'one' => q(mauriciska rupija),
				'other' => q(mauriciskich rupijow),
				'two' => q(mauriciskej rupiji),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(malediwiska rupija),
				'few' => q(malediwiske rupije),
				'one' => q(malediwiska rupija),
				'other' => q(malediwiskich rupijow),
				'two' => q(malediwiskej rupiji),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawiski kwacha),
				'few' => q(malawiske kwachy),
				'one' => q(malawiski kwacha),
				'other' => q(malawiskich kwachow),
				'two' => q(malawiskej kwaše),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(mexiski peso),
				'few' => q(mexiske peso),
				'one' => q(mexiski peso),
				'other' => q(mexiskich peso),
				'two' => q(mexiskej peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajziski ringgit),
				'few' => q(malajziske ringgity),
				'one' => q(malajziski ringgit),
				'other' => q(malajziskich ringgitow),
				'two' => q(malajziskej ringgita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozabicke escudo),
				'few' => q(mozabicke escuda),
				'one' => q(mozabicke escudo),
				'other' => q(mozabickich escud),
				'two' => q(mozabickej escuźe),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mosambikski metical \(1980–2006\)),
				'few' => q(mosambikske meticale \(1980–2006\)),
				'one' => q(mosambikski metical \(1980–2006\)),
				'other' => q(mosambikskich meticalow \(1980–2006\)),
				'two' => q(mosambikskej meticala \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mosambikski metical),
				'few' => q(mosambikske meticale),
				'one' => q(mosambikski metical),
				'other' => q(mosambikskich meticalow),
				'two' => q(mosambikskej meticala),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiski dolar),
				'few' => q(namibiske dolary),
				'one' => q(namibiski dolar),
				'other' => q(namibiskich dolarow),
				'two' => q(namibiskej dolara),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriska naira),
				'few' => q(nigeriske nairy),
				'one' => q(nigeriska naira),
				'other' => q(nigeriskich nairow),
				'two' => q(nigeriskej nairje),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaraguaska cordoba),
				'few' => q(nikaraguaske cordoby),
				'one' => q(nikaraguaska cordoba),
				'other' => q(nikaraguaskich cordobow),
				'two' => q(nikaraguaskej cordobje),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norwegska krona),
				'few' => q(norwegske krony),
				'one' => q(norwegska krona),
				'other' => q(norwegskich kronow),
				'two' => q(norwegskej kronje),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskich rupijow),
				'two' => q(nepalskej rupiji),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(nowoseelandski dolar),
				'few' => q(nowoseelandske dolary),
				'one' => q(nowoseelandski dolar),
				'other' => q(nowoseelandskich dolarow),
				'two' => q(nowoseelandskej dolara),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omański rial),
				'few' => q(omańske riale),
				'one' => q(omański rial),
				'other' => q(omańskich rialow),
				'two' => q(omańskej riala),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamaski balboa),
				'few' => q(panamaske balboa),
				'one' => q(panamaski balboa),
				'other' => q(panamaskich balboa),
				'two' => q(panamaskej balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruski sol),
				'few' => q(peruske sole),
				'one' => q(peruski sol),
				'other' => q(peruskich solow),
				'two' => q(peruskej sola),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua-neuguinejska kina),
				'few' => q(papua-neuguinejske kiny),
				'one' => q(papua-neuguinejska kina),
				'other' => q(papua-neuguinejskich kinow),
				'two' => q(papua-neuguinejskej kinje),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipinski peso),
				'few' => q(filipinske peso),
				'one' => q(filipinski peso),
				'other' => q(filipinskich peso),
				'two' => q(filipinskej peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistańska rupija),
				'few' => q(pakistańske rupije),
				'one' => q(pakistańska rupija),
				'other' => q(pakistańskich rupijow),
				'two' => q(pakistańskej rupiji),
			},
		},
		'PLN' => {
			symbol => 'zł',
			display_name => {
				'currency' => q(pólski złoty),
				'few' => q(pólske złote),
				'one' => q(pólski złoty),
				'other' => q(pólskich złotych),
				'two' => q(pólskej złotej),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayski guarani),
				'few' => q(paraguayske guaranije),
				'one' => q(paraguayski guarani),
				'other' => q(paraguayskich guaranijow),
				'two' => q(paraguayskej guaranija),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarski rial),
				'few' => q(katarske riale),
				'one' => q(katarski rial),
				'other' => q(katarskich rialow),
				'two' => q(katarskej riala),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumuński leu),
				'few' => q(rumuńske leu),
				'one' => q(rumuński leu),
				'other' => q(rumuńskich leu),
				'two' => q(rumuńskej leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiski dinar),
				'few' => q(serbiske dinary),
				'one' => q(serbiski dinar),
				'other' => q(serbiskich dinarow),
				'two' => q(serbiskej dinara),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruski rubl),
				'few' => q(ruske ruble),
				'one' => q(ruski rubl),
				'other' => q(ruskich rublow),
				'two' => q(ruskej rubla),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandiski frank),
				'few' => q(ruandiske franki),
				'one' => q(ruandiski frank),
				'other' => q(ruandiskich frankow),
				'two' => q(ruandiskej franka),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudi-arabiski rial),
				'few' => q(saudi-arabiske riale),
				'one' => q(saudi-arabiski rial),
				'other' => q(saudi-arabiskich rialow),
				'two' => q(saudi-arabiskej riala),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomoński dolar),
				'few' => q(salomońske dolary),
				'one' => q(salomoński dolar),
				'other' => q(salomońskich dolarow),
				'two' => q(salomońskej dolara),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelska rupija),
				'few' => q(seychelske rupije),
				'one' => q(seychelska rupija),
				'other' => q(seychelskich rupijow),
				'two' => q(seychelskej rupiji),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudański punt),
				'few' => q(sudańske punty),
				'one' => q(sudański punt),
				'other' => q(sudańskich puntow),
				'two' => q(sudańskej punta),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(šwedska krona),
				'few' => q(šwedske krony),
				'one' => q(šwedska krona),
				'other' => q(šwedskich kronow),
				'two' => q(šwedskej kronje),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurske dolary),
				'one' => q(singapurski dolar),
				'other' => q(singapurskich dolarow),
				'two' => q(singapurskej dolara),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena punt),
				'few' => q(St. Helena punty),
				'one' => q(St. Helena punt),
				'other' => q(St. Helena puntow),
				'two' => q(St. Helena punta),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierra-leoneski leone),
				'few' => q(sierra-leoneske leone),
				'one' => q(sierra-leoneski leone),
				'other' => q(sierra-leoneskich leone),
				'two' => q(sierra-leoneskej leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliski šiling),
				'few' => q(somaliske šilingi),
				'one' => q(somaliski šiling),
				'other' => q(somaliskich šilingow),
				'two' => q(somaliskej šilinga),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamske dolary),
				'one' => q(surinamski dolar),
				'other' => q(surinamskich dolarow),
				'two' => q(surinamskej dolara),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(pódpołdnjowosudański punt),
				'few' => q(pódpołdnjowosudańske punty),
				'one' => q(pódpołdnjowosudański punt),
				'other' => q(pódpołdnjowosudańskich puntow),
				'two' => q(pódpołdnjowosudańskej punta),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(são-tomeska dobra),
				'few' => q(são-tomeske dobry),
				'one' => q(são-tomeska dobra),
				'other' => q(são-tomeskich dobrow),
				'two' => q(são-tomeskej dobrje),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(el-salvadorski colón),
				'few' => q(el-salvadorske colóny),
				'one' => q(el-salvadorski colón),
				'other' => q(el-salvadorskich colónow),
				'two' => q(el-salvadorskej colóna),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriski punt),
				'few' => q(syriske punty),
				'one' => q(syriski punt),
				'other' => q(syriskich puntow),
				'two' => q(syriskej punta),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swasiski lilangeni),
				'few' => q(swasiske lilangenije),
				'one' => q(swasiski lilangeni),
				'other' => q(swasiskich lilangenijow),
				'two' => q(swasiskej lilangenija),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(thaiski baht),
				'few' => q(thaiske bahty),
				'one' => q(thaiski baht),
				'other' => q(thaiskich bahtow),
				'two' => q(thaiskej bahta),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadźikiski somoni),
				'few' => q(tadźikiske somonije),
				'one' => q(tadźikiski somoni),
				'other' => q(tadźikiskich somonijow),
				'two' => q(tadźikiskej somonija),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmeniski manat),
				'few' => q(turkmeniske manaty),
				'one' => q(turkmeniski manat),
				'other' => q(turkmeniskich manatow),
				'two' => q(turkmeniskej manata),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuneziski dinar),
				'few' => q(tuneziske dinary),
				'one' => q(tuneziski dinar),
				'other' => q(tuneziskich dinarow),
				'two' => q(tuneziskej dinara),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongaski paʻanga),
				'few' => q(tongaske pa’anga),
				'one' => q(tongaski pa’anga),
				'other' => q(tongaskich pa’anga),
				'two' => q(tongaskej pa’anga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turkojska lira),
				'few' => q(turkojske liry),
				'one' => q(turkojska lira),
				'other' => q(turkojskich lirow),
				'two' => q(turkojskej lirje),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidad-tobagoski dolar),
				'few' => q(trinidad-tobagoske dolary),
				'one' => q(trinidad-tobagoski dolar),
				'other' => q(trinidad-tobagoskich dolarow),
				'two' => q(trinidad-tobagoskej dolara),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(nowy taiwański dolar),
				'few' => q(nowe taiwańske dolary),
				'one' => q(nowy taiwański dolar),
				'other' => q(nowych taiwańskich dolarow),
				'two' => q(nowej taiwańskej dolara),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tansaniski šiling),
				'few' => q(tansaniske šilingi),
				'one' => q(tansaniski šiling),
				'other' => q(tansaniskich šilingow),
				'two' => q(tansaniskej šilinga),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainska griwna),
				'few' => q(ukrainske griwny),
				'one' => q(ukrainska griwna),
				'other' => q(ukrainskich griwnow),
				'two' => q(ukrainskej griwnje),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandaski šiling),
				'few' => q(ugandaske šilingi),
				'one' => q(ugandaski šiling),
				'other' => q(ugandaskich šilingow),
				'two' => q(ugandaskej šilinga),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ameriski dolar),
				'few' => q(ameriske dolary),
				'one' => q(ameriski dolar),
				'other' => q(ameriskich dolarow),
				'two' => q(ameriskej dolara),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayski peso),
				'few' => q(uruguayske peso),
				'one' => q(uruguayski peso),
				'other' => q(uruguayskich peso),
				'two' => q(uruguayskej peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekiski sum),
				'few' => q(usbekiske sumy),
				'one' => q(usbekiski sum),
				'other' => q(usbekiskich sumow),
				'two' => q(usbekiskej suma),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelski bolívar),
				'few' => q(venezuelske bolívary),
				'one' => q(venezuelski bolívar),
				'other' => q(venezuelskich bolívarow),
				'two' => q(venezuelskej bolívara),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(vietnamski dong),
				'few' => q(vietnamske dongi),
				'one' => q(vietnamski dong),
				'other' => q(vietnamskich dongow),
				'two' => q(vietnamskej donga),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatski vatu),
				'few' => q(vanuatske vatu),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskich vatu),
				'two' => q(vanuatskej vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoaska tala),
				'few' => q(samoaske tale),
				'one' => q(samoaski tala),
				'other' => q(samoaskich talow),
				'two' => q(samoaskej tali),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA-frank \(BEAC\)),
				'few' => q(CFA-franki \(BEAC\)),
				'one' => q(CFA-frank \(BEAC\)),
				'other' => q(CFA-frankow \(BEAC\)),
				'two' => q(CFA-franka \(BEAC\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(pódzajtšnokaribiski dolar),
				'few' => q(pódzajtšnokaribiske dolary),
				'one' => q(pódzajtšnokaribiski dolar),
				'other' => q(pódzajtšnokaribiskich dolarow),
				'two' => q(pódzajtšnokaribiskej dolara),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA-frank \(BCEAO\)),
				'few' => q(CFA-franki \(BCEAO\)),
				'one' => q(CFA-frank \(BCEAO\)),
				'other' => q(CFA-frankow \(BCEAO\)),
				'two' => q(CFA-franka \(BCEAO\)),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-frank),
				'few' => q(CFP-franki),
				'one' => q(CFP-frank),
				'other' => q(CFP-frankow),
				'two' => q(CFP-franka),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(njeznate pjenjeze),
				'few' => q(njeznate pjenjeze),
				'one' => q(njeznate pjenjeze),
				'other' => q(njeznatych pjenjez),
				'two' => q(njeznate pjenjeze),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemeński rial),
				'few' => q(jemeńske riale),
				'one' => q(jemeński rial),
				'other' => q(jemeńskich rialow),
				'two' => q(jemeńskej riala),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(pódpołdnjowoafriski rand),
				'few' => q(pódpołdnjowoafriske randy),
				'one' => q(pódpołdnjowoafriski rand),
				'other' => q(pódpołdnjowoafriskich randow),
				'two' => q(pódpołdnjowoafriskej randa),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(sambiska kwacha),
				'few' => q(sambiske kwachy),
				'one' => q(sambiska kwacha),
				'other' => q(sambiskich kwachow),
				'two' => q(sambiskej kwaše),
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
							'jan.',
							'feb.',
							'měr.',
							'apr.',
							'maj.',
							'jun.',
							'jul.',
							'awg.',
							'sep.',
							'okt.',
							'now.',
							'dec.'
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
							'januara',
							'februara',
							'měrca',
							'apryla',
							'maja',
							'junija',
							'julija',
							'awgusta',
							'septembra',
							'oktobra',
							'nowembra',
							'decembra'
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
							'měr',
							'apr',
							'maj',
							'jun',
							'jul',
							'awg',
							'sep',
							'okt',
							'now',
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
							'januar',
							'februar',
							'měrc',
							'apryl',
							'maj',
							'junij',
							'julij',
							'awgust',
							'september',
							'oktober',
							'nowember',
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
						mon => 'pón',
						tue => 'wał',
						wed => 'srj',
						thu => 'stw',
						fri => 'pět',
						sat => 'sob',
						sun => 'nje'
					},
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 's',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
						mon => 'pó',
						tue => 'wa',
						wed => 'sr',
						thu => 'st',
						fri => 'pě',
						sat => 'so',
						sun => 'nj'
					},
					wide => {
						mon => 'pónjeźele',
						tue => 'wałtora',
						wed => 'srjoda',
						thu => 'stwórtk',
						fri => 'pětk',
						sat => 'sobota',
						sun => 'njeźela'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'pón',
						tue => 'wał',
						wed => 'srj',
						thu => 'stw',
						fri => 'pět',
						sat => 'sob',
						sun => 'nje'
					},
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 's',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
						mon => 'pó',
						tue => 'wa',
						wed => 'sr',
						thu => 'st',
						fri => 'pě',
						sat => 'so',
						sun => 'nj'
					},
					wide => {
						mon => 'pónjeźele',
						tue => 'wałtora',
						wed => 'srjoda',
						thu => 'stwórtk',
						fri => 'pětk',
						sat => 'sobota',
						sun => 'njeźela'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. kwartal',
						1 => '2. kwartal',
						2 => '3. kwartal',
						3 => '4. kwartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. kwartal',
						1 => '2. kwartal',
						2 => '3. kwartal',
						3 => '4. kwartal'
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
					'pm' => q{wótpołdnja},
					'am' => q{dopołdnja},
				},
				'narrow' => {
					'am' => q{dop.},
					'pm' => q{wótp.},
				},
				'abbreviated' => {
					'pm' => q{wótpołdnja},
					'am' => q{dopołdnja},
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
				'0' => 'pś.Chr.n.',
				'1' => 'pó Chr.n.'
			},
			wide => {
				'0' => 'pśed Kristusowym naroźenim',
				'1' => 'pó Kristusowem naroźenju'
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d.M.y},
			'short' => q{d.M.yy},
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
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E, 'zeg'. H:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{'zeg'. H},
			Hm => q{'zeg'. H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'generic' => {
			Ed => q{E, d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
		'gregorian' => {
			H => {
				H => q{'zeg'. H–H},
			},
			Hm => {
				H => q{'zeg'. H:mm – H:mm},
				m => q{'zeg'. H:mm – H:mm},
			},
			Hmv => {
				H => q{'zeg'. H:mm – H:mm v},
				m => q{'zeg'. H:mm – H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
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
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y},
				d => q{E, d.M.y – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{LLL – LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d. – d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
		'generic' => {
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M.y – M.y G},
				y => q{M.y – M.y G},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y G},
				d => q{E, d.M.y – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d. – d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y G},
				d => q{d.M.y – d.M.y G},
				y => q{d.M.y – d.M.y G},
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
		regionFormat => q(Casowe pasmo {0}),
		regionFormat => q({0} lěśojski cas),
		regionFormat => q({0} zymski cas),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afghaniski cas#,
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
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
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
			exemplarCity => q#Mogadišu#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Srjejźoafriski cas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnoafriski cas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Pódpołdnjowoafriski cas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Pódwjacornoafriski lěśojski cas#,
				'generic' => q#Pódwjacornoafriski cas#,
				'standard' => q#Pódwjacornoafriski standardny cas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaskojski lěśojski cas#,
				'generic' => q#Alaskojski cas#,
				'standard' => q#Alaskojski standardny cas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amaconaski lěśojski cas#,
				'generic' => q#Amaconaski cas#,
				'standard' => q#Amaconaski standardny cas#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaniske kupy#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
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
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-město#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St.Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
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
				'daylight' => q#Pódpołnocnoameriski centralny lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski centralny cas#,
				'standard' => q#Pódpołnocnoameriski centralny standardny cas#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski pódzajtšny lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski pódzajtšny cas#,
				'standard' => q#Pódpołnocnoameriski pódzajtšny standardny cas#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski górski lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski górski cas#,
				'standard' => q#Pódpołnocnoameriski górski standardny cas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski pacifiski lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski pacifiski cas#,
				'standard' => q#Pódpołnocnoameriski pacifiski standardny cas#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont D’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiaski lěśojski cas#,
				'generic' => q#Apiaski cas#,
				'standard' => q#Apiaski standardny cas#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabiski lěśojski cas#,
				'generic' => q#Arabiski cas#,
				'standard' => q#Arabiski standardny cas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinski lěśojski cas#,
				'generic' => q#Argentinski cas#,
				'standard' => q#Argentinski standardny cas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Pódwjacornoargentinski lěśojski cas#,
				'generic' => q#Pódwjacornoargentinski cas#,
				'standard' => q#Pódwjacornoargentinski standardny cas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeński lěśojski cas#,
				'generic' => q#Armeński cas#,
				'standard' => q#Armeński standardny cas#,
			},
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Port Numbay#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznjetsk#,
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
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Chi-Minh-město#,
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
			exemplarCity => q#Taškent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
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
			exemplarCity => q#Jerewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantiski lěśojski cas#,
				'generic' => q#Atlantiski cas#,
				'standard' => q#Atlantiski standardny cas#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Acory#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöje#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Pódpołdnjowa Georgiska#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Srjejźoawstralski lěśojski cas#,
				'generic' => q#Srjejźoawstralski cas#,
				'standard' => q#Srjejźoawstralski standardny cas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Srjejźopódwjacorny awstralski lěśojski cas#,
				'generic' => q#Srjejźopódwjacorny awstralski cas#,
				'standard' => q#Srjejźopódwjacorny awstralski standardny cas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnoawstralski lěśojski cas#,
				'generic' => q#Pódzajtšnoawstralski cas#,
				'standard' => q#Pódzajtšnoawstralski standardny cas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Pódwjacornoawstralski lěśojski cas#,
				'generic' => q#Pódwjacornoawstralski cas#,
				'standard' => q#Pódwjacornoawstralski standardny cas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbajdžaniski lěśojski cas#,
				'generic' => q#Azerbajdžaniski cas#,
				'standard' => q#Azerbajdžaniski standardny cas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Acorski lěśojski cas#,
				'generic' => q#Acorski cas#,
				'standard' => q#Acorski standardny cas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladešski lěśojski cas#,
				'generic' => q#Bangladešski cas#,
				'standard' => q#Bangladešski standardny cas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutański cas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliwiski cas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília lěśojski cas#,
				'generic' => q#Brasília cas#,
				'standard' => q#Brasília standardny cas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneiski cas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapverdski lěśojski cas#,
				'generic' => q#Kapverdski cas#,
				'standard' => q#Kapverdski standardny cas#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorrski cas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathamski lěśojski cas#,
				'generic' => q#Chathamski cas#,
				'standard' => q#Chathamski standardny cas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilski lěśojski cas#,
				'generic' => q#Chilski cas#,
				'standard' => q#Chilski standardny cas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinski lěśojski cas#,
				'generic' => q#Chinski cas#,
				'standard' => q#Chinski standardny cas#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsański lěśojski cas#,
				'generic' => q#Choibalsański cas#,
				'standard' => q#Choibalsański standardny cas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#cas Gódownych kupow#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#cas Kokosowych kupow#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbiski lěśojski cas#,
				'generic' => q#Kolumbiski cas#,
				'standard' => q#Kolumbiski standardny cas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#lěśojski cas Cookowych kupow#,
				'generic' => q#cas Cookowych kupow#,
				'standard' => q#Standardny cas Cookowych kupow#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubański lěśojski cas#,
				'generic' => q#Kubański cas#,
				'standard' => q#Kubański standardny cas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis cas#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#DumontDUrville cas#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Pódzajtšnotimorski cas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#lěśojski cas Jatšowneje kupy#,
				'generic' => q#cas Jatšowneje kupy#,
				'standard' => q#standardny cas Jatšowneje kupy#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekuadorski cas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Njeznate#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Běłogrod#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Iriski lěśojski cas#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britiski lěśojski cas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilna#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Waršawa#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporižja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Srjejźoeuropski lěśojski cas#,
				'generic' => q#Srjejźoeuropski cas#,
				'standard' => q#Srjejźoeuropski standardny cas#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnoeuropski lěśojski cas#,
				'generic' => q#Pódzajtšnoeuropski cas#,
				'standard' => q#Pódzajtšnoeuropski standardny cas#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningradski cas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Pódwjacornoeuropski lěśojski cas#,
				'generic' => q#Pódwjacornoeuropski cas#,
				'standard' => q#Pódwjacornoeuropski standardny cas#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandski lěśojski cas#,
				'generic' => q#Falklandski cas#,
				'standard' => q#Falklandski standardny cas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidźiski lěśojski cas#,
				'generic' => q#Fidźiski cas#,
				'standard' => q#Fidźiski standardny cas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francojskoguyański cas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#cas francojskego pódpołdnjowego a antarktiskeho teritoriuma#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichski cas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagoski cas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambierski cas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgiski lěśojski cas#,
				'generic' => q#Georgiski cas#,
				'standard' => q#Georgiski standardny cas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#cas Gilbertowych kupow#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnogrönlandski lěśojski cas#,
				'generic' => q#Pódzajtšnogrönlandski cas#,
				'standard' => q#Pódzajtšnogrönlandski standardny cas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Pódwjacornogrönlandski lěśojski cas#,
				'generic' => q#Pódwjacornogrönlandski cas#,
				'standard' => q#Pódwjacornogrönlandski standardny cas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#cas Persiskego golfa#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyański cas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaiisko-aleutski lěśojski cas#,
				'generic' => q#Hawaiisko-aleutski cas#,
				'standard' => q#Hawaiisko-aleutski standardny cas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongski lěśojski cas#,
				'generic' => q#Hongkongski cas#,
				'standard' => q#Hongkongski standardny cas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chowdski lěśojski cas#,
				'generic' => q#Chowdski cas#,
				'standard' => q#Chowdski standardny cas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indiski cas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Gódowne kupy#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komory#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediwy#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiskooceaniski cas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochinski cas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Srjejźoindoneski cas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnoindoneski#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Pódwjacornoindoneski cas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irański lěśojski cas#,
				'generic' => q#Irański cas#,
				'standard' => q#Irański standardny cas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutski lěśojski cas#,
				'generic' => q#Irkutski cas#,
				'standard' => q#Irkutski standardny cas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelski lěśojski cas#,
				'generic' => q#Israelski cas#,
				'standard' => q#Israelski standardny cas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japański lěśojski cas#,
				'generic' => q#Japański cas#,
				'standard' => q#Japański standardny cas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnokazachski cas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Pódwjacornokazachski cas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejski lěśojski cas#,
				'generic' => q#Korejski cas#,
				'standard' => q#Korejski standardny cas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraeski cas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarski lěśojski cas#,
				'generic' => q#Krasnojarski cas#,
				'standard' => q#Krasnojarski standardny cas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgiski cas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#cas Linijowych kupow#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#lěśojski cas kupy Lord-Howe#,
				'generic' => q#cas kupy Lord-Howe#,
				'standard' => q#Standardny cas kupy Lord-Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#cas kupy Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadański lěśojski cas#,
				'generic' => q#Magadański cas#,
				'standard' => q#Magadański standardny cas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malajziski cas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediwski cas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marqueski cas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#cas Marshallowych kupow#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauriciski lěśojski cas#,
				'generic' => q#Mauriciski cas#,
				'standard' => q#Mauriciski standardny cas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson cas#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Mexiski dłujkowjacorny lěśojski cas#,
				'generic' => q#Mexiski dłujkowjacorny cas#,
				'standard' => q#Mexiski dłujkowjacorny standardny cas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexiski pacifiski lěśojski cas#,
				'generic' => q#Mexiski pacifiski cas#,
				'standard' => q#Mexiski pacifiski standardny cas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Batorski lěśojski cas#,
				'generic' => q#Ulan-Batorski cas#,
				'standard' => q#Ulan-Batorski standardny cas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskowski lěśojski cas#,
				'generic' => q#Moskowski cas#,
				'standard' => q#Moskowski standardny cas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarski cas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruski cas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalski cas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nowokaledoniski lěśojski cas#,
				'generic' => q#Nowokaledoniski cas#,
				'standard' => q#Nowokaledoniski standardny cas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nowoseelandski lěśojski cas#,
				'generic' => q#Nowoseelandski cas#,
				'standard' => q#Nowoseelandski standardny cas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nowofundlandski lěśojski cas#,
				'generic' => q#Nowofundlandski cas#,
				'standard' => q#Nowofundlandski standardny cas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niueski cas#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#cas kupy Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#lěśojski cas Fernando de Noronha#,
				'generic' => q#cas Fernando de Noronha#,
				'standard' => q#standardny cas Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirski lěśojski cas#,
				'generic' => q#Nowosibirski cas#,
				'standard' => q#Nowosibirski standardny cas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omski lěśojski cas#,
				'generic' => q#Omski cas#,
				'standard' => q#Omski standardny cas#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Jatšowne kupy#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistański lěśojski cas#,
				'generic' => q#Pakistański cas#,
				'standard' => q#Pakistański standardny cas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palauski cas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Nowoginejski cas#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayski lěśojski cas#,
				'generic' => q#Paraguayski cas#,
				'standard' => q#Paraguayski standardny cas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruski lěśojski cas#,
				'generic' => q#Peruski cas#,
				'standard' => q#Peruski standardny cas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinski lěśojski cas#,
				'generic' => q#Filipinski cas#,
				'standard' => q#Filipinski standardny cas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#cas Phoenixowych kupow#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St.-Pierre-a-Miqueloński lěśojski cas#,
				'generic' => q#St.-Pierre-a-Miqueloński cas#,
				'standard' => q#St.-Pierre-a-Miqueloński standardny cas#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#cas Pitcairnowych kupow#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapski cas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunionski cas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#cas Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalinski lěśojski cas#,
				'generic' => q#Sachalinski cas#,
				'standard' => q#Sachalinski standardny cas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoaski lěśojski cas#,
				'generic' => q#Samoaski cas#,
				'standard' => q#Samoaski standardny cas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelski cas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurski cas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomoński cas#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Pódpołdnjowogeorgiski cas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamski cas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa cas#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiski cas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tchajpejski lěśojski cas#,
				'generic' => q#Tchajpejski cas#,
				'standard' => q#Tchajpejski standardny cas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadźikiski cas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelauski cas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongaski lěśojski cas#,
				'generic' => q#Tongaski cas#,
				'standard' => q#Tongaski standardny cas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukski cas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmeniski lěśojski cas#,
				'generic' => q#Turkmeniski cas#,
				'standard' => q#Turkmeniski standardny cas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalski cas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayski lěśojski cas#,
				'generic' => q#Uruguayski cas#,
				'standard' => q#Uruguayski standardny cas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekiski lěśojski cas#,
				'generic' => q#Uzbekiski cas#,
				'standard' => q#Uzbekiski standardny cas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatski lěśojski cas#,
				'generic' => q#Vanuatski cas#,
				'standard' => q#Vanuatski standardny cas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelski cas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostokski lěśojski cas#,
				'generic' => q#Wladiwostokski cas#,
				'standard' => q#Wladiwostokski standardny cas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgogradski lěśojski cas#,
				'generic' => q#Wolgogradski cas#,
				'standard' => q#Wolgogradski standardny cas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#cas Wostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#cas kupy Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#cas kupow Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutski lěśojski cas#,
				'generic' => q#Jakutski cas#,
				'standard' => q#Jakutski standardny cas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgski lěśojski cas#,
				'generic' => q#Jekaterinburgski cas#,
				'standard' => q#Jekaterinburgski standardny cas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
