=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sc - Package for language Sardinian

=cut

package Locale::CLDR::Locales::Sc;
# This file auto generated from Data\common\main\sc.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
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
				'ab' => 'abcasu',
 				'ace' => 'acehnesu',
 				'ada' => 'adangme',
 				'ady' => 'adighè',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'àinu',
 				'ak' => 'akan',
 				'ale' => 'aleutinu',
 				'alt' => 'altai meridionale',
 				'am' => 'amàricu',
 				'an' => 'aragonesu',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'apc' => 'àrabu levantinu',
 				'ar' => 'àrabu',
 				'ar_001' => 'àrabu modernu istandard',
 				'arn' => 'mapudungun',
 				'arp' => 'arapaho',
 				'ars' => 'àrabu najdi',
 				'as' => 'assamesu',
 				'asa' => 'asu',
 				'ast' => 'asturianu',
 				'atj' => 'atikamekw',
 				'av' => 'avaru',
 				'awa' => 'awadhi',
 				'ay' => 'aimara',
 				'az' => 'azerbaigianu',
 				'az@alt=short' => 'azeru',
 				'ba' => 'baschiru',
 				'ban' => 'balinesu',
 				'bas' => 'basaa',
 				'be' => 'bielorussu',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bùlgaru',
 				'bgc' => 'haryanvi',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'pees nieddos',
 				'bm' => 'bambara',
 				'bn' => 'bengalesu',
 				'bo' => 'tibetanu',
 				'br' => 'brètone',
 				'brx' => 'bodo',
 				'bs' => 'bosnìacu',
 				'bug' => 'buginesu',
 				'byn' => 'blin',
 				'ca' => 'catalanu',
 				'cay' => 'cayuga',
 				'ccp' => 'chakma',
 				'ce' => 'cecenu',
 				'ceb' => 'cebuanu',
 				'cgg' => 'chiga',
 				'ch' => 'chamorru',
 				'chk' => 'chuukesu',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'curdu tzentrale',
 				'ckb@alt=menu' => 'curdu, tzentrale',
 				'ckb@alt=variant' => 'curdu, sorani',
 				'clc' => 'chilcotin',
 				'co' => 'corsicanu',
 				'crg' => 'michif',
 				'crj' => 'cree sud-orientale',
 				'crk' => 'cree de sas campuras',
 				'crl' => 'cree nord-orientale',
 				'crm' => 'cree moose',
 				'crr' => 'algonchinu de sa Carolina',
 				'cs' => 'tzecu',
 				'csw' => 'cree de sas paludes',
 				'cu' => 'islavu eclesiàsticu',
 				'cv' => 'ciuvàsciu',
 				'cy' => 'gallesu',
 				'da' => 'danesu',
 				'dak' => 'dakota',
 				'dar' => 'dargua',
 				'dav' => 'taita',
 				'de' => 'tedescu',
 				'de_AT' => 'tedescu austrìacu',
 				'de_CH' => 'tedescu artu isvìtzeru',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'sòrabu bassu',
 				'dua' => 'duala',
 				'dv' => 'malvidianu',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'grecu',
 				'en' => 'inglesu',
 				'en_AU' => 'inglesu australianu',
 				'en_CA' => 'inglesu canadesu',
 				'en_GB' => 'inglesu britànnicu',
 				'en_GB@alt=short' => 'inglesu (RU)',
 				'en_US' => 'inglesu americanu',
 				'en_US@alt=short' => 'inglesu (USA)',
 				'eo' => 'esperanto',
 				'es' => 'ispagnolu',
 				'es_419' => 'ispagnolu latinoamericanu',
 				'es_ES' => 'ispagnolu europeu',
 				'es_MX' => 'ispagnolu messicanu',
 				'et' => 'èstone',
 				'eu' => 'bascu',
 				'ewo' => 'ewondo',
 				'fa' => 'persianu',
 				'fa_AF' => 'dari',
 				'ff' => 'fulah',
 				'fi' => 'finlandesu',
 				'fil' => 'filipinu',
 				'fj' => 'fijianu',
 				'fo' => 'faroesu',
 				'fon' => 'fon',
 				'fr' => 'frantzesu',
 				'fr_CA' => 'frantzesu canadesu',
 				'fr_CH' => 'frantzesu isvìtzeru',
 				'frc' => 'frantzesu cajun',
 				'frr' => 'frisone setentrionale',
 				'fur' => 'friulanu',
 				'fy' => 'frisone otzidentale',
 				'ga' => 'irlandesu',
 				'gaa' => 'ga',
 				'gd' => 'gaèlicu iscotzesu',
 				'gez' => 'ge’ez',
 				'gil' => 'gilbertesu',
 				'gl' => 'galitzianu',
 				'gn' => 'guaranì',
 				'gor' => 'gorontalo',
 				'gsw' => 'tedescu isvìtzeru',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'mannesu',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'hawaianu',
 				'hax' => 'haida meridionale',
 				'he' => 'ebreu',
 				'hi' => 'hindi',
 				'hi_Latn' => 'hindi (caràteres latinos)',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'ilongu',
 				'hmn' => 'hmong',
 				'hr' => 'croatu',
 				'hsb' => 'sòrabu artu',
 				'ht' => 'crèolu haitianu',
 				'hu' => 'ungheresu',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armenu',
 				'hz' => 'herero',
 				'ia' => 'interlìngua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesianu',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ikt' => 'inuktitut canadesu otzidentale',
 				'ilo' => 'ilocanu',
 				'inh' => 'ingùsciu',
 				'io' => 'ido',
 				'is' => 'islandesu',
 				'it' => 'italianu',
 				'iu' => 'inuktitut',
 				'ja' => 'giaponesu',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'giavanesu',
 				'ka' => 'georgianu',
 				'kab' => 'cabilu',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'cabardianu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'cabubirdianu',
 				'kfo' => 'koro',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazacu',
 				'kkj' => 'kako',
 				'kl' => 'groenlandesu',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'coreanu',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'caraciai-balcaru',
 				'krl' => 'carelianu',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'coloniesu',
 				'ku' => 'curdu',
 				'kum' => 'cumucu',
 				'kv' => 'komi',
 				'kw' => 'còrnicu',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'chirghisu',
 				'la' => 'latinu',
 				'lad' => 'giudeu-ispagnolu',
 				'lag' => 'langi',
 				'lb' => 'lussemburghesu',
 				'lez' => 'lezghianu',
 				'lg' => 'ganda',
 				'li' => 'limburghesu',
 				'lij' => 'lìgure',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardu',
 				'ln' => 'lingala',
 				'lo' => 'laotianu',
 				'lou' => 'crèolu de sa Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri setentrionale',
 				'lsm' => 'sàmia',
 				'lt' => 'lituanu',
 				'lu' => 'luba-katanga',
 				'lua' => 'tshiluba',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'lètone',
 				'mad' => 'maduresu',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makassaresu',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'crèolu mauritzianu',
 				'mg' => 'malgàsciu',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallesu',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'matzèdone',
 				'ml' => 'malayalam',
 				'mn' => 'mòngolu',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'moore',
 				'mr' => 'marathi',
 				'ms' => 'malesu',
 				'mt' => 'maltesu',
 				'mua' => 'mundang',
 				'mul' => 'limbas mùltiplas',
 				'mus' => 'muscogee',
 				'mwl' => 'mirandesu',
 				'my' => 'burmesu',
 				'myv' => 'erzya',
 				'mzn' => 'mazandarani',
 				'na' => 'nauru',
 				'nap' => 'napoletanu',
 				'naq' => 'nama',
 				'nb' => 'norvegesu bokmål',
 				'nd' => 'ndebele de su nord',
 				'nds' => 'tedescu bassu',
 				'nds_NL' => 'sàssone bassu',
 				'ne' => 'nepalesu',
 				'new' => 'nepal bhasa',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueanu',
 				'nl' => 'olandesu',
 				'nl_BE' => 'fiammingu',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegesu nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegesu',
 				'nog' => 'nogai',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele de su sud',
 				'nso' => 'sotho setentrionale',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'otzitanu',
 				'ojb' => 'ojibwa nord-otzidentale',
 				'ojc' => 'ojibwa tzentrale',
 				'ojs' => 'oji-Cree',
 				'ojw' => 'ojibwa otzidentale',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossèticu',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiamentu',
 				'pau' => 'palauanu',
 				'pcm' => 'pidgin nigerianu',
 				'pis' => 'pijin',
 				'pl' => 'polacu',
 				'pqm' => 'malecite-passamaquoddy',
 				'prg' => 'prussianu',
 				'ps' => 'pashto',
 				'pt' => 'portoghesu',
 				'pt_BR' => 'portoghesu brasilianu',
 				'pt_PT' => 'portoghesu europeu',
 				'qu' => 'quechua',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonganu',
 				'rhg' => 'rohingya',
 				'rif' => 'rifenu',
 				'rm' => 'romànciu',
 				'rn' => 'rundi',
 				'ro' => 'rumenu',
 				'ro_MD' => 'moldavu',
 				'rof' => 'rombo',
 				'ru' => 'russu',
 				'rup' => 'arumenu',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sànscritu',
 				'sad' => 'sandawe',
 				'sah' => 'yakut',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardu',
 				'scn' => 'sitzilianu',
 				'sco' => 'scots',
 				'sd' => 'sindhi',
 				'se' => 'sami setentrionale',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'shi' => 'tashelhit',
 				'shn' => 'shan',
 				'si' => 'singalesu',
 				'sk' => 'islovacu',
 				'sl' => 'islovenu',
 				'slh' => 'lushootseed meridionale',
 				'sm' => 'samoanu',
 				'smn' => 'sami de sos inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'sòmalu',
 				'sq' => 'albanesu',
 				'sr' => 'serbu',
 				'srn' => 'sranan tongo',
 				'ss' => 'swati',
 				'st' => 'sotho meridionale',
 				'str' => 'salish de sas astrinturas',
 				'su' => 'sundanesu',
 				'suk' => 'sukuma',
 				'sv' => 'isvedesu',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili de su Congo',
 				'swb' => 'comorianu',
 				'syr' => 'sirìacu',
 				'ta' => 'tamil',
 				'tce' => 'tutchone meridionale',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tagicu',
 				'tgx' => 'tagish',
 				'th' => 'tailandesu',
 				'tht' => 'tahltan',
 				'ti' => 'tigrignu',
 				'tig' => 'tigrè',
 				'tk' => 'turcmenu',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tn' => 'tswana',
 				'to' => 'tonganu',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turcu',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tàtaru',
 				'ttm' => 'tutchone setentrionale',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'twq' => 'tasawaq',
 				'ty' => 'taitianu',
 				'tyv' => 'tuvanu',
 				'tzm' => 'tamazight de s’Atlànte tzentrale',
 				'udm' => 'udmurtu',
 				'ug' => 'uiguru',
 				'uk' => 'ucrainu',
 				'umb' => 'umbundu',
 				'und' => 'limba disconnota',
 				'ur' => 'urdu',
 				'uz' => 'uzbecu',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'vènetu',
 				'vi' => 'vietnamita',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'vallonu',
 				'wae' => 'walser',
 				'wal' => 'wolaita',
 				'war' => 'waray',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'calmucu',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantonesu',
 				'yue@alt=menu' => 'tzinesu, cantonesu',
 				'zgh' => 'tamazight istandard marochinu',
 				'zh' => 'tzinesu',
 				'zh@alt=menu' => 'tzinesu, mandarinu',
 				'zh_Hans' => 'tzinesu semplificadu',
 				'zh_Hans@alt=long' => 'tzinesu mandarinu semplificadu',
 				'zh_Hant' => 'tzinesu traditzionale',
 				'zh_Hant@alt=long' => 'tzinesu mandarinu traditzionale',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'perunu cuntenutu linguìsticu',
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
			'Adlm' => 'adlam',
 			'Aghb' => 'albanesu caucàsicu',
 			'Ahom' => 'ahom',
 			'Arab' => 'àrabu',
 			'Aran' => 'nastaʿlīq',
 			'Armi' => 'aramàicu imperiale',
 			'Armn' => 'armenu',
 			'Avst' => 'avèsticu',
 			'Bali' => 'balinesu',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalesu',
 			'Bhks' => 'bhaiksuki',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'buginesu',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'sillabàriu aborìgenu canadesu unificadu',
 			'Cari' => 'carian',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Chrs' => 'coràsmiu',
 			'Copt' => 'coptu',
 			'Cpmn' => 'tzipro-minòicu',
 			'Cprt' => 'tzipriotu',
 			'Cyrl' => 'tzirìllicu',
 			'Deva' => 'devanagari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogra',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'istenografia duployan',
 			'Egyp' => 'geroglìficos egitzianos',
 			'Elba' => 'elbasan',
 			'Elym' => 'elimàicu',
 			'Ethi' => 'etìope',
 			'Geor' => 'georgianu',
 			'Glag' => 'glagolìticu',
 			'Gong' => 'gunjala gondi',
 			'Gonm' => 'gondi de Masaram',
 			'Goth' => 'gòticu',
 			'Gran' => 'grantha',
 			'Grek' => 'grecu',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han cun bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'semplificadu',
 			'Hans@alt=stand-alone' => 'han semplificadu',
 			'Hant' => 'traditzionale',
 			'Hant@alt=stand-alone' => 'han traditzionale',
 			'Hatr' => 'hatran',
 			'Hebr' => 'ebràicu',
 			'Hira' => 'hiragana',
 			'Hluw' => 'geroglìficos anatòlicos',
 			'Hmng' => 'pahawn hmong',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'sillabàrios giaponesos',
 			'Hung' => 'ungheresu antigu',
 			'Ital' => 'itàlicu antigu',
 			'Jamo' => 'jamo',
 			'Java' => 'giavanesu',
 			'Jpan' => 'giaponesu',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Kawi' => 'kawi',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khojki',
 			'Kits' => 'iscritura khitan minore',
 			'Knda' => 'kannada',
 			'Kore' => 'coreanu',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laotianu',
 			'Latn' => 'latinu',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineare A',
 			'Linb' => 'lineare B',
 			'Lisu' => 'lisu',
 			'Lyci' => 'lìtziu',
 			'Lydi' => 'lìdiu',
 			'Mahj' => 'mahajani',
 			'Maka' => 'makasar',
 			'Mand' => 'mandàicu',
 			'Mani' => 'manicheu',
 			'Marc' => 'marchen',
 			'Medf' => 'medefaidrin',
 			'Mend' => 'mende',
 			'Merc' => 'corsivu meroìticu',
 			'Mero' => 'meroìticu',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modi',
 			'Mong' => 'mòngolu',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei mayek',
 			'Mult' => 'multani',
 			'Mymr' => 'birmanu',
 			'Nagm' => 'nag mundari',
 			'Nand' => 'nandinagari',
 			'Narb' => 'àrabu setentrionale antigu',
 			'Nbat' => 'nabateu',
 			'Newa' => 'newa',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'odia',
 			'Osge' => 'osage',
 			'Osma' => 'osmanya',
 			'Ougr' => 'uiguru antigu',
 			'Palm' => 'palmirenu',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'pèrmicu antigu',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi de sas iscritziones',
 			'Phlp' => 'psalter pahlavi',
 			'Phnx' => 'fenìtziu',
 			'Plrd' => 'pollard miao',
 			'Prti' => 'pàrticu de sas iscritziones',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi rohingya',
 			'Runr' => 'rùnicu',
 			'Samr' => 'samaritanu',
 			'Sarb' => 'àrabu meridionale antigu',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'limba de sos sinnos',
 			'Shaw' => 'shavianu',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'singalesu',
 			'Sogd' => 'sogdianu',
 			'Sogo' => 'sogdianu antigu',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyombo',
 			'Sund' => 'sundanesu',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'sirìacu',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue nou',
 			'Taml' => 'tamil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandesu',
 			'Tibt' => 'tibetanu',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'toto',
 			'Ugar' => 'ugarìticu',
 			'Vaii' => 'vai',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wancho',
 			'Xpeo' => 'persianu antigu',
 			'Xsux' => 'cuneiforme sumero-acàdicu',
 			'Yezi' => 'yezidi',
 			'Yiii' => 'yi',
 			'Zanb' => 'zanabar cuadradu',
 			'Zinh' => 'eredadu',
 			'Zmth' => 'notatzione matemàtica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'sìmbulos',
 			'Zxxx' => 'no iscritu',
 			'Zyyy' => 'comune',
 			'Zzzz' => 'iscritura disconnota',

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
			'001' => 'Mundu',
 			'002' => 'Àfrica',
 			'003' => 'Amèrica de su Nord',
 			'005' => 'Amèrica de su Sud',
 			'009' => 'Otzeània',
 			'011' => 'Àfrica otzidentale',
 			'013' => 'Amèrica tzentrale',
 			'014' => 'Àfrica orientale',
 			'015' => 'Àfrica setentrionale',
 			'017' => 'Àfrica tzentrale',
 			'018' => 'Àfrica meridionale',
 			'019' => 'Amèricas',
 			'021' => 'Amèrica setentrionale',
 			'029' => 'Caràibes',
 			'030' => 'Àsia orientale',
 			'034' => 'Àsia meridionale',
 			'035' => 'Sud-est asiàticu',
 			'039' => 'Europa meridionale',
 			'053' => 'Australàsia',
 			'054' => 'Melanèsia',
 			'057' => 'Regione micronesiana',
 			'061' => 'Polinèsia',
 			'142' => 'Àsia',
 			'143' => 'Àsia tzentrale',
 			'145' => 'Àsia otzidentale',
 			'150' => 'Europa',
 			'151' => 'Europa orientale',
 			'154' => 'Europa setentrionale',
 			'155' => 'Europa otzidentale',
 			'202' => 'Àfrica sub-sahariana',
 			'419' => 'Amèrica latina',
 			'AC' => 'Ìsula de s’Ascensione',
 			'AD' => 'Andorra',
 			'AE' => 'Emirados Àrabos Unidos',
 			'AF' => 'Afghànistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armènia',
 			'AO' => 'Angola',
 			'AQ' => 'Antàrticu',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa americanas',
 			'AT' => 'Àustria',
 			'AU' => 'Austràlia',
 			'AW' => 'Aruba',
 			'AX' => 'Ìsulas Åland',
 			'AZ' => 'Azerbaigiàn',
 			'BA' => 'Bòsnia e Erzegòvina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladèsh',
 			'BE' => 'Bèlgiu',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Santu Bartolomeu',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolìvia',
 			'BQ' => 'Caràibes olandesas',
 			'BR' => 'Brasile',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutàn',
 			'BV' => 'Ìsula Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorùssia',
 			'BZ' => 'Belize',
 			'CA' => 'Cànada',
 			'CC' => 'Ìsulas Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'Repùblica Tzentrafricana',
 			'CG' => 'Congo - Bratzaville',
 			'CG@alt=variant' => 'Congo (Repùblica)',
 			'CH' => 'Isvìtzera',
 			'CI' => 'Costa de Avòriu',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Ìsulas Cook',
 			'CL' => 'Tzile',
 			'CM' => 'Camerùn',
 			'CN' => 'Tzina',
 			'CO' => 'Colòmbia',
 			'CP' => 'Ìsula de Clipperton',
 			'CQ' => 'Sark',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabu birde',
 			'CW' => 'Curaçao',
 			'CX' => 'Ìsula de sa Natividade',
 			'CY' => 'Tzipru',
 			'CZ' => 'Tzèchia',
 			'CZ@alt=variant' => 'Repùblica Tzeca',
 			'DE' => 'Germània',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Gibuti',
 			'DK' => 'Danimarca',
 			'DM' => 'Dominica',
 			'DO' => 'Repùblica Dominicana',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ècuador',
 			'EE' => 'Estònia',
 			'EG' => 'Egitu',
 			'EH' => 'Sahara otzidentale',
 			'ER' => 'Eritrea',
 			'ES' => 'Ispagna',
 			'ET' => 'Etiòpia',
 			'EU' => 'Unione Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlàndia',
 			'FJ' => 'Fiji',
 			'FK' => 'Ìsulas Falkland',
 			'FK@alt=variant' => 'Ìsulas Falkland (Ìsulas Malvinas)',
 			'FM' => 'Micronèsia',
 			'FO' => 'Ìsulas Føroyar',
 			'FR' => 'Frantza',
 			'GA' => 'Gabòn',
 			'GB' => 'Regnu Unidu',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Grenada',
 			'GE' => 'Geòrgia',
 			'GF' => 'Guiana frantzesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibilterra',
 			'GL' => 'Groenlàndia',
 			'GM' => 'Gàmbia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinea Ecuadoriale',
 			'GR' => 'Grètzia',
 			'GS' => 'Geòrgia de su Sud e Ìsulas Sandwich Australes',
 			'GT' => 'Guatemala',
 			'GU' => 'Guàm',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'RAS tzinesa de Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ìsulas Heard e McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croàtzia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungheria',
 			'IC' => 'Ìsulas Canàrias',
 			'ID' => 'Indonèsia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israele',
 			'IM' => 'Ìsula de Man',
 			'IN' => 'Ìndia',
 			'IO' => 'Territòriu Britànnicu de s’Otzèanu Indianu',
 			'IO@alt=chagos' => 'Artzipèlagu Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iràn',
 			'IS' => 'Islanda',
 			'IT' => 'Itàlia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamàica',
 			'JO' => 'Giordània',
 			'JP' => 'Giapone',
 			'KE' => 'Kènya',
 			'KG' => 'Kirghìzistan',
 			'KH' => 'Cambòdia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoras',
 			'KN' => 'Santu Cristolu e Nevis',
 			'KP' => 'Corea de su Nord',
 			'KR' => 'Corea de su Sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Ìsulas Cayman',
 			'KZ' => 'Kazàkistan',
 			'LA' => 'Laos',
 			'LB' => 'Lèbanu',
 			'LC' => 'Santa Lughia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libèria',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituània',
 			'LU' => 'Lussemburgu',
 			'LV' => 'Letònia',
 			'LY' => 'Lìbia',
 			'MA' => 'Marocu',
 			'MC' => 'Mònacu',
 			'MD' => 'Moldàvia',
 			'ME' => 'Montenegro',
 			'MF' => 'Santu Martine',
 			'MG' => 'Madagascàr',
 			'MH' => 'Ìsulas Marshall',
 			'MK' => 'Matzedònia de su Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmàr (Birmània)',
 			'MN' => 'Mongòlia',
 			'MO' => 'RAS tzinesa de Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Ìsulas Mariannas setentrionales',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritània',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurìtzius',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'Mèssicu',
 			'MY' => 'Malèsia',
 			'MZ' => 'Mozambicu',
 			'NA' => 'Namìbia',
 			'NC' => 'Caledònia Noa',
 			'NE' => 'Niger',
 			'NF' => 'Ìsula Norfolk',
 			'NG' => 'Nigèria',
 			'NI' => 'Nicaràgua',
 			'NL' => 'Paisos Bassos',
 			'NO' => 'Norvègia',
 			'NP' => 'Nèpal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Zelanda Noa',
 			'NZ@alt=variant' => 'Aotearoa Zelanda Noa',
 			'OM' => 'Omàn',
 			'PA' => 'Pànama',
 			'PE' => 'Perù',
 			'PF' => 'Polinèsia frantzesa',
 			'PG' => 'Pàpua Guinea Noa',
 			'PH' => 'Filipinas',
 			'PK' => 'Pàkistan',
 			'PL' => 'Polònia',
 			'PM' => 'Santu Predu e Miquelon',
 			'PN' => 'Ìsulas Pìtcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territòrios palestinesos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portogallu',
 			'PW' => 'Palau',
 			'PY' => 'Paraguày',
 			'QA' => 'Catar',
 			'QO' => 'Otzeània perifèrica',
 			'RE' => 'Riunione',
 			'RO' => 'Romania',
 			'RS' => 'Sèrbia',
 			'RU' => 'Rùssia',
 			'RW' => 'Ruanda',
 			'SA' => 'Aràbia Saudita',
 			'SB' => 'Ìsulas Salomone',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudàn',
 			'SE' => 'Isvètzia',
 			'SG' => 'Singapore',
 			'SH' => 'Santa Elene',
 			'SI' => 'Islovènia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Islovàchia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'Santu Marinu',
 			'SN' => 'Senegal',
 			'SO' => 'Somàlia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan de su Sud',
 			'ST' => 'São Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sìria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swàziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Ìsulas Turks e Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Terras australes frantzesas',
 			'TG' => 'Togo',
 			'TH' => 'Tailàndia',
 			'TJ' => 'Tagìkistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Est',
 			'TL@alt=variant' => 'Timor Orientale',
 			'TM' => 'Turkmènistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwàn',
 			'TZ' => 'Tanzània',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ìsulas perifèricas de sos Istados Unidos',
 			'UN' => 'Natziones Unidas',
 			'US' => 'Istados Unidos',
 			'US@alt=short' => 'IUA',
 			'UY' => 'Uruguày',
 			'UZ' => 'Uzbèkistan',
 			'VA' => 'Tzitade de su Vaticanu',
 			'VC' => 'Santu Vissente e sas Grenadinas',
 			'VE' => 'Venetzuela',
 			'VG' => 'Ìsulas Vèrgines Britànnicas',
 			'VI' => 'Ìsulas Vèrgines de sos Istados Unidos',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'psèudo-atzentos',
 			'XB' => 'psèudo-bidi',
 			'XK' => 'Kòssovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudàfrica',
 			'ZM' => 'Zàmbia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'regione disconnota',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia traditzionale tedesca',
 			'1994' => 'ortografia resiana istandardizada',
 			'1996' => 'ortografia tedesca de su 1996',
 			'1606NICT' => 'frantzesu mèdiu-tardu finas a su 1606',
 			'1694ACAD' => 'primu frantzesu modernu',
 			'1959ACAD' => 'acadèmicu',
 			'ABL1943' => 'formulatzione ortogràfica de su 1943',
 			'AKUAPEM' => 'akuapem',
 			'ALALC97' => 'romanizatzione de ALA-LC, versione de su 1997',
 			'ALUKU' => 'dialetu aluku',
 			'AO1990' => 'acordu ortogràficu de sa limba portoghesa de su 1990',
 			'ARANES' => 'aranesu',
 			'ARKAIKA' => 'esperanto arcàicu',
 			'ASANTE' => 'asante',
 			'AUVERN' => 'auvernesu',
 			'BAKU1926' => 'alfabetu latinu turcu unificadu',
 			'BALANKA' => 'dialetu balanka de s’anii',
 			'BARLA' => 'grupu dialetale barlavento de su cabubirdianu',
 			'BASICENG' => 'inglesu bàsicu',
 			'BAUDDHA' => 'variante ìbrida buddhista',
 			'BISCAYAN' => 'bizcaianu',
 			'BISKE' => 'dialetu de Santu Giorghi/Bila',
 			'BOHORIC' => 'alfabetu Bohorič',
 			'BOONT' => 'boontling',
 			'BORNHOLM' => 'bornholmesu',
 			'CISAUP' => 'cisalpinu',
 			'COLB1945' => 'cunventzione ortogràfica portoghesa-brasiliana de su 1945',
 			'CORNU' => 'còrnicu',
 			'CREISS' => 'creschente',
 			'DAJNKO' => 'alfabetu Dajnko',
 			'EKAVSK' => 'serbu cun pronùntzia ekaviana',
 			'EMODENG' => 'primu inglesu modernu',
 			'FONIPA' => 'alfabetu fonèticu internatzionale IPA',
 			'FONKIRSH' => 'alfabetu fonèticu de Kirshenbaum',
 			'FONNAPA' => 'alfabetu fonèticu de s’Amèrica setentrionale',
 			'FONUPA' => 'alfabetu fonèticu uràlicu UPA',
 			'FONXSAMP' => 'alfabetu fonèticu X-SAMPA',
 			'GALLO' => 'gallu',
 			'GASCON' => 'gasconu',
 			'GRCLASS' => 'ortografia otzitana clàssica',
 			'GRITAL' => 'ortografia otzitana italianizada',
 			'GRMISTR' => 'ortografia otzitana mistraliana',
 			'HEPBURN' => 'romanizatzione Hepburn',
 			'HOGNORSK' => 'variante de norvegesu artu (høgnorsk)',
 			'HSISTEMO' => 'sistema ortogràficu H de s’esperanto',
 			'IJEKAVSK' => 'serbu cun pronùntzia ijekaviana',
 			'ITIHASA' => 'variante èpica induista',
 			'IVANCHOV' => 'ortografia bùlgara de Ivanchov de su 1899',
 			'JAUER' => 'dialetu jauer',
 			'JYUTPING' => 'romanizatzione jyutping',
 			'KKCOR' => 'ortografia comuna',
 			'KOCIEWIE' => 'variante kochieviana',
 			'KSCOR' => 'ortografia istandard',
 			'LAUKIKA' => 'variante clàssica',
 			'LEMOSIN' => 'limosinu',
 			'LENGADOC' => 'languedocianu',
 			'LIPAW' => 'su dialetu lipovaz de su resianu',
 			'LTG1929' => 'ortografia de sa limba latgaliana de su 1929',
 			'LTG2007' => 'ortografia de sa limba latgaliana de su 2007',
 			'LUNA1918' => 'ortografia russa riformada de su 1918',
 			'METELKO' => 'alfabetu Metelko',
 			'MONOTON' => 'monotònicu',
 			'NDYUKA' => 'dialetu ndyuka',
 			'NEDIS' => 'dialetu de Natisone',
 			'NEWFOUND' => 'inglesu de Terranova',
 			'NICARD' => 'nitzardu',
 			'NJIVA' => 'dialetu de Gniva/Njiva',
 			'NULIK' => 'volapük modernu',
 			'OSOJS' => 'dialetu de Oseacco/Osojane',
 			'OXENDICT' => 'ortografia inglesa de su ditzionàriu de Oxford',
 			'PAHAWH2' => 'ortografia reduida pahawh hmong fase 2',
 			'PAHAWH3' => 'ortografia reduida pahawh hmong fase 3',
 			'PAHAWH4' => 'ortografia reduida pahawh hmong fase 4',
 			'PAMAKA' => 'dialetu pamaka',
 			'PEANO' => 'interlingua de peano',
 			'PETR1708' => 'ortografia de Perdu I de su 1708',
 			'PINYIN' => 'romanizatzione pinyin',
 			'POLYTON' => 'politònicu',
 			'POSIX' => 'informàticu',
 			'PROVENC' => 'proventzale',
 			'PUTER' => 'puter',
 			'REVISED' => 'ortografia revisionada',
 			'RIGIK' => 'volapük clàssicu',
 			'ROZAJ' => 'resianu',
 			'RUMGR' => 'istandard de sos Grisones',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'inglesu istandard iscotzesu',
 			'SCOUSE' => 'scouse',
 			'SIMPLE' => 'semplificadu',
 			'SOLBA' => 'dialetu de Stolvizza/Solbica',
 			'SOTAV' => 'grupu dialetale sotavento de su cabubirdianu',
 			'SPANGLIS' => 'spanglish',
 			'SURMIRAN' => 'surmiranu',
 			'SURSILV' => 'sursilvanu',
 			'SUTSILV' => 'sutsilvanu',
 			'SYNNEJYL' => 'jutlandesu meridionale',
 			'TARASK' => 'ortografia taraškievica',
 			'TONGYONG' => 'romanizatzione pinyin tongyong',
 			'TUNUMIIT' => 'groenlandesu orientale',
 			'UCCOR' => 'ortografia unificada',
 			'UCRCOR' => 'ortografia revisionada unificada',
 			'ULSTER' => 'ortografia de s’Ulster',
 			'UNIFON' => 'alfabetu fonèticu Unifon',
 			'VAIDIKA' => 'variante vèdica',
 			'VALENCIA' => 'valentzianu',
 			'VALLADER' => 'vallader',
 			'VECDRUKA' => 'ortografia lètone vecā druka',
 			'VIVARAUP' => 'vivaro-alpinu',
 			'WADEGILE' => 'romanizatzione Wale-Giles',
 			'XSISTEMO' => 'sistema ortogràficu X de s’esperanto',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendàriu',
 			'cf' => 'formadu de valuta',
 			'collation' => 'ordinamentu',
 			'currency' => 'valuta',
 			'hc' => 'sistema oràriu (12 o 24 oras)',
 			'lb' => 'casta de truncadura de lìnia',
 			'ms' => 'sistema de medida',
 			'numbers' => 'nùmeros',

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
 				'buddhist' => q{calendàriu buddhista},
 				'chinese' => q{calendàriu tzinesu},
 				'coptic' => q{calendàriu coptu},
 				'dangi' => q{calendàriu dangi},
 				'ethiopic' => q{calendàriu etìope},
 				'ethiopic-amete-alem' => q{calendàriu etìope Amete Alem},
 				'gregorian' => q{calendàriu gregorianu},
 				'hebrew' => q{calendàriu ebràicu},
 				'indian' => q{calendàriu natzionale indianu},
 				'islamic' => q{calendàriu egirianu},
 				'islamic-civil' => q{calendàriu egirianu (tabulare, època tzivile)},
 				'islamic-rgsa' => q{calendàriu islàmicu (Aràbia Saudita, osservatzione)},
 				'islamic-tbla' => q{calendàriu islàmicu (tabulare, època astronòmica)},
 				'islamic-umalqura' => q{calendàriu egirianu (Umm al-Qura)},
 				'iso8601' => q{calendàriu ISO-8601},
 				'japanese' => q{calendàriu giaponesu},
 				'persian' => q{calendàriu persianu},
 				'roc' => q{calendàriu minguo},
 			},
 			'cf' => {
 				'account' => q{formadu de valuta contàbile},
 				'standard' => q{formadu de valuta istandard},
 			},
 			'collation' => {
 				'big5han' => q{ordinamentu de su tzinesu traditzionale - Big5},
 				'compat' => q{ordinamentu antepostu, pro cumpatibilitade},
 				'dictionary' => q{ordinamentu de su ditzionàriu},
 				'ducet' => q{ordinamentu Unicode predefinidu},
 				'emoji' => q{ordinamentu de sas emoji},
 				'eor' => q{règulas de ordinamentu europeas},
 				'gb2312han' => q{ordinamentu de su tzinesu semplificadu - GB2312},
 				'phonebook' => q{ordinamentu de s’elencu telefònicu},
 				'pinyin' => q{ordinamentu pinyin},
 				'reformed' => q{ordinamentu riformadu},
 				'search' => q{chirca genèrica},
 				'searchjl' => q{chirca pro consonante hangul initziale},
 				'standard' => q{ordinamentu istandard},
 				'stroke' => q{òrdine de sos tratos},
 				'traditional' => q{ordinamentu traditzionale},
 				'unihan' => q{ordinamentu in base a sos radicales},
 				'zhuyin' => q{ordinamentu zhuyin},
 			},
 			'hc' => {
 				'h11' => q{sistema oràriu a 12 oras (0–11)},
 				'h12' => q{sistema oràriu a 12 oras (1–12)},
 				'h23' => q{sistema oràriu a 24 oras (0–23)},
 				'h24' => q{sistema oràriu a 24 oras (1–24)},
 			},
 			'lb' => {
 				'loose' => q{truncadura de lìnia facoltativa},
 				'normal' => q{truncadura de lìnia normale},
 				'strict' => q{truncadura de lìnia fortzada},
 			},
 			'ms' => {
 				'metric' => q{sistema mètricu},
 				'uksystem' => q{sistema imperiale britànnicu},
 				'ussystem' => q{sistema consuetudinàriu americanu},
 			},
 			'numbers' => {
 				'ahom' => q{tzifras ahom},
 				'arab' => q{tzifras indo-àrabas},
 				'arabext' => q{tzifras indo-àrabas estèndidas},
 				'armn' => q{nùmeros armenos},
 				'armnlow' => q{nùmeros armenos minùscolos},
 				'bali' => q{tzifras balinesas},
 				'beng' => q{tzifras bengalesas},
 				'brah' => q{tzifras brahmi},
 				'cakm' => q{tzifras chakma},
 				'cham' => q{tzifras cham},
 				'cyrl' => q{tzifras tzirìllicas},
 				'deva' => q{tzifras devanagari},
 				'diak' => q{tzifras dhives akuru},
 				'ethi' => q{nùmeros etìopes},
 				'fullwide' => q{tzifras a largària intrea},
 				'geor' => q{nùmeros georgianos},
 				'gong' => q{tzifras gondi gunjala},
 				'gonm' => q{tzifras gondi masaram},
 				'grek' => q{nùmeros grecos},
 				'greklow' => q{nùmeros grecos minùscolos},
 				'gujr' => q{tzifras gujarati},
 				'guru' => q{tzifras gurmukhi},
 				'hanidec' => q{nùmeros detzimales tzinesos},
 				'hans' => q{nùmeros in tzinesu semplificadu},
 				'hansfin' => q{nùmeros finantziàrios in tzinesu semplificadu},
 				'hant' => q{nùmeros in tzinesu traditzionale},
 				'hantfin' => q{nùmeros finantziàrios in tzinesu traditzionale},
 				'hebr' => q{nùmeros ebràicos},
 				'hmng' => q{tzifras pahawh hmong},
 				'hmnp' => q{tzifras nyiakeng puachue hmong},
 				'java' => q{tzifras giavanesas},
 				'jpan' => q{nùmeros giaponesos},
 				'jpanfin' => q{nùmeros finantziàrios giaponesos},
 				'kali' => q{tzifras kayah li},
 				'kawi' => q{tzifras kawi},
 				'khmr' => q{tzifras khmer},
 				'knda' => q{tzifras kannada},
 				'lana' => q{tzifras tai tham hora},
 				'lanatham' => q{tzifras tai tham tham},
 				'laoo' => q{tzifras laotianas},
 				'latn' => q{tzifras otzidentales},
 				'lepc' => q{tzifras lepcha},
 				'limb' => q{tzifras limbu},
 				'mathbold' => q{tzifras matemàticas in grussitu},
 				'mathdbl' => q{tzifras matemàticas a tràtu dòpiu},
 				'mathmono' => q{tzifras matemàticas a ispàtziu sìngulu},
 				'mathsanb' => q{tzifras matemàticas in grussitu chene gràtzias},
 				'mathsans' => q{tzifras matemàticas chene gràtzias},
 				'mlym' => q{tzifras malayam},
 				'modi' => q{tzifras modi},
 				'mong' => q{tzifras mòngolas},
 				'mroo' => q{tzifras mro},
 				'mtei' => q{tzifras meitei mayek},
 				'mymr' => q{tzifras birmanas},
 				'mymrshan' => q{tzifras shan birmanas},
 				'mymrtlng' => q{tzifras tai lang birmanas},
 				'nagm' => q{tzifras nag mundari},
 				'nkoo' => q{tzifras n’ko},
 				'olck' => q{tzifras ol chiki},
 				'orya' => q{tzifras odia},
 				'osma' => q{tzifras osmanya},
 				'rohg' => q{tzifras rohingya hanifi},
 				'roman' => q{nùmeros romanos},
 				'romanlow' => q{nùmeros romanos minùscolos},
 				'saur' => q{tzifras saurashtra},
 				'shrd' => q{tzifras sharada},
 				'sind' => q{tzifras khudawadi},
 				'sinh' => q{tzifras lith singalesas},
 				'sora' => q{tzifras sora sompeng},
 				'sund' => q{tzifras sundanesas},
 				'takr' => q{tzifras takri},
 				'talu' => q{tzifras tai lue noas},
 				'taml' => q{nùmeros tamil traditzionales},
 				'tamldec' => q{tzifras tamil},
 				'telu' => q{tzifras telugu},
 				'thai' => q{tzifras tailandesas},
 				'tibt' => q{tzifras tibetanas},
 				'tirh' => q{tzifras tirhuta},
 				'tnsa' => q{tzifras tangsa},
 				'vaii' => q{tzifras vai},
 				'wara' => q{tzifras warang citi},
 				'wcho' => q{tzifras wancho},
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
 			'UK' => q{britànnicu},
 			'US' => q{americanu},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Limba: {0}',
 			'script' => 'Iscritura: {0}',
 			'region' => 'Regione: {0}',

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
			auxiliary => qr{[ªáâåäã æ ç éêë íîï k ñ ºóôöõø œ q ß úûü w x yÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', '{TZ}', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aà b c d eè f g h iì j l m n oò p r s t uù v z]},
			punctuation => qr{[‐ – — , ; \: ! ? . … · '‘’ "“” « » ( ) \[ \] @ * / \& # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', '{TZ}', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(puntu cardinale),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(puntu cardinale),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibì{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibì{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebì{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebì{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibì{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibì{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebì{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebì{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebì{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebì{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbì{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbì{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebì{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebì{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobì{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobì{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(detzì{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(detzì{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(picò{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(picò{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femtò{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femtò{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atò{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atò{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(tzentì{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(tzentì{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zeptò{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zeptò{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yoctò{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yoctò{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(rontò{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(rontò{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(millì{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(millì{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quectò{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quectò{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micrò{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micrò{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanò{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanò{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(decà{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(decà{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(terà{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(terà{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(petà{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(petà{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exà{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exà{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(etò{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(etò{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetà{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetà{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotà{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotà{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronnà{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronnà{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(chilò{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(chilò{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quettà{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quettà{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(megà{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(megà{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(gigà{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(gigà{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} fortza g),
						'other' => q({0} fortza g),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} fortza g),
						'other' => q({0} fortza g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros a su segundu cuadradu),
						'one' => q({0} metru a su segundu cuadradu),
						'other' => q({0} metros a su segundu cuadradu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros a su segundu cuadradu),
						'one' => q({0} metru a su segundu cuadradu),
						'other' => q({0} metros a su segundu cuadradu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(primos de arcu),
						'one' => q({0} primu de arcu),
						'other' => q({0} primos de arcu),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(primos de arcu),
						'one' => q({0} primu de arcu),
						'other' => q({0} primos de arcu),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segundos de arcu),
						'one' => q({0} segundu de arcu),
						'other' => q({0} segundos de arcu),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segundos de arcu),
						'one' => q({0} segundu de arcu),
						'other' => q({0} segundos de arcu),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grados),
						'one' => q({0} gradu),
						'other' => q({0} grados),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grados),
						'one' => q({0} gradu),
						'other' => q({0} grados),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiantes),
						'one' => q({0} radiante),
						'other' => q({0} radiantes),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiantes),
						'one' => q({0} radiante),
						'other' => q({0} radiantes),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rivolutzione),
						'one' => q({0} rivolutzione),
						'other' => q({0} rivolutziones),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rivolutzione),
						'one' => q({0} rivolutzione),
						'other' => q({0} rivolutziones),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acru),
						'other' => q({0} acros),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acru),
						'other' => q({0} acros),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ètaru),
						'other' => q({0} ètaros),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ètaru),
						'other' => q({0} ètaros),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(tzentìmetros cuadrados),
						'one' => q({0} tzentìmetru cuadradu),
						'other' => q({0} tzentìmetros cuadrados),
						'per' => q({0} pro tzentìmetru cuadradu),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(tzentìmetros cuadrados),
						'one' => q({0} tzentìmetru cuadradu),
						'other' => q({0} tzentìmetros cuadrados),
						'per' => q({0} pro tzentìmetru cuadradu),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pedes cuadrados),
						'one' => q({0} pede cuadradu),
						'other' => q({0} pedes cuadrados),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pedes cuadrados),
						'one' => q({0} pede cuadradu),
						'other' => q({0} pedes cuadrados),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pòddighes cuadrados),
						'one' => q({0} pòddighe cuadradu),
						'other' => q({0} pòddighes cuadrados),
						'per' => q({0} pro pòddighe cuadradu),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pòddighes cuadrados),
						'one' => q({0} pòddighe cuadradu),
						'other' => q({0} pòddighes cuadrados),
						'per' => q({0} pro pòddighe cuadradu),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(chilòmetros cuadrados),
						'one' => q({0} chilòmetru cuadradu),
						'other' => q({0} chilòmetros cuadrados),
						'per' => q({0} pro chilòmetru cuadradu),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(chilòmetros cuadrados),
						'one' => q({0} chilòmetru cuadradu),
						'other' => q({0} chilòmetros cuadrados),
						'per' => q({0} pro chilòmetru cuadradu),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metros cuadrados),
						'one' => q({0} metru cuadradu),
						'other' => q({0} metros cuadrados),
						'per' => q({0} pro metru cuadradu),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metros cuadrados),
						'one' => q({0} metru cuadradu),
						'other' => q({0} metros cuadrados),
						'per' => q({0} pro metru cuadradu),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mìllias cuadradas),
						'one' => q({0} mìlliu cuadradu),
						'other' => q({0} mìllias cuadradas),
						'per' => q({0} pro mìlliu cuadradu),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mìllias cuadradas),
						'one' => q({0} mìlliu cuadradu),
						'other' => q({0} mìllias cuadradas),
						'per' => q({0} pro mìlliu cuadradu),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iardas cuadradas),
						'one' => q({0} iarda cuadrada),
						'other' => q({0} iardas cuadradas),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iardas cuadradas),
						'one' => q({0} iarda cuadrada),
						'other' => q({0} iardas cuadradas),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elementos),
						'one' => q({0} elementu),
						'other' => q({0} elementos),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elementos),
						'one' => q({0} elementu),
						'other' => q({0} elementos),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(caratos),
						'one' => q({0} caratu),
						'other' => q({0} caratos),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(caratos),
						'one' => q({0} caratu),
						'other' => q({0} caratos),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammos pro detzìlitru),
						'one' => q({0} milligrammu pro detzìlitru),
						'other' => q({0} milligrammos pro detzìlitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammos pro detzìlitru),
						'one' => q({0} milligrammu pro detzìlitru),
						'other' => q({0} milligrammos pro detzìlitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoles pro litru),
						'one' => q({0} millimole pro litru),
						'other' => q({0} millimoles pro litru),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoles pro litru),
						'one' => q({0} millimole pro litru),
						'other' => q({0} millimoles pro litru),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moles),
						'one' => q({0} mole),
						'other' => q({0} moles),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moles),
						'one' => q({0} mole),
						'other' => q({0} moles),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(pro chentu),
						'one' => q({0} pro chentu),
						'other' => q({0} pro chentu),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(pro chentu),
						'one' => q({0} pro chentu),
						'other' => q({0} pro chentu),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pro milli),
						'one' => q({0} pro milli),
						'other' => q({0} pro milli),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pro milli),
						'one' => q({0} pro milli),
						'other' => q({0} pro milli),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes pro millione),
						'one' => q({0} parte pro millione),
						'other' => q({0} partes pro millione),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes pro millione),
						'one' => q({0} parte pro millione),
						'other' => q({0} partes pro millione),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pro deghemìgia),
						'one' => q({0} pro deghemìgia),
						'other' => q({0} pro deghemìgia),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pro deghemìgia),
						'one' => q({0} pro deghemìgia),
						'other' => q({0} pro deghemìgia),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros pro 100 chilòmetros),
						'one' => q({0} litru pro 100 chilòmetros),
						'other' => q({0} litros pro 100 chilòmetros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros pro 100 chilòmetros),
						'one' => q({0} litru pro 100 chilòmetros),
						'other' => q({0} litros pro 100 chilòmetros),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litros pro chilòmetru),
						'one' => q({0} litru pro chilòmetru),
						'other' => q({0} litros pro chilòmetru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros pro chilòmetru),
						'one' => q({0} litru pro chilòmetru),
						'other' => q({0} litros pro chilòmetru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mìllias pro gallone),
						'one' => q({0} mìlliu pro gallone),
						'other' => q({0} mìllias pro gallone),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mìllias pro gallone),
						'one' => q({0} mìlliu pro gallone),
						'other' => q({0} mìllias pro gallone),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mìllias pro gallone imperiale),
						'one' => q({0} mìlliu pro gallone imperiale),
						'other' => q({0} mìllias pro gallone imperiale),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mìllias pro gallone imperiale),
						'one' => q({0} mìlliu pro gallone imperiale),
						'other' => q({0} mìllias pro gallone imperiale),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ovest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ovest),
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
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(chilobits),
						'one' => q({0} chilobit),
						'other' => q({0} chilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(chilobits),
						'one' => q({0} chilobit),
						'other' => q({0} chilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(chilobytes),
						'one' => q({0} chilobyte),
						'other' => q({0} chilobytes),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(chilobytes),
						'one' => q({0} chilobyte),
						'other' => q({0} chilobytes),
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
						'name' => q(sèculos),
						'one' => q({0} sèculu),
						'other' => q({0} sèculos),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sèculos),
						'one' => q({0} sèculu),
						'other' => q({0} sèculos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} a sa die),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} a sa die),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dècadas),
						'one' => q({0} dècada),
						'other' => q({0} dècadas),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dècadas),
						'one' => q({0} dècada),
						'other' => q({0} dècadas),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} a s’ora),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} a s’ora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundu),
						'other' => q({0} microsegundos),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundu),
						'other' => q({0} microsegundos),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisegundos),
						'one' => q({0} millisegundu),
						'other' => q({0} millisegundos),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisegundos),
						'one' => q({0} millisegundu),
						'other' => q({0} millisegundos),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutos),
						'one' => q({0} minutu),
						'other' => q({0} minutos),
						'per' => q({0} a su minutu),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} minutu),
						'other' => q({0} minutos),
						'per' => q({0} a su minutu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} a su mese),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} a su mese),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundu),
						'other' => q({0} nanosegundos),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundu),
						'other' => q({0} nanosegundos),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} cuartu),
						'other' => q({0} cuartos),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} cuartu),
						'other' => q({0} cuartos),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundos),
						'one' => q({0} segundu),
						'other' => q({0} segundos),
						'per' => q({0} a su segundu),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundos),
						'one' => q({0} segundu),
						'other' => q({0} segundos),
						'per' => q({0} a su segundu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} chida),
						'other' => q({0} chidas),
						'per' => q({0} a sa chida),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} chida),
						'other' => q({0} chidas),
						'per' => q({0} a sa chida),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} a s’annu),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} a s’annu),
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
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperes),
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
						'name' => q(unidades tèrmicas britànnicas),
						'one' => q({0} unidade tèrmica britànnica),
						'other' => q({0} unidades tèrmicas britànnicas),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unidades tèrmicas britànnicas),
						'one' => q({0} unidade tèrmica britànnica),
						'other' => q({0} unidades tèrmicas britànnicas),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
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
						'name' => q(Calorias),
						'one' => q({0} Caloria),
						'other' => q({0} Calorias),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calorias),
						'one' => q({0} Caloria),
						'other' => q({0} Calorias),
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
						'name' => q(chilocalorias),
						'one' => q({0} chilocaloria),
						'other' => q({0} chilocalorias),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(chilocalorias),
						'one' => q({0} chilocaloria),
						'other' => q({0} chilocalorias),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(chilojoules),
						'one' => q({0} chilojoule),
						'other' => q({0} chilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(chilojoules),
						'one' => q({0} chilojoule),
						'other' => q({0} chilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(chilowatt-oras),
						'one' => q({0} chilowatt-ora),
						'other' => q({0} chilowatt-oras),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(chilowatt-oras),
						'one' => q({0} chilowatt-ora),
						'other' => q({0} chilowatt-oras),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therms americanos),
						'one' => q({0} therm americanu),
						'other' => q({0} therms americanos),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therms americanos),
						'one' => q({0} therm americanu),
						'other' => q({0} therms americanos),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(chilowatt-ora pro 100 chilòmetros),
						'one' => q({0} chilowatt-ora pro 100 chilòmetros),
						'other' => q({0} chilowatt-oras pro 100 chilòmetros),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(chilowatt-ora pro 100 chilòmetros),
						'one' => q({0} chilowatt-ora pro 100 chilòmetros),
						'other' => q({0} chilowatt-oras pro 100 chilòmetros),
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
						'name' => q(libbras de fortza),
						'one' => q({0} libbra de fortza),
						'other' => q({0} libbras de fortza),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libbras de fortza),
						'one' => q({0} libbra de fortza),
						'other' => q({0} libbras de fortza),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(chilohertz),
						'one' => q({0} chilohertz),
						'other' => q({0} chilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(chilohertz),
						'one' => q({0} chilohertz),
						'other' => q({0} chilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} puntu gràficu),
						'other' => q({0} puntos gràficos),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} puntu gràficu),
						'other' => q({0} puntos gràficos),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntos pro tzentìmetru),
						'one' => q({0} puntu pro tzentìmetru),
						'other' => q({0} puntos pro tzentìmetru),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntos pro tzentìmetru),
						'one' => q({0} puntu pro tzentìmetru),
						'other' => q({0} puntos pro tzentìmetru),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntos pro pòddighe),
						'one' => q({0} puntu pro pòddighe),
						'other' => q({0} puntos pro pòddighe),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntos pro pòddighe),
						'one' => q({0} puntu pro pòddighe),
						'other' => q({0} puntos pro pòddighe),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipogràficu),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipogràficu),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels pro tzentrìmetru),
						'one' => q({0} pixel pro tzentrìmetru),
						'other' => q({0} pixels pro tzentrìmetru),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels pro tzentrìmetru),
						'one' => q({0} pixel pro tzentrìmetru),
						'other' => q({0} pixels pro tzentrìmetru),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels pro pòddighe),
						'one' => q({0} pixel pro pòddighe),
						'other' => q({0} pixels pro pòddighe),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels pro pòddighe),
						'one' => q({0} pixel pro pòddighe),
						'other' => q({0} pixels pro pòddighe),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronòmicas),
						'one' => q({0} unidade astronòmica),
						'other' => q({0} unidades astronòmicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronòmicas),
						'one' => q({0} unidade astronòmica),
						'other' => q({0} unidades astronòmicas),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(tzentìmetros),
						'one' => q({0} tzentìmetru),
						'other' => q({0} tzentìmetros),
						'per' => q({0} pro tzentìmetru),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(tzentìmetros),
						'one' => q({0} tzentìmetru),
						'other' => q({0} tzentìmetros),
						'per' => q({0} pro tzentìmetru),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(detzìmetros),
						'one' => q({0} detzìmetru),
						'other' => q({0} detzìmetros),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(detzìmetros),
						'one' => q({0} detzìmetru),
						'other' => q({0} detzìmetros),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raju de sa terra),
						'one' => q({0} raju de sa terra),
						'other' => q({0} rajos de sa terra),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raju de sa terra),
						'one' => q({0} raju de sa terra),
						'other' => q({0} rajos de sa terra),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'one' => q({0} fathom),
						'other' => q({0} fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'one' => q({0} fathom),
						'other' => q({0} fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pedes),
						'one' => q({0} pede),
						'other' => q({0} pedes),
						'per' => q({0} pro pede),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pedes),
						'one' => q({0} pede),
						'other' => q({0} pedes),
						'per' => q({0} pro pede),
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
						'name' => q(pòddighes),
						'one' => q({0} pòddighe),
						'other' => q({0} pòddighes),
						'per' => q({0} pro pòddighe),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pòddighes),
						'one' => q({0} pòddighe),
						'other' => q({0} pòddighes),
						'per' => q({0} pro pòddighe),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(chilòmetros),
						'one' => q({0} chilòmetru),
						'other' => q({0} chilòmetros),
						'per' => q({0} pro chilòmetru),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(chilòmetros),
						'one' => q({0} chilòmetru),
						'other' => q({0} chilòmetros),
						'per' => q({0} pro chilòmetru),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(annos lughe),
						'one' => q({0} annu lughe),
						'other' => q({0} annos lughe),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(annos lughe),
						'one' => q({0} annu lughe),
						'other' => q({0} annos lughe),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metros),
						'one' => q({0} metru),
						'other' => q({0} metros),
						'per' => q({0} pro metru),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metru),
						'other' => q({0} metros),
						'per' => q({0} pro metru),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micròmetros),
						'one' => q({0} micròmetru),
						'other' => q({0} micròmetros),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micròmetros),
						'one' => q({0} micròmetru),
						'other' => q({0} micròmetros),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mìlliu),
						'other' => q({0} mìllias),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mìlliu),
						'other' => q({0} mìllias),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mìllias iscandìnavas),
						'one' => q({0} mìlliu iscandìnavu),
						'other' => q({0} mìllias iscandìnavas),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mìllias iscandìnavas),
						'one' => q({0} mìlliu iscandìnavu),
						'other' => q({0} mìllias iscandìnavas),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millìmetros),
						'one' => q({0} millìmetru),
						'other' => q({0} millìmetros),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millìmetros),
						'one' => q({0} millìmetru),
						'other' => q({0} millìmetros),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanòmetros),
						'one' => q({0} nanòmetru),
						'other' => q({0} nanòmetros),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanòmetros),
						'one' => q({0} nanòmetru),
						'other' => q({0} nanòmetros),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mìllias nàuticas),
						'one' => q({0} mìlliu nàuticu),
						'other' => q({0} mìllias nàuticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mìllias nàuticas),
						'one' => q({0} mìlliu nàuticu),
						'other' => q({0} mìllias nàuticas),
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
						'name' => q(picòmetros),
						'one' => q({0} picòmetru),
						'other' => q({0} picòmetros),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picòmetros),
						'one' => q({0} picòmetru),
						'other' => q({0} picòmetros),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos),
						'one' => q({0} puntu),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos),
						'one' => q({0} puntu),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(rajos solares),
						'one' => q({0} raju solare),
						'other' => q({0} rajos solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(rajos solares),
						'one' => q({0} raju solare),
						'other' => q({0} rajos solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} iarda),
						'other' => q({0} iardas),
					},
					# Core Unit Identifier
					'yard' => {
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
						'one' => q({0} luminosidade solare),
						'other' => q({0} luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminosidades solares),
						'one' => q({0} luminosidade solare),
						'other' => q({0} luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(caratos),
						'one' => q({0} caratu),
						'other' => q({0} caratos),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(caratos),
						'one' => q({0} caratu),
						'other' => q({0} caratos),
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
						'name' => q(massas terrestres),
						'one' => q({0} massa terrestre),
						'other' => q({0} massas terrestres),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massas terrestres),
						'one' => q({0} massa terrestre),
						'other' => q({0} massas terrestres),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammos),
						'one' => q({0} grammu),
						'other' => q({0} grammos),
						'per' => q({0} pro grammu),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammos),
						'one' => q({0} grammu),
						'other' => q({0} grammos),
						'per' => q({0} pro grammu),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(chilogrammos),
						'one' => q({0} chilogrammu),
						'other' => q({0} chilogrammos),
						'per' => q({0} pro chilogrammu),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(chilogrammos),
						'one' => q({0} chilogrammu),
						'other' => q({0} chilogrammos),
						'per' => q({0} pro chilogrammu),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgrammos),
						'one' => q({0} microgrammu),
						'other' => q({0} microgrammos),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgrammos),
						'one' => q({0} microgrammu),
						'other' => q({0} microgrammos),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrammos),
						'one' => q({0} milligrammu),
						'other' => q({0} milligrammos),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrammos),
						'one' => q({0} milligrammu),
						'other' => q({0} milligrammos),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(untzas),
						'one' => q({0} untza),
						'other' => q({0} untzas),
						'per' => q({0} pro untza),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(untzas),
						'one' => q({0} untza),
						'other' => q({0} untzas),
						'per' => q({0} pro untza),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(untzas troy),
						'one' => q({0} untza troy),
						'other' => q({0} untzas troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(untzas troy),
						'one' => q({0} untza troy),
						'other' => q({0} untzas troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libbras),
						'one' => q({0} libbra),
						'other' => q({0} libbras),
						'per' => q({0} pro libbra),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libbras),
						'one' => q({0} libbra),
						'other' => q({0} libbras),
						'per' => q({0} pro libbra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massas solares),
						'one' => q({0} massa solare),
						'other' => q({0} massas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massas solares),
						'one' => q({0} massa solare),
						'other' => q({0} massas solares),
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
						'name' => q(tonnelladas),
						'one' => q({0} tonnellada),
						'other' => q({0} tonnelladas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonnelladas),
						'one' => q({0} tonnellada),
						'other' => q({0} tonnelladas),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnelladas mètricas),
						'one' => q({0} tonnellada mètrica),
						'other' => q({0} tonnelladas mètricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnelladas mètricas),
						'one' => q({0} tonnellada mètrica),
						'other' => q({0} tonnelladas mètricas),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} a su {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} a su {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(caddos-papore),
						'one' => q({0} caddu-papore),
						'other' => q({0} caddos-papore),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(caddos-papore),
						'one' => q({0} caddu-papore),
						'other' => q({0} caddos-papore),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
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
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
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
						'one' => q({0} cuadradu),
						'other' => q({0} cuadrados),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} cuadradu),
						'other' => q({0} cuadrados),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} cùbicu),
						'other' => q({0} cùbicos),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} cùbicu),
						'other' => q({0} cùbicos),
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
						'name' => q(bars),
						'one' => q({0} bar),
						'other' => q({0} bars),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bars),
						'one' => q({0} bar),
						'other' => q({0} bars),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(etopascàls),
						'one' => q({0} etopascàl),
						'other' => q({0} etopascàls),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(etopascàls),
						'one' => q({0} etopascàl),
						'other' => q({0} etopascàls),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pòddighes de mercùriu),
						'one' => q({0} pòddighe de mercùriu),
						'other' => q({0} pòddighes de mercùriu),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pòddighes de mercùriu),
						'one' => q({0} pòddighe de mercùriu),
						'other' => q({0} pòddighes de mercùriu),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(chilopascàls),
						'one' => q({0} chilopascàl),
						'other' => q({0} chilopascàls),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(chilopascàls),
						'one' => q({0} chilopascàl),
						'other' => q({0} chilopascàls),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascàls),
						'one' => q({0} megapascàl),
						'other' => q({0} megapascàls),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascàls),
						'one' => q({0} megapascàl),
						'other' => q({0} megapascàls),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mìllibars),
						'one' => q({0} mìllibar),
						'other' => q({0} mìllibars),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mìllibars),
						'one' => q({0} mìllibar),
						'other' => q({0} mìllibars),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millìmetros de mercùriu),
						'one' => q({0} millìmetru de mercùriu),
						'other' => q({0} millìmetros de mercùriu),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millìmetros de mercùriu),
						'one' => q({0} millìmetru de mercùriu),
						'other' => q({0} millìmetros de mercùriu),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascàls),
						'one' => q({0} pascàl),
						'other' => q({0} pascàls),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascàls),
						'one' => q({0} pascàl),
						'other' => q({0} pascàls),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libbras pro pòddighe cuadradu),
						'one' => q({0} libbra pro pòddighe cuadradu),
						'other' => q({0} libbras pro pòddighe cuadradu),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libbras pro pòddighe cuadradu),
						'one' => q({0} libbra pro pòddighe cuadradu),
						'other' => q({0} libbras pro pòddighe cuadradu),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(chilòmetros a s’ora),
						'one' => q({0} chilòmetru a s’ora),
						'other' => q({0} chilòmetros a s’ora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(chilòmetros a s’ora),
						'one' => q({0} chilòmetru a s’ora),
						'other' => q({0} chilòmetros a s’ora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nodos),
						'one' => q({0} nodu),
						'other' => q({0} nodos),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nodos),
						'one' => q({0} nodu),
						'other' => q({0} nodos),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metros a su segundu),
						'one' => q({0} metru a su segundu),
						'other' => q({0} metros a su segundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metros a su segundu),
						'one' => q({0} metru a su segundu),
						'other' => q({0} metros a su segundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mìllias a s’ora),
						'one' => q({0} mìlliu a s'ora),
						'other' => q({0} mìllias a s'ora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mìllias a s’ora),
						'one' => q({0} mìlliu a s'ora),
						'other' => q({0} mìllias a s'ora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grados Cèlsius),
						'one' => q({0} gradu Cèlsius),
						'other' => q({0} grados Cèlsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grados Cèlsius),
						'one' => q({0} gradu Cèlsius),
						'other' => q({0} grados Cèlsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grados Fahrenheit),
						'one' => q({0} gradu Fahrenheit),
						'other' => q({0} grados Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grados Fahrenheit),
						'one' => q({0} gradu Fahrenheit),
						'other' => q({0} grados Fahrenheit),
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
						'name' => q(newtons-metros),
						'one' => q({0} newton-metru),
						'other' => q({0} newtons-metros),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtons-metros),
						'one' => q({0} newton-metru),
						'other' => q({0} newtons-metros),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libbras-pedes),
						'one' => q({0} libbra-pede),
						'other' => q({0} libbras-pedes),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libbras-pedes),
						'one' => q({0} libbra-pede),
						'other' => q({0} libbras-pedes),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acros-pedes),
						'one' => q({0} acru-pede),
						'other' => q({0} acros-pedes),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acros-pedes),
						'one' => q({0} acru-pede),
						'other' => q({0} acros-pedes),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bariles),
						'one' => q({0} barile),
						'other' => q({0} bariles),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bariles),
						'one' => q({0} barile),
						'other' => q({0} bariles),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} carra),
						'other' => q({0} carras),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} carra),
						'other' => q({0} carras),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(tzentìlitros),
						'one' => q({0} tzentìlitru),
						'other' => q({0} tzentìlitros),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(tzentìlitros),
						'one' => q({0} tzentìlitru),
						'other' => q({0} tzentìlitros),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(tzentìmetros cùbicos),
						'one' => q({0} tzentìmetru cùbicu),
						'other' => q({0} tzentìmetros cùbicos),
						'per' => q({0} pro tzentìmetru cùbicu),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(tzentìmetros cùbicos),
						'one' => q({0} tzentìmetru cùbicu),
						'other' => q({0} tzentìmetros cùbicos),
						'per' => q({0} pro tzentìmetru cùbicu),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pedes cùbicos),
						'one' => q({0} pede cùbicu),
						'other' => q({0} pedes cùbicos),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pedes cùbicos),
						'one' => q({0} pede cùbicu),
						'other' => q({0} pedes cùbicos),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pòddighes cùbicos),
						'one' => q({0} pòddighe cùbicu),
						'other' => q({0} pòddighes cùbicos),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pòddighes cùbicos),
						'one' => q({0} pòddighe cùbicu),
						'other' => q({0} pòddighes cùbicos),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(chilòmetros cùbicos),
						'one' => q({0} chilòmetru cùbicu),
						'other' => q({0} chilòmetros cùbicos),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(chilòmetros cùbicos),
						'one' => q({0} chilòmetru cùbicu),
						'other' => q({0} chilòmetros cùbicos),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metros cùbicos),
						'one' => q({0} metru cùbicu),
						'other' => q({0} metros cùbicos),
						'per' => q({0} pro metru cùbicu),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metros cùbicos),
						'one' => q({0} metru cùbicu),
						'other' => q({0} metros cùbicos),
						'per' => q({0} pro metru cùbicu),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mìllias cùbicas),
						'one' => q({0} mìlliu cùbicu),
						'other' => q({0} mìllias cùbicas),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mìllias cùbicas),
						'one' => q({0} mìlliu cùbicu),
						'other' => q({0} mìllias cùbicas),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iardas cùbicas),
						'one' => q({0} iarda cùbica),
						'other' => q({0} iardas cùbicas),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iardas cùbicas),
						'one' => q({0} iarda cùbica),
						'other' => q({0} iardas cùbicas),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tzìcheras),
						'one' => q({0} tzìchera),
						'other' => q({0} tzìcheras),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tzìcheras),
						'one' => q({0} tzìchera),
						'other' => q({0} tzìcheras),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tzìcheras mètricas),
						'one' => q({0} tzìchera mètrica),
						'other' => q({0} tzìcheras mètricas),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tzìcheras mètricas),
						'one' => q({0} tzìchera mètrica),
						'other' => q({0} tzìcheras mètricas),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(detzìlitros),
						'one' => q({0} detzìlitru),
						'other' => q({0} detzìlitros),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(detzìlitros),
						'one' => q({0} detzìlitru),
						'other' => q({0} detzìlitros),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(culleredda de postre),
						'one' => q({0} culleredda de postre),
						'other' => q({0} cullereddas de postre),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(culleredda de postre),
						'one' => q({0} culleredda de postre),
						'other' => q({0} cullereddas de postre),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(culleredda de postre imperiale),
						'one' => q({0} culleredda de postre imperiale),
						'other' => q({0} cullereddas de postre imperiales),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(culleredda de postre imperiale),
						'one' => q({0} culleredda de postre imperiale),
						'other' => q({0} cullereddas de postre imperiales),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0} dràcma flùida),
						'other' => q({0} dràcmas flùidas),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0} dràcma flùida),
						'other' => q({0} dràcmas flùidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(untzas flùidas),
						'one' => q({0} untza flùida),
						'other' => q({0} untzas flùidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(untzas flùidas),
						'one' => q({0} untza flùida),
						'other' => q({0} untzas flùidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(untzas flùidas imperiales),
						'one' => q({0} untza flùida imperiale),
						'other' => q({0} untzas flùidas imperiales),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(untzas flùidas imperiales),
						'one' => q({0} untza flùida imperiale),
						'other' => q({0} untzas flùidas imperiales),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallones),
						'one' => q({0} gallone),
						'other' => q({0} gallones),
						'per' => q({0} pro gallone),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallones),
						'one' => q({0} gallone),
						'other' => q({0} gallones),
						'per' => q({0} pro gallone),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gallones imperiales),
						'one' => q({0} gallone imperiale),
						'other' => q({0} gallones imperiales),
						'per' => q({0} pro gallone imperiale),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gallones imperiales),
						'one' => q({0} gallone imperiale),
						'other' => q({0} gallones imperiales),
						'per' => q({0} pro gallone imperiale),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(etòlitros),
						'one' => q({0} etòlitru),
						'other' => q({0} etòlitros),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(etòlitros),
						'one' => q({0} etòlitru),
						'other' => q({0} etòlitros),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litros),
						'one' => q({0} litru),
						'other' => q({0} litros),
						'per' => q({0} pro litru),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litros),
						'one' => q({0} litru),
						'other' => q({0} litros),
						'per' => q({0} pro litru),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megàlitros),
						'one' => q({0} megàlitru),
						'other' => q({0} megàlitros),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megàlitros),
						'one' => q({0} megàlitru),
						'other' => q({0} megàlitros),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millìlitros),
						'one' => q({0} millìlitru),
						'other' => q({0} millìlitros),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millìlitros),
						'one' => q({0} millìlitru),
						'other' => q({0} millìlitros),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0} ispitzuleddu),
						'other' => q({0} ispitzuleddos),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0} ispitzuleddu),
						'other' => q({0} ispitzuleddos),
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
						'name' => q(pintas mètricas),
						'one' => q({0} pinta mètrica),
						'other' => q({0} pintas mètricas),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pintas mètricas),
						'one' => q({0} pinta mètrica),
						'other' => q({0} pintas mètricas),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuartu),
						'other' => q({0} cuartos),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuartu),
						'other' => q({0} cuartos),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(cuartu imperiale),
						'one' => q({0} cuartu imperiale),
						'other' => q({0} cuartos imperiales),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(cuartu imperiale),
						'one' => q({0} cuartu imperiale),
						'other' => q({0} cuartos imperiales),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(culleras),
						'one' => q({0} cullera),
						'other' => q({0} culleras),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(culleras),
						'one' => q({0} cullera),
						'other' => q({0} culleras),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cullereddas),
						'one' => q({0} culleredda),
						'other' => q({0} cullereddas),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cullereddas),
						'one' => q({0} culleredda),
						'other' => q({0} cullereddas),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0}riv),
						'other' => q({0}riv),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}riv),
						'other' => q({0}riv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acru),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acru),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ètaru),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ètaru),
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
					'area-square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
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
					'area-square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0}elem.),
						'other' => q({0}elem.),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0}elem.),
						'other' => q({0}elem.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}mi/gUK),
						'other' => q({0}mi/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mi/gUK),
						'other' => q({0}mi/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}sèc.),
						'other' => q({0}sèc.),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}sèc.),
						'other' => q({0}sèc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(die),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(die),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}dèc.),
						'other' => q({0}dèc.),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}dèc.),
						'other' => q({0}dèc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ora),
						'one' => q({0}o),
						'other' => q({0}o),
						'per' => q({0}/o),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ora),
						'one' => q({0}o),
						'other' => q({0}o),
						'per' => q({0}/o),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mese),
						'one' => q({0}me.),
						'other' => q({0}me.),
						'per' => q({0}/me.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mese),
						'one' => q({0}me.),
						'other' => q({0}me.),
						'per' => q({0}/me.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(crt),
						'one' => q({0}crt),
						'other' => q({0}crt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(crt),
						'one' => q({0}crt),
						'other' => q({0}crt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ch.),
						'one' => q({0}ch.),
						'other' => q({0}ch.),
						'per' => q({0}/ch.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ch.),
						'one' => q({0}ch.),
						'other' => q({0}ch.),
						'per' => q({0}/ch.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(annu),
						'one' => q({0}an.),
						'other' => q({0}an.),
						'per' => q({0}/an.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(annu),
						'one' => q({0}an.),
						'other' => q({0}an.),
						'per' => q({0}/an.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}thm US),
						'other' => q({0}thm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}thm US),
						'other' => q({0}thm US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntu gràficu),
						'one' => q({0}pg),
						'other' => q({0}pg),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntu gràficu),
						'one' => q({0}pg),
						'other' => q({0}pg),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}pupcm),
						'other' => q({0}pupcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}pupcm),
						'other' => q({0}pupcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}ppp),
						'other' => q({0}ppp),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}ppp),
						'other' => q({0}ppp),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}ua),
						'other' => q({0}ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}ua),
						'other' => q({0}ua),
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
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}in),
						'other' => q({0}in),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}in),
						'other' => q({0}in),
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
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
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
					'length-mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
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
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
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
					'length-point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
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
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}cp),
						'other' => q({0}cp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}cp),
						'other' => q({0}cp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bars),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bars),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
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
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(carra),
						'one' => q({0}ca),
						'other' => q({0}ca),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(carra),
						'one' => q({0}ca),
						'other' => q({0}ca),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}tz),
						'other' => q({0}tz),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}tz),
						'other' => q({0}tz),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}tzm),
						'other' => q({0}tzm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}tzm),
						'other' => q({0}tzm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp imp.),
						'one' => q({0}dspI),
						'other' => q({0}dspI),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp imp.),
						'one' => q({0}dspI),
						'other' => q({0}dspI),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dr.fl.),
						'one' => q({0}dr.fl.),
						'other' => q({0}dr.fl.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dr.fl.),
						'one' => q({0}dr.fl.),
						'other' => q({0}dr.fl.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gù),
						'one' => q({0}gù),
						'other' => q({0}gù),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gù),
						'one' => q({0}gù),
						'other' => q({0}gù),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}flozI),
						'other' => q({0}flozI),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}flozI),
						'other' => q({0}flozI),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0}gal imp.),
						'other' => q({0}gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}gal imp.),
						'other' => q({0}gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0}tzichete),
						'other' => q({0}tzichetes),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}tzichete),
						'other' => q({0}tzichetes),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ispitz.),
						'one' => q({0}isptz.),
						'other' => q({0}isptz.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ispitz.),
						'one' => q({0}isptz.),
						'other' => q({0}isptz.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}qtI),
						'other' => q({0}qtI),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qtI),
						'other' => q({0}qtI),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}cull),
						'other' => q({0}cull),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}cull),
						'other' => q({0}cull),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}culld),
						'other' => q({0}culld),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}culld),
						'other' => q({0}culld),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(puntu),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(puntu),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(fortza g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(fortza g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(riv),
						'one' => q({0} riv),
						'other' => q({0} riv),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(riv),
						'one' => q({0} riv),
						'other' => q({0} riv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acros),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acros),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ètaros),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ètaros),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
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
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
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
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sèc.),
						'one' => q({0} sèc.),
						'other' => q({0} sèc.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sèc.),
						'one' => q({0} sèc.),
						'other' => q({0} sèc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dies),
						'one' => q({0} die),
						'other' => q({0} dies),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dies),
						'one' => q({0} die),
						'other' => q({0} dies),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dèc.),
						'one' => q({0} dèc.),
						'other' => q({0} dèc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dèc.),
						'one' => q({0} dèc.),
						'other' => q({0} dèc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oras),
						'one' => q({0} ora),
						'other' => q({0} oras),
						'per' => q({0}/ora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oras),
						'one' => q({0} ora),
						'other' => q({0} oras),
						'per' => q({0}/ora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'one' => q({0} mese),
						'other' => q({0} meses),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'one' => q({0} mese),
						'other' => q({0} meses),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(cuartos),
						'one' => q({0} crt),
						'other' => q({0} crt),
						'per' => q({0}/crt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(cuartos),
						'one' => q({0} crt),
						'other' => q({0} crt),
						'per' => q({0}/crt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seg),
						'one' => q({0} seg),
						'other' => q({0} seg),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seg),
						'one' => q({0} seg),
						'other' => q({0} seg),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(chidas),
						'one' => q({0} chida),
						'other' => q({0} chida),
						'per' => q({0}/chida),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(chidas),
						'one' => q({0} chida),
						'other' => q({0} chida),
						'per' => q({0}/chida),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(annos),
						'one' => q({0} annu),
						'other' => q({0} annos),
						'per' => q({0}/annu),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(annos),
						'one' => q({0} annu),
						'other' => q({0} annos),
						'per' => q({0}/annu),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
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
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
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
						'name' => q(thm US),
						'one' => q({0} thm US),
						'other' => q({0} thm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm US),
						'one' => q({0} thm US),
						'other' => q({0} thm US),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntos gràficos),
						'one' => q({0} pg),
						'other' => q({0} pg),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntos gràficos),
						'one' => q({0} pg),
						'other' => q({0} pg),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pupcm),
						'one' => q({0} pupcm),
						'other' => q({0} pupcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pupcm),
						'one' => q({0} pupcm),
						'other' => q({0} pupcm),
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
					'length-light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
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
						'name' => q(mìllias),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mìllias),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iardas),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iardas),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(granu),
						'one' => q({0} granu),
						'other' => q({0} granos),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(granu),
						'one' => q({0} granu),
						'other' => q({0} granos),
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
					'power-horsepower' => {
						'name' => q(cp),
						'one' => q({0} cp),
						'other' => q({0} cp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cp),
						'one' => q({0} cp),
						'other' => q({0} cp),
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
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(carras),
						'one' => q({0} ca),
						'other' => q({0} ca),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(carras),
						'one' => q({0} ca),
						'other' => q({0} ca),
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
					'volume-cup' => {
						'name' => q(tz),
						'one' => q({0} tz),
						'other' => q({0} tz),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tz),
						'one' => q({0} tz),
						'other' => q({0} tz),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tzm),
						'one' => q({0} tzm),
						'other' => q({0} tzm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tzm),
						'one' => q({0} tzm),
						'other' => q({0} tzm),
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
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dràcma flùida),
						'one' => q({0} dràcma fl),
						'other' => q({0} dràcma fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dràcma flùida),
						'one' => q({0} dràcma fl),
						'other' => q({0} dràcma fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gùtiu),
						'one' => q({0} gùtiu),
						'other' => q({0} gùtios),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gùtiu),
						'one' => q({0} gùtiu),
						'other' => q({0} gùtios),
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
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
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
						'name' => q(tzichete),
						'one' => q({0} tzichete),
						'other' => q({0} tzichetes),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(tzichete),
						'one' => q({0} tzichete),
						'other' => q({0} tzichetes),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
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
						'name' => q(ispitzuleddu),
						'one' => q({0} ispitzuleddu),
						'other' => q({0} ispitzuleddu),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ispitzuleddu),
						'one' => q({0} ispitzuleddu),
						'other' => q({0} ispitzuleddu),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cull),
						'one' => q({0} cull),
						'other' => q({0} cull),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cull),
						'one' => q({0} cull),
						'other' => q({0} cull),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(culld),
						'one' => q({0} culld),
						'other' => q({0} culld),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(culld),
						'one' => q({0} culld),
						'other' => q({0} culld),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:eja|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nono|n)$' }
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
					'one' => '0 mìgia',
					'other' => '0 mìgia',
				},
				'10000' => {
					'one' => '00 mìgia',
					'other' => '00 mìgia',
				},
				'100000' => {
					'one' => '000 mìgia',
					'other' => '000 mìgia',
				},
				'1000000' => {
					'one' => '0 millione',
					'other' => '0 milliones',
				},
				'10000000' => {
					'one' => '00 milliones',
					'other' => '00 milliones',
				},
				'100000000' => {
					'one' => '000 milliones',
					'other' => '000 milliones',
				},
				'1000000000' => {
					'one' => '0 milliardu',
					'other' => '0 milliardos',
				},
				'10000000000' => {
					'one' => '00 milliardos',
					'other' => '00 milliardos',
				},
				'100000000000' => {
					'one' => '000 milliardos',
					'other' => '000 milliardos',
				},
				'1000000000000' => {
					'one' => '0 mìgia milliardos',
					'other' => '0 mìgia milliardos',
				},
				'10000000000000' => {
					'one' => '00 mìgia milliardos',
					'other' => '00 mìgia milliardos',
				},
				'100000000000000' => {
					'one' => '000 mìgia milliardos',
					'other' => '000 mìgia milliardos',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 mìg',
					'other' => '0 mìg',
				},
				'10000' => {
					'one' => '00 mìg',
					'other' => '00 mìg',
				},
				'100000' => {
					'one' => '000 mìg',
					'other' => '000 mìg',
				},
				'1000000' => {
					'one' => '0 Mln',
					'other' => '0 Mln',
				},
				'10000000' => {
					'one' => '00 Mln',
					'other' => '00 Mln',
				},
				'100000000' => {
					'one' => '000 Mln',
					'other' => '000 Mln',
				},
				'1000000000' => {
					'one' => '0 Mrd',
					'other' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
				},
				'1000000000000' => {
					'one' => '0 Bln',
					'other' => '0 Bln',
				},
				'10000000000000' => {
					'one' => '00 Bln',
					'other' => '00 Bln',
				},
				'100000000000000' => {
					'one' => '000 Bln',
					'other' => '000 Bln',
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
			display_name => {
				'currency' => q(dirham de sos Emirados Àrabos Unidos),
				'one' => q(dirham de sos Emirados Àrabos Unidos),
				'other' => q(dirhams de sos Emirados Àrabos Unidos),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgani afganu \(1927–2002\)),
				'one' => q(afgani afganu \(1927–2002\)),
				'other' => q(afganis afganos \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani afganu),
				'one' => q(afgani afganu),
				'other' => q(afganis afganos),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanesu \(1946–1965\)),
				'one' => q(lek albanesu \(1946–1965\)),
				'other' => q(leks albanesos \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanesu),
				'one' => q(lek albanesu),
				'other' => q(leks albanesos),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armenu),
				'one' => q(dram armenu),
				'other' => q(drams armenos),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(fiorinu de sas Antillas Olandesas),
				'one' => q(fiorinu de sas Antillas Olandesas),
				'other' => q(fiorinos de sas Antillas Olandesas),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolanu),
				'one' => q(kwanza angolanu),
				'other' => q(kwanzas angolanos),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolanu \(1977–1991\)),
				'one' => q(kwanza angolanu \(1977–1991\)),
				'other' => q(kwanzas angolanos \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(kwanza nou angolanu \(1990–2000\)),
				'one' => q(kwanza nou angolanu \(1990–2000\)),
				'other' => q(kwanzas noos angolanos \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza ri-acontzadu angolanu \(1995–1999\)),
				'one' => q(kwanza ri-acontzadu angolanu \(1995–1999\)),
				'other' => q(kwanzas ri-acontzados angolanos \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentinu),
				'one' => q(austral argentinu),
				'other' => q(australs argentinos),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(peso ley argentinu \(1970–1983\)),
				'one' => q(peso ley argentinu \(1970–1983\)),
				'other' => q(pesos ley argentinos \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso argentinu \(1881–1970\)),
				'one' => q(peso argentinu \(1881–1970\)),
				'other' => q(pesos argentinos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentinu \(1983–1985\)),
				'one' => q(peso argentinu \(1983–1985\)),
				'other' => q(pesos argentinos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentinu),
				'one' => q(peso argentinu),
				'other' => q(pesos argentinos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(iscellinu austrìacu),
				'one' => q(iscellinu austrìacu),
				'other' => q(iscellinos austrìacos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dòllaru australianu),
				'one' => q(dòllaru australianu),
				'other' => q(dòllaros australianos),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(fiorinu arubanu),
				'one' => q(fiorinu arubanu),
				'other' => q(fiorinos arubanos),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azeru \(1993–2006\)),
				'one' => q(manat azeru \(1993–2006\)),
				'other' => q(manats azeros \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azeru),
				'one' => q(manat azeru),
				'other' => q(manats azeros),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar de sa Bòsnia-Erzegòvina \(1992–1994\)),
				'one' => q(dinar de sa Bòsnia-Erzegòvina \(1992–1994\)),
				'other' => q(dinares de sa Bòsnia-Erzegòvina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marcu cunvertìbile de sa Bòsnia-Erzegòvina),
				'one' => q(marcu cunvertìbile de sa Bòsnia-Erzegòvina),
				'other' => q(marcos cunvertìbiles de sa Bòsnia-Erzegòvina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(dinar de sa Bòsnia-Erzegòvina \(1994–1997\)),
				'one' => q(dinar de sa Bòsnia-Erzegòvina \(1994–1997\)),
				'other' => q(dinares de sa Bòsnia-Erzegòvina \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dòllaru barbadianu),
				'one' => q(dòllaru barbadianu),
				'other' => q(dòllaros barbadianos),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladesu),
				'one' => q(taka bangladesu),
				'other' => q(takas bangladesos),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(francu belga \(cunvertìbile\)),
				'one' => q(francu belga \(cunvertìbile\)),
				'other' => q(francos belgas \(cunvertìbiles\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(francu belga),
				'one' => q(francu belga),
				'other' => q(francos belgas),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(francu belga \(finantziàriu\)),
				'one' => q(francu belga \(finantziàriu\)),
				'other' => q(francos belgas \(finantziàrios\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev bùlgaru \(1962–1999\)),
				'one' => q(lev bùlgaru \(1962–1999\)),
				'other' => q(levs bùlgaros \(1962–1999\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev sotzialista bùlgaru),
				'one' => q(lev sotzialista bùlgaru),
				'other' => q(levs sotzialistas bùlgaros),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bùlgaru),
				'one' => q(lev bùlgaru),
				'other' => q(levs bùlgaros),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(lev bùlgaru \(1879–1952\)),
				'one' => q(lev bùlgaru \(1879–1952\)),
				'other' => q(levs bùlgaros \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar bahreinu),
				'one' => q(dinar bahreinu),
				'other' => q(dinares bahreinos),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(francu burundianu),
				'one' => q(francu burundianu),
				'other' => q(francos burundianos),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dòllaru de sas Bermudas),
				'one' => q(dòllaru de sas Bermudas),
				'other' => q(dòllaros de sas Bermudas),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dòllaru de su Brunei),
				'one' => q(dòllaru de su Brunei),
				'other' => q(dòllaros de su Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivianu),
				'one' => q(bolivianu),
				'other' => q(bolivianos),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(bolivianu \(1863–1963\)),
				'one' => q(bolivianu \(1863–1963\)),
				'other' => q(bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso bolivianu),
				'one' => q(peso bolivianu),
				'other' => q(pesos bolivianos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol bolivianu),
				'one' => q(mvdol bolivianu),
				'other' => q(mvdols bolivianos),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(cruzèiru nou brasilianu \(1967–1986\)),
				'one' => q(cruzèiru nou brasilianu \(1967–1986\)),
				'other' => q(cruzèiros noos brasilianos \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzadu brasilianu \(1986–1989\)),
				'one' => q(cruzadu brasilianu \(1986–1989\)),
				'other' => q(cruzados brasilianos \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzèiru brasilianu \(1990–1993\)),
				'one' => q(cruzèiru brasilianu \(1990–1993\)),
				'other' => q(cruzèiros brasilianos \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasilianu),
				'one' => q(real brasilianu),
				'other' => q(reales brasilianos),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(cruzadu nou brasilianu \(1989–1990\)),
				'one' => q(cruzadu nou brasilianu \(1989–1990\)),
				'other' => q(cruzados noos brasilianos \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzèiru brasilianu \(1993–1994\)),
				'one' => q(cruzèiru brasilianu \(1993–1994\)),
				'other' => q(cruzèiros brasilianos \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(cruzèiru brasilianu \(1942–1967\)),
				'one' => q(cruzèiru brasilianu \(1942–1967\)),
				'other' => q(cruzèiros brasilianos \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dòllaru bahamesu),
				'one' => q(dòllaru bahamesu),
				'other' => q(dòllaros bahamesos),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum bhutanesu),
				'one' => q(ngultrum bhutanesu),
				'other' => q(ngultrums bhutanesos),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birmanu),
				'one' => q(kyat birmanu),
				'other' => q(kyats birmanos),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula botswanesa),
				'one' => q(pula botswanesa),
				'other' => q(pulas botswanesas),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(rublu bielorussu \(1994–1999\)),
				'one' => q(rublu bielorussu \(1994–1999\)),
				'other' => q(rublos bielorussos \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rublu bielorussu),
				'one' => q(rublu bielorussu),
				'other' => q(rublos bielorussos),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rublu bielorussu \(2000–2016\)),
				'one' => q(rublu bielorussu \(2000–2016\)),
				'other' => q(rublos bielorussos \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dòllaru de su Belize),
				'one' => q(dòllaru de su Belize),
				'other' => q(dòllaros de su Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dòllaru canadesu),
				'one' => q(dòllaru canadesu),
				'other' => q(dòllaros canadesos),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(francu congolesu),
				'one' => q(francu congolesu),
				'other' => q(francos congolesos),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro WIR),
				'one' => q(euro WIR),
				'other' => q(euros WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(francu isvìtzeru),
				'one' => q(francu isvìtzeru),
				'other' => q(francos isvìtzeros),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(francu WIR),
				'one' => q(francu WIR),
				'other' => q(francos WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(iscudu tzilenu),
				'one' => q(iscudu tzilenu),
				'other' => q(iscudos tzilenos),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unidade de acontu tzilena \(UF\)),
				'one' => q(unidade de acontu tzilena \(UF\)),
				'other' => q(unidades de acontu tzilenas \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso tzilenu),
				'one' => q(peso tzilenu),
				'other' => q(pesos tzilenos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(renminbi tzinesu \(extracontinentale\)),
				'one' => q(yuan tzinesu \(extracontinentale\)),
				'other' => q(yuans tzinesos \(extracontinentales\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dòllaru de sa Banca Popolare Tzinesa),
				'one' => q(dòllaru de sa Banca Popolare Tzinesa),
				'other' => q(dòllaros de sa Banca Popolare Tzinesa),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(renminbi tzinesu),
				'one' => q(yuan tzinesu),
				'other' => q(yuans tzinesos),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombianu),
				'one' => q(peso colombianu),
				'other' => q(pesos colombianos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidade de valore reale colombiana),
				'one' => q(unidade de valore reale colombiana),
				'other' => q(unidades de valore reale colombianas),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón costaricanu),
				'one' => q(colón costaricanu),
				'other' => q(colones costaricanos),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar serbu \(2002–2006\)),
				'one' => q(dinar serbu \(2002–2006\)),
				'other' => q(dinares serbos \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(corona forte tzecoslovaca),
				'one' => q(corona forte tzecoslovaca),
				'other' => q(coronas fortes tzecoslovacas),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cubanu cunvertìbile),
				'one' => q(peso cubanu cunvertìbile),
				'other' => q(pesos cubanos cunvertìbiles),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubanu),
				'one' => q(peso cubanu),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(iscudu cabubirdianu),
				'one' => q(iscudu cabubirdianu),
				'other' => q(iscudos cabubirdianos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(isterlina tzipriota),
				'one' => q(isterlina tzipriota),
				'other' => q(isterlinas tzipriotas),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona tzeca),
				'one' => q(corona tzeca),
				'other' => q(coronas tzecas),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(marcu de sa Germània orientale),
				'one' => q(marcu de sa Germània orientale),
				'other' => q(marcos de sa Germània orientale),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marcu tedescu),
				'one' => q(marcu tedescu),
				'other' => q(marcos tedescos),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(francu gibutianu),
				'one' => q(francu gibutianu),
				'other' => q(francos gibutianos),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona danesa),
				'one' => q(corona danesa),
				'other' => q(coronas danesas),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominicanu),
				'one' => q(peso dominicanu),
				'other' => q(pesos dominicanos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerinu),
				'one' => q(dinar algerinu),
				'other' => q(dinares algerinos),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre ecuadorenu),
				'one' => q(sucre ecuadorenu),
				'other' => q(sucres ecuadorenos),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unidade de valore costante ecuadorena),
				'one' => q(unidade de valore costante ecuadorena),
				'other' => q(unidades de valore costante ecuadorenas),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(corona estonesa),
				'one' => q(corona estonesa),
				'other' => q(coronas estonesas),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(isterlina egitziana),
				'one' => q(isterlina egitziana),
				'other' => q(isterlinas egitzianas),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka eritreu),
				'one' => q(nafka eritreu),
				'other' => q(nafkas eritreos),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta ispagnola \(contu A\)),
				'one' => q(peseta ispagnola \(contu A\)),
				'other' => q(pesetas ispagnolas \(contu A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta ispagnola \(contu cunvertìbile\)),
				'one' => q(peseta ispagnola \(contu cunvertìbile\)),
				'other' => q(pesetas ispagnolas \(contu cunvertìbile\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta ispagnola),
				'one' => q(peseta ispagnola),
				'other' => q(pesetas ispagnolas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etìope),
				'one' => q(birr etìope),
				'other' => q(birrs etìopes),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(èuro),
				'one' => q(èuro),
				'other' => q(èuros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marcu finlandesu),
				'one' => q(marcu finlandesu),
				'other' => q(marcos finlandesos),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dòllaru fijianu),
				'one' => q(dòllaru fijianu),
				'other' => q(dòllaros fijianos),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(isterlina de sas ìsulas Falklands),
				'one' => q(isterlina de sas ìsulas Falklands),
				'other' => q(isterlinas de sas ìsulas Falklands),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(francu frantzesu),
				'one' => q(francu frantzesu),
				'other' => q(francos frantzesos),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(isterlina britànnica),
				'one' => q(isterlina britànnica),
				'other' => q(isterlinas britànnicas),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgianu),
				'one' => q(kupon larit georgianu),
				'other' => q(kupon larits georgianos),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgianu),
				'one' => q(lari georgianu),
				'other' => q(laris georgianos),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ganesu \(1979–2007\)),
				'one' => q(cedi ganesu \(1979–2007\)),
				'other' => q(cedis ganesos \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ganesu),
				'one' => q(cedi ganesu),
				'other' => q(cedis ganesos),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(isterlina de Gibilterra),
				'one' => q(isterlina de Gibilterra),
				'other' => q(isterlinas de Gibilterra),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambianu),
				'one' => q(dalasi gambianu),
				'other' => q(dalasis gambianos),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(francu guineanu),
				'one' => q(francu guineanu),
				'other' => q(francos guineanos),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli guineanu),
				'one' => q(syli guineanu),
				'other' => q(sylis guineanos),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele de sa Guinea Ecuadoriana),
				'one' => q(ekwele de sa Guinea Ecuadoriana),
				'other' => q(ekweles de sa Guinea Ecuadoriana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(dracma greca),
				'one' => q(dracma greca),
				'other' => q(dracmas grecas),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemaltecu),
				'one' => q(quetzal guatemaltecu),
				'other' => q(quetzales guatemaltecos),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(iscudu de sa Guinea portoghesa),
				'one' => q(iscudu de sa Guinea portoghesa),
				'other' => q(iscudos de sa Guinea portoghesa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso de sa Guinea-Bissau),
				'one' => q(peso de sa Guinea-Bissau),
				'other' => q(pesos de sa Guinea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dòllaru guyanesu),
				'one' => q(dòllaru guyanesu),
				'other' => q(dòllaros guyanesos),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dòllaru de Hong Kong),
				'one' => q(dòllaru de Hong Kong),
				'other' => q(dòllaros de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira hondurenu),
				'one' => q(lempira hondurenu),
				'other' => q(lempiras hondurenos),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croatu),
				'one' => q(dinar croatu),
				'other' => q(dinares croatos),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunas croatas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitianu),
				'one' => q(gourde haitianu),
				'other' => q(gourdes haitianos),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fiorinu ungheresu),
				'one' => q(fiorinu ungheresu),
				'other' => q(fiorinos ungheresos),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonesiana),
				'one' => q(rupia indonesiana),
				'other' => q(rupias indonesianas),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(isterlina irlandesa),
				'one' => q(isterlina irlandesa),
				'other' => q(isterlinas irlandesas),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(isterlina israeliana),
				'one' => q(isterlina israeliana),
				'other' => q(isterlinas israelianas),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(siclu israelianu \(1980–1985\)),
				'one' => q(siclu israelianu \(1980–1985\)),
				'other' => q(siclos israelianos \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(siclu nou israelianu),
				'one' => q(siclu nou israelianu),
				'other' => q(siclos noos israelianos),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia indiana),
				'one' => q(rupia indiana),
				'other' => q(rupias indianas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar irachenu),
				'one' => q(dinar irachenu),
				'other' => q(dinares irachenos),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranianu),
				'one' => q(rial iranianu),
				'other' => q(riales iranianos),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(corona islandesa \(1918–1981\)),
				'one' => q(corona islandesa \(1918–1981\)),
				'other' => q(coronas islandesas \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona islandesa),
				'one' => q(corona islandesa),
				'other' => q(coronas islandesas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiana),
				'one' => q(lira italiana),
				'other' => q(liras italianas),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dòllaru giamaicanu),
				'one' => q(dòllaru giamaicanu),
				'other' => q(dòllaros giamaicanos),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar giordanu),
				'one' => q(dinar giordanu),
				'other' => q(dinares giordanos),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen giaponesu),
				'one' => q(yen giaponesu),
				'other' => q(yens giaponesos),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(iscellinu kenianu),
				'one' => q(iscellinu kenianu),
				'other' => q(iscellinos kenianos),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghisu),
				'one' => q(som kirghisu),
				'other' => q(soms kirghisos),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambogianu),
				'one' => q(riel cambogianu),
				'other' => q(rieles cambogianos),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(francu comorianu),
				'one' => q(francu comorianu),
				'other' => q(francos comorianos),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nordcoreanu),
				'one' => q(won nordcoreanu),
				'other' => q(wons nordcoreanos),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan sudcoreanu \(1953–1962\)),
				'one' => q(hwan sudcoreanu \(1953–1962\)),
				'other' => q(hwans sudcoreanos \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(won sudcoreanu \(1945–1953\)),
				'one' => q(won sudcoreanu \(1945–1953\)),
				'other' => q(wons sudcoreanos \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won sudcoreanu),
				'one' => q(won sudcoreanu),
				'other' => q(wons sudcoreanos),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuwaitianu),
				'one' => q(dinar kuwaitianu),
				'other' => q(dinares kuwaitianos),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòllaru de sas Ìsulas Cayman),
				'one' => q(dòllaru de sas Ìsulas Cayman),
				'other' => q(dòllaros de sas Ìsulas Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazaku),
				'one' => q(tenge kazaku),
				'other' => q(tenges kazakos),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laotianu),
				'one' => q(kip laotianu),
				'other' => q(kips laotianos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(isterlina lebanesa),
				'one' => q(isterlina lebanesa),
				'other' => q(isterlinas lebanesas),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia de su Sri Lanka),
				'one' => q(rupia de su Sri Lanka),
				'other' => q(rupias de su Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dòllaru liberianu),
				'one' => q(dòllaru liberianu),
				'other' => q(dòllaros liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesothianu),
				'one' => q(loti lesothianu),
				'other' => q(maloti lesothianos),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituanu),
				'one' => q(litas lituanu),
				'other' => q(litas lituanos),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituanu),
				'one' => q(talonas lituanu),
				'other' => q(talonas lituanos),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(francu cunvertìbile lussemburghesu),
				'one' => q(francu cunvertìbile lussemburghesu),
				'other' => q(francos cunvertìbiles lussemburghesos),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(francu lussemburghesu),
				'one' => q(francu lussemburghesu),
				'other' => q(francos lussemburghesos),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(francu finantziàriu lussemburghesu),
				'one' => q(francu finantziàriu lussemburghesu),
				'other' => q(francos finantziàrios lussemburghesos),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats lètone),
				'one' => q(lats lètone),
				'other' => q(lats lètones),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rublu lètone),
				'one' => q(rublu lètone),
				'other' => q(rublos lètones),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar lìbicu),
				'one' => q(dinar lìbicu),
				'other' => q(dinares lìbicos),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marochinu),
				'one' => q(dirham marochinu),
				'other' => q(dirhams marochinos),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(francu marochinu),
				'one' => q(francu marochinu),
				'other' => q(francos marochinos),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(francu monegascu),
				'one' => q(francu monegascu),
				'other' => q(francos monegascos),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(cupon moldavu),
				'one' => q(cupon moldavu),
				'other' => q(cupons moldavos),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldavu),
				'one' => q(leu moldavu),
				'other' => q(leos moldavos),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgàsciu),
				'one' => q(ariary malgàsciu),
				'other' => q(ariarys malgàscios),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(francu malgàsciu),
				'one' => q(francu malgàsciu),
				'other' => q(francos malgàscios),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(denar matzèdone),
				'one' => q(denar matzèdone),
				'other' => q(denares matzèdones),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(denar matzèdone \(1992–1993\)),
				'one' => q(denar matzèdone \(1992–1993\)),
				'other' => q(denares matzèdones \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(francu malianu),
				'one' => q(francu malianu),
				'other' => q(francos malianos),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat de su Myanmar),
				'one' => q(kyat de su Myanmar),
				'other' => q(kyats de su Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mòngolu),
				'one' => q(tugrik mòngolu),
				'other' => q(tugriks mòngolos),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca macanesa),
				'one' => q(pataca macanesa),
				'other' => q(patacas macanesas),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya mauritiana \(1973–2017\)),
				'one' => q(ouguiya mauritiana \(1973–2017\)),
				'other' => q(ouguiyas mauritianas \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritiana),
				'one' => q(ouguiya mauritiana),
				'other' => q(ouguiyas mauritianas),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltesa),
				'one' => q(lira maltesa),
				'other' => q(liras maltesas),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(isterlina maltesa),
				'one' => q(isterlina maltesa),
				'other' => q(isterlinas maltesas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauritziana),
				'one' => q(rupia mauritziana),
				'other' => q(rupias mauritzianas),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(rupia maldiviana \(1947–1981\)),
				'one' => q(rupia maldiviana \(1947–1981\)),
				'other' => q(rupias maldivianas \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa maldiviana),
				'one' => q(rufiyaa maldiviana),
				'other' => q(rufiyaas maldivianas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawiana),
				'one' => q(kwacha malawiana),
				'other' => q(kwachas malawianas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso messicanu),
				'one' => q(peso messicanu),
				'other' => q(pesos messicanos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso de prata messicanu \(1861–1992\)),
				'one' => q(peso de prata messicanu \(1861–1992\)),
				'other' => q(pesos de prata messicanos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unidade de investimentu messicana),
				'one' => q(unidade de investimentu messicana),
				'other' => q(unidades de investimentu messicanas),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malesu),
				'one' => q(ringgit malesu),
				'other' => q(ringgits malesos),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(iscudu mozambicanu),
				'one' => q(iscudu mozambicanu),
				'other' => q(iscudos mozambicanos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metical mozambicanu \(1980–2006\)),
				'one' => q(metical mozambicanu \(1980–2006\)),
				'other' => q(meticales mozambicanos \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambicanu),
				'one' => q(metical mozambicanu),
				'other' => q(meticales mozambicanos),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dòllaru namibianu),
				'one' => q(dòllaru namibianu),
				'other' => q(dòllaros namibianos),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(nairas nigerianas),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(córdoba nicaraguesu \(1988–1991\)),
				'one' => q(córdoba nicaraguesu \(1988–1991\)),
				'other' => q(córdobas nicaraguesos \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaraguesu),
				'one' => q(córdoba nicaraguesu),
				'other' => q(córdobas nicaraguesos),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(fiorinu olandesu),
				'one' => q(fiorinu olandesu),
				'other' => q(fiorinos olandesos),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corona norvegesa),
				'one' => q(corona norvegesa),
				'other' => q(coronas norvegesas),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupias nepalesas),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dòllaru neozelandesu),
				'one' => q(dòllaru neozelandesu),
				'other' => q(dòllaros neozelandesos),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanesu),
				'one' => q(rial omanesu),
				'other' => q(riales omanesos),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panamesu),
				'one' => q(balboa panamesu),
				'other' => q(balboas panamesos),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruvianu),
				'one' => q(inti peruvianu),
				'other' => q(intis peruvianos),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruvianu),
				'one' => q(sol peruvianu),
				'other' => q(soles peruvianos),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruvianu \(1863–1965\)),
				'one' => q(sol peruvianu \(1863–1965\)),
				'other' => q(soles peruvianos \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papuana),
				'one' => q(kina papuana),
				'other' => q(kinas papuanas),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(peso filipinu),
				'one' => q(peso filipinu),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistana),
				'one' => q(rupia pakistana),
				'other' => q(rupias pakistanas),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polacu),
				'one' => q(zloty polacu),
				'other' => q(zlotys polacos),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(złoty polacu \(1950–1995\)),
				'one' => q(złoty polacu \(1950–1995\)),
				'other' => q(złotys polacos \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(iscudu portoghesu),
				'one' => q(iscudu portoghesu),
				'other' => q(iscudos portoghesos),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní paraguayanu),
				'one' => q(guaraní paraguayanu),
				'other' => q(guaranís paraguayanos),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial catarianu),
				'one' => q(rial catarianu),
				'other' => q(riales catarianos),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dòllaru rhodesianu),
				'one' => q(dòllaru rhodesianu),
				'other' => q(dòllaros rhodesianos),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu rumenu \(1952–2006\)),
				'one' => q(leu rumenu \(1952–2006\)),
				'other' => q(leos rumenos \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu rumenu),
				'one' => q(leu rumenu),
				'other' => q(leos rumenos),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbu),
				'one' => q(dinar serbu),
				'other' => q(dinares serbos),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublu russu),
				'one' => q(rublu russu),
				'other' => q(rublos russos),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rublu russu \(1991–1998\)),
				'one' => q(rublu russu \(1991–1998\)),
				'other' => q(rublos russos \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(francu ruandesu),
				'one' => q(francu ruandesu),
				'other' => q(francos ruandesos),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal saudita),
				'one' => q(riyal saudita),
				'other' => q(riyales sauditas),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dòllaru de sas Ìsulas Salomone),
				'one' => q(dòllaru de sas Ìsulas Salomone),
				'other' => q(dòllaros de sas Ìsulas Salomone),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia seychellesa),
				'one' => q(rupia seychellesa),
				'other' => q(rupias seychellesas),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanesu \(1992–2007\)),
				'one' => q(dinar sudanesu \(1992–2007\)),
				'other' => q(dinares sudanesos \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(isterlina sudanesa),
				'one' => q(isterlina sudanesa),
				'other' => q(isterlinas sudanesas),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(isterlina sudanesa \(1957–1998\)),
				'one' => q(isterlina sudanesa \(1957–1998\)),
				'other' => q(isterlinas sudanesas \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona isvedesa),
				'one' => q(corona isvedesa),
				'other' => q(coronas isvedesas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dòllaru de Singapore),
				'one' => q(dòllaru de Singapore),
				'other' => q(dòllaros de Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(isterlina de Sant’Elene),
				'one' => q(isterlina de Sant’Elene),
				'other' => q(isterlinas de Sant’Elene),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar islovenu),
				'one' => q(tolar islovenu),
				'other' => q(tolars islovenos),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(corona islovaca),
				'one' => q(corona islovaca),
				'other' => q(coronas islovacas),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone nou de sa Sierra Leone),
				'one' => q(leone nou de sa Sierra Leone),
				'other' => q(leones noos de sa Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone de sa Sierra Leone),
				'one' => q(leone de sa Sierra Leone),
				'other' => q(leones de sa Sierra Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(iscellinu sòmalu),
				'one' => q(iscellinu sòmalu),
				'other' => q(iscellinos sòmalos),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dòllaru surinamesu),
				'one' => q(dòllaru surinamesu),
				'other' => q(dòllaros surinamesos),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(fiorinu surinamesu),
				'one' => q(fiorinu surinamesu),
				'other' => q(fiorinos surinamesos),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(isterlina sud-sudanesa),
				'one' => q(isterlina sud-sudanesa),
				'other' => q(isterlinas sud-sudanesas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra de São Tomé e Príncipe \(1977–2017\)),
				'one' => q(dobra de São Tomé e Príncipe \(1977–2017\)),
				'other' => q(dobras de São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de São Tomé e Príncipe),
				'one' => q(dobra de São Tomé e Príncipe),
				'other' => q(dobras de São Tomé e Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rublu sovièticu),
				'one' => q(rublu sovièticu),
				'other' => q(rublos sovièticos),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colón salvadorenu),
				'one' => q(colón salvadorenu),
				'other' => q(colones salvadorenos),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(isterlina siriana),
				'one' => q(isterlina siriana),
				'other' => q(isterlinas sirianas),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni de s’Eswatini),
				'one' => q(lilangeni de s’Eswatini),
				'other' => q(lilangenis de s’Eswatini),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandesu),
				'one' => q(baht tailandesu),
				'other' => q(bahts tailandesos),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rublu tagiku),
				'one' => q(rublu tagiku),
				'other' => q(rublos tagikos),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tagiku),
				'one' => q(somoni tagiku),
				'other' => q(somones tagikos),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmenu \(1993–2009\)),
				'one' => q(manat turkmenu \(1993–2009\)),
				'other' => q(manats turkmenos \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmenu),
				'one' => q(manat turkmenu),
				'other' => q(manats turkmenos),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisinu),
				'one' => q(dinar tunisinu),
				'other' => q(dinares tunisinos),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga tongana),
				'one' => q(paʻanga tongana),
				'other' => q(paʻangas tonganas),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(iscudu timoresu),
				'one' => q(iscudu timoresu),
				'other' => q(iscudos timoresos),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira turca \(1922–2005\)),
				'one' => q(lira turca \(1922–2005\)),
				'other' => q(liras turcas \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(liras turcas),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dòllaru de Trinidad e Tobago),
				'one' => q(dòllaru de Trinidad e Tobago),
				'other' => q(dòllaros de Trinidad e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(dòllaru nou taiwanesu),
				'one' => q(dòllaru nou taiwanesu),
				'other' => q(dòllaros noos taiwanesos),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(iscellinu tanzanianu),
				'one' => q(iscellinu tanzanianu),
				'other' => q(iscellinos tanzanianos),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ucraina),
				'one' => q(hryvnia ucraina),
				'other' => q(hryvnias ucrainas),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanets ucrainu),
				'one' => q(karbovanets ucrainu),
				'other' => q(karbovanets ucrainos),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(iscellinu ugandesu \(1966–1987\)),
				'one' => q(iscellinu ugandesu \(1966–1987\)),
				'other' => q(iscellinos ugandesos \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(iscellinu ugandesu),
				'one' => q(iscellinu ugandesu),
				'other' => q(iscellinos ugandesos),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dòllaru americanu),
				'one' => q(dòllaru americanu),
				'other' => q(dòllaros americanos),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dòllaru americanu \(die imbeniente\)),
				'one' => q(dòllaru americanu \(die imbeniente\)),
				'other' => q(dòllaros americanos \(die imbeniente\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dòllaru americanu \(die matessi\)),
				'one' => q(dòllaru americanu \(die matessi\)),
				'other' => q(dòllaros americanos \(die matessi\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguayanu \(unidades inditzizadas\)),
				'one' => q(peso uruguayanu \(unidades inditzizadas\)),
				'other' => q(pesos uruguayanos \(unidades inditzizadas\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguayanu \(1975–1993\)),
				'one' => q(peso uruguayanu \(1975–1993\)),
				'other' => q(pesos uruguayanos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguayanu),
				'one' => q(peso uruguayanu),
				'other' => q(pesos uruguayanos),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(unidade ìnditze de sos salàrios nominales uruguayanos),
				'one' => q(unidade ìnditze de sos salàrios nominales uruguayanos),
				'other' => q(unidades ìnditze de sos salàrios nominales uruguayanos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som uzbeku),
				'one' => q(som uzbeku),
				'other' => q(soms uzbekos),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar venezuelanu \(1871–2008\)),
				'one' => q(bolivar venezuelanu \(1871–2008\)),
				'other' => q(bolivares venezuelanos \(1871–2008\)),
			},
		},
		'VED' => {
			display_name => {
				'currency' => q(bolivar soberanu),
				'one' => q(bolivar soberanu),
				'other' => q(bolivares soberanos),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar venezuelanu \(2008–2018\)),
				'one' => q(bolivar venezuelanu \(2008–2018\)),
				'other' => q(bolivares venezuelanos \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolivar venezuelanu),
				'one' => q(bolivar venezuelanu),
				'other' => q(bolivares venezuelanos),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamesu),
				'one' => q(dong vietnamesu),
				'other' => q(dongs vietnamesos),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong vietnamesu \(1978–1985\)),
				'one' => q(dong vietnamesu \(1978–1985\)),
				'other' => q(dongs vietnamesos \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu de Vanuatu),
				'one' => q(vatu de Vanuatu),
				'other' => q(vatus de Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoana),
				'one' => q(tala samoana),
				'other' => q(talas samoanas),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(francu CFA BEAC),
				'one' => q(francu CFA BEAC),
				'other' => q(francos CFA BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(prata),
				'one' => q(untza troy de prata),
				'other' => q(untzas troy de prata),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(oro),
				'one' => q(untza troy de oro),
				'other' => q(untzas troy de oro),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unidade cumpòsita europea),
				'one' => q(unidade cumpòsita europea),
				'other' => q(unidades cumpòsitas europeas),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unidade monetària europea),
				'one' => q(unidade monetària europea),
				'other' => q(unidades monetàrias europeas),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unidade de acontu europea \(XBC\)),
				'one' => q(unidade de acontu europea \(XBC\)),
				'other' => q(unidades de acontu europeas \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unidade de acontu europea \(XBD\)),
				'one' => q(unidade de acontu europea \(XBD\)),
				'other' => q(unidades de acontu europeas \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dòllaru de sos Caràibes orientales),
				'one' => q(dòllaru de sos Caràibes orientales),
				'other' => q(dòllaros de sos Caràibes orientales),
			},
		},
		'XDR' => {
			symbol => 'DIP',
			display_name => {
				'currency' => q(diritos ispetziales de prelievu),
				'one' => q(diritu ispetziale de prelievu),
				'other' => q(diritos ispetziales de prelievu),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unidade de contu europea),
				'one' => q(unidade de contu europea),
				'other' => q(unidades de contu europeas),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(francu oro frantzesu),
				'one' => q(francu oro frantzesu),
				'other' => q(francos oro frantzesos),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(francu UIC frantzesu),
				'one' => q(francu UIC frantzesu),
				'other' => q(francos UIC frantzesos),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(francu CFA BCEAO),
				'one' => q(francu CFA BCEAO),
				'other' => q(francos CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(pallàdiu),
				'one' => q(untza troy de pallàdiu),
				'other' => q(untzas troy de pallàdiu),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(francu CFP),
				'one' => q(francu CFP),
				'other' => q(francos CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(plàtinu),
				'one' => q(untza troy de plàtinu),
				'other' => q(untzas troy de plàtinu),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fundos RINET),
				'one' => q(unidade de sos fundos RINET),
				'other' => q(unidades de sos fundos RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucres),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(còdighe de valuta pro sas proas),
				'one' => q(unidade de valuta de proa),
				'other' => q(unidades de valuta de proa),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(unidade de acontu ADB),
				'one' => q(unidade de acontu ADB),
				'other' => q(unidades de acontu ADB),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(valuta disconnota),
				'one' => q(\(valuta disconnota\)),
				'other' => q(\(valuta disconnota\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar yemenita),
				'one' => q(dinar yemenita),
				'other' => q(dinares yemenitas),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial yemenita),
				'one' => q(rial yemenita),
				'other' => q(riales yemenitas),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar forte yugoslavu \(1966–1990\)),
				'one' => q(dinar forte yugoslavu \(1966–1990\)),
				'other' => q(dinares fortes yugoslavos \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinar nou yugoslavu \(1994–2002\)),
				'one' => q(dinar nou yugoslavu \(1994–2002\)),
				'other' => q(dinares noos yugoslavos \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar cunvertìbile yugoslavu \(1990–1992\)),
				'one' => q(dinar cunvertìbile yugoslavu \(1990–1992\)),
				'other' => q(dinares cunvertìbiles yugoslavos \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar riformadu yugoslavu \(1992–1993\)),
				'one' => q(dinar riformadu yugoslavu \(1992–1993\)),
				'other' => q(dinares riformados yugoslavos \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sudafricanu \(finantziàriu\)),
				'one' => q(rand sudafricanu \(finantziàriu\)),
				'other' => q(rands sudafricanos \(finantziàrios\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafricanu),
				'one' => q(rand sudafricanu),
				'other' => q(rands sudafricanos),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zambiana \(1968–2012\)),
				'one' => q(kwacha zambiana \(1968–2012\)),
				'other' => q(kwachas zambianas \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambiana),
				'one' => q(kwacha zambiana),
				'other' => q(kwachas zambianas),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zaire nou zaireanu \(1993–1998\)),
				'one' => q(zaire nou zaireanu \(1993–1998\)),
				'other' => q(zaires noos zaireanos \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire zaireanu \(1971–1993\)),
				'one' => q(zaire zaireanu \(1971–1993\)),
				'other' => q(zaires zaireanos \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dòllaru zimbabweanu \(1980–2008\)),
				'one' => q(dòllaru zimbabweanu \(1980–2008\)),
				'other' => q(dòllaros zimbabweanos \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dòllaru zimbabweanu \(2009\)),
				'one' => q(dòllaru zimbabweanu \(2009\)),
				'other' => q(dòllaros zimbabweanos \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dòllaru zimbabweanu \(2008\)),
				'one' => q(dòllaru zimbabweanu \(2008),
				'other' => q(dòllaros zimbabweanos \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'm01',
							'm02',
							'm03',
							'm04',
							'm05',
							'm06',
							'm07',
							'm08',
							'm09',
							'm10',
							'm11',
							'm12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'su de unu mese',
							'su de duos meses',
							'su de tres meses',
							'su de bator meses',
							'su de chimbe meses',
							'su de ses meses',
							'su de sete meses',
							'su de oto meses',
							'su de nove meses',
							'su de deghe meses',
							'su de ùndighi meses',
							'su de dòighi meses'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'mes.',
							'tek.',
							'hed.',
							'tah.',
							'ter',
							'yek.',
							'meg.',
							'mia.',
							'gen.',
							'sene',
							'ham.',
							'neh.',
							'pagu.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'ghe',
							'fre',
							'mar',
							'abr',
							'maj',
							'làm',
							'trì',
							'aus',
							'cab',
							'stG',
							'stA',
							'nad'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ghennàrgiu',
							'freàrgiu',
							'martzu',
							'abrile',
							'maju',
							'làmpadas',
							'trìulas',
							'austu',
							'cabudanni',
							'santugaine',
							'santandria',
							'nadale'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'G',
							'F',
							'M',
							'A',
							'M',
							'L',
							'T',
							'A',
							'C',
							'S',
							'S',
							'N'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'tis.',
							'hes.',
							'kis.',
							'tev.',
							'she.',
							'ad.I',
							'adar',
							'nis.',
							'iyar',
							'siv.',
							'tam.',
							'av',
							'elul'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
					wide => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'cha.',
							'vai.',
							'jya.',
							'asa.',
							'sra.',
							'bha.',
							'asv.',
							'kar.',
							'agr.',
							'pau.',
							'mag.',
							'pha.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-q.',
							'dhuʻl-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharram',
							'safar',
							'rabiʻ I',
							'rabiʻ II',
							'jumada I',
							'jumada II',
							'rajab',
							'shaban',
							'ramadan',
							'shawwal',
							'dhuʻl-qiʻdah',
							'dhuʻl-hijjah'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'far.',
							'ord.',
							'kho.',
							'tir',
							'mor.',
							'sha.',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bah.',
							'esf.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
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
						wed => 'mèr',
						thu => 'giò',
						fri => 'che',
						sat => 'sàb',
						sun => 'dom'
					},
					wide => {
						mon => 'lunis',
						tue => 'martis',
						wed => 'mèrcuris',
						thu => 'giòbia',
						fri => 'chenàbura',
						sat => 'sàbadu',
						sun => 'domìniga'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'G',
						fri => 'C',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1u trimestre',
						1 => '2u trimestre',
						2 => '3u trimestre',
						3 => '4u trimestre'
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
				'narrow' => {
					'am' => q{m.},
					'pm' => q{b.},
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
		'buddhist' => {
			abbreviated => {
				'0' => 'E.B.'
			},
			narrow => {
				'0' => 'EB'
			},
			wide => {
				'0' => 'era buddhista'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'a.D.',
				'1' => 'a.M.'
			},
			wide => {
				'0' => 'in antis de Diocletzianu',
				'1' => 'annu de sos màrtires'
			},
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'a.Inc.',
				'1' => 'p.Inc.'
			},
			wide => {
				'0' => 'in antis de s’Incarnatzione',
				'1' => 'a pustis de s’Incarnatzione'
			},
		},
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => 'a.m.'
			},
			wide => {
				'0' => 'annu de su mundu'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.',
				'1' => 'p.C.'
			},
			wide => {
				'0' => 'in antis de Cristu',
				'1' => 'a pustis de Cristu'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'a.m.'
			},
			wide => {
				'0' => 'annu de su mundu'
			},
		},
		'indian' => {
			wide => {
				'0' => 'era Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'e.E.'
			},
			narrow => {
				'0' => 'E'
			},
			wide => {
				'0' => 'era de s’Egira'
			},
		},
		'japanese' => {
		},
		'persian' => {
			abbreviated => {
				'0' => 'a.p.'
			},
			wide => {
				'0' => 'annu persianu'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'a.R.d.T.',
				'1' => 'R.d.T'
			},
			wide => {
				'0' => 'in antis de sa R.d.T.',
				'1' => 'R.d.T.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'full' => q{EEEE dd 'de' MMMM 'de' 'su' r (U)},
			'long' => q{dd 'de' MMMM 'de' 'su' r (U)},
			'medium' => q{dd MMM r},
			'short' => q{dd-MM-r},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{EEEE d 'de' MMMM 'de' 'su' y G},
			'long' => q{d 'de' MMMM 'de' 'su' y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d 'de' MMMM 'de' 'su' y},
			'long' => q{d 'de' MMMM 'de' 'su' y},
			'medium' => q{d 'de' MMM y},
			'short' => q{dd/MM/y},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			Ed => q{E d},
			Gy => q{r (U)},
			GyMMM => q{MMM r (U)},
			GyMMMEd => q{E d MMM r (U)},
			GyMMMM => q{MMMM 'de' 'su' r (U)},
			GyMMMMEd => q{E d 'de' MMMM 'de' 'su' r (U)},
			GyMMMMd => q{d 'de' MMMM 'de' 'su' r (U)},
			GyMMMd => q{d MMM r},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			UM => q{MM/U},
			UMMM => q{MMM U},
			UMMMd => q{d MMM U},
			UMd => q{dd/MM/U},
			y => q{r (U)},
			yMd => q{dd/MM/r},
			yyyy => q{r (U)},
			yyyyM => q{MM/r},
			yyyyMEd => q{E dd/MM/r},
			yyyyMMM => q{MMM r (U)},
			yyyyMMMEd => q{E d MMM r (U)},
			yyyyMMMM => q{MMMM 'de' 'su' r (U)},
			yyyyMMMMEd => q{E d 'de' MMMM 'de' 'su' r (U)},
			yyyyMMMMd => q{d 'de' MMMM 'de' 'su' r (U)},
			yyyyMMMd => q{d MMM r},
			yyyyMd => q{dd/MM/r},
			yyyyQQQ => q{QQQ r (U)},
			yyyyQQQQ => q{QQQQ 'de' 'su' r (U)},
		},
		'generic' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM 'de' 'su' y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'de' 'su' y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d 'de' MMM 'de' 'su' y G},
			GyMMMd => q{d 'de' MMM 'de' 'su' y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E d 'de' MMM},
			MMMMW => q{'chida' W 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			Md => q{dd/MM},
			yM => q{MM/Y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d 'de' MMM y},
			yMMMM => q{MMMM 'de' 'su' y},
			yMMMd => q{d 'de' MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' 'su' y},
			yw => q{'chida' w 'de' 'su' Y},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'chinese' => {
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM U},
				y => q{MMM U – MMM U},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM U},
				d => q{E d MMM – E d MMM U},
				y => q{E d MMM U – E d MMM U},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' 'su' U},
				y => q{MMMM 'de' 'su' U – MMMM 'de' 'su' U},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM U},
				d => q{dd–dd MMM U},
				y => q{dd MMM U – dd MMM U},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'coptic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'dangi' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'ethiopic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'generic' => {
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd–dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
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
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
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
				M => q{MMMM–MMMM 'de' 'su' y},
				y => q{MMMM 'de' 'su' y – MMMM 'de' 'su' y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'indian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'islamic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'persian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'roc' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'format' => {
				'wide' => {
					'leap' => q{{0} bis},
				},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(incumintzu de su beranu),
						1 => q(abba dae chelu),
						2 => q(ischidada de sos boborrotos),
						3 => q(ecuinòtziu de beranu),
						4 => q(luminosu e craru),
						5 => q(abba pro trigu),
						6 => q(incumintzu de s’istiu),
						7 => q(maturatzione minore),
						8 => q(trigu in ispigas),
						9 => q(solstìtziu de istiu),
						10 => q(afogu minore),
						11 => q(afogu mannu),
						12 => q(incumintzu de s’atòngiu),
						13 => q(acabu de s’afogu),
						14 => q(lentore biancu),
						15 => q(ecuinòtziu de atòngiu),
						16 => q(lentore fritu),
						17 => q(achirrada de su ghiliore),
						18 => q(incumintzu de s’ierru),
						19 => q(nie minore),
						20 => q(nie mannu),
						21 => q(solstìtziu de ierru),
						22 => q(fritu minore),
						23 => q(fritu mannu),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(sòrighe),
						1 => q(boe),
						2 => q(tigre),
						3 => q(cunillu),
						4 => q(dragu),
						5 => q(serpente),
						6 => q(caddu),
						7 => q(craba),
						8 => q(martinica),
						9 => q(puddu),
						10 => q(cane),
						11 => q(porcu),
					},
				},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Ora {0}),
		regionFormat => q(Ora legale: {0}),
		regionFormat => q(Ora istandard: {0}),
		'Acre' => {
			long => {
				'daylight' => q#Ora legale de Acre#,
				'generic' => q#Ora de Acre#,
				'standard' => q#Ora istandard de Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Ora de s’Afghànistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algeri#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Su Càiru#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadìsciu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monròvia#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portu-Nou#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trìpoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tùnisi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora de s’Àfrica tzentrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora de s’Àfrica orientale#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora istandard de s’Àfrica meridionale#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora legale de s’Àfrica otzidentale#,
				'generic' => q#Ora de s’Àfrica otzidentale#,
				'standard' => q#Ora istandard de s’Àfrica otzidentale#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora legale de s’Alaska#,
				'generic' => q#Ora de s’Alaska#,
				'standard' => q#Ora istandard de s’Alaska#,
			},
			short => {
				'daylight' => q#OLAK#,
				'generic' => q#OAK#,
				'standard' => q#OIAK#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Ora legale de Almaty#,
				'generic' => q#Ora de Almaty#,
				'standard' => q#Ora istandard de Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora legale de s’Amatzònia#,
				'generic' => q#Ora de s’Amatzònia#,
				'standard' => q#Ora istandard de s’Amatzònia#,
			},
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Havana' => {
			exemplarCity => q#S’Avana#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Tzitade de su Mèssicu#,
		},
		'America/New_York' => {
			exemplarCity => q#Noa York#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota de su Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota de su Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota de su Nord#,
		},
		'America/Panama' => {
			exemplarCity => q#Pànama#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Portu de Ispagna#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Santu Bartolomeu#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Santu Giuanne#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Santu Cristolu#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lughia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santu Tommasu#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Santu Vissente#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora legale tzentrale USA#,
				'generic' => q#Ora tzentrale USA#,
				'standard' => q#Ora istandard tzentrale USA#,
			},
			short => {
				'daylight' => q#OLT#,
				'generic' => q#OT#,
				'standard' => q#OIT#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora legale orientale USA#,
				'generic' => q#Ora orientale USA#,
				'standard' => q#Ora istandard orientale USA#,
			},
			short => {
				'daylight' => q#OLO#,
				'generic' => q#OO#,
				'standard' => q#OIO#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora legale Montes Pedrosos USA#,
				'generic' => q#Ora Montes Pedrosos USA#,
				'standard' => q#Ora istandard Montes Pedrosos USA#,
			},
			short => {
				'daylight' => q#OLMP#,
				'generic' => q#OMP#,
				'standard' => q#OIMP#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora legale de su Patzìficu USA#,
				'generic' => q#Ora de su Patzìficu USA#,
				'standard' => q#Ora istandard de su Patzìficu USA#,
			},
			short => {
				'daylight' => q#OLP#,
				'generic' => q#OP#,
				'standard' => q#OIP#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Ora legale de Anadyr#,
				'generic' => q#Ora de Anadyr#,
				'standard' => q#Ora istandard de Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora legale de Apia#,
				'generic' => q#Ora de Apia#,
				'standard' => q#Ora istandard de Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Ora legale de Aktau#,
				'generic' => q#Ora de Aktau#,
				'standard' => q#Ora istandard de Aktau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Ora legale de Aktobe#,
				'generic' => q#Ora de Aktobe#,
				'standard' => q#Ora istandard de Aktobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora legale àraba#,
				'generic' => q#Ora àraba#,
				'standard' => q#Ora istandard àraba#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora legale de s’Argentina#,
				'generic' => q#Ora de s’Argentina#,
				'standard' => q#Ora istandard de s’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora legale de s’Argentina otzidentale#,
				'generic' => q#Ora de s’Argentina otzidentale#,
				'standard' => q#Ora istandard de s’Argentina otzidentale#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora legale de s’Armènia#,
				'generic' => q#Ora de s’Armènia#,
				'standard' => q#Ora istandard de s’Armènia#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascu#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daca#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Gerusalemme#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catàr#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyàd#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Tzitade de Ho Chi Minh#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seùl#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheràn#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulàn Bator#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora legale de s’Atlànticu#,
				'generic' => q#Ora de s’Atlànticu#,
				'standard' => q#Ora istandard de s’Atlànticu#,
			},
			short => {
				'daylight' => q#OLA#,
				'generic' => q#OA#,
				'standard' => q#OIA#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorras#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Ìsulas Canàrias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabu Birde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ìsulas Føroyar#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geòrgia de su Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant’Elene#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora legale de s’Austràlia tzentrale#,
				'generic' => q#Ora de s’Austràlia tzentrale#,
				'standard' => q#Ora istandard de s’Austràlia tzentrale#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora legale de s’Austràlia tzentru-otzidentale#,
				'generic' => q#Ora de s’Austràlia tzentru-otzidentale#,
				'standard' => q#Ora istandard de s’Austràlia tzentru-otzidentale#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora legale de s’Austràlia orientale#,
				'generic' => q#Ora de s’Austràlia orientale#,
				'standard' => q#Ora istandard de s’Austràlia orientale#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora legale de s’Austràlia otzidentale#,
				'generic' => q#Ora de s’Austràlia otzidentale#,
				'standard' => q#Ora istandard de s’Austràlia otzidentale#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora legale de s’Azerbaigiàn#,
				'generic' => q#Ora de s’Azerbaigiàn#,
				'standard' => q#Ora istandard de s’Azerbaigiàn#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora legale de sas Azorras#,
				'generic' => q#Ora de sas Azorras#,
				'standard' => q#Ora istandard de sas Azorras#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora legale de su Bangladesh#,
				'generic' => q#Ora de su Bangladesh#,
				'standard' => q#Ora istandard de su Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora de su Bhutàn#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora de sa Bolìvia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora legale de Brasìlia#,
				'generic' => q#Ora de Brasìlia#,
				'standard' => q#Ora istandard de Brasìlia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora de su Brunei#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora legale de su Cabu Birde#,
				'generic' => q#Ora de su Cabu Birde#,
				'standard' => q#Ora istandard de su Cabu Birde#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Ora de Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora istandard de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora legale de sas Chatham#,
				'generic' => q#Ora de sas Chatham#,
				'standard' => q#Ora istandard de sas Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora legale de su Tzile#,
				'generic' => q#Ora de su Tzile#,
				'standard' => q#Ora istandard de su Tzile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora legale de sa Tzina#,
				'generic' => q#Ora de sa Tzina#,
				'standard' => q#Ora istandard de sa Tzina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Ora legale de Choibalsan#,
				'generic' => q#Ora de Choibalsan#,
				'standard' => q#Ora istandard de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora de s’Ìsula de sa Natividade#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora legale de sa Colòmbia#,
				'generic' => q#Ora de sa Colòmbia#,
				'standard' => q#Ora istandard de sa Colòmbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora legale de sas Ìsulas Cook#,
				'generic' => q#Ora de sas Ìsulas Cook#,
				'standard' => q#Ora istandard de sas Ìsulas Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora legale de Cuba#,
				'generic' => q#Ora de Cuba#,
				'standard' => q#Ora istandard de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora de su Timor Est#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora legale de s’Ìsula de Pasca#,
				'generic' => q#Ora de s’Ìsula de Pasca#,
				'standard' => q#Ora istandard de s’Ìsula de Pasca#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora de s’Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Tempus coordinadu universale#,
			},
			short => {
				'standard' => q#TCU#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Tzitade disconnota#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgradu#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlinu#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bùcarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Bùdapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublinu#,
			long => {
				'daylight' => q#Ora istandard irlandesa#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibilterra#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ìsula de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Ìstanbul#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbona#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Ora istiale britànnica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lussemburgu#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mònacu#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parigi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Santu Marinu#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Istocolma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Tzitade de su Vaticanu#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsàvia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagàbria#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurigu#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora legale de s’Europa tzentrale#,
				'generic' => q#Ora de s’Europa tzentrale#,
				'standard' => q#Ora istandard de s’Europa tzentrale#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora legale de s’Europa orientale#,
				'generic' => q#Ora de s’Europa orientale#,
				'standard' => q#Ora istandard de s’Europa orientale#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora de s’estremu oriente europeu (Kaliningrad)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora legale de s’Europa otzidentale#,
				'generic' => q#Ora de s’Europa otzidentale#,
				'standard' => q#Ora istandard de s’Europa otzidentale#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora legale de sas Ìsulas Falkland#,
				'generic' => q#Ora de sas Ìsulas Falkland#,
				'standard' => q#Ora istandard de sas Ìsulas Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora legale de sas Fiji#,
				'generic' => q#Ora de sas Fiji#,
				'standard' => q#Ora istandard de sas Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora de sa Guiana Frantzesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora de sa Terras australes e antàrticas frantzesas#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora de su meridianu de Greenwich#,
			},
			short => {
				'standard' => q#OMG#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora de sas Galàpagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora legale de sa Geòrgia#,
				'generic' => q#Ora de sa Geòrgia#,
				'standard' => q#Ora istandard de sa Geòrgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora legale de sa Groenlàndia orientale#,
				'generic' => q#Ora de sa Groenlàndia orientale#,
				'standard' => q#Ora istandard de sa Groenlàndia orientale#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora legale de sa Groenlàndia otzidentale#,
				'generic' => q#Ora de sa Groenlàndia otzidentale#,
				'standard' => q#Ora istandard de sa Groenlàndia otzidentale#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Ora istandard de Guàm#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora istandard de su Gulfu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora de sa Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora legale de sas ìsulas Hawaii-Aleutinas#,
				'generic' => q#Ora de sas ìsulas Hawaii-Aleutinas#,
				'standard' => q#Ora istandard de sas ìsulas Hawaii-Aleutinas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora legale de Hong Kong#,
				'generic' => q#Ora de Hong Kong#,
				'standard' => q#Ora istandard de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora legale de Hovd#,
				'generic' => q#Ora de Hovd#,
				'standard' => q#Ora istandard de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora istandard de s’Ìndia#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Natividade#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurìtzius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Maiota#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunione#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora de s’Otzèanu Indianu#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora de s’Indotzina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora de s’Indonèsia tzentrale#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora de s’Indonèsia orientale#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora de s’Indonèsia otzidentale#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora legale de s’Iràn#,
				'generic' => q#Ora de s’Iràn#,
				'standard' => q#Ora istandard de s’Iràn#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora legale de Irkutsk#,
				'generic' => q#Ora de Irkutsk#,
				'standard' => q#Ora istandard de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora legale de Israele#,
				'generic' => q#Ora de Israele#,
				'standard' => q#Ora istandard de Israele#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora legale de su Giapone#,
				'generic' => q#Ora de su Giapone#,
				'standard' => q#Ora istandard de su Giapone#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Ora legale de Petropavlovsk-Kamchatski#,
				'generic' => q#Ora de Petropavlovsk-Kamchatski#,
				'standard' => q#Ora istandard de Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora de su Kazàkistan orientale#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora de su Kazàkistan otzidentale#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora legale coreana#,
				'generic' => q#Ora coreana#,
				'standard' => q#Ora istandard coreana#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora legale de Krasnoyarsk#,
				'generic' => q#Ora de Krasnoyarsk#,
				'standard' => q#Ora istandard de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora de su Kirghìzistan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Ora de Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora de sas Ìsulas de sa Lìnia#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora legale de Lord Howe#,
				'generic' => q#Ora de Lord Howe#,
				'standard' => q#Ora istandard de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Ora legale de Macao#,
				'generic' => q#Ora de Macao#,
				'standard' => q#Ora istandard de Macao#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ora de s’Ìsula Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora legale de Magadan#,
				'generic' => q#Ora de Magadan#,
				'standard' => q#Ora istandard de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora de sa Malèsia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora de sas Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora de sas Marchesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora legale de sas Maurìtzius#,
				'generic' => q#Ora de sas Maurìtzius#,
				'standard' => q#Ora istandard de sas Maurìtzius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ora legale de su Mèssicu nord-otzidentale#,
				'generic' => q#Ora de su Mèssicu nord-otzidentale#,
				'standard' => q#Ora istandard de su Mèssicu nord-otzidentale#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora legale de su Patzìficu (Mèssicu)#,
				'generic' => q#Ora de su Patzìficu (Mèssicu)#,
				'standard' => q#Ora istandard de su Patzìficu (Mèssicu)#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora legale de Ulàn Bator#,
				'generic' => q#Ora de Ulàn Bator#,
				'standard' => q#Ora istandard de Ulàn Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora legale de Mosca#,
				'generic' => q#Ora de Mosca#,
				'standard' => q#Ora istandard de Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora de su Myanmàr#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora de su Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora legale de sa Caledònia Noa#,
				'generic' => q#Ora de sa Caledònia Noa#,
				'standard' => q#Ora istandard de sa Caledònia Noa#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora legale de sa Zelanda Noa#,
				'generic' => q#Ora de sa Zelanda Noa#,
				'standard' => q#Ora istandard de sa Zelanda Noa#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora legale de Terranova#,
				'generic' => q#Ora de Terranova#,
				'standard' => q#Ora istandard de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora legale de s’Ìsula Norfolk#,
				'generic' => q#Ora de s’Ìsula Norfolk#,
				'standard' => q#Ora istandard de s’Ìsula Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora legale de su Fernando de Noronha#,
				'generic' => q#Ora de su Fernando de Noronha#,
				'standard' => q#Ora istandard de su Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Mariannas Setentrionales#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora legale de Novosibirsk#,
				'generic' => q#Ora de Novosibirsk#,
				'standard' => q#Ora istandard de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora legale de Omsk#,
				'generic' => q#Ora de Omsk#,
				'standard' => q#Ora istandard de Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guàm#,
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#OLH#,
				'generic' => q#OIH#,
				'standard' => q#OIH#,
			},
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Canton#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marchesas#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora legale de su Pàkistan#,
				'generic' => q#Ora de su Pàkistan#,
				'standard' => q#Ora istandard de su Pàkistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora de sa Pàpua Guinea Noa#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora legale de su Paraguay#,
				'generic' => q#Ora de su Paraguay#,
				'standard' => q#Ora istandard de su Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora legale de su Perù#,
				'generic' => q#Ora de su Perù#,
				'standard' => q#Ora istandard de su Perù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora legale de sas Filipinas#,
				'generic' => q#Ora de sas Filipinas#,
				'standard' => q#Ora istandard de sas Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora de sas Ìsulas de sa Fenìtzie#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora legale de Saint-Pierre e Miquelon#,
				'generic' => q#Ora de Saint-Pierre e Miquelon#,
				'standard' => q#Ora istandard de Saint-Pierre e Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora de sas Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Ora legale de Qyzylorda#,
				'generic' => q#Ora de Qyzylorda#,
				'standard' => q#Ora istandard de Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora de sa Reunione#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora legale de Sakhalin#,
				'generic' => q#Ora de Sakhalin#,
				'standard' => q#Ora istandard de Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Ora legale de Samara#,
				'generic' => q#Ora de Samara#,
				'standard' => q#Ora istandard de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora legale de sas Samoa#,
				'generic' => q#Ora de sas Samoa#,
				'standard' => q#Ora istandard de sas Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora de sas Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora de Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Salomone#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora de sa Geòrgia de su Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora de su Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora legale de Taipei#,
				'generic' => q#Ora de Taipei#,
				'standard' => q#Ora istandard de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora de su Tagìkistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora de su Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora legale de su Tonga#,
				'generic' => q#Ora de su Tonga#,
				'standard' => q#Ora istandard de su Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora de su Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora legale de su Turkmènistan#,
				'generic' => q#Ora de su Turkmènistan#,
				'standard' => q#Ora istandard de su Turkmènistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora de su Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora legale de s’Uruguay#,
				'generic' => q#Ora de s’Uruguay#,
				'standard' => q#Ora istandard de s’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora legale de s’Uzbèkistan#,
				'generic' => q#Ora de s’Uzbèkistan#,
				'standard' => q#Ora istandard de s’Uzbèkistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora legale de su Vanuatu#,
				'generic' => q#Ora de su Vanuatu#,
				'standard' => q#Ora istandard de su Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora de su Venetzuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora legale de Vladivostok#,
				'generic' => q#Ora de Vladivostok#,
				'standard' => q#Ora istandard de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora legale de Volgograd#,
				'generic' => q#Ora de Volgograd#,
				'standard' => q#Ora istandard de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora de sas Ìsulas Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora legale de Yakutsk#,
				'generic' => q#Ora de Yakutsk#,
				'standard' => q#Ora istandard de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora legale de Yekaterinburg#,
				'generic' => q#Ora de Yekaterinburg#,
				'standard' => q#Ora istandard de Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora de su Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
