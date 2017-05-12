=head1

Locale::CLDR::Locales::Sw - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw;
# This file auto generated from Data\common\main\sw.xml
#	on Fri 29 Apr  7:27:19 pm GMT

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
				'ab' => 'Kiabkhazi',
 				'ach' => 'Kiakoli',
 				'af' => 'Kiafrikana',
 				'agq' => 'Kiaghem',
 				'ak' => 'Kiakani',
 				'am' => 'Kiamhari',
 				'ang' => 'Kiingereza cha Kale',
 				'ar' => 'Kiarabu',
 				'ar_001' => 'Kiarabu Sanifu cha Kisasa',
 				'arc' => 'Kiaramu',
 				'arn' => 'Kimapuche',
 				'arq' => 'Kiarabu cha Kialjeria',
 				'arz' => 'Kiarabu cha Misri',
 				'as' => 'Kiassam',
 				'asa' => 'Kiasu',
 				'ay' => 'Kiaimara',
 				'az' => 'Kiazabajani',
 				'az@alt=short' => 'Kiazeri',
 				'ba' => 'Kibashkir',
 				'bas' => 'Kibasaa',
 				'bax' => 'Kibamun',
 				'bbj' => 'Kighomala',
 				'be' => 'Kibelarusi',
 				'bej' => 'Kibeja',
 				'bem' => 'Kibemba',
 				'bez' => 'Kibena',
 				'bfd' => 'Kibafut',
 				'bg' => 'Kibulgaria',
 				'bgn' => 'Kibalochi cha Magharibi',
 				'bkm' => 'Kikom',
 				'bm' => 'Kibambara',
 				'bn' => 'Kibengali',
 				'bo' => 'Kitibeti',
 				'br' => 'Kibretoni',
 				'brx' => 'Kibodo',
 				'bs' => 'Kibosnia',
 				'bum' => 'Kibulu',
 				'byv' => 'Kimedumba',
 				'ca' => 'Kikatalani',
 				'ce' => 'Kichechenia',
 				'cgg' => 'Kichiga',
 				'chr' => 'Kicherokee',
 				'ckb' => 'Kikurdi cha Sorani',
 				'co' => 'Kikosikani',
 				'cop' => 'Kikhufti',
 				'cs' => 'Kicheki',
 				'cv' => 'Kichuvash',
 				'cy' => 'Kiwelisi',
 				'da' => 'Kidenmaki',
 				'dav' => 'Kitaita',
 				'de' => 'Kijerumani',
 				'dje' => 'Kizarma',
 				'dsb' => 'Kidolnoserbski',
 				'dua' => 'Kiduala',
 				'dv' => 'Kidivehi',
 				'dyo' => 'Kijola-Fonyi',
 				'dyu' => 'Kijula',
 				'dz' => 'Kizongkha',
 				'ebu' => 'Kiembu',
 				'ee' => 'Kiewe',
 				'efi' => 'Kiefiki',
 				'egy' => 'Kimisri',
 				'eka' => 'Kiekajuk',
 				'el' => 'Kigiriki',
 				'en' => 'Kiingereza',
 				'en_US@alt=short' => 'Kiingereza (US)',
 				'eo' => 'Kiesperanto',
 				'es' => 'Kihispania',
 				'et' => 'Kiestonia',
 				'eu' => 'Kibasque',
 				'ewo' => 'Kiewondo',
 				'fa' => 'Kiajemi',
 				'ff' => 'Kifulfulde',
 				'fi' => 'Kifini',
 				'fil' => 'Kifilipino',
 				'fj' => 'Kifiji',
 				'fo' => 'Kifaroe',
 				'fon' => 'Kifon',
 				'fr' => 'Kifaransa',
 				'fro' => 'Kifaransa cha Kale',
 				'frr' => 'Kifrisia cha Kaskazini',
 				'frs' => 'Kifrisia cha Mashariki',
 				'fy' => 'Kifrisia cha Magharibi',
 				'ga' => 'Kiayalandi',
 				'gaa' => 'Kiga',
 				'gag' => 'Kigagauzi',
 				'gba' => 'Kigbaya',
 				'gd' => 'Kigaeli cha Uskoti',
 				'gez' => 'Kige’ez',
 				'gl' => 'Kigalisi',
 				'gn' => 'Kiguarani',
 				'grc' => 'Kiyunani',
 				'gsw' => 'Kijerumani cha Uswisi',
 				'gu' => 'Kigujarati',
 				'guz' => 'Kikisii',
 				'gv' => 'Kimanx',
 				'ha' => 'Kihausa',
 				'haw' => 'Kihawai',
 				'he' => 'Kiebrania',
 				'hi' => 'Kihindi',
 				'hit' => 'Kihiti',
 				'hr' => 'Kroeshia',
 				'hsb' => 'hsb',
 				'ht' => 'Kihaiti',
 				'hu' => 'Kihungari',
 				'hy' => 'Kiarmenia',
 				'hz' => 'Kiherero',
 				'ia' => 'Kiintalingua',
 				'ibb' => 'Kiibibio',
 				'id' => 'Kiindonesia',
 				'ie' => 'lugha ya kisayansi',
 				'ig' => 'Kiigbo',
 				'ii' => 'Sichuan Yi',
 				'is' => 'Kiaisilandi',
 				'it' => 'Kiitaliano',
 				'iu' => 'Kiinuktitut',
 				'ja' => 'Kijapani',
 				'jgo' => 'Kingomba',
 				'jmc' => 'Kimachame',
 				'jv' => 'Kijava',
 				'ka' => 'Kijojia',
 				'kab' => 'Kikabylia',
 				'kam' => 'Kikamba',
 				'kbl' => 'Kikanembu',
 				'kde' => 'Kimakonde',
 				'kea' => 'Kikabuverdianu',
 				'kfo' => 'Kikoro',
 				'kg' => 'Kikongo',
 				'khq' => 'Kikoyra Chiini',
 				'ki' => 'Kikikuyu',
 				'kj' => 'Kikwanyama',
 				'kk' => 'Kikazaki',
 				'kkj' => 'Kikako',
 				'kl' => 'Kikalaallisut',
 				'kln' => 'Kikalenjin',
 				'km' => 'Kikambodia',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kikannada',
 				'ko' => 'Kikorea',
 				'koi' => 'Kikomipermyak',
 				'kok' => 'Kikonkani',
 				'kr' => 'Kikanuri',
 				'ks' => 'Kikashmiri',
 				'ksb' => 'Kisambaa',
 				'ksf' => 'Kibafia',
 				'ku' => 'Kikurdi',
 				'kv' => 'Kikomi',
 				'kw' => 'Kikorni',
 				'ky' => 'Kikirigizi',
 				'la' => 'Kilatini',
 				'lag' => 'Kirangi',
 				'lam' => 'Chilamba',
 				'lb' => 'Kilasembagi',
 				'lg' => 'Kiganda',
 				'lkt' => 'Kilakota',
 				'ln' => 'Kilingala',
 				'lo' => 'Kilaosi',
 				'lol' => 'Kimongo',
 				'loz' => 'Kilozi',
 				'lrc' => 'Kiluri cha Kaskazini',
 				'lt' => 'Kilithuania',
 				'lu' => 'Kiluba-Katanga',
 				'lua' => 'Kiluba-Lulua',
 				'lun' => 'Kilunda',
 				'luo' => 'Kijaluo',
 				'luy' => 'Kiluhya',
 				'lv' => 'Kilatvia',
 				'maf' => 'Kimafa',
 				'mag' => 'Kimagahi',
 				'mas' => 'Kimaasai',
 				'mde' => 'Kimaba',
 				'men' => 'Kimende',
 				'mer' => 'Kimeru',
 				'mfe' => 'Kimoriseni',
 				'mg' => 'Malagasi',
 				'mgh' => 'Kimakhuwa-Meetto',
 				'mgo' => 'Kimeta',
 				'mi' => 'Kimaori',
 				'mk' => 'Kimasedonia',
 				'ml' => 'Kimalayalam',
 				'mn' => 'Kimongolia',
 				'moh' => 'Kimohoki',
 				'mos' => 'Kimoore',
 				'mr' => 'Kimarathi',
 				'ms' => 'Kimalesia',
 				'mt' => 'Kimalta',
 				'mua' => 'Kimundang',
 				'mul' => 'Lugha Nyingi',
 				'my' => 'Kiburma',
 				'mzn' => 'Kimazanderani',
 				'naq' => 'Kinama',
 				'nb' => 'Kibokmal cha Norwe',
 				'nd' => 'Kindebele cha Kaskazini',
 				'nds' => 'nds',
 				'ne' => 'Kinepali',
 				'new' => 'Kinewari',
 				'ng' => 'Kindonga',
 				'nl' => 'Kiholanzi',
 				'nmg' => 'Kikwasio',
 				'nn' => 'Kinorwe Kipya',
 				'no' => 'Kinorwe',
 				'nqo' => 'N’Ko',
 				'nr' => 'Kindebele',
 				'nso' => 'Kisotho cha Kaskazini',
 				'nus' => 'Kinuer',
 				'nwc' => 'Kinewari cha kale',
 				'ny' => 'Kinyanja',
 				'nym' => 'Kinyamwezi',
 				'nyn' => 'Kinyankole',
 				'nyo' => 'Kinyoro',
 				'nzi' => 'Kinzema',
 				'oc' => 'Kiokitani',
 				'om' => 'Kioromo',
 				'or' => 'Kioriya',
 				'os' => 'Kiosetia',
 				'pa' => 'Kipunjabi',
 				'peo' => 'Kiajemi cha Kale',
 				'pl' => 'Kipolandi',
 				'ps' => 'Kipashto',
 				'ps@alt=variant' => 'Kipushto',
 				'pt' => 'Kireno',
 				'qu' => 'Kiquechua',
 				'quc' => 'Kʼicheʼ',
 				'rap' => 'Kirapanui',
 				'rar' => 'Kiraratonga',
 				'rm' => 'Kiromanshi',
 				'rn' => 'Kirundi',
 				'ro' => 'Kiromania',
 				'rof' => 'Kirombo',
 				'ru' => 'Kirusi',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Kirwo',
 				'sa' => 'Kisanskriti',
 				'sad' => 'Kisandawe',
 				'sam' => 'Kiaramu cha Wasamaria',
 				'saq' => 'Kisamburu',
 				'sbp' => 'Kisangu',
 				'sd' => 'Kisindhi',
 				'sdh' => 'Kikurdi cha Kusini',
 				'se' => 'Kisami cha Kaskazini',
 				'seh' => 'Kisena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Kisango',
 				'sh' => 'Kiserbia-kroeshia',
 				'shi' => 'Kitachelhit',
 				'shu' => 'Kiarabu cha Chadi',
 				'si' => 'Kisinhala',
 				'sk' => 'Kislovakia',
 				'sl' => 'Kislovenia',
 				'sm' => 'Kisamoa',
 				'sma' => 'Kisami cha Kusini',
 				'smj' => 'Kisami cha Lule',
 				'smn' => 'Kisami cha Inari',
 				'sms' => 'Kisami cha Skolt',
 				'sn' => 'Kishona',
 				'snk' => 'Kisoninke',
 				'so' => 'Kisomali',
 				'sq' => 'Kialbania',
 				'sr' => 'Kiserbia',
 				'ss' => 'Kiswati',
 				'ssy' => 'Kisaho',
 				'st' => 'Kisotho cha Kusini',
 				'su' => 'Kisunda',
 				'suk' => 'Kisukuma',
 				'sus' => 'Kisusu',
 				'sv' => 'Kiswidi',
 				'sw' => 'Kiswahili',
 				'sw_CD' => 'Kingwana',
 				'swb' => 'Shikomor',
 				'ta' => 'Kitamil',
 				'te' => 'Kitelugu',
 				'tem' => 'Kitemne',
 				'teo' => 'Kiteso',
 				'tet' => 'Kitetum',
 				'tg' => 'Kitajiki',
 				'th' => 'Kitailandi',
 				'ti' => 'Kitigrinya',
 				'tk' => 'Kiturukimeni',
 				'tlh' => 'Kiklingoni',
 				'tn' => 'Kitswana',
 				'to' => 'Kitonga',
 				'tpi' => 'Kitokpisin',
 				'tr' => 'Kituruki',
 				'ts' => 'Kitsonga',
 				'tt' => 'Kitatari',
 				'tum' => 'Kitumbuka',
 				'tw' => 'Kitwi',
 				'twq' => 'Kitasawaq',
 				'ty' => 'Kitahiti',
 				'tzm' => 'Central Atlas Tamazight',
 				'ug' => 'Kiuyghur',
 				'uk' => 'Kiukrania',
 				'und' => 'Lugha Isiyojulikana',
 				'ur' => 'Kiurdu',
 				'uz' => 'Kiuzbeki',
 				'vai' => 'Kivai',
 				've' => 'Kivenda',
 				'vi' => 'Kivietinamu',
 				'vun' => 'Kivunjo',
 				'wbp' => 'Kiwarlpiri',
 				'wo' => 'Kiwolofu',
 				'xh' => 'Kixhosa',
 				'xog' => 'Kisoga',
 				'yao' => 'Kiyao',
 				'ybb' => 'Kiyemba',
 				'yi' => 'Kiyidi',
 				'yo' => 'Kiyoruba',
 				'zgh' => 'Tamaziti Msingi ya Kimoroko',
 				'zh' => 'Kichina',
 				'zh_Hans' => 'Kichina (Kilichorahisishwa)',
 				'zh_Hant' => 'Kichina cha Jadi',
 				'zu' => 'Kizulu',
 				'zxx' => 'Hakuna maudhui ya lugha',

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
			'Arab' => 'Kiarabu',
 			'Arab@alt=variant' => 'Kiajemi/Kiarabu',
 			'Armn' => 'Kiarmenia',
 			'Beng' => 'Kibengali',
 			'Bopo' => 'Kibopomofo',
 			'Brai' => 'Braille',
 			'Cyrl' => 'Kisiriliki',
 			'Deva' => 'Kidevanagari',
 			'Ethi' => 'Kiethiopia',
 			'Geor' => 'Kijojia',
 			'Grek' => 'Kigiriki',
 			'Gujr' => 'Kigujarati',
 			'Guru' => 'Kigurmukhi',
 			'Hang' => 'Kihangul',
 			'Hani' => 'Kihan',
 			'Hans' => 'Rahisi',
 			'Hans@alt=stand-alone' => 'Kihan Rahisi',
 			'Hant' => 'Kihan cha Jadi',
 			'Hant@alt=stand-alone' => 'Kihan cha Jadi',
 			'Hebr' => 'Kiebrania',
 			'Hira' => 'Kihiragana',
 			'Jpan' => 'Kijapani',
 			'Kana' => 'Kikatakana',
 			'Khmr' => 'Kikambodia',
 			'Knda' => 'Kikannada',
 			'Kore' => 'Kikorea',
 			'Laoo' => 'Kilaosi',
 			'Latn' => 'Kilatini',
 			'Mlym' => 'Kimalayalam',
 			'Mong' => 'Kimongolia',
 			'Mymr' => 'Myama',
 			'Orya' => 'Kioriya',
 			'Sinh' => 'Kisinhala',
 			'Taml' => 'Kitamil',
 			'Telu' => 'Kitelugu',
 			'Thaa' => 'Kithaana',
 			'Thai' => 'Kitai',
 			'Tibt' => 'Kitibeti',
 			'Zsym' => 'Alama',
 			'Zxxx' => 'Haijaandikwa',
 			'Zyyy' => 'Kawaida',
 			'Zzzz' => 'Hati isiyojulikana',

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
			'001' => 'Dunia',
 			'002' => 'Afrika',
 			'003' => 'Amerika Kaskazini',
 			'005' => 'Amerika Kusini',
 			'009' => 'Oceania',
 			'011' => 'Afrika ya Magharibi',
 			'013' => 'Amerika ya Kati',
 			'014' => 'Afrika ya Mashariki',
 			'015' => 'Afrika ya Kaskazini',
 			'017' => 'Afrika ya Kati',
 			'018' => 'Afrika ya Kusini',
 			'019' => 'Amerika',
 			'021' => 'Amerika ya Kaskazini',
 			'029' => 'Karibiani',
 			'030' => 'Asia Mashariki',
 			'034' => 'Asia ya Kusini',
 			'035' => 'Asia ya Kusini Mashariki',
 			'039' => 'Ulaya ya Kusini',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Eneo la Mikronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Asia ya Kati',
 			'145' => 'Asia ya Magharibi',
 			'150' => 'Ulaya',
 			'151' => 'Ulaya ya Mashariki',
 			'154' => 'Ulaya ya Kaskazini',
 			'155' => 'Ulaya ya Magharibi',
 			'419' => 'Amerika ya Kilatini',
 			'AC' => 'Kisiwa cha Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Falme za Kiarabu',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antaktika',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ya Marekani',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Visiwa vya Alandi',
 			'AZ' => 'Azabajani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangladeshi',
 			'BE' => 'Ubelgiji',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahareni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Santabathelemi',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Uholanzi ya Karibiani',
 			'BR' => 'Brazili',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Kisiwa cha Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarusi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Visiwa vya Cocos (Keeling)',
 			'CD' => 'Jamhuri ya Kidemokrasia ya Kongo',
 			'CD@alt=variant' => 'Kongo (DRC)',
 			'CF' => 'Jamhuri ya Afrika ya Kati',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Jamhuri ya Kongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Visiwa vya Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameruni',
 			'CN' => 'China',
 			'CO' => 'Kolombia',
 			'CP' => 'Kisiwa cha Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepuvede',
 			'CW' => 'Kurakao',
 			'CX' => 'Kisiwa cha Krismasi',
 			'CY' => 'Cyprus',
 			'CZ' => 'Jamhuri ya Cheki',
 			'DE' => 'Ujerumani',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuri ya Dominika',
 			'DZ' => 'Aljeria',
 			'EA' => 'Ceuta na Melilla',
 			'EC' => 'Ekwado',
 			'EE' => 'Estonia',
 			'EG' => 'Misri',
 			'EH' => 'Sahara Magharibi',
 			'ER' => 'Eritrea',
 			'ES' => 'Hispania',
 			'ET' => 'Uhabeshi',
 			'EU' => 'Umoja wa Ulaya',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Visiwa vya Falkland',
 			'FK@alt=variant' => 'Visiwa vya Falkland (Islas Malvinas)',
 			'FM' => 'Mikronesia',
 			'FO' => 'Visiwa vya Faroe',
 			'FR' => 'Ufaransa',
 			'GA' => 'Gabon',
 			'GB' => 'Uingereza',
 			'GB@alt=short' => 'Uingereza',
 			'GD' => 'Grenada',
 			'GE' => 'Jojia',
 			'GF' => 'Gwiyana ya Ufaransa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Jibralta',
 			'GL' => 'Grinlandi',
 			'GM' => 'Gambia',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Ginekweta',
 			'GR' => 'Ugiriki',
 			'GS' => 'Jojia Kusini na Visiwa vya Sandwich Kusini',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Kisiwa cha Heard na Visiwa vya McDonald',
 			'HN' => 'Hondurasi',
 			'HR' => 'Korasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Visiwa vya Kanari',
 			'ID' => 'Indonesia',
 			'IE' => 'Ayalandi',
 			'IL' => 'Israeli',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Eneo la Uingereza katika Bahari Hindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Iran',
 			'IS' => 'Aislandi',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizistani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Santakitzi na Nevis',
 			'KP' => 'Korea Kaskazini',
 			'KR' => 'Korea Kusini',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Visiwa vya Kayman',
 			'KZ' => 'Kazakistani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Santalusia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Lativia',
 			'LY' => 'Libya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaska',
 			'MH' => 'Visiwa vya Marshall',
 			'MK' => 'Masedonia',
 			'MK@alt=variant' => 'Masedonia (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Visiwa vya Mariana vya Kaskazini',
 			'MQ' => 'Martiniki',
 			'MR' => 'Moritania',
 			'MS' => 'Montserrati',
 			'MT' => 'Malta',
 			'MU' => 'Morisi',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Msumbiji',
 			'NA' => 'Namibia',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Niger',
 			'NF' => 'Kisiwa cha Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Uholanzi',
 			'NO' => 'Norwe',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nyuzilandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Ufilipino',
 			'PK' => 'Pakistani',
 			'PL' => 'Polandi',
 			'PM' => 'Santapierre na Miquelon',
 			'PN' => 'Visiwa vya Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Maeneo ya Palestina',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Ureno',
 			'PW' => 'Palau',
 			'PY' => 'Paragwai',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania ya Nje',
 			'RE' => 'Riyunioni',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Urusi',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi',
 			'SB' => 'Visiwa vya Solomon',
 			'SC' => 'Shelisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Uswidi',
 			'SG' => 'Singapore',
 			'SH' => 'Santahelena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard na Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Siera Leoni',
 			'SM' => 'San Marino',
 			'SN' => 'Senegali',
 			'SO' => 'Somalia',
 			'SR' => 'Surinamu',
 			'SS' => 'Sudani Kusini',
 			'ST' => 'São Tomé na Príncipe',
 			'SV' => 'Elsavado',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Uswazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Visiwa vya Turki na Kaiko',
 			'TD' => 'Chad',
 			'TF' => 'Maeneo ya Kusini ya Ufaransa',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tajikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor ya Mashariki',
 			'TM' => 'Turukimenistani',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Uturuki',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraini',
 			'UG' => 'Uganda',
 			'UM' => 'Visiwa Vidogo vya Nje vya Marekani',
 			'US' => 'Marekani',
 			'US@alt=short' => 'US',
 			'UY' => 'Urugwai',
 			'UZ' => 'Uzibekistani',
 			'VA' => 'Vatikani',
 			'VC' => 'Santavisenti na Grenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Visiwa vya Virgin vya Uingereza',
 			'VI' => 'Visiwa vya Virgin vya Marekani',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walis na Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kusini',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Eneo lisilojulikana',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Kalenda',
 			'colalternate' => 'Puuza Upangaji Alama',
 			'colbackwards' => 'Upangaji Uliogeuzwa wa Kiinitoni',
 			'colcasefirst' => 'Upangaji wa Herufi kubwa/Herufi ndogo',
 			'colcaselevel' => 'Upangaji Unaoathiriwa na Herufi',
 			'colhiraganaquaternary' => 'Upangaji wa Kana',
 			'collation' => 'Mpangilio',
 			'colnormalization' => 'Upangaji wa Kawaida',
 			'colnumeric' => 'Upangaji wa Namba',
 			'colstrength' => 'Nguvu ya Upangaji',
 			'currency' => 'Sarafu',
 			'hc' => 'hc',
 			'lb' => 'lb',
 			'ms' => 'ms',
 			'numbers' => 'Nambari',
 			'timezone' => 'Ukanda Saa',
 			'va' => 'Tofauti ya Mandhari',
 			'variabletop' => 'Panga Kama Alama',
 			'x' => 'Matumizi ya Kibinafsi',

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
 				'buddhist' => q{Kalenda ya Kibuddha},
 				'chinese' => q{Kalenda ya Kichina},
 				'coptic' => q{Kalenda ya Koptiki},
 				'dangi' => q{Kalenda ya Dangi},
 				'ethiopic' => q{Kalenda ya Kiethiopia},
 				'ethiopic-amete-alem' => q{Kalenda ya Kiethiopia ya Amete Alem},
 				'gregorian' => q{Kalenda ya Kigregori},
 				'hebrew' => q{Kalenda ya Kiebrania},
 				'indian' => q{Kalenda ya Taifa ya India},
 				'islamic' => q{Kalenda ya Kiislamu},
 				'islamic-civil' => q{Kalenda ya Kiislamu/Rasmi},
 				'iso8601' => q{Kalenda ya ISO-8601},
 				'japanese' => q{Kalenda ya Kijapani},
 				'persian' => q{Kalenda ya Kiajemi},
 				'roc' => q{Kalenda ya Minguo},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Panga Alama},
 				'shifted' => q{Panga Alama za Kupuuza},
 			},
 			'colbackwards' => {
 				'no' => q{Panga Viinitoni kwa Kawaida},
 				'yes' => q{Panga Viinitoni Kumegeuzwa},
 			},
 			'colcasefirst' => {
 				'lower' => q{Panga Herufi ndogo Kwanza},
 				'no' => q{Panga Utaratibu wa Herufi ya Kawaida},
 				'upper' => q{Panga Herufi kubwa Kwanza},
 			},
 			'colcaselevel' => {
 				'no' => q{Panga Isiyoathiriwa na Herufi},
 				'yes' => q{Panga kwa Inayoathiriwa na Herufi},
 			},
 			'colhiraganaquaternary' => {
 				'no' => q{Panga Kana Kando},
 				'yes' => q{Panga Kana Kitofauti},
 			},
 			'collation' => {
 				'big5han' => q{Mpangilio wa Kichina cha Jadi - Big5},
 				'dictionary' => q{Mpangilio wa Kamusi},
 				'ducet' => q{Mpangilio Chaguo-Msingi wa Unicode},
 				'gb2312han' => q{Mpangilio wa Kichina Rahisi - GB2312},
 				'phonebook' => q{Mpangilio wa Orodha za Nambari za Simu},
 				'phonetic' => q{Utaratibu wa Kupanga Fonetiki},
 				'pinyin' => q{Mpangilio wa Kipinyin},
 				'reformed' => q{Mpangilio Uliorekebishwa},
 				'search' => q{Utafutaji wa Kijumla},
 				'searchjl' => q{Tafuta kwa Konsonanti Halisi ya Hangul},
 				'standard' => q{Mpangilio wa Kawaida},
 				'stroke' => q{Mpangilio wa Mikwaju},
 				'traditional' => q{Mpangilio wa Kawaida},
 				'unihan' => q{Mpangilio wa Mikwaju ya Shina},
 			},
 			'colnormalization' => {
 				'no' => q{Panga Bila Ukawaida},
 				'yes' => q{Upangaji Msimbosare Umekawaidishwa},
 			},
 			'colnumeric' => {
 				'no' => q{Panga Tarakimu Kivyake},
 				'yes' => q{Panga Dijiti kwa Namba},
 			},
 			'colstrength' => {
 				'identical' => q{Panga Zote},
 				'primary' => q{Panga Herufi Msingi Tu},
 				'quaternary' => q{Panga Viinitoni/Herufi/Upana/Kana},
 				'secondary' => q{Panga Viinitoni},
 				'tertiary' => q{Panga Viinitoni/Herufi/Upana},
 			},
 			'hc' => {
 				'h11' => q{h11},
 				'h12' => q{h12},
 				'h23' => q{h23},
 				'h24' => q{h24},
 			},
 			'lb' => {
 				'loose' => q{loose},
 				'normal' => q{normal},
 				'strict' => q{strict},
 			},
 			'ms' => {
 				'metric' => q{metriki},
 				'uksystem' => q{mfumo wa UK},
 				'ussystem' => q{Mfumo wa US},
 			},
 			'numbers' => {
 				'arab' => q{Nambari za Kiarabu/Kihindi},
 				'arabext' => q{Nambari za Kiarabu/Kihindi Zilizopanuliwa},
 				'armn' => q{Nambari za Kiarmenia},
 				'armnlow' => q{Nambari Ndogo za Kiarmenia},
 				'beng' => q{Nambari za Kibengali},
 				'cham' => q{Nambari za Kichami},
 				'deva' => q{Nambari za Kidevanagari},
 				'ethi' => q{Nambari za Kiethiopia},
 				'finance' => q{Tarakimu za Kifedha},
 				'fullwide' => q{Nambari za Upana Kamili},
 				'geor' => q{Nambari za Georgia},
 				'grek' => q{Nambari za Kigiriki},
 				'greklow' => q{Nambari Ndogo za Kigiriki},
 				'gujr' => q{Nambari za Kigujarati},
 				'guru' => q{Nambari za Kigurumukhi},
 				'hanidec' => q{Nambari za Desimali za Kichina},
 				'hans' => q{Nambari za Kichina Rahisi},
 				'hansfin' => q{Nambari za Kifedha za Kichina Rahisi},
 				'hant' => q{Nambari za Kichina cha Jadi},
 				'hantfin' => q{Nambari za Kichina za Fedha},
 				'hebr' => q{Nambari za Kiebrania},
 				'java' => q{Nambari za Kijava},
 				'jpan' => q{Nambari za Kijapani},
 				'jpanfin' => q{Nambari za Kifedha za Kijapani},
 				'khmr' => q{Nambari za Kikhmeri},
 				'knda' => q{Nambari za Kikannada},
 				'laoo' => q{Nambari za Kilao},
 				'latn' => q{Nambari za Magharibi},
 				'limb' => q{Nambari za Kilimbu},
 				'mlym' => q{Nambari za Kimalayamu},
 				'mong' => q{Nambari za Kimongolia},
 				'mymr' => q{Nambari za Myama},
 				'native' => q{Digiti Asili},
 				'orya' => q{Nambari za Kioriya},
 				'roman' => q{Nambari za Kirumi},
 				'romanlow' => q{Nambari Ndogo za Kirumi},
 				'takr' => q{Nambari za Kitakri},
 				'taml' => q{Nambari za Kitamili},
 				'tamldec' => q{Nambari za Kitamili},
 				'telu' => q{Nambari za Kitelugu},
 				'thai' => q{Nambari za Kitai},
 				'tibt' => q{Nambari za Kitibeti},
 				'traditional' => q{Tarakimu za Jadi},
 				'vaii' => q{Dijiti za Vai},
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
			'metric' => q{Mfumo wa Mita},
 			'UK' => q{Uingereza},
 			'US' => q{Marekani},

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
 			'numeric' => 'Ya Nambari',
 			'tone' => 'Sauti',
 			'ungegn' => 'UNGEGN',
 			'x-accents' => 'Rangi za Kuangaza',
 			'x-fullwidth' => 'Upana kamili',
 			'x-halfwidth' => 'Nusu upana',
 			'x-jamo' => 'Kijamo',
 			'x-pinyin' => 'Kipinyin',
 			'x-publishing' => 'Inachapishwa',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{(?^u:[c q x])},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a b {ch} d e f g h i j k l m n o p r s t u v w y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					'acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					'ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					'arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(kipimo {0} cha astronomia),
						'other' => q(vipimo {0} vya astronomia),
					},
					'bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					'byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					'calorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'celsius' => {
						'name' => q(nyuzi za selisiasi),
						'one' => q(nyuzi ya selisiasi {0}),
						'other' => q(nyuzi za selisiasi {0}),
					},
					'centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					'century' => {
						'name' => q(karne),
						'one' => q(karne ya {0}),
						'other' => q(karne za {0}),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(sentimita {0} ya ujazo),
						'other' => q(sentimita {0} za ujazo),
						'per' => q({0} kwa kila sentimita ya ujazo),
					},
					'cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(futi {0} ya ujazo),
						'other' => q(futi {0} za ujazo),
					},
					'cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(inchi {0} ya ujazo),
						'other' => q(inchi {0} za ujazo),
					},
					'cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(kilomita {0} ya ujazo),
						'other' => q(kilomita {0} za ujazo),
					},
					'cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(mita {0} ya ujazo),
						'other' => q(mita {0} za ujazo),
						'per' => q({0} kwa kila mita ya ujazo),
					},
					'cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(maili {0} ya ujazo),
						'other' => q(maili {0} za ujazo),
					},
					'cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yadi {0} ya ujazo),
						'other' => q(yadi {0} za ujazo),
					},
					'cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					'cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(kikombe {0} cha mizani),
						'other' => q(vikombe {0} vya mizani),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					'deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					'decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					'fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
						'one' => q(nyuzi za farenheiti {0}),
						'other' => q(nyuzi za farenheiti {0}),
					},
					'fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(aunsi {0} ya ujazo),
						'other' => q(aunsi {0} za ujazo),
					},
					'foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					'g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(mvuto wa graviti {0}),
						'other' => q(mvuto wa graviti {0}),
					},
					'gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0} kwa kila galoni),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					'gigabyte' => {
						'name' => q(gigabaiti),
						'one' => q(gigabaiti {0}),
						'other' => q(gigabaiti {0}),
					},
					'gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					'gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					'hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					'hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					'hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hektopaskali {0}),
						'other' => q(hektopaskali {0}),
					},
					'hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					'horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q(kipimo cha hospawa {0}),
						'other' => q(kipimo cha hospawa {0}),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					'inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					'inch-hg' => {
						'name' => q(inchi za zebaki),
						'one' => q(inchi {0} ya zebaki),
						'other' => q(inchi {0} za zebaki),
					},
					'joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					'karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'kelvin' => {
						'name' => q(kelvini),
						'one' => q(kelvini {0}),
						'other' => q(kelvini {0}),
					},
					'kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					'kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kilogramu {0}),
						'other' => q(kilogramu {0}),
						'per' => q({0} kwa kila kilogramu),
					},
					'kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					'kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
						'per' => q({0} kwa kila kilomita),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(kilomita {0} kwa saa),
						'other' => q(kilomita {0} kwa saa),
					},
					'kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					'kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q(kilowati {0} kwa saa),
						'other' => q(kilowati {0} kwa saa),
					},
					'knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					'light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(miaka ya mwanga {0}),
						'other' => q(miaka ya mwanga {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0} kwa kilomita 100),
					},
					'liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					'megabit' => {
						'name' => q(megabiti),
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					'megabyte' => {
						'name' => q(megabaiti),
						'one' => q(megabaiti {0}),
						'other' => q(megabaiti {0}),
					},
					'megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					'megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					'megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					'meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q(mita {0} kwa sekunde),
						'other' => q(mita {0} kwa sekunde),
					},
					'meter-per-second-squared' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(mita {0} kwa kila sekunde mraba),
						'other' => q(mita {0} kwa kila sekunde mraba),
					},
					'metric-ton' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					'microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					'microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					'mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					'mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q(maili {0} kwa kila galoni),
						'other' => q(maili {0} kwa kila galoni),
					},
					'mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q(maili {0} kwa saa),
						'other' => q(maili {0} kwa saa),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliampea),
						'one' => q(miliampea {0}),
						'other' => q(miliampea {0}),
					},
					'millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(kipimo cha milibari {0}),
						'other' => q(kipimo cha milibari {0}),
					},
					'milligram' => {
						'name' => q(miligramu),
						'one' => q(miligramu {0}),
						'other' => q(miligramu {0}),
					},
					'milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimita za zebaki),
						'one' => q(milimita {0} ya zebaki),
						'other' => q(milimita {0} za zebaki),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					'milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					'month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					'nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					'nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
						'per' => q({0} kwa kila aunsi),
					},
					'ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q(parsec {0}),
						'other' => q(parsecs {0}),
					},
					'per' => {
						'1' => q({0} kwa kila {1}),
					},
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					'pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					'pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(painti {0} ya mizani),
						'other' => q(painti {0} za mizani),
					},
					'pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
						'per' => q({0} kwa kila ratili),
					},
					'pound-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(pauni {0} kwa kila inchi mraba),
						'other' => q(pauni {0} kwa kila inchi mraba),
					},
					'quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					'radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					'revolution' => {
						'name' => q(mzunguko),
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					'square-centimeter' => {
						'name' => q(sentimita mraba),
						'one' => q(sentimita mraba {0}),
						'other' => q(sentimita mraba {0}),
						'per' => q({0} kwa kila sentimita mraba),
					},
					'square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(futi {0} ya mraba),
						'other' => q(futi {0} za mraba),
					},
					'square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(inchi {0} ya mraba),
						'other' => q(inchi {0} za mraba),
						'per' => q({0} kwa kila inchi ya mraba),
					},
					'square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(kilomita {0} ya mraba),
						'other' => q(kilomita {0} za mraba),
					},
					'square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(mita {0} ya mraba),
						'other' => q(mita {0} za mraba),
						'per' => q({0} kwa kila mita ya mraba),
					},
					'square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
					},
					'square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					'tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					'teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
					'terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					'terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					'ton' => {
						'name' => q(tani),
						'one' => q(tani {0}),
						'other' => q(tani {0}),
					},
					'volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					'yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					'year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q(Ekari {0}),
						'other' => q(Ekari {0}),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(nyuzi za selisiasi),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					'cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q(Futi {0}),
						'other' => q(Futi {0}),
					},
					'g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
					},
					'hectare' => {
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					'hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					'horsepower' => {
						'one' => q(hp {0}),
						'other' => q(hp {0}),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
					},
					'inch' => {
						'name' => q(Inchi),
						'one' => q(Inchi {0}),
						'other' => q(Inchi {0}),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q(km {0}),
						'other' => q(km {0}),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					'kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					'light-year' => {
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
					},
					'meter-per-second' => {
						'one' => q(m {0}/s),
						'other' => q(m {0}/s),
					},
					'mile' => {
						'one' => q(Maili {0}),
						'other' => q(Maili {0}),
					},
					'mile-per-hour' => {
						'one' => q(mi {0}/saa),
						'other' => q(mi {0}/saa),
					},
					'millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'month' => {
						'name' => q(mwezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
					},
					'ounce' => {
						'one' => q(Aunsi {0}),
						'other' => q(Aunsi {0}),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					'pound' => {
						'one' => q(Ratili {0}),
						'other' => q(Ratili {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'square-foot' => {
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					'square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					'square-meter' => {
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					'square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
					},
					'volt' => {
						'name' => q(volti),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(Wati {0}),
						'other' => q(Wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
					},
					'yard' => {
						'one' => q(Yadi {0}),
						'other' => q(Yadi {0}),
					},
					'year' => {
						'name' => q(mwaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					'acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					'ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					'arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					'bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					'byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q(kalori {0}),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'celsius' => {
						'name' => q(nyuzi za selisiasi),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					'century' => {
						'name' => q(karne),
						'one' => q(karne ya {0}),
						'other' => q(karne za {0}),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
					},
					'cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					'cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					'cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(m³ {0}),
						'other' => q(mita {0} za ujazo),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					'cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					'cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					'cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(mc {0}),
						'other' => q(vikombe {0} vya mizani),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					'deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					'decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					'fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					'foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					'g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					'gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0}/gal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					'gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					'gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					'hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					'hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					'hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					'hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					'horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					'inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					'inch-hg' => {
						'name' => q(inchi za zebaki),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					'karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					'kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					'kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(km {0}),
						'other' => q(km {0}),
						'per' => q({0} kwa kila kilomita),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					'kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					'kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					'light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0} kwa kilomita 100),
					},
					'liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					'megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					'megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					'megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					'meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(m {0}/s²),
						'other' => q(m {0}/s²),
					},
					'metric-ton' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					'microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					'microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					'mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					'mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q(maili {0} kwa kila galoni),
						'other' => q(maili {0} kwa kila galoni),
					},
					'mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliampea),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					'milligram' => {
						'name' => q(miligramu),
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					'milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimita za zebaki),
						'one' => q(milimita {0} ya zebaki),
						'other' => q(milimita {0} za zebaki),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					'milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					'month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					'nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					'nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					'pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					'pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					'pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					'quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					'radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					'revolution' => {
						'name' => q(mzunguko),
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					'square-centimeter' => {
						'name' => q(sentimita mraba),
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					'square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					'square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(mita {0} ya mraba),
						'other' => q(m² {0}),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
					},
					'square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					'tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					'teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
					'terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					'terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					'ton' => {
						'name' => q(tani),
						'one' => q(tani {0}),
						'other' => q(tani {0}),
					},
					'volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					'yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					'year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ndiyo|N|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hapana|H)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} na {1}),
				2 => q({0} na {1}),
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
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
					'one' => 'elfu 0',
					'other' => 'elfu 0',
				},
				'10000' => {
					'one' => 'elfu 00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'M0',
					'other' => 'M0',
				},
				'10000000' => {
					'one' => 'M00',
					'other' => 'M00',
				},
				'100000000' => {
					'one' => 'M000',
					'other' => 'M000',
				},
				'1000000000' => {
					'one' => 'B0',
					'other' => 'B0',
				},
				'10000000000' => {
					'one' => 'B00',
					'other' => 'B00',
				},
				'100000000000' => {
					'one' => 'B000',
					'other' => 'B000',
				},
				'1000000000000' => {
					'one' => 'T0',
					'other' => 'T0',
				},
				'10000000000000' => {
					'one' => 'T00',
					'other' => 'T00',
				},
				'100000000000000' => {
					'one' => 'T000',
					'other' => 'T000',
				},
				'standard' => {
					'' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => 'Elfu 0',
					'other' => 'Elfu 0',
				},
				'10000' => {
					'one' => 'Elfu 00',
					'other' => 'Elfu 00',
				},
				'100000' => {
					'one' => 'Elfu 000',
					'other' => 'Elfu 000',
				},
				'1000000' => {
					'one' => 'Milioni 0',
					'other' => 'Milioni 0',
				},
				'10000000' => {
					'one' => 'Milioni 00',
					'other' => 'Milioni 00',
				},
				'100000000' => {
					'one' => 'Milioni 000',
					'other' => 'Milioni 000',
				},
				'1000000000' => {
					'one' => 'Bilioni 0',
					'other' => 'Bilioni 0',
				},
				'10000000000' => {
					'one' => 'Bilioni 00',
					'other' => 'Bilioni 00',
				},
				'100000000000' => {
					'one' => 'Bilioni 000',
					'other' => 'Bilioni 000',
				},
				'1000000000000' => {
					'one' => 'Trilioni 0',
					'other' => 'Trilioni 0',
				},
				'10000000000000' => {
					'one' => 'Trilioni 00',
					'other' => 'Trilioni 00',
				},
				'100000000000000' => {
					'one' => 'Trilioni 000',
					'other' => 'Trilioni 000',
				},
			},
			'short' => {
				'1000' => {
					'one' => 'elfu 0',
					'other' => 'elfu 0',
				},
				'10000' => {
					'one' => 'elfu 00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'M0',
					'other' => 'M0',
				},
				'10000000' => {
					'one' => 'M00',
					'other' => 'M00',
				},
				'100000000' => {
					'one' => 'M000',
					'other' => 'M000',
				},
				'1000000000' => {
					'one' => 'B0',
					'other' => 'B0',
				},
				'10000000000' => {
					'one' => 'B00',
					'other' => 'B00',
				},
				'100000000000' => {
					'one' => 'B000',
					'other' => 'B000',
				},
				'1000000000000' => {
					'one' => 'T0',
					'other' => 'T0',
				},
				'10000000000000' => {
					'one' => 'T00',
					'other' => 'T00',
				},
				'100000000000000' => {
					'one' => 'T000',
					'other' => 'T000',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham ya Falme za Kiarabu),
				'one' => q(dirham ya Falme za Kiarabu),
				'other' => q(dirham za Falme za Kiarabu),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghani ya Afghanistan),
				'one' => q(Afghani ya Afghanistan),
				'other' => q(Afghani za Afghanistan),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek ya Albania),
				'one' => q(Lek ya Albania),
				'other' => q(Lek za Albania),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram ya Armenia),
				'one' => q(Dram ya Armenia),
				'other' => q(Dram za Armenia),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Guilder ya Antili za Kiholanzi),
				'one' => q(Guilder ya Antili za Kiholanzi),
				'other' => q(Guilder ya Antili za Kiholanzi),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza ya Angola),
				'one' => q(kwanza ya Angola),
				'other' => q(kwanza za Angola),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso ya Ajentina),
				'one' => q(Peso ya Ajentina),
				'other' => q(Peso za Ajentina),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dola ya Australia),
				'one' => q(dola ya Australia),
				'other' => q(dola za Australia),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florin ya Aruba),
				'one' => q(Florin ya Aruba),
				'other' => q(Florin za Aruba),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat ya Azebaijani),
				'one' => q(Manat ya Azebaijani),
				'other' => q(Manat za Azebaijani),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Convertible Mark ya Bosnia na Hezegovina),
				'one' => q(Convertible Mark ya Bosnia na Hezegovina),
				'other' => q(Convertible Mark za Bosnia na Hezegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dola ya Barbados),
				'one' => q(Dola ya Barbados),
				'other' => q(Dola za Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka ya Bangladeshi),
				'one' => q(Taka ya Bangladeshi),
				'other' => q(Taka za Bangladeshi),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev ya Bulgaria),
				'one' => q(Lev ya Bulgaria),
				'other' => q(Lev za Bulgaria),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar ya Bahareni),
				'one' => q(Dinar ya Bahareni),
				'other' => q(Dinar za Bahareni),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Faranga ya Burundi),
				'one' => q(faranga ya Burundi),
				'other' => q(faranga za Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dola ya Bermuda),
				'one' => q(Dola ya Bermuda),
				'other' => q(Dola za Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dola ya Brunei),
				'one' => q(Dola ya Brunei),
				'other' => q(Dola za Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano ya Bolivia),
				'one' => q(Boliviano ya Bolivia),
				'other' => q(Boliviano za Bolivia),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real ya Brazil),
				'one' => q(Real ya Brazil),
				'other' => q(Real za Brazil),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dola ya Bahamas),
				'one' => q(Dola ya Bahamas),
				'other' => q(Dola za Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum ya Bhutan),
				'one' => q(Ngultrum ya Bhutan),
				'other' => q(Ngultrum za Bhutan),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula ya Botswana),
				'one' => q(pula ya Botswana),
				'other' => q(pula za Botswana),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Ruble ya Belarusi),
				'one' => q(Ruble ya Belarusi),
				'other' => q(Ruble za Belarusi),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dola ya Belize),
				'one' => q(Dola ya Belize),
				'other' => q(Dola za Belize),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dola ya Kanada),
				'one' => q(dola ya Kanada),
				'other' => q(dola za Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Faranga ya Kongo),
				'one' => q(faranga ya Kongo),
				'other' => q(faranga za Kongo),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Faranga ya Uswisi),
				'one' => q(faranga ya Uswisi),
				'other' => q(faranga za Uswisi),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso ya Chile),
				'one' => q(Peso ya Chile),
				'other' => q(Peso za Chile),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan ya Uchina),
				'one' => q(yuan ya Uchina),
				'other' => q(yuan za Uchina),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso ya Kolombia),
				'one' => q(Peso ya Kolombia),
				'other' => q(Peso za Kolombia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colon ya Kostarika),
				'one' => q(Colon ya Kostarika),
				'other' => q(Colon za Kostarika),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso ya Cuba Inayoweza Kubadilishwa),
				'one' => q(Peso ya Cuba Inayoweza Kubadilishwa),
				'other' => q(Peso za Cuba Zinazoweza Kubadilishwa),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso ya Cuba),
				'one' => q(Peso ya Cuba),
				'other' => q(Peso za Cuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Eskudo ya Cape Verde),
				'one' => q(Eskudo ya Cape Verde),
				'other' => q(Eskudo za Cape Verde),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Koruna ya Jamhuri ya Cheki),
				'one' => q(Koruna ya Jamhuri ya Cheki),
				'other' => q(Koruna za Jamhuri ya Cheki),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Faranga ya Jibuti),
				'one' => q(faranga ya Jibuti),
				'other' => q(faranga za Jibuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Krone ya Denmaki),
				'one' => q(Krone ya Denmaki),
				'other' => q(Krone za Denmaki),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso ya Dominika),
				'one' => q(Peso ya Dominika),
				'other' => q(Peso za Dominika),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinari ya Aljeria),
				'one' => q(dinari ya Aljeria),
				'other' => q(dinari za Aljeria),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Pauni ya Misri),
				'one' => q(pauni ya Misri),
				'other' => q(pauni za Misri),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa ya Eritrea),
				'one' => q(nakfa ya Eritrea),
				'other' => q(nakfa za Eritrea),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr ya Uhabeshi),
				'one' => q(birr ya Uhabeshi),
				'other' => q(birr za Uhabeshi),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Yuro),
				'one' => q(yuro),
				'other' => q(yuro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dola ya Fiji),
				'one' => q(Dola ya Fiji),
				'other' => q(Dola za Fiji),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Pauni ya Visiwa vya Falkland),
				'one' => q(Pauni ya Visiwa vya Falkland),
				'other' => q(Pauni za Visiwa vya Falkland),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Pauni ya Uingereza),
				'one' => q(pauni ya Uingereza),
				'other' => q(pauni za Uingereza),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari ya Georgia),
				'one' => q(Lari ya Georgia),
				'other' => q(Lari za Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Ghana),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi ya Ghana),
				'one' => q(Cedi ya Ghana),
				'other' => q(Cedi za Ghana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Pauni ya Gibraltar),
				'one' => q(Pauni ya Gibraltar),
				'other' => q(Pauni za Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi ya Gambia),
				'one' => q(dalasi ya Gambia),
				'other' => q(dalasi za Gambia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Faranga ya Guinea),
				'one' => q(faranga ya Guinea),
				'other' => q(faranga za Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Gine),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal ya Guatemala),
				'one' => q(Quetzal ya Guatemala),
				'other' => q(Quetzal za Guatemala),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dola ya Guyana),
				'one' => q(Dola ya Guyana),
				'other' => q(Dola za Guyana),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dola ya Hong Kong),
				'one' => q(Dola ya Hong Kong),
				'other' => q(Dola za Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira ya Hondurasi),
				'one' => q(Lempira ya Hondurasi),
				'other' => q(Lempira za Hondurasi),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna ya Kroeshia),
				'one' => q(Kuna ya Kroeshia),
				'other' => q(Kuna za Kroeshia),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde ya Haiti),
				'one' => q(Gourde ya Haiti),
				'other' => q(Gourde za Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forint ya Hungaria),
				'one' => q(Forint ya Hungaria),
				'other' => q(Forint za Hungaria),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupiah ya Indonesia),
				'one' => q(Rupiah ya Indonesia),
				'other' => q(Rupiah za Indonesia),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Sheqel Mpya ya Israeli),
				'one' => q(Sheqel Mpya ya Israeli),
				'other' => q(Sheqel Mpya za Israeli),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia ya India),
				'one' => q(rupia ya India),
				'other' => q(rupia za India),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar ya Iraki),
				'one' => q(Dinar ya Iraki),
				'other' => q(Dinar za Iraki),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial ya Iran),
				'one' => q(Rial ya Iran),
				'other' => q(Rial za Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Krona ya Aisilandi),
				'one' => q(Krona ya Aisilandi),
				'other' => q(Krona za Aisilandi),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dola ya Jamaica),
				'one' => q(Dola ya Jamaica),
				'other' => q(Dola za Jamaica),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar ya Yordani),
				'one' => q(Dinar ya Yordani),
				'other' => q(Dinar za Yordani),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen ya Japani),
				'one' => q(Yen ya Japani),
				'other' => q(Yen za Japani),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Shilingi ya Kenya),
				'one' => q(shilingi ya Kenya),
				'other' => q(shilingi za Kenya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som ya Kyrgystani),
				'one' => q(Som ya Kyrgystani),
				'other' => q(Som za Kyrgystani),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel ya Kambodia),
				'one' => q(Riel ya Kambodia),
				'other' => q(Riel za Kambodia),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Faranga ya Komoro),
				'one' => q(faranga ya Komoro),
				'other' => q(faranga za Komoro),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won ya Korea Kaskazini),
				'one' => q(Won ya Korea Kaskazini),
				'other' => q(Won za Korea Kaskazini),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won ya Korea Kusini),
				'one' => q(Won ya Korea Kusini),
				'other' => q(Won za Korea Kusini),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar ya Kuwaiti),
				'one' => q(Dinar ya Kuwaiti),
				'other' => q(Dinar za Kuwaiti),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dola ya Visiwa vya Cayman),
				'one' => q(Dola ya Visiwa vya Cayman),
				'other' => q(Dola ya Visiwa vya Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge ya Kazakistani),
				'one' => q(Tenge ya Kazakistani),
				'other' => q(Tenge za Kazakistani),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip ya Laosi),
				'one' => q(Kip ya Laosi),
				'other' => q(Kip za Laosi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Pauni ya Lebanon),
				'one' => q(Pauni ya Lebanon),
				'other' => q(Pauni za Lebanon),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia ya Sri Lanka),
				'one' => q(Rupia ya Sri Lanka),
				'other' => q(Rupia za Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dola ya Liberia),
				'one' => q(dola ya Liberia),
				'other' => q(dola za Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoto),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas ya Lithuania),
				'one' => q(Litas ya Lithuania),
				'other' => q(Litas za Lithuania),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats ya Lativia),
				'one' => q(Lats ya Lativia),
				'other' => q(Lats za Lativia),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinari ya Libya),
				'one' => q(dinari ya Libya),
				'other' => q(dinari za Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirham ya Moroko),
				'one' => q(dirham ya Moroko),
				'other' => q(dirham za Moroko),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu ya Moldova),
				'one' => q(Leu ya Moldova),
				'other' => q(Leu za Moldova),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariari ya Madagaska),
				'one' => q(Ariari ya Madagaska),
				'other' => q(Ariari za Madagaska),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar ya Masedonia),
				'one' => q(Denar ya Masedonia),
				'other' => q(Denar za Masedonia),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat ya Myama),
				'one' => q(Kyat ya Myama),
				'other' => q(Kyat za Myama),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik ya Mongolia),
				'one' => q(Tugrik ya Mongolia),
				'other' => q(Tugrik za Mongolia),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca ya Macau),
				'one' => q(Pataca ya Macau),
				'other' => q(Pataca za Macau),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ouguiya ya Moritania),
				'one' => q(Ouguiya ya Moritania),
				'other' => q(Ouguiya za Moritania),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia ya Morisi),
				'one' => q(rupia ya Morisi),
				'other' => q(rupia za Morisi),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa ya Maldivi),
				'one' => q(Rufiyaa ya Maldivi),
				'other' => q(Rufiyaa za Maldivi),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha ya Malawi),
				'one' => q(kwacha ya Malawi),
				'other' => q(kwacha za Malawi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Peso ya Meksiko),
				'one' => q(Peso ya Meksiko),
				'other' => q(Peso za Meksiko),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringgit ya Malaysia),
				'one' => q(Ringgit ya Malaysia),
				'other' => q(Ringgit za Malaysia),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali ya Msumbiji \(1980–2006\)),
				'one' => q(metikali ya Msumbiji \(1980–2006\)),
				'other' => q(metikali ya Msumbiji \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metikali ya Msumbiji),
				'one' => q(Metikali ya Msumbiji),
				'other' => q(Metikali za Msumbiji),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dola ya Namibia),
				'one' => q(dola ya Namibia),
				'other' => q(dola za Namibia),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira ya Nijeria),
				'one' => q(naira ya Nijeria),
				'other' => q(naira za Nijeria),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Cordoba ya Nikaragua),
				'one' => q(Cordoba ya Nikaragua),
				'other' => q(Cordoba za Nikaragua),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Krone ya Norwe),
				'one' => q(Krone ya Norwe),
				'other' => q(Krone za Norwe),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia ya Nepali),
				'one' => q(Rupia ya Nepali),
				'other' => q(Rupia za Nepali),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dola ya Nyuzilandi),
				'one' => q(Dola ya Nyuzilandi),
				'other' => q(Dola za Nyuzilandi),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial ya Omani),
				'one' => q(Rial ya Omani),
				'other' => q(Rial za Omani),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa ya Panama),
				'one' => q(Balboa ya Panama),
				'other' => q(Balboa za Panama),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Nuevo Sol ya Peru),
				'one' => q(Nuevo Sol ya Peru),
				'other' => q(Nuevo Sol za Peru),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina ya Papua New Guinea),
				'one' => q(Kina ya Papua New Guinea),
				'other' => q(Kina za Papua New Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso ya Ufilipino),
				'one' => q(Peso ya Ufilipino),
				'other' => q(Peso za Ufilipino),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia ya Pakistani),
				'one' => q(Rupia ya Pakistani),
				'other' => q(Rupia za Pakistani),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty ya Polandi),
				'one' => q(Zloty ya Polandi),
				'other' => q(Zloty za Polandi),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani ya Paragwai),
				'one' => q(Guarani ya Paragwai),
				'other' => q(Guarani za Paragwai),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial ya Qatari),
				'one' => q(Rial ya Qatari),
				'other' => q(Rial za Qatari),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu ya Romania),
				'one' => q(Leu ya Romania),
				'other' => q(Leu za Romania),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar ya Serbia),
				'one' => q(Dinar ya Serbia),
				'other' => q(Dinar za Serbia),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Ruble ya Urusi),
				'one' => q(Ruble ya Urusi),
				'other' => q(Ruble za Urusi),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Faranga ya Rwanda),
				'one' => q(faranga ya Rwanda),
				'other' => q(faranga za Rwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal ya Saudia),
				'one' => q(riyal ya Saudia),
				'other' => q(riyal za Saudia),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dola ya Visiwa vya Solomon),
				'one' => q(Dola ya Visiwa vya Solomon),
				'other' => q(Dola za Visiwa vya Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia ya Ushelisheli),
				'one' => q(rupia ya Ushelisheli),
				'other' => q(rupia za Ushelisheli),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Pauni ya Sudani),
				'one' => q(pauni ya Sudani),
				'other' => q(pauni za Sudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pauni ya Sudani \(1957–1998\)),
				'one' => q(pauni ya Sudani \(1957–1998\)),
				'other' => q(pauni za Sudani \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Krona ya Uswidi),
				'one' => q(Krona ya Uswidi),
				'other' => q(Krona za Uswidi),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dola ya Singapore),
				'one' => q(Dola ya Singapore),
				'other' => q(Dola za Singapore),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Pauni ya Santahelena),
				'one' => q(pauni ya Santahelena),
				'other' => q(pauni za Santahelena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone),
				'one' => q(Leone),
				'other' => q(Leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Shilingi ya Somalia),
				'one' => q(shilingi ya Somalia),
				'other' => q(shilingi za Somalia),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dola ya Suriname),
				'one' => q(Dola ya Suriname),
				'other' => q(Dola za Suriname),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Pauni ya Sudani Kusini),
				'one' => q(pauni ya Sudani Kusini),
				'other' => q(pauni za Sudani Kusini),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe),
				'one' => q(dobra ya Sao Tome na Principe),
				'other' => q(dobra za Sao Tome na Principe),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Pauni ya Syria),
				'one' => q(Pauni ya Syria),
				'other' => q(Pauni za Syria),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni),
				'one' => q(lilangeni),
				'other' => q(lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht ya Tailandi),
				'one' => q(Baht ya Tailandi),
				'other' => q(Baht za Tailandi),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni ya Tajikistani),
				'one' => q(Somoni ya Tajikistani),
				'other' => q(Somoni za Tajikistani),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat ya Turukimenistani),
				'one' => q(Manat ya Turukimenistani),
				'other' => q(Manat za Turukimenistani),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinari ya Tunisia),
				'one' => q(dinari ya Tunisia),
				'other' => q(dinari za Tunisia),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga ya Tonga),
				'one' => q(Paʻanga ya Tonga),
				'other' => q(Paʻanga za Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira ya Uturuki),
				'one' => q(Lira ya Uturuki),
				'other' => q(Lira za Uturuki),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dola ya Trinidad na Tobago),
				'one' => q(Dola ya Trinidad na Tobago),
				'other' => q(Dola za Trinidad na Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dola ya Taiwan),
				'one' => q(Dola ya Taiwan),
				'other' => q(Dola za Taiwan),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Shilingi ya Tanzania),
				'one' => q(shilingi ya Tanzania),
				'other' => q(shilingi za Tanzania),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hryvnia ya Ukrania),
				'one' => q(Hryvnia ya Ukrania),
				'other' => q(Hryvnia za Ukrania),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilingi ya Uganda),
				'one' => q(shilingi ya Uganda),
				'other' => q(shilingi za Uganda),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dola ya Marekani),
				'one' => q(dola ya Marekani),
				'other' => q(dola za Marekani),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso ya Urugwai),
				'one' => q(Peso ya Urugwai),
				'other' => q(Peso za Urugwai),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som ya Uzibekistani),
				'one' => q(Som ya Uzibekistani),
				'other' => q(Som za Uzibekistani),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolivar ya Venezuela),
				'one' => q(Bolivar ya Venezuela),
				'other' => q(Bolivar za Venezuela),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong ya Vietnam),
				'one' => q(Dong ya Vietnam),
				'other' => q(Dong za Vietnam),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu ya Vanuatu),
				'one' => q(Vatu ya Vanuatu),
				'other' => q(Vatu za Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala ya Samoa),
				'one' => q(Tala ya Samoa),
				'other' => q(Tala za Samoa),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA faranga ya BEAC),
				'one' => q(CFA faranga ya BEAC),
				'other' => q(CFA faranga za BEAC),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dola ya Karibea ya Mashariki),
				'one' => q(Dola ya Karibea ya Mashariki),
				'other' => q(Dola za Karibea ya Mashariki),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA faranga za BCEAO),
				'one' => q(CFA faranga za BCEAO),
				'other' => q(CFA faranga za BCEAO),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Faranga ya CFP),
				'one' => q(Faranga ya CFP),
				'other' => q(Faranga za CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Sarafu isiyojulikana),
				'one' => q(sarafu isiyojulikana),
				'other' => q(sarafu zisizojulikana),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial ya Yemeni),
				'one' => q(Rial ya Yemeni),
				'other' => q(Rial za Yemeni),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Randi ya Afrika Kusini),
				'one' => q(randi ya Afrika Kusini),
				'other' => q(randi za Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha ya Zambia),
				'one' => q(kwacha ya Zambia),
				'other' => q(kwacha za Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola ya Zimbabwe),
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
							'Jan',
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ago',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
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
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Machi',
							'Aprili',
							'Mei',
							'Juni',
							'Julai',
							'Agosti',
							'Septemba',
							'Oktoba',
							'Novemba',
							'Desemba'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ago',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
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
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Machi',
							'Aprili',
							'Mei',
							'Juni',
							'Julai',
							'Agosti',
							'Septemba',
							'Oktoba',
							'Novemba',
							'Desemba'
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
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
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
					abbreviated => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
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
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
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
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'am' => q{AM},
					'pm' => q{PM},
					'morning2' => q{asubuhi},
					'noon' => q{saa sita za mchana},
					'night1' => q{usiku},
					'morning1' => q{alfajiri},
					'midnight' => q{saa sita za usiku},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
					'evening1' => q{jioni},
					'afternoon1' => q{mchana},
					'morning2' => q{asubuhi},
					'midnight' => q{saa sita za usiku},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'morning1' => q{alfajiri},
				},
				'wide' => {
					'evening1' => q{jioni},
					'afternoon1' => q{mchana},
					'pm' => q{PM},
					'am' => q{AM},
					'midnight' => q{saa sita za usiku},
					'noon' => q{saa sita za mchana},
					'night1' => q{usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'noon' => q{saa sita za mchana},
					'night1' => q{usiku},
					'morning1' => q{alfajiri},
					'midnight' => q{saa sita za usiku},
					'morning2' => q{asubuhi},
					'pm' => q{PM},
					'am' => q{AM},
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
				},
				'narrow' => {
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'morning1' => q{alfajiri},
					'noon' => q{saa sita za mchana},
					'midnight' => q{saa sita za usiku},
					'am' => q{am},
					'pm' => q{pm},
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
				},
				'wide' => {
					'noon' => q{saa sita za mchana},
					'night1' => q{usiku},
					'morning1' => q{alfajiri},
					'midnight' => q{saa sita za usiku},
					'morning2' => q{asubuhi},
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'pm' => q{PM},
					'am' => q{AM},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Kabla ya Kristo',
				'1' => 'Baada ya Kristo'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			hm => q{h:mm a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
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
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{y QQQ},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
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
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
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
				h => q{h:mm–h:mm a},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d– E, MMM d y},
				d => q{E, MMM d – E, MMM d y},
				y => q{E, MMM d y – E, MMM d y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – d, y},
				d => q{MMM d – d, y},
				y => q{MMM d y – MMM d y},
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
		gmtFormat => q(GMT {0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Saa za {0}),
		regionFormat => q(Saa za Mchana za {0}),
		regionFormat => q(Saa za wastani za {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q(Saa za Afghanistani),
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
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
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
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
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
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
			exemplarCity => q#Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(Saa za Afrika ya Kati),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(Saa za Afrika Mashariki),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(Saa Wastani za Afrika Kusini),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Afrika Magharibi),
				'generic' => q(Saa za Afrika Magharibi),
				'standard' => q(Saa Wastani za Afrika Magharibi),
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q(Saa za Mchana za Alaska),
				'generic' => q(Saa za Alaska),
				'standard' => q(Saa za Wastani za Alaska),
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Amazon),
				'generic' => q(Saa za Amazon),
				'standard' => q(Saa Wastani za Amazon),
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
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
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
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
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
			exemplarCity => q#Bogota#,
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
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
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
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurakao#,
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
			exemplarCity => q#El Salvador#,
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
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
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
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
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
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
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
			exemplarCity => q#Jiji la Meksiko#,
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
			exemplarCity => q#New York#,
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
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
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
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
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
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
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
			exemplarCity => q#Rio Branco#,
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
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
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
				'daylight' => q(Saa za Mchana za Kati),
				'generic' => q(Saa za Kati),
				'standard' => q(Saa za Wastani za Kati),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(Saa za Mchana za Mashariki),
				'generic' => q(Saa za Mashariki),
				'standard' => q(Saa za Wastani za Mashariki),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(Saa za Mchana za Mountain),
				'generic' => q(Saa za Mountain),
				'standard' => q(Saa za Wastani za Mountain),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(Saa za Mchana za Pasifiki),
				'generic' => q(Saa za Pasifiki),
				'standard' => q(Saa za Wastani za Pasifiki),
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q(Saa za Kiangazi za Anadyr),
				'generic' => q(Saa za Anadyr),
				'standard' => q(Saa za Wastani za Anadyr),
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
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
				'daylight' => q(Saa za Mchana za Apia),
				'generic' => q(Saa za Apia),
				'standard' => q(Saa Wastani za Apia),
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q(Saa za Mchana za Arabiani),
				'generic' => q(Saa za Uarabuni),
				'standard' => q(Saa Wastani za Uarabuni),
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Ajentina),
				'generic' => q(Saa za Ajentina),
				'standard' => q(Saa Wastani za Ajentina),
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Magharibi mwa Ajentina),
				'generic' => q(Saa za Magharibi mwa Ajentina),
				'standard' => q(Saa Wastani za Magharibi mwa Ajentina),
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Armenia),
				'generic' => q(Saa za Armenia),
				'standard' => q(Saa Wastani za Armenia),
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
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
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
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
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascus#,
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
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
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
			exemplarCity => q#Muscat#,
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
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapore#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
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
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
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
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q(Saa za Mchana za Atlantiki),
				'generic' => q(Saa za Atlantiki),
				'standard' => q(Saa za Wastani za Atlantiki),
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#South Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
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
			exemplarCity => q#Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q(Saa za Mchana za Australia ya Kati),
				'generic' => q(Saa za Australia ya Kati),
				'standard' => q(Saa Wastani za Australia ya Kati),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(Saa za Mchana za Magharibi ya Kati ya Australia),
				'generic' => q(Saa za Magharibi ya Kati ya Australia),
				'standard' => q(Saa Wastani za Magharibi ya Kati ya Australia),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(Saa za Mchana za Mashariki mwa Australia),
				'generic' => q(Saa za Australia Mashariki),
				'standard' => q(Saa Wastani za Mashariki mwa Australia),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(Saa za Mchana za Australia Magharibi),
				'generic' => q(Saa za Australia Magharibi),
				'standard' => q(Saa Wastani za Australia Magharibi),
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Azeribaijani),
				'generic' => q(Saa za Azeribaijani),
				'standard' => q(Saa Wastani za Azeribaijani),
			},
		},
		'Azores' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Azores),
				'generic' => q(Saa za Azores),
				'standard' => q(Saa Wastani za Azores),
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Bangladeshi),
				'generic' => q(Saa za Bangladeshi),
				'standard' => q(Saa Wastani za Bangladeshi),
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q(Saa za Bhutan),
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q(Saa za Bolivia),
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Brasilia),
				'generic' => q(Saa za Brasilia),
				'standard' => q(Saa Wastani za Brasilia),
			},
		},
		'Brunei' => {
			long => {
				'standard' => q(Saa za Brunei Darussalam),
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Cape Verde),
				'generic' => q(Saa za Cape Verde),
				'standard' => q(Saa Wastani za Cape Verde),
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q(Saa Wastani za Chamorro),
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q(Saa za Mchana za Chatham),
				'generic' => q(Saa za Chatham),
				'standard' => q(Saa Wastani za Chatham),
			},
		},
		'Chile' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Chile),
				'generic' => q(Saa za Chile),
				'standard' => q(Saa Wastani za Chile),
			},
		},
		'China' => {
			long => {
				'daylight' => q(Saa za Mchana za Uchina),
				'generic' => q(Saa za Uchina),
				'standard' => q(Saa Wastani za Uchina),
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Choibalsan),
				'generic' => q(Saa za Choibalsan),
				'standard' => q(Saa Wastani za Choibalsan),
			},
		},
		'Christmas' => {
			long => {
				'standard' => q(Saa za Kisiwa cha Krisimasi),
			},
		},
		'Cocos' => {
			long => {
				'standard' => q(Saa za Visiwa vya Cocos),
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Kolombia),
				'generic' => q(Saa za Kolombia),
				'standard' => q(Saa Wastani za Kolombia),
			},
		},
		'Cook' => {
			long => {
				'daylight' => q(Saa za Majira nusu ya joto za Visiwa Cook),
				'generic' => q(Saa za Visiwa vya Cook),
				'standard' => q(Saa Wastani za Visiwa vya Cook),
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q(Saa za Mchana za Cuba),
				'generic' => q(Saa za Cuba),
				'standard' => q(Saa za Wastani ya Cuba),
			},
		},
		'Davis' => {
			long => {
				'standard' => q(Saa za Davis),
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q(Saa za Dumont-d’Urville),
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q(Saa za Timor Mashariki),
			},
		},
		'Easter' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Kisiwa cha Pasaka),
				'generic' => q(Saa za Kisiwa cha Pasaka),
				'standard' => q(Saa Wastani za Kisiwa cha Pasaka),
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q(Saa za Ekwado),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Jiji Lisilojulikana#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
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
			exemplarCity => q#Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q(Muda wa Majira ya Joto wa Ayalandi),
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
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
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
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q(Muda wa Majira ya Joto wa Uingereza),
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembourg#,
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
			exemplarCity => q#Moscow#,
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
			exemplarCity => q#Prague#,
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
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
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
			exemplarCity => q#Warsaw#,
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
				'daylight' => q(Saa za Majira ya joto za Ulaya ya Kati),
				'generic' => q(Saa za Ulaya ya Kati),
				'standard' => q(Saa Wastani za Ulaya ya kati),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Mashariki mwa Ulaya),
				'generic' => q(Saa za Mashariki mwa Ulaya),
				'standard' => q(Saa Wastani za Mashariki mwa Ulaya),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(Saa za Further-eastern European Time),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Magharibi mwa Ulaya),
				'generic' => q(Saa za Magharibi mwa Ulaya),
				'standard' => q(Saa Wastani za Magharibi mwa Ulaya),
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Visiwa vya Falkland),
				'generic' => q(Saa za Visiwa vya Falkland),
				'standard' => q(Saa Wastani za Visiwa vya Falkland),
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Fiji),
				'generic' => q(Saa za Fiji),
				'standard' => q(Saa Wastani za Fiji),
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q(Saa za Guiana ya Ufaransa),
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q(Saa za Kusini mwa Ufaransa na Antaktiki),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(Saa za Greenwich),
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q(Saa za Galapagos),
			},
		},
		'Gambier' => {
			long => {
				'standard' => q(Saa za Gambier),
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Jojia),
				'generic' => q(Saa za Jojia),
				'standard' => q(Saa Wastani za Jojia),
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q(Saa za Visiwa vya Gilbert),
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Greenland Mashariki),
				'generic' => q(Saa za Greenland Mashariki),
				'standard' => q(Saa za Wastani za Greenland Mashariki),
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Greenland Magharibi),
				'generic' => q(Saa za Greenland Magharibi),
				'standard' => q(Saa za Wastani za Greenland Magharibi),
			},
		},
		'Gulf' => {
			long => {
				'standard' => q(Saa Wastani za Gulf),
			},
		},
		'Guyana' => {
			long => {
				'standard' => q(Saa za Guyana),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(Saa za Mchana za Hawaii-Aleutian),
				'generic' => q(Saa za Hawaii-Aleutian),
				'standard' => q(Saa za Wastani za Hawaii-Aleutian),
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Hong Kong),
				'generic' => q(Saa za Hong Kong),
				'standard' => q(Saa Wastani za Hong Kong),
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Hovd),
				'generic' => q(Saa za Hovd),
				'standard' => q(Saa Wastani za Hovd),
			},
		},
		'India' => {
			long => {
				'standard' => q(Saa Wastani za India),
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krismasi#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q(Saa za Bahari Hindi),
			},
		},
		'Indochina' => {
			long => {
				'standard' => q(Saa za Indochina),
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q(Saa za Indonesia ya Kati),
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q(Saa za Mashariki mwa Indonesia),
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q(Saa za Magharibi mwa Indonesia),
			},
		},
		'Iran' => {
			long => {
				'daylight' => q(Saa za Mchana za Iran),
				'generic' => q(Saa za Iran),
				'standard' => q(Saa Wastani za Iran),
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Irkutsk),
				'generic' => q(Saa za Irkutsk),
				'standard' => q(Saa Wastani za Irkutsk),
			},
		},
		'Israel' => {
			long => {
				'daylight' => q(Saa za Mchana za Israeli),
				'generic' => q(Saa za Israeli),
				'standard' => q(Saa Wastani za Israeli),
			},
		},
		'Japan' => {
			long => {
				'daylight' => q(Saa za Mchana za Japani),
				'generic' => q(Saa za Japani),
				'standard' => q(Saa Wastani za Japani),
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q(Saa za Kiangazi za Petropavlovsk-Kamchatski),
				'generic' => q(Saa za Petropavlovsk-Kamchatski),
				'standard' => q(Saa za Wastani za Petropavlovsk-Kamchatski),
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q(Saa za Kazakistani Mashariki),
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q(Saa za Kazakistani Magharibi),
			},
		},
		'Korea' => {
			long => {
				'daylight' => q(Saa za Mchana za Korea),
				'generic' => q(Saa za Korea),
				'standard' => q(Saa Wastani za Korea),
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q(Saa za Kosrae),
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Krasnoyarsk),
				'generic' => q(Saa za Krasnoyarsk),
				'standard' => q(Saa Wastani za Krasnoyaski),
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q(Saa za Kyrgystan),
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q(Saa za Visiwa vya Line),
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q(Saa za Mchana za Lord Howe),
				'generic' => q(Saa za Lord Howe),
				'standard' => q(Saa Wastani za Lord Howe),
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q(Saa za kisiwa cha Macquarie),
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Magadan),
				'generic' => q(Saa za Magadan),
				'standard' => q(Saa Wastani za Magadani),
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q(Saa za Malaysia),
			},
		},
		'Maldives' => {
			long => {
				'standard' => q(Saa za Maldives),
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q(Saa za Marquesas),
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q(Saa za Visiwa vya Marshall),
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Mauritius),
				'generic' => q(Saa za Mauritius),
				'standard' => q(Saa Wastani za Mauritius),
			},
		},
		'Mawson' => {
			long => {
				'standard' => q(Saa za Mawson),
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q(Saa za mchana za Meksiko Kaskazini Magharibi),
				'generic' => q(Saa za Meksiko Kaskazini Magharibi),
				'standard' => q(Saa za wastani za Meksiko Kaskazini Magharibi),
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q(Saa za mchana za pasifiki za Meksiko),
				'generic' => q(Saa za pasifiki za Meksiko),
				'standard' => q(Saa za wastani za pasifiki za Meksiko),
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Ulan Bator),
				'generic' => q(Saa za Ulan Bator),
				'standard' => q(Saa Wastani za Ulan Bator),
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Moscow),
				'generic' => q(Saa za Moscow),
				'standard' => q(Saa za Wastani za Moscow),
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q(Saa za Myanmar),
			},
		},
		'Nauru' => {
			long => {
				'standard' => q(Saa za Nauru),
			},
		},
		'Nepal' => {
			long => {
				'standard' => q(Saa za Nepali),
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za New Caledonia),
				'generic' => q(Saa za New Caledonia),
				'standard' => q(Saa Wastani za New Caledonia),
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q(Saa za Mchana za Nyuzilandi),
				'generic' => q(Saa za Nyuzilandi),
				'standard' => q(Saa Wastani za Nyuzilandi),
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q(Saa za Mchana za Newfoundland),
				'generic' => q(Saa za Newfoundland),
				'standard' => q(Saa za Wastani za Newfoundland),
			},
		},
		'Niue' => {
			long => {
				'standard' => q(Saa za Niue),
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q(Saa za Kisiwa cha Norfolk),
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Fernando de Noronha),
				'generic' => q(Saa za Fernando de Noronha),
				'standard' => q(Saa Wastani za Fernando de Noronha),
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Novosibirsk),
				'generic' => q(Saa za Novosibirsk),
				'standard' => q(Saa Wastani za Novosibirsk),
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Omsk),
				'generic' => q(Saa za Omsk),
				'standard' => q(Saa Wastani za Omsk),
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
			exemplarCity => q#Easter#,
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
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
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
			exemplarCity => q#Honolulu#,
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
			exemplarCity => q#Tahiti#,
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
				'daylight' => q(Saa za Majira ya joto za Pakistani),
				'generic' => q(Saa za Pakistani),
				'standard' => q(Saa Wastani za Pakistani),
			},
		},
		'Palau' => {
			long => {
				'standard' => q(Saa za Palau),
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q(Saa za Papua New Guinea),
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Paragwai),
				'generic' => q(Saa za Paragwai),
				'standard' => q(Saa Wastani za Paragwai),
			},
		},
		'Peru' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Peru),
				'generic' => q(Saa za Peru),
				'standard' => q(Saa Wastani za Peru),
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Ufilipino),
				'generic' => q(Saa za Ufilipino),
				'standard' => q(Saa Wastani za Ufilipino),
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q(Saa za Visiwa vya Phoenix),
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q(Saa za Mchana za Saint-Pierre na Miquelon),
				'generic' => q(Saa za Saint-Pierre na Miquelon),
				'standard' => q(Saa za Wastani ya Saint-Pierre na Miquelon),
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q(Saa za Pitcairn),
			},
		},
		'Ponape' => {
			long => {
				'standard' => q(Saa za Ponape),
			},
		},
		'Reunion' => {
			long => {
				'standard' => q(Saa za Reunion),
			},
		},
		'Rothera' => {
			long => {
				'standard' => q(Saa za Rothera),
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Sakhalin),
				'generic' => q(Saa za Sakhalin),
				'standard' => q(Saa Wastani za Sakhalin),
			},
		},
		'Samara' => {
			long => {
				'daylight' => q(Saa za Kiangazi za Samara),
				'generic' => q(Saa za Samara),
				'standard' => q(Saa za Wastani za Samara),
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Samoa),
				'generic' => q(Saa za Samoa),
				'standard' => q(Saa Wastani za Samoa),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(Saa za Ushelisheli),
			},
		},
		'Singapore' => {
			long => {
				'standard' => q(Saa Wastani za Singapore),
			},
		},
		'Solomon' => {
			long => {
				'standard' => q(Saa za Visiwa vya Suleimani),
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q(Saa za Jojia Kusini),
			},
		},
		'Suriname' => {
			long => {
				'standard' => q(Saa za Suriname),
			},
		},
		'Syowa' => {
			long => {
				'standard' => q(Saa za Syowa),
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q(Saa za Tahiti),
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q(Saa za Mchana za Taipei),
				'generic' => q(Saa za Taipei),
				'standard' => q(Saa Wastani za Taipei),
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q(Saa za Tajikistani),
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q(Saa za Tokelau),
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Tonga),
				'generic' => q(Saa za Tonga),
				'standard' => q(Saa Wastani za Tonga),
			},
		},
		'Truk' => {
			long => {
				'standard' => q(Saa za Chuuk),
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Turkmenistan),
				'generic' => q(Saa za Turkmenistan),
				'standard' => q(Saa Wastani za Turkmenistan),
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q(Saa za Tuvalu),
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Urugwai),
				'generic' => q(Saa za Urugwai),
				'standard' => q(Saa Wastani za Urugwai),
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Uzbekistani),
				'generic' => q(Saa za Uzbekistani),
				'standard' => q(Saa Wastani za Uzbekistani),
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Vanuatu),
				'generic' => q(Saa za Vanuatu),
				'standard' => q(Saa Wastani za Vanuatu),
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q(Saa za Venezuela),
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Vladivostok),
				'generic' => q(Saa za Vladivostok),
				'standard' => q(Saa Wastani za Vladivostok),
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Volgograd),
				'generic' => q(Saa za Volgograd),
				'standard' => q(Saa Wastani za Volgograd),
			},
		},
		'Vostok' => {
			long => {
				'standard' => q(Saa za Vostok),
			},
		},
		'Wake' => {
			long => {
				'standard' => q(Saa za Kisiwa cha Wake),
			},
		},
		'Wallis' => {
			long => {
				'standard' => q(Saa za Wallis na Futuna),
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Yakutsk),
				'generic' => q(Saa za Yakutsk),
				'standard' => q(Saa Wastani za Yakutsk),
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q(Saa za Majira ya joto za Yekaterinburg),
				'generic' => q(Saa za Yekaterinburg),
				'standard' => q(Saa Wastani za Yekaterinburg),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
