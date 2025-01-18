=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Scn - Package for language Sicilian

=cut

package Locale::CLDR::Locales::Scn;
# This file auto generated from Data\common\main\scn.xml
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
				'aa' => 'afar',
 				'ab' => 'abkhasu',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ak' => 'akan',
 				'am' => 'amàricu',
 				'an' => 'aragunisi',
 				'apc' => 'àrabbu livantinu di tramuntana',
 				'ar' => 'àrabbu',
 				'ar_001' => 'àrabbu nadaru mudernu',
 				'arn' => 'mapuche',
 				'as' => 'assamisi',
 				'asa' => 'asu',
 				'ast' => 'asturianu',
 				'az' => 'azzeru',
 				'ba' => 'bashkir',
 				'bal' => 'baluchi',
 				'bas' => 'basaa',
 				'be' => 'belurrussu',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bg' => 'bùrgaru',
 				'bgc' => 'haryanvi',
 				'bho' => 'bhojipuri',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bangladisi',
 				'br' => 'brètuni',
 				'brx' => 'bodu',
 				'bs' => 'busnìacu',
 				'bss' => 'akoose',
 				'byn' => 'blin',
 				'ca' => 'catalanu',
 				'cad' => 'caddu',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'cicenu',
 				'ceb' => 'cebbuanu',
 				'cgg' => 'chiga',
 				'cho' => 'choctaw',
 				'chr' => 'cherokee',
 				'cic' => 'chickasaw',
 				'ckb' => 'curdu cintrali',
 				'ckb@alt=variant' => 'curdu Sorani',
 				'co' => 'corsu',
 				'cs' => 'cecu',
 				'csw' => 'swampy cree',
 				'cu' => 'slavu dâ cresia',
 				'cv' => 'ciuvasciu',
 				'cy' => 'gallisi',
 				'da' => 'danisi',
 				'de' => 'tidiscu',
 				'de_AT' => 'tidiscu austrìacu',
 				'de_CH' => 'tidiscu autu sbìzziru',
 				'doi' => 'dogri',
 				'dsb' => 'sorbu suttanu',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'el' => 'grecu',
 				'en' => 'ngrisi',
 				'en_AU' => 'ngrisi australianu',
 				'en_CA' => 'ngrisi canadisi',
 				'en_GB' => 'ngrisi britànnicu',
 				'en_US' => 'ngrisi miricanu',
 				'eo' => 'spirantu',
 				'es' => 'spagnolu',
 				'es_419' => 'spagnolu dâ mèrica latina',
 				'es_ES' => 'spagnolu eurupeu',
 				'es_MX' => 'spagnolu missicanu',
 				'et' => 'èstuni',
 				'eu' => 'bascu',
 				'ewo' => 'ewondo',
 				'fa' => 'pirsianu',
 				'ff' => 'fula',
 				'fi' => 'fillannisi',
 				'fil' => 'filippinu',
 				'fo' => 'faruisi',
 				'fr' => 'francisi',
 				'fr_CA' => 'francisi canadisi',
 				'fr_CH' => 'francisi sbìzziru',
 				'frc' => 'francisi Cajun',
 				'fur' => 'friulanu',
 				'fy' => 'frìsuni uccidintali',
 				'ga' => 'irlannisi',
 				'gaa' => 'ga',
 				'gd' => 'gaèlicu scuzzisi',
 				'gez' => 'geez',
 				'gl' => 'galizzianu',
 				'gn' => 'guarani',
 				'gsw' => 'tidiscu sbìzziru',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'mannisi',
 				'ha' => 'hausa',
 				'haw' => 'hawaiianu',
 				'he' => 'ebbràicu',
 				'hi' => 'innianu',
 				'hi_Latn' => 'innianu (latinu)',
 				'hi_Latn@alt=variant' => 'innianu ngrisi',
 				'hnj' => 'hmong njua',
 				'hr' => 'cruatu',
 				'hsb' => 'surbu supranu',
 				'hu' => 'unghirisi',
 				'hy' => 'armenu',
 				'ia' => 'ntirlingua',
 				'id' => 'innunisianu',
 				'ie' => 'ntirlingui',
 				'ig' => 'igbo',
 				'io' => 'idu',
 				'is' => 'islannisi',
 				'it' => 'talianu',
 				'iu' => 'inuktitut',
 				'ja' => 'giappunisi',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'giavanisi',
 				'ka' => 'giurgianu',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabyle',
 				'kaj' => 'jiu',
 				'kam' => 'kamba',
 				'kde' => 'makonde',
 				'kea' => 'capuvirdianu',
 				'ken' => 'kenyang',
 				'kgp' => 'kaingang',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kk' => 'kazaku',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kn' => 'kannada',
 				'ko' => 'curianu',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'ks' => 'kashmiri',
 				'ksf' => 'bafia',
 				'ksh' => 'culunisi',
 				'ku' => 'curdu',
 				'kw' => 'còrnicu',
 				'kxv' => 'kuvi',
 				'ky' => 'kirghizu',
 				'la' => 'latinu',
 				'lag' => 'langi',
 				'lb' => 'lussimmurghisi',
 				'lg' => 'ganda',
 				'lij' => 'lìguri',
 				'lkt' => 'lakota',
 				'lld' => 'ild',
 				'lmo' => 'lummardu',
 				'ln' => 'lingala',
 				'lo' => 'lau',
 				'lou' => 'criolu dâ Louisiana',
 				'lt' => 'lituanu',
 				'ltg' => 'latgallisi',
 				'lu' => 'luba-katanga',
 				'luy' => 'luyia',
 				'lv' => 'lèttuni',
 				'mai' => 'maithili',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'mer' => 'meru',
 				'mfe' => 'murisianu',
 				'mg' => 'margasciu',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'metaʼ',
 				'mhn' => 'muchenu',
 				'mi' => 'māori',
 				'mic' => 'mi\'kmaw',
 				'mk' => 'macèduni',
 				'ml' => 'malayalam',
 				'mn' => 'mòngulu',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mr' => 'marathi',
 				'ms' => 'malisi',
 				'mt' => 'mautisi',
 				'mua' => 'mundang',
 				'mul' => 'assai lingui',
 				'mus' => 'muscogee',
 				'my' => 'burmisi',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'naq' => 'nama',
 				'nb' => 'nurviggisi Bokmål',
 				'nds' => 'tidiscu suttanu',
 				'nds_NL' => 'sàssuni suttanu',
 				'ne' => 'nipalisi',
 				'nl' => 'ulannisi',
 				'nl_BE' => 'ciammingu',
 				'nmg' => 'kwasio',
 				'nn' => 'nurviggisi Nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'nurviggisi',
 				'nqo' => 'n’ko',
 				'nv' => 'navajo',
 				'oc' => 'uccitanu',
 				'or' => 'odia',
 				'pa' => 'punjabi',
 				'pcm' => 'pidgin niggirianu',
 				'pl' => 'pulaccu',
 				'prg' => 'prussianu',
 				'ps' => 'pashto',
 				'pt' => 'purtughisi',
 				'pt_BR' => 'purtughisi brasilianu',
 				'pt_PT' => 'purtughisi eurupeu',
 				'qu' => 'quechua',
 				'quc' => 'kʼicheʼ',
 				'raj' => 'rajasthani',
 				'rm' => 'rumanciu',
 				'ro' => 'rumenu',
 				'ro_MD' => 'murdavu',
 				'ru' => 'russu',
 				'rw' => 'kinyarwanda',
 				'sa' => 'sàscritu',
 				'sah' => 'yakut',
 				'sat' => 'santali',
 				'sc' => 'sardu',
 				'scn' => 'sicilianu',
 				'sd' => 'sindhi',
 				'ses' => 'koyraboro senni',
 				'si' => 'sinhala',
 				'sk' => 'sluvaccu',
 				'sl' => 'sluvenu',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'so' => 'sòmalu',
 				'sq' => 'arbanisi',
 				'sr' => 'serbu',
 				'su' => 'sunnanisi',
 				'sv' => 'svidisi',
 				'sw' => 'swahili',
 				'syr' => 'sirìacu',
 				'szl' => 'silisianu',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tg' => 'tajik',
 				'th' => 'tailannisi',
 				'ti' => 'tigrinya',
 				'tk' => 'turkmenu',
 				'to' => 'tunganu',
 				'tr' => 'turcu',
 				'tt' => 'tàtaru',
 				'tzm' => 'tamazight di l’Atlanti Cintrali',
 				'ug' => 'uyghur',
 				'uk' => 'ucrainu',
 				'und' => 'lingua scanusciuta',
 				'ur' => 'urdu',
 				'uz' => 'uzbeku',
 				'vec' => 'vènitu',
 				'vi' => 'vietnamisi',
 				'vmw' => 'makhuwa',
 				'vo' => 'volapük',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'xnr' => 'kangri',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantunisi',
 				'yue@alt=menu' => 'cinisi cantunisi',
 				'za' => 'zhuang',
 				'zh' => 'cinisi',
 				'zh@alt=menu' => 'cinisi, mannarinu',
 				'zh_Hans' => 'cinisi simprificatu',
 				'zh_Hans@alt=long' => 'cinisi mannarinu simprificatu',
 				'zh_Hant' => 'cinisi tradizziunali',
 				'zh_Hant@alt=long' => 'cinisi mannarinu tradizziunali',
 				'zu' => 'zulu',
 				'zxx' => 'nuḍḍu cuntinutu linguìsticu',

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
			'Adlm' => 'adlam',
 			'Arab' => 'àrabbu',
 			'Aran' => 'nastaliq',
 			'Armn' => 'armenu',
 			'Beng' => 'bangla',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cakm' => 'chakma',
 			'Cans' => 'sillabbazzioni nurmalizzata di l’abburìggini canadisi',
 			'Cher' => 'cherokee',
 			'Cyrl' => 'cirìllicu',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etìupi',
 			'Geor' => 'giurgianu',
 			'Grek' => 'grecu',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'Han cu bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'simprificatu',
 			'Hans@alt=stand-alone' => 'Han simprificatu',
 			'Hant' => 'tradizziunali',
 			'Hant@alt=stand-alone' => 'Han tradizziunali',
 			'Hebr' => 'ebbràicu',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'sillabbari giappunisi',
 			'Jamo' => 'jamo',
 			'Jpan' => 'giappunisi',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'curianu',
 			'Laoo' => 'lao',
 			'Latn' => 'latinu',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mòngulu',
 			'Mtei' => 'meitei mayek',
 			'Mymr' => 'myanmar',
 			'Nkoo' => 'n’ko',
 			'Olck' => 'ol chiki',
 			'Orya' => 'odia',
 			'Rohg' => 'hanifi',
 			'Sinh' => 'sinhala',
 			'Sund' => 'sunnanisi',
 			'Syrc' => 'sirìacu',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagh',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailannisi',
 			'Tibt' => 'tibbitanu',
 			'Vaii' => 'vai',
 			'Yiii' => 'yi',
 			'Zmth' => 'nutazzioni matimàtica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'sìmmuli',
 			'Zxxx' => 'nun scrittu',
 			'Zyyy' => 'cumuni',
 			'Zzzz' => 'scrittura scanusciuta',

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
			'001' => 'Munnu',
 			'002' => 'Àfrica',
 			'003' => 'Mèrica di tramuntana cuntinintali',
 			'005' => 'Mèrica di sciroccu',
 			'009' => 'Uciània',
 			'011' => 'Àfrica punintina',
 			'013' => 'Mèrica cintrali',
 			'014' => 'Àfrica livantina',
 			'015' => 'Àfrica di tramuntana',
 			'017' => 'Àfrica di menzu',
 			'018' => 'Àfrica di sciroccu',
 			'019' => 'Mèrichi',
 			'021' => 'Mèrica di tramuntana',
 			'029' => 'Caràibbi',
 			'030' => 'Asia livantina',
 			'034' => 'Asia di sciroccu',
 			'035' => 'Asia di sciroccu-livantina',
 			'039' => 'Europa di sciroccu',
 			'053' => 'Australasia',
 			'054' => 'Milanesia',
 			'057' => 'Riggiuni dâ Micrunesia',
 			'061' => 'Pulinesia',
 			'142' => 'Asia',
 			'143' => 'Asia cintrali',
 			'145' => 'Asia punintina',
 			'150' => 'Europa',
 			'151' => 'Europa livantina',
 			'154' => 'Europa di tramuntana',
 			'155' => 'Europa punintina',
 			'202' => 'Àfrica sutta-sahariana',
 			'419' => 'Mèrica latina',
 			'AC' => 'Ìsula d’Ascinziuni',
 			'AD' => 'Annorra',
 			'AE' => 'Emirati Àrabbi Junciuti',
 			'AF' => 'Afghànistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Arbanìa',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antàrtidi',
 			'AR' => 'Argintina',
 			'AS' => 'Samoa Miricani',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Ìsuli Åland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia e Herzegòvina',
 			'BB' => 'Barbados',
 			'BD' => 'Bàngladesh',
 			'BE' => 'Bergiu',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Burgarìa',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Birmuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bulivia',
 			'BQ' => 'Caràibbi ulannisi',
 			'BR' => 'Brasili',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Ìsula Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belurussia',
 			'BZ' => 'Bilisi',
 			'CA' => 'Cànada',
 			'CC' => 'Ìsuli Cocos (Keeling)',
 			'CD' => 'Congu - Kinshasa',
 			'CD@alt=variant' => 'Congu (RDC)',
 			'CF' => 'Ripùbblica Centrafricana',
 			'CG' => 'Congu - Brazzaville',
 			'CG@alt=variant' => 'Congu (Ripùbblica)',
 			'CH' => 'Sbìzzira',
 			'CI' => 'Custa d’Avoriu',
 			'CK' => 'Ìsuli Cook',
 			'CL' => 'Cili',
 			'CM' => 'Càmerun',
 			'CN' => 'Cina',
 			'CO' => 'Culommia',
 			'CP' => 'Ìsula di Clipperton',
 			'CR' => 'Custa Rica',
 			'CU' => 'Cubba',
 			'CV' => 'Capu Virdi',
 			'CW' => 'Curaçao',
 			'CX' => 'Ìsula di Natali',
 			'CY' => 'Cipru',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Ripùbblica Ceca',
 			'DE' => 'Girmania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Gibbuti',
 			'DK' => 'Danimarca',
 			'DM' => 'Dumìnica',
 			'DO' => 'Ripùbblica Duminicana',
 			'DZ' => 'Algirìa',
 			'EA' => 'Ceuta e Miliḍḍa',
 			'EC' => 'Ècuador',
 			'EE' => 'Estonia',
 			'EG' => 'Eggittu',
 			'EH' => 'Sahara punintinu',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Uniuni Eurupea',
 			'EZ' => 'Zuna Euru',
 			'FI' => 'Fillannia',
 			'FJ' => 'Figi',
 			'FK' => 'Ìsuli Falkland',
 			'FK@alt=variant' => 'Ìsuli Falkland (Ìsuli Marvini)',
 			'FM' => 'Micrunisia',
 			'FO' => 'Ìsuli Faroe',
 			'FR' => 'Franza',
 			'GA' => 'Gabon',
 			'GB' => 'Regnu Junciutu',
 			'GB@alt=short' => 'RJ',
 			'GD' => 'Grenada',
 			'GE' => 'Giorgia',
 			'GF' => 'Guiana Francisi',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibbirterra',
 			'GL' => 'Gruillannia',
 			'GM' => 'Gammia',
 			'GN' => 'Guinìa',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinìa Equaturiali',
 			'GR' => 'Grecia',
 			'GS' => 'Giorgia di sciroccu e Ìsuli Sandwich australi',
 			'GT' => 'Guatimala',
 			'GU' => 'Guam',
 			'GW' => 'Guinìa-Bissau',
 			'GY' => 'Guiana',
 			'HK' => 'Hong Kong RAS dâ Cina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ìsuli Heard e McDonald',
 			'HN' => 'Hunnuras',
 			'HR' => 'Cruazzia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarìa',
 			'IC' => 'Ìsuli Canari',
 			'ID' => 'Innunesia',
 			'IE' => 'Irlanna',
 			'IL' => 'Isdraeli',
 			'IM' => 'Ìsula di Man',
 			'IN' => 'Innia',
 			'IO' => 'Tirritoriu Ucianicu di l’Innia Britànnica',
 			'IO@alt=chagos' => 'Arcipèlagu Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islanna',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamàica',
 			'JO' => 'Giurdania',
 			'JP' => 'Giappuni',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzistan',
 			'KH' => 'Camboggia',
 			'KI' => 'Kiribati',
 			'KM' => 'Còmoros',
 			'KN' => 'S. Kitts e Nevis',
 			'KP' => 'Curìa di Tramuntana',
 			'KR' => 'Curìa di Sciroccu',
 			'KW' => 'Kuwait',
 			'KY' => 'Ìsuli Cayman',
 			'KZ' => 'Kazzàkistan',
 			'LA' => 'Laos',
 			'LB' => 'Lìbbanu',
 			'LC' => 'Santa Lucìa',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libberia',
 			'LS' => 'Lisothu',
 			'LT' => 'Lituania',
 			'LU' => 'Lussimmurgu',
 			'LV' => 'Littonia',
 			'LY' => 'Libbia',
 			'MA' => 'Maroccu',
 			'MC' => 'Mònacu',
 			'MD' => 'Murdova',
 			'ME' => 'Muntinegru',
 			'MF' => 'San Martinu',
 			'MG' => 'Madagascàr',
 			'MH' => 'Ìsuli Marshall',
 			'MK' => 'Macidonia di tramuntana',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mungolia',
 			'MO' => 'Macau RAS dâ Cina',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Ìsuli Marianna di Tramuntana',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Munzirratu',
 			'MT' => 'Mauta',
 			'MU' => 'Mauritius',
 			'MV' => 'Mardivi',
 			'MW' => 'Malawi',
 			'MX' => 'Mèssicu',
 			'MY' => 'Malesia',
 			'MZ' => 'Muzzammicu',
 			'NA' => 'Namibbia',
 			'NC' => 'Nova Calidonia',
 			'NE' => 'Niger',
 			'NF' => 'Ìsula Norfolk',
 			'NG' => 'Niggeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paisi Vasci',
 			'NO' => 'Nurveggia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zilannia',
 			'NZ@alt=variant' => 'Aotearoa Nova Zilannia',
 			'OM' => 'Oman',
 			'PA' => 'Pànama',
 			'PE' => 'Pirù',
 			'PF' => 'Pulinisia Francisi',
 			'PG' => 'Papua Nova Guinìa',
 			'PH' => 'Filippini',
 			'PK' => 'Pàkistan',
 			'PL' => 'Pulonia',
 			'PM' => 'S. Pierre e Miquelon',
 			'PN' => 'Ìsuli Pitcairn',
 			'PR' => 'Portu Ricu',
 			'PS' => 'Tirritori Palistinesi',
 			'PS@alt=short' => 'Palistina',
 			'PT' => 'Purtugallu',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Uciània di fora',
 			'RE' => 'Réunion',
 			'RO' => 'Rumanìa',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Ruanna',
 			'SA' => 'Arabbia Saudita',
 			'SB' => 'Ìsuli Salumuni',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sbezzia',
 			'SG' => 'Singapuri',
 			'SH' => 'Sant’Èlina',
 			'SI' => 'Sluvenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Sluvacchia',
 			'SL' => 'Sierra Liuni',
 			'SM' => 'San Marinu',
 			'SN' => 'Sènigal',
 			'SO' => 'Sumalia',
 			'SR' => 'Surinami',
 			'SS' => 'Sudan di sciroccu',
 			'ST' => 'São Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazilannia',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Ìsuli Turks e Càicos',
 			'TD' => 'Chad',
 			'TF' => 'Tirritori Francisi di Sciroccu',
 			'TG' => 'Togu',
 			'TH' => 'Tailannia',
 			'TJ' => 'Tajìkistan',
 			'TK' => 'Tukilau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor di Livanti',
 			'TM' => 'Turkmènistan',
 			'TN' => 'Tunisìa',
 			'TO' => 'Tonga',
 			'TR' => 'Turchìa',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganna',
 			'UM' => 'Ìsuli Miricani di Fora',
 			'UN' => 'Nazziuna Junciuti',
 			'US' => 'Stati Junciuti',
 			'US@alt=short' => 'SJM',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbèkistan',
 			'VA' => 'Città dû Vaticanu',
 			'VC' => 'S. Vincent e Grenadine',
 			'VE' => 'Vinizzuela',
 			'VG' => 'Ìsuli Vìrgini Britànnichi',
 			'VI' => 'Ìsuli Vìrgini Miricani',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Accenti fausi',
 			'XB' => 'Bidirizziunali fausu',
 			'XK' => 'Kòssuvu',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Africa di sciroccu',
 			'ZM' => 'Zammia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Riggiuni scanusciuta',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Calannariu',
 			'ms' => 'Sistema di misura',
 			'numbers' => 'Nùmmari',

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
 				'buddhist' => q{Calannariu buddista},
 				'chinese' => q{Calannariu cinisi},
 				'coptic' => q{Calannariu coptu},
 				'dangi' => q{Calannariu dangi},
 				'ethiopic' => q{Calannariu etìupi},
 				'ethiopic-amete-alem' => q{Calannariu etìupi Amete-Alem},
 				'gregorian' => q{Calannariu grigurianu},
 				'hebrew' => q{Calannariu ebbràicu},
 				'islamic' => q{Calannariu slàmicu},
 				'islamic-civil' => q{Calannariu slàmicu civili},
 				'islamic-umalqura' => q{Calannariu slàmicu Umm Al-Qura},
 				'iso8601' => q{Calannariu ISO-8601},
 				'japanese' => q{Calannariu giappunisi},
 				'persian' => q{Calannariu pirsianu},
 				'roc' => q{Calannariu minguo},
 			},
 			'collation' => {
 				'standard' => q{Arringu Pridifinitu},
 			},
 			'ms' => {
 				'metric' => q{Sistema mètricu},
 				'uksystem' => q{Sistema mpiriali},
 				'ussystem' => q{Sistema miricanu},
 			},
 			'numbers' => {
 				'latn' => q{Nùmmari di Punenti},
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
			'metric' => q{mètricu},
 			'UK' => q{ngrisi},
 			'US' => q{miricanu},

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
 			'script' => 'Scrittura: {0}',
 			'region' => 'Riggiuni: {0}',

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
			auxiliary => qr{[ç đ éë ə ḥ k š w x y]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'Z'],
			main => qr{[aàâ b c dḍ eèê f g h iìî j l m n oòô p q r s t uùû v z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'Z'], };
},
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
					# Long Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(dirizzioni),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'north' => q({0}T),
						'west' => q({0}P),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:se|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} e {1}),
				2 => q({0} e {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => '0 migghiaru',
					'other' => '0 mila',
				},
				'10000' => {
					'one' => '00 mila',
					'other' => '00 mila',
				},
				'100000' => {
					'one' => '000 mila',
					'other' => '000 mila',
				},
				'1000000' => {
					'one' => '0 miliuni',
					'other' => '0 miliuna',
				},
				'10000000' => {
					'one' => '00 miliuna',
					'other' => '00 miliuna',
				},
				'100000000' => {
					'one' => '000 miliuna',
					'other' => '000 miliuna',
				},
				'1000000000' => {
					'one' => '0 miliardu',
					'other' => '0 miliardi',
				},
				'10000000000' => {
					'one' => '00 miliardi',
					'other' => '00 miliardi',
				},
				'100000000000' => {
					'one' => '000 miliardi',
					'other' => '000 miliardi',
				},
				'1000000000000' => {
					'one' => '0 biliuni',
					'other' => '0 biliuna',
				},
				'10000000000000' => {
					'one' => '00 biliuna',
					'other' => '00 biliuna',
				},
				'100000000000000' => {
					'one' => '000 biliuna',
					'other' => '000 biliuna',
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
			display_name => {
				'currency' => q(Dirham di l’Emirati Àrabbi Junciuti),
				'one' => q(dirham EAJ),
				'other' => q(dirham EAJ),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani afghanu),
				'one' => q(afghani afghanu),
				'other' => q(afghani afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek arbanisi),
				'one' => q(lek arbanisi),
				'other' => q(lek arbanisi),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram armenu),
				'one' => q(dram armenu),
				'other' => q(dram armeni),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Ciurinu di l’Antiḍḍi Ulannisi),
				'one' => q(ciurinu di l’Antiḍḍi Ulannisi),
				'other' => q(ciurini di l’Antiḍḍi Ulannisi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza angulisi),
				'one' => q(kwanza angulisi),
				'other' => q(kwanza angulisi),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Pesu argintinu),
				'one' => q(pesu argintinu),
				'other' => q(pesi argintini),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dòllaru australianu),
				'one' => q(dòllaru australianu),
				'other' => q(dòllari australiani),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Ciurinu d’Arubba),
				'one' => q(ciurinu d’Arubba),
				'other' => q(ciurini d’Arubba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat azzeru),
				'one' => q(manat azzeru),
				'other' => q(manat azzeri),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marcu cummirtìbbili dâ Bosnia-Herzegòvina),
				'one' => q(marcu cummirtìbbili dâ Bosnia-Herzegòvina),
				'other' => q(marchi cummirtìbbili dâ Bosnia-Herzegòvina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dòllaru dî Barbados),
				'one' => q(dòllaru dî Barbados),
				'other' => q(dòllari dî Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka dû Bàngladesh),
				'one' => q(taka dû Bàngladesh),
				'other' => q(taka dû Bàngladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev bùrgaru),
				'one' => q(lev bùrgaru),
				'other' => q(lev bùrgari),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dìnaru dû Bahrain),
				'one' => q(dìnaru dû Bahrain),
				'other' => q(dìnari dû Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Francu dû Burundi),
				'one' => q(francu dû Burundi),
				'other' => q(franchi dû Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dòllaru dî Birmuda),
				'one' => q(dòllaru dî Birmuda),
				'other' => q(dòllari dî Birmuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dòllaru dû Brunei),
				'one' => q(dòllaru dû Brunei),
				'other' => q(dòllari dû Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bulivianu),
				'one' => q(bulivianu),
				'other' => q(buliviani),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Riali brasilianu),
				'one' => q(riali brasilianu),
				'other' => q(riali brasiliani),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dòllaru dî Bahamas),
				'one' => q(dòllaru dî Bahamas),
				'other' => q(dòllari dî Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum butanisi),
				'one' => q(ngultrum butanisi),
				'other' => q(ngultrum butanisi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula dû Botswana),
				'one' => q(pula dû Botswana),
				'other' => q(pula dû Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubblu belurrussu),
				'one' => q(rubblu belurrussu),
				'other' => q(rubbli belurrussi),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dòllaru dû Bilisi),
				'one' => q(dòllaru dû Bilisi),
				'other' => q(dòllari dû Bilisi),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dòllaru canadisi),
				'one' => q(dòllaru canadisi),
				'other' => q(dòllari canadisi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Francu cungulisi),
				'one' => q(francu cungulisi),
				'other' => q(franchi cungulisi),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Francu sbìzziru),
				'one' => q(francu sbìzziru),
				'other' => q(franchi sbìzziri),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Pesu cilenu),
				'one' => q(pesu cilenu),
				'other' => q(pesi cileni),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan cinisi \(di fora\)),
				'one' => q(yuan cinisi \(di fora\)),
				'other' => q(yuan cinisi \(di fora\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan cinisi),
				'one' => q(yuan cinisi),
				'other' => q(yuan cinisi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Pesu culummianu),
				'one' => q(pesu culummianu),
				'other' => q(pesi culummiani),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Culón dâ Custa Rica),
				'one' => q(culón dâ Custa Rica),
				'other' => q(culoni dâ Custa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Pesu cubbanu cummirtìbbili),
				'one' => q(pesu cubbanu cummirtìbbili),
				'other' => q(pesi cubbani cummirtìbbili),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Pesu cubbanu),
				'one' => q(pesu cubbanu),
				'other' => q(pesi cubbani),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Scudu capuvirdisi),
				'one' => q(scudu capuvirdisi),
				'other' => q(scudi capuvirdisi),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Curuna ceca),
				'one' => q(curuna ceca),
				'other' => q(curuni cechi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Francu di Gibbuti),
				'one' => q(francu di Gibbuti),
				'other' => q(franchi di Gibbuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Curuna danisi),
				'one' => q(curuna danisi),
				'other' => q(curuni danisi),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Pesu duminicanu),
				'one' => q(pesu duminicanu),
				'other' => q(pesi duminicani),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dìnaru argirinu),
				'one' => q(dìnaru argirinu),
				'other' => q(dìnari argirini),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Stirlina eggizziana),
				'one' => q(stirlina eggizziana),
				'other' => q(stirlini eggizziani),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nafka eritreu),
				'one' => q(nafka eritreu),
				'other' => q(nafka eritrei),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr etiupi),
				'one' => q(birr etiupi),
				'other' => q(birr etiupi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euru),
				'one' => q(euru),
				'other' => q(euru),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dòllaru dî Figi),
				'one' => q(dòllaru dî Figi),
				'other' => q(dòllari dî Figi),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Stirlina di l’Ìsuli Falkland),
				'one' => q(stirlina di l’Ìsuli Falkland),
				'other' => q(stirlini di l’Ìsuli Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Stirlina Britànnica),
				'one' => q(stirlina Britànnica),
				'other' => q(stirlini Britànnica),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari giurgianu),
				'one' => q(lari giurgianu),
				'other' => q(lari giurgiani),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi ganisi),
				'one' => q(cedi ganisi),
				'other' => q(cedi ganisi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Stirlina di Gibbirterra),
				'one' => q(stirlina di Gibbirterra),
				'other' => q(stirlini di Gibbirterra),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi dû Gammia),
				'one' => q(dalasi dû Gammia),
				'other' => q(dalasi dû Gammia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Francu dâ Guinìa),
				'one' => q(francu dâ Guinìa),
				'other' => q(franchi dâ Guinìa),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal dâ Guatimala),
				'one' => q(quetzal dâ Guatimala),
				'other' => q(quetzal dâ Guatimala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dòllaru dâ Guiana),
				'one' => q(dòllaru dâ Guiana),
				'other' => q(dòllari dâ Guiana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dòllaru di Hong Kong),
				'one' => q(dòllaru di Hong Kong),
				'other' => q(dòllari di Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Limpira di l’Hunnuras),
				'one' => q(limpira di l’Hunnuras),
				'other' => q(limpira di l’Hunnuras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna cruata),
				'one' => q(kuna cruata),
				'other' => q(kuni cruati),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gordu d’Haiti),
				'one' => q(gordu d’Haiti),
				'other' => q(gordi d’Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ciurinu unghirisi),
				'one' => q(ciurinu unghirisi),
				'other' => q(ciurini unghirisi),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupìa innunisiana),
				'one' => q(rupìa innunisiana),
				'other' => q(rupìi innunisiani),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Novu siclu isdraelianu),
				'one' => q(novu siclu isdraelianu),
				'other' => q(novi sicli isdraeliani),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupìa inniana),
				'one' => q(rupìa inniana),
				'other' => q(rupìi inniani),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dìnaru irachenu),
				'one' => q(dìnaru irachenu),
				'other' => q(dìnari iracheni),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riali iranianu),
				'one' => q(riali iranianu),
				'other' => q(riali iraniani),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Curuna islannisi),
				'one' => q(curuna islannisi),
				'other' => q(curuni islannisi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dòllaru giamaicanu),
				'one' => q(dòllaru giamaicanu),
				'other' => q(dòllari giamaicanu),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dìnaru giurdanu),
				'one' => q(dìnaru giurdanu),
				'other' => q(dìnari giurdani),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen giappunisi),
				'one' => q(yen giappunisi),
				'other' => q(yen giappunisi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Scillinu dû Kenya),
				'one' => q(scillinu dû Kenya),
				'other' => q(scillini dû Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som dû Kyrgyzistan),
				'one' => q(som dû Kyrgyzistan),
				'other' => q(som dû Kyrgyzistan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel cambuggianu),
				'one' => q(riel cambuggianu),
				'other' => q(riel cambuggianI),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Francu dî Cumori),
				'one' => q(francu dî Cumori),
				'other' => q(franchi dî Cumori),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won dâ Curìa di Tramuntana),
				'one' => q(won dâ Curìa di Tramuntana),
				'other' => q(won dâ Curìa di Tramuntana),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won dâ Curìa di Sciroccu),
				'one' => q(won dâ Curìa di Sciroccu),
				'other' => q(won dâ Curìa di Sciroccu),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dìnaru dû Kuwait),
				'one' => q(dìnaru dû Kuwait),
				'other' => q(dìnari dû Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dòllaru di l’Ìsuli Cayman),
				'one' => q(dòllaru di l’Ìsuli Cayman),
				'other' => q(dòllari di l’Ìsuli Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge dû Kazzàkistan),
				'one' => q(tenge dû Kazzàkistan),
				'other' => q(tenge dû Kazzàkistan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip lauisi),
				'one' => q(kip lauisi),
				'other' => q(kip lauisi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Stirlina libbanisi),
				'one' => q(stirlina libbanisi),
				'other' => q(stirlini libbanisi),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupìa dû Sri Lanka),
				'one' => q(rupìa dû Sri Lanka),
				'other' => q(rupìi dû Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dòllaru dâ Libberia),
				'one' => q(dòllaru dâ Libberia),
				'other' => q(dòllari dâ Libberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti dû Lisothu),
				'one' => q(loti dû Lisothu),
				'other' => q(loti dû Lisothu),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dìnaru lìbbicu),
				'one' => q(dìnaru lìbbicu),
				'other' => q(dìnari lìbbichi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham marucchinu),
				'one' => q(dirham marucchinu),
				'other' => q(dirham marucchini),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu murdavu),
				'one' => q(leu murdavu),
				'other' => q(lei murdavi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary margasciu),
				'one' => q(ariary margasciu),
				'other' => q(ariary margasci),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dìnaru macèduni),
				'one' => q(dìnaru macèduni),
				'other' => q(dìnari macèduni),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat dû Myanmar),
				'one' => q(kyat dû Myanmar),
				'other' => q(kyat dû Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik mòngulu),
				'one' => q(tugrik mòngulu),
				'other' => q(tugrik mònguli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca di Macau),
				'one' => q(pataca di Macau),
				'other' => q(patachi di Macau),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya mauritanu),
				'one' => q(ouguiya mauritanu),
				'other' => q(ouguiya mauritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupìa di Mauritius),
				'one' => q(rupìa di Mauritius),
				'other' => q(rupìi di Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa dî Mardivi),
				'one' => q(rufiyaa dî Mardivi),
				'other' => q(rufiyaa dî Mardivi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha dû Malawi),
				'one' => q(kwacha dû Malawi),
				'other' => q(kwacha dû Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pesu missicanu),
				'one' => q(pesu missicanu),
				'other' => q(pesi missicani),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit malisi),
				'one' => q(ringgit malisi),
				'other' => q(ringgit malisi),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mètical dû Muzzammicu),
				'one' => q(mètical dû Muzzammicu),
				'other' => q(mètical dû Muzzammicu),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dòllaru dâ Namibbia),
				'one' => q(dòllaru dâ Namibbia),
				'other' => q(dòllari dâ Namibbia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira niggirianu),
				'one' => q(naira niggirianu),
				'other' => q(naira niggiriani),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Còrdubba dâ Nicaragua),
				'one' => q(còrdubba dâ Nicaragua),
				'other' => q(còrdubba dâ Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Curuna nurviggisi),
				'one' => q(curuna nurviggisi),
				'other' => q(curuni nurviggisi),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupìa nipalisi),
				'one' => q(rupìa nipalisi),
				'other' => q(rupìi nipalisi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dòllaru dâ Nova Zilannia),
				'one' => q(dòllaru dâ Nova Zilannia),
				'other' => q(dòllari dâ Nova Zilannia),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riali di l’Oman),
				'one' => q(riali di l’Oman),
				'other' => q(riali di l’Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Barboa di Pànama),
				'one' => q(barboa di Pànama),
				'other' => q(barboa di Pànama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Suli piruvianu),
				'one' => q(suli piruvianu),
				'other' => q(suli piruvianu),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina dâ Papua Nova Guinìa),
				'one' => q(kina dâ Papua Nova Guinìa),
				'other' => q(kina dâ Papua Nova Guinìa),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Pesu filippinu),
				'one' => q(pesu filippinu),
				'other' => q(pesi filippini),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupìa pakistana),
				'one' => q(rupìa pakistana),
				'other' => q(rupìi pakistani),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty pulaccu),
				'one' => q(zloty pulaccu),
				'other' => q(zloty pulacchi),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guaranì dû Paraguay),
				'one' => q(guaranì dû Paraguay),
				'other' => q(guaranì dû Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riali dû Qatar),
				'one' => q(riali dû Qatar),
				'other' => q(riali dû Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu rumenu),
				'one' => q(leu rumenu),
				'other' => q(lei rumeni),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dìnaru serbu),
				'one' => q(dìnaru serbu),
				'other' => q(dìnari serbi),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubblu russu),
				'one' => q(rubblu russu),
				'other' => q(rubbli russi),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Francu dû Ruanna),
				'one' => q(francu dû Ruanna),
				'other' => q(franchi dû Ruanna),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riali di l’Arabbia Saudita),
				'one' => q(riali di l’Arabbia Saudita),
				'other' => q(riali di l’Arabbia Saudita),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dòllaru di l’Ìsuli Salumuni),
				'one' => q(dòllaru di l’Ìsuli Salumuni),
				'other' => q(dòllari di l’Ìsuli Salumuni),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupìa dî Seychelles),
				'one' => q(rupìa dî Seychelles),
				'other' => q(rupìi dî Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Stirlina sudanisi),
				'one' => q(stirlina sudanisi),
				'other' => q(stirlini sudanisi),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Curuna svidisi),
				'one' => q(curuna svidisi),
				'other' => q(curuni svidisi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dòllaru di Singapuri),
				'one' => q(dòllaru di Singapuri),
				'other' => q(dòllari di Singapuri),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Stirlina di Sant’Èlina),
				'one' => q(stirlina di Sant’Èlina),
				'other' => q(stirlini di Sant’Èlina),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Liuni dâ Sierra Liuni),
				'one' => q(liuni dâ Sierra Liuni),
				'other' => q(liuna dâ Sierra Liuni),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Liuni dâ Sierra Liuni \(1964—2022\)),
				'one' => q(liuni dâ Sierra Liuni \(1964—2022\)),
				'other' => q(liuna dâ Sierra Liuni \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Scillinu sòmalu),
				'one' => q(scillinu sòmalu),
				'other' => q(scillini sòmali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dòllaru dû Surinami),
				'one' => q(dòllaru dû Surinami),
				'other' => q(dòllari dû Surinami),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Stirlina dû Sudan di sciroccu),
				'one' => q(stirlina dû Sudan di sciroccu),
				'other' => q(stirlini dû Sudan di sciroccu),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra di São Tomé & Príncipe),
				'one' => q(dobra di São Tomé & Príncipe),
				'other' => q(dobra di São Tomé & Príncipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Stirlina siriana),
				'one' => q(stirlina siriana),
				'other' => q(stirlini siriani),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni di Eswatini),
				'one' => q(lilangeni di Eswatini),
				'other' => q(lilangeni di Eswatini),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht tailannisi),
				'one' => q(baht tailannisi),
				'other' => q(baht tailannisi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni dû Tajìkistan),
				'one' => q(somoni dû Tajìkistan),
				'other' => q(somoni dû Tajìkistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat turkmenu),
				'one' => q(manat turkmenu),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dìnaru tunisinu),
				'one' => q(dìnaru tunisinu),
				'other' => q(dìnari tunisini),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Paʻanga),
				'one' => q(Tongan paʻanga),
				'other' => q(Tongan paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira turca),
				'one' => q(lira turca),
				'other' => q(liri turchi),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dòllaru di Trinidad e Tobago),
				'one' => q(dòllaru di Trinidad e Tobago),
				'other' => q(dòllari di Trinidad e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Novu dòllaru taiwanisi),
				'one' => q(novu dòllaru taiwanisi),
				'other' => q(novi dòllari taiwanisi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Scillinu dâ Tanzania),
				'one' => q(scillinu dâ Tanzania),
				'other' => q(scillini dâ Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Grivnia ucràina),
				'one' => q(grivnia ucràina),
				'other' => q(grivni ucràini),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Scillinu di l’Uganna),
				'one' => q(scillinu di l’Uganna),
				'other' => q(scillini di l’Uganna),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dòllaru miricanu),
				'one' => q(dòllaru miricanu),
				'other' => q(dòllari miricani),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Pesu di l’Uruguay),
				'one' => q(pesu di l’Uruguay),
				'other' => q(pesi di l’Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som di l’Uzbèkistan),
				'one' => q(som di l’Uzbèkistan),
				'other' => q(som di l’Uzbèkistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bulivar dû Vinizzuela),
				'one' => q(bulivar dû Vinizzuela),
				'other' => q(bulivar dû Vinizzuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong vietnamisi),
				'one' => q(dong vietnamisi),
				'other' => q(dong vietnamisi),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu di Vanuatu),
				'one' => q(vatu di Vanuatu),
				'other' => q(vatu di Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala samuanu),
				'one' => q(Tala samuanu),
				'other' => q(Tala samuani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Francu CFA di l’Àfrica cintrali),
				'one' => q(francu CFA di l’Àfrica cintrali),
				'other' => q(franchi CFA di l’Àfrica cintrali),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dòllaru dî Caraibbi di livanti),
				'one' => q(dòllaru dî Caraibbi di livanti),
				'other' => q(dòllari dî Caraibbi di livanti),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Francu CFA di l’Àfrica di punenti),
				'one' => q(francu CFA di l’Àfrica di punenti),
				'other' => q(franchi CFA di l’Àfrica di punenti),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Francu CFP),
				'one' => q(francu CFP),
				'other' => q(franchi CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Munita Scanusciuta),
				'one' => q(\(munita scanusciuta\)),
				'other' => q(\(munita scanusciuta\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riali dû Yemen),
				'one' => q(riali dû Yemen),
				'other' => q(riali dû Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand di l’Àfrica di Sciroccu),
				'one' => q(rand di l’Àfrica di Sciroccu),
				'other' => q(rand di l’Àfrica di Sciroccu),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha dâ Zammia),
				'one' => q(kwacha dâ Zammia),
				'other' => q(kwacha dâ Zammia),
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
							'jin',
							'fri',
							'mar',
							'apr',
							'maj',
							'giu',
							'gnt',
							'agu',
							'sit',
							'utt',
							'nuv',
							'dic'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'jinnaru',
							'frivaru',
							'marzu',
							'aprili',
							'maju',
							'giugnu',
							'giugnettu',
							'agustu',
							'sittèmmiru',
							'uttùviru',
							'nuvèmmiru',
							'dicèmmiru'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'G',
							'G',
							'A',
							'S',
							'U',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'jinnaru',
							'frivaru',
							'marzu',
							'aprili',
							'maju',
							'giugnu',
							'giugnettu',
							'agustu',
							'sittèmmiru',
							'uttùviru',
							'nuvèmmiru',
							'dicèmmiru'
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
						sun => 'dum'
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
						sun => 'du'
					},
					wide => {
						mon => 'lunnidìa',
						tue => 'martidìa',
						wed => 'mercuridìa',
						thu => 'jovidìa',
						fri => 'venniridìa',
						sat => 'sàbbatu',
						sun => 'dumìnica'
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
						sun => 'dum'
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
						sun => 'du'
					},
					wide => {
						mon => 'lunnidìa',
						tue => 'martidìa',
						wed => 'mercuridìa',
						thu => 'jovidìa',
						fri => 'venniridìa',
						sat => 'sàbbatu',
						sun => 'dumìnica'
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
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1ᵘ trimestri',
						1 => '2ᵘ trimestri',
						2 => '3ᵘ trimestri',
						3 => '4ᵘ trimestri'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1ᵘ trimestri',
						1 => '2ᵘ trimestri',
						2 => '3ᵘ trimestri',
						3 => '4ᵘ trimestri'
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
				'0' => 'p.C.',
				'1' => 'd.C.'
			},
			narrow => {
				'0' => 'pC',
				'1' => 'dC'
			},
			wide => {
				'0' => 'prima di Cristu',
				'1' => 'doppu di Cristu'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			Ed => q{E d},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ/y G},
			yyyyQQQQ => q{QQQQ 'dû' y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y G},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMW => q{'simana' W 'di' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'dû' y},
			yw => q{'simana' w 'dû' Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E d/M/y G – E d/M/y G},
				M => q{E d/M/y – E d/M/y G},
				d => q{E d/M/y – E d/M/y G},
				y => q{E d/M/y – E d/M/y G},
			},
			GyMMM => {
				G => q{MMM y – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			MEd => {
				M => q{E M/d – E M/d},
				d => q{E M/d – E M/d},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y},
				d => q{E d/M/y – E d/M/y},
				y => q{E d/M/y – E d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} (ura ligali)),
		regionFormat => q({0} (ura sulari)),
		'Afghanistan' => {
			long => {
				'standard' => q#Ura di l’Afghànistan#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algeri#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Cairu#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casabblanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Cèuta#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Gibbuti#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mugadisciu#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobbi#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trìpuli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tùnisi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ura di l’Àfrica Cintrali#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ura di l’Àfrica di Livanti#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ura Nurmali di l’Àfrica di Sciroccu#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ura ligali di l’Àfrica di Punenti#,
				'generic' => q#Ura di l’Àfrica di Punenti#,
				'standard' => q#Ura sulari di l’Àfrica di Punenti#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ura ligali di l’Alaska#,
				'generic' => q#Ura di l’Alaska#,
				'standard' => q#Ura sulari di l’Alaska#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ura ligali di l’Amazzonia#,
				'generic' => q#Ura di l’Amazzonia#,
				'standard' => q#Ura sulari di l’Amazzonia#,
			},
		},
		'America/Belize' => {
			exemplarCity => q#Bilisi#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campu Ranni#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Còrduba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Custa Rica#,
		},
		'America/Detroit' => {
			exemplarCity => q#Ditroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dumìnica#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatimala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guiana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Giamaica#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cità dû Mèssicu#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Muntirrei#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Munzirratu#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova Jorca#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota di Tramuntana#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Centru, Dakota di Tramuntana#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota di Tramuntana#,
		},
		'America/Panama' => {
			exemplarCity => q#Pànama#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Portu di Spagna#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portu Ricu#,
		},
		'America/Regina' => {
			exemplarCity => q#Riggina#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santu Dumingu#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Paulu#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucìa#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torontu#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ura ligali cintrali#,
				'generic' => q#Ura cintrali#,
				'standard' => q#Ura sulari cintrali#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ura ligali livantina#,
				'generic' => q#Ura livantina#,
				'standard' => q#Ura sulari livantina#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ura ligali dî muntagni#,
				'generic' => q#Ura dî muntagni#,
				'standard' => q#Ura sulari dî muntagni#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ura ligali dû Pacìficu#,
				'generic' => q#Ura dû Pacìficu#,
				'standard' => q#Ura sulari dû Pacìficu#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Ura ligali di Apia#,
				'generic' => q#Ura di Apia#,
				'standard' => q#Ura sulari di Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ura ligali Àrabba#,
				'generic' => q#Ura Àrabba#,
				'standard' => q#Ura sulari Àrabba#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ura ligali di l’Argintina#,
				'generic' => q#Ura di l’Argintina#,
				'standard' => q#Ura sulari di l’Argintina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ura ligali di l’Argintina di punenti#,
				'generic' => q#Ura di l’Argintina di punenti#,
				'standard' => q#Ura sulari di l’Argintina di punenti#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ura ligali di l’Armenia#,
				'generic' => q#Ura di l’Armenia#,
				'standard' => q#Ura sulari di l’Armenia#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammàn#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kurkata#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Culummu#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascu#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gazza#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Girusalemmi#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascati#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicusìa#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanna#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Siul#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapuri#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladìvustok#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekatirimmurgu#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ura ligali di l’Atlànticu#,
				'generic' => q#Ura di l’Atlànticu#,
				'standard' => q#Ura sulari di l’Atlànticu#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azzorri#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Birmuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Capu Virdi#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Giorgia di sciroccu#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant’Èlina#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adilaidi#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ura ligali di l’Australia cintrali#,
				'generic' => q#Ura di l’Australia cintrali#,
				'standard' => q#Ura sulari di l’Australia cintrali#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ura ligali di l’Australia cintrali di punenti#,
				'generic' => q#Ura di l’Australia cintrali di punenti#,
				'standard' => q#Ura sulari di l’Australia cintrali di punenti#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ura ligali di l’Australia di livanti#,
				'generic' => q#Ura di l’Australia di livanti#,
				'standard' => q#Ura sulari di l’Australia di livanti#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ura ligali di l’Australia di punenti#,
				'generic' => q#Ura di l’Australia di punenti#,
				'standard' => q#Ura sulari di l’Australia di punenti#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ura ligali di l’Azerbaijan#,
				'generic' => q#Ura di l’Azerbaijan#,
				'standard' => q#Ura sulari di l’Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ura ligali di l’Azzorri#,
				'generic' => q#Ura di l’Azzorri#,
				'standard' => q#Ura sulari di l’Azzorri#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ura ligali dû Bàngladesh#,
				'generic' => q#Ura dû Bàngladesh#,
				'standard' => q#Ura sulari dû Bàngladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ura dû Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ura dâ Bulivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ura ligali di Brasilia#,
				'generic' => q#Ura di Brasilia#,
				'standard' => q#Ura sulari di Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ura dû Brunei#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ura ligali di Capu Virdi#,
				'generic' => q#Ura di Capu Virdi#,
				'standard' => q#Ura sulari di Capu Virdi#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ura di Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ura ligali di Chatham#,
				'generic' => q#Ura di Chatham#,
				'standard' => q#Ura sulari di Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ura ligali dû Cili#,
				'generic' => q#Ura dû Cili#,
				'standard' => q#Ura sulari dû Cili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ura ligali dâ Cina#,
				'generic' => q#Ura dâ Cina#,
				'standard' => q#Ura sulari dâ Cina#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ura di l’Ìsula di Natali#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ura ligali dâ Culummia#,
				'generic' => q#Ura dâ Culummia#,
				'standard' => q#Ura sulari dâ Culummia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ura ligali di l’Ìsuli Cook#,
				'generic' => q#Ura di l’Ìsuli Cook#,
				'standard' => q#Ura sulari di l’Ìsuli Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ura ligali di Cubba#,
				'generic' => q#Ura di Cubba#,
				'standard' => q#Ura sulari di Cubba#,
			},
			short => {
				'daylight' => q#CuDT#,
				'generic' => q#CuT#,
				'standard' => q#CuST#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ura di Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ura di Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ura di Timor di Livanti#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ura ligali di l’Ìsula di Pasca#,
				'generic' => q#Ura di l’Ìsula di Pasca#,
				'standard' => q#Ura sulari di l’Ìsula di Pasca#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ura di l’Ècuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ura Curdinata Univirsali#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Scanusciutu#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateni#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgradu#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Birlinu#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusseli#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dubblinu#,
			long => {
				'daylight' => q#Ura sulari Irlannisi#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibbirterra#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hèlsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ìsula di Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Ìstanbul#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbona#,
		},
		'Europe/London' => {
			exemplarCity => q#Lònnira#,
			long => {
				'daylight' => q#Ura ligali Britànnica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lussimburgu#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Mauta#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mònacu#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariggi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marinu#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevu#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stuccorma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticanu#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Vòlgugrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagabbria#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurigu#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ura ligali Cintrali Eurupea#,
				'generic' => q#Ura Cintrali Eurupea#,
				'standard' => q#Ura sulari Cintrali Eurupea#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ura ligali di l’Europa di Livanti#,
				'generic' => q#Ura di l’Europa di Livanti#,
				'standard' => q#Ura sulari di l’Europa di Livanti#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ura di l’Europa cchiù a Livanti#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ura ligali di l’Europa di Punenti#,
				'generic' => q#Ura di l’Europa di Punenti#,
				'standard' => q#Ura sulari di l’Europa di Punenti#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ura ligali di l’Ìsuli Falkland#,
				'generic' => q#Ura di l’Ìsuli Falkland#,
				'standard' => q#Ura sulari di l’Ìsuli Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ura ligali dî Figi#,
				'generic' => q#Ura dî Figi#,
				'standard' => q#Ura sulari dî Figi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ura dâ Guiana Francisi#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ura Francisi di Sciroccu e di l’Antàrtidi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ura Minzana di Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ura dî Galàpagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ura di Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ura ligali dâ Giorgia#,
				'generic' => q#Ura dâ Giorgia#,
				'standard' => q#Ura sulari dâ Giorgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Gilbert#,
			},
		},
		'Greenland' => {
			long => {
				'daylight' => q#Ura ligali dâ Gruillannia#,
				'generic' => q#Ura dâ Gruillannia#,
				'standard' => q#Ura sulari dâ Gruillannia#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ura livantina dâ Gruillannia livantina#,
				'generic' => q#Ura dâ Gruillannia livantina#,
				'standard' => q#Ura sulari dâ Gruillannia livantina#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ura ligali dâ Gruillannia punintina#,
				'generic' => q#Ura dâ Gruillannia punintina#,
				'standard' => q#Ura sulari dâ Gruillannia punintina#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ura Nurmali dû Gurfu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ura dâ Guiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ura ligali di l’Hawaai#,
				'generic' => q#Ura di l’Hawaai#,
				'standard' => q#Ura sulari di l’Hawaai#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ura ligali di Hong Kong#,
				'generic' => q#Ura di Hong Kong#,
				'standard' => q#Ura sulari di Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ura ligali di Hovd#,
				'generic' => q#Ura di Hovd#,
				'standard' => q#Ura sulari di Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ura sulari di l’Ìnnia#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Natali#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Mardivi#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ura di l’Ucianu Innianu#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ura di l’Innucina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ura di l’Innunesia cintrali#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ura di l’Innunesia di livanti#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ura di l’Innunesia di punenti#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ura ligali di l’Iran#,
				'generic' => q#Ura di l’Iran#,
				'standard' => q#Ura sulari di l’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ura ligali di Irtkutsk#,
				'generic' => q#Ura di Irtkutsk#,
				'standard' => q#Ura sulari di Irtkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ura ligali di Isdraeli#,
				'generic' => q#Ura di Isdraeli#,
				'standard' => q#Ura sulari di Isdraeli#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ura ligali dû Giappuni#,
				'generic' => q#Ura dû Giappuni#,
				'standard' => q#Ura sulari dû Giappuni#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Ura dû Kazzàkistan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ura dû Kazzàkistan di Livanti#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ura dû Kazzàkistan di Punenti#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ura ligali dâ Curìa#,
				'generic' => q#Ura dâ Curìa#,
				'standard' => q#Ura sulari dâ Curìa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ura di Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ura ligali di Krasnoyarsk#,
				'generic' => q#Ura di Krasnoyarsk#,
				'standard' => q#Ura sulari di Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ura dû Kirghìzzistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ura ligali di Lord Howe#,
				'generic' => q#Ura di Lord Howe#,
				'standard' => q#Ura sulari di Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ura ligali di Magdan#,
				'generic' => q#Ura di Magdan#,
				'standard' => q#Ura sulari di Magdan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ura dâ Malisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ura dî Mardivi#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ura dî Marchesi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ura ligali di Mauritius#,
				'generic' => q#Ura di Mauritius#,
				'standard' => q#Ura sulari di Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ura di Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ura ligali dû Mèssicu Pacìficu#,
				'generic' => q#Ura dû Mèssicu Pacìficu#,
				'standard' => q#Ura sulari dû Mèssicu Pacìficu#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ura ligali di Ulaanbaatar#,
				'generic' => q#Ura di Ulaanbaatar#,
				'standard' => q#Ura sulari di Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ura ligali di Mosca#,
				'generic' => q#Ura di Mosca#,
				'standard' => q#Ura sulari di Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ura di Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ura di Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ura dû Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ura ligali dâ Nova Calidonia#,
				'generic' => q#Ura dâ Nova Calidonia#,
				'standard' => q#Ura sulari dâ Nova Calidonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ura ligali dâ Nova Zilannia#,
				'generic' => q#Ura dâ Nova Zilannia#,
				'standard' => q#Ura sulari dâ Nova Zilannia#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ura ligali di Tirranova#,
				'generic' => q#Ura di Tirranova#,
				'standard' => q#Ura sulari di Tirranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ura di Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ura ligali di l’Ìsula Norfolk#,
				'generic' => q#Ura di l’Ìsula Norfolk#,
				'standard' => q#Ura sulari di l’Ìsula Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ura ligali di Fernando di Noronha#,
				'generic' => q#Ura di Fernando di Noronha#,
				'standard' => q#Ura sulari di Fernando di Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ura ligali di Novosibirsk#,
				'generic' => q#Ura di Novosibirsk#,
				'standard' => q#Ura sulari di Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ura ligali di Omsk#,
				'generic' => q#Ura di Omsk#,
				'standard' => q#Ura sulari di Omsk#,
			},
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Figi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galàpagos#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marchesi#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ura ligali dû Pàkistan#,
				'generic' => q#Ura dû Pàkistan#,
				'standard' => q#Ura sulari dû Pàkistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ura di Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ura dâ Papua Nova Guinìa#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ura ligali dû Paraguay#,
				'generic' => q#Ura dû Paraguay#,
				'standard' => q#Ura sulari dû Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ura ligali dû Pirù#,
				'generic' => q#Ura dû Pirù#,
				'standard' => q#Ura sulari dû Pirù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ura ligali dî Filippini#,
				'generic' => q#Ura dî Filippini#,
				'standard' => q#Ura sulari dî Filippini#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ura ligali di S. Pierre e Miquelon#,
				'generic' => q#Ura di S. Pierre e Miquelon#,
				'standard' => q#Ura sulari di S. Pierre e Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ura di Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ura di Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ura di Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ura di Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ura di Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ura ligali di Sakhalin#,
				'generic' => q#Ura di Sakhalin#,
				'standard' => q#Ura sulari di Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ura ligali dî Samoa#,
				'generic' => q#Ura dî Samoa#,
				'standard' => q#Ura sulari dî Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ura dî Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ura di Singapuri#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ura di l’Ìsuli Salumuni#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ura dâ Giorgia di sciroccu#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ura dû Surinami#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ura di Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ura di Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ura ligali di Taipei#,
				'generic' => q#Ura di Taipei#,
				'standard' => q#Ura sulari di Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ura dû Taggìkistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ura di Tukilau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ura ligali di Tonga#,
				'generic' => q#Ura di Tonga#,
				'standard' => q#Ura sulari di Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ura di Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ura ligali dû Turkmènistan#,
				'generic' => q#Ura dû Turkmènistan#,
				'standard' => q#Ura sulari dû Turkmènistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ura di Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ura ligali di l’Uruguay#,
				'generic' => q#Ura di l’Uruguay#,
				'standard' => q#Ura sulari di l’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ura ligali di l’Uzbèkistan#,
				'generic' => q#Ura di l’Uzbèkistan#,
				'standard' => q#Ura sulari di l’Uzbèkistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ura ligali di Vanuatu#,
				'generic' => q#Ura di Vanuatu#,
				'standard' => q#Ura sulari di Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ura dû Vinizzuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ura ligali di Vladìvustok#,
				'generic' => q#Ura di Vladìvustok#,
				'standard' => q#Ura sulari di Vladìvustok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ura ligali di Vòlgugrad#,
				'generic' => q#Ura di Vòlgugrad#,
				'standard' => q#Ura sulari di Vòlgugrad#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ura di Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ura di l’Ìsula Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ura di Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ura ligali di Yakutsk#,
				'generic' => q#Ura di Yakutsk#,
				'standard' => q#Ura sulari di Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ura ligali di Yekatirimmurgu#,
				'generic' => q#Ura di Yekatirimmurgu#,
				'standard' => q#Ura sulari di Yekatirimmurgu#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ura dû Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
