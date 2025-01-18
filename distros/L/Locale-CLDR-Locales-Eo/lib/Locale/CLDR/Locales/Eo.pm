=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Eo - Package for language Esperanto

=cut

package Locale::CLDR::Locales::Eo;
# This file auto generated from Data\common\main\eo.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulo),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komo →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(unu),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(du),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(kvar),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(kvin),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ses),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sep),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ok),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naŭ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dek[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←dek[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←cent[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miliono[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← milionoj[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miliardoj[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biliono[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← bilionoj[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biliardoj[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=a),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=a),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afara',
 				'ab' => 'abĥaza',
 				'ace' => 'aĉea',
 				'ada' => 'dangba',
 				'ady' => 'adigea',
 				'af' => 'afrikansa',
 				'ain' => 'ajnua',
 				'ak' => 'akana',
 				'ale' => 'aleuta',
 				'alt' => 'sud-altaja',
 				'am' => 'amhara',
 				'an' => 'aragona',
 				'anp' => 'angika',
 				'ar' => 'araba',
 				'ar_001' => 'araba moderna norma',
 				'arn' => 'mapuĉa',
 				'arp' => 'arapaha',
 				'ars' => 'araba naĝda',
 				'as' => 'asama',
 				'ast' => 'astura',
 				'atj' => 'atikameka',
 				'av' => 'avara',
 				'awa' => 'avadhia',
 				'ay' => 'ajmara',
 				'az' => 'azerbajĝana',
 				'az@alt=short' => 'azera',
 				'ba' => 'baŝkira',
 				'ban' => 'balia',
 				'bas' => 'basaa',
 				'be' => 'belorusa',
 				'bem' => 'bemba',
 				'bez' => 'benaa',
 				'bg' => 'bulgara',
 				'bgc' => 'harjana',
 				'bho' => 'boĝpura',
 				'bi' => 'bislamo',
 				'bin' => 'edoa',
 				'bla' => 'siksika',
 				'blo' => 'aniia',
 				'bm' => 'bambara',
 				'bn' => 'bengala',
 				'bo' => 'tibeta',
 				'br' => 'bretona',
 				'brx' => 'bodoa',
 				'bs' => 'bosna',
 				'bug' => 'buĝia',
 				'byn' => 'bilena',
 				'ca' => 'kataluna',
 				'cay' => 'kajuga',
 				'ccp' => 'ĉakma',
 				'ce' => 'ĉeĉena',
 				'ceb' => 'cebua',
 				'cgg' => 'kiga',
 				'ch' => 'ĉamora',
 				'chk' => 'ĉuka',
 				'chm' => 'maria',
 				'cho' => 'ĉakta',
 				'chp' => 'ĉipevajana',
 				'chr' => 'ĉeroka',
 				'chy' => 'ĉejena',
 				'ckb' => 'sorana',
 				'ckb@alt=menu' => 'kurda, sorana',
 				'ckb@alt=variant' => 'kurda centra',
 				'clc' => 'ĉilkotina',
 				'co' => 'korsika',
 				'crg' => 'miĉifa',
 				'crj' => 'kria jakob-golfa suda',
 				'crk' => 'kria preria',
 				'crl' => 'kria jakob-golfa norda',
 				'crm' => 'kria alka',
 				'crr' => 'algonkena (Norda Karolino)',
 				'cs' => 'ĉeĥa',
 				'csw' => 'kria marĉa',
 				'cu' => 'malnovslava',
 				'cv' => 'ĉuvaŝa',
 				'cy' => 'kimra',
 				'da' => 'dana',
 				'dak' => 'dakotaa',
 				'dar' => 'dargva',
 				'dav' => 'taitaa',
 				'de' => 'germana',
 				'de_AT' => 'germana aŭstra',
 				'de_CH' => 'germana svisa',
 				'dgr' => 'dogriba',
 				'dje' => 'zarmaa',
 				'doi' => 'dogra',
 				'dsb' => 'malsuprasoraba',
 				'dua' => 'dualaa',
 				'dv' => 'maldiva',
 				'dyo' => 'djola',
 				'dz' => 'dzonko',
 				'dzg' => 'dazaa',
 				'ebu' => 'embua',
 				'ee' => 'evea',
 				'efi' => 'ibibioefika',
 				'eka' => 'ekaĝuka',
 				'el' => 'greka',
 				'en' => 'angla',
 				'en_AU' => 'angla aŭstralia',
 				'en_CA' => 'angla kanada',
 				'en_GB' => 'angla brita',
 				'en_US' => 'angla usona',
 				'eo' => 'Esperanto',
 				'es' => 'hispana',
 				'es_419' => 'hispana amerika',
 				'es_ES' => 'hispana eŭropa',
 				'es_MX' => 'hispana meksika',
 				'et' => 'estona',
 				'eu' => 'eŭska',
 				'ewo' => 'eunda',
 				'fa' => 'persa',
 				'fa_AF' => 'daria',
 				'ff' => 'fula',
 				'fi' => 'finna',
 				'fil' => 'filipina',
 				'fj' => 'fiĝia',
 				'fo' => 'feroa',
 				'fon' => 'fonua',
 				'fr' => 'franca',
 				'fr_CA' => 'franca kanada',
 				'fr_CH' => 'franca svisa',
 				'frc' => 'kaĵun-franca',
 				'frr' => 'nord-frisa',
 				'fur' => 'friula',
 				'fy' => 'okcident-frisa',
 				'ga' => 'irlanda',
 				'gaa' => 'gaa',
 				'gd' => 'skot-gaela',
 				'gez' => 'geeza',
 				'gil' => 'kiribata',
 				'gl' => 'galega',
 				'gn' => 'gvarania',
 				'gor' => 'gorontala',
 				'gsw' => 'svisgermana',
 				'gu' => 'guĝarata',
 				'guz' => 'gusia',
 				'gv' => 'manksa',
 				'gwi' => 'gviĉina',
 				'ha' => 'haŭsa',
 				'hai' => 'haida',
 				'haw' => 'havaja',
 				'hax' => 'sud-haida',
 				'he' => 'hebrea',
 				'hi' => 'hinda',
 				'hil' => 'hiligajnona',
 				'hmn' => 'mjaŭa',
 				'hr' => 'kroata',
 				'hsb' => 'suprasoraba',
 				'ht' => 'haitia kreola',
 				'hu' => 'hungara',
 				'hup' => 'hupa',
 				'hur' => 'halkomelema',
 				'hy' => 'armena',
 				'hz' => 'herera',
 				'ia' => 'Interlingvao',
 				'iba' => 'ibana',
 				'ibb' => 'ibibia',
 				'id' => 'indonezia',
 				'ie' => 'Interlingveo',
 				'ig' => 'igba',
 				'ii' => 'jia',
 				'ik' => 'eskima',
 				'ikt' => 'inuvialuktuna',
 				'ilo' => 'iloka',
 				'inh' => 'inguŝa',
 				'io' => 'Ido',
 				'is' => 'islanda',
 				'it' => 'itala',
 				'iu' => 'inuita',
 				'ja' => 'japana',
 				'jbo' => 'Loĵbano',
 				'jmc' => 'kimaĉame',
 				'jv' => 'java',
 				'ka' => 'kartvela',
 				'kab' => 'kabila',
 				'kac' => 'kaĉina',
 				'kam' => 'kambaa',
 				'kbd' => 'kabarda',
 				'kde' => 'makonda',
 				'kea' => 'kaboverda kreola',
 				'kfo' => 'malinka (Koro)',
 				'kgp' => 'kainganga',
 				'kha' => 'kasia',
 				'ki' => 'kikuja',
 				'kj' => 'kuanjama',
 				'kk' => 'kazaĥa',
 				'kl' => 'gronlanda',
 				'kln' => 'kalenĝina',
 				'km' => 'kmera',
 				'kmb' => 'kimbunda',
 				'kn' => 'kanara',
 				'ko' => 'korea',
 				'kok' => 'konkana',
 				'kpe' => 'kpelea',
 				'kr' => 'kanura',
 				'krc' => 'karaĉaj-balkara',
 				'krl' => 'karela',
 				'kru' => 'kuruksa',
 				'ks' => 'kaŝmira',
 				'ksb' => 'ŝambaa',
 				'ksh' => 'kolonja',
 				'ku' => 'kurda',
 				'kum' => 'kumika',
 				'kv' => 'komia',
 				'kw' => 'kornvala',
 				'ky' => 'kirgiza',
 				'la' => 'latino',
 				'lad' => 'judhispana',
 				'lag' => 'rangia',
 				'lb' => 'luksemburga',
 				'lez' => 'lezga',
 				'lg' => 'ganda',
 				'li' => 'limburga',
 				'lij' => 'ligura',
 				'lil' => 'lilueta',
 				'lkt' => 'lakota',
 				'lmo' => 'lombarda',
 				'ln' => 'lingala',
 				'lo' => 'laŭa',
 				'lou' => 'luiziana kreola',
 				'loz' => 'lozia',
 				'lrc' => 'nord-lura',
 				'lt' => 'litova',
 				'lu' => 'katanga-luba',
 				'lua' => 'kasaja-luba',
 				'lun' => 'lundaa',
 				'luo' => 'lua',
 				'luy' => 'luhia',
 				'lv' => 'latva',
 				'mad' => 'madura',
 				'mag' => 'magaha',
 				'mai' => 'majtila',
 				'mak' => 'makasara',
 				'mas' => 'masaja',
 				'mdf' => 'mokŝa',
 				'men' => 'mendea',
 				'mer' => 'merua',
 				'mfe' => 'maŭrica kreola',
 				'mg' => 'malagasa',
 				'mgh' => 'makua (Meetto)',
 				'mh' => 'marŝala',
 				'mi' => 'maoria',
 				'mic' => 'mikmaka',
 				'min' => 'minankabaŭa',
 				'mk' => 'makedona',
 				'ml' => 'malajalama',
 				'mn' => 'mongola',
 				'mni' => 'manipura',
 				'moe' => 'inua',
 				'moh' => 'mohoka',
 				'mos' => 'mosia',
 				'mr' => 'marata',
 				'ms' => 'malaja',
 				'mt' => 'malta',
 				'mua' => 'mundanga',
 				'mul' => 'pluraj lingvoj',
 				'mus' => 'krika',
 				'mwl' => 'miranda',
 				'my' => 'birma',
 				'myv' => 'erzja',
 				'mzn' => 'mazandarana',
 				'na' => 'naura',
 				'nap' => 'napola',
 				'naq' => 'nama',
 				'nb' => 'dannorvega',
 				'nd' => 'nord-matabela',
 				'nds' => 'platgermana',
 				'ne' => 'nepala',
 				'new' => 'nevara',
 				'ng' => 'ndonga',
 				'nia' => 'niasa',
 				'niu' => 'niua',
 				'nl' => 'nederlanda',
 				'nl_BE' => 'flandra',
 				'nn' => 'novnorvega',
 				'no' => 'norvega',
 				'nog' => 'nogaja',
 				'nqo' => 'N’Ko',
 				'nr' => 'sud-matabela',
 				'nso' => 'nord-sota',
 				'nus' => 'nuera',
 				'nv' => 'navaha',
 				'ny' => 'njanĝa',
 				'nyn' => 'njankora',
 				'oc' => 'okcitana',
 				'ojb' => 'oĝibva nordokcidenta',
 				'ojc' => 'oĝibva centra',
 				'ojw' => 'oĝibva okcidenta',
 				'oka' => 'okanagana',
 				'om' => 'oroma',
 				'or' => 'orijo',
 				'os' => 'oseta',
 				'pa' => 'panĝaba',
 				'pag' => 'pangasina',
 				'pam' => 'pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'palaŭa',
 				'pcm' => 'niĝeria piĝino',
 				'pis' => 'piĵina',
 				'pl' => 'pola',
 				'pqm' => 'malesita-pasamakvodja',
 				'prg' => 'prusa',
 				'ps' => 'paŝtua',
 				'pt' => 'portugala',
 				'pt_BR' => 'portugala brazila',
 				'pt_PT' => 'portugala eŭropa',
 				'qu' => 'keĉua',
 				'raj' => 'raĝastana',
 				'rap' => 'rapanuia',
 				'rar' => 'maoria kukinsula',
 				'rhg' => 'rohinĝa',
 				'rm' => 'romanĉa',
 				'rn' => 'burunda',
 				'ro' => 'rumana',
 				'rof' => 'kiromba',
 				'ru' => 'rusa',
 				'rup' => 'arumana',
 				'rw' => 'ruanda',
 				'rwk' => 'rua',
 				'sa' => 'sanskrito',
 				'sad' => 'sandavea',
 				'sah' => 'jakuta',
 				'saq' => 'samburua',
 				'sat' => 'santala',
 				'sba' => 'gambaja',
 				'sc' => 'sarda',
 				'scn' => 'sicilia',
 				'sco' => 'skota',
 				'sd' => 'sinda',
 				'se' => 'nord-samea',
 				'sg' => 'sangoa',
 				'sh' => 'serbo-Kroata',
 				'shi' => 'ŝelha',
 				'shn' => 'ŝana',
 				'si' => 'sinhala',
 				'sk' => 'slovaka',
 				'sl' => 'slovena',
 				'slh' => 'sud-laŝucida',
 				'sm' => 'samoa',
 				'smn' => 'anar-samea',
 				'sms' => 'skolt-samea',
 				'sn' => 'ŝona',
 				'snk' => 'soninka',
 				'so' => 'somala',
 				'sq' => 'albana',
 				'sr' => 'serba',
 				'srn' => 'surinama',
 				'ss' => 'svazia',
 				'st' => 'sota',
 				'str' => 'saliŝa nord-markola',
 				'su' => 'sunda',
 				'suk' => 'sukuma',
 				'sv' => 'sveda',
 				'sw' => 'svahila',
 				'swb' => 'maorea',
 				'syr' => 'siria',
 				'szl' => 'silezi-pola',
 				'ta' => 'tamila',
 				'tce' => 'sud-tuĉona',
 				'te' => 'telugua',
 				'tem' => 'temna',
 				'teo' => 'tesa',
 				'tet' => 'tetuna',
 				'tg' => 'taĝika',
 				'tgx' => 'tagiŝa',
 				'th' => 'taja',
 				'tht' => 'taltana',
 				'ti' => 'tigraja',
 				'tig' => 'tigrea',
 				'tk' => 'turkmena',
 				'tl' => 'tagaloga',
 				'tlh' => 'klingona',
 				'tli' => 'tlingita',
 				'tn' => 'cvana',
 				'to' => 'tongana',
 				'tok' => 'Tokipono',
 				'tpi' => 'Tokpisino',
 				'tr' => 'turka',
 				'trv' => 'sedeka',
 				'ts' => 'conga',
 				'tt' => 'tatara',
 				'ttm' => 'nord-tuĉona',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvala',
 				'ty' => 'tahitia',
 				'tyv' => 'tuva',
 				'tzm' => 'tamaziĥta mez-atlasa',
 				'udm' => 'udmurta',
 				'ug' => 'ujgura',
 				'uk' => 'ukraina',
 				'umb' => 'ovimbunda',
 				'und' => 'nekonata lingvo',
 				'ur' => 'urduo',
 				'uz' => 'uzbeka',
 				'vai' => 'vaja',
 				've' => 'vendaa',
 				'vec' => 'venecia',
 				'vi' => 'vjetnama',
 				'vmw' => 'makua',
 				'vo' => 'Volapuko',
 				'vun' => 'kivunja',
 				'wa' => 'valona',
 				'wae' => 'germana valza',
 				'war' => 'varaja',
 				'wo' => 'volofa',
 				'wuu' => 'vua',
 				'xal' => 'kalmuka',
 				'xh' => 'ksosa',
 				'xnr' => 'kangra',
 				'xog' => 'soga',
 				'yi' => 'jida',
 				'yo' => 'joruba',
 				'yrl' => 'nengatua',
 				'yue' => 'kantona',
 				'yue@alt=menu' => 'ĉina kantona',
 				'za' => 'ĝuanga',
 				'zgh' => 'tamaziĥta maroka norma',
 				'zh' => 'ĉina',
 				'zh@alt=menu' => 'ĉina, normlingvo',
 				'zh_Hans' => 'ĉina simpligita',
 				'zh_Hans@alt=long' => 'ĉina normlingvo simpligita',
 				'zh_Hant' => 'ĉina tradicia',
 				'zh_Hant@alt=long' => 'ĉina normlingvo tradicia',
 				'zu' => 'zulua',
 				'zun' => 'zunjia',
 				'zxx' => 'nelingvaĵo',
 				'zza' => 'zazaa',

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
			'Arab' => 'araba',
 			'Aran' => 'nastalika',
 			'Armn' => 'armena',
 			'Beng' => 'bengala',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'brajlo',
 			'Cyrl' => 'cirila',
 			'Deva' => 'nagario',
 			'Ethi' => 'etiopa',
 			'Geor' => 'kartvela',
 			'Grek' => 'greka',
 			'Gujr' => 'guĝarata',
 			'Guru' => 'gurmuka',
 			'Hanb' => 'ĉina kun bopomofo',
 			'Hang' => 'hangulo',
 			'Hani' => 'ĉina',
 			'Hans' => 'simpligita',
 			'Hans@alt=stand-alone' => 'simpligita ĉina',
 			'Hant' => 'tradicia',
 			'Hant@alt=stand-alone' => 'tradicia ĉina',
 			'Hebr' => 'hebrea',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japanaj silabaroj',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japana',
 			'Kana' => 'katakana',
 			'Khmr' => 'kmera',
 			'Knda' => 'kanara',
 			'Kore' => 'korea',
 			'Laoo' => 'laŭa',
 			'Latn' => 'latina',
 			'Mlym' => 'malajalama',
 			'Mymr' => 'birma',
 			'Orya' => 'orija',
 			'Sinh' => 'sinhala',
 			'Taml' => 'tamila',
 			'Telu' => 'telugua',
 			'Thaa' => 'maldiva',
 			'Thai' => 'taja',
 			'Tibt' => 'tibeta',
 			'Zmth' => 'matematika notacio',
 			'Zsye' => 'emoĝioj',
 			'Zsym' => 'simboloj',
 			'Zxxx' => 'neskribata',
 			'Zyyy' => 'nedifinita',
 			'Zzzz' => 'nekonata skribsistemo',

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
			'001' => 'mondo',
 			'002' => 'Afriko',
 			'003' => 'Nordameriko',
 			'005' => 'Sudameriko',
 			'009' => 'Oceanio',
 			'011' => 'Okcidenta Afriko',
 			'013' => 'Centra Ameriko',
 			'014' => 'Orienta Afriko',
 			'015' => 'Norda Afriko',
 			'017' => 'Centra Afriko',
 			'018' => 'Suda Afriko',
 			'019' => 'Amerikoj',
 			'021' => 'Norda Ameriko',
 			'029' => 'Kariba regiono',
 			'030' => 'Orienta Azio',
 			'034' => 'Suda Azio',
 			'035' => 'Sud-orienta Azio',
 			'039' => 'Suda Eŭropo',
 			'053' => 'Aŭstralazio',
 			'054' => 'Melanezio',
 			'057' => 'Mikronezia regiono',
 			'061' => 'Polinezio',
 			'142' => 'Azio',
 			'143' => 'Centra Azio',
 			'145' => 'Okcidenta Azio',
 			'150' => 'Eŭropo',
 			'151' => 'Orienta Eŭropo',
 			'154' => 'Norda Eŭropo',
 			'155' => 'Okcidenta Eŭropo',
 			'202' => 'Subsahara Afriko',
 			'419' => 'Latinameriko',
 			'AC' => 'Ascension',
 			'AD' => 'Andoro',
 			'AE' => 'Unuiĝintaj Arabaj Emirlandoj',
 			'AF' => 'Afganujo',
 			'AG' => 'Antigvo kaj Barbudo',
 			'AI' => 'Angvilo',
 			'AL' => 'Albanujo',
 			'AM' => 'Armenujo',
 			'AO' => 'Angolo',
 			'AQ' => 'Antarkto',
 			'AR' => 'Argentino',
 			'AS' => 'Usona Samoo',
 			'AT' => 'Aŭstrujo',
 			'AU' => 'Aŭstralio',
 			'AW' => 'Arubo',
 			'AX' => 'Alando',
 			'AZ' => 'Azerbajĝano',
 			'BA' => 'Bosnujo kaj Hercegovino',
 			'BB' => 'Barbado',
 			'BD' => 'Bangladeŝo',
 			'BE' => 'Belgujo',
 			'BF' => 'Burkino',
 			'BG' => 'Bulgarujo',
 			'BH' => 'Barejno',
 			'BI' => 'Burundo',
 			'BJ' => 'Benino',
 			'BL' => 'Sankta Bartolomeo',
 			'BM' => 'Bermudoj',
 			'BN' => 'Brunejo',
 			'BO' => 'Bolivio',
 			'BQ' => 'Kariba Nederlando',
 			'BR' => 'Brazilo',
 			'BS' => 'Bahamoj',
 			'BT' => 'Butano',
 			'BV' => 'Buvetinsulo',
 			'BW' => 'Bocvano',
 			'BY' => 'Belorusujo',
 			'BZ' => 'Belizo',
 			'CA' => 'Kanado',
 			'CC' => 'Kokosinsuloj',
 			'CD' => 'Kongo Kinŝasa',
 			'CD@alt=variant' => 'Demokratia Respubliko Kongo',
 			'CF' => 'Centr-Afrika Respubliko',
 			'CG' => 'Kongo Brazavila',
 			'CG@alt=variant' => 'Respubliko Kongo',
 			'CH' => 'Svisujo',
 			'CI' => 'Ebur-Bordo',
 			'CK' => 'Kukinsuloj',
 			'CL' => 'Ĉilio',
 			'CM' => 'Kameruno',
 			'CN' => 'Ĉinujo',
 			'CO' => 'Kolombio',
 			'CP' => 'Klipertono',
 			'CQ' => 'Sark',
 			'CR' => 'Kostariko',
 			'CU' => 'Kubo',
 			'CV' => 'Kaboverdo',
 			'CW' => 'Kuracao',
 			'CX' => 'Kristnaskinsulo',
 			'CY' => 'Kipro',
 			'CZ' => 'Ĉeĥujo',
 			'CZ@alt=variant' => 'Ĉeĥa Respubliko',
 			'DE' => 'Germanujo',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Ĝibutio',
 			'DK' => 'Danujo',
 			'DM' => 'Dominiko',
 			'DO' => 'Domingo',
 			'DZ' => 'Alĝerio',
 			'EA' => 'Ceŭto kaj Melilo',
 			'EC' => 'Ekvadoro',
 			'EE' => 'Estonujo',
 			'EG' => 'Egiptujo',
 			'EH' => 'Okcidenta Saharo',
 			'ER' => 'Eritreo',
 			'ES' => 'Hispanujo',
 			'ET' => 'Etiopujo',
 			'EU' => 'Eŭropa Unio',
 			'EZ' => 'Eŭrozono',
 			'FI' => 'Finnlando',
 			'FJ' => 'Fiĝoj',
 			'FK' => 'Falklandoj',
 			'FM' => 'Mikronezio',
 			'FO' => 'Ferooj',
 			'FR' => 'Francujo',
 			'GA' => 'Gabono',
 			'GB' => 'Unuiĝinta Reĝlando',
 			'GB@alt=short' => 'Britujo',
 			'GD' => 'Grenado',
 			'GE' => 'Kartvelujo',
 			'GF' => 'Franca Gviano',
 			'GG' => 'Gernezejo',
 			'GH' => 'Ganao',
 			'GI' => 'Ĝibraltaro',
 			'GL' => 'Gronlando',
 			'GM' => 'Gambio',
 			'GN' => 'Gvineo',
 			'GP' => 'Gvadelupo',
 			'GQ' => 'Ekvatora Gvineo',
 			'GR' => 'Grekujo',
 			'GS' => 'Sud-Georgio kaj Sud-Sandviĉinsuloj',
 			'GT' => 'Gvatemalo',
 			'GU' => 'Gvamo',
 			'GW' => 'Gvineo-Bisaŭo',
 			'GY' => 'Gujano',
 			'HK' => 'Honkongo',
 			'HM' => 'Herda kaj Makdonaldaj Insuloj',
 			'HN' => 'Honduro',
 			'HR' => 'Kroatujo',
 			'HT' => 'Haitio',
 			'HU' => 'Hungarujo',
 			'IC' => 'Kanarioj',
 			'ID' => 'Indonezio',
 			'IE' => 'Irlando',
 			'IL' => 'Israelo',
 			'IM' => 'Mankinsulo',
 			'IN' => 'Hindujo',
 			'IO' => 'Brita Hindoceana Teritorio',
 			'IO@alt=chagos' => 'Ĉagos-arĥipelago',
 			'IQ' => 'Irako',
 			'IR' => 'Irano',
 			'IS' => 'Islando',
 			'IT' => 'Italujo',
 			'JE' => 'Ĵerzejo',
 			'JM' => 'Jamajko',
 			'JO' => 'Jordanio',
 			'JP' => 'Japanujo',
 			'KE' => 'Kenjo',
 			'KG' => 'Kirgizujo',
 			'KH' => 'Kamboĝo',
 			'KI' => 'Kiribato',
 			'KM' => 'Komoroj',
 			'KN' => 'Sankta Kristoforo kaj Neviso',
 			'KP' => 'Nord-Koreo',
 			'KR' => 'Sud-Koreo',
 			'KW' => 'Kuvajto',
 			'KY' => 'Kejmanoj',
 			'KZ' => 'Kazaĥujo',
 			'LA' => 'Laoso',
 			'LB' => 'Libano',
 			'LC' => 'Sankta Lucio',
 			'LI' => 'Liĥtenŝtejno',
 			'LK' => 'Srilanko',
 			'LR' => 'Liberio',
 			'LS' => 'Lesoto',
 			'LT' => 'Litovujo',
 			'LU' => 'Luksemburgo',
 			'LV' => 'Latvujo',
 			'LY' => 'Libio',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavujo',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskaro',
 			'MH' => 'Marŝaloj',
 			'MK' => 'Nord-Makedonujo',
 			'ML' => 'Malio',
 			'MM' => 'Birmo',
 			'MN' => 'Mongolujo',
 			'MO' => 'Makao',
 			'MP' => 'Nord-Marianoj',
 			'MQ' => 'Martiniko',
 			'MR' => 'Maŭritanujo',
 			'MS' => 'Moncerato',
 			'MT' => 'Malto',
 			'MU' => 'Maŭricio',
 			'MV' => 'Maldivoj',
 			'MW' => 'Malavio',
 			'MX' => 'Meksiko',
 			'MY' => 'Malajzio',
 			'MZ' => 'Mozambiko',
 			'NA' => 'Namibio',
 			'NC' => 'Nov-Kaledonio',
 			'NE' => 'Niĝero',
 			'NF' => 'Norfolkinsulo',
 			'NG' => 'Niĝerio',
 			'NI' => 'Nikaragvo',
 			'NL' => 'Nederlando',
 			'NO' => 'Norvegujo',
 			'NP' => 'Nepalo',
 			'NR' => 'Nauro',
 			'NU' => 'Niuo',
 			'NZ' => 'Nov-Zelando',
 			'OM' => 'Omano',
 			'PA' => 'Panamo',
 			'PE' => 'Peruo',
 			'PF' => 'Franca Polinezio',
 			'PG' => 'Papuo-Nov-Gvineo',
 			'PH' => 'Filipinoj',
 			'PK' => 'Pakistano',
 			'PL' => 'Pollando',
 			'PM' => 'Sankta Piero kaj Mikelono',
 			'PN' => 'Pitkarna Insulo',
 			'PR' => 'Puertoriko',
 			'PS' => 'Palestino',
 			'PT' => 'Portugalujo',
 			'PW' => 'Palaŭo',
 			'PY' => 'Paragvajo',
 			'QA' => 'Kataro',
 			'QO' => 'malproksimaj insuletoj de Oceanio',
 			'RE' => 'Reunio',
 			'RO' => 'Rumanujo',
 			'RS' => 'Serbujo',
 			'RU' => 'Rusujo',
 			'RW' => 'Ruando',
 			'SA' => 'Sauda Arabujo',
 			'SB' => 'Salomonoj',
 			'SC' => 'Sejŝeloj',
 			'SD' => 'Sudano',
 			'SE' => 'Svedujo',
 			'SG' => 'Singapuro',
 			'SH' => 'Sankta Heleno',
 			'SI' => 'Slovenujo',
 			'SJ' => 'Svalbardo kaj Janmajeno',
 			'SK' => 'Slovakujo',
 			'SL' => 'Sieraleono',
 			'SM' => 'Sanmarino',
 			'SN' => 'Senegalo',
 			'SO' => 'Somalujo',
 			'SR' => 'Surinamo',
 			'SS' => 'Sud-Sudano',
 			'ST' => 'Santomeo kaj Principeo',
 			'SV' => 'Salvadoro',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Sirio',
 			'SZ' => 'Svazilando',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turkoj kaj Kajkoj',
 			'TD' => 'Ĉado',
 			'TF' => 'Francaj Sudaj Teritorioj',
 			'TG' => 'Togolando',
 			'TH' => 'Tajlando',
 			'TJ' => 'Taĝikujo',
 			'TK' => 'Tokelao',
 			'TL' => 'Orienta Timoro',
 			'TM' => 'Turkmenujo',
 			'TN' => 'Tunizio',
 			'TO' => 'Tongo',
 			'TR' => 'Turkujo',
 			'TR@alt=variant' => 'Turkio',
 			'TT' => 'Trinidado kaj Tobago',
 			'TV' => 'Tuvalo',
 			'TW' => 'Tajvano',
 			'TZ' => 'Tanzanio',
 			'UA' => 'Ukrainujo',
 			'UG' => 'Ugando',
 			'UM' => 'Usonaj malgrandaj insuloj',
 			'UN' => 'Unuiĝintaj Nacioj',
 			'US' => 'Usono',
 			'UY' => 'Urugvajo',
 			'UZ' => 'Uzbekujo',
 			'VA' => 'Vatikano',
 			'VC' => 'Sankta Vincento kaj Grenadinoj',
 			'VE' => 'Venezuelo',
 			'VG' => 'Britaj Virgulininsuloj',
 			'VI' => 'Usonaj Virgulininsuloj',
 			'VN' => 'Vjetnamo',
 			'VU' => 'Vanuatuo',
 			'WF' => 'Valiso kaj Futuno',
 			'WS' => 'Samoo',
 			'XA' => 'pseŭdo-supersignoj',
 			'XB' => 'pseŭdo-inversdirekta',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemeno',
 			'YT' => 'Majoto',
 			'ZA' => 'Sud-Afriko',
 			'ZM' => 'Zambio',
 			'ZW' => 'Zimbabvo',
 			'ZZ' => 'nekonata regiono',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'ARKAIKA' => 'Arkaika',
 			'HSISTEMO' => 'h-sistemo',
 			'XSISTEMO' => 'x-sistemo',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalendaro',
 			'cf' => 'formo de valuto',
 			'collation' => 'ordigo',
 			'currency' => 'valuto',

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
 				'buddhist' => q{budhaisma kalendaro},
 				'chinese' => q{ĉina kalendaro},
 				'coptic' => q{kopta kalendaro},
 				'dangi' => q{korea kalendaro},
 				'ethiopic' => q{etiopa kalendaro},
 				'gregorian' => q{gregoria kalendaro},
 				'hebrew' => q{juda kalendaro},
 				'islamic' => q{islama kalendaro},
 				'islamic-civil' => q{tabela islama kalendaro},
 				'islamic-umalqura' => q{islama kalendaro (Umm al-Qura)},
 				'iso8601' => q{kalendaro ISO-8601},
 				'japanese' => q{japana kalendaro},
 				'persian' => q{persa kalendaro},
 				'roc' => q{kalendaro de Respubliko Ĉinujo},
 			},
 			'collation' => {
 				'ducet' => q{norma ordigo laŭ Unikodo},
 				'search' => q{ĝeneral-uza serĉo},
 				'standard' => q{norma ordigo},
 			},
 			'numbers' => {
 				'latn' => q{eŭropaj ciferoj},
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
			'metric' => q{metra},
 			'UK' => q{brita},
 			'US' => q{usona},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingvo: {0}',
 			'script' => 'Skribsistemo: {0}',
 			'region' => 'Regiono: {0}',

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
			auxiliary => qr{[q w x y]},
			index => ['A', 'B', 'C', 'Ĉ', 'D', 'E', 'F', 'G', 'Ĝ', 'H', 'Ĥ', 'I', 'J', 'Ĵ', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'Ŝ', 'T', 'U', 'Ŭ', 'V', 'Z'],
			main => qr{[a b c ĉ d e f g ĝ h ĥ i j ĵ k l m n o p r s ŝ t u ŭ v z]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] \{ \} /]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ĉ', 'D', 'E', 'F', 'G', 'Ĝ', 'H', 'Ĥ', 'I', 'J', 'Ĵ', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'Ŝ', 'T', 'U', 'Ŭ', 'V', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
		};
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direkto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direkto),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akreoj),
						'one' => q({0} akreo),
						'other' => q({0} akreoj),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akreoj),
						'one' => q({0} akreo),
						'other' => q({0} akreoj),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektaroj),
						'one' => q({0} hektaro),
						'other' => q({0} hektaroj),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektaroj),
						'one' => q({0} hektaro),
						'other' => q({0} hektaroj),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(kvadrataj centimetroj),
						'one' => q({0} kvadrata centimetro),
						'other' => q({0} kvadrataj centimetroj),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(kvadrataj centimetroj),
						'one' => q({0} kvadrata centimetro),
						'other' => q({0} kvadrataj centimetroj),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadrataj futoj),
						'one' => q({0} kvadrata futo),
						'other' => q({0} kvadrataj futoj),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadrataj futoj),
						'one' => q({0} kvadrata futo),
						'other' => q({0} kvadrataj futoj),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrataj coloj),
						'one' => q({0} kvadrata colo),
						'other' => q({0} kvadrataj coloj),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrataj coloj),
						'one' => q({0} kvadrata colo),
						'other' => q({0} kvadrataj coloj),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadrataj kilometroj),
						'one' => q({0} kvadrata kilometro),
						'other' => q({0} kvadrataj kilometroj),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadrataj kilometroj),
						'one' => q({0} kvadrata kilometro),
						'other' => q({0} kvadrataj kilometroj),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadrataj metroj),
						'one' => q({0} kvadrata metro),
						'other' => q({0} kvadrataj metroj),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadrataj metroj),
						'one' => q({0} kvadrata metro),
						'other' => q({0} kvadrataj metroj),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kvadrataj mejloj),
						'one' => q({0} kvadrata mejlo),
						'other' => q({0} kvadrataj mejloj),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kvadrataj mejloj),
						'one' => q({0} kvadrata mejlo),
						'other' => q({0} kvadrataj mejloj),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kvadrataj jardoj),
						'one' => q({0} kvadrata jardo),
						'other' => q({0} kvadrataj jardoj),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kvadrataj jardoj),
						'one' => q({0} kvadrata jardo),
						'other' => q({0} kvadrataj jardoj),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} oriente),
						'north' => q({0} norde),
						'south' => q({0} sude),
						'west' => q({0} okcidente),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} oriente),
						'north' => q({0} norde),
						'south' => q({0} sude),
						'west' => q({0} okcidente),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bitoj),
						'one' => q({0} bito),
						'other' => q({0} bitoj),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bitoj),
						'one' => q({0} bito),
						'other' => q({0} bitoj),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bajtoj),
						'one' => q({0} bajto),
						'other' => q({0} bajtoj),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bajtoj),
						'one' => q({0} bajto),
						'other' => q({0} bajtoj),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabitoj),
						'one' => q({0} gigabito),
						'other' => q({0} gigabitoj),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabitoj),
						'one' => q({0} gigabito),
						'other' => q({0} gigabitoj),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabajtoj),
						'one' => q({0} gigabajto),
						'other' => q({0} gigabajtoj),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabajtoj),
						'one' => q({0} gigabajto),
						'other' => q({0} gigabajtoj),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobitoj),
						'one' => q({0} kilobito),
						'other' => q({0} kilobitoj),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobitoj),
						'one' => q({0} kilobito),
						'other' => q({0} kilobitoj),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobajtoj),
						'one' => q({0} kilobajto),
						'other' => q({0} kilobajtoj),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobajtoj),
						'one' => q({0} kilobajto),
						'other' => q({0} kilobajtoj),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabitoj),
						'one' => q({0} megabito),
						'other' => q({0} megabitoj),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabitoj),
						'one' => q({0} megabito),
						'other' => q({0} megabitoj),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabajtoj),
						'one' => q({0} megabajto),
						'other' => q({0} megabajtoj),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabajtoj),
						'one' => q({0} megabajto),
						'other' => q({0} megabajtoj),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabitoj),
						'one' => q({0} terabito),
						'other' => q({0} terabitoj),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabitoj),
						'one' => q({0} terabito),
						'other' => q({0} terabitoj),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabajtoj),
						'one' => q({0} terabajto),
						'other' => q({0} terabajtoj),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabajtoj),
						'one' => q({0} terabajto),
						'other' => q({0} terabajtoj),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(jarcentoj),
						'one' => q({0} jarcento),
						'other' => q({0} jarcentoj),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(jarcentoj),
						'one' => q({0} jarcento),
						'other' => q({0} jarcentoj),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(tagoj),
						'one' => q({0} tago),
						'other' => q({0} tagoj),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(tagoj),
						'one' => q({0} tago),
						'other' => q({0} tagoj),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(jardekoj),
						'one' => q({0} jardeko),
						'other' => q({0} jardekoj),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(jardekoj),
						'one' => q({0} jardeko),
						'other' => q({0} jardekoj),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(horoj),
						'one' => q({0} horo),
						'other' => q({0} horoj),
						'per' => q({0} por horo),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(horoj),
						'one' => q({0} horo),
						'other' => q({0} horoj),
						'per' => q({0} por horo),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekundoj),
						'one' => q({0} milisekundo),
						'other' => q({0} milisekundoj),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekundoj),
						'one' => q({0} milisekundo),
						'other' => q({0} milisekundoj),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutoj),
						'one' => q({0} minuto),
						'other' => q({0} minutoj),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutoj),
						'one' => q({0} minuto),
						'other' => q({0} minutoj),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(monatoj),
						'one' => q({0} monato),
						'other' => q({0} monatoj),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(monatoj),
						'one' => q({0} monato),
						'other' => q({0} monatoj),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(noktoj),
						'one' => q({0} nokto),
						'other' => q({0} noktoj),
						'per' => q(po {0} por nokto),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(noktoj),
						'one' => q({0} nokto),
						'other' => q({0} noktoj),
						'per' => q(po {0} por nokto),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundoj),
						'one' => q({0} sekundo),
						'other' => q({0} sekundoj),
						'per' => q({0} por sekundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundoj),
						'one' => q({0} sekundo),
						'other' => q({0} sekundoj),
						'per' => q({0} por sekundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semajnoj),
						'one' => q({0} semajno),
						'other' => q({0} semajnoj),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semajnoj),
						'one' => q({0} semajno),
						'other' => q({0} semajnoj),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(jaroj),
						'one' => q({0} jaro),
						'other' => q({0} jaroj),
						'per' => q(po {0} por jaro),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jaroj),
						'one' => q({0} jaro),
						'other' => q({0} jaroj),
						'per' => q(po {0} por jaro),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiaj unuoj),
						'one' => q({0} astronomia unuo),
						'other' => q({0} astronomiaj unuoj),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiaj unuoj),
						'one' => q({0} astronomia unuo),
						'other' => q({0} astronomiaj unuoj),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimetroj),
						'one' => q({0} centimetro),
						'other' => q({0} centimetroj),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimetroj),
						'one' => q({0} centimetro),
						'other' => q({0} centimetroj),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimetroj),
						'one' => q({0} decimetro),
						'other' => q({0} decimetroj),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimetroj),
						'one' => q({0} decimetro),
						'other' => q({0} decimetroj),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(klaftoj),
						'one' => q({0} klafto),
						'other' => q({0} klaftoj),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(klaftoj),
						'one' => q({0} klafto),
						'other' => q({0} klaftoj),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(futoj),
						'one' => q({0} futo),
						'other' => q({0} futoj),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(futoj),
						'one' => q({0} futo),
						'other' => q({0} futoj),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(stadioj),
						'one' => q({0} stadio),
						'other' => q({0} stadioj),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(stadioj),
						'one' => q({0} stadio),
						'other' => q({0} stadioj),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(coloj),
						'one' => q({0} colo),
						'other' => q({0} coloj),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(coloj),
						'one' => q({0} colo),
						'other' => q({0} coloj),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometroj),
						'one' => q({0} kilometro),
						'other' => q({0} kilometroj),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometroj),
						'one' => q({0} kilometro),
						'other' => q({0} kilometroj),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lumjaroj),
						'one' => q({0} lumjaro),
						'other' => q({0} lumjaroj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lumjaroj),
						'one' => q({0} lumjaro),
						'other' => q({0} lumjaroj),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metroj),
						'one' => q({0} metro),
						'other' => q({0} metroj),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metroj),
						'one' => q({0} metro),
						'other' => q({0} metroj),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometroj),
						'one' => q({0} mikrometro),
						'other' => q({0} mikrometroj),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometroj),
						'one' => q({0} mikrometro),
						'other' => q({0} mikrometroj),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mejloj),
						'one' => q({0} mejlo),
						'other' => q({0} mejloj),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mejloj),
						'one' => q({0} mejlo),
						'other' => q({0} mejloj),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetroj),
						'one' => q({0} milimetro),
						'other' => q({0} milimetroj),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetroj),
						'one' => q({0} milimetro),
						'other' => q({0} milimetroj),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometroj),
						'one' => q({0} nanometro),
						'other' => q({0} nanometroj),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometroj),
						'one' => q({0} nanometro),
						'other' => q({0} nanometroj),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(marmejloj),
						'one' => q({0} marmejlo),
						'other' => q({0} marmejloj),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(marmejloj),
						'one' => q({0} marmejlo),
						'other' => q({0} marmejloj),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsekoj),
						'one' => q({0} parseko),
						'other' => q({0} parsekoj),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsekoj),
						'one' => q({0} parseko),
						'other' => q({0} parsekoj),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometroj),
						'one' => q({0} pikometro),
						'other' => q({0} pikometroj),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometroj),
						'one' => q({0} pikometro),
						'other' => q({0} pikometroj),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardoj),
						'one' => q({0} jardo),
						'other' => q({0} jardoj),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardoj),
						'one' => q({0} jardo),
						'other' => q({0} jardoj),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramoj),
						'one' => q({0} gramo),
						'other' => q({0} gramoj),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramoj),
						'one' => q({0} gramo),
						'other' => q({0} gramoj),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramoj),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramoj),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramoj),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramoj),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q(po {0} por {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q(po {0} por {1}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometroj en horo),
						'one' => q({0} kilometro en horo),
						'other' => q({0} kilometroj en horo),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometroj en horo),
						'one' => q({0} kilometro en horo),
						'other' => q({0} kilometroj en horo),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradoj celsiaj),
						'one' => q({0} grado celsia),
						'other' => q({0} gradoj celsiaj),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradoj celsiaj),
						'one' => q({0} grado celsia),
						'other' => q({0} gradoj celsiaj),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0} oble {1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0} oble {1}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litroj),
						'one' => q({0} litro),
						'other' => q({0} litroj),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litroj),
						'one' => q({0} litro),
						'other' => q({0} litroj),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direkto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direkto),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(jc.),
						'one' => q({0} jc.),
						'other' => q({0} jc.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(jc.),
						'one' => q({0} jc.),
						'other' => q({0} jc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(jd.),
						'one' => q({0} jd.),
						'other' => q({0} jd.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(jd.),
						'one' => q({0} jd.),
						'other' => q({0} jd.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h.),
						'one' => q({0}h.),
						'other' => q({0}h.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h.),
						'one' => q({0}h.),
						'other' => q({0}h.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(n.),
						'one' => q({0} n.),
						'other' => q({0} n.),
						'per' => q({0}/n.),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(n.),
						'one' => q({0} n.),
						'other' => q({0} n.),
						'per' => q({0}/n.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}lj),
						'other' => q({0}lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}lj),
						'other' => q({0}lj),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direkto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direkto),
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
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(jarcent.),
						'one' => q({0} jarcent.),
						'other' => q({0} jarcent.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(jarcent.),
						'one' => q({0} jarcent.),
						'other' => q({0} jarcent.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(tago),
						'one' => q({0} t.),
						'other' => q({0} t.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(tago),
						'one' => q({0} t.),
						'other' => q({0} t.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(jardek.),
						'one' => q({0} jardek.),
						'other' => q({0} jardek.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(jardek.),
						'one' => q({0} jardek.),
						'other' => q({0} jardek.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(horo),
						'one' => q({0} h.),
						'other' => q({0} h.),
						'per' => q({0}/h.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(horo),
						'one' => q({0} h.),
						'other' => q({0} h.),
						'per' => q({0}/h.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekundo),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekundo),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuto),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuto),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(monato),
						'one' => q({0} mon.),
						'other' => q({0} mon.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(monato),
						'one' => q({0} mon.),
						'other' => q({0} mon.),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nokt.),
						'one' => q({0} nokt.),
						'other' => q({0} nokt.),
						'per' => q({0}/nokto),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nokt.),
						'one' => q({0} nokt.),
						'other' => q({0} nokt.),
						'per' => q({0}/nokto),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundo),
						'one' => q({0} s.),
						'other' => q({0} s.),
						'per' => q({0}/s.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundo),
						'one' => q({0} s.),
						'other' => q({0} s.),
						'per' => q({0}/s.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semajno),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semajno),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(j.),
						'one' => q({0} j.),
						'other' => q({0} j.),
						'per' => q({0}/j.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(j.),
						'one' => q({0} j.),
						'other' => q({0} j.),
						'per' => q({0}/j.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jes|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ne|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} kaj {1}),
				2 => q({0} kaj {1}),
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
			'superscriptingExponent' => q(⋅),
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
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 miliono',
					'other' => '0 milionoj',
				},
				'10000000' => {
					'one' => '00 miliono',
					'other' => '00 milionoj',
				},
				'100000000' => {
					'one' => '000 miliono',
					'other' => '000 milionoj',
				},
				'1000000000' => {
					'one' => '0 miliardo',
					'other' => '0 miliardoj',
				},
				'10000000000' => {
					'one' => '00 miliardo',
					'other' => '00 miliardoj',
				},
				'100000000000' => {
					'one' => '000 miliardo',
					'other' => '000 miliardoj',
				},
				'1000000000000' => {
					'one' => '0 duiliono',
					'other' => '0 duilionoj',
				},
				'10000000000000' => {
					'one' => '00 duiliono',
					'other' => '00 duilionoj',
				},
				'100000000000000' => {
					'one' => '000 duiliono',
					'other' => '000 duilionoj',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0k',
					'other' => '0k',
				},
				'10000' => {
					'one' => '00k',
					'other' => '00k',
				},
				'100000' => {
					'one' => '000k',
					'other' => '000k',
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
						'positive' => '#,##0.00 ¤',
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
		'AED' => {
			display_name => {
				'currency' => q(dirhamo de Unuiĝintaj Arabaj Emirlandoj),
				'one' => q(UAE-dirhamo),
				'other' => q(UAE-dirhamoj),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgana afganio),
				'one' => q(afgana afganio),
				'other' => q(afganaj afganioj),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albana leko),
				'one' => q(albana leko),
				'other' => q(albanaj lekoj),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armena dramo),
				'one' => q(armena dramo),
				'other' => q(armenaj dramoj),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nederlandantila guldeno),
				'one' => q(nederlandantila guldeno),
				'other' => q(nederlandantilaj guldenoj),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angola kvanzo),
				'one' => q(angola kvanzo),
				'other' => q(angolaj kvanzoj),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentina peso),
				'one' => q(argentina peso),
				'other' => q(argentinaj pesoj),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(aŭstralia dolaro),
				'one' => q(aŭstralia dolaro),
				'other' => q(aŭstraliaj dolaroj),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(aruba guldeno),
				'one' => q(aruba guldeno),
				'other' => q(arubaj guldenoj),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajĝana manato),
				'one' => q(azerbajĝana manato),
				'other' => q(azerbajĝanaj manatoj),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(konvertebla marko de Bosnujo kaj Hercegovino),
				'one' => q(konvertebla marko),
				'other' => q(konverteblaj markoj),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbada dolaro),
				'one' => q(barbada dolaro),
				'other' => q(barbadaj dolaroj),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeŝa tako),
				'one' => q(bangladeŝa tako),
				'other' => q(bangladeŝaj takoj),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgara levo),
				'one' => q(bulgara levo),
				'other' => q(bulgaraj levoj),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(barejna dinaro),
				'one' => q(barejna dinaro),
				'other' => q(barejnaj dinaroj),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burunda franko),
				'one' => q(burunda franko),
				'other' => q(burundaj frankoj),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermuda dolaro),
				'one' => q(bermuda dolaro),
				'other' => q(bermudaj dolaroj),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneja dolaro),
				'one' => q(bruneja dolaro),
				'other' => q(brunejaj dolaroj),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivia bolivjano),
				'one' => q(bolivia bolivjano),
				'other' => q(boliviaj bolivjanoj),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazila realo),
				'one' => q(brazila realo),
				'other' => q(brazilaj realoj),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahama dolaro),
				'one' => q(bahama dolaro),
				'other' => q(bahamaj dolaroj),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(butana ngultrumo),
				'one' => q(butana ngultrumo),
				'other' => q(butanaj ngultrumoj),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(bocvana pulao),
				'one' => q(bocvana pulao),
				'other' => q(bocvanaj pulaoj),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(belorusa rublo),
				'one' => q(belorusa rublo),
				'other' => q(belorusaj rubloj),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(beliza dolaro),
				'one' => q(beliza dolaro),
				'other' => q(belizaj dolaroj),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanada dolaro),
				'one' => q(kanada dolaro),
				'other' => q(kanadaj dolaroj),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(konga franko),
				'one' => q(konga franko),
				'other' => q(kongaj frankoj),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(svisa franko),
				'one' => q(svisa franko),
				'other' => q(svisaj frankoj),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(ĉilia peso),
				'one' => q(ĉilia peso),
				'other' => q(ĉiliaj pesoj),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(ĉina juano \(eksterlanda uzo\)),
				'one' => q(ĉina juano \(eksterlande\)),
				'other' => q(ĉinaj juanoj \(eksterlande\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(ĉinaj juanoj),
				'one' => q(ĉina juano),
				'other' => q(ĉinaj juanoj),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolombia peso),
				'one' => q(kolombia peso),
				'other' => q(kolombiaj pesoj),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarika kolumbo),
				'one' => q(kostarika kolumbo),
				'other' => q(kostarikaj kolumboj),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(konvertebla kuba peso),
				'one' => q(konvertebla kuba peso),
				'other' => q(konverteblaj kubaj pesoj),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kuba peso),
				'one' => q(kuba peso),
				'other' => q(kubaj pesoj),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kaboverda eskudo),
				'one' => q(kaboverda eskudo),
				'other' => q(kaboverdaj eskudoj),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(ĉeĥa krono),
				'one' => q(ĉeĥa krono),
				'other' => q(ĉeĥaj kronoj),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(ĝibutia franko),
				'one' => q(ĝibutia franko),
				'other' => q(ĝibutiaj frankoj),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dana krono),
				'one' => q(dana krono),
				'other' => q(danaj kronoj),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominika peso),
				'one' => q(dominika peso),
				'other' => q(dominikaj pesoj),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alĝeria dinaro),
				'one' => q(alĝeria dinaro),
				'other' => q(alĝeriaj dinaroj),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egipta pundo),
				'one' => q(egipta pundo),
				'other' => q(egiptaj pundoj),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrea nakfo),
				'one' => q(eritrea nakfo),
				'other' => q(eritreaj nakfoj),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopa birro),
				'one' => q(etiopa birro),
				'other' => q(etiopaj birroj),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(eŭro),
				'one' => q(eŭro),
				'other' => q(eŭroj),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fiĝia dolaro),
				'one' => q(fiĝia dolaro),
				'other' => q(fiĝiaj dolaroj),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklanda pundo),
				'one' => q(falklanda pundo),
				'other' => q(falklandaj pundoj),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(brita pundo),
				'one' => q(brita pundo),
				'other' => q(britaj pundoj),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(kartvela lario),
				'one' => q(kartvela lario),
				'other' => q(kartvelaj larioj),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ganaa cedio),
				'one' => q(ganaa cedio),
				'other' => q(ganaaj cedioj),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(ĝibraltara pundo),
				'one' => q(ĝibraltara pundo),
				'other' => q(ĝibraltaraj pundoj),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambia dalasio),
				'one' => q(gambia dalasio),
				'other' => q(gambiaj dalasioj),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(gvinea franko),
				'one' => q(gvinea franko),
				'other' => q(gvineaj frankoj),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(gvatemala kecalo),
				'one' => q(gvatemala kecalo),
				'other' => q(gvatemalaj kecaloj),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(gujana dolaro),
				'one' => q(gujana dolaro),
				'other' => q(gujanaj dolaroj),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(honkonga dolaro),
				'one' => q(honkonga dolaro),
				'other' => q(honkongaj dolaroj),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(hondura lempiro),
				'one' => q(hondura lempiro),
				'other' => q(honduraj lempiroj),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroata kunao),
				'one' => q(kroata kunao),
				'other' => q(kroataj kunaoj),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitia gurdo),
				'one' => q(haitia gurdo),
				'other' => q(haitiaj gurdoj),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(hungara forinto),
				'one' => q(hungara forinto),
				'other' => q(hungaraj forintoj),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonezia rupio),
				'one' => q(indonezia rupio),
				'other' => q(indoneziaj rupioj),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(israela nova siklo),
				'one' => q(israela nova siklo),
				'other' => q(israelaj novaj sikloj),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(hinda rupio),
				'one' => q(hinda rupio),
				'other' => q(hindaj rupioj),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iraka dinaro),
				'one' => q(iraka dinaro),
				'other' => q(irakaj dinaroj),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(irana rialo),
				'one' => q(irana rialo),
				'other' => q(iranaj rialoj),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islanda krono),
				'one' => q(islanda krono),
				'other' => q(islandaj kronoj),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamajka dolaro),
				'one' => q(jamajka dolaro),
				'other' => q(jamajkaj dolaroj),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordania dinaro),
				'one' => q(jordania dinaro),
				'other' => q(jordaniaj dinaroj),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japana eno),
				'one' => q(japana eno),
				'other' => q(japanaj enoj),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenja ŝilingo),
				'one' => q(kenja ŝilingo),
				'other' => q(kenjaj ŝilingoj),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiza somo),
				'one' => q(kirgiza somo),
				'other' => q(kirgizaj somoj),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kamboĝa rielo),
				'one' => q(kamboĝa rielo),
				'other' => q(kamboĝaj rieloj),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komora franko),
				'one' => q(komora franko),
				'other' => q(komoraj frankoj),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nordkorea vono),
				'one' => q(nordkorea vono),
				'other' => q(nordkoreaj vonoj),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(sudkorea vono),
				'one' => q(sudkorea vono),
				'other' => q(sudkoreaj vonoj),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvajta dinaro),
				'one' => q(kuvajta dinaro),
				'other' => q(kuvajtaj dinaroj),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmana dolaro),
				'one' => q(kajmana dolaro),
				'other' => q(kajmanaj dolaroj),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazaĥa tengo),
				'one' => q(kazaĥa tengo),
				'other' => q(kazaĥaj tengoj),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laosa kipo),
				'one' => q(laosa kipo),
				'other' => q(laosaj kipoj),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libana liro),
				'one' => q(libana liro),
				'other' => q(libanaj liroj),
			},
		},
		'LKR' => {
			symbol => '₨',
			display_name => {
				'currency' => q(srilanka rupio),
				'one' => q(srilanka rupio),
				'other' => q(srilankaj rupioj),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberia dolaro),
				'one' => q(liberia dolaro),
				'other' => q(liberiaj dolaroj),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesota lotio),
				'one' => q(lesota lotio),
				'other' => q(lesotaj lotioj),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libia dinaro),
				'one' => q(libia dinaro),
				'other' => q(libiaj dinaroj),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(maroka dirhamo),
				'one' => q(maroka dirhamo),
				'other' => q(marokaj dirhamoj),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldava leo),
				'one' => q(moldava leo),
				'other' => q(moldavaj leoj),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskara ariaro),
				'one' => q(madagaskara ariaro),
				'other' => q(madagaskaraj ariaroj),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedona denaro),
				'one' => q(makedona denaro),
				'other' => q(makedonaj denaroj),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(birma kjato),
				'one' => q(birma kjato),
				'other' => q(birmaj kjatoj),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongola tugriko),
				'one' => q(mongola tugriko),
				'other' => q(mongolaj tugrikoj),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaa patako),
				'one' => q(makaa patako),
				'other' => q(makaaj patakoj),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(maŭritania uguijao),
				'one' => q(maŭritania uguijao),
				'other' => q(maŭritaniaj uguijaoj),
			},
		},
		'MUR' => {
			symbol => '₨',
			display_name => {
				'currency' => q(maŭricia rupio),
				'one' => q(maŭricia rupio),
				'other' => q(maŭriciaj rupioj),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldiva rufijao),
				'one' => q(maldiva rufijao),
				'other' => q(maldivaj rufijaoj),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malavia kvaĉo),
				'one' => q(malavia kvaĉo),
				'other' => q(malaviaj kvaĉoj),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(meksika peso),
				'one' => q(meksika peso),
				'other' => q(meksikaj pesoj),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajzia ringito),
				'one' => q(malajzia ringito),
				'other' => q(malajziaj ringitoj),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambika metikalo),
				'one' => q(mozambika metikalo),
				'other' => q(mozambikaj metikaloj),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibia dolaro),
				'one' => q(namibia dolaro),
				'other' => q(namibiaj dolaroj),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(niĝeria najro),
				'one' => q(niĝeria najro),
				'other' => q(niĝeriaj najroj),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaragva kordovo),
				'one' => q(nikaragva kordovo),
				'other' => q(nikaragvaj kordovoj),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norvega krono),
				'one' => q(norvega krono),
				'other' => q(norvegaj kronoj),
			},
		},
		'NPR' => {
			symbol => '₨',
			display_name => {
				'currency' => q(nepala rupio),
				'one' => q(nepala rupio),
				'other' => q(nepalaj rupioj),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(novzelanda dolaro),
				'one' => q(novzelanda dolaro),
				'other' => q(novzelandaj dolaroj),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omana rialo),
				'one' => q(omana rialo),
				'other' => q(omanaj rialoj),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panama balboo),
				'one' => q(panama balboo),
				'other' => q(panamaj balbooj),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(perua suno),
				'one' => q(perua suno),
				'other' => q(peruaj sunoj),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuonovgvinea kinao),
				'one' => q(papuonovgvinea kinao),
				'other' => q(papuonovgvineaj kinaoj),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipina peso),
				'one' => q(filipina peso),
				'other' => q(filipinaj pesoj),
			},
		},
		'PKR' => {
			symbol => '₨',
			display_name => {
				'currency' => q(pakistana rupio),
				'one' => q(pakistana rupio),
				'other' => q(pakistanaj rupioj),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(pola zloto),
				'one' => q(pola zloto),
				'other' => q(polaj zlotoj),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paragvaja gvaranio),
				'one' => q(paragvaja gvaranio),
				'other' => q(paragvajaj gvaranioj),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katara rialo),
				'one' => q(katara rialo),
				'other' => q(kataraj rialoj),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumana leo),
				'one' => q(rumana leo),
				'other' => q(rumanaj leoj),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serba dinaro),
				'one' => q(serba dinaro),
				'other' => q(serbaj dinaroj),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rusa rublo),
				'one' => q(rusa rublo),
				'other' => q(rusaj rubloj),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruanda franko),
				'one' => q(ruanda franko),
				'other' => q(ruandaj frankoj),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(sauda rialo),
				'one' => q(sauda rialo),
				'other' => q(saudaj rialoj),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomona dolaro),
				'one' => q(salomona dolaro),
				'other' => q(salomonaj dolaroj),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sejŝela rupio),
				'one' => q(sejŝela rupio),
				'other' => q(sejŝelaj rupioj),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudana pundo),
				'one' => q(sudana pundo),
				'other' => q(sudanaj pundoj),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(sveda krono),
				'one' => q(sveda krono),
				'other' => q(svedaj kronoj),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapura dolaro),
				'one' => q(singapura dolaro),
				'other' => q(singapuraj dolaroj),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sankthelena pundo),
				'one' => q(sankthelena pundo),
				'other' => q(sankthelenaj pundoj),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sieraleona leono),
				'one' => q(sieraleona leono),
				'other' => q(sieraleonaj leonoj),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sieraleona leono \(1964–2022\)),
				'one' => q(sieraleona leono \(1964–2022\)),
				'other' => q(sieraleonaj leonoj \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somala ŝilingo),
				'one' => q(somala ŝilingo),
				'other' => q(somalaj ŝilingoj),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinama dolaro),
				'one' => q(surinama dolaro),
				'other' => q(surinamaj dolaroj),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sudsudana pundo),
				'one' => q(sudsudana pundo),
				'other' => q(sudsudanaj pundoj),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(santomea dobro),
				'one' => q(santomea dobro),
				'other' => q(santomeaj dobroj),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(siria pundo),
				'one' => q(siria pundo),
				'other' => q(siriaj pundoj),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(svazilanda liliagenio),
				'one' => q(svazia lilangenio),
				'other' => q(svaziaj lilangenioj),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(taja bahto),
				'one' => q(taja bahto),
				'other' => q(tajaj bahtoj),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(taĝika somonio),
				'one' => q(taĝika somonio),
				'other' => q(taĝikaj somonioj),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmena manato),
				'one' => q(turkmena manato),
				'other' => q(turkmenaj manatoj),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunizia dinaro),
				'one' => q(tunizia dinaro),
				'other' => q(tuniziaj dinaroj),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonga paangao),
				'one' => q(tonga paangao),
				'other' => q(tongaj paangaoj),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turka liro),
				'one' => q(turka liro),
				'other' => q(turkaj liroj),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidada dolaro),
				'one' => q(trinidada dolaro),
				'other' => q(trinidadaj dolaroj),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(tajvana nova dolaro),
				'one' => q(tajvana nova dolaro),
				'other' => q(tajvanaj novaj dolaroj),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzania ŝilingo),
				'one' => q(tanzania ŝilingo),
				'other' => q(tanzaniaj ŝilingoj),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukraina hrivno),
				'one' => q(ukraina hrivno),
				'other' => q(ukrainaj hrivnoj),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(uganda ŝilingo),
				'one' => q(uganda ŝilingo),
				'other' => q(ugandaj ŝilingoj),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(usona dolaro),
				'one' => q(usona dolaro),
				'other' => q(usonaj dolaroj),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(urugvaja peso),
				'one' => q(urugvaja peso),
				'other' => q(urugvajaj pesoj),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbeka somo),
				'one' => q(uzbeka somo),
				'other' => q(uzbekaj somoj),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuela bolivaro),
				'one' => q(venezuela bolivaro),
				'other' => q(venezuelaj bolivaroj),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vjetnama dongo),
				'one' => q(vjetnama dongo),
				'other' => q(vjetnamaj dongoj),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatua vatuo),
				'one' => q(vanuatua vatuo),
				'other' => q(vanuatuaj vatuoj),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoa talao),
				'one' => q(samoa talao),
				'other' => q(samoaj talaoj),
			},
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(ekvatorafrika franko),
				'one' => q(ekvatorafrika franko),
				'other' => q(ekvatorafrikaj frankoj),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(arĝento),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(oro),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(eŭropa monunuo),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(orientkariba dolaro),
				'one' => q(orientkariba dolaro),
				'other' => q(orientkaribaj dolaroj),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franca ora franko),
			},
		},
		'XOF' => {
			symbol => 'XOF',
			display_name => {
				'currency' => q(okcidentafrika franko),
				'one' => q(okcidentafrika franko),
				'other' => q(okcidentafrikaj frankoj),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladio),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(pacifika franko),
				'one' => q(pacifika franko),
				'other' => q(pacifikaj frankoj),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(plateno),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(nekonata monunuo),
				'one' => q(\(nekunata monunuo\)),
				'other' => q(\(nekonata monunuo\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemena rialo),
				'one' => q(jemena rialo),
				'other' => q(jemenaj rialoj),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sudafrika rando),
				'one' => q(sudafrika rando),
				'other' => q(sudafrikaj randoj),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambia kvaĉo),
				'one' => q(zambia kvaĉo),
				'other' => q(zambiaj kvaĉoj),
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
							'Mar',
							'Apr',
							'Maj',
							'Jun',
							'Jul',
							'Aŭg',
							'Sep',
							'Okt',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januaro',
							'Februaro',
							'Marto',
							'Aprilo',
							'Majo',
							'Junio',
							'Julio',
							'Aŭgusto',
							'Septembro',
							'Oktobro',
							'Novembro',
							'Decembro'
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
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'ĵa',
						fri => 've',
						sat => 'sa',
						sun => 'di'
					},
					wide => {
						mon => 'lundo',
						tue => 'mardo',
						wed => 'merkredo',
						thu => 'ĵaŭdo',
						fri => 'vendredo',
						sat => 'sabato',
						sun => 'dimanĉo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'ĵ',
						fri => 'v',
						sat => 's',
						sun => 'd'
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
					abbreviated => {0 => '1. jk.',
						1 => '2. jk.',
						2 => '3. jk.',
						3 => '4. jk.'
					},
					wide => {0 => '1-a jarkvarono',
						1 => '2-a jarkvarono',
						2 => '3-a jarkvarono',
						3 => '4-a jarkvarono'
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
					'am' => q{atm},
					'pm' => q{ptm},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
				'0' => 'a.n.e.',
				'1' => 'n.e.'
			},
			wide => {
				'0' => 'antaŭ nia erao',
				'1' => 'de nia erao'
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
			'full' => q{EEEE, 'la' d-'a' 'de' MMMM y G},
			'long' => q{G y-MMMM-dd},
			'medium' => q{G y-MMM-dd},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, 'la' d-'a' 'de' MMMM y},
			'long' => q{y-MMMM-dd},
			'medium' => q{y-MMM-dd},
			'short' => q{yy-MM-dd},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d MMM y G},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M y GGGGG},
			yyyyMEd => q{E, y-MM-dd GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{y-MM-dd GGGGG},
			yyyyQQQ => q{QQQ 'de' y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
		},
		'gregorian' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d MMM y G},
			MEd => q{E, MM-dd},
			MMM => q{MMM},
			MMMEd => q{E, d MMM},
			MMMMW => q{W-'a' 'semajno' 'de' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			yMEd => q{E, y-MM-dd},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{w-'a' 'semajno' 'de' Y},
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
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MMM y GGGGG – MMM y GGGGG},
				M => q{MMM – MMM y GGGGG},
				y => q{MMM y – MMM y GGGGG},
			},
			GyMEd => {
				G => q{E, d MMM y GGGGG – E, d MMM y GGGGG},
				M => q{E, d MMM – E, d MMM y GGGGG},
				d => q{E, d – E, d MMM y GGGGG},
				y => q{E, d MMM y – E, d MMM y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d MMM – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d MMM y GGGGG – d MMM y GGGGG},
				M => q{d MMM – d MMM y GGGGG},
				d => q{d – d MMM y GGGGG},
				y => q{d MMM y – d MMM y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d – d},
			},
			h => {
				h => q{h–h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{y-MM – y-MM GGGGG},
				y => q{y-MM – y-MM GGGGG},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd GGGGG},
				d => q{E, y-MM-dd – E, y-MM-dd GGGGG},
				y => q{E, y-MM-dd – E, y-MM-dd GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd GGGGG},
				d => q{y-MM-dd – y-MM-dd GGGGG},
				y => q{y-MM-dd – y-MM-dd GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			MEd => {
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
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
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(tempo de {0}),
		regionFormat => q(somera tempo de {0}),
		regionFormat => q(norma tempo de {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#afgana tempo#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abiĝano#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akrao#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adisabebo#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alĝero#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmero#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bango#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjulo#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisaŭo#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazavilo#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Buĵumburo#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanko#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceŭto#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakrio#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakaro#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daresalamo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Ĝibutio#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Dualao#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ajuno#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaŭno#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborono#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harareo#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johanesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Ĝubao#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampalo#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Ĥartumo#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigalo#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinŝaso#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagoso#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevilo#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomeo#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luando#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaŝo#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusako#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseruo#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabano#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiŝo#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovio#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Najrobio#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Niĝameno#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamejo#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakŝoto#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Vagaduguo#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portonovo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Santomeo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolo#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunizo#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vindhuko#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#centrafrika tempo#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#orientafrika tempo#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#sudafrika tempo#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#okcidentafrika somera tempo#,
				'generic' => q#okcidentafrika tempo#,
				'standard' => q#okcidentafrika norma tempo#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaska somera tempo#,
				'generic' => q#alaska tempo#,
				'standard' => q#alaska norma tempo#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazonia somera tempo#,
				'generic' => q#amazonia tempo#,
				'standard' => q#amazonia norma tempo#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvilo#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigvo#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Saltaurbo#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arubo#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunciono#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahio#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbado#,
		},
		'America/Belem' => {
			exemplarCity => q#Belemo#,
		},
		'America/Belize' => {
			exemplarCity => q#Belizo#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogoto#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Bonaero#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembriĝa Golfo#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankuno#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakaso#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajeno#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmanoj#,
		},
		'America/Chicago' => {
			exemplarCity => q#Ĉikago#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordobo#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostariko#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kuracao#,
		},
		'America/Denver' => {
			exemplarCity => q#Denvero#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detrojto#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominiko#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmontono#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvadoro#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortalezo#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuko#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Granda Turko#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenado#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadelupo#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemalo#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gujano#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifakso#,
		},
		'America/Havana' => {
			exemplarCity => q#Havano#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indianao#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indianao#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indianao#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indianao#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indianao#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indianao#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indianao#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolo, Indianao#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluito#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajko#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentukio#,
		},
		'America/Lima' => {
			exemplarCity => q#Limo#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Losanĝeleso#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Managua' => {
			exemplarCity => q#Managvo#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaŭso#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigoto#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martiniko#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Merida' => {
			exemplarCity => q#Merido#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksikurbo#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelono#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monktono#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterejo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Moncerato#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasaŭo#,
		},
		'America/New_York' => {
			exemplarCity => q#Novjorko#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Norda Dakoto#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Norda Dakoto#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Norda Dakoto#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Fenikso#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Portoprinco#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Portospeno#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puertoriko#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Sankta Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sanpaŭlo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sankta Bartolomeo#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sankta Kristoforo#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sankta Lucio#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sankta Tomaso#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sankta Vincento#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpo#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuvero#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinipego#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#centra nordamerika somera tempo#,
				'generic' => q#centra nordamerika tempo#,
				'standard' => q#centra nordamerika norma tempo#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#orienta nordamerika somera tempo#,
				'generic' => q#orienta nordamerika tempo#,
				'standard' => q#orienta nordamerika norma tempo#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#montara nordamerika somera tempo#,
				'generic' => q#montara nordamerika tempo#,
				'standard' => q#montara nordamerika norma tempo#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#pacifika nordamerika somera tempo#,
				'generic' => q#pacifika nordamerika tempo#,
				'standard' => q#pacifika nordamerika norma tempo#,
			},
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makvora insulo#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apio (somera tempo)#,
				'generic' => q#tempo: Apio#,
				'standard' => q#Apio (norma tempo)#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#araba somera tempo#,
				'generic' => q#araba tempo#,
				'standard' => q#araba norma tempo#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longjerurbo#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentina somera tempo#,
				'generic' => q#argentina tempo#,
				'standard' => q#argentina norma tempo#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#okcident-argentina somera tempo#,
				'generic' => q#okcident-argentina tempo#,
				'standard' => q#okcident-argentina norma tempo#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armena somera tempo#,
				'generic' => q#armena tempo#,
				'standard' => q#armena norma tempo#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adeno#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almato#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amano#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aŝĥabado#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdado#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barejno#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakuo#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bankoko#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejruto#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biŝkeko#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunejo#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkato#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Ĉita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasko#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dako#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dilo#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubajurbo#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duŝanbeo#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gazao#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrono#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Honkongo#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Ĥovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsko#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Ĝakarto#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalemo#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabulo#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamĉatko#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaĉio#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmanduo#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Ĥandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsko#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kualalumpuro#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajto#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manilo#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskato#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozio#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznecko#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsko#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsko#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oralo#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompeno#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjongjango#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Kataro#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilordo#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranguno#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riado#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hoĉimino#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saĥaleno#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkando#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seulo#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Ŝanhajo#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapuro#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpeo#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taŝkento#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbiliso#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherano#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timbuo#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbatoro#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumĉio#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ustnero#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vjentiano#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostoko#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsko#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevano#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantika nordamerika somera tempo#,
				'generic' => q#atlantika nordamerika tempo#,
				'standard' => q#atlantika nordamerika norma tempo#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Acoroj#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudoj#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarioj#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaboverdo#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ferooj#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madejro#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rejkjaviko#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sud-Georgio#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sankta Heleno#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanlejo#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelajdo#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbano#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvino#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobarto#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburno#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perto#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidnejo#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#centra aŭstralia somera tempo#,
				'generic' => q#centra aŭstralia tempo#,
				'standard' => q#centra aŭstralia norma tempo#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#centrokcidenta aŭstralia somera tempo#,
				'generic' => q#centrokcidenta aŭstralia tempo#,
				'standard' => q#centrokcidenta aŭstralia norma tempo#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#orienta aŭstralia somera tempo#,
				'generic' => q#orienta aŭstralia tempo#,
				'standard' => q#orienta aŭstralia norma tempo#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#okcidenta aŭstralia somera tempo#,
				'generic' => q#okcidenta aŭstralia tempo#,
				'standard' => q#okcidenta aŭstralia norma tempo#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajĝana somera tempo#,
				'generic' => q#azerbajĝana tempo#,
				'standard' => q#azerbajĝana norma tempo#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Acoroj (somera tempo)#,
				'generic' => q#tempo: Acoroj#,
				'standard' => q#Acoroj (norma tempo)#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeŝa somera tempo#,
				'generic' => q#bangladeŝa tempo#,
				'standard' => q#bangladeŝa norma tempo#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#butana tempo#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolivia tempo#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brazilja somera tempo#,
				'generic' => q#brazilja tempo#,
				'standard' => q#brazilja norma tempo#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#bruneja tempo#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kaboverda somera tempo#,
				'generic' => q#kaboverda tempo#,
				'standard' => q#kaboverda norma tempo#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ĉamora tempo#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ĉathama somera tempo#,
				'generic' => q#ĉathama tempo#,
				'standard' => q#ĉathama norma tempo#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ĉilia somera tempo#,
				'generic' => q#ĉilia tempo#,
				'standard' => q#ĉilia norma tempo#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ĉina somera tempo#,
				'generic' => q#ĉina tempo#,
				'standard' => q#ĉina norma tempo#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#kristnaskinsula tempo#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#kokosinsula tempo#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolombia somera tempo#,
				'generic' => q#kolombia tempo#,
				'standard' => q#kolombia norma tempo#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#kukinsula somera tempo#,
				'generic' => q#kukinsula tempo#,
				'standard' => q#kukinsula norma tempo#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubo (somera tempo)#,
				'generic' => q#tempo: Kubo#,
				'standard' => q#Kubo (norma tempo)#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#tempo: Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#tempo: Dumont d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#orient-timora tempo#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#paskinsula somera tempo#,
				'generic' => q#paskinsula tempo#,
				'standard' => q#paskinsula norma tempo#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ekvadora tempo#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#universala tempo kunordigita#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#nekonata urbo#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdamo#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andoro#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astraĥano#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateno#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beogrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlino#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislavo#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruselo#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukareŝto#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeŝto#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen am Hochrhein#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kiŝinevo#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhago#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublino#,
			long => {
				'daylight' => q#irlanda norma tempo#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Ĝibraltaro#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernezejo#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinko#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mankinsulo#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbulo#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Ĵerzejo#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kievo#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbono#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljano#,
		},
		'Europe/London' => {
			exemplarCity => q#Londono#,
			long => {
				'daylight' => q#brita somera tempo#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburgo#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrido#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malto#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsko#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskvo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parizo#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorico#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prago#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rigo#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Romo#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Sanmarino#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopolo#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopjo#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofio#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talino#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirano#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsko#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduzo#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vieno#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilno#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovio#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagrebo#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zuriko#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#centreŭropa somera tempo#,
				'generic' => q#centreŭropa tempo#,
				'standard' => q#centreŭropa norma tempo#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#orienteŭropa somera tempo#,
				'generic' => q#orienteŭropa tempo#,
				'standard' => q#orienteŭropa norma tempo#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ekstrem-orienteŭropa tempo#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#okcidenteŭropa somera tempo#,
				'generic' => q#okcidenteŭropa tempo#,
				'standard' => q#okcidenteŭropa norma tempo#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falklanda somera tempo#,
				'generic' => q#falklanda tempo#,
				'standard' => q#falklanda norma tempo#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fiĝia somera tempo#,
				'generic' => q#fiĝia tempo#,
				'standard' => q#fiĝia norma tempo#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#tempo: Franca Gujano#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#tempo: Francaj Sudaj Teritorioj#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#universala tempo kunordigita#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#galapaga tempo#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#tempo: Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#kartvela somera tempo#,
				'generic' => q#kartvela tempo#,
				'standard' => q#kartvela norma tempo#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#gilbertinsula tempo#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#orienta gronlanda somera tempo#,
				'generic' => q#orienta gronlanda tempo#,
				'standard' => q#orienta gronlanda norma tempo#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#okcidenta gronlanda somera tempo#,
				'generic' => q#okcidenta gronlanda tempo#,
				'standard' => q#okcidenta gronlanda norma tempo#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#arabgolfa norma tempo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#gujana tempo#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajo-Aleutoj (somera tempo)#,
				'generic' => q#tempo: Havajo-Aleutoj#,
				'standard' => q#Havajo-Aleutoj (norma tempo)#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#honkonga somera tempo#,
				'generic' => q#honkonga tempo#,
				'standard' => q#honkonga norma tempo#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ĥovda somera tempo#,
				'generic' => q#ĥovda tempo#,
				'standard' => q#ĥovda norma tempo#,
			},
		},
		'India' => {
			long => {
				'standard' => q#hinda norma tempo#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Ĉagosoj#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kristnaskinsulo#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosinsuloj#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoroj#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelenoj#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivoj#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maŭricio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Majoto#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunio#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#hindoceana tempo#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#hindoĉina tempo#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#centr-indonezia tempo#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#orient-indonezia tempo#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#okcident-indonezia tempo#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#irana somera tempo#,
				'generic' => q#irana tempo#,
				'standard' => q#irana norma tempo#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#irkutska somera tempo#,
				'generic' => q#irkutska tempo#,
				'standard' => q#irkutska norma tempo#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israela somera tempo#,
				'generic' => q#israela tempo#,
				'standard' => q#israela norma tempo#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japana somera tempo#,
				'generic' => q#japana tempo#,
				'standard' => q#japana norma tempo#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#kazaĥa tempo#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#orient-kazaĥa tempo#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#okcident-kazaĥa tempo#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korea somera tempo#,
				'generic' => q#korea tempo#,
				'standard' => q#korea norma tempo#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#tempo: Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krasnojarska somera tempo#,
				'generic' => q#krasnojarska tempo#,
				'standard' => q#krasnojarska norma tempo#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgiza tempo#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#tempo: Liniaj Insuloj#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe (somera tempo)#,
				'generic' => q#tempo: Lord Howe#,
				'standard' => q#Lord Howe (norma tempo)#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#magadana somera tempo#,
				'generic' => q#magadana tempo#,
				'standard' => q#magadana norma tempo#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malajzia tempo#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldiva tempo#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#markizinsula tempo#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#marŝalinsula tempo#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#maŭricia somera tempo#,
				'generic' => q#maŭricia tempo#,
				'standard' => q#maŭricia norma tempo#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#tempo: Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#pacifika meksika somera tempo#,
				'generic' => q#pacifika meksika tempo#,
				'standard' => q#pacifika meksika norma tempo#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ulanbatora somera tempo#,
				'generic' => q#ulanbatora tempo#,
				'standard' => q#ulanbatora norma tempo#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moskva somera tempo#,
				'generic' => q#moskva tempo#,
				'standard' => q#moskva norma tempo#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#birma tempo#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#naura tempo#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepala tempo#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#novkaledonia somera tempo#,
				'generic' => q#novkaledonia tempo#,
				'standard' => q#novkaledonia norma tempo#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#novzelanda somera tempo#,
				'generic' => q#novzelanda tempo#,
				'standard' => q#novzelanda norma tempo#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Novlando (somera tempo)#,
				'generic' => q#tempo: Novlando#,
				'standard' => q#Novlando (norma tempo)#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niua tempo#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#norfolkinsula somera tempo#,
				'generic' => q#norfolkinsula tempo#,
				'standard' => q#norfolkinsula norma tempo#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha (somera tempo)#,
				'generic' => q#tempo: Fernando de Noronha#,
				'standard' => q#Fernando de Noronha (norma tempo)#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#novosibirska somera tempo#,
				'generic' => q#novosibirska tempo#,
				'standard' => q#novosibirska norma tempo#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#omska somera tempo#,
				'generic' => q#omska tempo#,
				'standard' => q#omska norma tempo#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apio#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Aŭklando#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Ĉathamo#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskinsulo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiĝio#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafutio#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagoj#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Gvamo#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markizinsuloj#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvejinsuloj#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauro#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niuo#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolkinsulo#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numeo#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pagopago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palaŭo#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkarna Insulo#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotongo#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipano#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahitio#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Taravo#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Ĉuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Vejkinsulo#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Valiso#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistana somera tempo#,
				'generic' => q#pakistana tempo#,
				'standard' => q#pakistana norma tempo#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palaŭa tempo#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#tempo: Papuo-Nov-Gvineo#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paragvaja somera tempo#,
				'generic' => q#paragvaja tempo#,
				'standard' => q#paragvaja norma tempo#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#perua somera tempo#,
				'generic' => q#perua tempo#,
				'standard' => q#perua norma tempo#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filipina somera tempo#,
				'generic' => q#filipina tempo#,
				'standard' => q#filipina norma tempo#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#feniksinsula tempo#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sankta Piero kaj Mikelono (somera tempo)#,
				'generic' => q#tempo: Sankta Piero kaj Mikelono#,
				'standard' => q#Sankta Piero kaj Mikelono (norma tempo)#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#pitkarninsula tempo#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#tempo: Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pjongjanga tempo#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#tempo: Reunio#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#tempo: Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#saĥalena somera tempo#,
				'generic' => q#saĥalena tempo#,
				'standard' => q#saĥalena norma tempo#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoa somera tempo#,
				'generic' => q#samoa tempo#,
				'standard' => q#samoa norma tempo#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#sejŝela tempo#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singapura norma tempo#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#tempo: Salomonoj#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#tempo: Sud-Georgio#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinama tempo#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#tempo: Showa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitia tempo#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#tajpea somera tempo#,
				'generic' => q#tajpea tempo#,
				'standard' => q#tajpea norma tempo#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#taĝika tempo#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tokelaa tempo#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tonga somera tempo#,
				'generic' => q#tonga tempo#,
				'standard' => q#tonga norma tempo#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#tempo: Ĉuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmena somera tempo#,
				'generic' => q#turkmena tempo#,
				'standard' => q#turkmena norma tempo#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvala tempo#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#urugvaja somera tempo#,
				'generic' => q#urugvaja tempo#,
				'standard' => q#urugvaja norma tempo#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbeka somera tempo#,
				'generic' => q#uzbeka tempo#,
				'standard' => q#uzbeka norma tempo#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatua somera tempo#,
				'generic' => q#vanuatua tempo#,
				'standard' => q#vanuatua norma tempo#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuela tempo#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#vladivostoka somera tempo#,
				'generic' => q#vladivostoka tempo#,
				'standard' => q#vladivostoka norma tempo#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#volgograda somera tempo#,
				'generic' => q#volgograda tempo#,
				'standard' => q#volgograda norma tempo#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#tempo: Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#vejkinsula tempo#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#tempo: Valiso kaj Futuno#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#jakutska somera tempo#,
				'generic' => q#jakutska tempo#,
				'standard' => q#jakutska norma tempo#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#jekaterinburga somera tempo#,
				'generic' => q#jekaterinburga tempo#,
				'standard' => q#jekaterinburga norma tempo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#jukonia tempo#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
