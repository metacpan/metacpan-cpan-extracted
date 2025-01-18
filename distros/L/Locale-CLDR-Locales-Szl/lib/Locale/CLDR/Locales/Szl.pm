=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Szl - Package for language Silesian

=cut

package Locale::CLDR::Locales::Szl;
# This file auto generated from Data\common\main\szl.xml
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
				'af' => 'afrikaans',
 				'agq' => 'aghym',
 				'ak' => 'akan',
 				'am' => 'amharski',
 				'ar' => 'arabski',
 				'as' => 'asamski',
 				'asa' => 'asu',
 				'ast' => 'asturyjski',
 				'az' => 'azerbejdżański',
 				'az@alt=short' => 'azerski',
 				'bas' => 'basaa',
 				'be' => 'biołoruski',
 				'bem' => 'bymba',
 				'bez' => 'byna',
 				'bg' => 'bułgarski',
 				'bm' => 'bambara',
 				'bn' => 'byngalski',
 				'bo' => 'tybetański',
 				'br' => 'bretōński',
 				'brx' => 'bodo',
 				'bs' => 'bośniacki',
 				'ca' => 'katalōński',
 				'ccp' => 'czakma',
 				'ce' => 'czeczyński',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'chr' => 'czirokeski',
 				'ckb' => 'sorani',
 				'co' => 'korsykański',
 				'cs' => 'czeski',
 				'cu' => 'cerkiewnosłowiański',
 				'cy' => 'walijski',
 				'da' => 'duński',
 				'dav' => 'taita',
 				'de' => 'niymiecki',
 				'de_AT' => 'austriacki niymiecki',
 				'de_CH' => 'szwajcarski wysokoniymiecki',
 				'dje' => 'dżerma',
 				'dsb' => 'dolnołużycki',
 				'dua' => 'duala',
 				'dyo' => 'diola',
 				'dz' => 'dzongkha',
 				'ebu' => 'ymbu',
 				'ee' => 'ewe',
 				'el' => 'grecki',
 				'en' => 'angelski',
 				'en_AU' => 'australijski angelski',
 				'en_CA' => 'kanadyjski angelski',
 				'en_GB' => 'brytyjski angelski',
 				'en_GB@alt=short' => 'angelski (Wlk. Bryt.)',
 				'en_US' => 'amerykański angelski',
 				'en_US@alt=short' => 'angelski (USA)',
 				'eo' => 'esperanto',
 				'es' => 'hiszpański',
 				'es_419' => 'amerykański hiszpański',
 				'es_ES' => 'europejski hiszpański',
 				'es_MX' => 'meksykański hiszpański',
 				'et' => 'estōński',
 				'eu' => 'baskijski',
 				'ewo' => 'ewōndo',
 				'fa' => 'perski',
 				'ff' => 'fulani',
 				'fi' => 'fiński',
 				'fil' => 'filipino',
 				'fo' => 'farerski',
 				'fr' => 'francuski',
 				'fr_CA' => 'kanadyjski francuski',
 				'fr_CH' => 'szwajcarski francuski',
 				'frc' => 'cajuński',
 				'fur' => 'friulski',
 				'fy' => 'zachodniofryzyjski',
 				'ga' => 'irlandzki',
 				'gd' => 'szkocki gaelicki',
 				'gl' => 'galicyjski',
 				'gsw' => 'szwajcarski niymiecki',
 				'gu' => 'gudżarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'ha' => 'hausa',
 				'haw' => 'hawajski',
 				'he' => 'hebrajski',
 				'hi' => 'hindi',
 				'hmn' => 'hmōng',
 				'hr' => 'chorwacki',
 				'hsb' => 'gōrnołużycki',
 				'ht' => 'kreolski haitański',
 				'hu' => 'wyngerski',
 				'hy' => 'ôrmiański',
 				'ia' => 'interlingua',
 				'id' => 'indōnezyjski',
 				'ig' => 'igbo',
 				'ii' => 'syczuański',
 				'is' => 'islandzki',
 				'it' => 'italijański',
 				'ja' => 'japōński',
 				'jgo' => 'ngōmbe',
 				'jmc' => 'machame',
 				'jv' => 'jawajski',
 				'ka' => 'gruziński',
 				'kab' => 'kabylski',
 				'kam' => 'kamba',
 				'kde' => 'makōnde',
 				'kea' => 'kreolski Wysp Zielōnego Przilōndka',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuju',
 				'kk' => 'kazachski',
 				'kkj' => 'kako',
 				'kl' => 'grynlandzki',
 				'kln' => 'kalynjin',
 				'km' => 'khmerski',
 				'kn' => 'kannada',
 				'ko' => 'koreański',
 				'kok' => 'kōnkani',
 				'ks' => 'kaszmirski',
 				'ksb' => 'sambala',
 				'ksf' => 'bafia',
 				'ksh' => 'gwara kolōńsko',
 				'ku' => 'kurdyjski',
 				'kw' => 'kornijski',
 				'ky' => 'kirgiski',
 				'la' => 'łaciński',
 				'lag' => 'langi',
 				'lb' => 'luksymburski',
 				'lg' => 'ganda',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laotański',
 				'lou' => 'kreolski luizjański',
 				'lrc' => 'luryjski pōłnocny',
 				'lt' => 'litewski',
 				'lu' => 'luba-katanga',
 				'luo' => 'luo',
 				'luy' => 'luhya',
 				'lv' => 'łotewski',
 				'mas' => 'masajski',
 				'mer' => 'meru',
 				'mfe' => 'kreolski Mauritiusa',
 				'mg' => 'malgaski',
 				'mgh' => 'makua',
 				'mgo' => 'meta',
 				'mi' => 'maoryjski',
 				'mk' => 'macedōński',
 				'ml' => 'malajalam',
 				'mn' => 'mōngolski',
 				'mr' => 'marathi',
 				'ms' => 'malajski',
 				'mt' => 'maltański',
 				'mua' => 'mundang',
 				'mul' => 'moc jynzykōw',
 				'my' => 'birmański',
 				'mzn' => 'mazanderański',
 				'naq' => 'nama',
 				'nb' => 'norweski (bokmål)',
 				'nd' => 'ndebele pōłnocny',
 				'nds' => 'dolnoniymiecki',
 				'nds_NL' => 'dolnozaksōński',
 				'ne' => 'nepalski',
 				'nl' => 'niderlandzki',
 				'nl_BE' => 'flamandzki',
 				'nmg' => 'ngumba',
 				'nn' => 'norweski (nynorsk)',
 				'nnh' => 'ngymboōn',
 				'nus' => 'nuer',
 				'ny' => 'njandża',
 				'nyn' => 'nyankole',
 				'om' => 'ôrōmo',
 				'or' => 'ôrija',
 				'os' => 'ôsetyjski',
 				'pa' => 'pyndżabski',
 				'pl' => 'polski',
 				'prg' => 'pruski',
 				'ps' => 'paszto',
 				'pt' => 'portugalski',
 				'pt_BR' => 'brazylijski portugalski',
 				'pt_PT' => 'europejski portugalski',
 				'qu' => 'keczua',
 				'rm' => 'retorōmański',
 				'rn' => 'rundi',
 				'ro' => 'rumuński',
 				'ro_MD' => 'mołdawski',
 				'rof' => 'rōmbo',
 				'ru' => 'ruski',
 				'rw' => 'kinya-ruanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskryt',
 				'sah' => 'jakucki',
 				'saq' => 'samburu',
 				'sbp' => 'sangu',
 				'sd' => 'sindhi',
 				'se' => 'pōłnocnolapōński',
 				'seh' => 'syna',
 				'ses' => 'koyraboro synni',
 				'sg' => 'sango',
 				'shi' => 'tashelhiyt',
 				'si' => 'syngaleski',
 				'sk' => 'słowacki',
 				'sl' => 'słowyński',
 				'sm' => 'samoański',
 				'smn' => 'inari',
 				'sn' => 'shōna',
 				'so' => 'sōmalijski',
 				'sq' => 'albański',
 				'sr' => 'serbski',
 				'st' => 'sotho połedniowy',
 				'su' => 'sundajski',
 				'sv' => 'szwedzki',
 				'sw' => 'suahili',
 				'sw_CD' => 'kōngijski suahili',
 				'szl' => 'ślōnski',
 				'ta' => 'tamilski',
 				'te' => 'telugu',
 				'teo' => 'ateso',
 				'tg' => 'tadżycki',
 				'th' => 'tajski',
 				'ti' => 'tigrinia',
 				'tk' => 'turkmyński',
 				'to' => 'tōnga',
 				'tr' => 'turecki',
 				'tt' => 'tatarski',
 				'twq' => 'tasawaq',
 				'tzm' => 'tamazight (Atlas Postrzodkowy)',
 				'ug' => 'ujgurski',
 				'uk' => 'ukraiński',
 				'und' => 'niyznōmy jynzyk',
 				'ur' => 'urdu',
 				'uz' => 'uzbecki',
 				'vai' => 'wai',
 				'vi' => 'wietnamski',
 				'vo' => 'wolapik',
 				'vun' => 'vunjo',
 				'wae' => 'walser',
 				'wo' => 'wolof',
 				'xh' => 'khosa',
 				'xog' => 'soga',
 				'yav' => 'yangbyn',
 				'yi' => 'jidysz',
 				'yo' => 'joruba',
 				'yue' => 'kantōński',
 				'zgh' => 'standardowy marokański tamazight',
 				'zh' => 'chiński',
 				'zh@alt=menu' => 'chiński mandaryński',
 				'zh_Hans' => 'chiński uproszczōny',
 				'zh_Hans@alt=long' => 'uproszczōny chiński mandaryński',
 				'zh_Hant' => 'chiński tradycyjny',
 				'zh_Hant@alt=long' => 'tradycyjny chiński mandaryński',
 				'zu' => 'zulu',
 				'zxx' => 'brak treści natury jynzykowyj',

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
			'Arab' => 'arabske',
 			'Armi' => 'armi',
 			'Armn' => 'ôrmiańske',
 			'Avst' => 'awestyjske',
 			'Bali' => 'balijske',
 			'Bamu' => 'bamun',
 			'Bass' => 'bassa',
 			'Batk' => 'batak',
 			'Beng' => 'byngalske',
 			'Bopo' => 'bopōmofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'Braille’a',
 			'Bugi' => 'bugińske',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'zunifikowane symbole kanadyjskich autochtōnōw',
 			'Cari' => 'karyjske',
 			'Cham' => 'czamske',
 			'Cher' => 'czirokeski',
 			'Copt' => 'koptyjske',
 			'Cprt' => 'cypryjske',
 			'Cyrl' => 'cyrylica',
 			'Deva' => 'dewanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duploye’a',
 			'Egyp' => 'hieroglify egipske',
 			'Ethi' => 'etiopske',
 			'Geor' => 'gruzińske',
 			'Glag' => 'głagolica',
 			'Goth' => 'gotyckie',
 			'Gran' => 'grantha',
 			'Grek' => 'greckie',
 			'Gujr' => 'gudźarackie',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangyl',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'uproszczōne',
 			'Hans@alt=stand-alone' => 'uproszczōne han',
 			'Hant' => 'tradycyjne',
 			'Hant@alt=stand-alone' => 'tradycyjne han',
 			'Hebr' => 'hebrajske',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hieroglify anatolijske',
 			'Hmng' => 'pahawh hmōng',
 			'Hrkt' => 'sylabariusze japōńske',
 			'Hung' => 'starowyngerske',
 			'Ital' => 'staroitalijańske',
 			'Jamo' => 'jamo',
 			'Java' => 'jawajske',
 			'Jpan' => 'japōńske',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'charosti',
 			'Khmr' => 'khmerske',
 			'Khoj' => 'khojki',
 			'Knda' => 'kannada',
 			'Kore' => 'koreańske',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laotańske',
 			'Latn' => 'łacińske',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'linearne A',
 			'Linb' => 'linearne B',
 			'Lisu' => 'alfabet Frasera',
 			'Lyci' => 'likijske',
 			'Lydi' => 'lidyjske',
 			'Mand' => 'mandejske',
 			'Mani' => 'manichejske',
 			'Mend' => 'mynde',
 			'Merc' => 'meroickie (kursywa)',
 			'Mero' => 'meroickie',
 			'Mlym' => 'malajalam',
 			'Mong' => 'mōngolske',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei mayek',
 			'Mymr' => 'birmańske',
 			'Narb' => 'staroarabske pōłnocne',
 			'Nbat' => 'nabatejske',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Palm' => 'palmirske',
 			'Perm' => 'staropermske',
 			'Phag' => 'phags-pa',
 			'Phli' => 'inskrypcyjne pahlawi',
 			'Phlp' => 'psałterzowe pahlawi',
 			'Phnx' => 'fynicke',
 			'Plrd' => 'fōnetyczne Pollarda',
 			'Prti' => 'partyjske inskrypcyjne',
 			'Rjng' => 'rejang',
 			'Runr' => 'runiczne',
 			'Samr' => 'samarytańske',
 			'Sarb' => 'staroarabske połedniowe',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'pismo znakowe',
 			'Shaw' => 'shawa',
 			'Shrd' => 'śarada',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'syngaleske',
 			'Sora' => 'sorang sōmpyng',
 			'Sund' => 'sundajske',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syryjske',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'nowy tai lue',
 			'Taml' => 'tamilske',
 			'Tang' => 'tanguckie',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagh (berberski)',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'tajske',
 			'Tibt' => 'tybetańske',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaryckie',
 			'Vaii' => 'vai',
 			'Wara' => 'Varang Kshiti',
 			'Xpeo' => 'staroperske',
 			'Xsux' => 'klinowe sumero-akadyjske',
 			'Yiii' => 'yi',
 			'Zinh' => 'erbowane',
 			'Zmth' => 'notacyjo matymatyczno',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'symbole',
 			'Zxxx' => 'jynzyk bez systymu pisma',
 			'Zyyy' => 'spōlne',
 			'Zzzz' => 'niyznōmy skrypt',

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
			'001' => 'Świat',
 			'002' => 'Afryka',
 			'003' => 'Pōłnocno Ameryka',
 			'005' => 'Połedniowo Ameryka',
 			'009' => 'Ôceanijo',
 			'011' => 'Zachodnio Afryka',
 			'013' => 'Postrzodkowo Ameryka',
 			'014' => 'Wschodnio Afryka',
 			'015' => 'Pōłnocno Afryka',
 			'017' => 'Postrzodkowo Afryka',
 			'018' => 'Połedniowo Afryka',
 			'019' => 'Ameryka',
 			'021' => 'Pōłnocno Ameryka (USA, Kanada)',
 			'029' => 'Karajiby',
 			'030' => 'Wschodnio Azyjo',
 			'034' => 'Połedniowo Azyjo',
 			'035' => 'Połedniowo-wschodnio Azyjo',
 			'039' => 'Połedniowo Europa',
 			'053' => 'Australazyjo',
 			'054' => 'Melanezyjo',
 			'057' => 'Regiōn Mikrōnezyje',
 			'061' => 'Polinezyjo',
 			'142' => 'Azyjo',
 			'143' => 'Postrzodkowo Azyjo',
 			'145' => 'Zachodnio Azyjo',
 			'150' => 'Europa',
 			'151' => 'Wschodnio Europa',
 			'154' => 'Pōłnocno Europa',
 			'155' => 'Zachodnio Europa',
 			'202' => 'Subsaharyjsko Afryka',
 			'419' => 'Łacińsko Ameryka',
 			'AC' => 'Wyspa Wniebostōmpiynio',
 			'AD' => 'Andora',
 			'AE' => 'Zjednoczōne Ymiraty Arabske',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua i Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanijo',
 			'AM' => 'Armynijo',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktyda',
 			'AR' => 'Argyntyna',
 			'AS' => 'Amerykańske Samoa',
 			'AT' => 'Austryjo',
 			'AU' => 'Australijo',
 			'AW' => 'Aruba',
 			'AX' => 'Wyspy Alandzkie',
 			'AZ' => 'Azerbejdżan',
 			'BA' => 'Bośnia i Hercegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesz',
 			'BE' => 'Belgijo',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bułgaryjo',
 			'BH' => 'Bahrajn',
 			'BI' => 'Burundi',
 			'BJ' => 'Bynin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermudy',
 			'BN' => 'Brunei',
 			'BO' => 'Boliwijo',
 			'BQ' => 'Karajibske Niderlandy',
 			'BR' => 'Brazylijo',
 			'BS' => 'Bahamy',
 			'BT' => 'Bhutan',
 			'BV' => 'Wyspa Bouveta',
 			'BW' => 'Botswana',
 			'BY' => 'Biołoruś',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosowe Wyspy',
 			'CD' => 'Dymokratyczno Republika Kōnga',
 			'CD@alt=variant' => 'Kōngo (DRK)',
 			'CF' => 'Republika Postrzodkowoafrykańsko',
 			'CG' => 'Kōngo',
 			'CG@alt=variant' => 'Republika Kōnga',
 			'CH' => 'Szwajcaryjo',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Wybrzeże Kości Słōniowyj',
 			'CK' => 'Wyspy Cooka',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Chiny',
 			'CO' => 'Kolumbijo',
 			'CP' => 'Wyspa Clippertona',
 			'CR' => 'Kostaryka',
 			'CU' => 'Kuba',
 			'CV' => 'Republika Zielōnego Przilōndka',
 			'CW' => 'Curaçao',
 			'CX' => 'Godnio Wyspa',
 			'CY' => 'Cypr',
 			'CZ' => 'Czechy',
 			'CZ@alt=variant' => 'Czesko Republika',
 			'DE' => 'Niymcy',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dżibuti',
 			'DK' => 'Danijo',
 			'DM' => 'Dōminika',
 			'DO' => 'Dōminikana',
 			'DZ' => 'Algeryjo',
 			'EA' => 'Ceuta i Melilla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estōnijo',
 			'EG' => 'Egipt',
 			'EH' => 'Zachodnio Sahara',
 			'ER' => 'Erytrea',
 			'ES' => 'Hiszpanijo',
 			'ET' => 'Etiopijo',
 			'EU' => 'Europejsko Unijo',
 			'EZ' => 'Strefa euro',
 			'FI' => 'Finlandyjo',
 			'FJ' => 'Fidżi',
 			'FK' => 'Falklandy',
 			'FK@alt=variant' => 'Falklandy (Malwiny)',
 			'FM' => 'Mikrōnezyjo',
 			'FO' => 'Wyspy Ôwcze',
 			'FR' => 'Francyjo',
 			'GA' => 'Gabōn',
 			'GB' => 'Wielko Brytanijo',
 			'GB@alt=short' => 'Wlk. Bryt.',
 			'GD' => 'Grynada',
 			'GE' => 'Gruzyjo',
 			'GF' => 'Francusko Gujana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grynlandyjo',
 			'GM' => 'Gambijo',
 			'GN' => 'Gwinea',
 			'GP' => 'Gwadelupa',
 			'GQ' => 'Rōwnikowo Gwinea',
 			'GR' => 'Grecyjo',
 			'GS' => 'Połedniowo Georgia i Połedniowy Sandwich',
 			'GT' => 'Gwatymala',
 			'GU' => 'Guam',
 			'GW' => 'Gwinea Bissau',
 			'GY' => 'Gujana',
 			'HK' => 'SRA Hōngkōng (Chiny)',
 			'HK@alt=short' => 'Hōngkōng',
 			'HM' => 'Wyspy Heard i McDonalda',
 			'HN' => 'Hōnduras',
 			'HR' => 'Chorwacyjo',
 			'HT' => 'Haiti',
 			'HU' => 'Wyngry',
 			'IC' => 'Kanaryjske Wyspy',
 			'ID' => 'Indōnezyjo',
 			'IE' => 'Irlandyjo',
 			'IL' => 'Izrael',
 			'IM' => 'Wyspa Man',
 			'IN' => 'Indyjo',
 			'IO' => 'Brytyjske Terytorium Indyjskigo Ôceanu',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandyjo',
 			'IT' => 'Italijo',
 			'JE' => 'Jersey',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordanijo',
 			'JP' => 'Japōnijo',
 			'KE' => 'Kynijo',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambodża',
 			'KI' => 'Kiribati',
 			'KM' => 'Kōmory',
 			'KN' => 'Saint Kitts i Nevis',
 			'KP' => 'Pōłnocno Korea',
 			'KR' => 'Połedniowo Korea',
 			'KW' => 'Kuwejt',
 			'KY' => 'Kajmany',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberyjo',
 			'LS' => 'Lesotho',
 			'LT' => 'Litwa',
 			'LU' => 'Luksymburg',
 			'LV' => 'Łotwa',
 			'LY' => 'Libijo',
 			'MA' => 'Maroko',
 			'MC' => 'Mōnako',
 			'MD' => 'Mołdawijo',
 			'ME' => 'Czornogōra',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Wyspy Marshalla',
 			'MK' => 'Pōłnocno Macedōnijo',
 			'ML' => 'Mali',
 			'MM' => 'Mjanma (Birma)',
 			'MN' => 'Mōngolijo',
 			'MO' => 'SRA Makau (Chiny)',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Pōłnocne Mariany',
 			'MQ' => 'Martynika',
 			'MR' => 'Mauretanijo',
 			'MS' => 'Mōntserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediwy',
 			'MW' => 'Malawi',
 			'MX' => 'Meksyk',
 			'MY' => 'Malezyjo',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibijo',
 			'NC' => 'Nowo Kaledōnijo',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigeryjo',
 			'NI' => 'Nikaragua',
 			'NL' => 'Niderlandy',
 			'NO' => 'Norwegijo',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nowo Zelandyjo',
 			'OM' => 'Ōman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francusko Polinezyjo',
 			'PG' => 'Papua-Nowo Gwinea',
 			'PH' => 'Filipiny',
 			'PK' => 'Pakistan',
 			'PL' => 'Polska',
 			'PM' => 'Saint-Pierre i Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Portoryko',
 			'PS' => 'Palestyńske Terytoria',
 			'PS@alt=short' => 'Palestyna',
 			'PT' => 'Portugalijo',
 			'PW' => 'Palau',
 			'PY' => 'Paragwaj',
 			'QA' => 'Katar',
 			'QO' => 'Ôceanijo — wyspy daleke',
 			'RE' => 'Reunion',
 			'RO' => 'Rumunijo',
 			'RS' => 'Serbijo',
 			'RU' => 'Rusyjo',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudyjsko Arabijo',
 			'SB' => 'Wyspy Salōmōna',
 			'SC' => 'Seszele',
 			'SD' => 'Sudan',
 			'SE' => 'Szwecyjo',
 			'SG' => 'Singapur',
 			'SH' => 'Wyspa Świyntyj Helyny',
 			'SI' => 'Słowynijo',
 			'SJ' => 'Svalbard i Jan Mayen',
 			'SK' => 'Słowacyjo',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Synegal',
 			'SO' => 'Sōmalijo',
 			'SR' => 'Surinam',
 			'SS' => 'Połedniowy Sudan',
 			'ST' => 'Wyspy Świyntego Tōmasza i Princowa',
 			'SV' => 'Salwador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syryjo',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Suazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks i Caicos',
 			'TD' => 'Czad',
 			'TF' => 'Francuske Terytoria Połedniowe i Antarktyczne',
 			'TG' => 'Togo',
 			'TH' => 'Tajlandyjo',
 			'TJ' => 'Tadżykistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Wschodni Timor',
 			'TM' => 'Turkmynistan',
 			'TN' => 'Tunezyjo',
 			'TO' => 'Tōnga',
 			'TR' => 'Turcyjo',
 			'TT' => 'Trynidad i Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajwan',
 			'TZ' => 'Tanzanijo',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Daleke Myńsze Wyspy Stanōw Zjednoczōnych',
 			'UN' => 'Ôrganizacyjo Norodōw Zjednoczōnych',
 			'US' => 'Stany Zjednoczōne',
 			'US@alt=short' => 'USA',
 			'UY' => 'Urugwaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Watykan',
 			'VC' => 'Saint Vincent i Grynadyny',
 			'VE' => 'Wynezuela',
 			'VG' => 'Brytyjske Wyspy Dziewicze',
 			'VI' => 'Wyspy Dziewicze Stanōw Zjednoczōnych',
 			'VN' => 'Wietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis i Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudoakcynty',
 			'XB' => 'Pseudodwurychtōnkowe',
 			'XK' => 'Kosowo',
 			'YE' => 'Jymyn',
 			'YT' => 'Majotta',
 			'ZA' => 'Republika Połedniowyj Afryki',
 			'ZM' => 'Zambijo',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Niyznōmy regiōn',

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
 				'gregorian' => q{Gregoriański kalyndorz},
 				'iso8601' => q{Kalyndorz ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Sztandardowy porzōndek zortowanio},
 			},
 			'numbers' => {
 				'latn' => q{Cyfry zachodnie},
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
			'metric' => q{metryczny},
 			'UK' => q{brytyjski},
 			'US' => q{amerykański},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Jynzyk: {0}',
 			'script' => 'Pismo: {0}',
 			'region' => 'Regiōn: {0}',

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
			auxiliary => qr{[àăâåäąā æ čç ď éèĕêěëęē íìĭîïī ľ ňñ óòöø œ q ŕř š ß ť úùŭûůüū v x ýÿ ž]},
			index => ['A', 'B', 'CĆ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'LŁ', 'M', 'NŃ', 'OÔŌ', 'P', 'Q', 'R', 'SŚ', 'T', 'U', 'V', 'W', 'X', 'Y', 'ZŹŻ'],
			main => qr{[aã b cć d e f g h i j k lł m nń oŏôõō p r sś t u w y zźż]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … ' "”„ « » ( ) \[ \] \{ \} § @ * / \& # % † ‡ ′ ″ ° ~]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'CĆ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'LŁ', 'M', 'NŃ', 'OÔŌ', 'P', 'Q', 'R', 'SŚ', 'T', 'U', 'V', 'W', 'X', 'Y', 'ZŹŻ'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(rychtōnek świata),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(rychtōnek świata),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(stało grawitacyje),
						'other' => q({0} stałyj grawitacyje),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(stało grawitacyje),
						'other' => q({0} stałyj grawitacyje),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metry na sekunda do kwadratu),
						'other' => q({0} metra na sekunda do kwadratu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metry na sekunda do kwadratu),
						'other' => q({0} metra na sekunda do kwadratu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minuty kōntowe),
						'other' => q({0} minuty kōntowyj),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minuty kōntowe),
						'other' => q({0} minuty kōntowyj),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sekundy kōntowe),
						'other' => q({0} sekundy kōntowyj),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sekundy kōntowe),
						'other' => q({0} sekundy kōntowyj),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} stopnia),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} stopnia),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiany),
						'other' => q({0} radiana),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiany),
						'other' => q({0} radiana),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ôbrōt),
						'other' => q({0} ôbrotu),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ôbrōt),
						'other' => q({0} ôbrotu),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} akra),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} akra),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektary),
						'other' => q({0} hektara),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektary),
						'other' => q({0} hektara),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cyntymetry kwadratowe),
						'other' => q({0} cyntymetra kwadratowego),
						'per' => q({0} na cyntymeter kwadratowy),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cyntymetry kwadratowe),
						'other' => q({0} cyntymetra kwadratowego),
						'per' => q({0} na cyntymeter kwadratowy),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(stopy kwadratowe),
						'other' => q({0} stopy kwadratowyj),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(stopy kwadratowe),
						'other' => q({0} stopy kwadratowyj),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(cale kwadratowe),
						'other' => q({0} cala kwadratowego),
						'per' => q({0} na cal kwadratowy),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(cale kwadratowe),
						'other' => q({0} cala kwadratowego),
						'per' => q({0} na cal kwadratowy),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilōmetry kwadratowe),
						'other' => q({0} kilōmetra kwadratowego),
						'per' => q({0} na kilōmeter kwadratowy),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilōmetry kwadratowe),
						'other' => q({0} kilōmetra kwadratowego),
						'per' => q({0} na kilōmeter kwadratowy),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metry kwadratowe),
						'other' => q({0} metra kwadratowego),
						'per' => q({0} na meter kwadratowy),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metry kwadratowe),
						'other' => q({0} metra kwadratowego),
						'per' => q({0} na meter kwadratowy),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mile kwadratowe),
						'other' => q({0} mili kwadratowyj),
						'per' => q({0} na mila kwadratowōm),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mile kwadratowe),
						'other' => q({0} mili kwadratowyj),
						'per' => q({0} na mila kwadratowōm),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jardy kwadratowe),
						'other' => q({0} jarda kwadratowego),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jardy kwadratowe),
						'other' => q({0} jarda kwadratowego),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramy na decyliter),
						'other' => q({0} miligrama na decyliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramy na decyliter),
						'other' => q({0} miligrama na decyliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole na liter),
						'other' => q({0} milimola na liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole na liter),
						'other' => q({0} milimola na liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} procynt),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} procynt),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} prōmila),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} prōmila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(czyńści na milijōn),
						'other' => q({0} czyńści na milijōn),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(czyńści na milijōn),
						'other' => q({0} czyńści na milijōn),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(punkt bazowy),
						'other' => q({0} punktu bazowego),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(punkt bazowy),
						'other' => q({0} punktu bazowego),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litry na 100 kilōmetrōw),
						'other' => q({0} litra na 100 kilōmetrōw),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litry na 100 kilōmetrōw),
						'other' => q({0} litra na 100 kilōmetrōw),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litry na kilōmeter),
						'other' => q({0} litra na kilōmeter),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litry na kilōmeter),
						'other' => q({0} litra na kilōmeter),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mile na galōn),
						'other' => q({0} mile na galōn),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mile na galōn),
						'other' => q({0} mile na galōn),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mile na galōn angelski),
						'other' => q({0} mile na galōn angelski),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mile na galōn angelski),
						'other' => q({0} mile na galōn angelski),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} dugości geograficznyj wschodnij),
						'north' => q({0} szyrokości geograficznyj pōłnocnyj),
						'south' => q({0} szyrokości geograficznyj połedniowyj),
						'west' => q({0} dugości geograficznyj zachodnij),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} dugości geograficznyj wschodnij),
						'north' => q({0} szyrokości geograficznyj pōłnocnyj),
						'south' => q({0} szyrokości geograficznyj połedniowyj),
						'west' => q({0} dugości geograficznyj zachodnij),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'other' => q({0} bitu),
					},
					# Core Unit Identifier
					'bit' => {
						'other' => q({0} bitu),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'other' => q({0} bajta),
					},
					# Core Unit Identifier
					'byte' => {
						'other' => q({0} bajta),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabity),
						'other' => q({0} gigabitu),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabity),
						'other' => q({0} gigabitu),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabajty),
						'other' => q({0} gigabajta),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabajty),
						'other' => q({0} gigabajta),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobity),
						'other' => q({0} kilobitu),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobity),
						'other' => q({0} kilobitu),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobajty),
						'other' => q({0} kilobajta),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobajty),
						'other' => q({0} kilobajta),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabity),
						'other' => q({0} megabitu),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabity),
						'other' => q({0} megabitu),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabajty),
						'other' => q({0} megabajta),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabajty),
						'other' => q({0} megabajta),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabajty),
						'other' => q({0} petabajta),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabajty),
						'other' => q({0} petabajta),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabity),
						'other' => q({0} terabitu),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabity),
						'other' => q({0} terabitu),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabajty),
						'other' => q({0} terabajta),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabajty),
						'other' => q({0} terabajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(stolecie),
						'other' => q({0} stolecio),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(stolecie),
						'other' => q({0} stolecio),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} na dziyń),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} na dziyń),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekady),
						'other' => q({0} dekady),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekady),
						'other' => q({0} dekady),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} godziny),
						'per' => q({0} na godzina),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} godziny),
						'per' => q({0} na godzina),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekundy),
						'other' => q({0} mikrosekundy),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekundy),
						'other' => q({0} mikrosekundy),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0} milisekundy),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0} milisekundy),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} minuty),
						'per' => q({0} na minuta),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} minuty),
						'per' => q({0} na minuta),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} miesiōnca),
						'per' => q({0} na miesiōnc),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} miesiōnca),
						'per' => q({0} na miesiōnc),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekundy),
						'other' => q({0} nanosekundy),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekundy),
						'other' => q({0} nanosekundy),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(sztwierci roku),
						'other' => q({0} sztwierci roku),
						'per' => q({0} na sztwierć roku),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(sztwierci roku),
						'other' => q({0} sztwierci roku),
						'per' => q({0} na sztwierć roku),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} sekundy),
						'per' => q({0} na sekunda),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} sekundy),
						'per' => q({0} na sekunda),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} tydnia),
						'per' => q({0} na tydziyń),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} tydnia),
						'per' => q({0} na tydziyń),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} na rok),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} na rok),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0} ampra),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0} ampra),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampry),
						'other' => q({0} miliampra),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampry),
						'other' => q({0} miliampra),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} ōma),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} ōma),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} wolta),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} wolta),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(brytyjsko jednostka ciepła),
						'other' => q({0} brytyjskij jednostki ciepła),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(brytyjsko jednostka ciepła),
						'other' => q({0} brytyjskij jednostki ciepła),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloryje),
						'other' => q({0} kaloryje),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloryje),
						'other' => q({0} kaloryje),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektrōnowolty),
						'other' => q({0} elektrōnowolta),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektrōnowolty),
						'other' => q({0} elektrōnowolta),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kaloryje),
						'other' => q({0} kaloryje),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kaloryje),
						'other' => q({0} kaloryje),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(dżule),
						'other' => q({0} dżula),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(dżule),
						'other' => q({0} dżula),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloryje),
						'other' => q({0} kilokaloryje),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloryje),
						'other' => q({0} kilokaloryje),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilodżule),
						'other' => q({0} kilodżula),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilodżule),
						'other' => q({0} kilodżula),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatogodziny),
						'other' => q({0} kilowatogodziny),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatogodziny),
						'other' => q({0} kilowatogodziny),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(term amerykański),
						'other' => q({0} terma amerykańskigo),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(term amerykański),
						'other' => q({0} terma amerykańskigo),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(niutōny),
						'other' => q({0} niutōna),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(niutōny),
						'other' => q({0} niutōna),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0} fōnta-siły),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0} fōnta-siły),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigaherce),
						'other' => q({0} gigaherca),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigaherce),
						'other' => q({0} gigaherca),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(herce),
						'other' => q({0} herca),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(herce),
						'other' => q({0} herca),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kiloherce),
						'other' => q({0} kiloherca),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kiloherce),
						'other' => q({0} kiloherca),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megaherce),
						'other' => q({0} megaherca),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megaherce),
						'other' => q({0} megaherca),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pōnkty na cyntymeter),
						'other' => q({0} pōnkta na cyntymeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pōnkty na cyntymeter),
						'other' => q({0} pōnkta na cyntymeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pōnkty na col),
						'other' => q({0} pōnkta na col),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pōnkty na col),
						'other' => q({0} pōnkta na col),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(typograficzne ym),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(typograficzne ym),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0} megapiksela),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0} megapiksela),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} piksela),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} piksela),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksele na cyntymeter),
						'other' => q({0} piksela na cyntymeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksele na cyntymeter),
						'other' => q({0} piksela na cyntymeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksele na col),
						'other' => q({0} piksela na col),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksele na col),
						'other' => q({0} piksela na col),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(jednostki astrōnōmiczne),
						'other' => q({0} jednostki astrōnōmicznyj),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(jednostki astrōnōmiczne),
						'other' => q({0} jednostki astrōnōmicznyj),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'other' => q({0} cyntymetra),
						'per' => q({0} na cyntymeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'other' => q({0} cyntymetra),
						'per' => q({0} na cyntymeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decymetry),
						'other' => q({0} decymetra),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decymetry),
						'other' => q({0} decymetra),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0} stopy),
						'per' => q({0} na stopa),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0} stopy),
						'per' => q({0} na stopa),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(cole),
						'other' => q({0} cola),
						'per' => q({0} na col),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(cole),
						'other' => q({0} cola),
						'per' => q({0} na col),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilōmetry),
						'other' => q({0} kilōmetra),
						'per' => q({0} na kilōmeter),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilōmetry),
						'other' => q({0} kilōmetra),
						'per' => q({0} na kilōmeter),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'other' => q({0} roku świetlnego),
					},
					# Core Unit Identifier
					'light-year' => {
						'other' => q({0} roku świetlnego),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metry),
						'other' => q({0} metra),
						'per' => q({0} na meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metry),
						'other' => q({0} metra),
						'per' => q({0} na meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrōmetry),
						'other' => q({0} mikrōmetra),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrōmetry),
						'other' => q({0} mikrōmetra),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q({0} mile),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0} mile),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mila skandynawsko),
						'other' => q({0} mile skandynawskij),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mila skandynawsko),
						'other' => q({0} mile skandynawskij),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetry),
						'other' => q({0} milimetra),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetry),
						'other' => q({0} milimetra),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanōmetry),
						'other' => q({0} nanōmetra),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanōmetry),
						'other' => q({0} nanōmetra),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mile morske),
						'other' => q({0} mile morskij),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mile morske),
						'other' => q({0} mile morskij),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parseki),
						'other' => q({0} parseka),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parseki),
						'other' => q({0} parseka),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikōmetry),
						'other' => q({0} pikōmetra),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikōmetry),
						'other' => q({0} pikōmetra),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} prōmiynia Słōńca),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} prōmiynia Słōńca),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardy),
						'other' => q({0} jarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardy),
						'other' => q({0} jarda),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luksy),
						'other' => q({0} luksu),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luksy),
						'other' => q({0} luksu),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0} jasności Słōńca),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} jasności Słōńca),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'carat' => {
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} daltōna),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} daltōna),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0} masy Ziymie),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0} masy Ziymie),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramy),
						'other' => q({0} grama),
						'per' => q({0} na gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramy),
						'other' => q({0} grama),
						'per' => q({0} na gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramy),
						'other' => q({0} kilograma),
						'per' => q({0} na kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramy),
						'other' => q({0} kilograma),
						'per' => q({0} na kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramy),
						'other' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramy),
						'other' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramy),
						'other' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramy),
						'other' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(uncyje),
						'other' => q({0} uncyje),
						'per' => q({0} na uncyjo),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(uncyje),
						'other' => q({0} uncyje),
						'per' => q({0} na uncyjo),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(uncyjo trojańsko),
						'other' => q({0} uncyje trojańskij),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(uncyjo trojańsko),
						'other' => q({0} uncyje trojańskij),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} fōnta),
						'per' => q({0} na fōnt),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} fōnta),
						'per' => q({0} na fōnt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0} masy Słōńca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0} masy Słōńca),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(krōtke tōny),
						'other' => q({0} krōtkij tōny),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(krōtke tōny),
						'other' => q({0} krōtkij tōny),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tōny),
						'other' => q({0} tōny),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tōny),
						'other' => q({0} tōny),
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
						'name' => q(gigawaty),
						'other' => q({0} gigawata),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawaty),
						'other' => q({0} gigawata),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kōnie mechaniczne),
						'other' => q({0} kōnia mechanicznego),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kōnie mechaniczne),
						'other' => q({0} kōnia mechanicznego),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowaty),
						'other' => q({0} kilowata),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowaty),
						'other' => q({0} kilowata),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawaty),
						'other' => q({0} megawata),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawaty),
						'other' => q({0} megawata),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwaty),
						'other' => q({0} miliwata),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwaty),
						'other' => q({0} miliwata),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} wata),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} wata),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfery),
						'other' => q({0} atmosfery),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfery),
						'other' => q({0} atmosfery),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bary),
						'other' => q({0} bara),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bary),
						'other' => q({0} bara),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskale),
						'other' => q({0} hektopaskala),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskale),
						'other' => q({0} hektopaskala),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(cole supa rtyńci),
						'other' => q({0} cola supa rtyńci),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(cole supa rtyńci),
						'other' => q({0} cola supa rtyńci),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskale),
						'other' => q({0} kilopaskala),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskale),
						'other' => q({0} kilopaskala),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskale),
						'other' => q({0} megapaskala),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskale),
						'other' => q({0} megapaskala),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibary),
						'other' => q({0} millibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibary),
						'other' => q({0} millibara),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetry supa rtyńci),
						'other' => q({0} milimetra supa rtyńci),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetry supa rtyńci),
						'other' => q({0} milimetra supa rtyńci),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskale),
						'other' => q({0} paskala),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskale),
						'other' => q({0} paskala),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(fōnty na col kwadratowy),
						'other' => q({0} fōnta na col kwadratowy),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(fōnty na col kwadratowy),
						'other' => q({0} fōnta na col kwadratowy),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilōmetry na godzina),
						'other' => q({0} kilōmetra na godzina),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilōmetry na godzina),
						'other' => q({0} kilōmetra na godzina),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(wynzeł),
						'other' => q({0} wynzła),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(wynzeł),
						'other' => q({0} wynzła),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metry na sekunda),
						'other' => q({0} metra na sekunda),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metry na sekunda),
						'other' => q({0} metra na sekunda),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mile na godzina),
						'other' => q({0} mile na godzina),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mile na godzina),
						'other' => q({0} mile na godzina),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(stopnie Celsjusza),
						'other' => q({0} stopnia Celsjusza),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(stopnie Celsjusza),
						'other' => q({0} stopnia Celsjusza),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(stopnie Fahrenheita),
						'other' => q({0} stopnia Fahrenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(stopnie Fahrenheita),
						'other' => q({0} stopnia Fahrenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(stopnie),
						'other' => q({0} stopnia),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(stopnie),
						'other' => q({0} stopnia),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelwiny),
						'other' => q({0} kelwina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelwiny),
						'other' => q({0} kelwina),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(niutōnōmetry),
						'other' => q({0} niutōnōmetra),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(niutōnōmetry),
						'other' => q({0} niutōnōmetra),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(stopofunty),
						'other' => q({0} stopofunt),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(stopofunty),
						'other' => q({0} stopofunt),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akro-stopy),
						'other' => q({0} akro-stopy),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akro-stopy),
						'other' => q({0} akro-stopy),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'other' => q({0} baryłki),
					},
					# Core Unit Identifier
					'barrel' => {
						'other' => q({0} baryłki),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cyntylitry),
						'other' => q({0} cyntylitra),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cyntylitry),
						'other' => q({0} cyntylitra),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cyntymetry sześciynne),
						'other' => q({0} cyntymetra sześciynnego),
						'per' => q({0} na cyntymeter sześciynny),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cyntymetry sześciynne),
						'other' => q({0} cyntymetra sześciynnego),
						'per' => q({0} na cyntymeter sześciynny),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(stopy sześciynne),
						'other' => q({0} stopy sześciynnyj),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(stopy sześciynne),
						'other' => q({0} stopy sześciynnyj),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(cale sześciynne),
						'other' => q({0} cala sześciynnego),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(cale sześciynne),
						'other' => q({0} cala sześciynnego),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilōmetry sześciynne),
						'other' => q({0} kilōmetra sześciynnego),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilōmetry sześciynne),
						'other' => q({0} kilōmetra sześciynnego),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metry sześciynne),
						'other' => q({0} metra sześciynnego),
						'per' => q({0} na meter sześciynny),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metry sześciynne),
						'other' => q({0} metra sześciynnego),
						'per' => q({0} na meter sześciynny),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mile sześciynne),
						'other' => q({0} mile sześciynnyj),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mile sześciynne),
						'other' => q({0} mile sześciynnyj),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jardy sześciynne),
						'other' => q({0} jarda sześciynnego),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jardy sześciynne),
						'other' => q({0} jarda sześciynnego),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} ćwierćkworty),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} ćwierćkworty),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ćwierćkwarty metryczne),
						'other' => q({0} ćwierćkwarty metrycznyj),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ćwierćkwarty metryczne),
						'other' => q({0} ćwierćkwarty metrycznyj),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decylitry),
						'other' => q({0} decylitra),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decylitry),
						'other' => q({0} decylitra),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(uncyje płynu),
						'other' => q({0} uncyje płynu),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(uncyje płynu),
						'other' => q({0} uncyje płynu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(uncyje płynu imp.),
						'other' => q({0} uncyje płynu imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(uncyje płynu imp.),
						'other' => q({0} uncyje płynu imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galōny),
						'other' => q({0} galōna),
						'per' => q({0} na galōn),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galōny),
						'other' => q({0} galōna),
						'per' => q({0} na galōn),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galōny angelske),
						'other' => q({0} galōna angelskigo),
						'per' => q({0} na galōn angelski),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galōny angelske),
						'other' => q({0} galōna angelskigo),
						'per' => q({0} na galōn angelski),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitry),
						'other' => q({0} hektolitra),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitry),
						'other' => q({0} hektolitra),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} litra),
						'per' => q({0} na liter),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} litra),
						'per' => q({0} na liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitry),
						'other' => q({0} megalitra),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitry),
						'other' => q({0} megalitra),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitry),
						'other' => q({0} mililitra),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitry),
						'other' => q({0} mililitra),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} pōłkworty),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} pōłkworty),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pōłkworty metryczne),
						'other' => q({0} pōłkworty metrycznyj),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pōłkworty metryczne),
						'other' => q({0} pōłkworty metrycznyj),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kworty),
						'other' => q({0} kworty),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kworty),
						'other' => q({0} kworty),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(łyżki stołowe),
						'other' => q({0} łyżki stołowyj),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(łyżki stołowe),
						'other' => q({0} łyżki stołowyj),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dziyń),
						'other' => q({0} dn.),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dziyń),
						'other' => q({0} dn.),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(godzina),
						'other' => q({0} g.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(godzina),
						'other' => q({0} g.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(miesiōnc),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(miesiōnc),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(tydziyń),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(tydziyń),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(rok),
						'other' => q({0} r.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(rok),
						'other' => q({0} r.),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(funty),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(funty),
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
						'name' => q(rychtōnek),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(rychtōnek),
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
						'name' => q(minuty),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minuty),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sekundy),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sekundy),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(stopnie),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(stopnie),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ôbr.),
						'other' => q({0} ôbr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ôbr.),
						'other' => q({0} ôbr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akry),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akry),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunamy),
						'other' => q({0} dunama),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunamy),
						'other' => q({0} dunama),
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
					'area-square-foot' => {
						'name' => q(st²),
						'other' => q({0} st²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(st²),
						'other' => q({0} st²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(c²),
						'other' => q({0} c²),
						'per' => q({0}/c²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(c²),
						'other' => q({0} c²),
						'per' => q({0}/c²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jd²),
						'other' => q({0} jd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jd²),
						'other' => q({0} jd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaty),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaty),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole/liter),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole/liter),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q({0} mola),
					},
					# Core Unit Identifier
					'mole' => {
						'other' => q({0} mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(procynt),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(procynt),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(prōmil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(prōmil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(czyńści/miliōn),
						'other' => q({0} cz/mln),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(czyńści/miliōn),
						'other' => q({0} cz/mln),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pōnkt bazowy),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pōnkt bazowy),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mile/gal ang.),
						'other' => q({0} mi/gal ang.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mile/gal ang.),
						'other' => q({0} mi/gal ang.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bity),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bity),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bajty),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bajty),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(st.),
						'other' => q({0} st.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(st.),
						'other' => q({0} st.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dni),
						'other' => q({0} dnia),
						'per' => q({0}/dziyń),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dni),
						'other' => q({0} dnia),
						'per' => q({0}/dziyń),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek.),
						'other' => q({0} dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek.),
						'other' => q({0} dek.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(godziny),
						'other' => q({0} godz.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(godziny),
						'other' => q({0} godz.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekundy),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekundy),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuty),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuty),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(miesiōnce),
						'other' => q({0} mies.),
						'per' => q({0}/mies.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(miesiōnce),
						'other' => q({0} mies.),
						'per' => q({0}/mies.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(sztr),
						'other' => q({0} sztr),
						'per' => q({0}/szt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(sztr),
						'other' => q({0} sztr),
						'per' => q({0}/szt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundy),
						'other' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundy),
						'other' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(tydnie),
						'other' => q({0} tyd.),
						'per' => q({0}/tydz.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(tydnie),
						'other' => q({0} tyd.),
						'per' => q({0}/tydz.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(lata),
						'other' => q({0} roku),
						'per' => q({0}/rok),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(lata),
						'other' => q({0} roku),
						'per' => q({0}/rok),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampry),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampry),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ōmy),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ōmy),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(wolty),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(wolty),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektrōnowolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektrōnowolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(col),
						'other' => q({0} col),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(col),
						'other' => q({0} col),
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
					'energy-therm-us' => {
						'name' => q(term USA),
						'other' => q({0} terma USA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(term USA),
						'other' => q({0} terma USA),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(niutōn),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(niutōn),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(fōnt-siła),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(fōnt-siła),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pk/cm),
						'other' => q({0} pk/cm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pk/cm),
						'other' => q({0} pk/cm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pk/c),
						'other' => q({0} pk/c),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pk/c),
						'other' => q({0} pk/c),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ym),
						'other' => q({0} yma),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ym),
						'other' => q({0} yma),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksele),
						'other' => q({0} mp),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksele),
						'other' => q({0} mp),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksele),
						'other' => q({0} pks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksele),
						'other' => q({0} pks),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pks/cm),
						'other' => q({0} pks/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pks/cm),
						'other' => q({0} pks/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pks/c),
						'other' => q({0} pks/c),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pks/c),
						'other' => q({0} pks/c),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(j.a.),
						'other' => q({0} j.a.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(j.a.),
						'other' => q({0} j.a.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cyntymetry),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cyntymetry),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(stopy),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(stopy),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(cale),
						'other' => q({0} cala),
						'per' => q({0}/cal),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(cale),
						'other' => q({0} cala),
						'per' => q({0}/cal),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lata świetlne),
						'other' => q({0} lś),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lata świetlne),
						'other' => q({0} lś),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mile),
						'other' => q({0} mili),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mile),
						'other' => q({0} mili),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(Mm),
						'other' => q({0} Mm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(Mm),
						'other' => q({0} Mm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punkty),
						'other' => q({0} pkt.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punkty),
						'other' => q({0} pkt.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(prōmiynie Słōńca),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(prōmiynie Słōńca),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lks),
						'other' => q({0} lks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lks),
						'other' => q({0} lks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(jasność Słōńca),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(jasność Słōńca),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karaty),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karaty),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltōny),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltōny),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masa Ziymie),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masa Ziymie),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(fōnty),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(fōnty),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masa Słōńca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masa Słōńca),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(KM),
						'other' => q({0} KM),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(KM),
						'other' => q({0} KM),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(waty),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(waty),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(w.),
						'other' => q({0} w.),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(w.),
						'other' => q({0} w.),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akst.),
						'other' => q({0} akst.),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akst.),
						'other' => q({0} akst.),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(baryłki),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(baryłki),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(st³),
						'other' => q({0} st³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(st³),
						'other' => q({0} st³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(c³),
						'other' => q({0} c³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(c³),
						'other' => q({0} c³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jd³),
						'other' => q({0} jd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jd³),
						'other' => q({0} jd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ćwierćkworty),
						'other' => q({0} ćwkw.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ćwierćkworty),
						'other' => q({0} ćwkw.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ćwkwm.),
						'other' => q({0} ćwkwm.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ćwkwm.),
						'other' => q({0} ćwkwm.),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal ang.),
						'other' => q({0} gal ang.),
						'per' => q({0}/gal ang.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal ang.),
						'other' => q({0} gal ang.),
						'per' => q({0}/gal ang.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litry),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litry),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pōłkworty),
						'other' => q({0} pkw.),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pōłkworty),
						'other' => q({0} pkw.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pkwm.),
						'other' => q({0} pkwm.),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pkwm.),
						'other' => q({0} pkwm.),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kw.),
						'other' => q({0} kw.),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kw.),
						'other' => q({0} kw.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ł. stoł.),
						'other' => q({0} ł. stoł.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ł. stoł.),
						'other' => q({0} ł. stoł.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(łyżeczki),
						'other' => q({0} łyżeczki),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(łyżeczki),
						'other' => q({0} łyżeczki),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:niy|n|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} i {1}),
				2 => q({0} i {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
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
						'positive' => '¤ #,##0.00',
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
		'PLN' => {
			symbol => 'zł',
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
							'sty',
							'lut',
							'mar',
							'kwi',
							'moj',
							'czy',
							'lip',
							'siy',
							'wrz',
							'paź',
							'lis',
							'gru'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'stycznia',
							'lutego',
							'marca',
							'kwietnia',
							'moja',
							'czyrwca',
							'lipca',
							'siyrpnia',
							'września',
							'października',
							'listopada',
							'grudnia'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'S',
							'L',
							'M',
							'K',
							'M',
							'C',
							'L',
							'S',
							'W',
							'P',
							'L',
							'G'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'styczyń',
							'luty',
							'marzec',
							'kwieciyń',
							'moj',
							'czyrwiec',
							'lipiec',
							'siyrpiyń',
							'wrzesiyń',
							'październik',
							'listopad',
							'grudziyń'
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
						mon => 'pyń',
						tue => 'wto',
						wed => 'str',
						thu => 'szt',
						fri => 'piō',
						sat => 'sob',
						sun => 'niy'
					},
					short => {
						mon => 'pń',
						tue => 'wt',
						wed => 'st',
						thu => 'sz',
						fri => 'pt',
						sat => 'sb',
						sun => 'nd'
					},
					wide => {
						mon => 'pyńdziałek',
						tue => 'wtorek',
						wed => 'strzoda',
						thu => 'sztwortek',
						fri => 'piōntek',
						sat => 'sobota',
						sun => 'niydziela'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 's',
						fri => 'p',
						sat => 's',
						sun => 'n'
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
					abbreviated => {0 => 'I szr.',
						1 => 'II szr.',
						2 => 'III szr.',
						3 => 'IV szr.'
					},
					wide => {0 => 'I sztwierć roku',
						1 => 'II sztwierć roku',
						2 => 'III sztwierć roku',
						3 => 'IV sztwierć roku'
					},
				},
				'stand-alone' => {
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
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
					'am' => q{do połedniŏ},
					'pm' => q{po połedniu},
				},
				'wide' => {
					'am' => q{do połedniŏ},
					'pm' => q{po połedniu},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{do połedniŏ},
					'pm' => q{po połedniu},
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
				'0' => 'p.n.e.',
				'1' => 'n.e.'
			},
			wide => {
				'0' => 'przed naszōm erōm',
				'1' => 'naszyj ery'
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
			'short' => q{dd.MM.y G},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.y},
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
			'full' => q{{1} 'ô' {0}},
			'long' => q{{1} 'ô' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'ô' {0}},
			'long' => q{{1} 'ô' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d.MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.MM},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM.y G},
			yyyyMEd => q{E, d.MM.y G},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d.MM.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d.MM},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMM, 'tydz'. W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.MM},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Y, 'tydz'. w},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y GGGGG – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			MEd => {
				M => q{E, dd.MM–E, dd.MM},
				d => q{E, dd.MM–E, dd.MM},
			},
			MMMEd => {
				M => q{E, d MMM–E, d MMM},
				d => q{E, d MMM–E, d MMM},
			},
			MMMd => {
				M => q{d MMM–d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y–E, dd.MM.y},
				d => q{E, dd.MM.y–E, dd.MM.y},
				y => q{E, dd.MM.y–E, dd.MM.y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y–LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM y–E, d MMM y},
				d => q{E, d–E, d MMM y},
				y => q{E, d MMM y–E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y–LLLL y},
			},
			yMMMd => {
				M => q{d MMM–d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y–d MMM y},
			},
			yMd => {
				M => q{dd.MM–dd.MM.y},
				d => q{dd–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y GGGGG – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			MEd => {
				M => q{E, dd.MM–E, dd.MM},
				d => q{E, dd.MM–E, dd.MM},
			},
			MMMEd => {
				M => q{E, d MMM–E, d MMM},
				d => q{E, d MMM–E, d MMM},
			},
			MMMd => {
				M => q{d MMM–d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y–E, dd.MM.y},
				d => q{E, dd.MM.y–E, dd.MM.y},
				y => q{E, dd.MM.y–E, dd.MM.y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y–LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM y–E, d MMM y},
				d => q{E, d–E, d MMM y},
				y => q{E, d MMM y–E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y–LLLL y},
			},
			yMMMd => {
				M => q{d MMM–d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y–d MMM y},
			},
			yMd => {
				M => q{dd.MM–dd.MM.y},
				d => q{dd–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(czas: {0}),
		regionFormat => q({0} (latowy czas)),
		regionFormat => q({0} (sztandardowy czas)),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidżan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bandżul#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bużumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kair#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Kōnakry#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dżibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Al-Ujun#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Dżuba#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Chartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinszasa#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiszu#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndżamena#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nawakszut#,
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
			exemplarCity => q#Trypolis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#postrzodkowoafrykański czas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#wschodnioafrykański czas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#połedniowoafrykański czas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#zachodnioafrykański latowy czas#,
				'generic' => q#zachodnioafrykański czas#,
				'standard' => q#zachodnioafrykański sztandardowy czas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskański czas latowy#,
				'generic' => q#czas alaskański#,
				'standard' => q#alaskański czas sztandardowy#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#czas ałmacki latowy#,
				'generic' => q#czas ałmacki#,
				'standard' => q#czas ałmacki sztandardowy#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazōński latowy czas#,
				'generic' => q#amazōński czas#,
				'standard' => q#amazōński sztandardowy czas#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuńcion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Salvador#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajynna#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmany#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostaryka#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dōminika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salwador#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grynada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gwadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gwatymala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gujana#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceiō#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martynika#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Myndoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Mynominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksyk (miasto)#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mōntserrat#,
		},
		'America/New_York' => {
			exemplarCity => q#Nowy Jork#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Pōłnocno Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Pōłnocno Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Pōłnocno Dakota#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoryko#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélymy#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#czas postrzodkowoamerykański latowy#,
				'generic' => q#czas postrzodkowoamerykański#,
				'standard' => q#czas postrzodkowoamerykański sztandardowy#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#czas wschodnioamerykański latowy#,
				'generic' => q#czas wschodnioamerykański#,
				'standard' => q#czas wschodnioamerykański sztandardowy#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#czas gōrski latowy#,
				'generic' => q#czas gōrski#,
				'standard' => q#czas gōrski sztandardowy#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#czas pacyficzny latowy#,
				'generic' => q#czas pacyficzny#,
				'standard' => q#czas pacyficzny sztandardowy#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#latowy czas Anadyr#,
				'generic' => q#czas Anadyr#,
				'standard' => q#sztandardowy czas Anadyr#,
			},
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Aqtau' => {
			long => {
				'daylight' => q#czas auktaucki latowy#,
				'generic' => q#czas auktaucki#,
				'standard' => q#czas auktaucki sztandardowy#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#czas aktiubiński latowy#,
				'generic' => q#czas aktiubiński#,
				'standard' => q#czas aktiubiński sztandardowy#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Pōłwysep Arabski (latowy czas)#,
				'generic' => q#Pōłwysep Arabski#,
				'standard' => q#Pōłwysep Arabski (sztandardowy czas)#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyyn#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argyntyna (latowy czas)#,
				'generic' => q#Argyntyna#,
				'standard' => q#Argyntyna (sztandardowy czas)#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Argyntyna Zachodnio (latowy czas)#,
				'generic' => q#Argyntyna Zachodnio#,
				'standard' => q#Argyntyna Zachodnio (sztandardowy czas)#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armynijo (latowy czas)#,
				'generic' => q#Armynijo#,
				'standard' => q#Armynijo (sztandardowy czas)#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adyn#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Ałmaty#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktiubińsk#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aszchabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnauł#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biszkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Czyta#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolōmbo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaszek#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duszanbe#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrōn#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hōngkōng#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Kobdo#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkuck#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Dżakarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerozolima#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamczatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaczi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwejt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozja#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuźnieck#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosybirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Ômsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Ôral#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjōngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kustanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzyłorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Szanghaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sriedniekołymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taszkynt#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tōmsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ułan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumczi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Niera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Wiyntian#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Władywostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakuck#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterynburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erywań#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#czas atlantycki latowy#,
				'generic' => q#czas atlantycki#,
				'standard' => q#czas atlantycki sztandardowy#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azory#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Wyspy Kanaryjske#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Republika Zielōnego Przilōndka#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Wyspy Ôwcze#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madera#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Połedniowo#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Świynto Helyna#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#postrzodkowoaustralijski latowy czas#,
				'generic' => q#postrzodkowoaustralijski czas#,
				'standard' => q#postrzodkowoaustralijski sztandardowy czas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#postrzodkowo-zachodnioaustralijski latowy czas#,
				'generic' => q#postrzodkowo-zachodnioaustralijski czas#,
				'standard' => q#postrzodkowo-zachodnioaustralijski sztandardowy czas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#wschodnioaustralijski latowy czas#,
				'generic' => q#wschodnioaustralijski czas#,
				'standard' => q#wschodnioaustralijski sztandardowy czas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#zachodnioaustralijski latowy czas#,
				'generic' => q#zachodnioaustralijski czas#,
				'standard' => q#zachodnioaustralijski sztandardowy czas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbejdżan (latowy czas)#,
				'generic' => q#Azerbejdżan#,
				'standard' => q#Azerbejdżan (sztandardowy czas)#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azory (latowy czas)#,
				'generic' => q#Azory#,
				'standard' => q#Azory (sztandardowy czas)#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesz (latowy czas)#,
				'generic' => q#Bangladesz#,
				'standard' => q#Bangladesz (sztandardowy czas)#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliwijo#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília (latowy czas)#,
				'generic' => q#Brasília#,
				'standard' => q#Brasília (sztandardowy czas)#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Wyspy Zielōnego Przilōndka (latowy czas)#,
				'generic' => q#Wyspy Zielōnego Przilōndka#,
				'standard' => q#Wyspy Zielōnego Przilōndka (sztandardowy czas)#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Czamorro#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chile (latowy czas)#,
				'generic' => q#czas Chile#,
				'standard' => q#Chile (sztandardowy czas)#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chiny (latowy czas)#,
				'generic' => q#Chiny#,
				'standard' => q#Chiny (sztandardowy czas)#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Godnio Wyspa#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Wyspy Kokosowe#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbijo (latowy czas)#,
				'generic' => q#Kolumbijo#,
				'standard' => q#Kolumbijo (sztandardowy czas)#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Wyspy Cooka (latowy czas)#,
				'generic' => q#Wyspy Cooka#,
				'standard' => q#Wyspy Cooka (sztandardowy czas)#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba (latowy czas)#,
				'generic' => q#Kuba#,
				'standard' => q#Kuba (sztandardowy czas)#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Timor Wschodni#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Wyspa Wielkanocno (latowy czas)#,
				'generic' => q#Wyspa Wielkanocno#,
				'standard' => q#Wyspa Wielkanocno (sztandardowy czas)#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekwador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#uniwersalny koordynowany czas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Niyznōme miasto#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachań#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atyny#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratysława#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruksela#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukareszt#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeszt#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen am Hochrhein#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kiszyniōw#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopynhaga#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irlandyjo (latowy czas)#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Wyspa Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stambuł#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijōw#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirow#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbōna#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lublana#,
		},
		'Europe/London' => {
			exemplarCity => q#Lōndyn#,
			long => {
				'daylight' => q#Brytyjski latowy czas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksymburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madryt#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maarianhamina#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mińsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mōnako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ôslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paryż#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Ryga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rzym#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajewo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratōw#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Symferopol#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Sztokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanowsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watykan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wiedyń#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilno#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wołgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagrzeb#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurych#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#postrzodkowoeuropejski latowy czas#,
				'generic' => q#postrzodkowoeuropejski czas#,
				'standard' => q#postrzodkowoeuropejski sztandardowy czas#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#wschodnioeuropejski latowy czas#,
				'generic' => q#wschodnioeuropejski czas#,
				'standard' => q#wschodnioeuropejski sztandardowy czas#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#wschodnioeuropejski dalszy czas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#zachodnioeuropejski latowy czas#,
				'generic' => q#zachodnioeuropejski czas#,
				'standard' => q#zachodnioeuropejski sztandardowy czas#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandy (latowy czas)#,
				'generic' => q#Falklandy#,
				'standard' => q#Falklandy (sztandardowy czas)#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidżi (latowy czas)#,
				'generic' => q#Fidżi#,
				'standard' => q#Fidżi (sztandardowy czas)#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Gujana Francusko#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Francuske Terytoria Połedniowe i Antarktyczne#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#uniwersalnego czasu#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#czas Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Wyspy Gambiera#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzyjo (latowy czas)#,
				'generic' => q#Gruzyjo#,
				'standard' => q#Gruzyjo (sztandardowy czas)#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertowe Wyspy#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Grynlandyjo Wschodnia (latowy czas)#,
				'generic' => q#Grynlandyjo Wschodnia#,
				'standard' => q#Grynlandyjo Wschodnia (sztandardowy czas)#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Grynlandyjo Zachodnio (latowy czas)#,
				'generic' => q#Grynlandyjo Zachodnio#,
				'standard' => q#Grynlandyjo Zachodnio (sztandardowy czas)#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Zatoka Perska#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gujana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaje-Aleuty (latowy czas)#,
				'generic' => q#Hawaje-Aleuty#,
				'standard' => q#Hawaje-Aleuty (sztandardowy czas)#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hōngkōng (latowy czas)#,
				'generic' => q#Hōngkōng#,
				'standard' => q#Hōngkōng (sztandardowy czas)#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Kobdo (latowy czas)#,
				'generic' => q#Kobdo#,
				'standard' => q#Kobdo (sztandardowy czas)#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indyjski sztandardowy czas#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarywa#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Czagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Godnio Wyspa#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Wyspy Kokosowe#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Kōmory#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelenowe Wyspy#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediwy#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Majotta#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ôcean Indyjski#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indochiński czas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Indōnezyjo Postrzodkowo#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Indōnezyjo Wschodnio#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Indōnezyjo Zachodnio#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkuck (latowy czas)#,
				'generic' => q#Irkuck#,
				'standard' => q#Irkuck (sztandardowy czas)#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izrael (latowy czas)#,
				'generic' => q#Izrael#,
				'standard' => q#Izrael (sztandardowy czas)#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japōnijo (latowy czas)#,
				'generic' => q#Japōnijo#,
				'standard' => q#Japōnijo (sztandardowy czas)#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#czas Pietropawłowsk Kamczacki latowy#,
				'generic' => q#czas Pietropawłowsk Kamczacki#,
				'standard' => q#sztandardowy czas Pietropawłowsk Kamczacki#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kazachstan Wschodni#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kazachstan Zachodni#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk (latowy czas)#,
				'generic' => q#Krasnojarsk#,
				'standard' => q#Krasnojarsk (sztandardowy czas)#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe (latowy czas)#,
				'generic' => q#Lord Howe#,
				'standard' => q#Lord Howe (sztandardowy czas)#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezyjo#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediwy#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markizy#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Wyspy Marshalla#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksyk (czas pacyficzny latowy)#,
				'generic' => q#Meksyk (czas pacyficzny)#,
				'standard' => q#Meksyk (czas pacyficzny sztandardowy)#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ułan Bator (latowy czas)#,
				'generic' => q#Ułan Bator#,
				'standard' => q#Ułan Bator (sztandardowy czas)#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskwa (latowy)#,
				'generic' => q#Moskwa#,
				'standard' => q#Moskwa (sztandardowy)#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanma#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nowo Kaledōnijo (latowy czas)#,
				'generic' => q#Nowo Kaledōnijo#,
				'standard' => q#Nowo Kaledōnijo (sztandardowy czas)#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nowo Zelandyjo (latowy czas)#,
				'generic' => q#Nowo Zelandyjo#,
				'standard' => q#Nowo Zelandyjo (sztandardowy czas)#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nowo Fundlandyjo (latowy czas)#,
				'generic' => q#Nowo Fundlandyjo#,
				'standard' => q#Nowo Fundlandyjo (sztandardowy czas)#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha (latowy czas)#,
				'generic' => q#Fernando de Noronha#,
				'standard' => q#Fernando de Noronha (sztandardowy czas)#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosybirsk (latowy czas)#,
				'generic' => q#Nowosybirsk#,
				'standard' => q#Nowosybirsk (sztandardowy czas)#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ômsk (latowy czas)#,
				'generic' => q#Ômsk#,
				'standard' => q#Ômsk (sztandardowy czas)#,
			},
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville’owa Wyspa#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Wyspa Wielkanocno#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidżi#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Wyspy Gambiera#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markizy#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea#,
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Nowo Gwinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragwaj (latowy czas)#,
				'generic' => q#Paragwaj#,
				'standard' => q#Paragwaj (sztandardowy czas)#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru (latowy czas)#,
				'generic' => q#czas Peru#,
				'standard' => q#Peru (sztandardowy czas)#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipiny (latowy czas)#,
				'generic' => q#Filipiny#,
				'standard' => q#Filipiny (sztandardowy czas)#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fyniks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre i Miquelon (latowy czas)#,
				'generic' => q#Saint-Pierre i Miquelon#,
				'standard' => q#Saint-Pierre i Miquelon (sztandardowy czas)#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjōngjang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#czas kyzyłordzki latowy#,
				'generic' => q#czas kyzyłordzki#,
				'standard' => q#czas kyzyłordzki sztandardowy#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin (latowy czas)#,
				'generic' => q#Sachalin#,
				'standard' => q#Sachalin (sztandardowy czas)#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#czas Samara latowy#,
				'generic' => q#czas Samara#,
				'standard' => q#sztandardowy czas Samara#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seszele#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Wyspy Salōmōna#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Georgia Połedniowo#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tajpej (latowy czas)#,
				'generic' => q#Tajpej#,
				'standard' => q#Tajpej (sztandardowy czas)#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadżykistan#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tōnga (latowy czas)#,
				'generic' => q#Tōnga#,
				'standard' => q#Tōnga (sztandardowy czas)#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmynistan (latowy czas)#,
				'generic' => q#Turkmynistan#,
				'standard' => q#Turkmynistan (sztandardowy czas)#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugwaj (latowy czas)#,
				'generic' => q#Urugwaj#,
				'standard' => q#Urugwaj (sztandardowy czas)#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wynezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Władywostok (latowy czas)#,
				'generic' => q#Władywostok#,
				'standard' => q#Władywostok (sztandardowy czas)#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wołgograd (latowy czas)#,
				'generic' => q#Wołgograd#,
				'standard' => q#Wołgograd (sztandardowy czas)#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis i Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakuck (latowy czas)#,
				'generic' => q#Jakuck#,
				'standard' => q#Jakuck (sztandardowy czas)#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterynburg (latowy czas)#,
				'generic' => q#Jekaterynburg#,
				'standard' => q#Jekaterynburg (sztandardowy czas)#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#czas jukōński#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
