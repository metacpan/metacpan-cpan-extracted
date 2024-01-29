=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Hsb - Package for language Upper Sorbian

=cut

package Locale::CLDR::Locales::Hsb;
# This file auto generated from Data\common\main\hsb.xml
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
 				'bas' => 'basaa',
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
 				'ccp' => 'čakma',
 				'ce' => 'čečenšćina',
 				'ceb' => 'cebuanšćina',
 				'cgg' => 'chiga',
 				'ch' => 'čamoršćina',
 				'cho' => 'choctawšćina',
 				'chr' => 'cherokee',
 				'ckb' => 'sorani',
 				'ckb@alt=variant' => 'centralna kurdišćina',
 				'co' => 'korsišćina',
 				'cr' => 'kri',
 				'cs' => 'čěšćina',
 				'cu' => 'cyrkwinosłowjanšćina',
 				'cy' => 'walizišćina',
 				'da' => 'danšćina',
 				'dav' => 'taita',
 				'de' => 'němčina',
 				'de_AT' => 'awstriska němčina',
 				'de_CH' => 'šwicarska wysokoněmčina',
 				'dje' => 'zarma',
 				'doi' => 'Dogri',
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
 				'en_US' => 'ameriska jendźelšćina',
 				'eo' => 'esperanto',
 				'es' => 'španišćina',
 				'es_419' => 'łaćonskoameriska španišćina',
 				'es_ES' => 'europska španišćina',
 				'es_MX' => 'mexiska španišćina',
 				'et' => 'estišćina',
 				'eu' => 'baskišćina',
 				'ewo' => 'ewondo',
 				'fa' => 'persišćina',
 				'fa_AF' => 'dari',
 				'ff' => 'fulbšćina',
 				'fi' => 'finšćina',
 				'fil' => 'filipinšćina',
 				'fj' => 'fidźišćina',
 				'fo' => 'färöšćina',
 				'fr' => 'francošćina',
 				'fr_CA' => 'kanadiska francošćina',
 				'fr_CH' => 'šwicarska francošćina',
 				'fur' => 'friulšćina',
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
 				'hmn' => 'hmongšćina',
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
 				'kkj' => 'kako',
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
 				'ksh' => 'kelnšćina',
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
 				'lrc' => 'sewjerny luri',
 				'lt' => 'litawšćina',
 				'lu' => 'luba-katanga',
 				'luo' => 'luo',
 				'luy' => 'luhya',
 				'lv' => 'letišćina',
 				'mai' => 'maithilšćina',
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
 				'mni' => 'manipuršćina',
 				'moh' => 'mohawkšćina',
 				'mr' => 'maratišćina',
 				'ms' => 'malajšćina',
 				'mt' => 'maltašćina',
 				'mua' => 'mundang',
 				'mul' => 'wjacerěčne',
 				'mus' => 'krik',
 				'my' => 'burmašćina',
 				'mzn' => 'mazanderanšćina',
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
 				'nnh' => 'ngiemboon',
 				'no' => 'norwegšćina',
 				'nqo' => 'n’ko',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'okcitanšćina',
 				'om' => 'oromo',
 				'or' => 'orijšćina',
 				'os' => 'osetšćina',
 				'pa' => 'pandźabšćina',
 				'pcm' => 'nigerijanski pidgin',
 				'pl' => 'pólšćina',
 				'prg' => 'prušćina',
 				'ps' => 'paštunšćina',
 				'pt' => 'portugalšćina',
 				'pt_BR' => 'brazilska portugalšćina',
 				'pt_PT' => 'europska portugalšćina',
 				'qu' => 'kečua',
 				'quc' => 'kʼicheʼ',
 				'rhg' => 'Rohingya',
 				'rm' => 'retoromanšćina',
 				'rn' => 'kirundišćina',
 				'ro' => 'rumunšćina',
 				'ro_MD' => 'moldawšćina',
 				'rof' => 'rombo',
 				'ru' => 'rušćina',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sah' => 'jakutšćina',
 				'saq' => 'samburu',
 				'sat' => 'santalšćina',
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
 				'wae' => 'walzeršćina',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'yi' => 'jidišćina',
 				'yo' => 'jorubašćina',
 				'yue' => 'kantonšćina',
 				'yue@alt=menu' => 'chinšćina (kantonšćina)',
 				'za' => 'zhuang',
 				'zgh' => 'tamazight',
 				'zh' => 'chinšćina',
 				'zh@alt=menu' => 'chinšćina (mandarin)',
 				'zh_Hans' => 'chinšćina (zjednorjena)',
 				'zh_Hans@alt=long' => 'chinšćina (zjednorjena)',
 				'zh_Hant' => 'chinšćina (tradicionalna)',
 				'zh_Hant@alt=long' => 'chinšćina (tradicionalna)',
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
 			'Hanb' => 'chinšćina z bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'chinsce',
 			'Hans' => 'zjednorjene',
 			'Hans@alt=stand-alone' => 'zjednorjene chinske pismo',
 			'Hant' => 'tradicionalne',
 			'Hant@alt=stand-alone' => 'tradicionalne chinske pismo',
 			'Hebr' => 'hebrejsce',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japanske złóžkowe pismo',
 			'Jamo' => 'jamo',
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
 			'Zmth' => 'matematiski zapis',
 			'Zsye' => 'emoji',
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
 			'202' => 'subsaharaska Afrika',
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
 			'EZ' => 'europasmo',
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
 			'MK' => 'Serwjerna Makedonska',
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
 			'UN' => 'Zjednoćene narody',
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
 			'XA' => 'pseudo-akcenty',
 			'XB' => 'pseudo-bidi',
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
 			'cf' => 'format měny',
 			'collation' => 'rjadowanski slěd',
 			'currency' => 'měna',
 			'hc' => 'hodźinowy cyklus (12 vs 24)',
 			'lb' => 'system łamanja linkow',
 			'ms' => 'system měrow',
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
 			'cf' => {
 				'account' => q{knihiwjedniski format měny},
 				'standard' => q{standardny format měny},
 			},
 			'collation' => {
 				'ducet' => q{rjadowanski slěd po Unicode},
 				'search' => q{powšitkowne pytanje},
 				'standard' => q{standardowy rjadowanski slěd},
 			},
 			'hc' => {
 				'h11' => q{12-hodźinowy cyklus (0-11)},
 				'h12' => q{12-hodźinowy cyklus (1-12)},
 				'h23' => q{24-hodźinowy cyklus (0-23)},
 				'h24' => q{24-hodźinowy cyklus (1-24)},
 			},
 			'lb' => {
 				'loose' => q{swobodny stil łamanja linkow},
 				'normal' => q{běžny stil łamanja linkow},
 				'strict' => q{kruty stil łamanja linkow},
 			},
 			'ms' => {
 				'metric' => q{metriski system},
 				'uksystem' => q{britiski system měrow},
 				'ussystem' => q{ameriski system měrow},
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
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
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
					# Long Unit Identifier
					'' => {
						'name' => q(wobzorosměr),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(wobzorosměr),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
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
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
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
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
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
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
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
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
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
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} jednotki zemskeho pospěšenja),
						'name' => q(jednotki zemskeho pospěšenja),
						'one' => q({0} jednotka zemskeho pospěšenja),
						'other' => q({0} jednotkow zemskeho pospěšenja),
						'two' => q({0} jednotce zemskeho pospěšenja),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} jednotki zemskeho pospěšenja),
						'name' => q(jednotki zemskeho pospěšenja),
						'one' => q({0} jednotka zemskeho pospěšenja),
						'other' => q({0} jednotkow zemskeho pospěšenja),
						'two' => q({0} jednotce zemskeho pospěšenja),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow na kwadratnu sekundu),
						'two' => q({0} metraj na kwadratnu sekundu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow na kwadratnu sekundu),
						'two' => q({0} metraj na kwadratnu sekundu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'two' => q({0} minuće),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'two' => q({0} minuće),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'two' => q({0} sekundźe),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'two' => q({0} sekundźe),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} stopnje),
						'name' => q(stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopnjej),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} stopnje),
						'name' => q(stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopnjej),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radiantaj),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radiantaj),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} wobroty),
						'name' => q(wobroty),
						'one' => q({0} wobrot),
						'other' => q({0} wobrotow),
						'two' => q({0} wobrotaj),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} wobroty),
						'name' => q(wobroty),
						'one' => q({0} wobrot),
						'other' => q({0} wobrotow),
						'two' => q({0} wobrotaj),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} acry),
						'name' => q(acry),
						'one' => q({0} acre),
						'other' => q({0} acrow),
						'two' => q({0} acraj),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} acry),
						'name' => q(acry),
						'one' => q({0} acre),
						'other' => q({0} acrow),
						'two' => q({0} acraj),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunamy),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamow),
						'two' => q({0} dunamaj),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunamy),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamow),
						'two' => q({0} dunamaj),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektaraj),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektaraj),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'per' => q({0} na kwadratny centimeter),
						'two' => q({0} kwadratnej centimetraj),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'per' => q({0} na kwadratny centimeter),
						'two' => q({0} kwadratnej centimetraj),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} kwadratne cóle),
						'name' => q(kwadratne cóle),
						'one' => q({0} kwadratny cól),
						'other' => q({0} kwadratnych cólow),
						'per' => q({0} na kwadratny cól),
						'two' => q({0} kwadratnej cólaj),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} kwadratne cóle),
						'name' => q(kwadratne cóle),
						'one' => q({0} kwadratny cól),
						'other' => q({0} kwadratnych cólow),
						'per' => q({0} na kwadratny cól),
						'two' => q({0} kwadratnej cólaj),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'per' => q({0} na kwadratny kilometer),
						'two' => q({0} kwadratnej kilometraj),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'per' => q({0} na kwadratny kilometer),
						'two' => q({0} kwadratnej kilometraj),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'per' => q({0} na kwadratny meter),
						'two' => q({0} kwadratnej metraj),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'per' => q({0} na kwadratny meter),
						'two' => q({0} kwadratnej metraj),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} kwadratne mile),
						'name' => q(kwadratne mile),
						'one' => q({0} kwadratna mila),
						'other' => q({0} kwadratnych milow),
						'per' => q({0} na kwadratnu milu),
						'two' => q({0} kwadratnej mili),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} kwadratne mile),
						'name' => q(kwadratne mile),
						'one' => q({0} kwadratna mila),
						'other' => q({0} kwadratnych milow),
						'per' => q({0} na kwadratnu milu),
						'two' => q({0} kwadratnej mili),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} kwadratne yardy),
						'name' => q(kwadratne yardy),
						'one' => q({0} kwadratny yard),
						'other' => q({0} kwadratnych yardow),
						'two' => q({0} kwadratnej yardaj),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} kwadratne yardy),
						'name' => q(kwadratne yardy),
						'one' => q({0} kwadratny yard),
						'other' => q({0} kwadratnych yardow),
						'two' => q({0} kwadratnej yardaj),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} kuski),
						'name' => q(kuski),
						'one' => q({0} kusk),
						'other' => q({0} kuskow),
						'two' => q({0} kuskaj),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} kuski),
						'name' => q(kuski),
						'one' => q({0} kusk),
						'other' => q({0} kuskow),
						'two' => q({0} kuskaj),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karataj),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karataj),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramow na deciliter),
						'two' => q({0} miligramaj na deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramow na deciliter),
						'two' => q({0} miligramaj na deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} milimole na liter),
						'name' => q(milimole na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolow na liter),
						'two' => q({0} milimolej na liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} milimole na liter),
						'name' => q(milimole na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolow na liter),
						'two' => q({0} milimolej na liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mole),
						'name' => q(mole),
						'one' => q({0} mol),
						'other' => q({0} molow),
						'two' => q({0} molej),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mole),
						'name' => q(mole),
						'one' => q({0} mol),
						'other' => q({0} molow),
						'two' => q({0} molej),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} procenty),
						'name' => q(procenty),
						'one' => q({0} procent),
						'other' => q({0} procentow),
						'two' => q({0} procentaj),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} procenty),
						'name' => q(procenty),
						'one' => q({0} procent),
						'other' => q({0} procentow),
						'two' => q({0} procentaj),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promil),
						'other' => q({0} promilow),
						'two' => q({0} promilej),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promil),
						'other' => q({0} promilow),
						'two' => q({0} promilej),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} milionćiny),
						'name' => q(milionćiny),
						'one' => q({0} milionćina),
						'other' => q({0} milionćinow),
						'two' => q({0} milionćinje),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} milionćiny),
						'name' => q(milionćiny),
						'one' => q({0} milionćina),
						'other' => q({0} milionćinow),
						'two' => q({0} milionćinje),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} dźesaćiny promila),
						'name' => q(dźesaćiny promila),
						'one' => q({0} dźesaćina promila),
						'other' => q({0} dźesaćinow promila),
						'two' => q({0} dźesaćinje promila),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} dźesaćiny promila),
						'name' => q(dźesaćiny promila),
						'one' => q({0} dźesaćina promila),
						'other' => q({0} dźesaćinow promila),
						'two' => q({0} dźesaćinje promila),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} litry na 100 kilometrow),
						'name' => q(litry na 100 kilometrow),
						'one' => q({0} liter na 100 kilometrow),
						'other' => q({0} litrow na 100 kilometrow),
						'two' => q({0} litraj na 100 kilometrow),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} litry na 100 kilometrow),
						'name' => q(litry na 100 kilometrow),
						'one' => q({0} liter na 100 kilometrow),
						'other' => q({0} litrow na 100 kilometrow),
						'two' => q({0} litraj na 100 kilometrow),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litraj na kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litraj na kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mile na galonu),
						'name' => q(mile na galonu),
						'one' => q({0} mila na galonu),
						'other' => q({0} milow na galonu),
						'two' => q({0} mili na galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mile na galonu),
						'name' => q(mile na galonu),
						'one' => q({0} mila na galonu),
						'other' => q({0} milow na galonu),
						'two' => q({0} mili na galonu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mile na britisku galonu),
						'name' => q(mile na britisku galonu),
						'one' => q({0} mila na britisku galonu),
						'other' => q({0} milow na britisku galonu),
						'two' => q({0} mili na britisku galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mile na britisku galonu),
						'name' => q(mile na britisku galonu),
						'one' => q({0} mila na britisku galonu),
						'other' => q({0} milow na britisku galonu),
						'two' => q({0} mili na britisku galonu),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wuchod),
						'north' => q({0} sewjer),
						'south' => q({0} juh),
						'west' => q({0} zapad),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wuchod),
						'north' => q({0} sewjer),
						'south' => q({0} juh),
						'west' => q({0} zapad),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bity),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bitaj),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bity),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bitaj),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bytey),
						'name' => q(bytey),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} byteaj),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bytey),
						'name' => q(bytey),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} byteaj),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabitaj),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabitaj),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabytey),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabyteaj),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabytey),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabyteaj),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobitaj),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobitaj),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobytey),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobyteaj),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobytey),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobyteaj),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} megabity),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabitaj),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} megabity),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabitaj),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabytey),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabyteaj),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabytey),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabyteaj),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} petabytey),
						'name' => q(petabytey),
						'one' => q({0} petabyte),
						'other' => q({0} petabyteow),
						'two' => q({0} petabyteaj),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} petabytey),
						'name' => q(petabytey),
						'one' => q({0} petabyte),
						'other' => q({0} petabyteow),
						'two' => q({0} petabyteaj),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabitaj),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabitaj),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabytey),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabyteaj),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabytey),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabyteaj),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} lětstotki),
						'name' => q(lětstotki),
						'one' => q({0} lětstotk),
						'other' => q({0} lětstotkow),
						'two' => q({0} lětstotkaj),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} lětstotki),
						'name' => q(lětstotki),
						'one' => q({0} lětstotk),
						'other' => q({0} lětstotkow),
						'two' => q({0} lětstotkaj),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dny),
						'name' => q(dny),
						'one' => q({0} dźeń),
						'other' => q({0} dnjow),
						'per' => q({0} wob dźeń),
						'two' => q({0} dnjej),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dny),
						'name' => q(dny),
						'one' => q({0} dźeń),
						'other' => q({0} dnjow),
						'per' => q({0} wob dźeń),
						'two' => q({0} dnjej),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} lětdźesatki),
						'name' => q(lětdźesatki),
						'one' => q({0} lětdźesatk),
						'other' => q({0} lětdźesatkow),
						'two' => q({0} lětdźesatkaj),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} lětdźesatki),
						'name' => q(lětdźesatki),
						'one' => q({0} lětdźesatk),
						'other' => q({0} lětdźesatkow),
						'two' => q({0} lětdźesatkaj),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} hodźiny),
						'name' => q(hodźiny),
						'one' => q({0} hodźina),
						'other' => q({0} hodźinow),
						'per' => q({0} na hodźinu),
						'two' => q({0} hodźinje),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} hodźiny),
						'name' => q(hodźiny),
						'one' => q({0} hodźina),
						'other' => q({0} hodźinow),
						'per' => q({0} na hodźinu),
						'two' => q({0} hodźinje),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekundźe),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekundźe),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekundźe),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekundźe),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'per' => q({0} za minutu),
						'two' => q({0} minuće),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'per' => q({0} za minutu),
						'two' => q({0} minuće),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} měsacy),
						'name' => q(měsacy),
						'one' => q({0} měsac),
						'other' => q({0} měsacow),
						'per' => q({0} wob měsac),
						'two' => q({0} měsacaj),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} měsacy),
						'name' => q(měsacy),
						'one' => q({0} měsac),
						'other' => q({0} měsacow),
						'per' => q({0} wob měsac),
						'two' => q({0} měsacaj),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekundźe),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekundźe),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekundźe),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekundźe),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} tydźenje),
						'name' => q(tydźenje),
						'one' => q({0} tydźeń),
						'other' => q({0} tydźenjow),
						'per' => q({0} wob tydźeń),
						'two' => q({0} tydźenjej),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} tydźenje),
						'name' => q(tydźenje),
						'one' => q({0} tydźeń),
						'other' => q({0} tydźenjow),
						'per' => q({0} wob tydźeń),
						'two' => q({0} tydźenjej),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'per' => q({0} wob lěto),
						'two' => q({0} lěće),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'per' => q({0} wob lěto),
						'two' => q({0} lěće),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} amperaj),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} amperaj),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliamperaj),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliamperaj),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} ohmy),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohmaj),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} ohmy),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohmaj),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volty),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltow),
						'two' => q({0} voltaj),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volty),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltow),
						'two' => q({0} voltaj),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britiske jednotki ćopłoty),
						'name' => q(britiske jednotki ćopłoty),
						'one' => q({0} britiska jednotka ćopłoty),
						'other' => q({0} britiskich jednotkow ćopłoty),
						'two' => q({0} britiskej jednotce ćopłoty),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britiske jednotki ćopłoty),
						'name' => q(britiske jednotki ćopłoty),
						'one' => q({0} britiska jednotka ćopłoty),
						'other' => q({0} britiskich jednotkow ćopłoty),
						'two' => q({0} britiskej jednotce ćopłoty),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijow),
						'two' => q({0} kaloriji),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijow),
						'two' => q({0} kaloriji),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolty),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltow),
						'two' => q({0} elektronvoltaj),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolty),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltow),
						'two' => q({0} elektronvoltaj),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} jouleow),
						'two' => q({0} joulej),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} jouleow),
						'two' => q({0} joulej),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojouleow),
						'two' => q({0} kilojoulej),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojouleow),
						'two' => q({0} kilojoulej),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kilowattowe hodźiny),
						'name' => q(kilowattowe hodźiny),
						'one' => q({0} kilowattowa hodźina),
						'other' => q({0} kilowattowych hodźin),
						'two' => q({0} kilowattowej hodźinje),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kilowattowe hodźiny),
						'name' => q(kilowattowe hodźiny),
						'one' => q({0} kilowattowa hodźina),
						'other' => q({0} kilowattowych hodźin),
						'two' => q({0} kilowattowej hodźinje),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} ameriske jednotki ćopłoty),
						'name' => q(ameriske jednotki ćopłoty),
						'one' => q({0} ameriska jednotka ćopłoty),
						'other' => q({0} ameriskich jednotkow ćopłoty),
						'two' => q({0} ameriskej jednotce ćopłoty),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} ameriske jednotki ćopłoty),
						'name' => q(ameriske jednotki ćopłoty),
						'one' => q({0} ameriska jednotka ćopłoty),
						'other' => q({0} ameriskich jednotkow ćopłoty),
						'two' => q({0} ameriskej jednotce ćopłoty),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kilowattowe hodźiny na 100 kilometrow),
						'name' => q(kilowattowe hodźiny na 100 kilometrow),
						'one' => q({0} kilowattowa hodźina na 100 kilometrow),
						'other' => q({0} kilowattowych hodźinow na 100 kilometrow),
						'two' => q({0} kilowattowej hodźinje na 100 kilometrow),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kilowattowe hodźiny na 100 kilometrow),
						'name' => q(kilowattowe hodźiny na 100 kilometrow),
						'one' => q({0} kilowattowa hodźina na 100 kilometrow),
						'other' => q({0} kilowattowych hodźinow na 100 kilometrow),
						'two' => q({0} kilowattowej hodźinje na 100 kilometrow),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} newtony),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonow),
						'two' => q({0} newtonaj),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} newtony),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonow),
						'two' => q({0} newtonaj),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} punty mocy),
						'name' => q(punty mocy),
						'one' => q({0} punt mocy),
						'other' => q({0} puntow mocy),
						'two' => q({0} puntaj mocy),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} punty mocy),
						'name' => q(punty mocy),
						'one' => q({0} punt mocy),
						'other' => q({0} puntow mocy),
						'two' => q({0} puntaj mocy),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertzaj),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertzaj),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertzaj),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertzaj),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertzaj),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertzaj),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertzaj),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertzaj),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} typografiske em),
						'name' => q(typografiski em),
						'one' => q({0} typografiski em),
						'other' => q({0} typografiskich em),
						'two' => q({0} typografiskej em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} typografiske em),
						'name' => q(typografiski em),
						'one' => q({0} typografiski em),
						'other' => q({0} typografiskich em),
						'two' => q({0} typografiskej em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} megapiksele),
						'name' => q(megapiksele),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselow),
						'two' => q({0} megapikselej),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} megapiksele),
						'name' => q(megapiksele),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselow),
						'two' => q({0} megapikselej),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} piksele),
						'name' => q(piksele),
						'one' => q({0} piksel),
						'other' => q({0} pikselow),
						'two' => q({0} pikselej),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} piksele),
						'name' => q(piksele),
						'one' => q({0} piksel),
						'other' => q({0} pikselow),
						'two' => q({0} pikselej),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} piksele na centimeter),
						'name' => q(piksele na centimeter),
						'one' => q({0} piksel na centimeter),
						'other' => q({0} pikselow na centimeter),
						'two' => q({0} pikselej na centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} piksele na centimeter),
						'name' => q(piksele na centimeter),
						'one' => q({0} piksel na centimeter),
						'other' => q({0} pikselow na centimeter),
						'two' => q({0} pikselej na centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} piksele na cól),
						'name' => q(piksele na cól),
						'one' => q({0} piksel na cól),
						'other' => q({0} pikselow na cól),
						'two' => q({0} pikselej na cól),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} piksele na cól),
						'name' => q(piksele na cól),
						'one' => q({0} piksel na cól),
						'other' => q({0} pikselow na cól),
						'two' => q({0} pikselej na cól),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomiske jednotki),
						'name' => q(astronomiske jednotki),
						'one' => q({0} astronomiska jednotka),
						'other' => q({0} astronomiskich jednotkow),
						'two' => q({0} astronomiskej jednotce),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomiske jednotki),
						'name' => q(astronomiske jednotki),
						'one' => q({0} astronomiska jednotka),
						'other' => q({0} astronomiskich jednotkow),
						'two' => q({0} astronomiskej jednotce),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetraj),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetraj),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetraj),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetraj),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} radiusy zemje),
						'name' => q(radius zemje),
						'one' => q({0} radius zemje),
						'other' => q({0} radiusow zemje),
						'two' => q({0} radiusaj zemje),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} radiusy zemje),
						'name' => q(radius zemje),
						'one' => q({0} radius zemje),
						'other' => q({0} radiusow zemje),
						'two' => q({0} radiusaj zemje),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} sahi),
						'name' => q(sahi),
						'one' => q({0} saha),
						'other' => q({0} sahow),
						'two' => q({0} saze),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} sahi),
						'name' => q(sahi),
						'one' => q({0} saha),
						'other' => q({0} sahow),
						'two' => q({0} saze),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stopow),
						'per' => q({0} na stopu),
						'two' => q({0} stopje),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stopow),
						'per' => q({0} na stopu),
						'two' => q({0} stopje),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongi),
						'name' => q(furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongow),
						'two' => q({0} furlongaj),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongi),
						'name' => q(furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongow),
						'two' => q({0} furlongaj),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} cóle),
						'name' => q(cóle),
						'one' => q({0} cól),
						'other' => q({0} cólow),
						'per' => q({0} na cól),
						'two' => q({0} cólej),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} cóle),
						'name' => q(cóle),
						'one' => q({0} cól),
						'other' => q({0} cólow),
						'per' => q({0} na cól),
						'two' => q({0} cólej),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometraj),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometraj),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} swětłolěta),
						'name' => q(swětłolěta),
						'one' => q({0} swětłolěto),
						'other' => q({0} swětłolět),
						'two' => q({0} swětłolěće),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} swětłolěta),
						'name' => q(swětłolěta),
						'one' => q({0} swětłolěto),
						'other' => q({0} swětłolět),
						'two' => q({0} swětłolěće),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'per' => q({0} na meter),
						'two' => q({0} metraj),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'per' => q({0} na meter),
						'two' => q({0} metraj),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometraj),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometraj),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} skandinawiske mile),
						'name' => q(skandinawiske mile),
						'one' => q({0} skandinawiska mila),
						'other' => q({0} skandinawiskich milow),
						'two' => q({0} skandinawiskej mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} skandinawiske mile),
						'name' => q(skandinawiske mile),
						'one' => q({0} skandinawiska mila),
						'other' => q({0} skandinawiskich milow),
						'two' => q({0} skandinawiskej mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetraj),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetraj),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometraj),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometraj),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nawtiske mile),
						'name' => q(nawtiske mile),
						'one' => q({0} nawtiska mila),
						'other' => q({0} nawtiskich milow),
						'two' => q({0} nawtiskej mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nawtiske mile),
						'name' => q(nawtiske mile),
						'one' => q({0} nawtiska mila),
						'other' => q({0} nawtiskich milow),
						'two' => q({0} nawtiskej mili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parsec),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parsec),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pikometry),
						'name' => q(pikometry),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrow),
						'two' => q({0} pikometraj),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pikometry),
						'name' => q(pikometry),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrow),
						'two' => q({0} pikometraj),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} dypki),
						'name' => q(dypki),
						'one' => q({0} dypk),
						'other' => q({0} dypkow),
						'two' => q({0} dypkaj),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} dypki),
						'name' => q(dypki),
						'one' => q({0} dypk),
						'other' => q({0} dypkow),
						'two' => q({0} dypkaj),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} radiusy słónca),
						'name' => q(radiusy słónca),
						'one' => q({0} radius słónca),
						'other' => q({0} radiusow słónca),
						'two' => q({0} radiusaj słónca),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} radiusy słónca),
						'name' => q(radiusy słónca),
						'one' => q({0} radius słónca),
						'other' => q({0} radiusow słónca),
						'two' => q({0} radiusaj słónca),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yardaj),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yardaj),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} kandele),
						'name' => q(kandele),
						'one' => q({0} kandela),
						'other' => q({0} kandelow),
						'two' => q({0} kandeli),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} kandele),
						'name' => q(kandele),
						'one' => q({0} kandela),
						'other' => q({0} kandelow),
						'two' => q({0} kandeli),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lumeny),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenow),
						'two' => q({0} lumenaj),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lumeny),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenow),
						'two' => q({0} lumenaj),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lux),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lux),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} swěćenske mocy słónca),
						'name' => q(swěćenske mocy słónca),
						'one' => q({0} swěćenska móc słónca),
						'other' => q({0} swěćenskich mocow słónca),
						'two' => q({0} swěćenskej mocy słónca),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} swěćenske mocy słónca),
						'name' => q(swěćenske mocy słónca),
						'one' => q({0} swěćenska móc słónca),
						'other' => q({0} swěćenskich mocow słónca),
						'two' => q({0} swěćenskej mocy słónca),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karataj),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karataj),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltony),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonow),
						'two' => q({0} daltonaj),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltony),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonow),
						'two' => q({0} daltonaj),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} masy zemje),
						'name' => q(masy zemje),
						'one' => q({0} masa zemje),
						'other' => q({0} masow zemje),
						'two' => q({0} masy zemje),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} masy zemje),
						'name' => q(masy zemje),
						'one' => q({0} masa zemje),
						'other' => q({0} masow zemje),
						'two' => q({0} masy zemje),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grainy),
						'name' => q(grain),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} grainaj),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grainy),
						'name' => q(grain),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} grainaj),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'per' => q({0} na gram),
						'two' => q({0} gramaj),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'per' => q({0} na gram),
						'two' => q({0} gramaj),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kilogramy),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramow),
						'per' => q({0} na kilogram),
						'two' => q({0} kilogramaj),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kilogramy),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramow),
						'per' => q({0} na kilogram),
						'two' => q({0} kilogramaj),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'few' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} tonow),
						'two' => q({0} tonje),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'few' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} tonow),
						'two' => q({0} tonje),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} mikrogramy),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramow),
						'two' => q({0} mikrogramaj),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} mikrogramy),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramow),
						'two' => q({0} mikrogramaj),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligramaj),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligramaj),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} uncy),
						'name' => q(uncy),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'per' => q({0} na uncu),
						'two' => q({0} uncy),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} uncy),
						'name' => q(uncy),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'per' => q({0} na uncu),
						'two' => q({0} uncy),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} troyske uncy),
						'name' => q(troyske uncy),
						'one' => q({0} troyska unca),
						'other' => q({0} troyskich uncow),
						'two' => q({0} troyskej uncy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} troyske uncy),
						'name' => q(troyske uncy),
						'one' => q({0} troyska unca),
						'other' => q({0} troyskich uncow),
						'two' => q({0} troyskej uncy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'per' => q({0} na punt),
						'two' => q({0} puntaj),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'per' => q({0} na punt),
						'two' => q({0} puntaj),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} masy słónca),
						'name' => q(masy słónca),
						'one' => q({0} masa słónca),
						'other' => q({0} masow słónca),
						'two' => q({0} masy słónca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} masy słónca),
						'name' => q(masy słónca),
						'one' => q({0} masa słónca),
						'other' => q({0} masow słónca),
						'two' => q({0} masy słónca),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} kamjenje),
						'name' => q(kamjenje),
						'one' => q({0} kamjeń),
						'other' => q({0} kamjenjow),
						'two' => q({0} kamjenjej),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} kamjenje),
						'name' => q(kamjenje),
						'one' => q({0} kamjeń),
						'other' => q({0} kamjenjow),
						'two' => q({0} kamjenjej),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} ameriske tony),
						'name' => q(ameriske tony),
						'one' => q({0} ameriska tona),
						'other' => q({0} ameriskich tonow),
						'two' => q({0} ameriskej tonje),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} ameriske tony),
						'name' => q(ameriske tony),
						'one' => q({0} ameriska tona),
						'other' => q({0} ameriskich tonow),
						'two' => q({0} ameriskej tonje),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} na {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} na {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawattaj),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawattaj),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} konjace mocy),
						'name' => q(konjace mocy),
						'one' => q({0} konjaca móc),
						'other' => q({0} konjacych mocow),
						'two' => q({0} konjacej mocy),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} konjace mocy),
						'name' => q(konjace mocy),
						'one' => q({0} konjaca móc),
						'other' => q({0} konjacych mocow),
						'two' => q({0} konjacej mocy),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowattaj),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowattaj),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawattaj),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawattaj),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwattaj),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwattaj),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} wattaj),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} wattaj),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q(kwadratne {0}),
						'one' => q(kwadratny {0}),
						'other' => q(kwadratnych {0}),
						'two' => q(kwadratnej {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q(kwadratne {0}),
						'one' => q(kwadratny {0}),
						'other' => q(kwadratnych {0}),
						'two' => q(kwadratnej {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q(kubikne {0}),
						'one' => q(kubikny {0}),
						'other' => q(kubiknych {0}),
						'two' => q(kubiknej {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q(kubikne {0}),
						'one' => q(kubikny {0}),
						'other' => q(kubiknych {0}),
						'two' => q(kubiknej {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atmosfery),
						'name' => q(atmosfery),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferow),
						'two' => q({0} atmosferje),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atmosfery),
						'name' => q(atmosfery),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferow),
						'two' => q({0} atmosferje),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bary),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barow),
						'two' => q({0} baraj),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bary),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barow),
						'two' => q({0} baraj),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascalej),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascalej),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} cóle žiwoslěbroweho stołpika),
						'name' => q(cóle žiwoslěbroweho stołpika),
						'one' => q({0} cól žiwoslěbroweho stołpika),
						'other' => q({0} cólow žiwoslěbroweho stołpika),
						'two' => q({0} cólej žiwoslěbroweho stołpika),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} cóle žiwoslěbroweho stołpika),
						'name' => q(cóle žiwoslěbroweho stołpika),
						'one' => q({0} cól žiwoslěbroweho stołpika),
						'other' => q({0} cólow žiwoslěbroweho stołpika),
						'two' => q({0} cólej žiwoslěbroweho stołpika),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kilopascale),
						'name' => q(kilopascale),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalow),
						'two' => q({0} kilopascalej),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kilopascale),
						'name' => q(kilopascale),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalow),
						'two' => q({0} kilopascalej),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} megapascale),
						'name' => q(megapascale),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalow),
						'two' => q({0} megapascalej),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} megapascale),
						'name' => q(megapascale),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalow),
						'two' => q({0} megapascalej),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibaraj),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibaraj),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetry žiwoslěbroweho stołpika),
						'name' => q(milimetry žiwoslěbroweho stołpika),
						'one' => q({0} milimeter žiwoslěbroweho stołpika),
						'other' => q({0} milimetrow žiwoslěbroweho stołpika),
						'two' => q({0} milimetraj žiwoslěbroweho stołpika),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetry žiwoslěbroweho stołpika),
						'name' => q(milimetry žiwoslěbroweho stołpika),
						'one' => q({0} milimeter žiwoslěbroweho stołpika),
						'other' => q({0} milimetrow žiwoslěbroweho stołpika),
						'two' => q({0} milimetraj žiwoslěbroweho stołpika),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} pascale),
						'name' => q(pascale),
						'one' => q({0} pascal),
						'other' => q({0} pascalow),
						'two' => q({0} pascalej),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} pascale),
						'name' => q(pascale),
						'one' => q({0} pascal),
						'other' => q({0} pascalow),
						'two' => q({0} pascalej),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} punty na kwadratny cól),
						'name' => q(punty na kwadratny cól),
						'one' => q({0} punt na kwadratny cól),
						'other' => q({0} puntow na kwadratny cól),
						'two' => q({0} puntaj na kwadratny cól),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} punty na kwadratny cól),
						'name' => q(punty na kwadratny cól),
						'one' => q({0} punt na kwadratny cól),
						'other' => q({0} puntow na kwadratny cól),
						'two' => q({0} puntaj na kwadratny cól),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} kilometry na hodźinu),
						'name' => q(kilometry na hodźinu),
						'one' => q({0} kilometer na hodźinu),
						'other' => q({0} kilometrow na hodźinu),
						'two' => q({0} kilometraj na hodźinu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} kilometry na hodźinu),
						'name' => q(kilometry na hodźinu),
						'one' => q({0} kilometer na hodźinu),
						'other' => q({0} kilometrow na hodźinu),
						'two' => q({0} kilometraj na hodźinu),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} suki),
						'name' => q(suki),
						'one' => q({0} suk),
						'other' => q({0} sukow),
						'two' => q({0} sukaj),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} suki),
						'name' => q(suki),
						'one' => q({0} suk),
						'other' => q({0} sukow),
						'two' => q({0} sukaj),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metraj na sekundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metraj na sekundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mile na hodźinu),
						'name' => q(mile na hodźinu),
						'one' => q({0} mila na hodźinu),
						'other' => q({0} milow na hodźinu),
						'two' => q({0} mili na hodźinu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mile na hodźinu),
						'name' => q(mile na hodźinu),
						'one' => q({0} mila na hodźinu),
						'other' => q({0} milow na hodźinu),
						'two' => q({0} mili na hodźinu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} stopnje Celsiusa),
						'name' => q(stopnje Celsiusa),
						'one' => q({0} stopjeń Celsiusa),
						'other' => q({0} stopnjow Celsiusa),
						'two' => q({0} stopnjej Celsiusa),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} stopnje Celsiusa),
						'name' => q(stopnje Celsiusa),
						'one' => q({0} stopjeń Celsiusa),
						'other' => q({0} stopnjow Celsiusa),
						'two' => q({0} stopnjej Celsiusa),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnjej Fahrenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnjej Fahrenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'few' => q({0} stopjenje),
						'name' => q(°),
						'one' => q({0} stopjeń),
						'other' => q({0} stopjenjow),
						'two' => q({0} stopjenjej),
					},
					# Core Unit Identifier
					'generic' => {
						'few' => q({0} stopjenje),
						'name' => q(°),
						'one' => q({0} stopjeń),
						'other' => q({0} stopjenjow),
						'two' => q({0} stopjenjej),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnjej Kelvina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnjej Kelvina),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} newtonmetry),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrow),
						'two' => q({0} newtonmetraj),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} newtonmetry),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrow),
						'two' => q({0} newtonmetraj),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostopow),
						'two' => q({0} librostopje),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostopow),
						'two' => q({0} librostopje),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} acre-stopy),
						'name' => q(acre-stopy),
						'one' => q({0} acre-stopa),
						'other' => q({0} acre-stopow),
						'two' => q({0} acre-stopje),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} acre-stopy),
						'name' => q(acre-stopy),
						'one' => q({0} acre-stopa),
						'other' => q({0} acre-stopow),
						'two' => q({0} acre-stopje),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barele),
						'name' => q(barele),
						'one' => q({0} barel),
						'other' => q({0} barelow),
						'two' => q({0} barelej),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barele),
						'name' => q(barele),
						'one' => q({0} barel),
						'other' => q({0} barelow),
						'two' => q({0} barelej),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušle),
						'name' => q(bušle),
						'one' => q({0} bušl),
						'other' => q({0} bušlow),
						'two' => q({0} bušlej),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušle),
						'name' => q(bušle),
						'one' => q({0} bušl),
						'other' => q({0} bušlow),
						'two' => q({0} bušlej),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitraj),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitraj),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'per' => q({0} na kubikny centimeter),
						'two' => q({0} kubiknej centimetraj),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'per' => q({0} na kubikny centimeter),
						'two' => q({0} kubiknej centimetraj),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubikne stopy),
						'name' => q(kubikne stopy),
						'one' => q({0} kubikna stopa),
						'other' => q({0} kubiknych stopow),
						'two' => q({0} kubiknej stopje),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubikne stopy),
						'name' => q(kubikne stopy),
						'one' => q({0} kubikna stopa),
						'other' => q({0} kubiknych stopow),
						'two' => q({0} kubiknej stopje),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubikne cóle),
						'name' => q(kubikne cóle),
						'one' => q({0} kubikny cól),
						'other' => q({0} kubiknych cólow),
						'two' => q({0} kubiknej cólej),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubikne cóle),
						'name' => q(kubikne cóle),
						'one' => q({0} kubikny cól),
						'other' => q({0} kubiknych cólow),
						'two' => q({0} kubiknej cólej),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometraj),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometraj),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'per' => q({0} na kubikny meter),
						'two' => q({0} kubiknej metraj),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'per' => q({0} na kubikny meter),
						'two' => q({0} kubiknej metraj),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubikne mile),
						'name' => q(kubikne mile),
						'one' => q({0} kubikna mila),
						'other' => q({0} kubiknych milow),
						'two' => q({0} kubiknej mili),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubikne mile),
						'name' => q(kubikne mile),
						'one' => q({0} kubikna mila),
						'other' => q({0} kubiknych milow),
						'two' => q({0} kubiknej mili),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubikne yardy),
						'name' => q(kubikne yardy),
						'one' => q({0} kubikny yard),
						'other' => q({0} kubiknych yardow),
						'two' => q({0} kubiknej yardaj),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubikne yardy),
						'name' => q(kubikne yardy),
						'one' => q({0} kubikny yard),
						'other' => q({0} kubiknych yardow),
						'two' => q({0} kubiknej yardaj),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} šalki),
						'name' => q(šalki),
						'one' => q({0} šalka),
						'other' => q({0} šalkow),
						'two' => q({0} šalce),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} šalki),
						'name' => q(šalki),
						'one' => q({0} šalka),
						'other' => q({0} šalkow),
						'two' => q({0} šalce),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} metriske šalki),
						'name' => q(metriske šalki),
						'one' => q({0} metriska šalka),
						'other' => q({0} metriskich šalkow),
						'two' => q({0} metriskej šalce),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} metriske šalki),
						'name' => q(metriske šalki),
						'one' => q({0} metriska šalka),
						'other' => q({0} metriskich šalkow),
						'two' => q({0} metriskej šalce),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitraj),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitraj),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dessertowe łžički),
						'name' => q(dessertowe łžički),
						'one' => q({0} dessertowa łžička),
						'other' => q({0} dessertowych łžičkow),
						'two' => q({0} dessertowej łžičce),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dessertowe łžički),
						'name' => q(dessertowe łžički),
						'one' => q({0} dessertowa łžička),
						'other' => q({0} dessertowych łžičkow),
						'two' => q({0} dessertowej łžičce),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} britiske łžički),
						'name' => q(britiske łžički),
						'one' => q({0} britiska łžička),
						'other' => q({0} britiskich łžičkow),
						'two' => q({0} britiskej łžičce),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} britiske łžički),
						'name' => q(britiske łžički),
						'one' => q({0} britiska łžička),
						'other' => q({0} britiskich łžičkow),
						'two' => q({0} britiskej łžičce),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dramy),
						'name' => q(dramy),
						'one' => q({0} dram),
						'other' => q({0} dramow),
						'two' => q({0} dramaj),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dramy),
						'name' => q(dramy),
						'one' => q({0} dram),
						'other' => q({0} dramow),
						'two' => q({0} dramaj),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kapki),
						'name' => q(kapki),
						'one' => q({0} kapka),
						'other' => q({0} kapkow),
						'two' => q({0} kapce),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kapki),
						'name' => q(kapki),
						'one' => q({0} kapka),
						'other' => q({0} kapkow),
						'two' => q({0} kapce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} běžite uncy),
						'name' => q(běžite uncy),
						'one' => q({0} běžita unca),
						'other' => q({0} běžitych uncow),
						'two' => q({0} běžitej uncy),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} běžite uncy),
						'name' => q(běžite uncy),
						'one' => q({0} běžita unca),
						'other' => q({0} běžitych uncow),
						'two' => q({0} běžitej uncy),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} britiske běžite uncy),
						'name' => q(britiske běžite uncy),
						'one' => q({0} britiska běžita unca),
						'other' => q({0} britiskich běžitych uncow),
						'two' => q({0} britiskej běžitej uncy),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} britiske běžite uncy),
						'name' => q(britiske běžite uncy),
						'one' => q({0} britiska běžita unca),
						'other' => q({0} britiskich běžitych uncow),
						'two' => q({0} britiskej běžitej uncy),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galony),
						'name' => q(galony),
						'one' => q({0} galona),
						'other' => q({0} galonow),
						'per' => q({0} na galonu),
						'two' => q({0} galonje),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galony),
						'name' => q(galony),
						'one' => q({0} galona),
						'other' => q({0} galonow),
						'per' => q({0} na galonu),
						'two' => q({0} galonje),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} britiske galony),
						'name' => q(britiske galony),
						'one' => q({0} britiska galona),
						'other' => q({0} britiskich galonow),
						'per' => q({0} na britisku galonu),
						'two' => q({0} britiskej galonje),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} britiske galony),
						'name' => q(britiske galony),
						'one' => q({0} britiska galona),
						'other' => q({0} britiskich galonow),
						'per' => q({0} na britisku galonu),
						'two' => q({0} britiskej galonje),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitraj),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitraj),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggeraj),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggeraj),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'per' => q({0} na liter),
						'two' => q({0} litraj),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'per' => q({0} na liter),
						'two' => q({0} litraj),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitraj),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitraj),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitraj),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitraj),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pintaj),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pintaj),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} metriske pinty),
						'name' => q(metriske pinty),
						'one' => q({0} metriski pint),
						'other' => q({0} metriskich pintow),
						'two' => q({0} metriskej pintaj),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} metriske pinty),
						'name' => q(metriske pinty),
						'one' => q({0} metriski pint),
						'other' => q({0} metriskich pintow),
						'two' => q({0} metriskej pintaj),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quartaj),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quartaj),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} britiske běrtle),
						'name' => q(britiske běrtle),
						'one' => q({0} britiski běrtl),
						'other' => q({0} britiskich běrtlow),
						'two' => q({0} britiskej běrtlej),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} britiske běrtle),
						'name' => q(britiske běrtle),
						'one' => q({0} britiski běrtl),
						'other' => q({0} britiskich běrtlow),
						'two' => q({0} britiskej běrtlej),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} łžicy),
						'name' => q(łžicy),
						'one' => q({0} łžica),
						'other' => q({0} łžicow),
						'two' => q({0} łžicy),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} łžicy),
						'name' => q(łžicy),
						'one' => q({0} łžica),
						'other' => q({0} łžicow),
						'two' => q({0} łžicy),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} łžički),
						'name' => q(łžički),
						'one' => q({0} łžička),
						'other' => q({0} łžičkow),
						'two' => q({0} łžičce),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} łžički),
						'name' => q(łžički),
						'one' => q({0} łžička),
						'other' => q({0} łžičkow),
						'two' => q({0} łžičce),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
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
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'two' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'two' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'two' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'two' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg br.),
						'name' => q(mpg br.),
						'one' => q({0} mpg br.),
						'other' => q({0} mpg br.),
						'two' => q({0} mpg br.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg br.),
						'name' => q(mpg br.),
						'one' => q({0} mpg br.),
						'other' => q({0} mpg br.),
						'two' => q({0} mpg br.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'two' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'two' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'two' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'two' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'two' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'two' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'two' => q({0} měs.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'two' => q({0} měs.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'two' => q({0} t.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'two' => q({0} t.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'two' => q({0} l.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'two' => q({0} l.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'two' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'two' => q({0} cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'two' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'two' => q({0} ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} in),
						'one' => q({0} in),
						'other' => q({0} in),
						'two' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} in),
						'one' => q({0} in),
						'other' => q({0} in),
						'two' => q({0} in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'two' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'two' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'two' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'two' => q({0} m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'two' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'two' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'two' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'two' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'two' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'two' => q({0} lb),
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
					'power-horsepower' => {
						'few' => q({0} PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0}°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0}°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} im. łk.),
						'name' => q(im. łk.),
						'one' => q({0} im. łk.),
						'other' => q({0} im. łk.),
						'two' => q({0} im. łk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} im. łk.),
						'name' => q(im. łk.),
						'one' => q({0} im. łk.),
						'other' => q({0} im. łk.),
						'two' => q({0} im. łk.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} br. fl oz),
						'name' => q(br. fl oz),
						'one' => q({0} br. fl oz),
						'other' => q({0} br. fl oz),
						'two' => q({0} br. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} br. fl oz),
						'name' => q(br. fl oz),
						'one' => q({0} br. fl oz),
						'other' => q({0} br. fl oz),
						'two' => q({0} br. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} br. gal.),
						'name' => q(br. gal.),
						'one' => q({0} br. gal.),
						'other' => q({0} br. gal.),
						'per' => q({0}/br. gal.),
						'two' => q({0} br. gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} br. gal.),
						'name' => q(br. gal.),
						'one' => q({0} br. gal.),
						'other' => q({0} br. gal.),
						'per' => q({0}/br. gal.),
						'two' => q({0} br. gal.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} jigg.),
						'name' => q(jigg.),
						'one' => q({0} jigg.),
						'other' => q({0} jigg.),
						'two' => q({0} jigg.),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} jigg.),
						'name' => q(jigg.),
						'one' => q({0} jigg.),
						'other' => q({0} jigg.),
						'two' => q({0} jigg.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'two' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'two' => q({0} l),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šć),
						'name' => q(šć),
						'one' => q({0} šć),
						'other' => q({0} šć),
						'two' => q({0} šć),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šć),
						'name' => q(šć),
						'one' => q({0} šć),
						'other' => q({0} šć),
						'two' => q({0} šć),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(směr),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(směr),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
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
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} ′),
						'name' => q(′),
						'one' => q({0} ′),
						'other' => q({0} ′),
						'two' => q({0} ′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} ′),
						'name' => q(′),
						'one' => q({0} ′),
						'other' => q({0} ′),
						'two' => q({0} ′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} ″),
						'name' => q(″),
						'one' => q({0} ″),
						'other' => q({0} ″),
						'two' => q({0} ″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} ″),
						'name' => q(″),
						'one' => q({0} ″),
						'other' => q({0} ″),
						'two' => q({0} ″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
						'two' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
						'two' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} wobr.),
						'name' => q(wobr.),
						'one' => q({0} wobr.),
						'other' => q({0} wobr.),
						'two' => q({0} wobr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} wobr.),
						'name' => q(wobr.),
						'one' => q({0} wobr.),
						'other' => q({0} wobr.),
						'two' => q({0} wobr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} ac),
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} ac),
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
						'two' => q({0} dun.),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
						'two' => q({0} dun.),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
						'two' => q({0} cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
						'two' => q({0} cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'two' => q({0} in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'two' => q({0} in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
						'two' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
						'two' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
						'two' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
						'two' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
						'two' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
						'two' => q({0} mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
						'two' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
						'two' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} kusy),
						'name' => q(kus),
						'one' => q({0} kus),
						'other' => q({0} kusow),
						'two' => q({0} kusaj),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} kusy),
						'name' => q(kus),
						'one' => q({0} kus),
						'other' => q({0} kusow),
						'two' => q({0} kusaj),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
						'two' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
						'two' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mol),
						'name' => q(mol),
						'one' => q({0} mol),
						'other' => q({0} mol),
						'two' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mol),
						'name' => q(mol),
						'one' => q({0} mol),
						'other' => q({0} mol),
						'two' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
						'two' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
						'two' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'name' => q(‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'name' => q(‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
						'two' => q({0} mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
						'two' => q({0} mpg brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} w),
						'north' => q({0} s),
						'south' => q({0} j),
						'west' => q({0} z),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} w),
						'north' => q({0} s),
						'south' => q({0} j),
						'west' => q({0} z),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bit),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bit),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} byte),
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
						'two' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} byte),
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
						'two' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
						'two' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
						'two' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
						'two' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
						'two' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
						'two' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
						'two' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
						'two' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
						'two' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
						'two' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
						'two' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
						'two' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
						'two' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} PB),
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
						'two' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} PB),
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
						'two' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
						'two' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
						'two' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
						'two' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
						'two' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} lětst.),
						'name' => q(lětst.),
						'one' => q({0} lětst.),
						'other' => q({0} lětst.),
						'two' => q({0} lětst.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} lětst.),
						'name' => q(lětst.),
						'one' => q({0} lětst.),
						'other' => q({0} lětst.),
						'two' => q({0} lětst.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} dź.),
						'other' => q({0} dn.),
						'per' => q({0}/dź.),
						'two' => q({0} dn.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} dź.),
						'other' => q({0} dn.),
						'per' => q({0}/dź.),
						'two' => q({0} dn.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} lětdź.),
						'name' => q(lětdź.),
						'one' => q({0} lětdź.),
						'other' => q({0} lětdź.),
						'two' => q({0} lětdź.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} lětdź.),
						'name' => q(lětdź.),
						'one' => q({0} lětdź.),
						'other' => q({0} lětdź.),
						'two' => q({0} lětdź.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} hodź.),
						'name' => q(hodź.),
						'one' => q({0} hodź.),
						'other' => q({0} hodź.),
						'per' => q({0}/h),
						'two' => q({0} hodź.),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} hodź.),
						'name' => q(hodź.),
						'one' => q({0} hodź.),
						'other' => q({0} hodź.),
						'per' => q({0}/h),
						'two' => q({0} hodź.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
						'two' => q({0} min.),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
						'two' => q({0} min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'per' => q({0}/měs.),
						'two' => q({0} měs.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'per' => q({0}/měs.),
						'two' => q({0} měs.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/s),
						'two' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/s),
						'two' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} tydź.),
						'name' => q(tydź.),
						'one' => q({0} tydź.),
						'other' => q({0} tydź.),
						'per' => q({0}/tydź.),
						'two' => q({0} tydź.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} tydź.),
						'name' => q(tydź.),
						'one' => q({0} tydź.),
						'other' => q({0} tydź.),
						'per' => q({0}/tydź.),
						'two' => q({0} tydź.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'per' => q({0}/l.),
						'two' => q({0} l.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'per' => q({0}/l.),
						'two' => q({0} l.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
						'two' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
						'two' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
						'two' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
						'two' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
						'two' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
						'two' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
						'two' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
						'two' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} Btu),
						'name' => q(Btu),
						'one' => q({0} Btu),
						'other' => q({0} Btu),
						'two' => q({0} Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} Btu),
						'name' => q(Btu),
						'one' => q({0} Btu),
						'other' => q({0} Btu),
						'two' => q({0} Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} eV),
						'name' => q(eV),
						'one' => q({0} eV),
						'other' => q({0} eV),
						'two' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} eV),
						'name' => q(eV),
						'one' => q({0} eV),
						'other' => q({0} eV),
						'two' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'two' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'two' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
						'two' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
						'two' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
						'two' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
						'two' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} US therms),
						'name' => q(US therm),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
						'two' => q({0} US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} US therms),
						'name' => q(US therm),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
						'two' => q({0} US therms),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'name' => q(kWh/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
						'two' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'name' => q(kWh/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
						'two' => q({0} kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} N),
						'name' => q(N),
						'one' => q({0} N),
						'other' => q({0} N),
						'two' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} N),
						'name' => q(N),
						'one' => q({0} N),
						'other' => q({0} N),
						'two' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} lbf),
						'name' => q(lbf),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
						'two' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} lbf),
						'name' => q(lbf),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
						'two' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
						'two' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
						'two' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
						'two' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
						'two' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
						'two' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
						'two' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
						'two' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
						'two' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} em),
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
						'two' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} em),
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
						'two' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} MP),
						'name' => q(MP),
						'one' => q({0} MP),
						'other' => q({0} MP),
						'two' => q({0} MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} MP),
						'name' => q(MP),
						'one' => q({0} MP),
						'other' => q({0} MP),
						'two' => q({0} MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} px),
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
						'two' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} px),
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
						'two' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
						'two' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
						'two' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(ppi),
						'one' => q({0} ppi),
						'other' => q({0} ppi),
						'two' => q({0} ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(ppi),
						'one' => q({0} ppi),
						'other' => q({0} ppi),
						'two' => q({0} ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
						'two' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
						'two' => q({0} au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
						'two' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
						'two' => q({0} cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} R⊕),
						'name' => q(R⊕),
						'one' => q({0} R⊕),
						'other' => q({0} R⊕),
						'two' => q({0} R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} R⊕),
						'name' => q(R⊕),
						'one' => q({0} R⊕),
						'other' => q({0} R⊕),
						'two' => q({0} R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} fth),
						'name' => q(fth),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'two' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} fth),
						'name' => q(fth),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'two' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
						'two' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
						'two' => q({0} ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
						'two' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
						'two' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/cól),
						'two' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/cól),
						'two' => q({0} in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'two' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'two' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} μm),
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
						'two' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} μm),
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
						'two' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
						'two' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
						'two' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
						'two' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
						'two' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
						'two' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
						'two' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} R☉),
						'name' => q(R☉),
						'one' => q({0} R☉),
						'other' => q({0} R☉),
						'two' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} R☉),
						'name' => q(R☉),
						'one' => q({0} R☉),
						'other' => q({0} R☉),
						'two' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} cd),
						'name' => q(cd),
						'one' => q({0} cd),
						'other' => q({0} cd),
						'two' => q({0} cd),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} cd),
						'name' => q(cd),
						'one' => q({0} cd),
						'other' => q({0} cd),
						'two' => q({0} cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lm),
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
						'two' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lm),
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
						'two' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
						'two' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
						'two' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} L☉),
						'name' => q(L☉),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
						'two' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} L☉),
						'name' => q(L☉),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
						'two' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} Kt),
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
						'two' => q({0} Kt),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} Kt),
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
						'two' => q({0} Kt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} Da),
						'name' => q(Da),
						'one' => q({0} Da),
						'other' => q({0} Da),
						'two' => q({0} Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} Da),
						'name' => q(Da),
						'one' => q({0} Da),
						'other' => q({0} Da),
						'two' => q({0} Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} M⊕),
						'name' => q(M⊕),
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
						'two' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} M⊕),
						'name' => q(M⊕),
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
						'two' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grainy),
						'name' => q(grain),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} grainaj),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grainy),
						'name' => q(grain),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} grainaj),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
						'two' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
						'two' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} μg),
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
						'two' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} μg),
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
						'two' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
						'two' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
						'two' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} oz. tr.),
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
						'two' => q({0} oz. tr.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} oz. tr.),
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
						'two' => q({0} oz. tr.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
						'two' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
						'two' => q({0} lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} M☉),
						'name' => q(M☉),
						'one' => q({0} M☉),
						'other' => q({0} M☉),
						'two' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} M☉),
						'name' => q(M☉),
						'one' => q({0} M☉),
						'other' => q({0} M☉),
						'two' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tn),
						'name' => q(am.tony),
						'one' => q({0} tn),
						'other' => q({0} tn),
						'two' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tn),
						'name' => q(am.tony),
						'one' => q({0} tn),
						'other' => q({0} tn),
						'two' => q({0} tn),
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
						'few' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
						'two' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
						'two' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} PS),
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} PS),
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
						'two' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
						'two' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
						'two' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
						'two' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
						'two' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
						'two' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
						'two' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
						'two' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atm),
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
						'two' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atm),
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
						'two' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bar),
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
						'two' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bar),
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
						'two' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kPa),
						'name' => q(kPa),
						'one' => q({0} kPa),
						'other' => q({0} kPa),
						'two' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kPa),
						'name' => q(kPa),
						'one' => q({0} kPa),
						'other' => q({0} kPa),
						'two' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} MPa),
						'name' => q(MPa),
						'one' => q({0} MPa),
						'other' => q({0} MPa),
						'two' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} MPa),
						'name' => q(MPa),
						'one' => q({0} MPa),
						'other' => q({0} MPa),
						'two' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
						'two' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
						'two' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} Pa),
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
						'two' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} Pa),
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
						'two' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
						'two' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
						'two' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} sk),
						'name' => q(sk),
						'one' => q({0} sk),
						'other' => q({0} sk),
						'two' => q({0} sk),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} sk),
						'name' => q(sk),
						'one' => q({0} sk),
						'other' => q({0} sk),
						'two' => q({0} sk),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mph),
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mph),
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0}°F),
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0}°F),
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
						'two' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
						'two' => q({0} K),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
						'two' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
						'two' => q({0} Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
						'two' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
						'two' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
						'two' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
						'two' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} bbl),
						'name' => q(bbl),
						'one' => q({0} bbl),
						'other' => q({0} bbl),
						'two' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} bbl),
						'name' => q(bbl),
						'one' => q({0} bbl),
						'other' => q({0} bbl),
						'two' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
						'two' => q({0} bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
						'two' => q({0} bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
						'two' => q({0} cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
						'two' => q({0} cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
						'two' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
						'two' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
						'two' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
						'two' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
						'two' => q({0} m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
						'two' => q({0} m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
						'two' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
						'two' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} š.),
						'name' => q(š.),
						'one' => q({0} š.),
						'other' => q({0} š.),
						'two' => q({0} š.),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} š.),
						'name' => q(š.),
						'one' => q({0} š.),
						'other' => q({0} š.),
						'two' => q({0} š.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} mc),
						'name' => q(mc),
						'one' => q({0} mc),
						'other' => q({0} mc),
						'two' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} mc),
						'name' => q(mc),
						'one' => q({0} mc),
						'other' => q({0} mc),
						'two' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dess. łžk.),
						'name' => q(dess. łžk.),
						'one' => q({0} dess. łžk.),
						'other' => q({0} dess. łžk.),
						'two' => q({0} dess. łžk.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dess. łžk.),
						'name' => q(dess. łžk.),
						'one' => q({0} dess. łžk.),
						'other' => q({0} dess. łžk.),
						'two' => q({0} dess. łžk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. łžk.),
						'name' => q(imp. łžk.),
						'one' => q({0} imp. łžk.),
						'other' => q({0} imp. łžk.),
						'two' => q({0} imp. łžk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. łžk.),
						'name' => q(imp. łžk.),
						'one' => q({0} imp. łžk.),
						'other' => q({0} imp. łžk.),
						'two' => q({0} imp. łžk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
						'two' => q({0} dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
						'two' => q({0} dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kpk.),
						'name' => q(kpk.),
						'one' => q({0} kpk.),
						'other' => q({0} kpk.),
						'two' => q({0} kpk.),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kpk.),
						'name' => q(kpk.),
						'one' => q({0} kpk.),
						'other' => q({0} kpk.),
						'two' => q({0} kpk.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl. oz.),
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
						'two' => q({0} fl. oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl. oz.),
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
						'two' => q({0} fl. oz.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
						'two' => q({0} brit. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
						'two' => q({0} brit. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
						'two' => q({0} brit. gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
						'two' => q({0} brit. gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggeraj),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggeraj),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
						'two' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
						'two' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
						'two' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
						'two' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} qt Imp.),
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
						'two' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt Imp.),
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
						'two' => q({0} qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} łž.),
						'name' => q(łž.),
						'one' => q({0} łž.),
						'other' => q({0} łž.),
						'two' => q({0} łž.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} łž.),
						'name' => q(łž.),
						'one' => q({0} łž.),
						'other' => q({0} łž.),
						'two' => q({0} łž.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} łžk.),
						'name' => q(łžk.),
						'one' => q({0} łžk.),
						'other' => q({0} łžk.),
						'two' => q({0} łžk.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} łžk.),
						'name' => q(łžk.),
						'one' => q({0} łžk.),
						'other' => q({0} łžk.),
						'two' => q({0} łžk.),
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
		'CNH' => {
			display_name => {
				'currency' => q(chinski yuan \(offshore\)),
				'few' => q(chinske yuany \(offshore\)),
				'one' => q(chinski yuan \(offshore\)),
				'other' => q(chinskich yuanow \(offshore\)),
				'two' => q(chinskej yuanaj \(offshore\)),
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
		'LSL' => {
			display_name => {
				'currency' => q(lesothiski loti),
				'few' => q(lesothiske lotije),
				'one' => q(lesothiski loti),
				'other' => q(lesothiskich lotijow),
				'two' => q(lesothiskej lotijej),
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
			symbol => 'F CFA',
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
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{am},
					'pm' => q{pm},
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
			Bh => q{h 'hodź'. B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{HH 'hodź'.},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h 'hodź'. a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMM => q{LLLL y G},
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
			GyMd => q{d.M.y GGGGG},
			H => q{H 'hodź'.},
			Hm => q{H:mm 'hodź'.},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMW => q{'tydźeń' W MMMM},
			MMMMd => q{d MMMM},
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
			yMMMM => q{LLLL y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'tydźeń' w 'lěta' Y},
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
				B => q{h 'hodź'. B – h 'hodź'. B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm 'hodź'. B – h:mm 'hodź'. B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
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
			Bh => {
				B => q{h 'hodź'. B – h 'hodź'. B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm 'hodź'. B – h:mm 'hodź'. B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
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
		'Asia/Karachi' => {
			exemplarCity => q#Karači#,
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
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
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
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinowany swětowy čas#,
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
				'daylight' => q#lětni čas kupy Norfolk#,
				'generic' => q#čas kupy Norfolk#,
				'standard' => q#standardny čas kupy Norfolk#,
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
		'Pyongyang' => {
			long => {
				'standard' => q#Pjöngjangski čas#,
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
		'Yukon' => {
			long => {
				'standard' => q#Yukonowy čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
