=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Eo - Package for language Esperanto

=cut

package Locale::CLDR::Locales::Eo;
# This file auto generated from Data\common\main\eo.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
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
 				'ast' => 'asturia',
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
 				'lil' => 'lilueta',
 				'lkt' => 'lakota',
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
 				'vi' => 'vjetnama',
 				'vo' => 'Volapuko',
 				'vun' => 'kivunja',
 				'wa' => 'valona',
 				'wae' => 'germana valza',
 				'war' => 'varaja',
 				'wo' => 'volofa',
 				'wuu' => 'vua',
 				'xal' => 'kalmuka',
 				'xh' => 'ksosa',
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
 			'BQ' => 'Karibia Nederlando',
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
 			'CR' => 'Kostariko',
 			'CU' => 'Kubo',
 			'CV' => 'Kaboverdo',
 			'CW' => 'Kuracao',
 			'CX' => 'Kristnaskinsulo',
 			'CY' => 'Kipro',
 			'CZ' => 'Ĉeĥujo',
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


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(jardekoj),
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
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jaroj),
						'one' => q({0} jaro),
						'other' => q({0} jaroj),
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
						'name' => q(j.),
						'one' => q({0}j.),
						'other' => q({0}j.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(j.),
						'one' => q({0}j.),
						'other' => q({0}j.),
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
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
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
						'name' => q(jaro),
						'one' => q({0} j.),
						'other' => q({0} j.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jaro),
						'one' => q({0} j.),
						'other' => q({0} j.),
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
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Aŭstralia dolaro),
				'one' => q(aŭstralia dolaro),
				'other' => q(aŭstraliaj dolaroj),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazila realo),
				'one' => q(brazila realo),
				'other' => q(brazilaj realoj),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada dolaro),
				'one' => q(kanada dolaro),
				'other' => q(kanadaj dolaroj),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Svisa franko),
				'one' => q(svisa franko),
				'other' => q(svisaj frankoj),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Ĉina juano),
				'one' => q(ĉina juano),
				'other' => q(ĉinaj juanoj),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Dana krono),
				'one' => q(dana krono),
				'other' => q(danaj kronoj),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Eŭro),
				'one' => q(eŭro),
				'other' => q(eŭroj),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Brita pundo),
				'one' => q(brita pundo),
				'other' => q(britaj pundoj),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Honkonga dolaro),
				'one' => q(honkonga dolaro),
				'other' => q(honkongaj dolaroj),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonezia rupio),
				'one' => q(Indonezia rupio),
				'other' => q(Indoneziaj rupioj),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Barata rupio),
				'one' => q(barata rupio),
				'other' => q(barataj rupioj),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japana eno),
				'one' => q(japana eno),
				'other' => q(japanaj enoj),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Sud-korea ŭono),
				'one' => q(sud-korea ŭono),
				'other' => q(sud-koreaj ŭonoj),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksika peso),
				'one' => q(meksika peso),
				'other' => q(meksikaj pesoj),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norvega krono),
				'one' => q(norvega krono),
				'other' => q(norvegaj kronoj),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Pola zloto),
				'one' => q(pola zloto),
				'other' => q(polaj zlotoj),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rusa rublo),
				'one' => q(rusa rublo),
				'other' => q(rusaj rubloj),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Sauda rialo),
				'one' => q(sauda rialo),
				'other' => q(saudaj rialoj),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sveda krono),
				'one' => q(sveda krono),
				'other' => q(svedaj kronoj),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Taja bahto),
				'one' => q(taja bahto),
				'other' => q(tajaj bahtoj),
			},
		},
		'TRY' => {
			symbol => '₺',
			display_name => {
				'currency' => q(Turka liro),
				'one' => q(turka liro),
				'other' => q(turkaj liroj),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nova tajvana dolaro),
				'one' => q(nova tajvana dolaro),
				'other' => q(novaj tajvanaj dolaroj),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Usona dolaro),
				'one' => q(usona dolaro),
				'other' => q(usonaj dolaroj),
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
		'XFO' => {
			display_name => {
				'currency' => q(franca ora franko),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladio),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(plateno),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nekonata valuto),
				'one' => q(nekonata monunuo),
				'other' => q(nekonataj monunuoj),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Sud-afrika rando),
				'one' => q(sud-afrika rando),
				'other' => q(sud-afrikaj randoj),
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
		'Africa/Abidjan' => {
			exemplarCity => q#Abiĝano#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akrao#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis-Abebo#,
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
			exemplarCity => q#San Miguel de Tucumán#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arubo#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunciono#,
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
		'America/Jujuy' => {
			exemplarCity => q#San Salvador de Jujuy#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentukio#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La-Pazo#,
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
			exemplarCity => q#San-Paŭlo#,
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
		'Asia/Chita' => {
			exemplarCity => q#Ĉita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Ĉoibalsan#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasko#,
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
			exemplarCity => q#Gaza-urbo#,
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
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamĉatko#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Ĥandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsko#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpuro#,
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
				'generic' => q#horzono Acoroj#,
				'standard' => q#Acoroj (norma tempo)#,
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
		'Choibalsan' => {
			long => {
				'daylight' => q#Ĉoibalsan (somera tempo)#,
				'generic' => q#horzono Ĉoibalsan#,
				'standard' => q#Ĉoibalsan (norma tempo)#,
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
		'Cuba' => {
			long => {
				'daylight' => q#Kubo (somera tempo)#,
				'generic' => q#horzono Kubo#,
				'standard' => q#Kubo (norma tempo)#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#horzono Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#horzono Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#orienttimora tempo#,
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
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uĵhorodo#,
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
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporiĵo#,
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
		'French_Guiana' => {
			long => {
				'standard' => q#horzono Franca Gviano#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#horzono Francaj Sudaj Teritorioj#,
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
		'Georgia' => {
			long => {
				'daylight' => q#kartvela somera tempo#,
				'generic' => q#kartvela tempo#,
				'standard' => q#kartvela norma tempo#,
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
				'standard' => q#golfa norma tempo#,
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
				'generic' => q#horzono Havajo-Aleutoj#,
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
				'standard' => q#barata tempo#,
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
				'standard' => q#centra indonezia tempo#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#orienta indonezia tempo#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#okcidenta indonezia tempo#,
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
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#orienta kazaĥa tempo#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#okcidenta kazaĥa tempo#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korea somera tempo#,
				'generic' => q#korea tempo#,
				'standard' => q#korea norma tempo#,
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
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe (somera tempo)#,
				'generic' => q#horzono Lord Howe#,
				'standard' => q#Lord Howe (norma tempo)#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#makvor-insula tempo#,
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
		'Mauritius' => {
			long => {
				'daylight' => q#maŭricia somera tempo#,
				'generic' => q#maŭricia tempo#,
				'standard' => q#maŭricia norma tempo#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#nordokcidenta meksika somera tempo#,
				'generic' => q#nordokcidenta meksika tempo#,
				'standard' => q#nordokcidenta meksika norma tempo#,
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
				'generic' => q#horzono Novlando#,
				'standard' => q#Novlando (norma tempo)#,
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
				'generic' => q#horzono Fernando de Noronha#,
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
		'Pacific/Chatham' => {
			exemplarCity => q#Ĉathamo#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskinsulo#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagoj#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolkinsulo#,
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
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sankta Piero kaj Mikelono (somera tempo)#,
				'generic' => q#horzono Sankta Piero kaj Mikelono#,
				'standard' => q#Sankta Piero kaj Mikelono (norma tempo)#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pjongjanga tempo#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#horzono Reunio#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#saĥalena somera tempo#,
				'generic' => q#saĥalena tempo#,
				'standard' => q#saĥalena norma tempo#,
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
		'South_Georgia' => {
			long => {
				'standard' => q#horzono Sud-Georgio#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinama tempo#,
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
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmena somera tempo#,
				'generic' => q#turkmena tempo#,
				'standard' => q#turkmena norma tempo#,
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
