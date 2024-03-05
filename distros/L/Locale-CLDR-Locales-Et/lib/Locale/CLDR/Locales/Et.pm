=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Et - Package for language Estonian

=cut

package Locale::CLDR::Locales::Et;
# This file auto generated from Data\common\main\et.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal' ]},
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
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← koma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(üks),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaks),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolm),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neli),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viis),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuus),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitse),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kaheksa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(üheksa),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kümme),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→teist),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←kümmend[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←sada[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← tuhat[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljon[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljonit[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardit[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljon[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljonit[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljardit[ →→]),
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
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←← sada[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
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
				'aa' => 'afari',
 				'ab' => 'abhaasi',
 				'ace' => 'atšehi',
 				'ach' => 'atšoli',
 				'ada' => 'adangme',
 				'ady' => 'adõgee',
 				'ae' => 'avesta',
 				'aeb' => 'Tuneesia araabia',
 				'af' => 'afrikaani',
 				'afh' => 'afrihili',
 				'agq' => 'aghemi',
 				'ain' => 'ainu',
 				'ak' => 'akani',
 				'akk' => 'akadi',
 				'akz' => 'alabama',
 				'ale' => 'aleuudi',
 				'aln' => 'geegi',
 				'alt' => 'altai',
 				'am' => 'amhara',
 				'an' => 'aragoni',
 				'ang' => 'vanainglise',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'apc' => 'Levandi araabia',
 				'ar' => 'araabia',
 				'ar_001' => 'tänapäeva araabia kirjakeel',
 				'arc' => 'aramea',
 				'arn' => 'mapudunguni',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'Alžeeria araabia',
 				'ars' => 'Najdi araabia',
 				'arw' => 'aravaki',
 				'ary' => 'Maroko araabia',
 				'arz' => 'Egiptuse araabia',
 				'as' => 'assami',
 				'asa' => 'asu',
 				'ase' => 'Ameerika viipekeel',
 				'ast' => 'astuuria',
 				'atj' => 'atikameki',
 				'av' => 'avaari',
 				'awa' => 'avadhi',
 				'ay' => 'aimara',
 				'az' => 'aserbaidžaani',
 				'az@alt=short' => 'aseri',
 				'ba' => 'baškiiri',
 				'bal' => 'belutši',
 				'ban' => 'bali',
 				'bar' => 'baieri',
 				'bas' => 'basaa',
 				'bax' => 'bamuni',
 				'bbc' => 'bataki',
 				'bbj' => 'ghomala',
 				'be' => 'valgevene',
 				'bej' => 'bedža',
 				'bem' => 'bemba',
 				'bew' => 'betavi',
 				'bez' => 'bena',
 				'bfd' => 'bafuti',
 				'bfq' => 'badaga',
 				'bg' => 'bulgaaria',
 				'bgc' => 'harjaanvi',
 				'bgn' => 'läänebelutši',
 				'bho' => 'bhodžpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikoli',
 				'bin' => 'edo',
 				'bjn' => 'bandžari',
 				'bkm' => 'komi (Aafrika)',
 				'bla' => 'mustjalaindiaani',
 				'blo' => 'anii',
 				'blt' => 'tai-dami',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tiibeti',
 				'bpy' => 'bišnuprija',
 				'bqi' => 'bahtiari',
 				'br' => 'bretooni',
 				'bra' => 'bradži',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosnia',
 				'bss' => 'akoose',
 				'bua' => 'burjaadi',
 				'bug' => 'bugi',
 				'bum' => 'bulu',
 				'byn' => 'bilini',
 				'byv' => 'medumba',
 				'ca' => 'katalaani',
 				'cad' => 'kado',
 				'car' => 'kariibi',
 				'cay' => 'kajuka',
 				'cch' => 'aitšami',
 				'ccp' => 'tšaakma',
 				'ce' => 'tšetšeeni',
 				'ceb' => 'sebu',
 				'cgg' => 'tšiga',
 				'ch' => 'tšamorro',
 				'chb' => 'tšibtša',
 				'chg' => 'tšagatai',
 				'chk' => 'tšuugi',
 				'chm' => 'mari',
 				'chn' => 'tšinuki žargoon',
 				'cho' => 'tšokto',
 				'chp' => 'tšipevai',
 				'chr' => 'tšerokii',
 				'chy' => 'šaieeni',
 				'cic' => 'tšikasoo',
 				'ckb' => 'sorani',
 				'ckb@alt=menu' => 'kurdi (keskkurdi)',
 				'ckb@alt=variant' => 'keskkurdi',
 				'clc' => 'tšilkotini',
 				'co' => 'korsika',
 				'cop' => 'kopti',
 				'cps' => 'kapisnoni',
 				'cr' => 'krii',
 				'crg' => 'michifi',
 				'crh' => 'krimmitatari',
 				'crj' => 'lõuna-idakrii',
 				'crk' => 'tasandikukrii',
 				'crl' => 'põhja-idakrii',
 				'crm' => 'põdrakrii',
 				'crr' => 'Carolina algonkini',
 				'crs' => 'seišelli',
 				'cs' => 'tšehhi',
 				'csb' => 'kašuubi',
 				'csw' => 'sookrii',
 				'cu' => 'kirikuslaavi',
 				'cv' => 'tšuvaši',
 				'cy' => 'kõmri',
 				'da' => 'taani',
 				'dak' => 'siuu',
 				'dar' => 'dargi',
 				'dav' => 'davida',
 				'de' => 'saksa',
 				'de_AT' => 'Austria saksa',
 				'de_CH' => 'Šveitsi ülemsaksa',
 				'del' => 'delavari',
 				'den' => 'sleivi',
 				'dgr' => 'dogribi',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'alamsorbi',
 				'dtp' => 'keskdusuni',
 				'dua' => 'duala',
 				'dum' => 'keskhollandi',
 				'dv' => 'maldiivi',
 				'dyo' => 'fonji',
 				'dyu' => 'djula',
 				'dz' => 'dzongkha',
 				'dzg' => 'daza',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efiki',
 				'egl' => 'emiilia',
 				'egy' => 'egiptuse',
 				'eka' => 'ekadžuki',
 				'el' => 'kreeka',
 				'elx' => 'eelami',
 				'en' => 'inglise',
 				'en_AU' => 'Austraalia inglise',
 				'en_CA' => 'Kanada inglise',
 				'en_GB' => 'Briti inglise',
 				'en_US' => 'Ameerika inglise',
 				'en_US@alt=short' => 'USA inglise',
 				'enm' => 'keskinglise',
 				'eo' => 'esperanto',
 				'es' => 'hispaania',
 				'es_419' => 'Ladina-Ameerika hispaania',
 				'es_ES' => 'Euroopa hispaania',
 				'es_MX' => 'Mehhiko hispaania',
 				'esu' => 'keskjupiki',
 				'et' => 'eesti',
 				'eu' => 'baski',
 				'ewo' => 'evondo',
 				'ext' => 'estremenju',
 				'fa' => 'pärsia',
 				'fa_AF' => 'dari',
 				'fan' => 'fangi',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'soome',
 				'fil' => 'filipiini',
 				'fit' => 'meä',
 				'fj' => 'fidži',
 				'fo' => 'fääri',
 				'fon' => 'foni',
 				'fr' => 'prantsuse',
 				'fr_CA' => 'Kanada prantsuse',
 				'fr_CH' => 'Šveitsi prantsuse',
 				'frc' => 'cajun’i',
 				'frm' => 'keskprantsuse',
 				'fro' => 'vanaprantsuse',
 				'frp' => 'frankoprovansi',
 				'frr' => 'põhjafriisi',
 				'frs' => 'idafriisi',
 				'fur' => 'friuuli',
 				'fy' => 'läänefriisi',
 				'ga' => 'iiri',
 				'gaa' => 'gaa',
 				'gag' => 'gagauusi',
 				'gan' => 'kani',
 				'gay' => 'gajo',
 				'gba' => 'gbaja',
 				'gd' => 'gaeli',
 				'gez' => 'etioopia',
 				'gil' => 'kiribati',
 				'gl' => 'galeegi',
 				'glk' => 'gilaki',
 				'gmh' => 'keskülemsaksa',
 				'gn' => 'guaranii',
 				'goh' => 'vanaülemsaksa',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gooti',
 				'grb' => 'grebo',
 				'grc' => 'vanakreeka',
 				'gsw' => 'šveitsisaksa',
 				'gu' => 'gudžarati',
 				'guc' => 'vajuu',
 				'gur' => 'farefare',
 				'guz' => 'gusii',
 				'gv' => 'mänksi',
 				'gwi' => 'gvitšini',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka',
 				'haw' => 'havai',
 				'hax' => 'lõunahaida',
 				'he' => 'heebrea',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglishi',
 				'hif' => 'Fidži hindi',
 				'hil' => 'hiligainoni',
 				'hit' => 'heti',
 				'hmn' => 'hmongi',
 				'ho' => 'hirimotu',
 				'hr' => 'horvaadi',
 				'hsb' => 'ülemsorbi',
 				'hsn' => 'sjangi',
 				'ht' => 'haiti',
 				'hu' => 'ungari',
 				'hup' => 'hupa',
 				'hur' => 'halkomelemi',
 				'hy' => 'armeenia',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'ibani',
 				'ibb' => 'ibibio',
 				'id' => 'indoneesia',
 				'ie' => 'interlingue',
 				'ig' => 'ibo',
 				'ii' => 'nuosu',
 				'ik' => 'injupiaki',
 				'ikt' => 'Lääne-Kanada inuktituti',
 				'ilo' => 'iloko',
 				'inh' => 'inguši',
 				'io' => 'ido',
 				'is' => 'islandi',
 				'it' => 'itaalia',
 				'iu' => 'inuktituti',
 				'izh' => 'isuri',
 				'ja' => 'jaapani',
 				'jam' => 'Jamaica kreoolkeel',
 				'jbo' => 'ložban',
 				'jgo' => 'ngomba',
 				'jmc' => 'matšame',
 				'jpr' => 'juudipärsia',
 				'jrb' => 'juudiaraabia',
 				'jut' => 'jüüti',
 				'jv' => 'jaava',
 				'ka' => 'gruusia',
 				'kaa' => 'karakalpaki',
 				'kab' => 'kabiili',
 				'kac' => 'katšini',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kaavi',
 				'kbd' => 'kabardi-tšerkessi',
 				'kbl' => 'kanembu',
 				'kcg' => 'tjapi',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingangi',
 				'kha' => 'khasi',
 				'kho' => 'saka',
 				'khq' => 'koyra chiini',
 				'khw' => 'khovari',
 				'ki' => 'kikuju',
 				'kiu' => 'kõrmandžki',
 				'kj' => 'kvanjama',
 				'kk' => 'kasahhi',
 				'kkj' => 'kako',
 				'kl' => 'grööni',
 				'kln' => 'kalendžini',
 				'km' => 'khmeeri',
 				'kmb' => 'mbundu',
 				'kn' => 'kannada',
 				'ko' => 'korea',
 				'koi' => 'permikomi',
 				'kok' => 'konkani',
 				'kos' => 'kosrae',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karatšai-balkaari',
 				'kri' => 'krio',
 				'krj' => 'kinaraia',
 				'krl' => 'karjala',
 				'kru' => 'kuruhhi',
 				'ks' => 'kašmiiri',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölni',
 				'ku' => 'kurdi',
 				'kum' => 'kumõki',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'korni',
 				'kwk' => 'kvakvala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirgiisi',
 				'la' => 'ladina',
 				'lad' => 'ladiino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'letseburgi',
 				'lez' => 'lesgi',
 				'lg' => 'ganda',
 				'li' => 'limburgi',
 				'lij' => 'liguuri',
 				'lil' => 'lillueti',
 				'liv' => 'liivi',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardi',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'Louisiana kreoolkeel',
 				'loz' => 'lozi',
 				'lrc' => 'põhjaluri',
 				'lsm' => 'samia',
 				'lt' => 'leedu',
 				'ltg' => 'latgali',
 				'lu' => 'Katanga luba',
 				'lua' => 'lulua',
 				'lui' => 'luisenjo',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lušei',
 				'luy' => 'luhja',
 				'lv' => 'läti',
 				'lzh' => 'klassikaline hiina',
 				'lzz' => 'lazi',
 				'mad' => 'madura',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makassari',
 				'man' => 'malinke',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'mokša',
 				'mdr' => 'mandari',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'Mauritiuse kreoolkeel',
 				'mg' => 'malagassi',
 				'mga' => 'keskiiri',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta',
 				'mh' => 'maršalli',
 				'mi' => 'maoori',
 				'mic' => 'mikmaki',
 				'min' => 'minangkabau',
 				'mk' => 'makedoonia',
 				'ml' => 'malajalami',
 				'mn' => 'mongoli',
 				'mnc' => 'mandžu',
 				'mni' => 'manipuri',
 				'moe' => 'innu',
 				'moh' => 'mohoogi',
 				'mos' => 'more',
 				'mr' => 'marathi',
 				'mrj' => 'mäemari',
 				'ms' => 'malai',
 				'mt' => 'malta',
 				'mua' => 'mundangi',
 				'mul' => 'mitu keelt',
 				'mus' => 'maskogi',
 				'mwl' => 'miranda',
 				'mwr' => 'marvari',
 				'mwv' => 'mentavei',
 				'my' => 'birma',
 				'mye' => 'mjene',
 				'myv' => 'ersa',
 				'mzn' => 'mazandaraani',
 				'na' => 'nauru',
 				'nan' => 'lõunamini',
 				'nap' => 'napoli',
 				'naq' => 'nama',
 				'nb' => 'norra bokmål',
 				'nd' => 'põhjandebele',
 				'nds' => 'alamsaksa',
 				'nds_NL' => 'Hollandi alamsaksa',
 				'ne' => 'nepali',
 				'new' => 'nevari',
 				'ng' => 'ndonga',
 				'nia' => 'niasi',
 				'niu' => 'niue',
 				'njo' => 'ao',
 				'nl' => 'hollandi',
 				'nl_BE' => 'flaami',
 				'nmg' => 'kwasio',
 				'nn' => 'uusnorra',
 				'nnh' => 'ngiembooni',
 				'no' => 'norra',
 				'nog' => 'nogai',
 				'non' => 'vanapõhja',
 				'nov' => 'noviaal',
 				'nqo' => 'nkoo',
 				'nr' => 'lõunandebele',
 				'nso' => 'põhjasotho',
 				'nus' => 'nueri',
 				'nv' => 'navaho',
 				'nwc' => 'vananevari',
 				'ny' => 'njandža',
 				'nym' => 'njamvesi',
 				'nyn' => 'njankole',
 				'nyo' => 'njoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitaani',
 				'oj' => 'odžibvei',
 				'ojb' => 'loodeodžibvei',
 				'ojc' => 'keskodžibvei',
 				'ojs' => 'Severni odžibvei',
 				'ojw' => 'lääneodžibvei',
 				'oka' => 'okanagani',
 				'om' => 'oromo',
 				'or' => 'oria',
 				'os' => 'osseedi',
 				'osa' => 'oseidži',
 				'ota' => 'osmanitürgi',
 				'pa' => 'pandžabi',
 				'pag' => 'pangasinani',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'belau',
 				'pcd' => 'pikardi',
 				'pcm' => 'Nigeeria pidžinkeel',
 				'pdc' => 'Pennsylvania saksa',
 				'pdt' => 'mennoniidisaksa',
 				'peo' => 'vanapärsia',
 				'pfl' => 'Pfalzi',
 				'phn' => 'foiniikia',
 				'pi' => 'paali',
 				'pis' => 'pijini',
 				'pl' => 'poola',
 				'pms' => 'piemonte',
 				'pnt' => 'pontose',
 				'pon' => 'poonpei',
 				'pqm' => 'passamakodi',
 				'prg' => 'preisi',
 				'pro' => 'vanaprovansi',
 				'ps' => 'puštu',
 				'pt' => 'portugali',
 				'pt_BR' => 'Brasiilia portugali',
 				'pt_PT' => 'Euroopa portugali',
 				'qu' => 'ketšua',
 				'quc' => 'kitše',
 				'raj' => 'radžastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rgn' => 'romanja',
 				'rhg' => 'rohingja',
 				'rif' => 'riifi',
 				'rm' => 'romanši',
 				'rn' => 'rundi',
 				'ro' => 'rumeenia',
 				'ro_MD' => 'moldova',
 				'rof' => 'rombo',
 				'rom' => 'mustlaskeel',
 				'rtm' => 'rotuma',
 				'ru' => 'vene',
 				'rue' => 'russiini',
 				'rug' => 'roviana',
 				'rup' => 'aromuuni',
 				'rw' => 'ruanda',
 				'rwk' => 'rvaa',
 				'sa' => 'sanskriti',
 				'sad' => 'sandave',
 				'sah' => 'jakuudi',
 				'sam' => 'Samaaria aramea',
 				'saq' => 'samburu',
 				'sas' => 'sasaki',
 				'sat' => 'santali',
 				'saz' => 'sauraštra',
 				'sba' => 'ngambai',
 				'sbp' => 'sangu',
 				'sc' => 'sardi',
 				'scn' => 'sitsiilia',
 				'sco' => 'šoti',
 				'sd' => 'sindhi',
 				'sdh' => 'lõunakurdi',
 				'se' => 'põhjasaami',
 				'see' => 'seneka',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'sölkupi',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'vanaiiri',
 				'sgs' => 'žemaidi',
 				'sh' => 'serbia-horvaadi',
 				'shi' => 'šilha',
 				'shn' => 'šani',
 				'shu' => 'Tšaadi araabia',
 				'si' => 'singali',
 				'sid' => 'sidamo',
 				'sk' => 'slovaki',
 				'skr' => 'seraiki',
 				'sl' => 'sloveeni',
 				'slh' => 'Lõuna-Puget-Soundi sališi',
 				'sli' => 'alamsileesia',
 				'sly' => 'selajari',
 				'sm' => 'samoa',
 				'sma' => 'lõunasaami',
 				'smj' => 'Lule saami',
 				'smn' => 'Inari saami',
 				'sms' => 'koltasaami',
 				'sn' => 'šona',
 				'snk' => 'soninke',
 				'so' => 'somaali',
 				'sog' => 'sogdi',
 				'sq' => 'albaania',
 				'sr' => 'serbia',
 				'srn' => 'sranani',
 				'srr' => 'sereri',
 				'ss' => 'svaasi',
 				'ssy' => 'saho',
 				'st' => 'lõunasotho',
 				'stq' => 'saterfriisi',
 				'str' => 'väinasališi',
 				'su' => 'sunda',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeri',
 				'sv' => 'rootsi',
 				'sw' => 'suahiili',
 				'sw_CD' => 'Kongo suahiili',
 				'swb' => 'komoori',
 				'syc' => 'vanasüüria',
 				'syr' => 'süüria',
 				'szl' => 'sileesia',
 				'ta' => 'tamili',
 				'tce' => 'lõunatutšoni',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetumi',
 				'tg' => 'tadžiki',
 				'tgx' => 'tagishi',
 				'th' => 'tai',
 				'tht' => 'tahltani',
 				'ti' => 'tigrinja',
 				'tig' => 'tigree',
 				'tiv' => 'tivi',
 				'tk' => 'türkmeeni',
 				'tkl' => 'tokelau',
 				'tkr' => 'tsahhi',
 				'tl' => 'tagalogi',
 				'tlh' => 'klingoni',
 				'tli' => 'tlingiti',
 				'tly' => 'talõši',
 				'tmh' => 'tamašeki',
 				'tn' => 'tsvana',
 				'to' => 'tonga',
 				'tog' => 'tšitonga',
 				'tok' => 'toki pona',
 				'tpi' => 'uusmelaneesia',
 				'tr' => 'türgi',
 				'tru' => 'turojo',
 				'trv' => 'taroko',
 				'trw' => 'torvali',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakoonia',
 				'tsi' => 'tsimši',
 				'tt' => 'tatari',
 				'ttm' => 'põhjatutšoni',
 				'ttt' => 'lõunataadi',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'tvii',
 				'twq' => 'taswaqi',
 				'ty' => 'tahiti',
 				'tyv' => 'tõva',
 				'tzm' => 'tamasikti',
 				'udm' => 'udmurdi',
 				'ug' => 'uiguuri',
 				'uga' => 'ugariti',
 				'uk' => 'ukraina',
 				'umb' => 'umbundu',
 				'und' => 'määramata keel',
 				'ur' => 'urdu',
 				'uz' => 'usbeki',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'veneti',
 				'vep' => 'vepsa',
 				'vi' => 'vietnami',
 				'vls' => 'lääneflaami',
 				'vmf' => 'Maini frangi',
 				'vmw' => 'makua',
 				'vo' => 'volapüki',
 				'vot' => 'vadja',
 				'vro' => 'võru',
 				'vun' => 'vundžo',
 				'wa' => 'vallooni',
 				'wae' => 'valsi',
 				'wal' => 'volaita',
 				'war' => 'varai',
 				'was' => 'vašo',
 				'wbp' => 'varlpiri',
 				'wo' => 'volofi',
 				'wuu' => 'uu',
 				'xal' => 'kalmõki',
 				'xh' => 'koosa',
 				'xmf' => 'megreli',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japi',
 				'yav' => 'yangbeni',
 				'ybb' => 'jemba',
 				'yi' => 'jidiši',
 				'yo' => 'joruba',
 				'yrl' => 'njengatu',
 				'yue' => 'kantoni',
 				'yue@alt=menu' => 'hiina (kantoni)',
 				'za' => 'tšuangi',
 				'zap' => 'sapoteegi',
 				'zbl' => 'Blissi sümbolid',
 				'zea' => 'zeelandi',
 				'zen' => 'zenaga',
 				'zgh' => 'tamasikti (Maroko)',
 				'zh' => 'hiina',
 				'zh@alt=menu' => 'hiina (mandariinihiina)',
 				'zh_Hans' => 'lihtsustatud hiina',
 				'zh_Hans@alt=long' => 'lihtsustatud mandariinihiina',
 				'zh_Hant' => 'traditsiooniline hiina',
 				'zh_Hant@alt=long' => 'traditsiooniline mandariinihiina',
 				'zu' => 'suulu',
 				'zun' => 'sunji',
 				'zxx' => 'mittekeeleline',
 				'zza' => 'zaza',

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
			'Adlm' => 'adlami',
 			'Afak' => 'afaka',
 			'Aghb' => 'albaani',
 			'Ahom' => 'ahomi',
 			'Arab' => 'araabia',
 			'Arab@alt=variant' => 'pärsia-araabia',
 			'Aran' => 'nastaliik',
 			'Armi' => 'vanaaramea',
 			'Armn' => 'armeenia',
 			'Avst' => 'avesta',
 			'Bali' => 'bali',
 			'Bamu' => 'bamumi',
 			'Bass' => 'bassa',
 			'Batk' => 'bataki',
 			'Beng' => 'bengali',
 			'Blis' => 'Blissi sümbolid',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'braahmi',
 			'Brai' => 'punktkiri',
 			'Bugi' => 'bugi',
 			'Buhd' => 'buhidi',
 			'Cakm' => 'tšaakma',
 			'Cans' => 'Kanada põlisrahvaste ühtlustatud silpkiri',
 			'Cari' => 'kaaria',
 			'Cham' => 'tšaami',
 			'Cher' => 'tšerokii',
 			'Chrs' => 'horezmi',
 			'Cirt' => 'Cirthi',
 			'Copt' => 'kopti',
 			'Cpmn' => 'Küprose minose',
 			'Cprt' => 'Küprose silpkiri',
 			'Cyrl' => 'kirillitsa',
 			'Cyrs' => 'kürilliline kirikuslaavi',
 			'Deva' => 'devanaagari',
 			'Diak' => 'divehi',
 			'Dsrt' => 'desereti',
 			'Dupl' => 'Duployé kiirkiri',
 			'Egyd' => 'egiptuse demootiline',
 			'Egyh' => 'egiptuse hieraatiline',
 			'Egyp' => 'egiptuse hieroglüüfkiri',
 			'Elba' => 'Elbasani',
 			'Elym' => 'elümi',
 			'Ethi' => 'etioopia',
 			'Geok' => 'hutsuri',
 			'Geor' => 'gruusia',
 			'Glag' => 'glagoolitsa',
 			'Gong' => 'Gūnjāla gondi',
 			'Gonm' => 'Masarami gondi',
 			'Goth' => 'gooti',
 			'Gran' => 'grantha',
 			'Grek' => 'kreeka',
 			'Gujr' => 'gudžarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanbi',
 			'Hang' => 'korea',
 			'Hani' => 'hani',
 			'Hano' => 'hanunoo',
 			'Hans' => 'lihtsustatud',
 			'Hans@alt=stand-alone' => 'lihtsustatud hani',
 			'Hant' => 'traditsiooniline',
 			'Hant@alt=stand-alone' => 'traditsiooniline hani',
 			'Hatr' => 'Hatra',
 			'Hebr' => 'heebrea',
 			'Hira' => 'hiragana',
 			'Hluw' => 'Anatoolia hieroglüüfkiri',
 			'Hmng' => 'phahau-hmongi kiri',
 			'Hrkt' => 'jaapani silpkirjad',
 			'Hung' => 'vanaungari',
 			'Inds' => 'Induse',
 			'Ital' => 'vanaitali',
 			'Jamo' => 'jamo',
 			'Java' => 'jaava',
 			'Jpan' => 'jaapani',
 			'Jurc' => 'tšurtšeni',
 			'Kali' => 'kaja-lii',
 			'Kana' => 'katakana',
 			'Kawi' => 'kaavi',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmeeri',
 			'Khoj' => 'hodžki',
 			'Kits' => 'kitani väike kiri',
 			'Knda' => 'kannada',
 			'Kore' => 'korea segakiri',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'tai-thami',
 			'Laoo' => 'lao',
 			'Latf' => 'ladina fraktuurkiri',
 			'Latg' => 'ladina gaeli',
 			'Latn' => 'ladina',
 			'Lepc' => 'leptša',
 			'Limb' => 'limbu',
 			'Lina' => 'lineaarkiri A',
 			'Linb' => 'lineaarkiri B',
 			'Lisu' => 'lisu',
 			'Loma' => 'loma',
 			'Lyci' => 'lüükia',
 			'Lydi' => 'lüüdia',
 			'Mahj' => 'mahaadžani',
 			'Maka' => 'makassari',
 			'Mand' => 'mandea',
 			'Mani' => 'mani',
 			'Maya' => 'maaja hieroglüüfkiri',
 			'Mend' => 'mende',
 			'Merc' => 'meroe kursiivkiri',
 			'Mero' => 'meroe',
 			'Mlym' => 'malajalami',
 			'Modi' => 'modi',
 			'Mong' => 'mongoli',
 			'Moon' => 'Mooni',
 			'Mroo' => 'mruu',
 			'Mtei' => 'meitei',
 			'Mult' => 'Multani',
 			'Mymr' => 'birma',
 			'Nagm' => 'Nagi mundari',
 			'Narb' => 'Põhja-Araabia',
 			'Nbat' => 'Nabatea',
 			'Newa' => 'nevari',
 			'Nkgb' => 'nasi',
 			'Nkoo' => 'nkoo',
 			'Nshu' => 'nüšu',
 			'Ogam' => 'ogam',
 			'Olck' => 'santali',
 			'Orkh' => 'Orhoni',
 			'Orya' => 'oria',
 			'Osge' => 'oseidži',
 			'Osma' => 'osmani',
 			'Ougr' => 'vanauiguuri',
 			'Palm' => 'Palmyra',
 			'Perm' => 'vanapermi',
 			'Phag' => 'phakpa',
 			'Phli' => 'pahlavi raidkiri',
 			'Phlp' => 'pahlavi psalmikiri',
 			'Phlv' => 'pahlavi raamatukiri',
 			'Phnx' => 'foiniikia',
 			'Plrd' => 'Pollardi miao',
 			'Prti' => 'partia raidkiri',
 			'Rjng' => 'redžangi',
 			'Rohg' => 'rohingja',
 			'Roro' => 'rongorongo',
 			'Runr' => 'ruunikiri',
 			'Samr' => 'Samaaria',
 			'Sara' => 'sarati',
 			'Sarb' => 'Lõuna-Araabia',
 			'Saur' => 'sauraštra',
 			'Sgnw' => 'viipekiri',
 			'Shaw' => 'Shaw’ kiri',
 			'Shrd' => 'šaarada',
 			'Sidd' => 'siddhami',
 			'Sind' => 'hudavadi',
 			'Sinh' => 'singali',
 			'Sogd' => 'sogdi',
 			'Sogo' => 'vanasogdi',
 			'Sora' => 'sora',
 			'Soyo' => 'sojombo',
 			'Sund' => 'sunda',
 			'Sylo' => 'siloti',
 			'Syrc' => 'süüria',
 			'Syre' => 'süüria estrangelo',
 			'Syrj' => 'läänesüüria',
 			'Syrn' => 'idasüüria',
 			'Tagb' => 'tagbanva',
 			'Takr' => 'taakri',
 			'Tale' => 'tai-löö',
 			'Talu' => 'uus tai-lõõ',
 			'Taml' => 'tamili',
 			'Tang' => 'tanguudi',
 			'Tavt' => 'tai-vieti',
 			'Telu' => 'telugu',
 			'Teng' => 'Tengwari',
 			'Tfng' => 'tifinagi',
 			'Tglg' => 'tagalogi',
 			'Thaa' => 'taana',
 			'Thai' => 'tai',
 			'Tibt' => 'tiibeti',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tase',
 			'Toto' => 'toto',
 			'Ugar' => 'ugariti',
 			'Vaii' => 'vai',
 			'Visp' => 'nähtava kõne',
 			'Vith' => 'Vithkuqi',
 			'Wara' => 'hoo',
 			'Wcho' => 'vantšo',
 			'Wole' => 'voleai',
 			'Xpeo' => 'vanapärsia',
 			'Xsux' => 'sumeri-akadi kiilkiri',
 			'Yezi' => 'jeziidi',
 			'Yiii' => 'jii',
 			'Zanb' => 'Dzanabadzari ruutkiri',
 			'Zinh' => 'päritud',
 			'Zmth' => 'matemaatiline tähistus',
 			'Zsye' => 'emoji',
 			'Zsym' => 'sümbolid',
 			'Zxxx' => 'kirjakeeleta',
 			'Zyyy' => 'üldine',
 			'Zzzz' => 'määramata kiri',

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
			'001' => 'maailm',
 			'002' => 'Aafrika',
 			'003' => 'Põhja-Ameerika',
 			'005' => 'Lõuna-Ameerika',
 			'009' => 'Okeaania',
 			'011' => 'Lääne-Aafrika',
 			'013' => 'Kesk-Ameerika',
 			'014' => 'Ida-Aafrika',
 			'015' => 'Põhja-Aafrika',
 			'017' => 'Kesk-Aafrika',
 			'018' => 'Lõuna-Aafrika',
 			'019' => 'Ameerika',
 			'021' => 'Ameerika põhjaosa',
 			'029' => 'Kariibi piirkond',
 			'030' => 'Ida-Aasia',
 			'034' => 'Lõuna-Aasia',
 			'035' => 'Kagu-Aasia',
 			'039' => 'Lõuna-Euroopa',
 			'053' => 'Australaasia',
 			'054' => 'Melaneesia',
 			'057' => 'Mikroneesia (piirkond)',
 			'061' => 'Polüneesia',
 			'142' => 'Aasia',
 			'143' => 'Kesk-Aasia',
 			'145' => 'Lääne-Aasia',
 			'150' => 'Euroopa',
 			'151' => 'Ida-Euroopa',
 			'154' => 'Põhja-Euroopa',
 			'155' => 'Lääne-Euroopa',
 			'202' => 'Sahara-tagune Aafrika',
 			'419' => 'Ladina-Ameerika',
 			'AC' => 'Ascensioni saar',
 			'AD' => 'Andorra',
 			'AE' => 'Araabia Ühendemiraadid',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua ja Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albaania',
 			'AM' => 'Armeenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Ameerika Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Austraalia',
 			'AW' => 'Aruba',
 			'AX' => 'Ahvenamaa',
 			'AZ' => 'Aserbaidžaan',
 			'BA' => 'Bosnia ja Hertsegoviina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaaria',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Boliivia',
 			'BQ' => 'Kariibi Madalmaad',
 			'BR' => 'Brasiilia',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet’ saar',
 			'BW' => 'Botswana',
 			'BY' => 'Valgevene',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kookossaared',
 			'CD' => 'Kongo DV',
 			'CD@alt=variant' => 'Kongo-Kinshasa',
 			'CF' => 'Kesk-Aafrika Vabariik',
 			'CG' => 'Kongo Vabariik',
 			'CG@alt=variant' => 'Kongo-Brazzaville',
 			'CH' => 'Šveits',
 			'CI' => 'Elevandiluurannik',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cooki saared',
 			'CL' => 'Tšiili',
 			'CM' => 'Kamerun',
 			'CN' => 'Hiina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertoni saar',
 			'CQ' => 'Sark',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Roheneemesaared',
 			'CW' => 'Curaçao',
 			'CX' => 'Jõulusaar',
 			'CY' => 'Küpros',
 			'CZ' => 'Tšehhi',
 			'CZ@alt=variant' => 'Tšehhi Vabariik',
 			'DE' => 'Saksamaa',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Taani',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaani Vabariik',
 			'DZ' => 'Alžeeria',
 			'EA' => 'Ceuta ja Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Eesti',
 			'EG' => 'Egiptus',
 			'EH' => 'Lääne-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Hispaania',
 			'ET' => 'Etioopia',
 			'EU' => 'Euroopa Liit',
 			'EZ' => 'euroala',
 			'FI' => 'Soome',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandi saared',
 			'FK@alt=variant' => 'Falklandi saared (Malviini saared)',
 			'FM' => 'Mikroneesia',
 			'FO' => 'Fääri saared',
 			'FR' => 'Prantsusmaa',
 			'GA' => 'Gabon',
 			'GB' => 'Ühendkuningriik',
 			'GB@alt=short' => 'ÜK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruusia',
 			'GF' => 'Prantsuse Guajaana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Gröönimaa',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatoriaal-Guinea',
 			'GR' => 'Kreeka',
 			'GS' => 'Lõuna-Georgia ja Lõuna-Sandwichi saared',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkongi erihalduspiirkond',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardi ja McDonaldi saared',
 			'HN' => 'Honduras',
 			'HR' => 'Horvaatia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungari',
 			'IC' => 'Kanaari saared',
 			'ID' => 'Indoneesia',
 			'IE' => 'Iirimaa',
 			'IL' => 'Iisrael',
 			'IM' => 'Mani saar',
 			'IN' => 'India',
 			'IO' => 'Briti India ookeani ala',
 			'IO@alt=chagos' => 'Chagose saared',
 			'IQ' => 'Iraak',
 			'IR' => 'Iraan',
 			'IS' => 'Island',
 			'IT' => 'Itaalia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordaania',
 			'JP' => 'Jaapan',
 			'KE' => 'Keenia',
 			'KG' => 'Kõrgõzstan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoorid',
 			'KN' => 'Saint Kitts ja Nevis',
 			'KP' => 'Põhja-Korea',
 			'KR' => 'Lõuna-Korea',
 			'KW' => 'Kuveit',
 			'KY' => 'Kaimanisaared',
 			'KZ' => 'Kasahstan',
 			'LA' => 'Laos',
 			'LB' => 'Liibanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libeeria',
 			'LS' => 'Lesotho',
 			'LT' => 'Leedu',
 			'LU' => 'Luksemburg',
 			'LV' => 'Läti',
 			'LY' => 'Liibüa',
 			'MA' => 'Maroko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalli Saared',
 			'MK' => 'Põhja-Makedoonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birma)',
 			'MN' => 'Mongoolia',
 			'MO' => 'Macau erihalduspiirkond',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Põhja-Mariaanid',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritaania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiivid',
 			'MW' => 'Malawi',
 			'MX' => 'Mehhiko',
 			'MY' => 'Malaisia',
 			'MZ' => 'Mosambiik',
 			'NA' => 'Namiibia',
 			'NC' => 'Uus-Kaledoonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigeeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Holland',
 			'NO' => 'Norra',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Uus-Meremaa',
 			'NZ@alt=variant' => 'Aotearoa Uus-Meremaa',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peruu',
 			'PF' => 'Prantsuse Polüneesia',
 			'PG' => 'Paapua Uus-Guinea',
 			'PH' => 'Filipiinid',
 			'PK' => 'Pakistan',
 			'PL' => 'Poola',
 			'PM' => 'Saint-Pierre ja Miquelon',
 			'PN' => 'Pitcairni saared',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestiina alad',
 			'PS@alt=short' => 'Palestiina',
 			'PT' => 'Portugal',
 			'PW' => 'Belau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Okeaania hajasaared',
 			'RE' => 'Réunion',
 			'RO' => 'Rumeenia',
 			'RS' => 'Serbia',
 			'RU' => 'Venemaa',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Araabia',
 			'SB' => 'Saalomoni Saared',
 			'SC' => 'Seišellid',
 			'SD' => 'Sudaan',
 			'SE' => 'Rootsi',
 			'SG' => 'Singapur',
 			'SH' => 'Saint Helena',
 			'SI' => 'Sloveenia',
 			'SJ' => 'Svalbard ja Jan Mayen',
 			'SK' => 'Slovakkia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somaalia',
 			'SR' => 'Suriname',
 			'SS' => 'Lõuna-Sudaan',
 			'ST' => 'São Tomé ja Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Süüria',
 			'SZ' => 'Svaasimaa',
 			'SZ@alt=variant' => 'eSwatini',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks ja Caicos',
 			'TD' => 'Tšaad',
 			'TF' => 'Prantsuse Lõunaalad',
 			'TG' => 'Togo',
 			'TH' => 'Tai',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Ida-Timor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Türkmenistan',
 			'TN' => 'Tuneesia',
 			'TO' => 'Tonga',
 			'TR' => 'Türgi',
 			'TT' => 'Trinidad ja Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansaania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ühendriikide hajasaared',
 			'UN' => 'Ühinenud Rahvaste Organisatsioon',
 			'UN@alt=short' => 'ÜRO',
 			'US' => 'Ameerika Ühendriigid',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Saint Vincent ja Grenadiinid',
 			'VE' => 'Venezuela',
 			'VG' => 'Briti Neitsisaared',
 			'VI' => 'USA Neitsisaared',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ja Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-aktsent',
 			'XB' => 'pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Jeemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Lõuna-Aafrika Vabariik',
 			'ZM' => 'Sambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'tundmatu piirkond',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'saksa traditsiooniline kirjaviis',
 			'1994' => 'normitud Resia kirjaviis',
 			'1996' => 'saksa reformitud kirjaviis',
 			'1606NICT' => 'hiliskeskprantsuse (kuni 1606)',
 			'1694ACAD' => 'varajane moodne prantsuse',
 			'1959ACAD' => 'akadeemiline',
 			'ALALC97' => 'ALA-LC latinisatsioon (1997)',
 			'AREVELA' => 'idaarmeenia',
 			'AREVMDA' => 'läänearmeenia',
 			'BAKU1926' => 'ühtlustatud türgi-ladina tähestik',
 			'BISKE' => 'San Giorgio/Bila murre',
 			'BOONT' => 'boontlingi',
 			'EKAVSK' => 'štokavi e-line murrak',
 			'FONIPA' => 'IPA foneetika',
 			'FONUPA' => 'UPA foneetika',
 			'HEPBURN' => 'Hepburni latinisatsioon',
 			'IJEKAVSK' => 'štokavi ije-line murrak',
 			'KKCOR' => 'üldlevinud kirjaviis',
 			'KSCOR' => 'normitud kirjaviis',
 			'LIPAW' => 'Resia Lipovaz’i murre',
 			'MONOTON' => 'monotoonne',
 			'NEDIS' => 'Natisone murre',
 			'NJIVA' => 'Gniva/Njiva murre',
 			'OSOJS' => 'Oseacco/Osojane murre',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polütooniline',
 			'POSIX' => 'arvuti',
 			'REVISED' => 'uus kirjaviis',
 			'ROZAJ' => 'Resia murre',
 			'SAAHO' => 'saho murre',
 			'SCOTLAND' => 'šoti tavainglise',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'Stolvizza/Solbica murre',
 			'TARASK' => 'Taraskievica ortograafia',
 			'UCCOR' => 'ühtlustatud ortograafia',
 			'UCRCOR' => 'ühtlustatud redigeeritud ortograafia',
 			'VALENCIA' => 'valentsia',
 			'WADEGILE' => 'Wade’i-Gilesi latinisatsioon',

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
 			'cf' => 'rahavorming',
 			'colalternate' => 'sümbolite eiramine järjestuses',
 			'colbackwards' => 'diakriitikute pöördjärjestus',
 			'colcasefirst' => 'suur- ja väiketähe järjestus',
 			'colcaselevel' => 'järjestuse tõstutundlikkus',
 			'collation' => 'järjestus',
 			'colnormalization' => 'normaliseeritud järjestus',
 			'colnumeric' => 'numbrite järjestus',
 			'colstrength' => 'järjestuskaalud',
 			'currency' => 'vääring',
 			'hc' => '12 või 24 tunni süsteem',
 			'lb' => 'reavahetuse laad',
 			'ms' => 'mõõdustik',
 			'numbers' => 'numbrid',
 			'timezone' => 'ajavöönd',
 			'va' => 'lokaadi variant',
 			'x' => 'erakasutus',

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
 				'buddhist' => q{budistlik kalender},
 				'chinese' => q{Hiina kalender},
 				'coptic' => q{kopti kalender},
 				'dangi' => q{dangi kalender},
 				'ethiopic' => q{Etioopia kalender},
 				'ethiopic-amete-alem' => q{Etioopia amete alemi kalender},
 				'gregorian' => q{Gregoriuse kalender},
 				'hebrew' => q{juudi kalender},
 				'indian' => q{India rahvuslik kalender},
 				'islamic' => q{hidžra kalender},
 				'islamic-civil' => q{hidžra kalender (tabelkalender, ilmalik)},
 				'islamic-rgsa' => q{hidžra kalender (Saudi Araabia, vaatluspõhine)},
 				'islamic-tbla' => q{hidžra kalender (tabelkalender, astronoomiline ajastu)},
 				'islamic-umalqura' => q{hidžra kalender (Umm al-Qurá)},
 				'iso8601' => q{ISO-8601 kalender},
 				'japanese' => q{Jaapani kalender},
 				'persian' => q{Pärsia kalender},
 				'roc' => q{Hiina Vabariigi kalender},
 			},
 			'cf' => {
 				'account' => q{arvelduse rahavorming},
 				'standard' => q{standardne rahavorming},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{järjesta sümbolid},
 				'shifted' => q{eira järjestuses sümboleid},
 			},
 			'colbackwards' => {
 				'no' => q{diakriitikud tavajärjestuses},
 				'yes' => q{diakriitikud pöördjärjestuses},
 			},
 			'colcasefirst' => {
 				'lower' => q{väiketäht järjestuses eespool},
 				'no' => q{harilik järjestus},
 				'upper' => q{suurtäht järjestuses eespool},
 			},
 			'colcaselevel' => {
 				'no' => q{tõstutundetu järjestus},
 				'yes' => q{tõstutundlik järjestus},
 			},
 			'collation' => {
 				'big5han' => q{hiina traditsiooniline sortimisjärjestus (Big5)},
 				'compat' => q{varasem sortimisjärjestus (ühilduvuse jaoks)},
 				'dictionary' => q{sõnastiku sortimisjärjestus},
 				'ducet' => q{Unicode’i vaikejärjestus},
 				'emoji' => q{emoji sortimisjärjestus},
 				'eor' => q{Euroopa järjestusreeglid},
 				'gb2312han' => q{hiina lihtsustatud sortimisjärjestus (GB2312)},
 				'phonebook' => q{telefoniraamatu sortimisjärjestus},
 				'phonetic' => q{foneetiline sortimisjärjestus},
 				'pinyin' => q{pinyin’i sortimisjärjestus},
 				'reformed' => q{reformitud sortimisjärjestus},
 				'search' => q{üldeesmärgiline otsing},
 				'searchjl' => q{otsing korea alguskonsonandi järgi},
 				'standard' => q{standardne järjestus},
 				'stroke' => q{kriipsude sortimisjärjestus},
 				'traditional' => q{traditsiooniline sortimisjärjestus},
 				'unihan' => q{võtmete-kriipsude sortimisjärjestus},
 				'zhuyin' => q{zhuyin’i sortimisjärjestus},
 			},
 			'colnormalization' => {
 				'no' => q{järjesta normaliseerimata},
 				'yes' => q{järjesta Unicode’i normaliseerimisega},
 			},
 			'colnumeric' => {
 				'no' => q{järjesta numbrid eraldi},
 				'yes' => q{järjesta numbrid arvuliselt},
 			},
 			'colstrength' => {
 				'identical' => q{järjesta kõik},
 				'primary' => q{järjesta ainult alustähed},
 				'quaternary' => q{järjesta diakriitikud, algustähed, laius ja kana kiri},
 				'secondary' => q{järjesta diakriitikud},
 				'tertiary' => q{järjesta diakriitikud, algustähed ja laius},
 			},
 			'd0' => {
 				'fwidth' => q{täislaius},
 				'hwidth' => q{poollaius},
 				'npinyin' => q{Numbriline},
 			},
 			'hc' => {
 				'h11' => q{12-tunnine süsteem (0–11)},
 				'h12' => q{12-tunnine süsteem (1–12)},
 				'h23' => q{24-tunnine süsteem (0–23)},
 				'h24' => q{24-tunnine süsteem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{paindlik reavahetuse laad},
 				'normal' => q{harilik reavahetuse laad},
 				'strict' => q{jäik reavahetuse laad},
 			},
 			'm0' => {
 				'bgn' => q{transkriptsioon (BGN)},
 				'ungegn' => q{transkriptsioon (UNGEGN)},
 			},
 			'ms' => {
 				'metric' => q{meetermõõdustik},
 				'uksystem' => q{inglise mõõdustik},
 				'ussystem' => q{USA mõõdustik},
 			},
 			'numbers' => {
 				'ahom' => q{ahomi numbrid},
 				'arab' => q{idaaraabia numbrid},
 				'arabext' => q{laiendatud idaaraabia numbrid},
 				'armn' => q{armeenia numbrid},
 				'armnlow' => q{väiketähelised armeenia numbrid},
 				'bali' => q{bali numbrid},
 				'beng' => q{bengali numbrid},
 				'brah' => q{braahmi numbrid},
 				'cakm' => q{tšaakma numbrid},
 				'cham' => q{tšaami numbrid},
 				'cyrl' => q{kirillitsa numbrid},
 				'deva' => q{devanaagari numbrid},
 				'diak' => q{divehi numbrid},
 				'ethi' => q{etioopia numbrid},
 				'finance' => q{finantsnumbrid},
 				'fullwide' => q{täislaiusega numbrid},
 				'geor' => q{gruusia numbrid},
 				'gong' => q{Gūnjāla gondi numbrid},
 				'gonm' => q{Masarami gondi numbrid},
 				'grek' => q{kreeka numbrid},
 				'greklow' => q{väiketähelised kreeka numbrid},
 				'gujr' => q{gudžarati numbrid},
 				'guru' => q{gurmukhi numbrid},
 				'hanidec' => q{hiina kümnendnumbrid},
 				'hans' => q{lihtsustatud hiina keele numbrid},
 				'hansfin' => q{lihtsustatud hiina keele finantsnumbrid},
 				'hant' => q{traditsioonilise hiina keele numbrid},
 				'hantfin' => q{traditsioonilise hiina keele finantsnumbrid},
 				'hebr' => q{heebrea numbrid},
 				'hmng' => q{phahau-hmongi numbrid},
 				'java' => q{jaava numbrid},
 				'jpan' => q{jaapani numbrid},
 				'jpanfin' => q{jaapani finantsnumbrid},
 				'kali' => q{kaja-lii numbrid},
 				'kawi' => q{kaavi numbrid},
 				'khmr' => q{khmeeri numbrid},
 				'knda' => q{kannada numbrid},
 				'lana' => q{tai tham hora numbrid},
 				'lanatham' => q{tai tham tham numbrid},
 				'laoo' => q{lao numbrid},
 				'latn' => q{araabia numbrid},
 				'lepc' => q{leptša numbrid},
 				'limb' => q{limbu numbrid},
 				'mlym' => q{malajalami numbrid},
 				'modi' => q{modi numbrid},
 				'mong' => q{mongoli numbrid},
 				'mroo' => q{mruu numbrid},
 				'mtei' => q{meitei numbrid},
 				'mymr' => q{birma numbrid},
 				'mymrshan' => q{myanmari shan numbrid},
 				'mymrtlng' => q{myanmari tai laing numbrid},
 				'nagm' => q{Nagi mundari numbrid},
 				'native' => q{kohalikud numbrid},
 				'nkoo' => q{nkoo numbrid},
 				'olck' => q{santali numbrid},
 				'orya' => q{oria numbrid},
 				'osma' => q{osmani numbrid},
 				'rohg' => q{rohingja numbrid},
 				'roman' => q{Rooma numbrid},
 				'romanlow' => q{väiketähelised Rooma numbrid},
 				'saur' => q{sauraštra numbrid},
 				'shrd' => q{šaarada numbrid},
 				'sind' => q{hudavadi numbrid},
 				'sinh' => q{sinhala lithi numbrid},
 				'sora' => q{sora numbrid},
 				'sund' => q{sunda numbrid},
 				'takr' => q{taakri numbrid},
 				'talu' => q{uue tai-lõõ numbrid},
 				'taml' => q{traditsioonilised tamili numbrid},
 				'tamldec' => q{tamili numbrid},
 				'telu' => q{telugu numbrid},
 				'thai' => q{tai numbrid},
 				'tibt' => q{tiibeti numbrid},
 				'tirh' => q{tirhuta numbrid},
 				'tnsa' => q{tase numbrid},
 				'traditional' => q{traditsioonilised numbrid},
 				'vaii' => q{vai numbrid},
 				'wara' => q{hoo numbrid},
 				'wcho' => q{vantšo numbrid},
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
			'metric' => q{meetermõõdustik},
 			'UK' => q{inglise mõõdustik},
 			'US' => q{USA mõõdustik},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Keel: {0}',
 			'script' => 'Kiri: {0}',
 			'region' => 'Piirkond: {0}',

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
			auxiliary => qr{[áàâåãā æ ç éèêëē íìîïī ñ óòŏôøō œ úùûū]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Z', 'Ž', 'T', 'U', 'V', 'W', 'Õ', 'Ä', 'Ö', 'Ü', 'X', 'Y'],
			main => qr{[a b c d e f g h i j k l m n o p q r s š z ž t u v w õ ä ö ü x y]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ – , ; \: ! ? . “„ ( ) \[ \] \{ \} @]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Z', 'Ž', 'T', 'U', 'V', 'W', 'Õ', 'Ä', 'Ö', 'Ü', 'X', 'Y'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'medial' => '{0} … {1}',
		};
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(põhiilmakaar),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(põhiilmakaar),
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
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
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
						'1' => q(jobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(detsi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(detsi{0}),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
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
						'1' => q(jokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(jokto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kvekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvekto{0}),
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
						'1' => q(jota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
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
					'10p30' => {
						'1' => q(kveta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kveta{0}),
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
						'one' => q({0} Maa raskuskiirendus),
						'other' => q({0} Maa raskuskiirendust),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} Maa raskuskiirendus),
						'other' => q({0} Maa raskuskiirendust),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meetrid sekundi ruudu kohta),
						'one' => q({0} meeter sekundi ruudu kohta),
						'other' => q({0} meetrit sekundi ruudu kohta),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meetrid sekundi ruudu kohta),
						'one' => q({0} meeter sekundi ruudu kohta),
						'other' => q({0} meetrit sekundi ruudu kohta),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(kaareminutid),
						'one' => q({0} kaareminut),
						'other' => q({0} kaareminutit),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(kaareminutid),
						'one' => q({0} kaareminut),
						'other' => q({0} kaareminutit),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(kaaresekundid),
						'one' => q({0} kaaresekund),
						'other' => q({0} kaaresekundit),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(kaaresekundid),
						'one' => q({0} kaaresekund),
						'other' => q({0} kaaresekundit),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} kraad),
						'other' => q({0} kraadi),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} kraad),
						'other' => q({0} kraadi),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radiaan),
						'other' => q({0} radiaani),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radiaan),
						'other' => q({0} radiaani),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(täispööre),
						'one' => q({0} täispööre),
						'other' => q({0} täispööret),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(täispööre),
						'one' => q({0} täispööre),
						'other' => q({0} täispööret),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hektar),
						'other' => q({0} hektarit),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hektar),
						'other' => q({0} hektarit),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ruutsentimeetrid),
						'one' => q({0} ruutsentimeeter),
						'other' => q({0} ruutsentimeetrit),
						'per' => q({0} ruutsentimeetri kohta),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ruutsentimeetrid),
						'one' => q({0} ruutsentimeeter),
						'other' => q({0} ruutsentimeetrit),
						'per' => q({0} ruutsentimeetri kohta),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ruutjalg),
						'other' => q({0} ruutjalga),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ruutjalg),
						'other' => q({0} ruutjalga),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0} ruuttoll),
						'other' => q({0} ruuttolli),
						'per' => q({0} ruuttolli kohta),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0} ruuttoll),
						'other' => q({0} ruuttolli),
						'per' => q({0} ruuttolli kohta),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ruutkilomeetrid),
						'one' => q({0} ruutkilomeeter),
						'other' => q({0} ruutkilomeetrit),
						'per' => q({0} ruutkilomeetri kohta),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ruutkilomeetrid),
						'one' => q({0} ruutkilomeeter),
						'other' => q({0} ruutkilomeetrit),
						'per' => q({0} ruutkilomeetri kohta),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ruutmeetrid),
						'one' => q({0} ruutmeeter),
						'other' => q({0} ruutmeetrit),
						'per' => q({0} ruutmeetri kohta),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ruutmeetrid),
						'one' => q({0} ruutmeeter),
						'other' => q({0} ruutmeetrit),
						'per' => q({0} ruutmeetri kohta),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ruutmiilid),
						'one' => q({0} ruutmiil),
						'other' => q({0} ruutmiili),
						'per' => q({0} ruutmiili kohta),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ruutmiilid),
						'one' => q({0} ruutmiil),
						'other' => q({0} ruutmiili),
						'per' => q({0} ruutmiili kohta),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0} ruutjard),
						'other' => q({0} ruutjardi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0} ruutjard),
						'other' => q({0} ruutjardi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammid detsiliitri kohta),
						'one' => q({0} milligramm detsiliitri kohta),
						'other' => q({0} milligrammi detsiliitri kohta),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammid detsiliitri kohta),
						'one' => q({0} milligramm detsiliitri kohta),
						'other' => q({0} milligrammi detsiliitri kohta),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoolid liitri kohta),
						'one' => q({0} millimool liitri kohta),
						'other' => q({0} millimooli liitri kohta),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoolid liitri kohta),
						'one' => q({0} millimool liitri kohta),
						'other' => q({0} millimooli liitri kohta),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moolid),
						'one' => q({0} mool),
						'other' => q({0} mooli),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moolid),
						'one' => q({0} mool),
						'other' => q({0} mooli),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(protsent),
						'one' => q({0} protsent),
						'other' => q({0} protsenti),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(protsent),
						'one' => q({0} protsent),
						'other' => q({0} protsenti),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promill),
						'one' => q({0} promill),
						'other' => q({0} promilli),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promill),
						'one' => q({0} promill),
						'other' => q({0} promilli),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(osa miljoni kohta),
						'one' => q({0} osa miljoni kohta),
						'other' => q({0} osa miljoni kohta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(osa miljoni kohta),
						'one' => q({0} osa miljoni kohta),
						'other' => q({0} osa miljoni kohta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} promüriaad),
						'other' => q({0} promüriaadi),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} promüriaad),
						'other' => q({0} promüriaadi),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liitrid 100 kilomeetri kohta),
						'one' => q({0} liiter 100 kilomeetri kohta),
						'other' => q({0} liitrit 100 kilomeetri kohta),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liitrid 100 kilomeetri kohta),
						'one' => q({0} liiter 100 kilomeetri kohta),
						'other' => q({0} liitrit 100 kilomeetri kohta),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liitrid kilomeetri kohta),
						'one' => q({0} liiter kilomeetri kohta),
						'other' => q({0} liitrit kilomeetri kohta),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liitrid kilomeetri kohta),
						'one' => q({0} liiter kilomeetri kohta),
						'other' => q({0} liitrit kilomeetri kohta),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miilid galloni kohta),
						'one' => q({0} miil galloni kohta),
						'other' => q({0} miili galloni kohta),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miilid galloni kohta),
						'one' => q({0} miil galloni kohta),
						'other' => q({0} miili galloni kohta),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miilid inglise galloni kohta),
						'one' => q({0} miil inglise galloni kohta),
						'other' => q({0} miili inglise galloni kohta),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miilid inglise galloni kohta),
						'one' => q({0} miil inglise galloni kohta),
						'other' => q({0} miili inglise galloni kohta),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} idapikkust),
						'north' => q({0} põhjalaiust),
						'south' => q({0} lõunalaiust),
						'west' => q({0} läänepikkust),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} idapikkust),
						'north' => q({0} põhjalaiust),
						'south' => q({0} lõunalaiust),
						'west' => q({0} läänepikkust),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bitid),
						'one' => q({0} bitt),
						'other' => q({0} bitti),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bitid),
						'one' => q({0} bitt),
						'other' => q({0} bitti),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(baidid),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(baidid),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabitid),
						'one' => q({0} gigabitt),
						'other' => q({0} gigabitti),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabitid),
						'one' => q({0} gigabitt),
						'other' => q({0} gigabitti),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabaidid),
						'one' => q({0} gigabait),
						'other' => q({0} gigabaiti),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabaidid),
						'one' => q({0} gigabait),
						'other' => q({0} gigabaiti),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobitid),
						'one' => q({0} kilobitt),
						'other' => q({0} kilobitti),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobitid),
						'one' => q({0} kilobitt),
						'other' => q({0} kilobitti),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobaidid),
						'one' => q({0} kilobait),
						'other' => q({0} kilobaiti),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobaidid),
						'one' => q({0} kilobait),
						'other' => q({0} kilobaiti),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabitid),
						'one' => q({0} megabitt),
						'other' => q({0} megabitti),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabitid),
						'one' => q({0} megabitt),
						'other' => q({0} megabitti),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabaidid),
						'one' => q({0} megabait),
						'other' => q({0} megabaiti),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabaidid),
						'one' => q({0} megabait),
						'other' => q({0} megabaiti),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabaidid),
						'one' => q({0} petabait),
						'other' => q({0} petabaiti),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabaidid),
						'one' => q({0} petabait),
						'other' => q({0} petabaiti),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabitid),
						'one' => q({0} terabitt),
						'other' => q({0} terabitti),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabitid),
						'one' => q({0} terabitt),
						'other' => q({0} terabitti),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabaidid),
						'one' => q({0} terabait),
						'other' => q({0} terabaiti),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabaidid),
						'one' => q({0} terabait),
						'other' => q({0} terabaiti),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sajandid),
						'one' => q({0} sajand),
						'other' => q({0} sajandit),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sajandid),
						'one' => q({0} sajand),
						'other' => q({0} sajandit),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ööpäevad),
						'one' => q({0} ööpäev),
						'other' => q({0} ööpäeva),
						'per' => q({0} ööpäevas),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ööpäevad),
						'one' => q({0} ööpäev),
						'other' => q({0} ööpäeva),
						'per' => q({0} ööpäevas),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekaadid),
						'one' => q({0} dekaad),
						'other' => q({0} dekaadi),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekaadid),
						'one' => q({0} dekaad),
						'other' => q({0} dekaadi),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(tunnid),
						'one' => q({0} tund),
						'other' => q({0} tundi),
						'per' => q({0} tunnis),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(tunnid),
						'one' => q({0} tund),
						'other' => q({0} tundi),
						'per' => q({0} tunnis),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekundid),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundit),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekundid),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundit),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekundid),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundit),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekundid),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundit),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutid),
						'one' => q({0} minut),
						'other' => q({0} minutit),
						'per' => q({0} minutis),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutid),
						'one' => q({0} minut),
						'other' => q({0} minutit),
						'per' => q({0} minutis),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} kuus),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} kuus),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekundid),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundit),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekundid),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundit),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kvartalid),
						'one' => q({0} kvartal),
						'other' => q({0} kvartalit),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kvartalid),
						'one' => q({0} kvartal),
						'other' => q({0} kvartalit),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundid),
						'one' => q({0} sekund),
						'other' => q({0} sekundit),
						'per' => q({0} sekundis),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundid),
						'one' => q({0} sekund),
						'other' => q({0} sekundit),
						'per' => q({0} sekundis),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(nädalad),
						'one' => q({0} nädal),
						'other' => q({0} nädalat),
						'per' => q({0} nädalas),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(nädalad),
						'one' => q({0} nädal),
						'other' => q({0} nädalat),
						'per' => q({0} nädalas),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} aasta),
						'other' => q({0} aastat),
						'per' => q({0} aastas),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} aasta),
						'other' => q({0} aastat),
						'per' => q({0} aastas),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amprit),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amprit),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} milliamper),
						'other' => q({0} milliamprit),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} milliamper),
						'other' => q({0} milliamprit),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} oom),
						'other' => q({0} oomi),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} oom),
						'other' => q({0} oomi),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Briti soojusühikud),
						'one' => q({0} Briti soojusühik),
						'other' => q({0} Briti soojusühikut),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Briti soojusühikud),
						'one' => q({0} Briti soojusühik),
						'other' => q({0} Briti soojusühikut),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalorid),
						'one' => q({0} kalor),
						'other' => q({0} kalorit),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalorid),
						'one' => q({0} kalor),
						'other' => q({0} kalorit),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvoldid),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolti),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvoldid),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolti),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kalorid),
						'one' => q({0} kalor),
						'other' => q({0} kalorit),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kalorid),
						'one' => q({0} kalor),
						'other' => q({0} kalorit),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} džaul),
						'other' => q({0} džauli),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} džaul),
						'other' => q({0} džauli),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalorid),
						'one' => q({0} kilokalor),
						'other' => q({0} kilokalorit),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalorid),
						'one' => q({0} kilokalor),
						'other' => q({0} kilokalorit),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilodžaulid),
						'one' => q({0} kilodžaul),
						'other' => q({0} kilodžauli),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilodžaulid),
						'one' => q({0} kilodžaul),
						'other' => q({0} kilodžauli),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatt-tunnid),
						'one' => q({0} kilovatt-tund),
						'other' => q({0} kilovatt-tundi),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatt-tunnid),
						'one' => q({0} kilovatt-tund),
						'other' => q({0} kilovatt-tundi),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(USA termid),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(USA termid),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovatt-tunnid 100 kilomeetri kohta),
						'one' => q({0} kilovatt-tund 100 kilomeetri kohta),
						'other' => q({0} kilovatt-tundi 100 kilomeetri kohta),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovatt-tunnid 100 kilomeetri kohta),
						'one' => q({0} kilovatt-tund 100 kilomeetri kohta),
						'other' => q({0} kilovatt-tundi 100 kilomeetri kohta),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(njuutonid),
						'one' => q({0} njuuton),
						'other' => q({0} njuutonit),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(njuutonid),
						'one' => q({0} njuuton),
						'other' => q({0} njuutonit),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(jõunaelad),
						'one' => q({0} jõunael),
						'other' => q({0} jõunaela),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(jõunaelad),
						'one' => q({0} jõunael),
						'other' => q({0} jõunaela),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertsid),
						'one' => q({0} gigaherts),
						'other' => q({0} gigahertsi),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertsid),
						'one' => q({0} gigaherts),
						'other' => q({0} gigahertsi),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertsid),
						'one' => q({0} herts),
						'other' => q({0} hertsi),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertsid),
						'one' => q({0} herts),
						'other' => q({0} hertsi),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertsid),
						'one' => q({0} kiloherts),
						'other' => q({0} kilohertsi),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertsid),
						'one' => q({0} kiloherts),
						'other' => q({0} kilohertsi),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertsid),
						'one' => q({0} megaherts),
						'other' => q({0} megahertsi),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertsid),
						'one' => q({0} megaherts),
						'other' => q({0} megahertsi),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punktid),
						'one' => q({0} punkt),
						'other' => q({0} punkti),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punktid),
						'one' => q({0} punkt),
						'other' => q({0} punkti),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punkte sentimeetri kohta),
						'one' => q({0} punkt sentimeetri kohta),
						'other' => q({0} punkti sentimeetri kohta),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punkte sentimeetri kohta),
						'one' => q({0} punkt sentimeetri kohta),
						'other' => q({0} punkti sentimeetri kohta),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punkte tolli kohta),
						'one' => q({0} punkt tolli kohta),
						'other' => q({0} punkti tolli kohta),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkte tolli kohta),
						'one' => q({0} punkt tolli kohta),
						'other' => q({0} punkti tolli kohta),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tüpograafiline emm),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tüpograafiline emm),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslit),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslit),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} pikslit),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} pikslit),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksleid sentimeetri kohta),
						'one' => q({0} piksel sentimeetri kohta),
						'other' => q({0} pikslit sentimeetri kohta),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksleid sentimeetri kohta),
						'one' => q({0} piksel sentimeetri kohta),
						'other' => q({0} pikslit sentimeetri kohta),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksleid tolli kohta),
						'one' => q({0} piksel tolli kohta),
						'other' => q({0} pikslit tolli kohta),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksleid tolli kohta),
						'one' => q({0} piksel tolli kohta),
						'other' => q({0} pikslit tolli kohta),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronoomilised ühikud),
						'one' => q({0} astronoomiline ühik),
						'other' => q({0} astronoomilist ühikut),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronoomilised ühikud),
						'one' => q({0} astronoomiline ühik),
						'other' => q({0} astronoomilist ühikut),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeetrid),
						'one' => q({0} sentimeeter),
						'other' => q({0} sentimeetrit),
						'per' => q({0} sentimeetri kohta),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeetrid),
						'one' => q({0} sentimeeter),
						'other' => q({0} sentimeetrit),
						'per' => q({0} sentimeetri kohta),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(detsimeetrid),
						'one' => q({0} detsimeeter),
						'other' => q({0} detsimeetrit),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(detsimeetrid),
						'one' => q({0} detsimeeter),
						'other' => q({0} detsimeetrit),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Maa raadius),
						'one' => q({0} Maa raadius),
						'other' => q({0} Maa raadiust),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Maa raadius),
						'one' => q({0} Maa raadius),
						'other' => q({0} Maa raadiust),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} süld),
						'other' => q({0} sülda),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} süld),
						'other' => q({0} sülda),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(jalad),
						'one' => q({0} jalg),
						'other' => q({0} jalga),
						'per' => q({0} jala kohta),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(jalad),
						'one' => q({0} jalg),
						'other' => q({0} jalga),
						'per' => q({0} jala kohta),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongi),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} toll),
						'other' => q({0} tolli),
						'per' => q({0} tolli kohta),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} toll),
						'other' => q({0} tolli),
						'per' => q({0} tolli kohta),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomeetrid),
						'one' => q({0} kilomeeter),
						'other' => q({0} kilomeetrit),
						'per' => q({0} kilomeetri kohta),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomeetrid),
						'one' => q({0} kilomeeter),
						'other' => q({0} kilomeetrit),
						'per' => q({0} kilomeetri kohta),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} valgusaasta),
						'other' => q({0} valgusaastat),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} valgusaasta),
						'other' => q({0} valgusaastat),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meetrid),
						'one' => q({0} meeter),
						'other' => q({0} meetrit),
						'per' => q({0} meetri kohta),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meetrid),
						'one' => q({0} meeter),
						'other' => q({0} meetrit),
						'per' => q({0} meetri kohta),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromeetrid),
						'one' => q({0} mikromeeter),
						'other' => q({0} mikromeetrit),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromeetrid),
						'one' => q({0} mikromeeter),
						'other' => q({0} mikromeetrit),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(miilid),
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miilid),
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Skandinaavia miilid),
						'one' => q({0} Skandinaavia miil),
						'other' => q({0} Skandinaavia miili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Skandinaavia miilid),
						'one' => q({0} Skandinaavia miil),
						'other' => q({0} Skandinaavia miili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeetrid),
						'one' => q({0} millimeeter),
						'other' => q({0} millimeetrit),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeetrid),
						'one' => q({0} millimeeter),
						'other' => q({0} millimeetrit),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomeetrid),
						'one' => q({0} nanomeeter),
						'other' => q({0} nanomeetrit),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomeetrid),
						'one' => q({0} nanomeeter),
						'other' => q({0} nanomeetrit),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(meremiilid),
						'one' => q({0} meremiil),
						'other' => q({0} meremiili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(meremiilid),
						'one' => q({0} meremiil),
						'other' => q({0} meremiili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsekit),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsekit),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomeetrid),
						'one' => q({0} pikomeeter),
						'other' => q({0} pikomeetrit),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomeetrid),
						'one' => q({0} pikomeeter),
						'other' => q({0} pikomeetrit),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} tüpograafiline punkt),
						'other' => q({0} tüpograafilist punkti),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} tüpograafiline punkt),
						'other' => q({0} tüpograafilist punkti),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} Päikese raadiust),
						'other' => q({0} Päikese raadiust),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} Päikese raadiust),
						'other' => q({0} Päikese raadiust),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandelat),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandelat),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(luumen),
						'one' => q({0} luumen),
						'other' => q({0} luumenit),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(luumen),
						'one' => q({0} luumen),
						'other' => q({0} luumenit),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksi),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksi),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} Päikese heledus),
						'other' => q({0} Päikese heledust),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} Päikese heledus),
						'other' => q({0} Päikese heledust),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} daltonit),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} daltonit),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} Maa massi),
						'other' => q({0} Maa massi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Maa massi),
						'other' => q({0} Maa massi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gramm),
						'other' => q({0} grammi),
						'per' => q({0} grammi kohta),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gramm),
						'other' => q({0} grammi),
						'per' => q({0} grammi kohta),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogrammid),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogrammi),
						'per' => q({0} kilogrammi kohta),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogrammid),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogrammi),
						'per' => q({0} kilogrammi kohta),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogrammid),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogrammi),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogrammid),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogrammi),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrammid),
						'one' => q({0} milligramm),
						'other' => q({0} milligrammi),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrammid),
						'one' => q({0} milligramm),
						'other' => q({0} milligrammi),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(untsid),
						'one' => q({0} unts),
						'other' => q({0} untsi),
						'per' => q({0} untsi kohta),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(untsid),
						'one' => q({0} unts),
						'other' => q({0} untsi),
						'per' => q({0} untsi kohta),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troiuntsid),
						'one' => q({0} troiunts),
						'other' => q({0} troiuntsi),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troiuntsid),
						'one' => q({0} troiunts),
						'other' => q({0} troiuntsi),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} nael),
						'other' => q({0} naela),
						'per' => q({0} naela kohta),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} nael),
						'other' => q({0} naela),
						'per' => q({0} naela kohta),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} Päikese massi),
						'other' => q({0} Päikese massi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} Päikese massi),
						'other' => q({0} Päikese massi),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} kivi),
						'other' => q({0} kivi),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} kivi),
						'other' => q({0} kivi),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(lühikesed tonnid),
						'one' => q({0} lühike tonn),
						'other' => q({0} lühikest tonni),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(lühikesed tonnid),
						'one' => q({0} lühike tonn),
						'other' => q({0} lühikest tonni),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnid),
						'one' => q({0} tonn),
						'other' => q({0} tonni),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnid),
						'one' => q({0} tonn),
						'other' => q({0} tonni),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} {1} kohta),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} {1} kohta),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigavatid),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatti),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigavatid),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatti),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hobujõud),
						'one' => q({0} hobujõud),
						'other' => q({0} hobujõudu),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hobujõud),
						'one' => q({0} hobujõud),
						'other' => q({0} hobujõudu),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilovatid),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatti),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilovatid),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatti),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megavatid),
						'one' => q({0} megavatt),
						'other' => q({0} megavatti),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megavatid),
						'one' => q({0} megavatt),
						'other' => q({0} megavatti),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(millivatid),
						'one' => q({0} millivatt),
						'other' => q({0} millivatti),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(millivatid),
						'one' => q({0} millivatt),
						'other' => q({0} millivatti),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} vatt),
						'other' => q({0} vatti),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} vatt),
						'other' => q({0} vatti),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(ruut{0}),
						'one' => q(ruut{0}),
						'other' => q(ruut{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(ruut{0}),
						'one' => q(ruut{0}),
						'other' => q(ruut{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kuup{0}),
						'one' => q(kuup{0}),
						'other' => q(kuup{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kuup{0}),
						'one' => q(kuup{0}),
						'other' => q(kuup{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfäärid),
						'one' => q({0} atmosfäär),
						'other' => q({0} atmosfääri),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfäärid),
						'one' => q({0} atmosfäär),
						'other' => q({0} atmosfääri),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baarid),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baarid),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskalid),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalit),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskalid),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalit),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tollid elavhõbedasammast),
						'one' => q({0} toll elavhõbedasammast),
						'other' => q({0} tolli elavhõbedasammast),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tollid elavhõbedasammast),
						'one' => q({0} toll elavhõbedasammast),
						'other' => q({0} tolli elavhõbedasammast),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskalid),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskalit),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskalid),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskalit),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskalid),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskalit),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskalid),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskalit),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibaarid),
						'one' => q({0} millibaar),
						'other' => q({0} millibaari),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibaarid),
						'one' => q({0} millibaar),
						'other' => q({0} millibaari),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimeetrid elavhõbedasammast),
						'one' => q({0} millimeeter elavhõbedasammast),
						'other' => q({0} millimeetrit elavhõbedasammast),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimeetrid elavhõbedasammast),
						'one' => q({0} millimeeter elavhõbedasammast),
						'other' => q({0} millimeetrit elavhõbedasammast),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskalid),
						'one' => q({0} paskal),
						'other' => q({0} paskalit),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskalid),
						'one' => q({0} paskal),
						'other' => q({0} paskalit),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(naelad ruuttolli kohta),
						'one' => q({0} nael ruuttolli kohta),
						'other' => q({0} naela ruuttolli kohta),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(naelad ruuttolli kohta),
						'one' => q({0} nael ruuttolli kohta),
						'other' => q({0} naela ruuttolli kohta),
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
						'name' => q(kilomeetrid tunnis),
						'one' => q({0} kilomeeter tunnis),
						'other' => q({0} kilomeetrit tunnis),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomeetrid tunnis),
						'one' => q({0} kilomeeter tunnis),
						'other' => q({0} kilomeetrit tunnis),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(sõlm),
						'one' => q({0} sõlm),
						'other' => q({0} sõlme),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(sõlm),
						'one' => q({0} sõlm),
						'other' => q({0} sõlme),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meetrid sekundis),
						'one' => q({0} meeter sekundis),
						'other' => q({0} meetrit sekundis),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meetrid sekundis),
						'one' => q({0} meeter sekundis),
						'other' => q({0} meetrit sekundis),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(miilid tunnis),
						'one' => q({0} miil tunnis),
						'other' => q({0} miili tunnis),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(miilid tunnis),
						'one' => q({0} miil tunnis),
						'other' => q({0} miili tunnis),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Celsiuse kraadid),
						'one' => q({0} Celsiuse kraad),
						'other' => q({0} Celsiuse kraadi),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Celsiuse kraadid),
						'one' => q({0} Celsiuse kraad),
						'other' => q({0} Celsiuse kraadi),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Fahrenheiti kraadid),
						'one' => q({0} Fahrenheiti kraad),
						'other' => q({0} Fahrenheiti kraadi),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Fahrenheiti kraadid),
						'one' => q({0} Fahrenheiti kraad),
						'other' => q({0} Fahrenheiti kraadi),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} kraad),
						'other' => q({0} kraadi),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} kraad),
						'other' => q({0} kraadi),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvinid),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinit),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvinid),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinit),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(njuutonmeetrid),
						'one' => q({0} njuutonmeeter),
						'other' => q({0} njuutonmeetrit),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(njuutonmeetrid),
						'one' => q({0} njuutonmeeter),
						'other' => q({0} njuutonmeetrit),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(naeljalad),
						'one' => q({0} naeljalg),
						'other' => q({0} naeljalga),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(naeljalad),
						'one' => q({0} naeljalg),
						'other' => q({0} naeljalga),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(aakerjalad),
						'one' => q({0} aakerjalg),
						'other' => q({0} aakerjalga),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(aakerjalad),
						'one' => q({0} aakerjalg),
						'other' => q({0} aakerjalga),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrelid),
						'one' => q({0} barrel),
						'other' => q({0} barrelit),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrelid),
						'one' => q({0} barrel),
						'other' => q({0} barrelit),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} buššel),
						'other' => q({0} buššelit),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} buššel),
						'other' => q({0} buššelit),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliitrid),
						'one' => q({0} sentiliiter),
						'other' => q({0} sentiliitrit),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliitrid),
						'one' => q({0} sentiliiter),
						'other' => q({0} sentiliitrit),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kuupsentimeetrid),
						'one' => q({0} kuupsentimeeter),
						'other' => q({0} kuupsentimeetrit),
						'per' => q({0} kuupsentimeetri kohta),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kuupsentimeetrid),
						'one' => q({0} kuupsentimeeter),
						'other' => q({0} kuupsentimeetrit),
						'per' => q({0} kuupsentimeetri kohta),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kuupjalad),
						'one' => q({0} kuupjalg),
						'other' => q({0} kuupjalga),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kuupjalad),
						'one' => q({0} kuupjalg),
						'other' => q({0} kuupjalga),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0} kuuptoll),
						'other' => q({0} kuuptolli),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0} kuuptoll),
						'other' => q({0} kuuptolli),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kuupkilomeetrid),
						'one' => q({0} kuupkilomeeter),
						'other' => q({0} kuupkilomeetrit),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kuupkilomeetrid),
						'one' => q({0} kuupkilomeeter),
						'other' => q({0} kuupkilomeetrit),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kuupmeetrid),
						'one' => q({0} kuupmeeter),
						'other' => q({0} kuupmeetrit),
						'per' => q({0} kuupmeetri kohta),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kuupmeetrid),
						'one' => q({0} kuupmeeter),
						'other' => q({0} kuupmeetrit),
						'per' => q({0} kuupmeetri kohta),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} kuupmiil),
						'other' => q({0} kuupmiili),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} kuupmiil),
						'other' => q({0} kuupmiili),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0} kuupjard),
						'other' => q({0} kuupjardi),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0} kuupjard),
						'other' => q({0} kuupjardi),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tassid),
						'one' => q({0} tass),
						'other' => q({0} tassi),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tassid),
						'one' => q({0} tass),
						'other' => q({0} tassi),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(meetrilised tassid),
						'one' => q({0} meetriline tass),
						'other' => q({0} meetrilist tassi),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(meetrilised tassid),
						'one' => q({0} meetriline tass),
						'other' => q({0} meetrilist tassi),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(detsiliitrid),
						'one' => q({0} detsiliiter),
						'other' => q({0} detsiliitrit),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(detsiliitrid),
						'one' => q({0} detsiliiter),
						'other' => q({0} detsiliitrit),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessertlusikas),
						'one' => q({0} dessertlusikas),
						'other' => q({0} dessertlusikat),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessertlusikas),
						'one' => q({0} dessertlusikas),
						'other' => q({0} dessertlusikat),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(inglise dessertlusikas),
						'one' => q({0} inglise dessertlusikas),
						'other' => q({0} inglise dessertlusikat),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(inglise dessertlusikas),
						'one' => q({0} inglise dessertlusikas),
						'other' => q({0} inglise dessertlusikat),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drahm),
						'one' => q({0} drahm),
						'other' => q({0} drahmi),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drahm),
						'one' => q({0} drahm),
						'other' => q({0} drahmi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(vedelikuuntsid),
						'one' => q({0} vedelikuunts),
						'other' => q({0} vedelikuuntsi),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(vedelikuuntsid),
						'one' => q({0} vedelikuunts),
						'other' => q({0} vedelikuuntsi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(inglise vedelikuuntsid),
						'one' => q({0} inglise vedelikuuntsi),
						'other' => q({0} inglise vedelikuuntsi),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(inglise vedelikuuntsid),
						'one' => q({0} inglise vedelikuuntsi),
						'other' => q({0} inglise vedelikuuntsi),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallonid),
						'one' => q({0} gallon),
						'other' => q({0} gallonit),
						'per' => q({0} galloni kohta),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallonid),
						'one' => q({0} gallon),
						'other' => q({0} gallonit),
						'per' => q({0} galloni kohta),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(inglise gallonid),
						'one' => q({0} inglise gallon),
						'other' => q({0} inglise gallonit),
						'per' => q({0} inglise galloni kohta),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(inglise gallonid),
						'one' => q({0} inglise gallon),
						'other' => q({0} inglise gallonit),
						'per' => q({0} inglise galloni kohta),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliitrid),
						'one' => q({0} hektoliiter),
						'other' => q({0} hektoliitrit),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliitrid),
						'one' => q({0} hektoliiter),
						'other' => q({0} hektoliitrit),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} liiter),
						'other' => q({0} liitrit),
						'per' => q({0} liitri kohta),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} liiter),
						'other' => q({0} liitrit),
						'per' => q({0} liitri kohta),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliitrid),
						'one' => q({0} megaliiter),
						'other' => q({0} megaliitrit),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliitrid),
						'one' => q({0} megaliiter),
						'other' => q({0} megaliitrit),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(milliliitrid),
						'one' => q({0} milliliiter),
						'other' => q({0} milliliitrit),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(milliliitrid),
						'one' => q({0} milliliiter),
						'other' => q({0} milliliitrit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} pint),
						'other' => q({0} pinti),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pint),
						'other' => q({0} pinti),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(meetrilised pindid),
						'one' => q({0} meetriline pint),
						'other' => q({0} meetrilist pinti),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(meetrilised pindid),
						'one' => q({0} meetriline pint),
						'other' => q({0} meetrilist pinti),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kvardid),
						'one' => q({0} kvart),
						'other' => q({0} kvarti),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvardid),
						'one' => q({0} kvart),
						'other' => q({0} kvarti),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(inglise kvart),
						'one' => q({0} inglise kvart),
						'other' => q({0} inglise kvarti),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(inglise kvart),
						'one' => q({0} inglise kvart),
						'other' => q({0} inglise kvarti),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(supilusikad),
						'one' => q({0} supilusikas),
						'other' => q({0} supilusikat),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(supilusikad),
						'one' => q({0} supilusikas),
						'other' => q({0} supilusikat),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(teelusikad),
						'one' => q({0} teelusikas),
						'other' => q({0} teelusikat),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(teelusikad),
						'one' => q({0} teelusikas),
						'other' => q({0} teelusikat),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(päev),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(päev),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(n),
						'one' => q({0} n),
						'other' => q({0} n),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(n),
						'one' => q({0} n),
						'other' => q({0} n),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
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
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} jalg),
						'other' => q({0} jalga),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} jalg),
						'other' => q({0} jalga),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} toll),
						'other' => q({0} tolli),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} toll),
						'other' => q({0} tolli),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punktid),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punktid),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramm),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0} toll Hg),
						'other' => q({0} tolli Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0} toll Hg),
						'other' => q({0} tolli Hg),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(d. ved.),
						'one' => q({0} d. ved.),
						'other' => q({0} d. ved.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(d. ved.),
						'one' => q({0} d. ved.),
						'other' => q({0} d. ved.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} gal Im),
						'other' => q({0} gal Im),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} gal Im),
						'other' => q({0} gal Im),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liiter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liiter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(näp.),
						'one' => q({0} näp.),
						'other' => q({0} näp.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(näp.),
						'one' => q({0} näp.),
						'other' => q({0} näp.),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ilmakaar),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ilmakaar),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Maa raskuskiirendus),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Maa raskuskiirendus),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(kaareminut),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(kaareminut),
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
						'name' => q(kraadid),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(kraadid),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiaanid),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiaanid),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(pööre),
						'one' => q({0} pööre),
						'other' => q({0} pööret),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(pööre),
						'one' => q({0} pööre),
						'other' => q({0} pööret),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(aakrid),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(aakrid),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunamid),
						'one' => q({0} dunam),
						'other' => q({0} dunami),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunamid),
						'one' => q({0} dunam),
						'other' => q({0} dunami),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarid),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarid),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ruutjalad),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ruutjalad),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ruuttollid),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ruuttollid),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ruutjardid),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ruutjardid),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(üksus),
						'one' => q({0} üksus),
						'other' => q({0} üksust),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(üksus),
						'one' => q({0} üksus),
						'other' => q({0} üksust),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaat),
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
					'concentr-mole' => {
						'name' => q(mool),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mool),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(osa/miljon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(osa/miljon),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(promüriaad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(promüriaad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
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
						'name' => q(miil/gallon),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miil/gallon),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miil / gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miil / gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ip),
						'north' => q({0} pl),
						'south' => q({0} ll),
						'west' => q({0} lp),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ip),
						'north' => q({0} pl),
						'south' => q({0} ll),
						'west' => q({0} lp),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bitt),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bitt),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bait),
						'one' => q({0} bait),
						'other' => q({0} baiti),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bait),
						'one' => q({0} bait),
						'other' => q({0} baiti),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(saj),
						'one' => q({0} saj),
						'other' => q({0} saj),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(saj),
						'one' => q({0} saj),
						'other' => q({0} saj),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(päevad),
						'one' => q({0} päev),
						'other' => q({0} päeva),
						'per' => q({0}/ööp),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(päevad),
						'one' => q({0} päev),
						'other' => q({0} päeva),
						'per' => q({0}/ööp),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(kuud),
						'one' => q({0} kuu),
						'other' => q({0} kuud),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kuud),
						'one' => q({0} kuu),
						'other' => q({0} kuud),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/kv),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/kv),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(näd),
						'one' => q({0} näd),
						'other' => q({0} näd),
						'per' => q({0}/näd),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(näd),
						'one' => q({0} näd),
						'other' => q({0} näd),
						'per' => q({0}/näd),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(aastad),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(aastad),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amprid),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amprid),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamprid),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamprid),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(oomid),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(oomid),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voldid),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voldid),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Briti soojusühik),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Briti soojusühik),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(džaulid),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(džaulid),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-tund),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-tund),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(USA term),
						'one' => q({0} USA term),
						'other' => q({0} USA termi),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(USA term),
						'one' => q({0} USA term),
						'other' => q({0} USA termi),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh / 100 km),
						'one' => q({0} kWh / 100 km),
						'other' => q({0} kWh / 100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh / 100 km),
						'one' => q({0} kWh / 100 km),
						'other' => q({0} kWh / 100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(njuuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(njuuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(jõunael),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(jõunael),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(emm),
						'one' => q({0} emm),
						'other' => q({0} emmi),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(emm),
						'one' => q({0} emm),
						'other' => q({0} emmi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikslid),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikslid),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikslid),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikslid),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(aü),
						'one' => q({0} aü),
						'other' => q({0} aü),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(aü),
						'one' => q({0} aü),
						'other' => q({0} aü),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(süllad),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(süllad),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongid),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongid),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tollid),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tollid),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(valgusaastad),
						'one' => q({0} valgusa.),
						'other' => q({0} valgusa.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(valgusaastad),
						'one' => q({0} valgusa.),
						'other' => q({0} valgusa.),
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
					'length-parsec' => {
						'name' => q(parsekid),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsekid),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(tüpograafilised punktid),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(tüpograafilised punktid),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Päikese raadiused),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Päikese raadiused),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardid),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardid),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Päikese heledus),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Päikese heledus),
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
					'mass-dalton' => {
						'name' => q(daltonid),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltonid),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Maa massid),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Maa massid),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(graan),
						'one' => q({0} graan),
						'other' => q({0} graani),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(graan),
						'one' => q({0} graan),
						'other' => q({0} graani),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammid),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammid),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(naelad),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(naelad),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Päikese massid),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Päikese massid),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(kivid),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(kivid),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(lüh t),
						'one' => q({0} lüh t),
						'other' => q({0} lüh t),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(lüh t),
						'one' => q({0} lüh t),
						'other' => q({0} lüh t),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hj),
						'one' => q({0} hj),
						'other' => q({0} hj),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hj),
						'one' => q({0} hj),
						'other' => q({0} hj),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vatid),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vatid),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baar),
						'one' => q({0} baar),
						'other' => q({0} baari),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baar),
						'one' => q({0} baar),
						'other' => q({0} baari),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
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
					'torque-newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(aakerjalg),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(aakerjalg),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buššelid),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buššelid),
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
					'volume-cubic-inch' => {
						'name' => q(kuuptollid),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kuuptollid),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kuupmiilid),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kuupmiilid),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kuupjardid),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kuupjardid),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tass),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tass),
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
						'name' => q(ingl dl),
						'one' => q({0} ingl dl),
						'other' => q({0} ingl dl),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ingl dl),
						'one' => q({0} ingl dl),
						'other' => q({0} ingl dl),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drahm vedelikku),
						'one' => q({0} drahm vedelikku),
						'other' => q({0} drahmi vedelikku),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drahm vedelikku),
						'one' => q({0} drahm vedelikku),
						'other' => q({0} drahmi vedelikku),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tilk),
						'one' => q({0} tilk),
						'other' => q({0} tilka),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tilk),
						'one' => q({0} tilk),
						'other' => q({0} tilka),
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
						'name' => q(pits),
						'one' => q({0} pits),
						'other' => q({0} pitsi),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(pits),
						'one' => q({0} pits),
						'other' => q({0} pitsi),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liitrid),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liitrid),
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
						'name' => q(näputäis),
						'one' => q({0} näputäis),
						'other' => q({0} näputäit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(näputäis),
						'one' => q({0} näputäis),
						'other' => q({0} näputäit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pindid),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pindid),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kvart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ingl kvart),
						'one' => q({0} ingl kvart),
						'other' => q({0} ingl kvarti),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ingl kvart),
						'one' => q({0} ingl kvart),
						'other' => q({0} ingl kvarti),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(spl),
						'one' => q({0} spl),
						'other' => q({0} spl),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(spl),
						'one' => q({0} spl),
						'other' => q({0} spl),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jah|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ei|e|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ja {1}),
				2 => q({0} ja {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(×10^),
			'group' => q( ),
			'minusSign' => q(−),
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
					'one' => '0 tuhat',
					'other' => '0 tuhat',
				},
				'10000' => {
					'one' => '00 tuhat',
					'other' => '00 tuhat',
				},
				'100000' => {
					'one' => '000 tuhat',
					'other' => '000 tuhat',
				},
				'1000000' => {
					'one' => '0 miljon',
					'other' => '0 miljonit',
				},
				'10000000' => {
					'one' => '00 miljonit',
					'other' => '00 miljonit',
				},
				'100000000' => {
					'one' => '000 miljonit',
					'other' => '000 miljonit',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljardit',
				},
				'10000000000' => {
					'one' => '00 miljardit',
					'other' => '00 miljardit',
				},
				'100000000000' => {
					'one' => '000 miljardit',
					'other' => '000 miljardit',
				},
				'1000000000000' => {
					'one' => '0 triljon',
					'other' => '0 triljonit',
				},
				'10000000000000' => {
					'one' => '00 triljonit',
					'other' => '00 triljonit',
				},
				'100000000000000' => {
					'one' => '000 triljonit',
					'other' => '000 triljonit',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tuh',
					'other' => '0 tuh',
				},
				'10000' => {
					'one' => '00 tuh',
					'other' => '00 tuh',
				},
				'100000' => {
					'one' => '000 tuh',
					'other' => '000 tuh',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mld',
					'other' => '0 mld',
				},
				'10000000000' => {
					'one' => '00 mld',
					'other' => '00 mld',
				},
				'100000000000' => {
					'one' => '000 mld',
					'other' => '000 mld',
				},
				'1000000000000' => {
					'one' => '0 trln',
					'other' => '0 trln',
				},
				'10000000000000' => {
					'one' => '00 trln',
					'other' => '00 trln',
				},
				'100000000000000' => {
					'one' => '000 trln',
					'other' => '000 trln',
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
						'negative' => '(#,##0.00 ¤)',
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
				'currency' => q(Andorra peseeta),
				'one' => q(Andorra peseeta),
				'other' => q(Andorra peseetat),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Araabia Ühendemiraatide dirhem),
				'one' => q(Araabia Ühendemiraatide dirhem),
				'other' => q(Araabia Ühendemiraatide dirhemit),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afganistani afgaani \(1927–2002\)),
				'one' => q(Afganistani afgaani \(1927–2002\)),
				'other' => q(Afganistani afgaanit \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistani afgaani),
				'one' => q(Afganistani afgaani),
				'other' => q(Afganistani afgaanit),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albaania lekk \(1946–1965\)),
				'one' => q(Albaania lekk \(1946–1965\)),
				'other' => q(Albaania lekki \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albaania lekk),
				'one' => q(Albaania lekk),
				'other' => q(Albaania lekki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armeenia dramm),
				'one' => q(Armeenia dramm),
				'other' => q(Armeenia drammi),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Hollandi Antillide kulden),
				'one' => q(Hollandi Antillide kulden),
				'other' => q(Hollandi Antillide kuldnat),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola kvanza),
				'one' => q(Angola kvanza),
				'other' => q(Angola kvanzat),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angola kvanza \(1977–1990\)),
				'one' => q(Angola kvanza \(1977–1990\)),
				'other' => q(Angola kvanzat \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angola kvanza \(1990–2000\)),
				'one' => q(Angola kvanza \(1990–2000\)),
				'other' => q(Angola kvanzat \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angola reformitud kvanza, 1995–1999),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentina austral),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentina peeso \(1881–1970\)),
				'one' => q(Argentina peeso \(1881–1970\)),
				'other' => q(Argentina peesot \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentina peeso \(1983–1985\)),
				'one' => q(Argentina peeso \(1983–1985\)),
				'other' => q(Argentina peesot \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentina peeso),
				'one' => q(Argentina peeso),
				'other' => q(Argentina peesot),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austria šilling),
				'one' => q(Austria šilling),
				'other' => q(Austria šillingit),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Austraalia dollar),
				'one' => q(Austraalia dollar),
				'other' => q(Austraalia dollarit),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba kulden),
				'one' => q(Aruba kulden),
				'other' => q(Aruba kuldnat),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Aserbaidžaani manat \(1993–2006\)),
				'one' => q(Aserbaidžaani manat \(1993–2006\)),
				'other' => q(Aserbaidžaani manatit \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbaidžaani manat),
				'one' => q(Aserbaidžaani manat),
				'other' => q(Aserbaidžaani manatit),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnia ja Hertsegoviina dinaar \(1992–1994\)),
				'one' => q(Bosnia ja Hertsegoviina dinaar \(1992–1994\)),
				'other' => q(Bosnia ja Hertsegoviina dinaari \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia ja Hertsegoviina konverteeritav mark),
				'one' => q(Bosnia ja Hertsegoviina konverteeritav mark),
				'other' => q(Bosnia ja Hertsegoviina konverteeritavat marka),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosnia ja Hertsegoviina uus dinaar \(1994–1997\)),
				'one' => q(Bosnia ja Hertsegoviina uus dinaar \(1994–1997\)),
				'other' => q(Bosnia ja Hertsegoviina uut dinaari \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadose dollar),
				'one' => q(Barbadose dollar),
				'other' => q(Barbadose dollarit),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeshi taka),
				'one' => q(Bangladeshi taka),
				'other' => q(Bangladeshi takat),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgia konverteeritav frank),
				'one' => q(Belgia konverteeritav frank),
				'other' => q(Belgia konverteeritavat franki),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgia frank),
				'one' => q(Belgia frank),
				'other' => q(Belgia franki),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgia arveldusfrank),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgaaria püsiv leev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaaria leev),
				'one' => q(Bulgaaria leev),
				'other' => q(Bulgaaria leevi),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgaaria leev \(1879–1952\)),
				'one' => q(Bulgaaria leev \(1879–1952\)),
				'other' => q(Bulgaaria leevi \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreini dinaar),
				'one' => q(Bahreini dinaar),
				'other' => q(Bahreini dinaari),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi frank),
				'one' => q(Burundi frank),
				'other' => q(Burundi franki),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda dollar),
				'one' => q(Bermuda dollar),
				'other' => q(Bermuda dollarit),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei dollar),
				'one' => q(Brunei dollar),
				'other' => q(Brunei dollarit),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliivia boliviaano),
				'one' => q(Boliivia boliviaano),
				'other' => q(Boliivia boliviaanot),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliivia boliviaano \(1863–1963\)),
				'one' => q(Boliivia boliviaano \(1863–1963\)),
				'other' => q(Boliivia boliviaanot \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliivia peeso),
				'one' => q(Boliivia peeso),
				'other' => q(Boliivia peesot),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasiilia uus kruseiro \(1967–1986\)),
				'one' => q(Brasiilia uus kruseiro \(1967–1986\)),
				'other' => q(Brasiilia uut kruseirot \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasiilia krusado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasiilia kruseiro \(1990–1993\)),
				'one' => q(Brasiilia kruseiro \(1990–1993\)),
				'other' => q(Brasiilia kruseirot \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasiilia reaal),
				'one' => q(Brasiilia reaal),
				'other' => q(Brasiilia reaali),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasiilia kruseiro \(1993–1994\)),
				'one' => q(Brasiilia kruseiro \(1993–1994\)),
				'other' => q(Brasiilia kruseirot \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brasiilia kruseiro \(1942–1967\)),
				'one' => q(Brasiilia kruseiro \(1942–1967\)),
				'other' => q(Brasiilia kruseirot \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahama dollar),
				'one' => q(Bahama dollar),
				'other' => q(Bahama dollarit),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutani ngultrum),
				'one' => q(Bhutani ngultrum),
				'other' => q(Bhutani ngultrumit),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Birma kjatt),
				'one' => q(Birma kjatt),
				'other' => q(Birma kjatti),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswana pula),
				'one' => q(Botswana pula),
				'other' => q(Botswana pulat),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Valgevene uus rubla \(1994–1999\)),
				'one' => q(Valgevene uus rubla \(1994–1999\)),
				'other' => q(Valgevene uut rubla \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Valgevene rubla),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Valgevene rubla \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize’i dollar),
				'one' => q(Belize’i dollar),
				'other' => q(Belize’i dollarit),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada dollar),
				'one' => q(Kanada dollar),
				'other' => q(Kanada dollarit),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo frank),
				'one' => q(Kongo frank),
				'other' => q(Kongo franki),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Šveitsi frank),
				'one' => q(Šveitsi frank),
				'other' => q(Šveitsi franki),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Tšiili eskuudo),
				'one' => q(Tšiili eskuudo),
				'other' => q(Tšiili eskuudot),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Tšiili peeso),
				'one' => q(Tšiili peeso),
				'other' => q(Tšiili peesot),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Hiina jüaan \(välismaine turg\)),
				'one' => q(Hiina jüaan \(välismaine turg\)),
				'other' => q(Hiina jüaani \(välismaine turg\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Hiina jüaan),
				'one' => q(Hiina jüaan),
				'other' => q(Hiina jüaani),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombia peeso),
				'one' => q(Colombia peeso),
				'other' => q(Colombia peesot),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rica koloon),
				'one' => q(Costa Rica koloon),
				'other' => q(Costa Rica kolooni),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbia dinaar \(2002–2006\)),
				'one' => q(Serbia dinaar \(2002–2006\)),
				'other' => q(Serbia dinaari \(2002–2006\)),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kuuba konverteeritav peeso),
				'one' => q(Kuuba konverteeritav peeso),
				'other' => q(Kuuba konverteeritavat peesot),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuuba peeso),
				'one' => q(Kuuba peeso),
				'other' => q(Kuuba peesot),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cabo Verde eskuudo),
				'one' => q(Cabo Verde eskuudo),
				'other' => q(Cabo Verde eskuudot),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Küprose nael),
				'one' => q(Küprose nael),
				'other' => q(Küprose naela),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tšehhi kroon),
				'one' => q(Tšehhi kroon),
				'other' => q(Tšehhi krooni),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Ida-Saksa mark),
				'one' => q(Ida-Saksa mark),
				'other' => q(Ida-Saksa marka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Saksa mark),
				'one' => q(Saksa mark),
				'other' => q(Saksa marka),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djibouti frank),
				'one' => q(Djibouti frank),
				'other' => q(Djibouti franki),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Taani kroon),
				'one' => q(Taani kroon),
				'other' => q(Taani krooni),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikaani peeso),
				'one' => q(Dominikaani peeso),
				'other' => q(Dominikaani peesot),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Alžeeria dinaar),
				'one' => q(Alžeeria dinaar),
				'other' => q(Alžeeria dinaari),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadori sukre),
				'one' => q(Ecuadori sukre),
				'other' => q(Ecuadori sukret),
			},
		},
		'EEK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(Eesti kroon),
				'one' => q(Eesti kroon),
				'other' => q(Eesti krooni),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egiptuse nael),
				'one' => q(Egiptuse nael),
				'other' => q(Egiptuse naela),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrea nakfa),
				'one' => q(Eritrea nakfa),
				'other' => q(Eritrea nakfat),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Hispaania peseeta),
				'one' => q(Hispaania peseeta),
				'other' => q(Hispaania peseetat),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etioopia birr),
				'one' => q(Etioopia birr),
				'other' => q(Etioopia birri),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(eurot),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Soome mark),
				'one' => q(Soome mark),
				'other' => q(Soome marka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidži dollar),
				'one' => q(Fidži dollar),
				'other' => q(Fidži dollarit),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklandi saarte nael),
				'one' => q(Falklandi saarte nael),
				'other' => q(Falklandi saarte naela),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Prantsuse frank),
				'one' => q(Prantsuse frank),
				'other' => q(Prantsuse franki),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Suurbritannia naelsterling),
				'one' => q(Suurbritannia naelsterling),
				'other' => q(Suurbritannia naelsterlingit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gruusia lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghana sedi \(1979–2007\)),
				'one' => q(Ghana sedi \(1979–2007\)),
				'other' => q(Ghana sedit \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghana sedi),
				'one' => q(Ghana sedi),
				'other' => q(Ghana sedit),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltari nael),
				'one' => q(Gibraltari nael),
				'other' => q(Gibraltari naela),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia dalasi),
				'one' => q(Gambia dalasi),
				'other' => q(Gambia dalasit),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinea frank),
				'one' => q(Guinea frank),
				'other' => q(Guinea franki),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinea syli),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Kreeka drahm),
				'one' => q(Kreeka drahm),
				'other' => q(Kreeka drahmi),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemala ketsaal),
				'one' => q(Guatemala ketsaal),
				'other' => q(Guatemala ketsaali),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugali Guinea eskuudo),
				'one' => q(Portugali Guinea eskuudo),
				'other' => q(Portugali Guinea eskuudot),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau peeso),
				'one' => q(Guinea-Bissau peeso),
				'other' => q(Guinea-Bissau peesot),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana dollar),
				'one' => q(Guyana dollar),
				'other' => q(Guyana dollarit),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkongi dollar),
				'one' => q(Hongkongi dollar),
				'other' => q(Hongkongi dollarit),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondurase lempiira),
				'one' => q(Hondurase lempiira),
				'other' => q(Hondurase lempiirat),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Horvaatia dinaar),
				'one' => q(Horvaatia dinaar),
				'other' => q(Horvaatia dinaari),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Horvaatia kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti gurd),
				'one' => q(Haiti gurd),
				'other' => q(Haiti gurdi),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungari forint),
				'one' => q(Ungari forint),
				'other' => q(Ungari forintit),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indoneesia ruupia),
				'one' => q(Indoneesia ruupia),
				'other' => q(Indoneesia ruupiat),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Iiri nael),
				'one' => q(Iiri nael),
				'other' => q(Iiri naela),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Iisraeli nael),
				'one' => q(Iisraeli nael),
				'other' => q(Iisraeli naela),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Iisraeli seekel \(1980–1985\)),
				'one' => q(Iisraeli seekel \(1980–1985\)),
				'other' => q(Iisraeli seekelit \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Iisraeli uus seekel),
				'one' => q(Iisraeli uus seekel),
				'other' => q(Iisraeli uut seeklit),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(India ruupia),
				'one' => q(India ruupia),
				'other' => q(India ruupiat),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraagi dinaar),
				'one' => q(Iraagi dinaar),
				'other' => q(Iraagi dinaari),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iraani riaal),
				'one' => q(Iraani riaal),
				'other' => q(Iraani riaali),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Islandi kroon \(1918–1981\)),
				'one' => q(Islandi kroon \(1918–1981\)),
				'other' => q(Islandi krooni \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islandi kroon),
				'one' => q(Islandi kroon),
				'other' => q(Islandi krooni),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Itaalia liir),
				'one' => q(Itaalia liir),
				'other' => q(Itaalia liiri),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaica dollar),
				'one' => q(Jamaica dollar),
				'other' => q(Jamaica dollarit),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaania dinaar),
				'one' => q(Jordaania dinaar),
				'other' => q(Jordaania dinaari),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Jaapani jeen),
				'one' => q(Jaapani jeen),
				'other' => q(Jaapani jeeni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keenia šilling),
				'one' => q(Keenia šilling),
				'other' => q(Keenia šillingit),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kõrgõzstani somm),
				'one' => q(Kõrgõzstani somm),
				'other' => q(Kõrgõzstani sommi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodža riaal),
				'one' => q(Kambodža riaal),
				'other' => q(Kambodža riaali),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoori frank),
				'one' => q(Komoori frank),
				'other' => q(Komoori franki),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Põhja-Korea vonn),
				'one' => q(Põhja-Korea vonn),
				'other' => q(Põhja-Korea vonni),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Lõuna-Korea vonn \(1945–1953\)),
				'one' => q(Lõuna-Korea vonn \(1945–1953\)),
				'other' => q(Lõuna-Korea vonni \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Lõuna-Korea vonn),
				'one' => q(Lõuna-Korea vonn),
				'other' => q(Lõuna-Korea vonni),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuveidi dinaar),
				'one' => q(Kuveidi dinaar),
				'other' => q(Kuveidi dinaari),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaimanisaarte dollar),
				'one' => q(Kaimanisaarte dollar),
				'other' => q(Kaimanisaarte dollarit),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasahstani tenge),
				'one' => q(Kasahstani tenge),
				'other' => q(Kasahstani tenget),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laose kiip),
				'one' => q(Laose kiip),
				'other' => q(Laose kiipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Liibanoni nael),
				'one' => q(Liibanoni nael),
				'other' => q(Liibanoni naela),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lanka ruupia),
				'one' => q(Sri Lanka ruupia),
				'other' => q(Sri Lanka ruupiat),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Libeeria dollar),
				'one' => q(Libeeria dollar),
				'other' => q(Libeeria dollarit),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho loti),
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotit),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Leedu litt),
				'one' => q(Leedu litt),
				'other' => q(Leedu litti),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luksemburgi konverteeritav frank),
				'one' => q(Luksemburgi konverteeritav frank),
				'other' => q(Luksemburgi konverteeritavat franki),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburgi frank),
				'one' => q(Luksemburgi frank),
				'other' => q(Luksemburgi franki),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Läti latt),
				'one' => q(Läti latt),
				'other' => q(Läti latti),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Läti rubla),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liibüa dinaar),
				'one' => q(Liibüa dinaar),
				'other' => q(Liibüa dinaari),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Maroko dirhem),
				'one' => q(Maroko dirhem),
				'other' => q(Maroko dirhemit),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Maroko frank),
				'one' => q(Maroko frank),
				'other' => q(Maroko franki),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monaco frank),
				'one' => q(Monaco frank),
				'other' => q(Monaco franki),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova leu),
				'one' => q(Moldova leu),
				'other' => q(Moldova leud),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskari ariari),
				'one' => q(Madagaskari ariari),
				'other' => q(Madagaskari ariarit),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskari frank),
				'one' => q(Madagaskari frank),
				'other' => q(Madagaskar franki),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedoonia dinaar),
				'one' => q(Makedoonia dinaar),
				'other' => q(Makedoonia dinaari),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedoonia dinaar \(1992–1993\)),
				'one' => q(Makedoonia dinaar \(1992–1993\)),
				'other' => q(Makedoonia dinaari \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali frank),
				'one' => q(Mali frank),
				'other' => q(Mali franki),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmari kjatt),
				'one' => q(Myanmari kjatt),
				'other' => q(Myanmari kjatti),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoolia tugrik),
				'one' => q(Mongoolia tugrik),
				'other' => q(Mongoolia tugrikut),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macau pataaka),
				'one' => q(Macau pataaka),
				'other' => q(Macau pataakat),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritaania ugia \(1973–2017\)),
				'one' => q(Mauritaania ugia \(1973–2017\)),
				'other' => q(Mauritaania ugiat \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritaania ugia),
				'one' => q(Mauritaania ugia),
				'other' => q(Mauritaania ugiat),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malta liir),
				'one' => q(Malta liir),
				'other' => q(Malta liiri),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Malta nael),
				'one' => q(Malta nael),
				'other' => q(Malta naela),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritiuse ruupia),
				'one' => q(Mauritiuse ruupia),
				'other' => q(Mauritiuse ruupiat),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Maldiivi ruupia \(1947–1981\)),
				'one' => q(Maldiivi ruupia \(1947–1981\)),
				'other' => q(Maldiivi ruupiat \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldiivi ruupia),
				'one' => q(Maldiivi ruupia),
				'other' => q(Maldiivi ruupiat),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi kvatša),
				'one' => q(Malawi kvatša),
				'other' => q(Malawi kvatšat),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mehhiko peeso),
				'one' => q(Mehhiko peeso),
				'other' => q(Mehhiko peesot),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mehhiko peeso \(1861–1992\)),
				'one' => q(Mehhiko peeso \(1861–1992\)),
				'other' => q(Mehhiko peesot \(1861–1992\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaisia ringgit),
				'one' => q(Malaisia ringgit),
				'other' => q(Malaisia ringgitit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mosambiigi eskuudo),
				'one' => q(Mosambiigi eskuudo),
				'other' => q(Mosambiigi eskuudot),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mosambiigi metikal \(1980–2006\)),
				'one' => q(Mosambiigi metikal \(1980–2006\)),
				'other' => q(Mosambiigi metikali \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambiigi metikal),
				'one' => q(Mosambiigi metikal),
				'other' => q(Mosambiigi metikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namiibia dollar),
				'one' => q(Namiibia dollar),
				'other' => q(Namiibia dollarit),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeeria naira),
				'one' => q(Nigeeria naira),
				'other' => q(Nigeeria nairat),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaragua kordoba \(1988–1991\)),
				'one' => q(Nicaragua kordoba \(1988–1991\)),
				'other' => q(Nicaragua kordobat \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaragua kordoba),
				'one' => q(Nicaragua kordoba),
				'other' => q(Nicaragua kordobat),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollandi kulden),
				'one' => q(Hollandi kulden),
				'other' => q(Hollandi kuldnat),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norra kroon),
				'one' => q(Norra kroon),
				'other' => q(Norra krooni),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepali ruupia),
				'one' => q(Nepali ruupia),
				'other' => q(Nepali ruupiat),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Uus-Meremaa dollar),
				'one' => q(Uus-Meremaa dollar),
				'other' => q(Uus-Meremaa dollarit),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omaani riaal),
				'one' => q(Omaani riaal),
				'other' => q(Omaani riaali),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama balboa),
				'one' => q(Panama balboa),
				'other' => q(Panama balboad),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruu inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruu soll),
				'one' => q(Peruu soll),
				'other' => q(Peruu solli),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruu soll \(1863–1965\)),
				'one' => q(Peruu soll \(1863–1965\)),
				'other' => q(Peruu solli \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Paapua Uus-Guinea kina),
				'one' => q(Paapua Uus-Guinea kina),
				'other' => q(Paapua Uus-Guinea kinat),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipiini peeso),
				'one' => q(Filipiini peeso),
				'other' => q(Filipiini peesot),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistani ruupia),
				'one' => q(Pakistani ruupia),
				'other' => q(Pakistani ruupiat),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poola zlott),
				'one' => q(Poola zlott),
				'other' => q(Poola zlotti),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poola zlott \(1950–1995\)),
				'one' => q(Poola zlott \(1950–1995\)),
				'other' => q(Poola zlotti \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugali eskuudo),
				'one' => q(Portugali eskuudo),
				'other' => q(Portugali eskuudot),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguay guaranii),
				'one' => q(Paraguay guaranii),
				'other' => q(Paraguay guaraniid),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katari riaal),
				'one' => q(Katari riaal),
				'other' => q(Katari riaali),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodeesia dollar),
				'one' => q(Rodeesia dollar),
				'other' => q(Rodeesia dollarit),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumeenia leu \(1952–2006\)),
				'one' => q(Rumeenia leu \(1952–2006\)),
				'other' => q(Rumeenia leud \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumeenia leu),
				'one' => q(Rumeenia leu),
				'other' => q(Rumeenia leud),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbia dinaar),
				'one' => q(Serbia dinaar),
				'other' => q(Serbia dinaari),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Venemaa rubla),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Venemaa rubla \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwanda frank),
				'one' => q(Rwanda frank),
				'other' => q(Rwanda franki),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Araabia riaal),
				'one' => q(Saudi Araabia riaal),
				'other' => q(Saudi Araabia riaali),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Saalomoni Saarte dollar),
				'one' => q(Saalomoni Saarte dollar),
				'other' => q(Saalomoni Saarte dollarit),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seišelli ruupia),
				'one' => q(Seišelli ruupia),
				'other' => q(Seišelli ruupiat),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudaani dinaar \(1992–2007\)),
				'one' => q(Sudaani dinaar \(1992–2007\)),
				'other' => q(Sudaani dinaari \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudaani nael),
				'one' => q(Sudaani nael),
				'other' => q(Sudaani naela),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudaani nael \(1957–1998\)),
				'one' => q(Sudaani nael \(1957–1998\)),
				'other' => q(Sudaani naela \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Rootsi kroon),
				'one' => q(Rootsi kroon),
				'other' => q(Rootsi krooni),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapuri dollar),
				'one' => q(Singapuri dollar),
				'other' => q(Singapuri dollarit),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Saint Helena nael),
				'one' => q(Saint Helena nael),
				'other' => q(Saint Helena naela),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloveenia tolar),
				'one' => q(Sloveenia tolar),
				'other' => q(Sloveenia tolarit),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovaki kroon),
				'one' => q(Slovaki kroon),
				'other' => q(Slovaki krooni),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leone leoone),
				'one' => q(Sierra Leone leoone),
				'other' => q(Sierra Leone leoonet),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leone leoone \(1964–2022\)),
				'one' => q(Sierra Leone leoone \(1964–2022\)),
				'other' => q(Sierra Leone leoonet \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somaalia šilling),
				'one' => q(Somaalia šilling),
				'other' => q(Somaalia šillingit),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Suriname dollar),
				'one' => q(Suriname dollar),
				'other' => q(Suriname dollarit),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Suriname kulden),
				'one' => q(Suriname kulden),
				'other' => q(Suriname kuldnat),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Lõuna-Sudaani nael),
				'one' => q(Lõuna-Sudaani nael),
				'other' => q(Lõuna-Sudaani naela),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé ja Príncipe dobra \(1977–2017\)),
				'one' => q(São Tomé ja Príncipe dobra \(1977–2017\)),
				'other' => q(São Tomé ja Príncipe dobrat \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé ja Príncipe dobra),
				'one' => q(São Tomé ja Príncipe dobra),
				'other' => q(São Tomé ja Príncipe dobrat),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(NSVL-i rubla),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvadori koloon),
				'one' => q(El Salvadori koloon),
				'other' => q(El Salvadori kolooni),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Süüria nael),
				'one' => q(Süüria nael),
				'other' => q(Süüria naela),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svaasimaa lilangeni),
				'one' => q(Svaasimaa lilangeni),
				'other' => q(Svaasimaa lilangenit),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Tai baat),
				'one' => q(Tai baat),
				'other' => q(Tai baati),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadžikistani rubla),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadžikistani somoni),
				'one' => q(Tadžikistani somoni),
				'other' => q(Tadžikistani somonit),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Türkmenistani manat \(1993–2009\)),
				'one' => q(Türkmenistani manat \(1993–2009\)),
				'other' => q(Türkmenistani manatit \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Türkmenistani manat),
				'one' => q(Türkmenistani manat),
				'other' => q(Türkmenistani manatit),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tuneesia dinaar),
				'one' => q(Tuneesia dinaar),
				'other' => q(Tuneesia dinaari),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga pa’anga),
				'one' => q(Tonga pa’anga),
				'other' => q(Tonga pa’angat),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timori eskuudo),
				'one' => q(Timori eskuudo),
				'other' => q(Timori eskuudot),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Türgi liir \(1922–2005\)),
				'one' => q(Türgi liir \(1922–2005\)),
				'other' => q(Türgi liiri \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Türgi liir),
				'one' => q(Türgi liir),
				'other' => q(Türgi liiri),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidadi ja Tobago dollar),
				'one' => q(Trinidadi ja Tobago dollar),
				'other' => q(Trinidadi ja Tobago dollarit),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(uus Taiwani dollar),
				'one' => q(uus Taiwani dollar),
				'other' => q(uut Taiwani dollarit),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansaania šilling),
				'one' => q(Tansaania šilling),
				'other' => q(Tansaania šillingit),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukraina grivna),
				'one' => q(Ukraina grivna),
				'other' => q(Ukraina grivnat),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukraina karbovanets),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uganda šilling \(1966–1987\)),
				'one' => q(Uganda šilling \(1966–1987\)),
				'other' => q(Uganda šillingit \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda šilling),
				'one' => q(Uganda šilling),
				'other' => q(Uganda šillingit),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(USA dollar),
				'one' => q(USA dollar),
				'other' => q(USA dollarit),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(USA järgmise päeva dollar),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(USA sama päeva dollar),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguay peeso \(1975–1993\)),
				'one' => q(Uruguay peeso \(1975–1993\)),
				'other' => q(Uruguay peesot \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguay peeso),
				'one' => q(Uruguay peeso),
				'other' => q(Uruguay peesot),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbekistani somm),
				'one' => q(Usbekistani somm),
				'other' => q(Usbekistani sommi),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuela boliivar \(1871–2008\)),
				'one' => q(Venezuela boliivar \(1871–2008\)),
				'other' => q(Venezuela boliivarit \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezuela boliivar \(2008–2018\)),
				'one' => q(Venezuela boliivar \(2008–2018\)),
				'other' => q(Venezuela boliivarit \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuela boliivar),
				'one' => q(Venezuela boliivar),
				'other' => q(Venezuela boliivarit),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnami dong),
				'one' => q(Vietnami dong),
				'other' => q(Vietnami dongi),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnami dong \(1978–1985\)),
				'one' => q(Vietnami dong \(1978–1985\)),
				'other' => q(Vietnami dongi \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatut),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa taala),
				'one' => q(Samoa taala),
				'other' => q(Samoa taalat),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Kesk-Aafrika CFA frank),
				'one' => q(Kesk-Aafrika CFA frank),
				'other' => q(Kesk-Aafrika CFA franki),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(hõbe),
				'one' => q(troiunts hõbedat),
				'other' => q(troiuntsi hõbedat),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(kuld),
				'one' => q(troiunts kulda),
				'other' => q(troiuntsi kulda),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(EURCO),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Euroopa rahaühik),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Euroopa rahaline arvestusühik \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Euroopa rahaline arvestusühik \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Ida-Kariibi dollar),
				'one' => q(Ida-Kariibi dollar),
				'other' => q(Ida-Kariibi dollarit),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Rahvusvahelise Valuutafondi arvestusühik),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(eküü),
				'one' => q(eküü),
				'other' => q(eküüd),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Prantsuse kuldfrank),
				'one' => q(Prantsuse kuldfrank),
				'other' => q(Prantsuse kuldfranki),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Prantsuse UIC-frank),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Lääne-Aafrika CFA frank),
				'one' => q(Lääne-Aafrika CFA frank),
				'other' => q(Lääne-Aafrika CFA franki),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(pallaadium),
				'one' => q(troiunts pallaadiumit),
				'other' => q(troiuntsi pallaadiumit),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP frank),
				'one' => q(CFP frank),
				'other' => q(CFP franki),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(plaatina),
				'one' => q(troiunts plaatinat),
				'other' => q(troiuntsi plaatinat),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(vääringute testkood),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(määramata rahaühik),
				'one' => q(\(määramata rahaühik\)),
				'other' => q(\(määramata rahaühikut\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jeemeni dinaar),
				'one' => q(Jeemeni dinaar),
				'other' => q(Jeemeni dinaari),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jeemeni riaal),
				'one' => q(Jeemeni riaal),
				'other' => q(Jeemeni riaali),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslaavia uus dinaar \(1994–2002\)),
				'one' => q(Jugoslaavia uus dinaar \(1994–2002\)),
				'other' => q(Jugoslaavia uut dinaari \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslaavia konverteeritav dinaar \(1990–1992\)),
				'one' => q(Jugoslaavia konverteeritav dinaar \(1990–1992\)),
				'other' => q(Jugoslaavia konverteeritavat dinaari \(1990–1992\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Lõuna-Aafrika rand),
				'one' => q(Lõuna-Aafrika rand),
				'other' => q(Lõuna-Aafrika randi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Sambia kvatša \(1968–2012\)),
				'one' => q(Sambia kvatša \(1968–2012\)),
				'other' => q(Sambia kvatšat \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Sambia kvatša),
				'one' => q(Sambia kvatša),
				'other' => q(Sambia kvatšat),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Sairi zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwe dollar \(1980–2008\)),
				'one' => q(Zimbabwe dollar \(1980–2008\)),
				'other' => q(Zimbabwe dollarit \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwe dollar \(2009\)),
				'one' => q(Zimbabwe dollar \(2009\)),
				'other' => q(Zimbabwe dollarit \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwe dollar \(2008\)),
				'one' => q(Zimbabwe dollar \(2008\)),
				'other' => q(Zimbabwe dollarit \(2008\)),
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
					wide => {
						nonleap => [
							'esimene kuu',
							'teine kuu',
							'kolmas kuu',
							'neljas kuu',
							'viies kuu',
							'kuues kuu',
							'seitsmes kuu',
							'kaheksas kuu',
							'üheksas kuu',
							'kümnes kuu',
							'üheteistkümnes kuu',
							'kaheteistkümnes kuu'
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
							'jaan',
							'veebr',
							'märts',
							'apr',
							'mai',
							'juuni',
							'juuli',
							'aug',
							'sept',
							'okt',
							'nov',
							'dets'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'jaanuar',
							'veebruar',
							'märts',
							'aprill',
							'mai',
							'juuni',
							'juuli',
							'august',
							'september',
							'oktoober',
							'november',
							'detsember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'V',
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
						mon => 'E',
						tue => 'T',
						wed => 'K',
						thu => 'N',
						fri => 'R',
						sat => 'L',
						sun => 'P'
					},
					wide => {
						mon => 'esmaspäev',
						tue => 'teisipäev',
						wed => 'kolmapäev',
						thu => 'neljapäev',
						fri => 'reede',
						sat => 'laupäev',
						sun => 'pühapäev'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'E',
						tue => 'T',
						wed => 'K',
						thu => 'N',
						fri => 'R',
						sat => 'L',
						sun => 'P'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. kvartal',
						1 => '2. kvartal',
						2 => '3. kvartal',
						3 => '4. kvartal'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
					'afternoon1' => q{pärastlõunal},
					'evening1' => q{õhtul},
					'midnight' => q{keskööl},
					'morning1' => q{hommikul},
					'night1' => q{öösel},
					'noon' => q{keskpäeval},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pärastlõuna},
					'evening1' => q{õhtu},
					'midnight' => q{kesköö},
					'morning1' => q{hommik},
					'night1' => q{öö},
					'noon' => q{keskpäev},
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
				'0' => 'BK'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'eKr',
				'1' => 'pKr'
			},
			wide => {
				'0' => 'enne Kristust',
				'1' => 'pärast Kristust'
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
		},
		'generic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{dd.MM.yy},
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
		'buddhist' => {
		},
		'chinese' => {
		},
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
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.MM.y GGGGG},
			Hms => q{H:mm:ss},
			M => q{M},
			MEd => q{E, d.M},
			MMM => q{MMMM},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E, d.M y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.MM.y GGGGG},
			M => q{M},
			MEd => q{E, d.M},
			MMM => q{MMMM},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{MMMM (W. 'nädal')},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'nädal' (Y)},
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
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y–M.y GGGGG},
				y => q{M.y–M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.MM.y GGGGG – E, d.MM.y GGGGG},
				M => q{E, d.MM.y – E, d.MM.y GGGGG},
				d => q{E, d.MM.y – E, d.MM.y GGGGG},
				y => q{E, d.MM.y – E, d.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y G – MMM y},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM y G – E, d. MMM},
				d => q{E, d. MMM y G – E, d. MMM},
				y => q{E, d. MMM y G – E, d. MMM y},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM y G – d. MMM},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y G – d. MMM y},
			},
			GyMd => {
				G => q{d.MM.y GGGGG – d.MM.y GGGGG},
				M => q{d.MM.y–d.MM.y GGGGG},
				d => q{d.MM.y–d.MM.y GGGGG},
				y => q{d.MM.y–d.MM.y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			fallback => '{0}–{1}',
			h => {
				h => q{h–h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y–MM.y G},
				y => q{MM.y–MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y G},
				d => q{dd.MM.y–dd.MM.y G},
				y => q{dd.MM.y–dd.MM.y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y–M.y GGGGG},
				y => q{M.y–M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.MM.y GGGGG – E, d.MM.y GGGGG},
				M => q{E, d.MM.y – E, d.MM.y GGGGG},
				d => q{E, d.MM.y – E, d.MM.y GGGGG},
				y => q{E, d.MM.y – E, d.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{d.MM.y GGGGG – d.MM.y GGGGG},
				M => q{d.MM.y–d.MM.y GGGGG},
				d => q{d.MM.y–d.MM.y GGGGG},
				y => q{d.MM.y–d.MM.y GGGGG},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
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
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. MMM – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y},
				d => q{dd.MM.y–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
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
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(rott),
						1 => q(härg),
						2 => q(tiiger),
						3 => q(küülik),
						4 => q(draakon),
						5 => q(madu),
						6 => q(hobune),
						7 => q(lammas),
						8 => q(ahv),
						9 => q(kukk),
						10 => q(koer),
						11 => q(siga),
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
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(GMT {0}),
		regionFormat => q(({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre suveaeg#,
				'generic' => q#Acre aeg#,
				'standard' => q#Acre standardaeg#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistani aeg#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžiir#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartum#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Kesk-Aafrika aeg#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ida-Aafrika aeg#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Lõuna-Aafrika standardaeg#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Lääne-Aafrika suveaeg#,
				'generic' => q#Lääne-Aafrika aeg#,
				'standard' => q#Lääne-Aafrika standardaeg#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska suveaeg#,
				'generic' => q#Alaska aeg#,
				'standard' => q#Alaska standardaeg#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatõ suveaeg#,
				'generic' => q#Almatõ aeg#,
				'standard' => q#Almatõ standardaeg#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonase suveaeg#,
				'generic' => q#Amazonase aeg#,
				'standard' => q#Amazonase standardaeg#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#México#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Põhja-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Põhja-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Põhja-Dakota#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
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
		'America_Central' => {
			long => {
				'daylight' => q#Kesk-Ameerika suveaeg#,
				'generic' => q#Kesk-Ameerika aeg#,
				'standard' => q#Kesk-Ameerika standardaeg#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Idaranniku suveaeg#,
				'generic' => q#Idaranniku aeg#,
				'standard' => q#Idaranniku standardaeg#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mäestikuvööndi suveaeg#,
				'generic' => q#Mäestikuvööndi aeg#,
				'standard' => q#Mäestikuvööndi standardaeg#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Vaikse ookeani suveaeg#,
				'generic' => q#Vaikse ookeani aeg#,
				'standard' => q#Vaikse ookeani standardaeg#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadõri suveaeg#,
				'generic' => q#Anadõri aeg#,
				'standard' => q#Anadõri standardaeg#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia suveaeg#,
				'generic' => q#Apia aeg#,
				'standard' => q#Apia standardaeg#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aktau suveaeg#,
				'generic' => q#Aktau aeg#,
				'standard' => q#Aktau standardaeg#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aktöbe suveaeg#,
				'generic' => q#Aktöbe aeg#,
				'standard' => q#Aktöbe standardaeg#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Araabia suveaeg#,
				'generic' => q#Araabia aeg#,
				'standard' => q#Araabia standardaeg#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina suveaeg#,
				'generic' => q#Argentina aeg#,
				'standard' => q#Argentina standardaeg#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Lääne-Argentina suveaeg#,
				'generic' => q#Lääne-Argentina aeg#,
				'standard' => q#Lääne-Argentina standardaeg#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeenia suveaeg#,
				'generic' => q#Armeenia aeg#,
				'standard' => q#Armeenia standardaeg#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatõ#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadõr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atõrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakuu#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tšita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tšojbalsan#,
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
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruusalemm#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtšatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handõga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuveit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Masqaţ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kõzõlorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ar-Riyāḑ#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahhalin#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolõmsk#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Thbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tōkyō#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlandi suveaeg#,
				'generic' => q#Atlandi aeg#,
				'standard' => q#Atlandi standardaeg#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Assoorid#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaari saared#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Roheneemesaared#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Fääri saared#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Lõuna-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Kesk-Austraalia suveaeg#,
				'generic' => q#Kesk-Austraalia aeg#,
				'standard' => q#Kesk-Austraalia standardaeg#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Austraalia Kesk-Lääne suveaeg#,
				'generic' => q#Austraalia Kesk-Lääne aeg#,
				'standard' => q#Austraalia Kesk-Lääne standardaeg#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ida-Austraalia suveaeg#,
				'generic' => q#Ida-Austraalia aeg#,
				'standard' => q#Ida-Austraalia standardaeg#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Lääne-Austraalia suveaeg#,
				'generic' => q#Lääne-Austraalia aeg#,
				'standard' => q#Lääne-Austraalia standardaeg#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbaidžaani suveaeg#,
				'generic' => q#Aserbaidžaani aeg#,
				'standard' => q#Aserbaidžaani standardaeg#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Assooride suveaeg#,
				'generic' => q#Assooride aeg#,
				'standard' => q#Assooride standardaeg#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeshi suveaeg#,
				'generic' => q#Bangladeshi aeg#,
				'standard' => q#Bangladeshi standardaeg#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutani aeg#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliivia aeg#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiilia suveaeg#,
				'generic' => q#Brasiilia aeg#,
				'standard' => q#Brasiilia standardaeg#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei aeg#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Roheneemesaarte suveaeg#,
				'generic' => q#Roheneemesaarte aeg#,
				'standard' => q#Roheneemesaarte standardaeg#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey aeg#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Tšamorro standardaeg#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathami suveaeg#,
				'generic' => q#Chathami aeg#,
				'standard' => q#Chathami standardaeg#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Tšiili suveaeg#,
				'generic' => q#Tšiili aeg#,
				'standard' => q#Tšiili standardaeg#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hiina suveaeg#,
				'generic' => q#Hiina aeg#,
				'standard' => q#Hiina standardaeg#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tšojbalsani suveaeg#,
				'generic' => q#Tšojbalsani aeg#,
				'standard' => q#Tšojbalsani standardaeg#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Jõulusaare aeg#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kookossaarte aeg#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombia suveaeg#,
				'generic' => q#Colombia aeg#,
				'standard' => q#Colombia standardaeg#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cooki saarte osaline suveaeg#,
				'generic' => q#Cooki saarte aeg#,
				'standard' => q#Cooki saarte standardaeg#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuuba suveaeg#,
				'generic' => q#Kuuba aeg#,
				'standard' => q#Kuuba standardaeg#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davise aeg#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville’i aeg#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ida-Timori aeg#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Lihavõttesaare suveaeg#,
				'generic' => q#Lihavõttesaare aeg#,
				'standard' => q#Lihavõttesaare standardaeg#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadori aeg#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordineeritud maailmaaeg#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#määramata linn#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berliin#,
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
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhaagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Iiri suveaeg#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsingi#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mani saar#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#İstanbul#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Briti suveaeg#,
			},
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maarianhamina#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariis#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riia#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rooma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viin#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varssavi#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporožje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Kesk-Euroopa suveaeg#,
				'generic' => q#Kesk-Euroopa aeg#,
				'standard' => q#Kesk-Euroopa standardaeg#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ida-Euroopa suveaeg#,
				'generic' => q#Ida-Euroopa aeg#,
				'standard' => q#Ida-Euroopa standardaeg#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningradi ja Valgevene aeg#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Lääne-Euroopa suveaeg#,
				'generic' => q#Lääne-Euroopa aeg#,
				'standard' => q#Lääne-Euroopa standardaeg#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandi saarte suveaeg#,
				'generic' => q#Falklandi saarte aeg#,
				'standard' => q#Falklandi saarte standardaeg#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidži suveaeg#,
				'generic' => q#Fidži aeg#,
				'standard' => q#Fidži standardaeg#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Prantsuse Guajaana aeg#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Prantsuse Antarktiliste ja Lõunaalade aeg#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichi aeg#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagose aeg#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier’ aeg#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruusia suveaeg#,
				'generic' => q#Gruusia aeg#,
				'standard' => q#Gruusia standardaeg#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberti saarte aeg#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ida-Gröönimaa suveaeg#,
				'generic' => q#Ida-Gröönimaa aeg#,
				'standard' => q#Ida-Gröönimaa standardaeg#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Lääne-Gröönimaa suveaeg#,
				'generic' => q#Lääne-Gröönimaa aeg#,
				'standard' => q#Lääne-Gröönimaa standardaeg#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guami standardaeg#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Pärsia lahe standardaeg#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana aeg#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleuudi suveaeg#,
				'generic' => q#Hawaii-Aleuudi aeg#,
				'standard' => q#Hawaii-Aleuudi standardaeg#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongi suveaeg#,
				'generic' => q#Hongkongi aeg#,
				'standard' => q#Hongkongi standardaeg#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdi suveaeg#,
				'generic' => q#Hovdi aeg#,
				'standard' => q#Hovdi standardaeg#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India aeg#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Jõulusaar#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kookossaared#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiivid#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#India ookeani aeg#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indohiina aeg#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Kesk-Indoneesia aeg#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ida-Indoneesia aeg#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Lääne-Indoneesia aeg#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iraani suveaeg#,
				'generic' => q#Iraani aeg#,
				'standard' => q#Iraani standardaeg#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutski suveaeg#,
				'generic' => q#Irkutski aeg#,
				'standard' => q#Irkutski standardaeg#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Iisraeli suveaeg#,
				'generic' => q#Iisraeli aeg#,
				'standard' => q#Iisraeli standardaeg#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Jaapani suveaeg#,
				'generic' => q#Jaapani aeg#,
				'standard' => q#Jaapani standardaeg#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Kamtšatka suveaeg#,
				'generic' => q#Petropavlovsk-Kamtšatski aeg#,
				'standard' => q#Kamtšatka standardaeg#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ida-Kasahstani aeg#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Lääne-Kasahstani aeg#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korea suveaeg#,
				'generic' => q#Korea aeg#,
				'standard' => q#Korea standardaeg#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae aeg#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarski suveaeg#,
				'generic' => q#Krasnojarski aeg#,
				'standard' => q#Krasnojarski standardaeg#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kõrgõzstani aeg#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Sri Lanka aeg#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line’i saarte aeg#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe’i suveaeg#,
				'generic' => q#Lord Howe’i aeg#,
				'standard' => q#Lord Howe’i standardaeg#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macau suveaeg#,
				'generic' => q#Macau aeg#,
				'standard' => q#Macau standardaeg#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie saare aeg#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadani suveaeg#,
				'generic' => q#Magadani aeg#,
				'standard' => q#Magadani standardaeg#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaisia aeg#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiivi aeg#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiisaarte aeg#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalli Saarte aeg#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritiuse suveaeg#,
				'generic' => q#Mauritiuse aeg#,
				'standard' => q#Mauritiuse standardaeg#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsoni aeg#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Loode-Mehhiko suveaeg#,
				'generic' => q#Loode-Mehhiko aeg#,
				'standard' => q#Loode-Mehhiko standardaeg#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mehhiko Vaikse ookeani suveaeg#,
				'generic' => q#Mehhiko Vaikse ookeani aeg#,
				'standard' => q#Mehhiko Vaikse ookeani standardaeg#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatari suveaeg#,
				'generic' => q#Ulaanbaatari aeg#,
				'standard' => q#Ulaanbaatari standardaeg#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva suveaeg#,
				'generic' => q#Moskva aeg#,
				'standard' => q#Moskva standardaeg#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Birma aeg#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru aeg#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepali aeg#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Uus-Kaledoonia suveaeg#,
				'generic' => q#Uus-Kaledoonia aeg#,
				'standard' => q#Uus-Kaledoonia standardaeg#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Uus-Meremaa suveaeg#,
				'generic' => q#Uus-Meremaa aeg#,
				'standard' => q#Uus-Meremaa standardaeg#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlandi suveaeg#,
				'generic' => q#Newfoundlandi aeg#,
				'standard' => q#Newfoundlandi standardaeg#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue aeg#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolki saare suveaeg#,
				'generic' => q#Norfolki saare aeg#,
				'standard' => q#Norfolki saare standardaeg#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha suveaeg#,
				'generic' => q#Fernando de Noronha aeg#,
				'standard' => q#Fernando de Noronha standardaeg#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Põhja-Mariaani aeg#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirski suveaeg#,
				'generic' => q#Novosibirski aeg#,
				'standard' => q#Novosibirski standardaeg#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omski suveaeg#,
				'generic' => q#Omski aeg#,
				'standard' => q#Omski standardaeg#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Lihavõttesaar#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiisaared#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Belau#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistani suveaeg#,
				'generic' => q#Pakistani aeg#,
				'standard' => q#Pakistani standardaeg#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Belau aeg#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Paapua Uus-Guinea aeg#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay suveaeg#,
				'generic' => q#Paraguay aeg#,
				'standard' => q#Paraguay standardaeg#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruu suveaeg#,
				'generic' => q#Peruu aeg#,
				'standard' => q#Peruu standardaeg#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipiini suveaeg#,
				'generic' => q#Filipiini aeg#,
				'standard' => q#Filipiini standardaeg#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fööniksisaarte aeg#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre’i ja Miqueloni suveaeg#,
				'generic' => q#Saint-Pierre’i ja Miqueloni aeg#,
				'standard' => q#Saint-Pierre’i ja Miqueloni standardaeg#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairni aeg#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pohnpei aeg#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyangi aeg#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kõzõlorda suveaeg#,
				'generic' => q#Kõzõlorda aeg#,
				'standard' => q#Kõzõlorda standardaeg#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunioni aeg#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera aeg#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahhalini suveaeg#,
				'generic' => q#Sahhalini aeg#,
				'standard' => q#Sahhalini standardaeg#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara suveaeg#,
				'generic' => q#Samara aeg#,
				'standard' => q#Samara standardaeg#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa suveaeg#,
				'generic' => q#Samoa aeg#,
				'standard' => q#Samoa standardaeg#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seišelli aeg#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapuri standardaeg#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Saalomoni Saarte aeg#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Lõuna-Georgia aeg#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname aeg#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa aeg#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti aeg#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei suveaeg#,
				'generic' => q#Taipei aeg#,
				'standard' => q#Taipei standardaeg#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistani aeg#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau aeg#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga suveaeg#,
				'generic' => q#Tonga aeg#,
				'standard' => q#Tonga standardaeg#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuki aeg#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Türkmenistani suveaeg#,
				'generic' => q#Türkmenistani aeg#,
				'standard' => q#Türkmenistani standardaeg#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu aeg#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay suveaeg#,
				'generic' => q#Uruguay aeg#,
				'standard' => q#Uruguay standardaeg#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistani suveaeg#,
				'generic' => q#Usbekistani aeg#,
				'standard' => q#Usbekistani standardaeg#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu suveaeg#,
				'generic' => q#Vanuatu aeg#,
				'standard' => q#Vanuatu standardaeg#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela aeg#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostoki suveaeg#,
				'generic' => q#Vladivostoki aeg#,
				'standard' => q#Vladivostoki standardaeg#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradi suveaeg#,
				'generic' => q#Volgogradi aeg#,
				'standard' => q#Volgogradi standardaeg#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostoki aeg#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake’i aeg#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallise ja Futuna aeg#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutski suveaeg#,
				'generic' => q#Jakutski aeg#,
				'standard' => q#Jakutski standardaeg#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgi suveaeg#,
				'generic' => q#Jekaterinburgi aeg#,
				'standard' => q#Jekaterinburgi standardaeg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukoni aeg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
