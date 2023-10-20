=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Hsb - Package for language Upper Sorbian

=cut

package Locale::CLDR::Locales::Hsb;
# This file auto generated from Data\common\main\hsb.xml
#	on Fri 13 Oct  9:20:02 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
 				'ab' => 'abchazišćina',
 				'af' => 'afrikaanšćina',
 				'agq' => 'aghemšćina',
 				'ak' => 'akanšćina',
 				'am' => 'amharšćina',
 				'an' => 'aragonšćina',
 				'ang' => 'anglosakšćina',
 				'ar' => 'arabšćina',
 				'ar_001' => 'moderna wysokoarabšćina',
 				'arn' => 'arawkanšćina',
 				'as' => 'asamšćina',
 				'asa' => 'pare',
 				'ast' => 'asturšćina',
 				'av' => 'awaršćina',
 				'ay' => 'aymaršćina',
 				'az' => 'azerbajdźanšćina',
 				'ba' => 'baškiršćina',
 				'be' => 'běłorušćina',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bołharšćina',
 				'bi' => 'bislamšćina',
 				'bm' => 'bambara',
 				'bn' => 'bengalšćina',
 				'bo' => 'tibetšćina',
 				'br' => 'bretonšćina',
 				'brx' => 'bodo',
 				'bs' => 'bosnišćina',
 				'bug' => 'buginezišćina',
 				'ca' => 'katalanšćina',
 				'cgg' => 'chiga',
 				'ch' => 'čamoršćina',
 				'cho' => 'choctawšćina',
 				'chr' => 'cherokee',
 				'ckb' => 'sorani',
 				'co' => 'korsišćina',
 				'cr' => 'kri',
 				'cs' => 'čěšćina',
 				'cy' => 'walizišćina',
 				'da' => 'danšćina',
 				'dav' => 'taita',
 				'de' => 'němčina',
 				'de_AT' => 'awstriska němčina',
 				'de_CH' => 'šwicarska wysokoněmčina',
 				'dje' => 'zarma',
 				'dsb' => 'delnjoserbšćina',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'el' => 'grjekšćina',
 				'en' => 'jendźelšćina',
 				'en_AU' => 'awstralska jendźelšćina',
 				'en_CA' => 'kanadiska jendźelšćina',
 				'en_GB' => 'britiska jendźelšćina',
 				'en_GB@alt=short' => 'jendźelšćina (UK)',
 				'en_US' => 'ameriska jendźelšćina',
 				'en_US@alt=short' => 'jendźelšćina (USA)',
 				'eo' => 'esperanto',
 				'es' => 'španišćina',
 				'es_419' => 'łaćonskoameriska španišćina',
 				'es_ES' => 'europska španišćina',
 				'es_MX' => 'mexiska španišćina',
 				'et' => 'estišćina',
 				'eu' => 'baskišćina',
 				'fa' => 'persišćina',
 				'fi' => 'finšćina',
 				'fil' => 'filipinšćina',
 				'fj' => 'fidźišćina',
 				'fo' => 'färöšćina',
 				'fr' => 'francošćina',
 				'fr_CA' => 'kanadiska francošćina',
 				'fr_CH' => 'šwicarska francošćina',
 				'fy' => 'frizišćina',
 				'ga' => 'iršćina',
 				'gag' => 'gagauzišćina',
 				'gd' => 'šotiska gelšćina',
 				'gl' => 'galicišćina',
 				'gn' => 'guarani',
 				'got' => 'gotšćina',
 				'gsw' => 'šwicarska němčina',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manšćina',
 				'ha' => 'hausa',
 				'haw' => 'hawaiišćina',
 				'he' => 'hebrejšćina',
 				'hi' => 'hindišćina',
 				'hr' => 'chorwatšćina',
 				'hsb' => 'hornjoserbšćina',
 				'ht' => 'haitišćina',
 				'hu' => 'madźaršćina',
 				'hy' => 'armenšćina',
 				'ia' => 'interlingua',
 				'id' => 'indonešćina',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiak',
 				'io' => 'ido',
 				'is' => 'islandšćina',
 				'it' => 'italšćina',
 				'iu' => 'inuitšćina',
 				'ja' => 'japanšćina',
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
 				'kl' => 'gröndlandšćina',
 				'kln' => 'kalenjin',
 				'km' => 'khmeršćina',
 				'kn' => 'kannadšćina',
 				'ko' => 'korejšćina',
 				'koi' => 'permska komišćina',
 				'kok' => 'konkani',
 				'kri' => 'krio',
 				'ks' => 'kašmiršćina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ku' => 'kurdišćina',
 				'kw' => 'kornišćina',
 				'ky' => 'kirgišćina',
 				'la' => 'łaćonšćina',
 				'lag' => 'langi',
 				'lb' => 'luxemburgšćina',
 				'lg' => 'gandšćina',
 				'li' => 'limburšćina',
 				'lkt' => 'lakota',
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
 				'mg' => 'malagassišćina',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mi' => 'maoršćina',
 				'mk' => 'makedonšćina',
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
 				'nb' => 'norwegšćina (bokmål)',
 				'nd' => 'sewjero-ndebele',
 				'nds' => 'delnjoněmčina',
 				'ne' => 'nepalšćina',
 				'nl' => 'nižozemšćina',
 				'nl_BE' => 'flamšćina',
 				'nmg' => 'kwasio',
 				'nn' => 'norwegšćina (nynorsk)',
 				'no' => 'norwegšćina',
 				'nqo' => 'n’ko',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nyn' => 'nyankole',
 				'oc' => 'okcitanšćina',
 				'om' => 'oromo',
 				'or' => 'orijšćina',
 				'pa' => 'pandźabšćina',
 				'pl' => 'pólšćina',
 				'prg' => 'prušćina',
 				'ps' => 'paštunšćina',
 				'pt' => 'portugalšćina',
 				'pt_BR' => 'brazilska portugalšćina',
 				'pt_PT' => 'europska portugalšćina',
 				'qu' => 'kečua',
 				'quc' => 'kʼicheʼ',
 				'rm' => 'retoromanšćina',
 				'rn' => 'kirundišćina',
 				'ro' => 'rumunšćina',
 				'ro_MD' => 'moldawšćina',
 				'rof' => 'rombo',
 				'ru' => 'rušćina',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'saq' => 'samburu',
 				'sbp' => 'sangu',
 				'sc' => 'sardinšćina',
 				'scn' => 'sicilšćina',
 				'sd' => 'sindhišćina',
 				'se' => 'sewjerosamišćina',
 				'seh' => 'sena',
 				'ses' => 'koyra senni',
 				'sg' => 'sango',
 				'sh' => 'serbochorwatšćina',
 				'shi' => 'tašelhit',
 				'si' => 'singhalšćina',
 				'sk' => 'słowakšćina',
 				'sl' => 'słowjenšćina',
 				'sm' => 'samoašćina',
 				'sma' => 'južnosamišćina',
 				'smj' => 'lule-samišćina',
 				'smn' => 'inari-samišćina',
 				'sms' => 'skolt-samišćina',
 				'sn' => 'šonašćina',
 				'so' => 'somališćina',
 				'sq' => 'albanšćina',
 				'sr' => 'serbišćina',
 				'ss' => 'siswati',
 				'st' => 'južnosotšćina (Sesotho)',
 				'stq' => 'saterfrizišćina',
 				'su' => 'sundanezišćina',
 				'sv' => 'šwedšćina',
 				'sw' => 'suahelšćina',
 				'sw_CD' => 'kongoska suahelšćina',
 				'ta' => 'tamilšćina',
 				'te' => 'telugu',
 				'teo' => 'teso',
 				'tg' => 'tadźikšćina',
 				'th' => 'thailandšćina',
 				'ti' => 'tigrinšćina',
 				'tk' => 'turkmenšćina',
 				'tl' => 'tagalog',
 				'tn' => 'tswana',
 				'to' => 'tongašćina',
 				'tr' => 'turkowšćina',
 				'ts' => 'tsonga',
 				'tt' => 'tataršćina',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitišćina',
 				'tzm' => 'tamazight (srjedźny Marokko)',
 				'ug' => 'ujguršćina',
 				'uk' => 'ukrainšćina',
 				'und' => 'njeznata rěč',
 				'ur' => 'urdušćina',
 				'uz' => 'uzbekšćina',
 				'vai' => 'vai',
 				'vi' => 'vietnamšćina',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'walonšćina',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yi' => 'jidišćina',
 				'yo' => 'jorubašćina',
 				'za' => 'zhuang',
 				'zgh' => 'tamazight',
 				'zh' => 'chinšćina',
 				'zh_Hans' => 'chinšćina (zjednorjena)',
 				'zh_Hant' => 'chinšćina (tradicionalna)',
 				'zu' => 'zulušćina',
 				'zxx' => 'žadyn rěčny wobsah',

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
			'Arab' => 'arabsce',
 			'Armn' => 'armensce',
 			'Beng' => 'bengalsce',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'Braillowe pismo',
 			'Cyrl' => 'kyrilisce',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopisce',
 			'Geor' => 'georgisce',
 			'Grek' => 'grjeksce',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hang' => 'hangul',
 			'Hani' => 'chinsce',
 			'Hans' => 'zjednorjene',
 			'Hans@alt=stand-alone' => 'zjednorjene chinske pismo',
 			'Hant' => 'tradicionalne',
 			'Hant@alt=stand-alone' => 'tradicionalne chinske pismo',
 			'Hebr' => 'hebrejsce',
 			'Hira' => 'hiragana',
 			'Jpan' => 'japansce',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmersce',
 			'Knda' => 'kannadsce',
 			'Kore' => 'korejsce',
 			'Laoo' => 'laosce',
 			'Latn' => 'łaćonsce',
 			'Mlym' => 'malayalamsce',
 			'Mong' => 'mongolsce',
 			'Mymr' => 'burmasce',
 			'Orya' => 'oriya',
 			'Sinh' => 'singhalsce',
 			'Taml' => 'tamilsce',
 			'Telu' => 'telugu',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandsce',
 			'Tibt' => 'tibetsce',
 			'Zsym' => 'symbole',
 			'Zxxx' => 'bjez pisma',
 			'Zyyy' => 'powšitkowne',
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
 			'003' => 'Sewjerna Amerika',
 			'005' => 'Južna Amerika',
 			'009' => 'Oceaniska',
 			'011' => 'zapadna Afrika',
 			'013' => 'Srjedźna Amerika',
 			'014' => 'wuchodna Afrika',
 			'015' => 'sewjerna Afrika',
 			'017' => 'srjedźna Afrika',
 			'018' => 'južna Afrika',
 			'019' => 'Amerika',
 			'021' => 'sewjerny ameriski kontinent',
 			'029' => 'Karibika',
 			'030' => 'wuchodna Azija',
 			'034' => 'južna Azija',
 			'035' => 'juhowuchodna Azija',
 			'039' => 'južna Europa',
 			'053' => 'Awstralazija',
 			'054' => 'Melaneziska',
 			'057' => 'Mikroneziska (kupowy region)',
 			'061' => 'Polyneziska',
 			'142' => 'Azija',
 			'143' => 'centralna Azija',
 			'145' => 'zapadna Azija',
 			'150' => 'Europa',
 			'151' => 'wuchodna Europa',
 			'154' => 'sewjerna Europa',
 			'155' => 'zapadna Europa',
 			'419' => 'Łaćonska Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Zjednoćene arabske emiraty',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanska',
 			'AM' => 'Armenska',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentinska',
 			'AS' => 'Ameriska Samoa',
 			'AT' => 'Awstriska',
 			'AU' => 'Awstralska',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbajdźan',
 			'BA' => 'Bosniska a Hercegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgiska',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bołharska',
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
 			'CI@alt=variant' => 'Słonowinowy pobrjóh',
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
 			'CX' => 'Hodowna kupa',
 			'CY' => 'Cypern',
 			'CZ' => 'Čěska republika',
 			'DE' => 'Němska',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dźibuti',
 			'DK' => 'Danska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikanska republika',
 			'DZ' => 'Algeriska',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estiska',
 			'EG' => 'Egyptowska',
 			'EH' => 'Zapadna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Španiska',
 			'ET' => 'Etiopiska',
 			'EU' => 'Europska unija',
 			'FI' => 'Finska',
 			'FJ' => 'Fidźi',
 			'FK' => 'Falklandske kupy',
 			'FK@alt=variant' => 'Falklandske kupy (Malwiny)',
 			'FM' => 'Mikroneziska',
 			'FO' => 'Färöske kupy',
 			'FR' => 'Francoska',
 			'GA' => 'Gabun',
 			'GB' => 'Zjednoćene kralestwo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgiska',
 			'GF' => 'Francoska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönlandska',
 			'GM' => 'Gambija',
 			'GN' => 'Gineja',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekwatorialna Gineja',
 			'GR' => 'Grjekska',
 			'GS' => 'Južna Georgiska a Južne Sandwichowe kupy',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gineja-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Wosebita zarjadniska cona Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardowa kupa a McDonaldowe kupy',
 			'HN' => 'Honduras',
 			'HR' => 'Chorwatska',
 			'HT' => 'Haiti',
 			'HU' => 'Madźarska',
 			'IC' => 'Kanariske kupy',
 			'ID' => 'Indoneska',
 			'IE' => 'Irska',
 			'IL' => 'Israel',
 			'IM' => 'Man',
 			'IN' => 'Indiska',
 			'IO' => 'Britiski teritorij w Indiskim oceanje',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandska',
 			'IT' => 'Italska',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordaniska',
 			'JP' => 'Japanska',
 			'KE' => 'Kenija',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodźa',
 			'KI' => 'Kiribati',
 			'KM' => 'Komory',
 			'KN' => 'St. Kitts a Nevis',
 			'KP' => 'Sewjerna Koreja',
 			'KR' => 'Južna Koreja',
 			'KW' => 'Kuwait',
 			'KY' => 'Kajmanske kupy',
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
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallowe kupy',
 			'MK' => 'Makedonska',
 			'MK@alt=variant' => 'Makedonska (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolska',
 			'MO' => 'Wosebita zarjadniska cona Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Sewjerne Mariany',
 			'MQ' => 'Martinique',
 			'MR' => 'Mawretanska',
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
 			'PF' => 'Francoska Polyneziska',
 			'PG' => 'Papuwa-Nowa Gineja',
 			'PH' => 'Filipiny',
 			'PK' => 'Pakistan',
 			'PL' => 'Pólska',
 			'PM' => 'St. Pierre a Miquelon',
 			'PN' => 'Pitcairnowe kupy',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinski awtonomny teritorij',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalska',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Wonkowna Oceaniska',
 			'RE' => 'Réunion',
 			'RO' => 'Rumunska',
 			'RS' => 'Serbiska',
 			'RU' => 'Ruska',
 			'RW' => 'Ruanda',
 			'SA' => 'Sawdi-Arabska',
 			'SB' => 'Salomony',
 			'SC' => 'Seychelle',
 			'SD' => 'Sudan',
 			'SE' => 'Šwedska',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Słowjenska',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Słowakska',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinam',
 			'SS' => 'Južny Sudan',
 			'ST' => 'São Tomé a Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syriska',
 			'SZ' => 'Swaziska',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'kupy Turks a Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francoski južny a antarktiski teritorij',
 			'TG' => 'Togo',
 			'TH' => 'Thailandska',
 			'TJ' => 'Tadźikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Wuchodny Timor',
 			'TM' => 'Turkmeniska',
 			'TN' => 'Tuneziska',
 			'TO' => 'Tonga',
 			'TR' => 'Turkowska',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansanija',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ameriska Oceaniska',
 			'US' => 'Zjednoćene staty Ameriki',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikanske město',
 			'VC' => 'St. Vincent a Grenadiny',
 			'VE' => 'Venezuela',
 			'VG' => 'Britiske knježniske kupy',
 			'VI' => 'Ameriske knježniske kupy',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosowo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Južna Afrika (Republika)',
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
			'calendar' => 'protyka',
 			'collation' => 'rjadowanski slěd',
 			'currency' => 'měna',
 			'numbers' => 'ličby',

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
 				'buddhist' => q{buddhistiska protyka},
 				'chinese' => q{chinska protyka},
 				'dangi' => q{dangi-protyka},
 				'ethiopic' => q{etiopiska protyka},
 				'gregorian' => q{gregorianska protyka},
 				'hebrew' => q{židowska protyka},
 				'islamic' => q{islamska protyka},
 				'iso8601' => q{protyka po iso-8601},
 				'japanese' => q{japanska protyka},
 				'persian' => q{persiska protyka},
 				'roc' => q{protyka republiki China},
 			},
 			'collation' => {
 				'ducet' => q{rjadowanski slěd po Unicode},
 				'search' => q{powšitkowne pytanje},
 				'standard' => q{standardowy rjadowanski slěd},
 			},
 			'numbers' => {
 				'arab' => q{arabsko-indiske cyfry},
 				'arabext' => q{rozšěrjene arabsko-indiske cyfry},
 				'armn' => q{armenske cyfry},
 				'armnlow' => q{armenske cyfry, małe pisane},
 				'beng' => q{bengalske cyfry},
 				'deva' => q{devanagari-cyfry},
 				'ethi' => q{etiopiske cyfry},
 				'fullwide' => q{połnošěroke cyfry},
 				'geor' => q{georgiske cyfry},
 				'grek' => q{grjekske cyfry},
 				'greklow' => q{grjekske cyfry, małe pisane},
 				'gujr' => q{gujarati-cyfry},
 				'guru' => q{gurmukhi-cyfry},
 				'hanidec' => q{chinske decimalne ličby},
 				'hans' => q{zjednorjene chinske cyfry},
 				'hansfin' => q{zjednorjene chinske financne cyfry},
 				'hant' => q{tradicionalne chinske cyfry},
 				'hantfin' => q{tradicionalne chinske financne cyfry},
 				'hebr' => q{hebrejske cyfry},
 				'jpan' => q{japanske cyfry},
 				'jpanfin' => q{japanske financne cyfry},
 				'khmr' => q{khmerske cyfry},
 				'knda' => q{kannadske cyfry},
 				'laoo' => q{laoske cyfry},
 				'latn' => q{arabske cyfry},
 				'mlym' => q{malayalamske cyfry},
 				'mymr' => q{burmaske cyfry},
 				'orya' => q{oriya-cyfry},
 				'roman' => q{romske cyfry},
 				'romanlow' => q{romske cyfry, małe pisane},
 				'taml' => q{tradicionalne tamilske cyfry},
 				'tamldec' => q{tamilske cyfry},
 				'telu' => q{telugu-cyfry},
 				'thai' => q{thailandske cyfry},
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
			'language' => 'rěč: {0}',
 			'script' => 'pismo: {0}',
 			'region' => 'region: {0}',

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
			auxiliary => qr{[á à ă â å ä ã ą ā æ ç ď đ é è ĕ ê ë ė ę ē ğ í ì ĭ î ï İ ī ı ĺ ľ ň ñ ò ŏ ô ö ő ø ō œ ŕ ś ş ß ť ú ù ŭ û ů ü ű ū ý ÿ ż ź]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŹ}', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č ć d {dź} e ě f g h {ch} i j k ł l m n ń o ó p q r ř s š t u v w x y z ž]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŹ}', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
						'few' => q({0} acry),
						'name' => q(acry),
						'one' => q({0} acre),
						'other' => q({0} acrow),
						'two' => q({0} acraj),
					},
					'acre-foot' => {
						'few' => q({0} acre-stopy),
						'name' => q(acre-stopy),
						'one' => q({0} acre-stopa),
						'other' => q({0} acre-stopow),
						'two' => q({0} acre-stopje),
					},
					'ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} amperaj),
					},
					'arc-minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'two' => q({0} minuće),
					},
					'arc-second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'two' => q({0} sekundźe),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomiske jednotki),
						'name' => q(astronomiske jednotki),
						'one' => q({0} astronomiska jednotka),
						'other' => q({0} astronomiskich jednotkow),
						'two' => q({0} astronomiskej jednotce),
					},
					'bit' => {
						'few' => q({0} bity),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bitaj),
					},
					'byte' => {
						'few' => q({0} bytey),
						'name' => q(bytey),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} byteaj),
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
						'two' => q({0} karataj),
					},
					'celsius' => {
						'few' => q({0} stopnje Celsiusa),
						'name' => q(stopnje Celsiusa),
						'one' => q({0} stopjeń Celsiusa),
						'other' => q({0} stopnjow Celsiusa),
						'two' => q({0} stopnjej Celsiusa),
					},
					'centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitraj),
					},
					'centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'two' => q({0} centimetraj),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'two' => q({0} kubiknej centimetraj),
					},
					'cubic-foot' => {
						'few' => q({0} kubikne stopy),
						'name' => q(kubikne stopy),
						'one' => q({0} kubikna stopa),
						'other' => q({0} kubiknych stopow),
						'two' => q({0} kubiknej stopje),
					},
					'cubic-inch' => {
						'few' => q({0} kubikne cóle),
						'name' => q(kubikne cóle),
						'one' => q({0} kubikny cól),
						'other' => q({0} kubiknych cólow),
						'two' => q({0} kubiknej cólej),
					},
					'cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometraj),
					},
					'cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'two' => q({0} kubiknej metraj),
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
						'two' => q({0} kubiknej yardaj),
					},
					'cup' => {
						'few' => q({0} šalki),
						'name' => q(šalki),
						'one' => q({0} šalka),
						'other' => q({0} šalkow),
						'two' => q({0} šalce),
					},
					'day' => {
						'few' => q({0} dny),
						'name' => q(dny),
						'one' => q({0} dźeń),
						'other' => q({0} dnjow),
						'two' => q({0} dnjej),
					},
					'deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitraj),
					},
					'decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetraj),
					},
					'degree' => {
						'few' => q({0} stopnje),
						'name' => q(stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopnjej),
					},
					'fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnjej Fahrenheita),
					},
					'fluid-ounce' => {
						'few' => q({0} běžite uncy),
						'name' => q(běžite uncy),
						'one' => q({0} běžita unca),
						'other' => q({0} běžitych uncow),
						'two' => q({0} běžitej uncy),
					},
					'foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					'foot' => {
						'few' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stopow),
						'two' => q({0} stopje),
					},
					'g-force' => {
						'few' => q({0} jednotki zemskeho pospěšenja),
						'name' => q(jednotki zemskeho pospěšenja),
						'one' => q({0} jednotka zemskeho pospěšenja),
						'other' => q({0} jednotkow zemskeho pospěšenja),
						'two' => q({0} jednotce zemskeho pospěšenja),
					},
					'gallon' => {
						'few' => q({0} galony),
						'name' => q(galony),
						'one' => q({0} galona),
						'other' => q({0} galonow),
						'two' => q({0} galonje),
					},
					'gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabitaj),
					},
					'gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabytey),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabyteaj),
					},
					'gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertzaj),
					},
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawattaj),
					},
					'gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'two' => q({0} gramaj),
					},
					'hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektaraj),
					},
					'hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitraj),
					},
					'hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascalej),
					},
					'hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertzaj),
					},
					'horsepower' => {
						'few' => q({0} konjace mocy),
						'name' => q(konjace mocy),
						'one' => q({0} konjaca móc),
						'other' => q({0} konjacych mocow),
						'two' => q({0} konjacej mocy),
					},
					'hour' => {
						'few' => q({0} hodźiny),
						'name' => q(hodźiny),
						'one' => q({0} hodźina),
						'other' => q({0} hodźinow),
						'per' => q({0} na hodźinu),
						'two' => q({0} hodźinje),
					},
					'inch' => {
						'few' => q({0} cóle),
						'name' => q(cóle),
						'one' => q({0} cól),
						'other' => q({0} cólow),
						'two' => q({0} cólej),
					},
					'inch-hg' => {
						'few' => q({0} cóle žiwoslěbroweho stołpika),
						'name' => q(cóle žiwoslěbroweho stołpika),
						'one' => q({0} cól žiwoslěbroweho stołpika),
						'other' => q({0} cólow žiwoslěbroweho stołpika),
						'two' => q({0} cólej žiwoslěbroweho stołpika),
					},
					'joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} jouleow),
						'two' => q({0} joulej),
					},
					'karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karataj),
					},
					'kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnjej Kelvina),
					},
					'kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobitaj),
					},
					'kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobytey),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobyteaj),
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
						'two' => q({0} kilogramaj),
					},
					'kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertzaj),
					},
					'kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojouleow),
						'two' => q({0} kilojoulej),
					},
					'kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'two' => q({0} kilometraj),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometry na hodźinu),
						'name' => q(kilometry na hodźinu),
						'one' => q({0} kilometer na hodźinu),
						'other' => q({0} kilometrow na hodźinu),
						'two' => q({0} kilometraj na hodźinu),
					},
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowattaj),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilowattowe hodźiny),
						'name' => q(kilowattowe hodźiny),
						'one' => q({0} kilowattowa hodźina),
						'other' => q({0} kilowattowych hodźin),
						'two' => q({0} kilowattowej hodźinje),
					},
					'light-year' => {
						'few' => q({0} swětłolěta),
						'name' => q(swětłolěta),
						'one' => q({0} swětłolěto),
						'other' => q({0} swětłolět),
						'two' => q({0} swětłolěće),
					},
					'liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'two' => q({0} litraj),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litraj na kilometer),
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
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabitaj),
					},
					'megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabytey),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabyteaj),
					},
					'megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertzaj),
					},
					'megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitraj),
					},
					'megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawattaj),
					},
					'meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'two' => q({0} metraj),
					},
					'meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metraj na sekundu),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow na kwadratnu sekundu),
						'two' => q({0} metraj na kwadratnu sekundu),
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
						'two' => q({0} mikrogramaj),
					},
					'micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometraj),
					},
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekundźe),
					},
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					'mile-per-gallon' => {
						'few' => q({0} mile na galonu),
						'name' => q(mile na galonu),
						'one' => q({0} mila na galonu),
						'other' => q({0} milow na galonu),
						'two' => q({0} mili na galonu),
					},
					'mile-per-hour' => {
						'few' => q({0} mile na hodźinu),
						'name' => q(mile na hodźinu),
						'one' => q({0} mila na hodźinu),
						'other' => q({0} milow na hodźinu),
						'two' => q({0} mili na hodźinu),
					},
					'milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliamperaj),
					},
					'millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibaraj),
					},
					'milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligramaj),
					},
					'milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitraj),
					},
					'millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetraj),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetry žiwoslěbroweho stołpika),
						'name' => q(milimetry žiwoslěbroweho stołpika),
						'one' => q({0} milimeter žiwoslěbroweho stołpika),
						'other' => q({0} milimetrow žiwoslěbroweho stołpika),
						'two' => q({0} milimetraj žiwoslěbroweho stołpika),
					},
					'millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekundźe),
					},
					'milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwattaj),
					},
					'minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'two' => q({0} minuće),
					},
					'month' => {
						'few' => q({0} měsacy),
						'name' => q(měsacy),
						'one' => q({0} měsac),
						'other' => q({0} měsacow),
						'two' => q({0} měsacaj),
					},
					'nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometraj),
					},
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekundźe),
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
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohmaj),
					},
					'ounce' => {
						'few' => q({0} uncy),
						'name' => q(uncy),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'two' => q({0} uncy),
					},
					'ounce-troy' => {
						'few' => q({0} troyske uncy),
						'name' => q(troyske uncy),
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
						'two' => q({0} pikometraj),
					},
					'pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pintaj),
					},
					'pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'two' => q({0} puntaj),
					},
					'pound-per-square-inch' => {
						'few' => q({0} punty na kwadratny cól),
						'name' => q(punty na kwadratny cól),
						'one' => q({0} punt na kwadratny cól),
						'other' => q({0} puntow na kwadratny cól),
						'two' => q({0} puntaj na kwadratny cól),
					},
					'quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quartaj),
					},
					'radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radiantaj),
					},
					'second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekundźe),
					},
					'square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'two' => q({0} kwadratnej centimetraj),
					},
					'square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					'square-inch' => {
						'few' => q({0} kwadratne cóle),
						'name' => q(kwadratne cóle),
						'one' => q({0} kwadratny cól),
						'other' => q({0} kwadratnych cólow),
						'two' => q({0} kwadratnej cólaj),
					},
					'square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'two' => q({0} kwadratnej kilometraj),
					},
					'square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'two' => q({0} kwadratnej metraj),
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
						'two' => q({0} kwadratnej yardaj),
					},
					'tablespoon' => {
						'few' => q({0} łžicy),
						'name' => q(łžicy),
						'one' => q({0} łžica),
						'other' => q({0} łžicow),
						'two' => q({0} łžicy),
					},
					'teaspoon' => {
						'few' => q({0} łžički),
						'name' => q(łžički),
						'one' => q({0} łžička),
						'other' => q({0} łžičkow),
						'two' => q({0} łžičce),
					},
					'terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabitaj),
					},
					'terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabytey),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabyteaj),
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
						'two' => q({0} voltaj),
					},
					'watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} wattaj),
					},
					'week' => {
						'few' => q({0} tydźenje),
						'name' => q(tydźenje),
						'one' => q({0} tydźeń),
						'other' => q({0} tydźenjow),
						'two' => q({0} tydźenjej),
					},
					'yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yardaj),
					},
					'year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'two' => q({0} lěće),
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
						'one' => q({0} d),
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
						'few' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'two' => q({0} h),
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
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'two' => q({0} měs.),
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
						'few' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'two' => q({0} t.),
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
						'few' => q({0} š.),
						'name' => q(š.),
						'one' => q({0} š.),
						'other' => q({0} š.),
						'two' => q({0} š.),
					},
					'day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} dź.),
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
						'few' => q({0} hodź.),
						'name' => q(hodź.),
						'one' => q({0} hodź.),
						'other' => q({0} hodź.),
						'per' => q({0}/h),
						'two' => q({0} hodź.),
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
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'two' => q({0} měs.),
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
						'few' => q({0} tydź.),
						'name' => q(tydź.),
						'one' => q({0} tydź.),
						'other' => q({0} tydź.),
						'two' => q({0} tydź.),
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
	default		=> sub { qr'^(?i:haj|h|yes|y)$' }
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
					'two' => '0 milionaj',
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
					'two' => '0 miliardźe',
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
					'two' => '0 bilionaj',
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
				'two' => q(andorraskej peseće),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(ZAE dirham),
				'few' => q(SAE dirhamy),
				'one' => q(ZAE dirham),
				'other' => q(SAE dirhamow),
				'two' => q(ZAE dirhamaj),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghaniski afghani),
				'few' => q(afghaniske afghanije),
				'one' => q(afghaniski afghani),
				'other' => q(afghaniskich afghanijow),
				'two' => q(afghaniskej afghanijej),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albanski lek),
				'few' => q(albanske leki),
				'one' => q(albanski lek),
				'other' => q(albanskich lekow),
				'two' => q(albanskej lekaj),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenski dram),
				'few' => q(armenske dramy),
				'one' => q(armenski dram),
				'other' => q(armenskich dramow),
				'two' => q(armenskej dramaj),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nižozemsko-antilski gulden),
				'few' => q(nižozemsko-antilske guldeny),
				'one' => q(nižozemsko-antilski gulden),
				'other' => q(nižozemsko-antilskich guldenow),
				'two' => q(nižozemsko-antilskej guldenaj),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolska kwanza),
				'few' => q(angolske kwanzy),
				'one' => q(angolska kwanza),
				'other' => q(angolskich kwanzow),
				'two' => q(angolskej kwanzy),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolska kwanza \(1977–1990\)),
				'few' => q(angolske kwanzy \(1977–1990\)),
				'one' => q(angolska kwanza \(1977–1990\)),
				'other' => q(angolskich kwanzow \(1977–1990\)),
				'two' => q(angolskej kwanzy \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolska nowa kwanza \(1990–2000\)),
				'few' => q(angolske nowe kwanzy \(1990–2000\)),
				'one' => q(angolska nowa kwanza \(1990–2000\)),
				'other' => q(angolskich nowych kwanzow \(1990–2000\)),
				'two' => q(angolskej nowej kwanzy \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolska kwanza reajustado \(1995–1999\)),
				'few' => q(angolske kwanzy reajustado \(1995–1999\)),
				'one' => q(angolska kwanza reajustado \(1995–1999\)),
				'other' => q(angolskich kwanzow reajustado \(1995–1999\)),
				'two' => q(angolskej kwanzy reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinski austral),
				'few' => q(argentinske australe),
				'one' => q(argentinski austral),
				'other' => q(argentinskich australow),
				'two' => q(argentinskej australej),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinski peso \(1983–1985\)),
				'few' => q(argentinske pesa \(1983–1985\)),
				'one' => q(argentinski peso \(1983–1985\)),
				'other' => q(argentinskich pesow \(1983–1985\)),
				'two' => q(argentinskej pesaj \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinski peso),
				'few' => q(argentinske pesa),
				'one' => q(argentinski peso),
				'other' => q(argentinskich pesow),
				'two' => q(argentinskej pesaj),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(awstriski šiling),
				'few' => q(awstriske šilingi),
				'one' => q(awstriski šiling),
				'other' => q(awstriskich šilingow),
				'two' => q(awstriskej šilingaj),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(awstralski dolar),
				'few' => q(awstralske dolary),
				'one' => q(awstralski dolar),
				'other' => q(awstralskich dolarow),
				'two' => q(awstralskej dolaraj),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(aruba-florin),
				'few' => q(aruba-floriny),
				'one' => q(aruba-florin),
				'other' => q(aruba-florinow),
				'two' => q(aruba-florinaj),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdźanski manat \(1993–2006\)),
				'few' => q(azerbajdźanski manaty \(1993–2006\)),
				'one' => q(azerbajdźanski manat \(1993–2006\)),
				'other' => q(azerbajdźanski manatow \(1993–2006\)),
				'two' => q(azerbajdźanski manataj \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdźanski manat),
				'few' => q(azerbajdźanski manaty),
				'one' => q(azerbajdźanski manat),
				'other' => q(azerbajdźanski manatow),
				'two' => q(azerbajdźanski manataj),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosniski dinar),
				'few' => q(bosniske dinary),
				'one' => q(bosniski dinar),
				'other' => q(bosniskich dinarow),
				'two' => q(bosniskej dinaraj),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosniska konwertibelna hriwna),
				'few' => q(bosniske konwertibelne hriwny),
				'one' => q(bosniska konwertibelna hriwna),
				'other' => q(bosniskich konwertibelnych hriwnow),
				'two' => q(bosniskej konwertibelnej hriwnje),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoski dolar),
				'few' => q(barbadoske dolary),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskich dolarow),
				'two' => q(barbadoskej dolaraj),
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
				'two' => q(belgiskej frankaj \(konwertibelnej\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgiski frank),
				'few' => q(belgiske franki),
				'one' => q(belgiski frank),
				'other' => q(belgiskich frankow),
				'two' => q(belgiskej frankaj),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiski finančny frank),
				'few' => q(belgiske finančne franki),
				'one' => q(belgiski finančny frank),
				'other' => q(belgiskich finančnych frankow),
				'two' => q(belgiskej finančnej frankaj),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bołharski lew \(1962–1999\)),
				'few' => q(bołharske lewy \(1962–1999\)),
				'one' => q(bołharski lew \(1962–1999\)),
				'other' => q(bołharskich lewow \(1962–1999\)),
				'two' => q(bołharskej lewaj \(1962–1999\)),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bołharski lew),
				'few' => q(bołharske lewy),
				'one' => q(bołharski lew),
				'other' => q(bołharskich lewow),
				'two' => q(bołharskej lewaj),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainski dinar),
				'few' => q(bahrainske dinary),
				'one' => q(bahrainski dinar),
				'other' => q(bahrainskich dinarow),
				'two' => q(bahrainskej dinaraj),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiski frank),
				'few' => q(burundiske franki),
				'one' => q(burundiski frank),
				'other' => q(burundiskich frankow),
				'two' => q(burundiskej frankaj),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudaski dolar),
				'few' => q(bermudaske dolary),
				'one' => q(bermudaski dolar),
				'other' => q(bermudaskich dolarow),
				'two' => q(bermudaskej dolaraj),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiski dolar),
				'few' => q(bruneiske dolary),
				'one' => q(bruneiski dolar),
				'other' => q(bruneiskich dolarow),
				'two' => q(bruneiskej dolaraj),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliwiski boliviano),
				'few' => q(boliwiske boliviany),
				'one' => q(boliwiski boliviano),
				'other' => q(boliwiskich bolivianow),
				'two' => q(boliwiskej bolivianaj),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliwiski peso),
				'few' => q(boliwiske pesa),
				'one' => q(boliwiski peso),
				'other' => q(boliwiskich pesow),
				'two' => q(boliwiskej pesaj),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliwiski mvdol),
				'few' => q(boliwiske mvdole),
				'one' => q(boliwiski mvdol),
				'other' => q(boliwiskich mvdolow),
				'two' => q(boliwiskej mvdolej),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'few' => q(brazilske nowe cruzeiry \(1967–1986\)),
				'one' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'other' => q(brazilskich nowych cruzeirow \(1967–1986\)),
				'two' => q(brazilskej nowej cruzeiraj \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilski cruzado \(1986–1989\)),
				'few' => q(brazilske cruzady \(1986–1989\)),
				'one' => q(brazilski cruzado \(1986–1989\)),
				'other' => q(brazilskich cruzadow \(1986–1989\)),
				'two' => q(brazilskej cruzadaj \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1990–1993\)),
				'few' => q(brazilske cruzeiry \(1990–1993\)),
				'one' => q(brazilski cruzeiro \(1990–1993\)),
				'other' => q(brazilskich cruzeirow \(1990–1993\)),
				'two' => q(brazilskej cruzeiraj \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilske reale),
				'one' => q(brazilski real),
				'other' => q(brazilskich realow),
				'two' => q(brazilskej realej),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilski nowy cruzado \(1989–1990\)),
				'few' => q(brazilske nowe cruzady),
				'one' => q(brazilski nowy cruzado \(1989–1990\)),
				'other' => q(brazilskich nowych cruzadow),
				'two' => q(brazilskej nowej cruzadaj \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1993–1994\)),
				'few' => q(brazilske cruzeiry \(1993–1994\)),
				'one' => q(brazilski cruzeiro \(1993–1994\)),
				'other' => q(brazilskich cruzeirow \(1993–1994\)),
				'two' => q(brazilskej cruzeiraj \(1993–1994\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamaski dolar),
				'few' => q(bahamaske dolary),
				'one' => q(bahamaski dolar),
				'other' => q(bahamaskich dolarow),
				'two' => q(bahamaskej dolaraj),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanski ngultrum),
				'few' => q(bhutanske ngultrumy),
				'one' => q(bhutanski ngultrum),
				'other' => q(bhutanskich ngultrumow),
				'two' => q(bhutanskej ngultrumaj),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmaski kyat),
				'few' => q(burmaske kyaty),
				'one' => q(burmaski kyat),
				'other' => q(burmaskich kyatow),
				'two' => q(burmaskej kyataj),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanska pula),
				'few' => q(botswanske pule),
				'one' => q(botswanska pula),
				'other' => q(botswanskich pulow),
				'two' => q(botswanskej puli),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(běłoruski rubl \(1994–1999\)),
				'few' => q(běłoruske ruble \(1994–1999\)),
				'one' => q(běłoruski rubl \(1994–1999\)),
				'other' => q(běłoruskich rublow \(1994–1999\)),
				'two' => q(běłoruskej rublej \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(běłoruski rubl),
				'few' => q(běłoruske ruble),
				'one' => q(běłoruski rubl),
				'other' => q(běłoruskich rublow),
				'two' => q(běłoruskej rublej),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(běłoruski rubl \(2000–2016\)),
				'few' => q(běłoruske ruble \(2000–2016\)),
				'one' => q(běłoruski rubl \(2000–2016\)),
				'other' => q(běłoruskich rublow \(2000–2016\)),
				'two' => q(běłoruskej rublej \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizeski dolar),
				'few' => q(belizeske dolary),
				'one' => q(belizeski dolar),
				'other' => q(belizeskich dolarow),
				'two' => q(belizeskej dolaraj),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(kanadiski dolar),
				'few' => q(kanadiske dolary),
				'one' => q(kanadiski dolar),
				'other' => q(kanadiskich dolarow),
				'two' => q(kanadiskej dolaraj),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoski frank),
				'few' => q(kongoske franki),
				'one' => q(kongoski frank),
				'other' => q(kongoskich frankow),
				'two' => q(kongoskej frankaj),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(šwicarski frank),
				'few' => q(šwicarske franki),
				'one' => q(šwicarski frank),
				'other' => q(šwicarskich frankow),
				'two' => q(šwicarskej frankaj),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilski peso),
				'few' => q(chilske pesa),
				'one' => q(chilski peso),
				'other' => q(chilskich pesow),
				'two' => q(chilskej pesaj),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(chinski yuan),
				'few' => q(chinske yuany),
				'one' => q(chinski yuan),
				'other' => q(chinskich yuanow),
				'two' => q(chinskej yuanaj),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbiski peso),
				'few' => q(kolumbiske pesa),
				'one' => q(kolumbiski peso),
				'other' => q(kolumbiskich pesow),
				'two' => q(kolumbiskej pesaj),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kosta-rikaski colón),
				'few' => q(kosta-rikaske colóny),
				'one' => q(kosta-rikaski colón),
				'other' => q(kosta-rikaskich colónow),
				'two' => q(kosta-rikaskej colónaj),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubaski konwertibelny peso),
				'few' => q(kubaske konwertibelne pesa),
				'one' => q(kubaski konwertibelny peso),
				'other' => q(kubaskich konwertibelnych pesow),
				'two' => q(kubaskej konwertibelnej pesaj),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubaski peso),
				'few' => q(kubaske pesa),
				'one' => q(kubaski peso),
				'other' => q(kubaskich pesow),
				'two' => q(kubaskej pesaj),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdski escudo),
				'few' => q(kapverdske escuda),
				'one' => q(kapverdski escudo),
				'other' => q(kapverdskich escudow),
				'two' => q(kapverdskej escudaj),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(čěska króna),
				'few' => q(čěske króny),
				'one' => q(čěska króna),
				'other' => q(čěskich krónow),
				'two' => q(čěskej krónje),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(dźibutiski frank),
				'few' => q(dźibutiske franki),
				'one' => q(dźibutiski frank),
				'other' => q(dźibutiskich frankow),
				'two' => q(dźibutiskej frankaj),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(danska króna),
				'few' => q(danske króny),
				'one' => q(danska króna),
				'other' => q(danskich krónow),
				'two' => q(danskej krónje),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikanski peso),
				'few' => q(dominikanske pesa),
				'one' => q(dominikanski peso),
				'other' => q(dominikanskich pesow),
				'two' => q(dominikanskej pesaj),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algeriski dinar),
				'few' => q(algeriske dinary),
				'one' => q(algeriski dinar),
				'other' => q(algeriskich dinarow),
				'two' => q(algeriskej dinaraj),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptowski punt),
				'few' => q(egyptowske punty),
				'one' => q(egyptowski punt),
				'other' => q(egyptowskich puntow),
				'two' => q(egyptowskej puntaj),
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
				'few' => q(etiopiske birra),
				'one' => q(etiopiski birr),
				'other' => q(etiopiskich birrow),
				'two' => q(etiopiskej birraj),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'few' => q(eura),
				'one' => q(euro),
				'other' => q(eurow),
				'two' => q(euraj),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidźiski dolar),
				'few' => q(fidźiske dolary),
				'one' => q(fidźiski dolar),
				'other' => q(fidźiskich dolarow),
				'two' => q(fidźiskej dolaraj),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandski punt),
				'few' => q(falklandske punty),
				'one' => q(falklandski punt),
				'other' => q(falklandskich puntow),
				'two' => q(falklandskej puntaj),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(britiski punt),
				'few' => q(britiske punty),
				'one' => q(britiski punt),
				'other' => q(britiskich puntow),
				'two' => q(britiskej puntaj),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgiski lari),
				'few' => q(georgiske larije),
				'one' => q(georgiski lari),
				'other' => q(georgiskich larijow),
				'two' => q(georgiskej larijej),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanaski cedi),
				'few' => q(ghanaske cedije),
				'one' => q(ghanaski cedi),
				'other' => q(ghanaskich cedijow),
				'two' => q(ghanaskej cedaj),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarski punt),
				'few' => q(gibraltarske punty),
				'one' => q(gibraltarski punt),
				'other' => q(gibraltarskich puntow),
				'two' => q(gibraltarskej puntaj),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiski dalasi),
				'few' => q(gambiske dalasije),
				'one' => q(gambiski dalasi),
				'other' => q(gambiskich dalasijow),
				'two' => q(gambiskej dalasijej),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(ginejski frank),
				'few' => q(ginejske franki),
				'one' => q(ginejski frank),
				'other' => q(ginejskich frankow),
				'two' => q(ginejskej frankaj),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalski quetzal),
				'few' => q(guatemalske quetzale),
				'one' => q(guatemalski quetzal),
				'other' => q(guatemalskich quetzalow),
				'two' => q(guatemalskej quetzalej),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(ginejsko-bissauski peso),
				'few' => q(ginejsko-bissauske pesa),
				'one' => q(ginejsko-bissauski peso),
				'other' => q(ginejsko-bissauskich pesow),
				'two' => q(ginejsko-bissauskej pesaj),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanski dolar),
				'few' => q(guyanske dolary),
				'one' => q(guyanski dolar),
				'other' => q(guyanskich dolarow),
				'two' => q(guyanskej dolaraj),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(hongkongski dolar),
				'few' => q(hongkongske dolary),
				'one' => q(hongkongski dolar),
				'other' => q(hongkongskich dolarow),
				'two' => q(hongkongskej dolaraj),
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
				'two' => q(haitiskej gourdźe),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(madźarski forint),
				'few' => q(madźarske forinty),
				'one' => q(madźarski forint),
				'other' => q(madźarskich forintow),
				'two' => q(madźarskej forintaj),
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
				'two' => q(israelskej nowej šekelej),
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
				'two' => q(irakskej dinaraj),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranski rial),
				'few' => q(iranske riale),
				'one' => q(iranski rial),
				'other' => q(iranskich rialow),
				'two' => q(iranskej rialej),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandska króna),
				'few' => q(islandske króny),
				'one' => q(islandska króna),
				'other' => q(islandskich krónow),
				'two' => q(islandskej krónje),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaiski dolar),
				'few' => q(jamaiske dolary),
				'one' => q(jamaiski dolar),
				'other' => q(jamaiskich dolarow),
				'two' => q(jamaiskej dolaraj),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordaniski dinar),
				'few' => q(jordaniske dinary),
				'one' => q(jordaniski dinar),
				'other' => q(jordaniskich dinarow),
				'two' => q(jordaniskej dinaraj),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japanski yen),
				'few' => q(japanske yeny),
				'one' => q(japanski yen),
				'other' => q(japanskich yenow),
				'two' => q(japanskej yenaj),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(keniaski šiling),
				'few' => q(keniaske šilingi),
				'one' => q(keniaski šiling),
				'other' => q(keniaskich šilingow),
				'two' => q(keniaskej šilingaj),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiski som),
				'few' => q(kirgiske somy),
				'one' => q(kirgiski som),
				'other' => q(kirgiskich somow),
				'two' => q(kirgiskej somaj),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodźaski riel),
				'few' => q(kambodźaske riele),
				'one' => q(kambodźaski riel),
				'other' => q(kambodźaskich rielow),
				'two' => q(kambodźaskej rielej),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorski frank),
				'few' => q(komorske franki),
				'one' => q(komorski frank),
				'other' => q(komorskich frankow),
				'two' => q(komorskej frankaj),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(sewjernokorejski won),
				'few' => q(sewjernokorejske wony),
				'one' => q(sewjernokorejski won),
				'other' => q(sewjernokorejskich wonow),
				'two' => q(sewjernokorejskej wonaj),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(južnokorejski won),
				'few' => q(južnokorejske wony),
				'one' => q(južnokorejski won),
				'other' => q(južnokorejskich wonow),
				'two' => q(južnokorejskej wonaj),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitski dinar),
				'few' => q(kuwaitske dinary),
				'one' => q(kuwaitski dinar),
				'other' => q(kuwaitskich dinarow),
				'two' => q(kuwaitskej dinaraj),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmanski dolar),
				'few' => q(kajmanske dolary),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskich dolarow),
				'two' => q(kajmanskej dolaraj),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazachski tenge),
				'few' => q(kazachske tengi),
				'one' => q(kazachski tenge),
				'other' => q(kazachskich tengow),
				'two' => q(kazachskej tengaj),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoski kip),
				'few' => q(laoske kipy),
				'one' => q(laoski kip),
				'other' => q(laoskich kipow),
				'two' => q(laoskej kipaj),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanonski punt),
				'few' => q(libanonske punty),
				'one' => q(libanonski punt),
				'other' => q(libanonskich puntow),
				'two' => q(libanonskej puntaj),
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
				'two' => q(liberiskej dolaraj),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litawski litas),
				'few' => q(litawske litasy),
				'one' => q(litawski litas),
				'other' => q(litawskich litasow),
				'two' => q(litawskej litasaj),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(letiski lat),
				'few' => q(letiske laty),
				'one' => q(letiski lat),
				'other' => q(letiskich latow),
				'two' => q(letiskej lataj),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyski dinar),
				'few' => q(libyske dinary),
				'one' => q(libyski dinar),
				'other' => q(libyskich dinarow),
				'two' => q(libyskej dinaraj),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkoski dirham),
				'few' => q(marokkoske dirhamy),
				'one' => q(marokkoski dirham),
				'other' => q(marokkoskich dirhamow),
				'two' => q(marokkoskej dirhamaj),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldawski leu),
				'few' => q(moldawske leuwy),
				'one' => q(moldawski leu),
				'other' => q(moldawskich leuwow),
				'two' => q(moldawskej leuwaj),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskarski ariary),
				'few' => q(madagaskarske ariaryje),
				'one' => q(madagaskarski ariary),
				'other' => q(madagaskarskich ariaryjow),
				'two' => q(madagaskarskej ariaryjej),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonski denar),
				'few' => q(makedonske denary),
				'one' => q(makedonski denar),
				'other' => q(makedonskich denarow),
				'two' => q(makedonskej denaraj),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarski kyat),
				'few' => q(myanmarske kyaty),
				'one' => q(myanmarski kyat),
				'other' => q(myanmarskich kyatow),
				'two' => q(myanmarskej kyataj),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolske tugriki),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskich tugrikow),
				'two' => q(mongolskej tugrikaj),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macaoska pataka),
				'few' => q(macaoske pataki),
				'one' => q(macaoska pataka),
				'other' => q(macaoskich patakow),
				'two' => q(macaoskej patace),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mawretanska ouguiya \(1973–2017\)),
				'few' => q(mawretanske ouguije \(1973–2017\)),
				'one' => q(mawretanska ouguiya \(1973–2017\)),
				'other' => q(mawretanskich ouguijow \(1973–2017\)),
				'two' => q(mawretanskej ouguiji \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mawretanska ouguiya),
				'few' => q(mawretanske ouguije),
				'one' => q(mawretanska ouguiya),
				'other' => q(mawretanskich ouguijow),
				'two' => q(mawretanskej ouguiji),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritiuska rupija),
				'few' => q(mauritiuske rupije),
				'one' => q(mauritiuska rupija),
				'other' => q(mauritiuskich rupijow),
				'two' => q(mauritiuskej rupiji),
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
				'few' => q(malawiske kwachi),
				'one' => q(malawiski kwacha),
				'other' => q(malawiskich kwachow),
				'two' => q(malawiskej kwachaj),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(mexiski peso),
				'few' => q(mexiske pesa),
				'one' => q(mexiski peso),
				'other' => q(mexiskich pesow),
				'two' => q(mexiskej pesaj),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajziski ringgit),
				'few' => q(malajziske ringgity),
				'one' => q(malajziski ringgit),
				'other' => q(malajziskich ringgitow),
				'two' => q(malajziskej ringgitaj),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mosambikski escudo),
				'few' => q(mosambikske escuda),
				'one' => q(mosambikski escudo),
				'other' => q(mosambikskich escudow),
				'two' => q(mosambikskej escudaj),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mosambikski metical \(1980–2006\)),
				'few' => q(mosambikske meticale \(1980–2006\)),
				'one' => q(mosambikski metical \(1980–2006\)),
				'other' => q(mosambikskich meticalow \(1980–2006\)),
				'two' => q(mosambikskej meticalej \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mosambikski metical),
				'few' => q(mosambikske meticale),
				'one' => q(mosambikski metical),
				'other' => q(mosambikskich meticalow),
				'two' => q(mosambikskej meticalej),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiski dolar),
				'few' => q(namibiske dolary),
				'one' => q(namibiski dolar),
				'other' => q(namibiskich dolarow),
				'two' => q(namibiskej dolaraj),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriski naira),
				'few' => q(nigeriske nairy),
				'one' => q(nigeriski naira),
				'other' => q(nigeriskich nairow),
				'two' => q(nigeriskej nairaj),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaraguaski cordoba),
				'few' => q(nikaraguaske cordoby),
				'one' => q(nikaraguaski cordoba),
				'other' => q(nikaraguaskich cordobow),
				'two' => q(nikaraguaskej cordobaj),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norwegska króna),
				'few' => q(norwegske króny),
				'one' => q(norwegska króna),
				'other' => q(norwegskich krónow),
				'two' => q(norwegskej krónje),
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
				'two' => q(nowoseelandskej dolaraj),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanski rial),
				'few' => q(omanske riale),
				'one' => q(omanski rial),
				'other' => q(omanskich rialow),
				'two' => q(omanskej rialej),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamaski balboa),
				'few' => q(panamaske balbowy),
				'one' => q(panamaski balboa),
				'other' => q(panamaskich balbowow),
				'two' => q(panamaskej balbowaj),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruski sol),
				'few' => q(peruske sole),
				'one' => q(peruski sol),
				'other' => q(peruskich solow),
				'two' => q(peruskej solej),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua-nowoginejski kina),
				'few' => q(papua-nowoginejske kiny),
				'one' => q(papua-nowoginejski kina),
				'other' => q(papua-nowoginejskich kinow),
				'two' => q(papua-nowoginejskej kinaj),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipinski peso),
				'few' => q(filipinske pesa),
				'one' => q(filipinski peso),
				'other' => q(filipinskich pesow),
				'two' => q(filipinskej pesaj),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskich rupijow),
				'two' => q(pakistanskej rupiji),
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
				'two' => q(paraguayskej guaranijej),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarski rial),
				'few' => q(katarske riale),
				'one' => q(katarski rial),
				'other' => q(katarskich rialow),
				'two' => q(katarskej rialej),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumunski leu),
				'few' => q(rumunske leuwy),
				'one' => q(rumunski leu),
				'other' => q(rumunskich leuwow),
				'two' => q(rumunskej leuwaj),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiski dinar),
				'few' => q(serbiske dinary),
				'one' => q(serbiski dinar),
				'other' => q(serbiskich dinarow),
				'two' => q(serbiskej dinaraj),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruski rubl),
				'few' => q(ruske ruble),
				'one' => q(ruski rubl),
				'other' => q(ruskich rublow),
				'two' => q(ruskej rublej),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandiski frank),
				'few' => q(ruandiske franki),
				'one' => q(ruandiski frank),
				'other' => q(ruandiskich frankow),
				'two' => q(ruandiskej frankaj),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudi-arabski rial),
				'few' => q(saudi-arabske riale),
				'one' => q(saudi-arabski rial),
				'other' => q(saudi-arabskich rialow),
				'two' => q(saudi-arabskej rialej),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomonski dolar),
				'few' => q(salomonske dolary),
				'one' => q(salomonski dolar),
				'other' => q(salomonskich dolarow),
				'two' => q(salomonskej dolaraj),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychellska rupija),
				'few' => q(seychellske rupije),
				'one' => q(seychellska rupija),
				'other' => q(seychellskich rupijow),
				'two' => q(seychellskej rupiji),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanski punt),
				'few' => q(sudanske punty),
				'one' => q(sudanski punt),
				'other' => q(sudanskich puntow),
				'two' => q(sudanskej puntaj),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(šwedska króna),
				'few' => q(šwedske króny),
				'one' => q(šwedska króna),
				'other' => q(šwedskich krónow),
				'two' => q(šwedskej krónje),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurske dolary),
				'one' => q(singapurski dolar),
				'other' => q(singapurskich dolarow),
				'two' => q(singapurskej dolaraj),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helenski punt),
				'few' => q(St. Helenske punty),
				'one' => q(St. Helenski punt),
				'other' => q(St. Helenskich puntow),
				'two' => q(St. Helenskej puntaj),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierra-leoneski leone),
				'few' => q(sierra-leoneske leony),
				'one' => q(sierra-leoneski leone),
				'other' => q(sierra-leoneskich leonow),
				'two' => q(sierra-leoneskej leonaj),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliski šiling),
				'few' => q(somaliske šilingi),
				'one' => q(somaliski šiling),
				'other' => q(somaliskich šilingow),
				'two' => q(somaliskej šilingaj),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamske dolary),
				'one' => q(surinamski dolar),
				'other' => q(surinamskich dolarow),
				'two' => q(surinamskej dolaraj),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(južnosudanski punt),
				'few' => q(južnosudanske punty),
				'one' => q(južnosudanski punt),
				'other' => q(južnosudanskich puntow),
				'two' => q(južnosudanskej puntaj),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(são tomeski dobra \(1977–2017\)),
				'few' => q(são tomeske dobry \(1977–2017\)),
				'one' => q(são tomeski dobra \(1977–2017\)),
				'other' => q(são tomeskich dobrow \(1977–2017\)),
				'two' => q(são tomeskej dobraj \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(são tomeski dobra),
				'few' => q(são tomeske dobry),
				'one' => q(são tomeski dobra),
				'other' => q(são tomeskich dobrow),
				'two' => q(são tomeskej dobraj),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(el salvadorski colón),
				'few' => q(el salvadorske colóny),
				'one' => q(el salvadorski colón),
				'other' => q(el salvadorskich colónow),
				'two' => q(el salvadorskej colónaj),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriski punt),
				'few' => q(syriske punty),
				'one' => q(syriski punt),
				'other' => q(syriskich puntow),
				'two' => q(syriskej puntaj),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swasiski lilangeni),
				'few' => q(swasiske lilangenije),
				'one' => q(swasiski lilangeni),
				'other' => q(swasiskich lilangenijow),
				'two' => q(swasiskej lilangenijej),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(thaiski baht),
				'few' => q(thaiske bahty),
				'one' => q(thaiski baht),
				'other' => q(thaiskich bahtow),
				'two' => q(thaiskej bahtaj),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadźikski somoni),
				'few' => q(tadźikske somonije),
				'one' => q(tadźikski somoni),
				'other' => q(tadźikskich somonijow),
				'two' => q(tadźikskej somonijej),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenski manat),
				'few' => q(turkmenske manaty),
				'one' => q(turkmenski manat),
				'other' => q(turkmenskich manatow),
				'two' => q(turkmenskej manataj),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuneziski dinar),
				'few' => q(tuneziske dinary),
				'one' => q(tuneziski dinar),
				'other' => q(tuneziskich dinarow),
				'two' => q(tuneziskej dinaraj),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongaski paʻanga),
				'few' => q(tongaske pa’angi),
				'one' => q(tongaski pa’anga),
				'other' => q(tongaskich pa’angow),
				'two' => q(tongaskej pa’angaj),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turkowska lira),
				'few' => q(turkowske liry),
				'one' => q(turkowska lira),
				'other' => q(turkowskich lirow),
				'two' => q(turkowskej lirje),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidad-tobagoski dolar),
				'few' => q(trinidad-tobagoske dolary),
				'one' => q(trinidad-tobagoski dolar),
				'other' => q(trinidad-tobagoskich dolarow),
				'two' => q(trinidad-tobagoskej dolaraj),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(nowy taiwanski dolar),
				'few' => q(nowe taiwanske dolary),
				'one' => q(nowy taiwanski dolar),
				'other' => q(nowych taiwanskich dolarow),
				'two' => q(nowej taiwanskej dolaraj),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tansaniski šiling),
				'few' => q(tansaniske šilingi),
				'one' => q(tansaniski šiling),
				'other' => q(tansaniskich šilingow),
				'two' => q(tansaniskej šilingaj),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainska hriwna),
				'few' => q(ukrainske hriwny),
				'one' => q(ukrainska hriwna),
				'other' => q(ukrainskich hriwnow),
				'two' => q(ukrainskej hriwnje),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandaski šiling),
				'few' => q(ugandaske šilingi),
				'one' => q(ugandaski šiling),
				'other' => q(ugandaskich šilingow),
				'two' => q(ugandaskej šilingaj),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ameriski dolar),
				'few' => q(ameriske dolary),
				'one' => q(ameriski dolar),
				'other' => q(ameriskich dolarow),
				'two' => q(ameriskej dolaraj),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayski peso),
				'few' => q(uruguayske pesa),
				'one' => q(uruguayski peso),
				'other' => q(uruguayskich pesow),
				'two' => q(uruguayskej pesaj),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbekski sum),
				'few' => q(uzbekske sumy),
				'one' => q(uzbekski sum),
				'other' => q(uzbekskich sumow),
				'two' => q(uzbekskej sumaj),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelski bolívar \(2008–2018\)),
				'few' => q(venezuelske bolívary \(2008–2018\)),
				'one' => q(venezuelski bolívar \(2008–2018\)),
				'other' => q(venezuelskich bolívarow \(2008–2018\)),
				'two' => q(venezuelskej bolívaraj \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelski bolívar),
				'few' => q(venezuelske bolívary),
				'one' => q(venezuelski bolívar),
				'other' => q(venezuelskich bolívarow),
				'two' => q(venezuelskej bolívaraj),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(vietnamski dong),
				'few' => q(vietnamske dongi),
				'one' => q(vietnamski dong),
				'other' => q(vietnamskich dongow),
				'two' => q(vietnamskej dongaj),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuski vatu),
				'few' => q(vanuatuske vatuwy),
				'one' => q(vanuatuski vatu),
				'other' => q(vanuatuskich vatuwow),
				'two' => q(vanuatuskej vatuwaj),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoaski tala),
				'few' => q(samoaske tale),
				'one' => q(samoaski tala),
				'other' => q(samoaskich talow),
				'two' => q(samoaskej talej),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA-frank \(BEAC\)),
				'few' => q(CFA-franki \(BEAC\)),
				'one' => q(CFA-frank \(BEAC\)),
				'other' => q(CFA-frankow \(BEAC\)),
				'two' => q(CFA-frankaj \(BEAC\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(wuchodnokaribiski dolar),
				'few' => q(wuchodnokaribiske dolary),
				'one' => q(wuchodnokaribiski dolar),
				'other' => q(wuchodnokaribiskich dolarow),
				'two' => q(wuchodnokaribiskej dolaraj),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA-frank \(BCEAO\)),
				'few' => q(CFA-franki \(BCEAO\)),
				'one' => q(CFA-frank \(BCEAO\)),
				'other' => q(CFA-frankow \(BCEAO\)),
				'two' => q(CFA-frankaj \(BCEAO\)),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-frank),
				'few' => q(CFP-franki),
				'one' => q(CFP-frank),
				'other' => q(CFP-frankow),
				'two' => q(CFP-frankaj),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(njeznata měna),
				'few' => q(njeznate měny),
				'one' => q(njeznata měna),
				'other' => q(njeznatych měnow),
				'two' => q(njeznatej měnje),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenski rial),
				'few' => q(jemenske riale),
				'one' => q(jemenski rial),
				'other' => q(jemenskich rialow),
				'two' => q(jemenskej rialej),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(južnoafriski rand),
				'few' => q(južnoafriske randy),
				'one' => q(južnoafriski rand),
				'other' => q(južnoafriskich randow),
				'two' => q(južnoafriskej randaj),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(sambiski kwacha),
				'few' => q(sambiske kwachi),
				'one' => q(sambiski kwacha),
				'other' => q(sambiskich kwachow),
				'two' => q(sambiskej kwachaj),
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
							'mej.',
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
							'meje',
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
							'mej',
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
							'meja',
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
						tue => 'wut',
						wed => 'srj',
						thu => 'štw',
						fri => 'pja',
						sat => 'sob',
						sun => 'nje'
					},
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 'š',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
						mon => 'pó',
						tue => 'wu',
						wed => 'sr',
						thu => 'št',
						fri => 'pj',
						sat => 'so',
						sun => 'nj'
					},
					wide => {
						mon => 'póndźela',
						tue => 'wutora',
						wed => 'srjeda',
						thu => 'štwórtk',
						fri => 'pjatk',
						sat => 'sobota',
						sun => 'njedźela'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'pón',
						tue => 'wut',
						wed => 'srj',
						thu => 'štw',
						fri => 'pja',
						sat => 'sob',
						sun => 'nje'
					},
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 'š',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
						mon => 'pó',
						tue => 'wu',
						wed => 'sr',
						thu => 'št',
						fri => 'pj',
						sat => 'so',
						sun => 'nj'
					},
					wide => {
						mon => 'póndźela',
						tue => 'wutora',
						wed => 'srjeda',
						thu => 'štwórtk',
						fri => 'pjatk',
						sat => 'sobota',
						sun => 'njedźela'
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
				'abbreviated' => {
					'am' => q{dopołdnja},
					'pm' => q{popołdnju},
				},
				'narrow' => {
					'am' => q{dop.},
					'pm' => q{pop.},
				},
				'wide' => {
					'am' => q{dopołdnja},
					'pm' => q{popołdnju},
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
				'0' => 'př.Chr.n.',
				'1' => 'po Chr.n.'
			},
			wide => {
				'0' => 'před Chrystowym narodźenjom',
				'1' => 'po Chrystowym narodźenju'
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
			'short' => q{H:mm 'hodź'.},
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E, H:mm 'hodź'.},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{H 'hodź'.},
			Hm => q{H:mm 'hodź'.},
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
		'gregorian' => {
			H => {
				H => q{H–H 'hodź'.},
			},
			Hm => {
				H => q{H:mm – H:mm 'hodź'.},
				m => q{H:mm – H:mm 'hodź'.},
			},
			Hmv => {
				H => q{H:mm – H:mm 'hodź'. v},
				m => q{H:mm – H:mm 'hodź'. v},
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
		regionFormat => q(časowe pasmo {0}),
		regionFormat => q({0} lětni čas),
		regionFormat => q({0} zymski čas),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#afghanski čas#,
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
			exemplarCity => q#Dźibuti#,
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
				'standard' => q#centralnoafriski čas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#wuchodoafriski čas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#južnoafriski čas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#zapadoafriski lětni čas#,
				'generic' => q#zapadoafriski čas#,
				'standard' => q#zapadoafriski standardny čas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskaski lětni čas#,
				'generic' => q#alaskaski čas#,
				'standard' => q#alaskaski standardny čas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amaconaski lětni čas#,
				'generic' => q#Amaconaski čas#,
				'standard' => q#Amaconaski standardny čas#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimanske kupy#,
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
			exemplarCity => q#Mexiko město#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Sewjerna Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Sewjerna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Sewjerna Dakota#,
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
				'daylight' => q#sewjeroameriski centralny lětni čas#,
				'generic' => q#sewjeroameriski centralny čas#,
				'standard' => q#sewjeroameriski centralny standardny čas#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#sewjeroameriski wuchodny lětni čas#,
				'generic' => q#sewjeroameriski wuchodny čas#,
				'standard' => q#sewjeroameriski wuchodny standardny čas#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#sewjeroameriski hórski lětni čas#,
				'generic' => q#sewjeroameriski hórski čas#,
				'standard' => q#sewjeroameriski hórski standardny čas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#sewjeroameriski pacifiski lětni čas#,
				'generic' => q#sewjeroameriski pacifiski čas#,
				'standard' => q#sewjeroameriski pacifiski standardny čas#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont D’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Antarktika/Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiaski lětni čas#,
				'generic' => q#Apiaski čas#,
				'standard' => q#Apiaski standardny čas#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabski lětni čas#,
				'generic' => q#arabski čas#,
				'standard' => q#arabski standardny čas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinski lětni čas#,
				'generic' => q#argentinski čas#,
				'standard' => q#argentinski standardny čas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#zapadoargentinski lětni čas#,
				'generic' => q#zapadoargentinski čas#,
				'standard' => q#zapadoargentinski standardny čas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armenski lětni čas#,
				'generic' => q#armenski čas#,
				'standard' => q#armenski standardny čas#,
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
			exemplarCity => q#Nowokuznjeck#,
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
			exemplarCity => q#Ho Chi Minhowe město#,
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
			exemplarCity => q#Jerjewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantiski lětni čas#,
				'generic' => q#atlantiski čas#,
				'standard' => q#atlantiski standardny čas#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Acory#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariske kupy#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöske kupy#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južna Georgiska#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#srjedźoawstralski lětni čas#,
				'generic' => q#srjedźoawstralski čas#,
				'standard' => q#srjedźoawstralski standardny čas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#sjedźozapadny awstralski lětni čas#,
				'generic' => q#srjedźozapadny awstralski čas#,
				'standard' => q#srjedźozapadny awstralski standardny čas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#wuchodoawstralski lětni čas#,
				'generic' => q#wuchodoawstralski čas#,
				'standard' => q#wuchodoawstralski standardny čas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#zapadoawstralski lětni čas#,
				'generic' => q#zapadoawstralski čas#,
				'standard' => q#zapadoawstralski standardny čas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajdźanski lětni čas#,
				'generic' => q#azerbajdźanski čas#,
				'standard' => q#azerbajdźanski standardny čas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#acorski lětni čas#,
				'generic' => q#acorski čas#,
				'standard' => q#acorski standardny čas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladešski lětni čas#,
				'generic' => q#bangladešski čas#,
				'standard' => q#bangladešski standardny čas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#bhutanski čas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#boliwiski čas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiliski lětni čas#,
				'generic' => q#Brasiliski čas#,
				'standard' => q#Brasiliski standardny čas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#bruneiski čas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kapverdski lětni čas#,
				'generic' => q#kapverdski čas#,
				'standard' => q#kapverdski standardny čas#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#chamorroski čas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#chathamski lětni čas#,
				'generic' => q#chathamski čas#,
				'standard' => q#chathamski standardny čas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilski lětni čas#,
				'generic' => q#chilski čas#,
				'standard' => q#chilski standardny čas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#chinski lětni čas#,
				'generic' => q#chinski čas#,
				'standard' => q#chinski standardny čas#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Čojbalsanski lětni čas#,
				'generic' => q#Čojbalsanski čas#,
				'standard' => q#Čojbalsanski standardny čas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#čas Hodowneje kupy#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#čas Kokosowych kupow#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolumbiski lětni čas#,
				'generic' => q#kolumbiski čas#,
				'standard' => q#kolumbiski standardny čas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#lětni čas Cookowych kupow#,
				'generic' => q#čas Cookowych kupow#,
				'standard' => q#standardny čas Cookowych kupow#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubaski lětni čas#,
				'generic' => q#kubaski čas#,
				'standard' => q#kubaski standardny čas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Daviski čas#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont d´ Urvilleski čas#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#wuchodnotimorski čas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#lětni čas Jutrowneje kupy#,
				'generic' => q#čas Jutrowneje kupy#,
				'standard' => q#standardny čas Jutrowneje kupy#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ekwadorski čas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#njeznate#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Běłohród#,
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
			exemplarCity => q#Kišinjow#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irski lětni čas#,
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
				'daylight' => q#Britiski lětni čas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
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
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Waršawa#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporižžja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#srjedźoeuropski lětni čas#,
				'generic' => q#srjedźoeuropski čas#,
				'standard' => q#srjedźoeuropski standardny čas#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#wuchodoeuropski lětni čas#,
				'generic' => q#wuchodoeuropski čas#,
				'standard' => q#wuchodoeuropski standardny čas#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningradski čas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#zapadoeuropski lětni čas#,
				'generic' => q#zapadoeuropski čas#,
				'standard' => q#zapadoeuropski standardny čas#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falklandski lětni čas#,
				'generic' => q#falklandski čas#,
				'standard' => q#falklandski standardny čas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fidźiski lětni čas#,
				'generic' => q#fidźiski čas#,
				'standard' => q#fidźiski standardny čas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#francoskoguyanski čas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#čas Francoskeho južneho a antarktiskeho teritorija#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichski čas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#galapagoski čas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#gambierski čas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#georgiski lětni čas#,
				'generic' => q#georgiski čas#,
				'standard' => q#georgiski standardny čas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#čas Gilbertowych kupow#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#wuchodogrönlandski lětni čas#,
				'generic' => q#wuchodogrönlandski čas#,
				'standard' => q#wuchodogrönlandski standardny čas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#zapadogrönlandski lětni čas#,
				'generic' => q#zapadogrönlandski čas#,
				'standard' => q#zapadogrönlandski standardny čas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#čas Persiskeho golfa#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyanski čas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#hawaiisko-aleutski lětni čas#,
				'generic' => q#hawaiisko-aleutski čas#,
				'standard' => q#hawaiisko-aleutski standardny čas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongski lětni čas#,
				'generic' => q#Hongkongski čas#,
				'standard' => q#Hongkongski standardny čas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chowdski lětni čas#,
				'generic' => q#Chowdski čas#,
				'standard' => q#Chowdski standardny čas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indiski čas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Hodowna kupa#,
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
				'standard' => q#indiskooceanski čas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indochinski čas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#srjedźoindoneski čas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#wuchodoindoneski#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#zapadoindoneski čas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iranski lětni čas#,
				'generic' => q#iranski čas#,
				'standard' => q#iranski standardny čas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutski lětni čas#,
				'generic' => q#Irkutski čas#,
				'standard' => q#Irkutski standardny čas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israelski lětni čas#,
				'generic' => q#israelski čas#,
				'standard' => q#israelski standardny čas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japanski lětni čas#,
				'generic' => q#japanski čas#,
				'standard' => q#japanski standardny čas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#wuchodnokazachski čas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#zapadnokazachski čas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korejski lětni čas#,
				'generic' => q#korejski čas#,
				'standard' => q#korejski standardny čas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#kosraeski čas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarski lětni čas#,
				'generic' => q#Krasnojarski čas#,
				'standard' => q#Krasnojarski standardny čas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgiski čas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#čas Linijowych kupow#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#lětni čas kupy Lord-Howe#,
				'generic' => q#čas kupy Lord-Howe#,
				'standard' => q#standardny čas kupy Lord-Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#čas kupy Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadanski lětni čas#,
				'generic' => q#Magadanski čas#,
				'standard' => q#Magadanski standardny čas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malajziski čas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#malediwski čas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#marquesaski čas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#čas Marshallowych kupow#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauritiuski lětni čas#,
				'generic' => q#mauritiuski čas#,
				'standard' => q#mauritiuski standardny čas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsonski čas#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#mexiski sewjerozapadny lětni čas#,
				'generic' => q#mexiski sewjerozapadny čas#,
				'standard' => q#mexiski sewjerozapadny standardny čas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexiski pacifiski lětni čas#,
				'generic' => q#mexiski pacifiski čas#,
				'standard' => q#mexiski pacifiski standardny čas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Batorski lětni čas#,
				'generic' => q#Ulan-Batorski čas#,
				'standard' => q#Ulan-Batorski standardny čas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskowski lětni čas#,
				'generic' => q#Moskowski čas#,
				'standard' => q#Moskowski standardny čas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#myanmarski čas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#nauruski čas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepalski čas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#nowokaledonski lětni čas#,
				'generic' => q#nowokaledonski čas#,
				'standard' => q#nowokaledonski standardny čas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#nowoseelandski lětni čas#,
				'generic' => q#nowoseelandski čas#,
				'standard' => q#nowoseelandski standardny čas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#nowofundlandski lětni čas#,
				'generic' => q#nowofundlandski čas#,
				'standard' => q#nowofundlandski standardny čas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niueski čas#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#čas kupy Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#lětni čas kupow Fernando de Noronha#,
				'generic' => q#čas kupow Fernando de Noronha#,
				'standard' => q#standardny čas kupow Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirski lětni čas#,
				'generic' => q#Nowosibirski čas#,
				'standard' => q#Nowosibirski standardny čas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omski lětni čas#,
				'generic' => q#Omski čas#,
				'standard' => q#Omski standardny čas#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Jutrowna kupa#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidźi#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistanski lětni čas#,
				'generic' => q#pakistanski čas#,
				'standard' => q#pakistanski standardny čas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palauski čas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#papua-nowoginejski čas#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayski lětni čas#,
				'generic' => q#Paraguayski čas#,
				'standard' => q#Paraguayski standardny čas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruski lětni čas#,
				'generic' => q#peruski čas#,
				'standard' => q#peruski standardny čas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filipinski lětni čas#,
				'generic' => q#filipinski čas#,
				'standard' => q#filipinski standardny čas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#čas Phoenixowych kupow#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#lětni čas kupow St. Pierre a Miquelon#,
				'generic' => q#čas kupow St. Pierre a Miquelon#,
				'standard' => q#standardny čas kupow St. Pierre a Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#čas Pitcairnowych kupow#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ponapeski čas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#reunionski čas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotheraski čas#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sachalinski lětni čas#,
				'generic' => q#sachalinski čas#,
				'standard' => q#sachalinski standardny čas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoaski lětni čas#,
				'generic' => q#samoaski čas#,
				'standard' => q#samoaski standardny čas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychellski čas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurski čas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#čas Salomonskich kupow#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#južnogeorgiski čas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamski čas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowaski čas#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitiski čas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipehski lětni čas#,
				'generic' => q#Taipehski čas#,
				'standard' => q#Taipehski standardny čas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tadźikski čas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tokelauski čas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tongaski lětni čas#,
				'generic' => q#tongaski čas#,
				'standard' => q#tongaski standardny čas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#chuukski čas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmenski lětni čas#,
				'generic' => q#turkmenski čas#,
				'standard' => q#turkmenski standardny čas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvaluski čas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayski lětni čas#,
				'generic' => q#uruguayski čas#,
				'standard' => q#uruguayski standardny čas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbekski lětni čas#,
				'generic' => q#uzbekski čas#,
				'standard' => q#uzbekski standardny čas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatuski lětni čas#,
				'generic' => q#vanuatuski čas#,
				'standard' => q#vanuatuski standardny čas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelski čas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostokski lětni čas#,
				'generic' => q#Wladiwostokski čas#,
				'standard' => q#Wladiwostokski standardny čas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgogradski lětni čas#,
				'generic' => q#Wolgogradski čas#,
				'standard' => q#Wolgogradski standardny čas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostokski čas#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#čas kupy Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#čas kupow Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutski lětni čas#,
				'generic' => q#Jakutski čas#,
				'standard' => q#Jakutski standardny čas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgski lětni čas#,
				'generic' => q#Jekaterinburgski čas#,
				'standard' => q#Jekaterinburgski standardny čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
