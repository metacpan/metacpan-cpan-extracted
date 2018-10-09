=encoding utf8

=head1

Locale::CLDR::Locales::Et - Package for language Estonian

=cut

package Locale::CLDR::Locales::Et;
# This file auto generated from Data\common\main\et.xml
#	on Sun  7 Oct 10:30:18 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
		use bignum;
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
 				'anp' => 'angika',
 				'ar' => 'araabia',
 				'ar_001' => 'araabia (tänapäevane)',
 				'arc' => 'aramea',
 				'arn' => 'mapudunguni',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'Alžeeria araabia',
 				'arw' => 'aravaki',
 				'ary' => 'Maroko araabia',
 				'arz' => 'Egiptuse araabia',
 				'as' => 'assami',
 				'asa' => 'asu',
 				'ase' => 'Ameerika viipekeel',
 				'ast' => 'astuuria',
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
 				'bgn' => 'läänebelutši',
 				'bho' => 'bhodžpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikoli',
 				'bin' => 'edo',
 				'bjn' => 'bandžari',
 				'bkm' => 'komi (Aafrika)',
 				'bla' => 'mustjalaindiaani',
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
 				'ckb' => 'sorani',
 				'co' => 'korsika',
 				'cop' => 'kopti',
 				'cps' => 'kapisnoni',
 				'cr' => 'krii',
 				'crh' => 'krimmitatari',
 				'crs' => 'seišelli',
 				'cs' => 'tšehhi',
 				'csb' => 'kašuubi',
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
 				'en_GB@alt=short' => 'Briti inglise',
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
 				'he' => 'heebrea',
 				'hi' => 'hindi',
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
 				'hy' => 'armeenia',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'ibani',
 				'ibb' => 'ibibio',
 				'id' => 'indoneesia',
 				'ie' => 'interlingue',
 				'ig' => 'ibo',
 				'ii' => 'Sichuani jii',
 				'ik' => 'injupiaki',
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
 				'liv' => 'liivi',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardi',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'Louisiana kreoolkeel',
 				'loz' => 'lozi',
 				'lrc' => 'põhjaluri',
 				'lt' => 'leedu',
 				'ltg' => 'latgali',
 				'lu' => 'luba',
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
 				'non' => 'vanapõhjala',
 				'nov' => 'noviaal',
 				'nqo' => 'nkoo',
 				'nr' => 'lõunandebele',
 				'nso' => 'põhjasotho',
 				'nus' => 'nueri',
 				'nv' => 'navaho',
 				'nwc' => 'vananevari',
 				'ny' => 'njandža',
 				'nym' => 'njamvesi',
 				'nyn' => 'nkole',
 				'nyo' => 'njoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitaani',
 				'oj' => 'odžibvei',
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
 				'pl' => 'poola',
 				'pms' => 'piemonte',
 				'pnt' => 'pontose',
 				'pon' => 'poonpei',
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
 				'rif' => 'riifi',
 				'rm' => 'romanši',
 				'rn' => 'rundi',
 				'ro' => 'rumeenia',
 				'ro_MD' => 'moldova',
 				'rof' => 'rombo',
 				'rom' => 'mustlaskeel',
 				'root' => 'root',
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
 				'sl' => 'sloveeni',
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
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetumi',
 				'tg' => 'tadžiki',
 				'th' => 'tai',
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
 				'tpi' => 'uusmelaneesia',
 				'tr' => 'türgi',
 				'tru' => 'turojo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakoonia',
 				'tsi' => 'tšimši',
 				'tt' => 'tatari',
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
 				'vo' => 'volapüki',
 				'vot' => 'vadja',
 				'vro' => 'võru',
 				'vun' => 'vundžo',
 				'wa' => 'vallooni',
 				'wae' => 'walseri',
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
 				'za' => 'tšuangi',
 				'zap' => 'sapoteegi',
 				'zbl' => 'Blissi sümbolid',
 				'zea' => 'zeelandi',
 				'zen' => 'zenaga',
 				'zgh' => 'tamasikti (Maroko)',
 				'zh' => 'hiina',
 				'zh_Hans' => 'lihtsustatud hiina',
 				'zh_Hant' => 'traditsiooniline hiina',
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
			'Afak' => 'afaka',
 			'Aghb' => 'albaani',
 			'Ahom' => 'ahomi',
 			'Arab' => 'araabia',
 			'Arab@alt=variant' => 'pärsia-araabia',
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
 			'Cirt' => 'Cirthi',
 			'Copt' => 'kopti',
 			'Cprt' => 'Küprose silpkiri',
 			'Cyrl' => 'kirillitsa',
 			'Cyrs' => 'kürilliline kirikuslaavi',
 			'Deva' => 'devanaagari',
 			'Dsrt' => 'desereti',
 			'Dupl' => 'Duployé kiirkiri',
 			'Egyd' => 'egiptuse demootiline',
 			'Egyh' => 'egiptuse hieraatiline',
 			'Egyp' => 'egiptuse hieroglüüfkiri',
 			'Elba' => 'Elbasani',
 			'Ethi' => 'etioopia',
 			'Geok' => 'hutsuri',
 			'Geor' => 'gruusia',
 			'Glag' => 'glagoolitsa',
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
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmeeri',
 			'Khoj' => 'hodžki',
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
 			'Ugar' => 'ugariti',
 			'Vaii' => 'vai',
 			'Visp' => 'nähtava kõne',
 			'Wara' => 'hoo',
 			'Wole' => 'voleai',
 			'Xpeo' => 'vanapärsia',
 			'Xsux' => 'sumeri-akadi kiilkiri',
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
 			'BQ' => 'Hollandi Kariibi mere saared',
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
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Elevandiluurannik',
 			'CK' => 'Cooki saared',
 			'CL' => 'Tšiili',
 			'CM' => 'Kamerun',
 			'CN' => 'Hiina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertoni saar',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Roheneemesaared',
 			'CW' => 'Curaçao',
 			'CX' => 'Jõulusaar',
 			'CY' => 'Küpros',
 			'CZ' => 'Tšehhi',
 			'CZ@alt=variant' => 'Tšehhia',
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
 			'FK@alt=variant' => 'Malviini saared',
 			'FM' => 'Mikroneesia',
 			'FO' => 'Fääri saared',
 			'FR' => 'Prantsusmaa',
 			'GA' => 'Gabon',
 			'GB' => 'Suurbritannia',
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
 			'MK' => 'Makedoonia',
 			'MK@alt=variant' => 'Makedoonia Vabariik',
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
 			'UN' => 'Ühendatud Rahvaste Organisatsioon',
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
 			'XK' => 'Kosovo',
 			'YE' => 'Jeemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Lõuna-Aafrika Vabariik',
 			'ZM' => 'Sambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Tundmatu piirkond',

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
 			'collation' => 'sortimisjärjestus',
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
 				'islamic' => q{islamikalender},
 				'islamic-civil' => q{islami ilmalik kalender},
 				'islamic-rgsa' => q{islamikalender (Saudi Araabia, vaatluspõhine)},
 				'islamic-tbla' => q{islamikalender (tabulaarne, astronoomiline ajastu)},
 				'islamic-umalqura' => q{islamikalender (Umm al-Qura)},
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
 				'ducet' => q{Unicode’i sortimise vaikejärjestus},
 				'emoji' => q{emoji sortimisjärjestus},
 				'eor' => q{Euroopa järjestusreeglid},
 				'gb2312han' => q{hiina lihtsustatud sortimisjärjestus (GB2312)},
 				'phonebook' => q{telefoniraamatu sortimisjärjestus},
 				'phonetic' => q{foneetiline sortimisjärjestus},
 				'pinyin' => q{pinyin’i sortimisjärjestus},
 				'reformed' => q{reformitud sortimisjärjestus},
 				'search' => q{üldeesmärgiline otsing},
 				'searchjl' => q{otsing korea alguskonsonandi järgi},
 				'standard' => q{standardne sortimisjärjestus},
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
 				'ethi' => q{etioopia numbrid},
 				'finance' => q{finantsnumbrid},
 				'fullwide' => q{täislaiusega numbrid},
 				'geor' => q{gruusia numbrid},
 				'gonm' => q{masaram gondi numbrid},
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
 				'native' => q{kohalikud numbrid},
 				'nkoo' => q{nkoo numbrid},
 				'olck' => q{santali numbrid},
 				'orya' => q{oria numbrid},
 				'osma' => q{osmani numbrid},
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
 				'traditional' => q{traditsioonilised numbrid},
 				'vaii' => q{vai numbrid},
 				'wara' => q{hoo numbrid},
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
			auxiliary => qr{[á à â å ā æ ç é è ê ë ē í ì î ï ī ñ ó ò ŏ ô ø ō œ ú ù û ū]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Z', 'Ž', 'T', 'U', 'V', 'Õ', 'Ä', 'Ö', 'Ü', 'X', 'Y'],
			main => qr{[a b c d e f g h i j k l m n o p q r s š z ž t u v w õ ä ö ü x y]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- , ; \: ! ? . “ „ ( ) \[ \] \{ \} @]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Z', 'Ž', 'T', 'U', 'V', 'Õ', 'Ä', 'Ö', 'Ü', 'X', 'Y'], };
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
			'medial' => '{0} … {1}',
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
						'name' => q(aakrid),
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					'acre-foot' => {
						'name' => q(aakerjalad),
						'one' => q({0} aakerjalg),
						'other' => q({0} aakerjalga),
					},
					'ampere' => {
						'name' => q(amprid),
						'one' => q({0} amper),
						'other' => q({0} amprit),
					},
					'arc-minute' => {
						'name' => q(kaareminutid),
						'one' => q({0} kaareminut),
						'other' => q({0} kaareminutit),
					},
					'arc-second' => {
						'name' => q(kaaresekundid),
						'one' => q({0} kaaresekund),
						'other' => q({0} kaaresekundit),
					},
					'astronomical-unit' => {
						'name' => q(astronoomilised ühikud),
						'one' => q({0} astronoomiline ühik),
						'other' => q({0} astronoomilist ühikut),
					},
					'bit' => {
						'name' => q(bitid),
						'one' => q({0} bitt),
						'other' => q({0} bitti),
					},
					'bushel' => {
						'name' => q(buššelid),
						'one' => q({0} buššel),
						'other' => q({0} buššelit),
					},
					'byte' => {
						'name' => q(baidid),
						'one' => q({0} bait),
						'other' => q({0} baiti),
					},
					'calorie' => {
						'name' => q(kalorid),
						'one' => q({0} kalor),
						'other' => q({0} kalorit),
					},
					'carat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					'celsius' => {
						'name' => q(Celsiuse kraadid),
						'one' => q({0} Celsiuse kraad),
						'other' => q({0} Celsiuse kraadi),
					},
					'centiliter' => {
						'name' => q(sentiliitrid),
						'one' => q({0} sentiliiter),
						'other' => q({0} sentiliitrit),
					},
					'centimeter' => {
						'name' => q(sentimeetrid),
						'one' => q({0} sentimeeter),
						'other' => q({0} sentimeetrit),
						'per' => q({0} sentimeetri kohta),
					},
					'century' => {
						'name' => q(sajandid),
						'one' => q({0} sajand),
						'other' => q({0} sajandit),
					},
					'coordinate' => {
						'east' => q({0} idapikkust),
						'north' => q({0} põhjalaiust),
						'south' => q({0} lõunalaiust),
						'west' => q({0} läänepikkust),
					},
					'cubic-centimeter' => {
						'name' => q(kuupsentimeetrid),
						'one' => q({0} kuupsentimeeter),
						'other' => q({0} kuupsentimeetrit),
						'per' => q({0} kuupsentimeetri kohta),
					},
					'cubic-foot' => {
						'name' => q(kuupjalad),
						'one' => q({0} kuupjalg),
						'other' => q({0} kuupjalga),
					},
					'cubic-inch' => {
						'name' => q(kuuptollid),
						'one' => q({0} kuuptoll),
						'other' => q({0} kuuptolli),
					},
					'cubic-kilometer' => {
						'name' => q(kuupkilomeetrid),
						'one' => q({0} kuupkilomeeter),
						'other' => q({0} kuupkilomeetrit),
					},
					'cubic-meter' => {
						'name' => q(kuupmeetrid),
						'one' => q({0} kuupmeeter),
						'other' => q({0} kuupmeetrit),
						'per' => q({0} kuupmeetri kohta),
					},
					'cubic-mile' => {
						'name' => q(kuupmiilid),
						'one' => q({0} kuupmiil),
						'other' => q({0} kuupmiili),
					},
					'cubic-yard' => {
						'name' => q(kuupjardid),
						'one' => q({0} kuupjard),
						'other' => q({0} kuupjardi),
					},
					'cup' => {
						'name' => q(tassid),
						'one' => q({0} tass),
						'other' => q({0} tassi),
					},
					'cup-metric' => {
						'name' => q(meetrilised tassid),
						'one' => q({0} meetriline tass),
						'other' => q({0} meetrilist tassi),
					},
					'day' => {
						'name' => q(ööpäevad),
						'one' => q({0} ööpäev),
						'other' => q({0} ööpäeva),
						'per' => q({0} ööpäevas),
					},
					'deciliter' => {
						'name' => q(detsiliitrid),
						'one' => q({0} detsiliiter),
						'other' => q({0} detsiliitrit),
					},
					'decimeter' => {
						'name' => q(detsimeetrid),
						'one' => q({0} detsimeeter),
						'other' => q({0} detsimeetrit),
					},
					'degree' => {
						'name' => q(kraadid),
						'one' => q({0} kraad),
						'other' => q({0} kraadi),
					},
					'fahrenheit' => {
						'name' => q(Fahrenheiti kraadid),
						'one' => q({0} Fahrenheiti kraad),
						'other' => q({0} Fahrenheiti kraadi),
					},
					'fathom' => {
						'name' => q(süllad),
						'one' => q({0} süld),
						'other' => q({0} sülda),
					},
					'fluid-ounce' => {
						'name' => q(vedelikuuntsid),
						'one' => q({0} vedelikuunts),
						'other' => q({0} vedelikuuntsi),
					},
					'foodcalorie' => {
						'name' => q(toidukalorid),
						'one' => q({0} toidukalor),
						'other' => q({0} toidukalorit),
					},
					'foot' => {
						'name' => q(jalad),
						'one' => q({0} jalg),
						'other' => q({0} jalga),
						'per' => q({0} jala kohta),
					},
					'furlong' => {
						'name' => q(furlongid),
						'one' => q({0} furlong),
						'other' => q({0} furlongi),
					},
					'g-force' => {
						'name' => q(Maa raskuskiirendus),
						'one' => q({0} Maa raskuskiirendus),
						'other' => q({0} Maa raskuskiirendust),
					},
					'gallon' => {
						'name' => q(gallonid),
						'one' => q({0} gallon),
						'other' => q({0} gallonit),
						'per' => q({0} galloni kohta),
					},
					'gallon-imperial' => {
						'name' => q(inglise gallonid),
						'one' => q({0} inglise gallon),
						'other' => q({0} inglise gallonit),
						'per' => q({0} inglise galloni kohta),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabitid),
						'one' => q({0} gigabitt),
						'other' => q({0} gigabitti),
					},
					'gigabyte' => {
						'name' => q(gigabaidid),
						'one' => q({0} gigabait),
						'other' => q({0} gigabaiti),
					},
					'gigahertz' => {
						'name' => q(gigahertsid),
						'one' => q({0} gigaherts),
						'other' => q({0} gigahertsi),
					},
					'gigawatt' => {
						'name' => q(gigavatid),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatti),
					},
					'gram' => {
						'name' => q(grammid),
						'one' => q({0} gramm),
						'other' => q({0} grammi),
						'per' => q({0} grammi kohta),
					},
					'hectare' => {
						'name' => q(hektarid),
						'one' => q({0} hektar),
						'other' => q({0} hektarit),
					},
					'hectoliter' => {
						'name' => q(hektoliitrid),
						'one' => q({0} hektoliiter),
						'other' => q({0} hektoliitrit),
					},
					'hectopascal' => {
						'name' => q(hektopaskalid),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalit),
					},
					'hertz' => {
						'name' => q(hertsid),
						'one' => q({0} herts),
						'other' => q({0} hertsi),
					},
					'horsepower' => {
						'name' => q(hobujõud),
						'one' => q({0} hobujõud),
						'other' => q({0} hobujõudu),
					},
					'hour' => {
						'name' => q(tunnid),
						'one' => q({0} tund),
						'other' => q({0} tundi),
						'per' => q({0} tunnis),
					},
					'inch' => {
						'name' => q(tollid),
						'one' => q({0} toll),
						'other' => q({0} tolli),
						'per' => q({0} tolli kohta),
					},
					'inch-hg' => {
						'name' => q(tollid elavhõbedasammast),
						'one' => q({0} toll elavhõbedasammast),
						'other' => q({0} tolli elavhõbedasammast),
					},
					'joule' => {
						'name' => q(džaulid),
						'one' => q({0} džaul),
						'other' => q({0} džauli),
					},
					'karat' => {
						'name' => q(karaadid),
						'one' => q({0} karaat),
						'other' => q({0} karaati),
					},
					'kelvin' => {
						'name' => q(kelvinid),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinit),
					},
					'kilobit' => {
						'name' => q(kilobitid),
						'one' => q({0} kilobitt),
						'other' => q({0} kilobitti),
					},
					'kilobyte' => {
						'name' => q(kilobaidid),
						'one' => q({0} kilobait),
						'other' => q({0} kilobaiti),
					},
					'kilocalorie' => {
						'name' => q(kilokalorid),
						'one' => q({0} kilokalor),
						'other' => q({0} kilokalorit),
					},
					'kilogram' => {
						'name' => q(kilogrammid),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogrammi),
						'per' => q({0} kilogrammi kohta),
					},
					'kilohertz' => {
						'name' => q(kilohertsid),
						'one' => q({0} kiloherts),
						'other' => q({0} kilohertsi),
					},
					'kilojoule' => {
						'name' => q(kilodžaulid),
						'one' => q({0} kilodžaul),
						'other' => q({0} kilodžauli),
					},
					'kilometer' => {
						'name' => q(kilomeetrid),
						'one' => q({0} kilomeeter),
						'other' => q({0} kilomeetrit),
						'per' => q({0} kilomeetri kohta),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomeetrid tunnis),
						'one' => q({0} kilomeeter tunnis),
						'other' => q({0} kilomeetrit tunnis),
					},
					'kilowatt' => {
						'name' => q(kilovatid),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatti),
					},
					'kilowatt-hour' => {
						'name' => q(kilovatt-tunnid),
						'one' => q({0} kilovatt-tund),
						'other' => q({0} kilovatt-tundi),
					},
					'knot' => {
						'name' => q(sõlm),
						'one' => q({0} sõlm),
						'other' => q({0} sõlme),
					},
					'light-year' => {
						'name' => q(valgusaastad),
						'one' => q({0} valgusaasta),
						'other' => q({0} valgusaastat),
					},
					'liter' => {
						'name' => q(liitrid),
						'one' => q({0} liiter),
						'other' => q({0} liitrit),
						'per' => q({0} liitri kohta),
					},
					'liter-per-100kilometers' => {
						'name' => q(liitrid 100 kilomeetri kohta),
						'one' => q(liiter 100 kilomeetri kohta),
						'other' => q({0} liitrit 100 kilomeetri kohta),
					},
					'liter-per-kilometer' => {
						'name' => q(liitrid kilomeetri kohta),
						'one' => q({0} liiter kilomeetri kohta),
						'other' => q({0} liitrit kilomeetri kohta),
					},
					'lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksi),
					},
					'megabit' => {
						'name' => q(megabitid),
						'one' => q({0} megabitt),
						'other' => q({0} megabitti),
					},
					'megabyte' => {
						'name' => q(megabaidid),
						'one' => q({0} megabait),
						'other' => q({0} megabaiti),
					},
					'megahertz' => {
						'name' => q(megahertsid),
						'one' => q({0} megaherts),
						'other' => q({0} megahertsi),
					},
					'megaliter' => {
						'name' => q(megaliitrid),
						'one' => q({0} megaliiter),
						'other' => q({0} megaliitrit),
					},
					'megawatt' => {
						'name' => q(megavatid),
						'one' => q({0} megavatt),
						'other' => q({0} megavatti),
					},
					'meter' => {
						'name' => q(meetrid),
						'one' => q({0} meeter),
						'other' => q({0} meetrit),
						'per' => q({0} meetri kohta),
					},
					'meter-per-second' => {
						'name' => q(meetrid sekundis),
						'one' => q({0} meeter sekundis),
						'other' => q({0} meetrit sekundis),
					},
					'meter-per-second-squared' => {
						'name' => q(meetrid sekundi ruudu kohta),
						'one' => q({0} meeter sekundi ruudu kohta),
						'other' => q({0} meetrit sekundi ruudu kohta),
					},
					'metric-ton' => {
						'name' => q(tonnid),
						'one' => q({0} tonn),
						'other' => q({0} tonni),
					},
					'microgram' => {
						'name' => q(mikrogrammid),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogrammi),
					},
					'micrometer' => {
						'name' => q(mikromeetrid),
						'one' => q({0} mikromeeter),
						'other' => q({0} mikromeetrit),
					},
					'microsecond' => {
						'name' => q(mikrosekundid),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekundit),
					},
					'mile' => {
						'name' => q(miilid),
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					'mile-per-gallon' => {
						'name' => q(miilid galloni kohta),
						'one' => q({0} miil galloni kohta),
						'other' => q({0} miili galloni kohta),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miilid inglise galloni kohta),
						'one' => q({0} miil inglise galloni kohta),
						'other' => q({0} miili inglise galloni kohta),
					},
					'mile-per-hour' => {
						'name' => q(miilid tunnis),
						'one' => q({0} miil tunnis),
						'other' => q({0} miili tunnis),
					},
					'mile-scandinavian' => {
						'name' => q(Skandinaavia miilid),
						'one' => q({0} Skandinaavia miil),
						'other' => q({0} Skandinaavia miili),
					},
					'milliampere' => {
						'name' => q(milliamprid),
						'one' => q({0} milliamper),
						'other' => q({0} milliamprit),
					},
					'millibar' => {
						'name' => q(millibaarid),
						'one' => q({0} millibaar),
						'other' => q({0} millibaari),
					},
					'milligram' => {
						'name' => q(milligrammid),
						'one' => q({0} milligramm),
						'other' => q({0} milligrammi),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrammid detsiliitri kohta),
						'one' => q({0} milligramm detsiliitri kohta),
						'other' => q({0} milligrammi detsiliitri kohta),
					},
					'milliliter' => {
						'name' => q(milliliitrid),
						'one' => q({0} milliliiter),
						'other' => q({0} milliliitrit),
					},
					'millimeter' => {
						'name' => q(millimeetrid),
						'one' => q({0} millimeeter),
						'other' => q({0} millimeetrit),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeetrid elavhõbedasammast),
						'one' => q({0} millimeeter elavhõbedasammast),
						'other' => q({0} millimeetrit elavhõbedasammast),
					},
					'millimole-per-liter' => {
						'name' => q(millimoolid liitri kohta),
						'one' => q({0} millimool liitri kohta),
						'other' => q({0} millimooli liitri kohta),
					},
					'millisecond' => {
						'name' => q(millisekundid),
						'one' => q({0} millisekund),
						'other' => q({0} millisekundit),
					},
					'milliwatt' => {
						'name' => q(millivatid),
						'one' => q({0} millivatt),
						'other' => q({0} millivatti),
					},
					'minute' => {
						'name' => q(minutid),
						'one' => q({0} minut),
						'other' => q({0} minutit),
						'per' => q({0} minutis),
					},
					'month' => {
						'name' => q(kuud),
						'one' => q({0} kuu),
						'other' => q({0} kuud),
						'per' => q({0} kuus),
					},
					'nanometer' => {
						'name' => q(nanomeetrid),
						'one' => q({0} nanomeeter),
						'other' => q({0} nanomeetrit),
					},
					'nanosecond' => {
						'name' => q(nanosekundid),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekundit),
					},
					'nautical-mile' => {
						'name' => q(meremiilid),
						'one' => q({0} meremiil),
						'other' => q({0} meremiili),
					},
					'ohm' => {
						'name' => q(oomid),
						'one' => q({0} oom),
						'other' => q({0} oomi),
					},
					'ounce' => {
						'name' => q(untsid),
						'one' => q({0} unts),
						'other' => q({0} untsi),
						'per' => q({0} untsi kohta),
					},
					'ounce-troy' => {
						'name' => q(troiuntsid),
						'one' => q({0} troiunts),
						'other' => q({0} troiuntsi),
					},
					'parsec' => {
						'name' => q(parsekid),
						'one' => q({0} parsek),
						'other' => q({0} parsekit),
					},
					'part-per-million' => {
						'name' => q(osa miljoni kohta),
						'one' => q({0} osa miljoni kohta),
						'other' => q({0} osa miljoni kohta),
					},
					'per' => {
						'1' => q({0} {1} kohta),
					},
					'picometer' => {
						'name' => q(pikomeetrid),
						'one' => q({0} pikomeeter),
						'other' => q({0} pikomeetrit),
					},
					'pint' => {
						'name' => q(pindid),
						'one' => q({0} pint),
						'other' => q({0} pinti),
					},
					'pint-metric' => {
						'name' => q(meetrilised pindid),
						'one' => q({0} meetriline pint),
						'other' => q({0} meetrilist pinti),
					},
					'point' => {
						'name' => q(punktid),
						'one' => q({0} punkt),
						'other' => q({0} punkti),
					},
					'pound' => {
						'name' => q(naelad),
						'one' => q({0} nael),
						'other' => q({0} naela),
						'per' => q({0} naela kohta),
					},
					'pound-per-square-inch' => {
						'name' => q(naelad ruuttolli kohta),
						'one' => q({0} nael ruuttolli kohta),
						'other' => q({0} naela ruuttolli kohta),
					},
					'quart' => {
						'name' => q(kvardid),
						'one' => q({0} kvart),
						'other' => q({0} kvarti),
					},
					'radian' => {
						'name' => q(radiaanid),
						'one' => q({0} radiaan),
						'other' => q({0} radiaani),
					},
					'revolution' => {
						'name' => q(täispööre),
						'one' => q({0} täispööre),
						'other' => q({0} täispööret),
					},
					'second' => {
						'name' => q(sekundid),
						'one' => q({0} sekund),
						'other' => q({0} sekundit),
						'per' => q({0} sekundis),
					},
					'square-centimeter' => {
						'name' => q(ruutsentimeetrid),
						'one' => q({0} ruutsentimeeter),
						'other' => q({0} ruutsentimeetrit),
						'per' => q({0} ruutsentimeetri kohta),
					},
					'square-foot' => {
						'name' => q(ruutjalad),
						'one' => q({0} ruutjalg),
						'other' => q({0} ruutjalga),
					},
					'square-inch' => {
						'name' => q(ruuttollid),
						'one' => q({0} ruuttoll),
						'other' => q({0} ruuttolli),
						'per' => q({0} ruuttolli kohta),
					},
					'square-kilometer' => {
						'name' => q(ruutkilomeetrid),
						'one' => q({0} ruutkilomeeter),
						'other' => q({0} ruutkilomeetrit),
						'per' => q({0} ruutkilomeetri kohta),
					},
					'square-meter' => {
						'name' => q(ruutmeetrid),
						'one' => q({0} ruutmeeter),
						'other' => q({0} ruutmeetrit),
						'per' => q({0} ruutmeetri kohta),
					},
					'square-mile' => {
						'name' => q(ruutmiilid),
						'one' => q({0} ruutmiil),
						'other' => q({0} ruutmiili),
						'per' => q({0} ruutmiili kohta),
					},
					'square-yard' => {
						'name' => q(ruutjardid),
						'one' => q({0} ruutjard),
						'other' => q({0} ruutjardi),
					},
					'stone' => {
						'name' => q(kivid),
						'one' => q({0} kivi),
						'other' => q({0} kivi),
					},
					'tablespoon' => {
						'name' => q(supilusikad),
						'one' => q({0} supilusikas),
						'other' => q({0} supilusikat),
					},
					'teaspoon' => {
						'name' => q(teelusikad),
						'one' => q({0} teelusikas),
						'other' => q({0} teelusikat),
					},
					'terabit' => {
						'name' => q(terabitid),
						'one' => q({0} terabitt),
						'other' => q({0} terabitti),
					},
					'terabyte' => {
						'name' => q(terabaidid),
						'one' => q({0} terabait),
						'other' => q({0} terabaiti),
					},
					'ton' => {
						'name' => q(lühikesed tonnid),
						'one' => q({0} lühike tonn),
						'other' => q({0} lühikest tonni),
					},
					'volt' => {
						'name' => q(voldid),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					'watt' => {
						'name' => q(vatid),
						'one' => q({0} vatt),
						'other' => q({0} vatti),
					},
					'week' => {
						'name' => q(nädalad),
						'one' => q({0} nädal),
						'other' => q({0} nädalat),
						'per' => q({0} nädalas),
					},
					'yard' => {
						'name' => q(jardid),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					'year' => {
						'name' => q(aastad),
						'one' => q({0} aasta),
						'other' => q({0} aastat),
						'per' => q({0} aastas),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} aaker),
						'other' => q({0} aakrit),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(aü),
						'one' => q({0} aü),
						'other' => q({0} aü),
					},
					'byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(päev),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'name' => q(süllad),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} jalg),
						'other' => q({0} jalga),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlongid),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(Maa raskuskiirendus),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} hj),
						'other' => q({0} hj),
					},
					'hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'inch' => {
						'name' => q(tollid),
						'one' => q({0} toll),
						'other' => q({0} tolli),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(″ Hg),
						'one' => q({0} toll Hg),
						'other' => q({0} tolli Hg),
					},
					'karat' => {
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(valgusaastad),
						'one' => q({0} valgusa.),
						'other' => q({0} valgusa.),
					},
					'liter' => {
						'name' => q(liiter),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} miil),
						'other' => q({0} miili),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(kuud),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsekid),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(naelad),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'stone' => {
						'name' => q(kivid),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'ton' => {
						'name' => q(lüh t),
						'one' => q({0} lüh t),
						'other' => q({0} lüh t),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(n),
						'one' => q({0} n),
						'other' => q({0} n),
					},
					'yard' => {
						'name' => q(jardid),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					'year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(aakrid),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(aakerjalg),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amprid),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(kaareminut),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(aü),
						'one' => q({0} aü),
						'other' => q({0} aü),
					},
					'bit' => {
						'name' => q(bitt),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'bushel' => {
						'name' => q(buššelid),
					},
					'byte' => {
						'name' => q(bait),
						'one' => q({0} bait),
						'other' => q({0} baiti),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(saj),
						'one' => q({0} saj),
						'other' => q({0} saj),
					},
					'coordinate' => {
						'east' => q({0} ip),
						'north' => q({0} pl),
						'south' => q({0} ll),
						'west' => q({0} lp),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(kuuptollid),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(kuupmiilid),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(kuupjardid),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(tass),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(päevad),
						'one' => q({0} päev),
						'other' => q({0} päeva),
						'per' => q({0}/ööp),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(kraadid),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'name' => q(süllad),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlongid),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(Maa raskuskiirendus),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(grammid),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektarid),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hj),
						'one' => q({0} hj),
						'other' => q({0} hj),
					},
					'hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					'inch' => {
						'name' => q(tollid),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
					},
					'joule' => {
						'name' => q(džaulid),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-tund),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(valgusaastad),
						'one' => q({0} valgusa.),
						'other' => q({0} valgusa.),
					},
					'liter' => {
						'name' => q(liitrid),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(miil/gallon),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miil/gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(milliamprid),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(kuud),
						'one' => q({0} kuu),
						'other' => q({0} kuud),
						'per' => q({0}/k),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(oomid),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsekid),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(osa/miljon),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pindid),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(punktid),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(naelad),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radiaanid),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(pööre),
						'one' => q({0} pööre),
						'other' => q({0} pööret),
					},
					'second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ruutjalad),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(ruuttollid),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(ruutjardid),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(kivid),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(spl),
						'one' => q({0} spl),
						'other' => q({0} spl),
					},
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(lüh t),
						'one' => q({0} lüh t),
						'other' => q({0} lüh t),
					},
					'volt' => {
						'name' => q(voldid),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(vatid),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(näd),
						'one' => q({0} näd),
						'other' => q({0} näd),
						'per' => q({0}/näd),
					},
					'yard' => {
						'name' => q(jardid),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(aastad),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
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
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
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
					'one' => '0 trl',
					'other' => '0 trl',
				},
				'10000000000000' => {
					'one' => '00 trl',
					'other' => '00 trl',
				},
				'100000000000000' => {
					'one' => '000 trl',
					'other' => '000 trl',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
					'one' => '0 trl',
					'other' => '0 trl',
				},
				'10000000000000' => {
					'one' => '00 trl',
					'other' => '00 trl',
				},
				'100000000000000' => {
					'one' => '000 trl',
					'other' => '000 trl',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
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
			symbol => 'AED',
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
			symbol => 'AFN',
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
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albaania lekk),
				'one' => q(Albaania lekk),
				'other' => q(Albaania lekki),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armeenia dramm),
				'one' => q(Armeenia dramm),
				'other' => q(Armeenia drammi),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Hollandi Antillide kulden),
				'one' => q(Hollandi Antillide kulden),
				'other' => q(Hollandi Antillide kuldnat),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
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
			symbol => 'AZN',
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
			symbol => 'BAM',
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
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbadose dollar),
				'one' => q(Barbadose dollar),
				'other' => q(Barbadose dollarit),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
			symbol => 'BGN',
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
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahreini dinaar),
				'one' => q(Bahreini dinaar),
				'other' => q(Bahreini dinaari),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi frank),
				'one' => q(Burundi frank),
				'other' => q(Burundi franki),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda dollar),
				'one' => q(Bermuda dollar),
				'other' => q(Bermuda dollarit),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunei dollar),
				'one' => q(Brunei dollar),
				'other' => q(Brunei dollarit),
			},
		},
		'BOB' => {
			symbol => 'BOB',
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
			symbol => 'R$',
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
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahama dollar),
				'one' => q(Bahama dollar),
				'other' => q(Bahama dollarit),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
			symbol => 'BWP',
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
			symbol => 'BYN',
			display_name => {
				'currency' => q(Valgevene rubla),
				'one' => q(Valgevene rubla),
				'other' => q(Valgevene rubla),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Valgevene rubla \(2000–2016\)),
				'one' => q(Valgevene rubla \(2000–2016\)),
				'other' => q(Valgevene rubla \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belize’i dollar),
				'one' => q(Belize’i dollar),
				'other' => q(Belize’i dollarit),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada dollar),
				'one' => q(Kanada dollar),
				'other' => q(Kanada dollarit),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongo frank),
				'one' => q(Kongo frank),
				'other' => q(Kongo franki),
			},
		},
		'CHF' => {
			symbol => 'CHF',
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
			symbol => 'CLP',
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
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Hiina jüaan),
				'one' => q(Hiina jüaan),
				'other' => q(Hiina jüaani),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Colombia peeso),
				'one' => q(Colombia peeso),
				'other' => q(Colombia peesot),
			},
		},
		'CRC' => {
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuuba konverteeritav peeso),
				'one' => q(Kuuba konverteeritav peeso),
				'other' => q(Kuuba konverteeritavat peesot),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuuba peeso),
				'one' => q(Kuuba peeso),
				'other' => q(Kuuba peesot),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(Djibouti frank),
				'one' => q(Djibouti frank),
				'other' => q(Djibouti franki),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Taani kroon),
				'one' => q(Taani kroon),
				'other' => q(Taani krooni),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikaani peeso),
				'one' => q(Dominikaani peeso),
				'other' => q(Dominikaani peesot),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egiptuse nael),
				'one' => q(Egiptuse nael),
				'other' => q(Egiptuse naela),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
			display_name => {
				'currency' => q(Etioopia birr),
				'one' => q(Etioopia birr),
				'other' => q(Etioopia birri),
			},
		},
		'EUR' => {
			symbol => '€',
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fidži dollar),
				'one' => q(Fidži dollar),
				'other' => q(Fidži dollarit),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
			symbol => '£',
			display_name => {
				'currency' => q(Suurbritannia naelsterling),
				'one' => q(Suurbritannia naelsterling),
				'other' => q(Suurbritannia naelsterlingit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Gruusia lari),
				'one' => q(Gruusia lari),
				'other' => q(Gruusia lari),
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ghana sedi),
				'one' => q(Ghana sedi),
				'other' => q(Ghana sedit),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltari nael),
				'one' => q(Gibraltari nael),
				'other' => q(Gibraltari naela),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambia dalasi),
				'one' => q(Gambia dalasi),
				'other' => q(Gambia dalasit),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyana dollar),
				'one' => q(Guyana dollar),
				'other' => q(Guyana dollarit),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hongkongi dollar),
				'one' => q(Hongkongi dollar),
				'other' => q(Hongkongi dollarit),
			},
		},
		'HNL' => {
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(Horvaatia kuna),
				'one' => q(Horvaatia kuna),
				'other' => q(Horvaatia kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haiti gurd),
				'one' => q(Haiti gurd),
				'other' => q(Haiti gurdi),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Ungari forint),
				'one' => q(Ungari forint),
				'other' => q(Ungari forintit),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
			display_name => {
				'currency' => q(Iisraeli uus seekel),
				'one' => q(Iisraeli uus seekel),
				'other' => q(Iisraeli uut seeklit),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(India ruupia),
				'one' => q(India ruupia),
				'other' => q(India ruupiat),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Iraagi dinaar),
				'one' => q(Iraagi dinaar),
				'other' => q(Iraagi dinaari),
			},
		},
		'IRR' => {
			symbol => 'IRR',
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
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaica dollar),
				'one' => q(Jamaica dollar),
				'other' => q(Jamaica dollarit),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(Keenia šilling),
				'one' => q(Keenia šilling),
				'other' => q(Keenia šillingit),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kõrgõzstani somm),
				'one' => q(Kõrgõzstani somm),
				'other' => q(Kõrgõzstani sommi),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodža riaal),
				'one' => q(Kambodža riaal),
				'other' => q(Kambodža riaali),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komoori frank),
				'one' => q(Komoori frank),
				'other' => q(Komoori franki),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => '₩',
			display_name => {
				'currency' => q(Lõuna-Korea vonn),
				'one' => q(Lõuna-Korea vonn),
				'other' => q(Lõuna-Korea vonni),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuveidi dinaar),
				'one' => q(Kuveidi dinaar),
				'other' => q(Kuveidi dinaari),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kaimanisaarte dollar),
				'one' => q(Kaimanisaarte dollar),
				'other' => q(Kaimanisaarte dollarit),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kasahstani tenge),
				'one' => q(Kasahstani tenge),
				'other' => q(Kasahstani tenget),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laose kiip),
				'one' => q(Laose kiip),
				'other' => q(Laose kiipi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Liibanoni nael),
				'one' => q(Liibanoni nael),
				'other' => q(Liibanoni naela),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lanka ruupia),
				'one' => q(Sri Lanka ruupia),
				'other' => q(Sri Lanka ruupiat),
			},
		},
		'LRD' => {
			symbol => 'LRD',
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
			symbol => 'LTL',
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
			symbol => 'LVL',
			display_name => {
				'currency' => q(Läti latt),
				'one' => q(Läti latt),
				'other' => q(Läti latti),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Läti rubla),
				'one' => q(Läti rubla),
				'other' => q(Läti rubla),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Liibüa dinaar),
				'one' => q(Liibüa dinaar),
				'other' => q(Liibüa dinaari),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldova leu),
				'one' => q(Moldova leu),
				'other' => q(Moldova leud),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Madagaskari ariari),
				'one' => q(Madagaskari ariari),
				'other' => q(Madagaskari ariarit),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskar frank),
				'one' => q(Madagaskar frank),
				'other' => q(Madagaskar franki),
			},
		},
		'MKD' => {
			symbol => 'MKD',
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmari kjatt),
				'one' => q(Myanmari kjatt),
				'other' => q(Myanmari kjatti),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongoolia tugrik),
				'one' => q(Mongoolia tugrik),
				'other' => q(Mongoolia tugrikut),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Macau pataaka),
				'one' => q(Macau pataaka),
				'other' => q(Macau pataakat),
			},
		},
		'MRO' => {
			symbol => 'MRO',
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
			symbol => 'MUR',
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
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldiivi ruupia),
				'one' => q(Maldiivi ruupia),
				'other' => q(Maldiivi ruupiat),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malawi kvatša),
				'one' => q(Malawi kvatša),
				'other' => q(Malawi kvatšat),
			},
		},
		'MXN' => {
			symbol => 'MX$',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mosambiigi metikal),
				'one' => q(Mosambiigi metikal),
				'other' => q(Mosambiigi metikali),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namiibia dollar),
				'one' => q(Namiibia dollar),
				'other' => q(Namiibia dollarit),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nicaragua kordoba),
				'one' => q(Nicaragua kordoba),
				'other' => q(Nicaragua kordobad),
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norra kroon),
				'one' => q(Norra kroon),
				'other' => q(Norra krooni),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepali ruupia),
				'one' => q(Nepali ruupia),
				'other' => q(Nepali ruupiat),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Uus-Meremaa dollar),
				'one' => q(Uus-Meremaa dollar),
				'other' => q(Uus-Meremaa dollarit),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omaani riaal),
				'one' => q(Omaani riaal),
				'other' => q(Omaani riaali),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
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
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistani ruupia),
				'one' => q(Pakistani ruupia),
				'other' => q(Pakistani ruupiat),
			},
		},
		'PLN' => {
			symbol => 'PLN',
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguay guaranii),
				'one' => q(Paraguay guaranii),
				'other' => q(Paraguay guaraniid),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumeenia leu),
				'one' => q(Rumeenia leu),
				'other' => q(Rumeenia leud),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbia dinaar),
				'one' => q(Serbia dinaar),
				'other' => q(Serbia dinaari),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Venemaa rubla),
				'one' => q(Venemaa rubla),
				'other' => q(Venemaa rubla),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Venemaa rubla \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Rwanda frank),
				'one' => q(Rwanda frank),
				'other' => q(Rwanda franki),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudi Araabia riaal),
				'one' => q(Saudi Araabia riaal),
				'other' => q(Saudi Araabia riaali),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Saalomoni Saarte dollar),
				'one' => q(Saalomoni Saarte dollar),
				'other' => q(Saalomoni Saarte dollarit),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(Rootsi kroon),
				'one' => q(Rootsi kroon),
				'other' => q(Rootsi krooni),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapuri dollar),
				'one' => q(Singapuri dollar),
				'other' => q(Singapuri dollarit),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra Leone leoone),
				'one' => q(Sierra Leone leoone),
				'other' => q(Sierra Leone leoonet),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somaalia šilling),
				'one' => q(Somaalia šilling),
				'other' => q(Somaalia šillingit),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(Lõuna-Sudaani nael),
				'one' => q(Lõuna-Sudaani nael),
				'other' => q(Lõuna-Sudaani naela),
			},
		},
		'STD' => {
			symbol => 'STD',
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(Süüria nael),
				'one' => q(Süüria nael),
				'other' => q(Süüria naela),
			},
		},
		'SZL' => {
			symbol => 'SZL',
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
				'one' => q(Tadžikistani rubla),
				'other' => q(Tadžikistani rubla),
			},
		},
		'TJS' => {
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(Türkmenistani manat),
				'one' => q(Türkmenistani manat),
				'other' => q(Türkmenistani manatit),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tuneesia dinaar),
				'one' => q(Tuneesia dinaar),
				'other' => q(Tuneesia dinaari),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(Türgi liir),
				'one' => q(Türgi liir),
				'other' => q(Türgi liiri),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tansaania šilling),
				'one' => q(Tansaania šilling),
				'other' => q(Tansaania šillingit),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguay peeso),
				'one' => q(Uruguay peeso),
				'other' => q(Uruguay peesot),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezuela boliivar),
				'one' => q(Venezuela boliivar),
				'other' => q(Venezuela boliivarit),
			},
		},
		'VND' => {
			symbol => '₫',
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
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatu vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatut),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoa taala),
				'one' => q(Samoa taala),
				'other' => q(Samoa taalat),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
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
			symbol => 'EC$',
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
			symbol => 'CFA',
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
			symbol => 'CFPF',
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
			symbol => 'YER',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
					narrow => {
						mon => 'E',
						tue => 'T',
						wed => 'K',
						thu => 'N',
						fri => 'R',
						sat => 'L',
						sun => 'P'
					},
					short => {
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
					abbreviated => {
						mon => 'E',
						tue => 'T',
						wed => 'K',
						thu => 'N',
						fri => 'R',
						sat => 'L',
						sun => 'P'
					},
					narrow => {
						mon => 'E',
						tue => 'T',
						wed => 'K',
						thu => 'N',
						fri => 'R',
						sat => 'L',
						sun => 'P'
					},
					short => {
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
					},
					wide => {0 => '1. kvartal',
						1 => '2. kvartal',
						2 => '3. kvartal',
						3 => '4. kvartal'
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
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
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
					'evening1' => q{õhtul},
					'am' => q{AM},
					'night1' => q{öösel},
					'morning1' => q{hommikul},
					'midnight' => q{keskööl},
					'afternoon1' => q{pärastlõunal},
					'noon' => q{keskpäeval},
					'pm' => q{PM},
				},
				'narrow' => {
					'pm' => q{PM},
					'noon' => q{keskpäeval},
					'midnight' => q{keskööl},
					'afternoon1' => q{pärastlõunal},
					'morning1' => q{hommikul},
					'night1' => q{öösel},
					'am' => q{AM},
					'evening1' => q{õhtul},
				},
				'wide' => {
					'evening1' => q{õhtul},
					'am' => q{AM},
					'morning1' => q{hommikul},
					'night1' => q{öösel},
					'midnight' => q{keskööl},
					'afternoon1' => q{pärastlõunal},
					'noon' => q{keskpäeval},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pärastlõuna},
					'midnight' => q{kesköö},
					'noon' => q{keskpäev},
					'pm' => q{PM},
					'evening1' => q{õhtu},
					'am' => q{AM},
					'morning1' => q{hommik},
					'night1' => q{öö},
				},
				'wide' => {
					'am' => q{AM},
					'evening1' => q{õhtu},
					'night1' => q{öö},
					'morning1' => q{hommik},
					'afternoon1' => q{pärastlõuna},
					'midnight' => q{kesköö},
					'pm' => q{PM},
					'noon' => q{keskpäev},
				},
				'narrow' => {
					'morning1' => q{hommik},
					'night1' => q{öö},
					'am' => q{AM},
					'evening1' => q{õhtu},
					'pm' => q{PM},
					'noon' => q{keskpäev},
					'midnight' => q{kesköö},
					'afternoon1' => q{pärastlõuna},
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
			narrow => {
				'0' => 'BK'
			},
			wide => {
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
			narrow => {
				'0' => 'eKr',
				'1' => 'pKr'
			},
			wide => {
				'0' => 'enne Kristust',
				'1' => 'pärast Kristust'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'AM'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'AH'
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
		'hebrew' => {
		},
		'islamic' => {
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
		'hebrew' => {
		},
		'islamic' => {
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
			'full' => q{{1}, 'kell' {0}},
			'long' => q{{1}, 'kell' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{H:mm.ss},
			M => q{M},
			MEd => q{E, d.M},
			MMM => q{MMMM},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm.ss a},
			mmss => q{mm.ss},
			ms => q{mm.ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{M},
			MEd => q{E, d.M},
			MMM => q{MMMM},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{MMM (W. 'nädal')},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
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
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y–MM.y G},
				y => q{MM.y–MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y G},
				d => q{dd.MM.y–dd.MM.y G},
				y => q{dd.MM.y–dd.MM.y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. MMM – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
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
					'wide' => {
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
		gmtZeroFormat => q(GMT),
		regionFormat => q(({0})),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
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
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžiir#,
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
			exemplarCity => q#Kairo#,
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
			exemplarCity => q#Hartum#,
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
			exemplarCity => q#N’Djamena#,
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
			exemplarCity => q#São Tomé#,
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
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
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
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
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
			exemplarCity => q#Belém#,
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
			exemplarCity => q#Bogotá#,
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
			exemplarCity => q#Cancún#,
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
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
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
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
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
			exemplarCity => q#Havanna#,
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
			exemplarCity => q#Maceió#,
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
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#México#,
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
			exemplarCity => q#Beulah, Põhja-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Põhja-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Põhja-Dakota#,
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
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
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
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatõ#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
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
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tšita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tšojbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
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
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
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
			exemplarCity => q#Jeruusalemm#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtšatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
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
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuveit#,
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
			exemplarCity => q#Masqaţ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
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
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kõzõlorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ar-Riyāḑ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolõmsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
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
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tōkyō#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
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
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
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
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Iiri suveaeg#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
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
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Briti suveaeg#,
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
			exemplarCity => q#Maarianhamina#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariis#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
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
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
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
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viin#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varssavi#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Jõulusaar#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kookossaared#,
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
			exemplarCity => q#Maldiivid#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'standard' => q#Malaisia ​​aeg#,
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
				'standard' => q#Norfolki saarte aeg#,
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
			exemplarCity => q#Lihavõttesaar#,
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
			exemplarCity => q#Fidži#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
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
			exemplarCity => q#Markiisaared#,
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
			exemplarCity => q#Belau#,
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
				'daylight' => q#Jakaterinburgi suveaeg#,
				'generic' => q#Jakaterinburgi aeg#,
				'standard' => q#Jekaterinburgi standardaeg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
