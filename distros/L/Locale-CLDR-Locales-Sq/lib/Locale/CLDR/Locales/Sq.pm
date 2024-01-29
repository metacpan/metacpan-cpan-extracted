=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sq - Package for language Albanian

=cut

package Locale::CLDR::Locales::Sq;
# This file auto generated from Data\common\main\sq.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← presje →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(një),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dy),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(njëzet[ e →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tridhjetë[ e →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(dyzet[ e →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←%spellout-cardinal-feminine←dhjetë[ e →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←qind[ e →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mijë[ e →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(një milion[ e →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milionë[ e →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(një miliar[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← miliarë[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(një bilion[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← bilionë[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(një biliar[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← biliarë[ e →→]),
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
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← presje →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(një),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dy),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(katër),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pesë),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(gjashtë),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(shtatë),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tetë),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nëntë),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dhjetë),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→%spellout-cardinal-masculine→mbëdhjetë),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(njëzet[ e →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tridhjetë[ e →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(dyzet[ e →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←%spellout-cardinal-feminine←dhjetë[ e →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←qind[ e →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mijë[ e →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(një milion[ e →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milionë[ e →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(një miliar[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← miliarë[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(një bilion[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← bilionë[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(një biliar[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← biliarë[ e →→]),
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
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
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
				'aa' => 'afarisht',
 				'ab' => 'abkazisht',
 				'ace' => 'akinezisht',
 				'ada' => 'andangmeisht',
 				'ady' => 'adigisht',
 				'af' => 'afrikanisht',
 				'agq' => 'agemisht',
 				'ain' => 'ajnuisht',
 				'ak' => 'akanisht',
 				'ale' => 'aleutisht',
 				'alt' => 'altaishte jugore',
 				'am' => 'amarisht',
 				'an' => 'aragonezisht',
 				'anp' => 'angikisht',
 				'ar' => 'arabisht',
 				'ar_001' => 'arabishte standarde moderne',
 				'arn' => 'mapuçisht',
 				'arp' => 'arapahoisht',
 				'as' => 'asamezisht',
 				'asa' => 'asuisht',
 				'ast' => 'asturisht',
 				'av' => 'avarikisht',
 				'awa' => 'auadhisht',
 				'ay' => 'ajmarisht',
 				'az' => 'azerbajxhanisht',
 				'az@alt=short' => 'azerisht',
 				'ba' => 'bashkirisht',
 				'ban' => 'balinezisht',
 				'bas' => 'basaisht',
 				'be' => 'bjellorusisht',
 				'bem' => 'bembaisht',
 				'bez' => 'benaisht',
 				'bg' => 'bullgarisht',
 				'bgn' => 'balokishte perëndimore',
 				'bho' => 'boxhpurisht',
 				'bi' => 'bislamisht',
 				'bin' => 'binisht',
 				'bla' => 'siksikaisht',
 				'bm' => 'bambarisht',
 				'bn' => 'bengalisht',
 				'bo' => 'tibetisht',
 				'br' => 'bretonisht',
 				'brx' => 'bodoisht',
 				'bs' => 'boshnjakisht',
 				'bug' => 'buginezisht',
 				'byn' => 'blinisht',
 				'ca' => 'katalonisht',
 				'ccp' => 'çakmaisht',
 				'ce' => 'çeçenisht',
 				'ceb' => 'sebuanisht',
 				'cgg' => 'çigisht',
 				'ch' => 'kamoroisht',
 				'chk' => 'çukezisht',
 				'chm' => 'marisht',
 				'cho' => 'çoktauisht',
 				'chr' => 'çerokisht',
 				'chy' => 'çejenisht',
 				'ckb' => 'kurdishte qendrore',
 				'co' => 'korsikisht',
 				'crs' => 'frëngjishte kreole seselve',
 				'cs' => 'çekisht',
 				'cu' => 'sllavishte kishtare',
 				'cv' => 'çuvashisht',
 				'cy' => 'uellsisht',
 				'da' => 'danisht',
 				'dak' => 'dakotisht',
 				'dar' => 'darguaisht',
 				'dav' => 'tajtaisht',
 				'de' => 'gjermanisht',
 				'de_AT' => 'gjermanishte austriake',
 				'de_CH' => 'gjermanishte zvicerane (dialekti i Alpeve)',
 				'dgr' => 'dogribisht',
 				'dje' => 'zarmaisht',
 				'doi' => 'dogrisht',
 				'dsb' => 'sorbishte e poshtme',
 				'dua' => 'dualaisht',
 				'dv' => 'divehisht',
 				'dyo' => 'xhulafonjisht',
 				'dz' => 'xhongaisht',
 				'dzg' => 'dazagauisht',
 				'ebu' => 'embuisht',
 				'ee' => 'eveisht',
 				'efi' => 'efikisht',
 				'eka' => 'ekajukisht',
 				'el' => 'greqisht',
 				'en' => 'anglisht',
 				'en_AU' => 'anglishte australiane',
 				'en_CA' => 'anglishte kanadeze',
 				'en_GB' => 'anglishte britanike',
 				'en_GB@alt=short' => 'anglishte e Mbretërisë së Bashkuar',
 				'en_US' => 'anglishte amerikane',
 				'en_US@alt=short' => 'anglishte e SHBA-së',
 				'eo' => 'esperanto',
 				'es' => 'spanjisht',
 				'es_419' => 'spanjishte amerikano-latine',
 				'es_ES' => 'spanjishte evropiane',
 				'es_MX' => 'spanjishte meksikane',
 				'et' => 'estonisht',
 				'eu' => 'baskisht',
 				'ewo' => 'euondoisht',
 				'fa' => 'persisht',
 				'fa_AF' => 'darisht',
 				'ff' => 'fulaisht',
 				'fi' => 'finlandisht',
 				'fil' => 'filipinisht',
 				'fj' => 'fixhianisht',
 				'fo' => 'faroisht',
 				'fon' => 'fonisht',
 				'fr' => 'frëngjisht',
 				'fr_CA' => 'frëngjishte kanadeze',
 				'fr_CH' => 'frëngjishte zvicerane',
 				'frc' => 'frëngjishte kajune',
 				'fur' => 'friulianisht',
 				'fy' => 'frizianishte perëndimore',
 				'ga' => 'irlandisht',
 				'gaa' => 'gaisht',
 				'gag' => 'gagauzisht',
 				'gd' => 'galishte skoceze',
 				'gez' => 'gizisht',
 				'gil' => 'gilbertazisht',
 				'gl' => 'galicisht',
 				'gn' => 'guaranisht',
 				'gor' => 'gorontaloisht',
 				'gsw' => 'gjermanishte zvicerane',
 				'gu' => 'guxharatisht',
 				'guz' => 'gusisht',
 				'gv' => 'manksisht',
 				'gwi' => 'guiçinisht',
 				'ha' => 'hausisht',
 				'haw' => 'havaisht',
 				'he' => 'hebraisht',
 				'hi' => 'indisht',
 				'hil' => 'hiligajnonisht',
 				'hmn' => 'hmongisht',
 				'hr' => 'kroatisht',
 				'hsb' => 'sorbishte e sipërme',
 				'ht' => 'haitisht',
 				'hu' => 'hungarisht',
 				'hup' => 'hupaisht',
 				'hy' => 'armenisht',
 				'hz' => 'hereroisht',
 				'ia' => 'interlingua',
 				'iba' => 'ibanisht',
 				'ibb' => 'ibibioisht',
 				'id' => 'indonezisht',
 				'ie' => 'gjuha oksidentale',
 				'ig' => 'igboisht',
 				'ii' => 'sishuanisht',
 				'ilo' => 'ilokoisht',
 				'inh' => 'ingushisht',
 				'io' => 'idoisht',
 				'is' => 'islandisht',
 				'it' => 'italisht',
 				'iu' => 'inuktitutisht',
 				'ja' => 'japonisht',
 				'jbo' => 'lojbanisht',
 				'jgo' => 'ngombisht',
 				'jmc' => 'maçamisht',
 				'jv' => 'javanisht',
 				'ka' => 'gjeorgjisht',
 				'kab' => 'kabilisht',
 				'kac' => 'kaçinisht',
 				'kaj' => 'kajeisht',
 				'kam' => 'kambaisht',
 				'kbd' => 'kabardianisht',
 				'kcg' => 'tjapisht',
 				'kde' => 'makondisht',
 				'kea' => 'kreolishte e Kepit të Gjelbër',
 				'kfo' => 'koroisht',
 				'kgp' => 'kaingangisht',
 				'kha' => 'kasisht',
 				'khq' => 'kojraçinisht',
 				'ki' => 'kikujuisht',
 				'kj' => 'kuanjamaisht',
 				'kk' => 'kazakisht',
 				'kkj' => 'kakoisht',
 				'kl' => 'kalalisutisht',
 				'kln' => 'kalenxhinisht',
 				'km' => 'kmerisht',
 				'kmb' => 'kimbunduisht',
 				'kn' => 'kanadisht',
 				'ko' => 'koreanisht',
 				'koi' => 'komi-parmjakisht',
 				'kok' => 'konkanisht',
 				'kpe' => 'kpeleisht',
 				'kr' => 'kanurisht',
 				'krc' => 'karaçaj-balkarisht',
 				'krl' => 'karelianisht',
 				'kru' => 'kurukisht',
 				'ks' => 'kashmirisht',
 				'ksb' => 'shambalisht',
 				'ksf' => 'bafianisht',
 				'ksh' => 'këlnisht',
 				'ku' => 'kurdisht',
 				'kum' => 'kumikisht',
 				'kv' => 'komisht',
 				'kw' => 'kornisht',
 				'ky' => 'kirgizisht',
 				'la' => 'latinisht',
 				'lad' => 'ladinoisht',
 				'lag' => 'langisht',
 				'lb' => 'luksemburgisht',
 				'lez' => 'lezgianisht',
 				'lg' => 'gandaisht',
 				'li' => 'limburgisht',
 				'lij' => 'ligurianisht',
 				'lkt' => 'lakotisht',
 				'ln' => 'lingalisht',
 				'lo' => 'laosisht',
 				'lou' => 'kreole e Luizianës',
 				'loz' => 'lozisht',
 				'lrc' => 'lurishte veriore',
 				'lt' => 'lituanisht',
 				'lu' => 'luba-katangaisht',
 				'lua' => 'luba-luluaisht',
 				'lun' => 'lundaisht',
 				'luo' => 'luoisht',
 				'lus' => 'mizoisht',
 				'luy' => 'lujaisht',
 				'lv' => 'letonisht',
 				'mad' => 'madurezisht',
 				'mag' => 'magaisht',
 				'mai' => 'maitilisht',
 				'mak' => 'makasarisht',
 				'mas' => 'masaisht',
 				'mdf' => 'mokshaisht',
 				'men' => 'mendisht',
 				'mer' => 'meruisht',
 				'mfe' => 'morisjenisht',
 				'mg' => 'madagaskarisht',
 				'mgh' => 'makua-mitoisht',
 				'mgo' => 'metaisht',
 				'mh' => 'marshallisht',
 				'mi' => 'maorisht',
 				'mic' => 'mikmakisht',
 				'min' => 'minangkabauisht',
 				'mk' => 'maqedonisht',
 				'ml' => 'malajalamisht',
 				'mn' => 'mongolisht',
 				'mni' => 'manipurisht',
 				'moh' => 'mohokisht',
 				'mos' => 'mosisht',
 				'mr' => 'maratisht',
 				'ms' => 'malajisht',
 				'mt' => 'maltisht',
 				'mua' => 'mundangisht',
 				'mul' => 'gjuhë të shumëfishta',
 				'mus' => 'krikisht',
 				'mwl' => 'mirandisht',
 				'my' => 'birmanisht',
 				'myv' => 'erzjaisht',
 				'mzn' => 'mazanderanisht',
 				'na' => 'nauruisht',
 				'nap' => 'napoletanisht',
 				'naq' => 'namaisht',
 				'nb' => 'norvegjishte letrare',
 				'nd' => 'ndebelishte veriore',
 				'nds' => 'gjermanishte e vendeve të ulëta',
 				'nds_NL' => 'gjermanishte saksone e vendeve të ulëta',
 				'ne' => 'nepalisht',
 				'new' => 'neuarisht',
 				'ng' => 'ndongaisht',
 				'nia' => 'niasisht',
 				'niu' => 'niueanisht',
 				'nl' => 'holandisht',
 				'nl_BE' => 'flamandisht',
 				'nmg' => 'kuasisht',
 				'nn' => 'norvegjishte nynorsk',
 				'nnh' => 'ngiembunisht',
 				'no' => 'norvegjisht',
 				'nog' => 'nogajisht',
 				'nqo' => 'nkoisht',
 				'nr' => 'ndebelishte jugore',
 				'nso' => 'sotoishte veriore',
 				'nus' => 'nuerisht',
 				'nv' => 'navahoisht',
 				'ny' => 'nianjisht',
 				'nyn' => 'niankolisht',
 				'oc' => 'oksitanisht',
 				'om' => 'oromoisht',
 				'or' => 'odisht',
 				'os' => 'osetisht',
 				'pa' => 'punxhabisht',
 				'pag' => 'pangasinanisht',
 				'pam' => 'pampangaisht',
 				'pap' => 'papiamentisht',
 				'pau' => 'paluanisht',
 				'pcm' => 'pixhinishte nigeriane',
 				'pl' => 'polonisht',
 				'prg' => 'prusisht',
 				'ps' => 'pashtoisht',
 				'pt' => 'portugalisht',
 				'pt_BR' => 'portugalishte braziliane',
 				'pt_PT' => 'portugalishte evropiane',
 				'qu' => 'keçuaisht',
 				'quc' => 'kiçeisht',
 				'rap' => 'rapanuisht',
 				'rar' => 'rarontonganisht',
 				'rhg' => 'rohingiaisht',
 				'rm' => 'retoromanisht',
 				'rn' => 'rundisht',
 				'ro' => 'rumanisht',
 				'ro_MD' => 'moldavisht',
 				'rof' => 'romboisht',
 				'ru' => 'rusisht',
 				'rup' => 'vllahisht',
 				'rw' => 'kiniaruandisht',
 				'rwk' => 'ruaisht',
 				'sa' => 'sanskritisht',
 				'sad' => 'sandauisht',
 				'sah' => 'sakaisht',
 				'saq' => 'samburisht',
 				'sat' => 'santalisht',
 				'sba' => 'ngambajisht',
 				'sbp' => 'sanguisht',
 				'sc' => 'sardenjisht',
 				'scn' => 'siçilianisht',
 				'sco' => 'skotisht',
 				'sd' => 'sindisht',
 				'sdh' => 'kurdishte jugore',
 				'se' => 'samishte veriore',
 				'seh' => 'senaisht',
 				'ses' => 'senishte kojrabore',
 				'sg' => 'sangoisht',
 				'sh' => 'serbo-kroatisht',
 				'shi' => 'taçelitisht',
 				'shn' => 'shanisht',
 				'si' => 'sinhalisht',
 				'sk' => 'sllovakisht',
 				'sl' => 'sllovenisht',
 				'sm' => 'samoanisht',
 				'sma' => 'samishte jugore',
 				'smj' => 'samishte lule',
 				'smn' => 'samishte inari',
 				'sms' => 'samishte skolti',
 				'sn' => 'shonisht',
 				'snk' => 'soninkisht',
 				'so' => 'somalisht',
 				'sq' => 'shqip',
 				'sr' => 'serbisht',
 				'srn' => 'srananisht (sranantongoisht)',
 				'ss' => 'suatisht',
 				'ssy' => 'sahoisht',
 				'st' => 'sotoishte jugore',
 				'su' => 'sundanisht',
 				'suk' => 'sukumaisht',
 				'sv' => 'suedisht',
 				'sw' => 'suahilisht',
 				'sw_CD' => 'suahilishte kongoleze',
 				'swb' => 'kamorianisht',
 				'syr' => 'siriakisht',
 				'ta' => 'tamilisht',
 				'te' => 'teluguisht',
 				'tem' => 'timneisht',
 				'teo' => 'tesoisht',
 				'tet' => 'tetumisht',
 				'tg' => 'taxhikisht',
 				'th' => 'tajlandisht',
 				'ti' => 'tigrinjaisht',
 				'tig' => 'tigreisht',
 				'tk' => 'turkmenisht',
 				'tlh' => 'klingonisht',
 				'tn' => 'cuanaisht',
 				'to' => 'tonganisht',
 				'tpi' => 'pisinishte toku',
 				'tr' => 'turqisht',
 				'trv' => 'torokoisht',
 				'ts' => 'congaisht',
 				'tt' => 'tatarisht',
 				'tum' => 'tumbukaisht',
 				'tvl' => 'tuvaluisht',
 				'tw' => 'tuisht',
 				'twq' => 'tasavakisht',
 				'ty' => 'tahitisht',
 				'tyv' => 'tuvinianisht',
 				'tzm' => 'tamazajtisht e Atlasit Qendror',
 				'udm' => 'udmurtisht',
 				'ug' => 'ujgurisht',
 				'uk' => 'ukrainisht',
 				'umb' => 'umbunduisht',
 				'und' => 'E panjohur',
 				'ur' => 'urduisht',
 				'uz' => 'uzbekisht',
 				'vai' => 'vaisht',
 				've' => 'vendaisht',
 				'vi' => 'vietnamisht',
 				'vo' => 'volapykisht',
 				'vun' => 'vunxhoisht',
 				'wa' => 'ualunisht',
 				'wae' => 'ualserisht',
 				'wal' => 'ulajtaisht',
 				'war' => 'uarajisht',
 				'wbp' => 'uarlpirisht',
 				'wo' => 'uolofisht',
 				'xal' => 'kalmikisht',
 				'xh' => 'xhosaisht',
 				'xog' => 'sogisht',
 				'yav' => 'jangbenisht',
 				'ybb' => 'jembaisht',
 				'yi' => 'jidisht',
 				'yo' => 'jorubaisht',
 				'yue' => 'kantonezisht',
 				'yue@alt=menu' => 'kinezishte kantoneze',
 				'zgh' => 'tamaziatishte standarde marokene',
 				'zh' => 'kinezisht',
 				'zh@alt=menu' => 'kinezishte mandarine',
 				'zh_Hans' => 'kinezishte e thjeshtuar',
 				'zh_Hans@alt=long' => 'kinezishte mandarine (e thjeshtuar)',
 				'zh_Hant' => 'kinezishte tradicionale',
 				'zh_Hant@alt=long' => 'kinezishte mandarine (tradicionale)',
 				'zu' => 'zuluisht',
 				'zun' => 'zunisht',
 				'zxx' => 'nuk ka përmbajtje gjuhësore',
 				'zza' => 'zazaisht',

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
			'Aghb' => 'albanishte e Kaukazit',
 			'Ahom' => 'ahomisht',
 			'Arab' => 'arabik',
 			'Armi' => 'aramaishte perandorake',
 			'Armn' => 'armen',
 			'Avst' => 'avestanisht',
 			'Bass' => 'basavahisht',
 			'Beng' => 'bengal',
 			'Bhks' => 'baiksukisht',
 			'Bopo' => 'bopomof',
 			'Brah' => 'brahmisht',
 			'Brai' => 'brailisht',
 			'Bugi' => 'buginisht',
 			'Buhd' => 'buhidisht',
 			'Cari' => 'karianisht',
 			'Chrs' => 'korasmianisht',
 			'Copt' => 'koptisht',
 			'Cpmn' => 'minoishte e Qipros',
 			'Cprt' => 'qipriotisht',
 			'Cyrl' => 'cirilik',
 			'Deva' => 'devanagar',
 			'Diak' => 'divesakuruisht',
 			'Dogr' => 'dograisht',
 			'Dsrt' => 'deseretisht',
 			'Dupl' => 'duplojanisht - formë e shkurtër',
 			'Egyp' => 'hieroglife egjiptiane',
 			'Elba' => 'shkrim i Elbasanit',
 			'Elym' => 'elimaisht',
 			'Ethi' => 'etiopik',
 			'Geor' => 'gjeorgjian',
 			'Glag' => 'glagolitikisht',
 			'Gonm' => 'masaramgondisht',
 			'Goth' => 'gotik',
 			'Gran' => 'grantaisht',
 			'Grek' => 'grek',
 			'Gujr' => 'guxharat',
 			'Guru' => 'gurmuk',
 			'Hanb' => 'hanbik',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoisht',
 			'Hans' => 'i thjeshtuar',
 			'Hans@alt=stand-alone' => 'han i thjeshtuar',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hatr' => 'hatranisht',
 			'Hebr' => 'hebraik',
 			'Hira' => 'hiragan',
 			'Hluw' => 'hieroglife anatoliane',
 			'Hmng' => 'pahauhmonisht',
 			'Hrkt' => 'alfabet rrokjesor japonez',
 			'Hung' => 'hungarishte e vjetër',
 			'Ital' => 'italishte e vjetër',
 			'Jamo' => 'jamosisht',
 			'Jpan' => 'japonez',
 			'Kana' => 'katakan',
 			'Khar' => 'karoshtisht',
 			'Khmr' => 'kmer',
 			'Khoj' => 'koxhkisht',
 			'Kits' => 'shkrim i vogël kitan',
 			'Knda' => 'kanad',
 			'Kore' => 'korean',
 			'Kthi' => 'kaitisht',
 			'Laoo' => 'laosisht',
 			'Latn' => 'latin',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lyci' => 'licianisht',
 			'Lydi' => 'lidianisht',
 			'Mahj' => 'mahaxhanisht',
 			'Maka' => 'makasarisht',
 			'Mani' => 'manikeanisht',
 			'Marc' => 'markenisht',
 			'Medf' => 'medefaidrinisht',
 			'Mend' => 'mendeisht',
 			'Merc' => 'meroitik kursiv',
 			'Mero' => 'meroitik',
 			'Mlym' => 'malajalam',
 			'Modi' => 'modisht',
 			'Mong' => 'mongolisht',
 			'Mroo' => 'mroisht',
 			'Mult' => 'multanisht',
 			'Mymr' => 'birman',
 			'Nand' => 'nandigarisht',
 			'Narb' => 'arabishte veriore e vjetër',
 			'Nbat' => 'nabateanisht',
 			'Nshu' => 'nyshuisht',
 			'Ogam' => 'ogamisht',
 			'Orkh' => 'orkonisht',
 			'Orya' => 'orija',
 			'Osma' => 'osmaniaisht',
 			'Ougr' => 'ujgurishte e vjetër',
 			'Palm' => 'palmirenisht',
 			'Pauc' => 'pausinhauisht',
 			'Perm' => 'permike e vjetër',
 			'Phag' => 'fagspaisht',
 			'Phli' => 'palavishte mbishkrimesh',
 			'Phlp' => 'palavishte psalteri',
 			'Phnx' => 'fenikisht',
 			'Prti' => 'persishte mbishkrimesh',
 			'Rjng' => 'rexhangisht',
 			'Runr' => 'runike',
 			'Samr' => 'samaritanisht',
 			'Sarb' => 'arabishte jugore e vjetër',
 			'Sgnw' => 'shkrim sing',
 			'Shaw' => 'shavianisht',
 			'Shrd' => 'sharadisht',
 			'Sidd' => 'sidamisht',
 			'Sind' => 'kudavadisht',
 			'Sinh' => 'sinhal',
 			'Sogd' => 'sogdianisht',
 			'Sogo' => 'sogdianishte e vjetër',
 			'Sora' => 'sorasompengisht',
 			'Soyo' => 'sojomboisht',
 			'Tagb' => 'tagbanvaisht',
 			'Taml' => 'tamil',
 			'Telu' => 'telug',
 			'Thaa' => 'tanisht',
 			'Thai' => 'tajlandez',
 			'Tibt' => 'tibetisht',
 			'Zmth' => 'simbole matematikore',
 			'Zsye' => 'emoji',
 			'Zsym' => 'me simbole',
 			'Zxxx' => 'i pashkruar',
 			'Zyyy' => 'i zakonshëm',
 			'Zzzz' => 'i panjohur',

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
			'001' => 'Bota',
 			'002' => 'Afrikë',
 			'003' => 'Amerika e Veriut',
 			'005' => 'Amerika e Jugut',
 			'009' => 'Oqeani',
 			'011' => 'Afrika Perëndimore',
 			'013' => 'Amerika Qendrore',
 			'014' => 'Afrika Lindore',
 			'015' => 'Afrika Veriore',
 			'017' => 'Afrika e Mesme',
 			'018' => 'Afrika Jugore',
 			'019' => 'Amerikë',
 			'021' => 'Amerika Veriore',
 			'029' => 'Karaibe',
 			'030' => 'Azia Lindore',
 			'034' => 'Azia Jugore',
 			'035' => 'Azia Juglindore',
 			'039' => 'Evropa Jugore',
 			'053' => 'Australazia',
 			'054' => 'Melanezia',
 			'057' => 'Rajoni Mikronezian',
 			'061' => 'Polinezia',
 			'142' => 'Azi',
 			'143' => 'Azia Qendrore',
 			'145' => 'Azia Perëndimore',
 			'150' => 'Evropë',
 			'151' => 'Evropa Lindore',
 			'154' => 'Evropa Veriore',
 			'155' => 'Evropa Perëndimore',
 			'202' => 'Afrika Subsahariane',
 			'419' => 'Amerika Latine',
 			'AC' => 'Ishulli Asenshion',
 			'AD' => 'Andorrë',
 			'AE' => 'Emiratet e Bashkuara Arabe',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilë',
 			'AL' => 'Shqipëri',
 			'AM' => 'Armeni',
 			'AO' => 'Angolë',
 			'AQ' => 'Antarktikë',
 			'AR' => 'Argjentinë',
 			'AS' => 'Samoa Amerikane',
 			'AT' => 'Austri',
 			'AU' => 'Australi',
 			'AW' => 'Arubë',
 			'AX' => 'Ishujt Alandë',
 			'AZ' => 'Azerbajxhan',
 			'BA' => 'Bosnjë-Hercegovinë',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgjikë',
 			'BF' => 'Burkina-Faso',
 			'BG' => 'Bullgari',
 			'BH' => 'Bahrejn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sen-Bartelemi',
 			'BM' => 'Bermude',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivi',
 			'BQ' => 'Karaibet holandeze',
 			'BR' => 'Brazil',
 			'BS' => 'Bahama',
 			'BT' => 'Butan',
 			'BV' => 'Ishulli Bove',
 			'BW' => 'Botsvanë',
 			'BY' => 'Bjellorusi',
 			'BZ' => 'Belizë',
 			'CA' => 'Kanada',
 			'CC' => 'Ishujt Kokos',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (RDK)',
 			'CF' => 'Republika e Afrikës Qendrore',
 			'CG' => 'Kongo-Brazavilë',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Zvicër',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Bregu i Fildishtë',
 			'CK' => 'Ishujt Kuk',
 			'CL' => 'Kili',
 			'CM' => 'Kamerun',
 			'CN' => 'Kinë',
 			'CO' => 'Kolumbi',
 			'CP' => 'Ishulli Klipërton',
 			'CR' => 'Kosta-Rikë',
 			'CU' => 'Kubë',
 			'CV' => 'Kepi i Gjelbër',
 			'CW' => 'Kurasao',
 			'CX' => 'Ishulli i Krishtlindjes',
 			'CY' => 'Qipro',
 			'CZ' => 'Çeki',
 			'CZ@alt=variant' => 'Republika Çeke',
 			'DE' => 'Gjermani',
 			'DG' => 'Diego-Garsia',
 			'DJ' => 'Xhibuti',
 			'DK' => 'Danimarkë',
 			'DM' => 'Dominikë',
 			'DO' => 'Republika Dominikane',
 			'DZ' => 'Algjeri',
 			'EA' => 'Theuta e Melila',
 			'EC' => 'Ekuador',
 			'EE' => 'Estoni',
 			'EG' => 'Egjipt',
 			'EH' => 'Saharaja Perëndimore',
 			'ER' => 'Eritre',
 			'ES' => 'Spanjë',
 			'ET' => 'Etiopi',
 			'EU' => 'Bashkimi Evropian',
 			'EZ' => 'Zona euro',
 			'FI' => 'Finlandë',
 			'FJ' => 'Fixhi',
 			'FK' => 'Ishujt Falkland',
 			'FK@alt=variant' => 'Ishujt Falkland (Malvine)',
 			'FM' => 'Mikronezi',
 			'FO' => 'Ishujt Faroe',
 			'FR' => 'Francë',
 			'GA' => 'Gabon',
 			'GB' => 'Mbretëria e Bashkuar',
 			'GB@alt=short' => 'MB',
 			'GD' => 'Granadë',
 			'GE' => 'Gjeorgji',
 			'GF' => 'Guajana Franceze',
 			'GG' => 'Gernsej',
 			'GH' => 'Ganë',
 			'GI' => 'Gjibraltar',
 			'GL' => 'Grënlandë',
 			'GM' => 'Gambi',
 			'GN' => 'Guine',
 			'GP' => 'Guadelupë',
 			'GQ' => 'Guineja Ekuatoriale',
 			'GR' => 'Greqi',
 			'GS' => 'Xhorxha Jugore dhe Ishujt Senduiçë të Jugut',
 			'GT' => 'Guatemalë',
 			'GU' => 'Guam',
 			'GW' => 'Guine-Bisau',
 			'GY' => 'Guajanë',
 			'HK' => 'RPA i Hong-Kongut',
 			'HK@alt=short' => 'Hong-Kong',
 			'HM' => 'Ishujt Hërd e Mekdonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroaci',
 			'HT' => 'Haiti',
 			'HU' => 'Hungari',
 			'IC' => 'Ishujt Kanarie',
 			'ID' => 'Indonezi',
 			'IE' => 'Irlandë',
 			'IL' => 'Izrael',
 			'IM' => 'Ishulli i Manit',
 			'IN' => 'Indi',
 			'IO' => 'Territori Britanik i Oqeanit Indian',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandë',
 			'IT' => 'Itali',
 			'JE' => 'Xhersej',
 			'JM' => 'Xhamajkë',
 			'JO' => 'Jordani',
 			'JP' => 'Japoni',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizi',
 			'KH' => 'Kamboxhia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komore',
 			'KN' => 'Shën-Kits dhe Nevis',
 			'KP' => 'Kore e Veriut',
 			'KR' => 'Kore e Jugut',
 			'KW' => 'Kuvajt',
 			'KY' => 'Ishujt Kajman',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Shën-Luçia',
 			'LI' => 'Lihtenshtajn',
 			'LK' => 'Sri-Lankë',
 			'LR' => 'Liberi',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituani',
 			'LU' => 'Luksemburg',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Marok',
 			'MC' => 'Monako',
 			'MD' => 'Moldavi',
 			'ME' => 'Mal i Zi',
 			'MF' => 'Sen-Marten',
 			'MG' => 'Madagaskar',
 			'MH' => 'Ishujt Marshall',
 			'MK' => 'Maqedonia e Veriut',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Burmë)',
 			'MN' => 'Mongoli',
 			'MO' => 'RPA i Makaos',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Ishujt e Marianës Veriore',
 			'MQ' => 'Martinikë',
 			'MR' => 'Mauritani',
 			'MS' => 'Montserat',
 			'MT' => 'Maltë',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldive',
 			'MW' => 'Malavi',
 			'MX' => 'Meksikë',
 			'MY' => 'Malajzi',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibi',
 			'NC' => 'Kaledoni e Re',
 			'NE' => 'Niger',
 			'NF' => 'Ishulli Norfolk',
 			'NG' => 'Nigeri',
 			'NI' => 'Nikaragua',
 			'NL' => 'Holandë',
 			'NO' => 'Norvegji',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Zelandë e Re',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinezia Franceze',
 			'PG' => 'Guineja e Re-Papua',
 			'PH' => 'Filipine',
 			'PK' => 'Pakistan',
 			'PL' => 'Poloni',
 			'PM' => 'Shën-Pier dhe Mikelon',
 			'PN' => 'Ishujt Pitkern',
 			'PR' => 'Porto-Riko',
 			'PS' => 'Territoret Palestineze',
 			'PS@alt=short' => 'Palestinë',
 			'PT' => 'Portugali',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'Oqeania e Largët (Lindja e Largët)',
 			'RE' => 'Reunion',
 			'RO' => 'Rumani',
 			'RS' => 'Serbi',
 			'RU' => 'Rusi',
 			'RW' => 'Ruandë',
 			'SA' => 'Arabi Saudite',
 			'SB' => 'Ishujt Solomon',
 			'SC' => 'Sejshelle',
 			'SD' => 'Sudan',
 			'SE' => 'Suedi',
 			'SG' => 'Singapor',
 			'SH' => 'Shën-Elenë',
 			'SI' => 'Slloveni',
 			'SJ' => 'Svalbard e Jan-Majen',
 			'SK' => 'Sllovaki',
 			'SL' => 'Sierra-Leone',
 			'SM' => 'San-Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SR' => 'Surinami',
 			'SS' => 'Sudani i Jugut',
 			'ST' => 'Sao-Tome e Principe',
 			'SV' => 'Salvador',
 			'SX' => 'Sint-Marten',
 			'SY' => 'Siri',
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Suazilend',
 			'TA' => 'Tristan-da-Kuna',
 			'TC' => 'Ishujt Turks dhe Kaikos',
 			'TD' => 'Çad',
 			'TF' => 'Territoret Jugore Franceze',
 			'TG' => 'Togo',
 			'TH' => 'Tajlandë',
 			'TJ' => 'Taxhikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timori Lindor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunizi',
 			'TO' => 'Tonga',
 			'TR' => 'Turqi',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajvan',
 			'TZ' => 'Tanzani',
 			'UA' => 'Ukrainë',
 			'UG' => 'Ugandë',
 			'UM' => 'Ishujt Periferikë të SHBA-së',
 			'UN' => 'Organizata e Kombeve të Bashkuara',
 			'UN@alt=short' => 'OKB',
 			'US' => 'SHBA',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Shën-Vincent dhe Grenadine',
 			'VE' => 'Venezuelë',
 			'VG' => 'Ishujt e Virgjër Britanikë',
 			'VI' => 'Ishujt e Virgjër të SHBA-së',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Uollis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-thekse',
 			'XB' => 'Pseudo-bidi',
 			'XK' => 'Kosovë',
 			'YE' => 'Jemen',
 			'YT' => 'Majotë',
 			'ZA' => 'Afrika e Jugut',
 			'ZM' => 'Zambi',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'I panjohur',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendari',
 			'cf' => 'Formati valutor',
 			'collation' => 'Radhitja',
 			'currency' => 'Valuta',
 			'hc' => 'Cikli orar (12 - 24)',
 			'lb' => 'Stili i gjerësisë së rreshtave',
 			'ms' => 'Sistemi i njësive matëse',
 			'numbers' => 'Numrat/shifrat',

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
 				'buddhist' => q{kalendar budist},
 				'chinese' => q{kalendar kinez},
 				'coptic' => q{Kalendari Koptik},
 				'dangi' => q{kalendar dangi},
 				'ethiopic' => q{kalendar etiopian},
 				'ethiopic-amete-alem' => q{Kalendari Etiopas Amete Alem},
 				'gregorian' => q{kalendar gregorian},
 				'hebrew' => q{kalendar hebraik},
 				'indian' => q{Kalendari Kombëtar Indian},
 				'islamic' => q{kalendar islamik},
 				'islamic-civil' => q{Kalendari Islamik (tabelor, periudha civile)},
 				'islamic-tbla' => q{Kalendari Islamik (tabelor, epoka austromikale)},
 				'islamic-umalqura' => q{Kalendari Islamik (Um al-Qura)},
 				'iso8601' => q{kalendar ISO-8601},
 				'japanese' => q{kalendar japonez},
 				'persian' => q{kalendar persian},
 				'roc' => q{kalendar minguo},
 			},
 			'cf' => {
 				'account' => q{format valutor llogaritës},
 				'standard' => q{format valutor standard},
 			},
 			'collation' => {
 				'big5han' => q{Radhitje e kinezishtes tradicionale - Big5},
 				'dictionary' => q{Radhitje fjalori},
 				'ducet' => q{radhitje unikode e parazgjedhur},
 				'gb2312han' => q{Radhitje e kinezishtes së thjeshtësuar - GB2312},
 				'phonebook' => q{Radhitje libri telefonik},
 				'pinyin' => q{Radhitje pinini},
 				'reformed' => q{Radhitje e reformuar},
 				'search' => q{kërkim i përgjithshëm},
 				'standard' => q{radhitje standarde},
 			},
 			'hc' => {
 				'h11' => q{sistem 12-orësh (0 - 11)},
 				'h12' => q{sistem 12-orësh (1 - 12)},
 				'h23' => q{sistem 24-orësh (0 - 23)},
 				'h24' => q{sistem 24-orësh (1 - 24)},
 			},
 			'lb' => {
 				'loose' => q{stil i gjerësisë së rreshtave - i larguar},
 				'normal' => q{stil i gjerësisë së rreshtave - normal},
 				'strict' => q{stil i gjerësisë së rreshtave - i ngushtuar},
 			},
 			'ms' => {
 				'metric' => q{sistem metrik},
 				'uksystem' => q{sistem imperial (britanik) i njësive matëse},
 				'ussystem' => q{sistem amerikan i njësive matëse},
 			},
 			'numbers' => {
 				'arab' => q{shifra indo-arabe},
 				'arabext' => q{shifra indo-arabe të zgjatura},
 				'armn' => q{numra armenë},
 				'armnlow' => q{numra armenë të vegjël},
 				'beng' => q{shifra bengali},
 				'deva' => q{shifra devanagari},
 				'ethi' => q{numra etiopianë},
 				'fullwide' => q{shifra me largësi të brendshme},
 				'geor' => q{numra gjeorgjianë},
 				'grek' => q{numra grekë},
 				'greklow' => q{numra grekë të vegjël},
 				'gujr' => q{shifra guxharati},
 				'guru' => q{shifra gurmuki},
 				'hanidec' => q{numra dhjetorë kinezë},
 				'hans' => q{numra të kinezishtes së thjeshtuar},
 				'hansfin' => q{numra financiarë të kinezishtes së thjeshtuar},
 				'hant' => q{numra të kinezishtes tradicionale},
 				'hantfin' => q{numra financiarë të kinezishtes tradicionale},
 				'hebr' => q{numra hebraikë},
 				'jpan' => q{numra japonezë},
 				'jpanfin' => q{numra financiarë japonezë},
 				'khmr' => q{shifra kmere},
 				'knda' => q{shifra kanade},
 				'laoo' => q{shifra lao},
 				'latn' => q{shifra latino-perëndimore},
 				'mlym' => q{shifra malajalame},
 				'mymr' => q{shifra mianmari},
 				'orya' => q{shifra orije},
 				'roman' => q{numra romakë},
 				'romanlow' => q{numra romakë të vegjël},
 				'taml' => q{numra tamilë tradicionalë},
 				'tamldec' => q{shifra tamile},
 				'telu' => q{shifra teluguje},
 				'thai' => q{shifra tajlandeze},
 				'tibt' => q{shifra tibetiane},
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
			'metric' => q{metrik},
 			'UK' => q{britanik (imperial)},
 			'US' => q{amerikan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Gjuha: {0}',
 			'script' => 'Skripti: {0}',
 			'region' => 'Rajoni: {0}',

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
			auxiliary => qr{[w]},
			index => ['A', 'B', 'C', 'Ç', 'D', '{DH}', 'E', 'Ë', 'F', 'G', '{GJ}', 'H', 'I', 'J', 'K', 'L', '{LL}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', '{RR}', 'S', '{SH}', 'T', '{TH}', 'U', 'V', 'X', '{XH}', 'Y', 'Z', '{ZH}'],
			main => qr{[a b c ç d {dh} e ë f g {gj} h i j k l {ll} m n {nj} o p q r {rr} s {sh} t {th} u v x {xh} y z {zh}]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” « » ( ) \[ \] § @ * / \& # ′ ″ ~]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', '{DH}', 'E', 'Ë', 'F', 'G', '{GJ}', 'H', 'I', 'J', 'K', 'L', '{LL}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', '{RR}', 'S', '{SH}', 'T', '{TH}', 'U', 'V', 'X', '{XH}', 'Y', 'Z', '{ZH}'], };
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
						'name' => q(drejtimi kardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(drejtimi kardinal),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
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
						'1' => q(josto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(josto{0}),
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
						'1' => q(ekza{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ekza{0}),
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
						'name' => q(g-forcë),
						'one' => q({0} g-forcë),
						'other' => q({0} g-forcë),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-forcë),
						'one' => q({0} g-forcë),
						'other' => q({0} g-forcë),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metra për sekondë në katror),
						'one' => q({0} metër për sekondë në katror),
						'other' => q({0} metra për sekondë në katror),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metra për sekondë në katror),
						'one' => q({0} metër për sekondë në katror),
						'other' => q({0} metra për sekondë në katror),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(hark-minuta),
						'one' => q({0} hark-minutë),
						'other' => q({0} hark-minuta),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(hark-minuta),
						'one' => q({0} hark-minutë),
						'other' => q({0} hark-minuta),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(hark-sekonda),
						'one' => q({0} hark-sekondë),
						'other' => q({0} hark-sekonda),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(hark-sekonda),
						'one' => q({0} hark-sekondë),
						'other' => q({0} hark-sekonda),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradë),
						'one' => q({0} gradë),
						'other' => q({0} gradë),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradë),
						'one' => q({0} gradë),
						'other' => q({0} gradë),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianë),
						'one' => q({0} radianë),
						'other' => q({0} radianë),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianë),
						'one' => q({0} radianë),
						'other' => q({0} radianë),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rrotullim),
						'one' => q({0} rrotullim),
						'other' => q({0} rrotullime),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rrotullim),
						'one' => q({0} rrotullim),
						'other' => q({0} rrotullime),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akra),
						'one' => q({0} akër),
						'other' => q({0} akra),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akra),
						'one' => q({0} akër),
						'other' => q({0} akra),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dynym),
						'one' => q({0} dynym),
						'other' => q({0} dynymë),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dynym),
						'one' => q({0} dynym),
						'other' => q({0} dynymë),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarë),
						'one' => q({0} hektar),
						'other' => q({0} hektarë),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarë),
						'one' => q({0} hektar),
						'other' => q({0} hektarë),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centimetra katrore),
						'one' => q({0} centimetër katror),
						'other' => q({0} centimetra katrore),
						'per' => q({0}/centimetër katror),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centimetra katrore),
						'one' => q({0} centimetër katror),
						'other' => q({0} centimetra katrore),
						'per' => q({0}/centimetër katror),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(këmbë katrore),
						'one' => q({0} këmbë katror),
						'other' => q({0} këmbë katrore),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(këmbë katrore),
						'one' => q({0} këmbë katror),
						'other' => q({0} këmbë katrore),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inç katrore),
						'one' => q({0} inç katror),
						'other' => q({0} inç katrore),
						'per' => q({0}/inç katror),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inç katrore),
						'one' => q({0} inç katror),
						'other' => q({0} inç katrore),
						'per' => q({0}/inç katror),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometra katrore),
						'one' => q({0} kilometër katror),
						'other' => q({0} kilometra katrore),
						'per' => q({0} për kilometër katror),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometra katrore),
						'one' => q({0} kilometër katror),
						'other' => q({0} kilometra katrore),
						'per' => q({0} për kilometër katror),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metra katrore),
						'one' => q({0} metër katror),
						'other' => q({0} metra katrore),
						'per' => q({0}/metër katror),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metra katrore),
						'one' => q({0} metër katror),
						'other' => q({0} metra katrore),
						'per' => q({0}/metër katror),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milje katrore),
						'one' => q({0} milje katror),
						'other' => q({0} milje katrore),
						'per' => q({0} për milje katrore),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milje katrore),
						'one' => q({0} milje katror),
						'other' => q({0} milje katrore),
						'per' => q({0} për milje katrore),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jardë katrore),
						'one' => q({0} jard katror),
						'other' => q({0} jardë katrore),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jardë katrore),
						'one' => q({0} jard katror),
						'other' => q({0} jardë katrore),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karatë),
						'one' => q({0} karat),
						'other' => q({0} karatë),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karatë),
						'one' => q({0} karat),
						'other' => q({0} karatë),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramë për decilitër),
						'one' => q({0} miligram për decilitër),
						'other' => q({0} miligramë për decilitër),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramë për decilitër),
						'one' => q({0} miligram për decilitër),
						'other' => q({0} miligramë për decilitër),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimolë për litër),
						'one' => q({0} milimol për litër),
						'other' => q({0} milimolë për litër),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimolë për litër),
						'one' => q({0} milimol për litër),
						'other' => q({0} milimolë për litër),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(molë),
						'one' => q({0} mol),
						'other' => q({0} molë),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(molë),
						'one' => q({0} mol),
						'other' => q({0} molë),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(përqind),
						'one' => q({0} përqind),
						'other' => q({0} përqind),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(përqind),
						'one' => q({0} përqind),
						'other' => q({0} përqind),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(përmijë),
						'one' => q({0} përmijë),
						'other' => q({0} përmijë),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(përmijë),
						'one' => q({0} përmijë),
						'other' => q({0} përmijë),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(pjesë për milion),
						'one' => q({0} pjesë për milion),
						'other' => q({0} pjesë për milion),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(pjesë për milion),
						'one' => q({0} pjesë për milion),
						'other' => q({0} pjesë për milion),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(përdhjetëmijë),
						'one' => q({0} përdhjetëmijë),
						'other' => q({0} përdhjetëmijë),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(përdhjetëmijë),
						'one' => q({0} përdhjetëmijë),
						'other' => q({0} përdhjetëmijë),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litra për 100 kilometra),
						'one' => q({0} litër për 100 kilometra),
						'other' => q({0} litra për 100 kilometra),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litra për 100 kilometra),
						'one' => q({0} litër për 100 kilometra),
						'other' => q({0} litra për 100 kilometra),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litra për kilometër),
						'one' => q({0} litër për kilometër),
						'other' => q({0} litra për kilometër),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litra për kilometër),
						'one' => q({0} litër për kilometër),
						'other' => q({0} litra për kilometër),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milje për gallon),
						'one' => q({0} milje për gallon),
						'other' => q({0} milje për gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milje për gallon),
						'one' => q({0} milje për gallon),
						'other' => q({0} milje për gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milje për gallon imperial),
						'one' => q({0} milje për gallon imperial),
						'other' => q({0} milje për gallon imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milje për gallon imperial),
						'one' => q({0} milje për gallon imperial),
						'other' => q({0} milje për gallon imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Lindje),
						'north' => q({0} Veri),
						'south' => q({0} Jug),
						'west' => q({0} Perëndim),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Lindje),
						'north' => q({0} Veri),
						'south' => q({0} Jug),
						'west' => q({0} Perëndim),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabajt),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabajt),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobajt),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobajt),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabajt),
						'one' => q({0} megabajt),
						'other' => q({0} megabajt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabajt),
						'one' => q({0} megabajt),
						'other' => q({0} megabajt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabajt),
						'one' => q({0} petabajt),
						'other' => q({0} petabajt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabajt),
						'one' => q({0} petabajt),
						'other' => q({0} petabajt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabajt),
						'one' => q({0} terabajt),
						'other' => q({0} terabajt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabajt),
						'one' => q({0} terabajt),
						'other' => q({0} terabajt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(shekuj),
						'one' => q({0} shekull),
						'other' => q({0} shekuj),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(shekuj),
						'one' => q({0} shekull),
						'other' => q({0} shekuj),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
						'per' => q({0}/ditë),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
						'per' => q({0}/ditë),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekada),
						'one' => q({0} dekadë),
						'other' => q({0} dekada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekada),
						'one' => q({0} dekadë),
						'other' => q({0} dekada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
						'per' => q({0}/orë),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
						'per' => q({0}/orë),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekonda),
						'one' => q({0} mikrosekondë),
						'other' => q({0} mikrosekonda),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekonda),
						'one' => q({0} mikrosekondë),
						'other' => q({0} mikrosekonda),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekonda),
						'one' => q({0} milisekondë),
						'other' => q({0} milisekonda),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekonda),
						'one' => q({0} milisekondë),
						'other' => q({0} milisekonda),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuta),
						'one' => q({0} minutë),
						'other' => q({0} minuta),
						'per' => q({0}/minutë),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuta),
						'one' => q({0} minutë),
						'other' => q({0} minuta),
						'per' => q({0}/minutë),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
						'per' => q({0}/muaj),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
						'per' => q({0}/muaj),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekonda),
						'one' => q({0} nanosekondë),
						'other' => q({0} nanosekonda),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekonda),
						'one' => q({0} nanosekondë),
						'other' => q({0} nanosekonda),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekonda),
						'one' => q({0} sekondë),
						'other' => q({0} sekonda),
						'per' => q({0}/sekondë),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekonda),
						'one' => q({0} sekondë),
						'other' => q({0} sekonda),
						'per' => q({0}/sekondë),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
						'per' => q({0}/javë),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
						'per' => q({0}/javë),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
						'per' => q({0}/vit),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
						'per' => q({0}/vit),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(njësi termale britanike),
						'one' => q({0} njësi termale britanike),
						'other' => q({0} njësi termale britanike),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(njësi termale britanike),
						'one' => q({0} njësi termale britanike),
						'other' => q({0} njësi termale britanike),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'one' => q({0} kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'one' => q({0} kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektrovolt),
						'one' => q({0} elektrovolt),
						'other' => q({0} elektrovolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektrovolt),
						'one' => q({0} elektrovolt),
						'other' => q({0} elektrovolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kalori ushqimore),
						'one' => q({0} kalori ushqimore),
						'other' => q({0} kalori ushqimore),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kalori ushqimore),
						'one' => q({0} kalori ushqimore),
						'other' => q({0} kalori ushqimore),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(zhul),
						'one' => q({0} zhul),
						'other' => q({0} zhul),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(zhul),
						'one' => q({0} zhul),
						'other' => q({0} zhul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilozhul),
						'one' => q({0} kilozhul),
						'other' => q({0} kilozhul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilozhul),
						'one' => q({0} kilozhul),
						'other' => q({0} kilozhul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovat-orë),
						'one' => q({0} kilovat-orë),
						'other' => q({0} kilovat-orë),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovat-orë),
						'one' => q({0} kilovat-orë),
						'other' => q({0} kilovat-orë),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(njësi termale amerikane),
						'one' => q({0} njësi termale amerikane),
						'other' => q({0} njësi termale amerikane),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(njësi termale amerikane),
						'one' => q({0} njësi termale amerikane),
						'other' => q({0} njësi termale amerikane),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovat-orë në 100 kilometra),
						'one' => q({0} kilovat-orë në 100 kilometra),
						'other' => q({0} kilovat-orë në 100 kilometra),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovat-orë në 100 kilometra),
						'one' => q({0} kilovat-orë në 100 kilometra),
						'other' => q({0} kilovat-orë në 100 kilometra),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(njuton),
						'one' => q({0} njuton),
						'other' => q({0} njuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(njuton),
						'one' => q({0} njuton),
						'other' => q({0} njuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(paund force),
						'one' => q({0} paund force),
						'other' => q({0} paund force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(paund force),
						'one' => q({0} paund force),
						'other' => q({0} paund force),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigaherc),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherc),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigaherc),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherc),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(herc),
						'one' => q({0} herc),
						'other' => q({0} herc),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(herc),
						'one' => q({0} herc),
						'other' => q({0} herc),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kiloherc),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherc),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kiloherc),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherc),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megaherc),
						'one' => q({0} megaherc),
						'other' => q({0} megaherc),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megaherc),
						'one' => q({0} megaherc),
						'other' => q({0} megaherc),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pika),
						'one' => q({0} pikë),
						'other' => q({0} pika),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pika),
						'one' => q({0} pikë),
						'other' => q({0} pika),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pika për centimetër),
						'one' => q({0} pikë për centimetër),
						'other' => q({0} pika për centimetër),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pika për centimetër),
						'one' => q({0} pikë për centimetër),
						'other' => q({0} pika për centimetër),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pika për inç),
						'one' => q({0} pikë për inç),
						'other' => q({0} pika për inç),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pika për inç),
						'one' => q({0} pikë për inç),
						'other' => q({0} pika për inç),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipografike),
						'one' => q({0} em tipografike),
						'other' => q({0} em tipografike),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipografike),
						'one' => q({0} em tipografike),
						'other' => q({0} em tipografike),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikselë),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselë),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikselë),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselë),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikselë),
						'one' => q({0} piksel),
						'other' => q({0} pikselë),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikselë),
						'one' => q({0} piksel),
						'other' => q({0} pikselë),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pikselë për centimetër),
						'one' => q({0} piksel për centimetër),
						'other' => q({0} pikselë për centimetër),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pikselë për centimetër),
						'one' => q({0} piksel për centimetër),
						'other' => q({0} pikselë për centimetër),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikselë për inç),
						'one' => q({0} piksel për inç),
						'other' => q({0} pikselë për inç),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikselë për inç),
						'one' => q({0} piksel për inç),
						'other' => q({0} pikselë për inç),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(njësi astronomike),
						'one' => q({0} njësi astronomike),
						'other' => q({0} njësi astronomike),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(njësi astronomike),
						'one' => q({0} njësi astronomike),
						'other' => q({0} njësi astronomike),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimetra),
						'one' => q({0} centimetër),
						'other' => q({0} centimetra),
						'per' => q({0}/centimetër),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimetra),
						'one' => q({0} centimetër),
						'other' => q({0} centimetra),
						'per' => q({0}/centimetër),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimetra),
						'one' => q({0} decimetër),
						'other' => q({0} decimetra),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimetra),
						'one' => q({0} decimetër),
						'other' => q({0} decimetra),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(rreze toke),
						'one' => q({0} rreze toke),
						'other' => q({0} rreze toke),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(rreze toke),
						'one' => q({0} rreze toke),
						'other' => q({0} rreze toke),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(këmbë),
						'one' => q({0} këmbë),
						'other' => q({0} këmbë),
						'per' => q({0}/këmbë),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(këmbë),
						'one' => q({0} këmbë),
						'other' => q({0} këmbë),
						'per' => q({0}/këmbë),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inç),
						'one' => q({0} inç),
						'other' => q({0} inç),
						'per' => q({0}/inç),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inç),
						'one' => q({0} inç),
						'other' => q({0} inç),
						'per' => q({0}/inç),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometra),
						'one' => q({0} kilometër),
						'other' => q({0} kilometra),
						'per' => q({0}/kilometër),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometra),
						'one' => q({0} kilometër),
						'other' => q({0} kilometra),
						'per' => q({0}/kilometër),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(vite dritë),
						'one' => q({0} vit drite),
						'other' => q({0} vite dritë),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(vite dritë),
						'one' => q({0} vit drite),
						'other' => q({0} vite dritë),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metra),
						'one' => q({0} metër),
						'other' => q({0} metra),
						'per' => q({0}/metër),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metra),
						'one' => q({0} metër),
						'other' => q({0} metra),
						'per' => q({0}/metër),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometra),
						'one' => q({0} mikrometër),
						'other' => q({0} mikrometra),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometra),
						'one' => q({0} mikrometër),
						'other' => q({0} mikrometra),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milje),
						'one' => q({0} milje),
						'other' => q({0} milje),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milje),
						'one' => q({0} milje),
						'other' => q({0} milje),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milje skandinave),
						'one' => q({0} milje skandinave),
						'other' => q({0} milje skandinave),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milje skandinave),
						'one' => q({0} milje skandinave),
						'other' => q({0} milje skandinave),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetra),
						'one' => q({0} milimetër),
						'other' => q({0} milimetra),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetra),
						'one' => q({0} milimetër),
						'other' => q({0} milimetra),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometra),
						'one' => q({0} nanometër),
						'other' => q({0} nanometra),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometra),
						'one' => q({0} nanometër),
						'other' => q({0} nanometra),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milje nautike),
						'one' => q({0} milje nautike),
						'other' => q({0} milje nautike),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milje nautike),
						'one' => q({0} milje nautike),
						'other' => q({0} milje nautike),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsekë),
						'one' => q({0} parsek),
						'other' => q({0} parsekë),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsekë),
						'one' => q({0} parsek),
						'other' => q({0} parsekë),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometra),
						'one' => q({0} pikometër),
						'other' => q({0} pikometra),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometra),
						'one' => q({0} pikometër),
						'other' => q({0} pikometra),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(shkallë),
						'one' => q({0} shkallë),
						'other' => q({0} shkallë),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(shkallë),
						'one' => q({0} shkallë),
						'other' => q({0} shkallë),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(rreze diellore),
						'one' => q({0} rreze diellore),
						'other' => q({0} rreze diellore),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(rreze diellore),
						'one' => q({0} rreze diellore),
						'other' => q({0} rreze diellore),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardë),
						'one' => q({0} jard),
						'other' => q({0} jardë),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardë),
						'one' => q({0} jard),
						'other' => q({0} jardë),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandelë),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandelë),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumenë),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumenë),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(lumenë diellorë),
						'one' => q({0} lumen diellorë),
						'other' => q({0} lumenë diellorë),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(lumenë diellorë),
						'one' => q({0} lumen diellorë),
						'other' => q({0} lumenë diellorë),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karatë),
						'one' => q({0} karat),
						'other' => q({0} karatë),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karatë),
						'one' => q({0} karat),
						'other' => q({0} karatë),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masa Toke),
						'one' => q({0} masë Toke),
						'other' => q({0} masa Toke),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masa Toke),
						'one' => q({0} masë Toke),
						'other' => q({0} masa Toke),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granë),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granë),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramë),
						'one' => q({0} gram),
						'other' => q({0} gramë),
						'per' => q({0}/gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramë),
						'one' => q({0} gram),
						'other' => q({0} gramë),
						'per' => q({0}/gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramë),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramë),
						'per' => q({0}/kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramë),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramë),
						'per' => q({0}/kilogram),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tonë metrik),
						'one' => q({0} ton metrik),
						'other' => q({0} tonë metrik),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tonë metrik),
						'one' => q({0} ton metrik),
						'other' => q({0} tonë metrik),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramë),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramë),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramë),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramë),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramë),
						'one' => q({0} miligram),
						'other' => q({0} miligramë),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramë),
						'one' => q({0} miligram),
						'other' => q({0} miligramë),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(onsë),
						'one' => q({0} ons),
						'other' => q({0} onsë),
						'per' => q({0}/ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(onsë),
						'one' => q({0} ons),
						'other' => q({0} onsë),
						'per' => q({0}/ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onsë troi),
						'one' => q({0} ons troi),
						'other' => q({0} onsë troi),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onsë troi),
						'one' => q({0} ons troi),
						'other' => q({0} onsë troi),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(paund),
						'one' => q({0} paund),
						'other' => q({0} paund),
						'per' => q({0}/paund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(paund),
						'one' => q({0} paund),
						'other' => q({0} paund),
						'per' => q({0}/paund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masa diellore),
						'one' => q({0} masë diellore),
						'other' => q({0} masa diellore),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masa diellore),
						'one' => q({0} masë diellore),
						'other' => q({0} masa diellore),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonë),
						'one' => q({0} ton),
						'other' => q({0} tonë),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonë),
						'one' => q({0} ton),
						'other' => q({0} tonë),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} në {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} në {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigavat),
						'one' => q({0} gigavat),
						'other' => q({0} gigavat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigavat),
						'one' => q({0} gigavat),
						'other' => q({0} gigavat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kuaj-fuqi),
						'one' => q({0} kalë-fuqi),
						'other' => q({0} kuaj-fuqi),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kuaj-fuqi),
						'one' => q({0} kalë-fuqi),
						'other' => q({0} kuaj-fuqi),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilovat),
						'one' => q({0} kilovat),
						'other' => q({0} kilovat),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilovat),
						'one' => q({0} kilovat),
						'other' => q({0} kilovat),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megavat),
						'one' => q({0} megavat),
						'other' => q({0} megavat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megavat),
						'one' => q({0} megavat),
						'other' => q({0} megavat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milivat),
						'one' => q({0} milivat),
						'other' => q({0} milivat),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milivat),
						'one' => q({0} milivat),
						'other' => q({0} milivat),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vat),
						'one' => q({0} vat),
						'other' => q({0} vat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vat),
						'one' => q({0} vat),
						'other' => q({0} vat),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} katror),
						'one' => q({0} katror),
						'other' => q({0} katror),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} katror),
						'one' => q({0} katror),
						'other' => q({0} katror),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} kub),
						'one' => q({0} kub),
						'other' => q({0} kub),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} kub),
						'one' => q({0} kub),
						'other' => q({0} kub),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosferë),
						'one' => q({0} atmosferë),
						'other' => q({0} atmosferë),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosferë),
						'one' => q({0} atmosferë),
						'other' => q({0} atmosferë),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bare),
						'one' => q({0} bar),
						'other' => q({0} bare),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bare),
						'one' => q({0} bar),
						'other' => q({0} bare),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inç merkuri),
						'one' => q({0} inç merkuri),
						'other' => q({0} inç merkuri),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inç merkuri),
						'one' => q({0} inç merkuri),
						'other' => q({0} inç merkuri),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibare),
						'one' => q({0} milibar),
						'other' => q({0} milibare),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibare),
						'one' => q({0} milibar),
						'other' => q({0} milibare),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetra mërkuri),
						'one' => q({0} milimetër mërkuri),
						'other' => q({0} milimetra mërkuri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetra mërkuri),
						'one' => q({0} milimetër mërkuri),
						'other' => q({0} milimetra mërkuri),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(paund për inç në katror),
						'one' => q({0} paund për inç në katror),
						'other' => q({0} paund për inç në katror),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(paund për inç në katror),
						'one' => q({0} paund për inç në katror),
						'other' => q({0} paund për inç në katror),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometra në orë),
						'one' => q({0} kilomentër në orë),
						'other' => q({0} kilometra në orë),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometra në orë),
						'one' => q({0} kilomentër në orë),
						'other' => q({0} kilometra në orë),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(milje nautike në orë),
						'one' => q({0} milje nautike në orë),
						'other' => q({0} milje nautike në orë),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(milje nautike në orë),
						'one' => q({0} milje nautike në orë),
						'other' => q({0} milje nautike në orë),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metra në sekondë),
						'one' => q({0} metër në sekondë),
						'other' => q({0} metra në sekondë),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metra në sekondë),
						'one' => q({0} metër në sekondë),
						'other' => q({0} metra në sekondë),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milje në orë),
						'one' => q({0} milje në orë),
						'other' => q({0} milje në orë),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milje në orë),
						'one' => q({0} milje në orë),
						'other' => q({0} milje në orë),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradë Celsius),
						'one' => q({0} gradë Celsius),
						'other' => q({0} gradë Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradë Celsius),
						'one' => q({0} gradë Celsius),
						'other' => q({0} gradë Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gradë Farenhait),
						'one' => q({0} gradë Farenhait),
						'other' => q({0} gradë Farenhait),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gradë Farenhait),
						'one' => q({0} gradë Farenhait),
						'other' => q({0} gradë Farenhait),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(njuton-metra),
						'one' => q({0} njuton-metër),
						'other' => q({0} njuton-metra),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(njuton-metra),
						'one' => q({0} njuton-metër),
						'other' => q({0} njuton-metra),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(paund-këmbë),
						'one' => q({0} paund-këmbë),
						'other' => q({0} paund-këmbë),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(paund-këmbë),
						'one' => q({0} paund-këmbë),
						'other' => q({0} paund-këmbë),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(këmbë-akër),
						'one' => q({0} këmbë-akër),
						'other' => q({0} këmbë-akër),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(këmbë-akër),
						'one' => q({0} këmbë-akër),
						'other' => q({0} këmbë-akër),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(fuçi),
						'one' => q({0} fuçi),
						'other' => q({0} fuçi),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(fuçi),
						'one' => q({0} fuçi),
						'other' => q({0} fuçi),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushelë),
						'one' => q({0} bushel),
						'other' => q({0} bushelë),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelë),
						'one' => q({0} bushel),
						'other' => q({0} bushelë),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitra),
						'one' => q({0} centilitër),
						'other' => q({0} centilitra),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitra),
						'one' => q({0} centilitër),
						'other' => q({0} centilitra),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(centimetra kub),
						'one' => q({0} centimetër kub),
						'other' => q({0} centimetra kub),
						'per' => q({0}/centimetër kub),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centimetra kub),
						'one' => q({0} centimetër kub),
						'other' => q({0} centimetra kub),
						'per' => q({0}/centimetër kub),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(këmbë kub),
						'one' => q({0} këmbë kub),
						'other' => q({0} këmbë kub),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(këmbë kub),
						'one' => q({0} këmbë kub),
						'other' => q({0} këmbë kub),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inç në kub),
						'one' => q({0} inç në kub),
						'other' => q({0} inç në kub),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inç në kub),
						'one' => q({0} inç në kub),
						'other' => q({0} inç në kub),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometra kub),
						'one' => q({0} kilometër kub),
						'other' => q({0} kilometra kub),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometra kub),
						'one' => q({0} kilometër kub),
						'other' => q({0} kilometra kub),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metra kub),
						'one' => q({0} metër kub),
						'other' => q({0} metra kub),
						'per' => q({0}/metër kub),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metra kub),
						'one' => q({0} metër kub),
						'other' => q({0} metra kub),
						'per' => q({0}/metër kub),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milje në kub),
						'one' => q({0} milje në kub),
						'other' => q({0} milje në kub),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milje në kub),
						'one' => q({0} milje në kub),
						'other' => q({0} milje në kub),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jardë në kub),
						'one' => q({0} jard në kub),
						'other' => q({0} jardë në kub),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jardë në kub),
						'one' => q({0} jard në kub),
						'other' => q({0} jardë në kub),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kupa),
						'one' => q({0} kupë),
						'other' => q({0} kupa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kupa),
						'one' => q({0} kupë),
						'other' => q({0} kupa),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(kupa metrike),
						'one' => q({0} kupë metrike),
						'other' => q({0} kupa metrike),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(kupa metrike),
						'one' => q({0} kupë metrike),
						'other' => q({0} kupa metrike),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitra),
						'one' => q({0} decilitër),
						'other' => q({0} decilitra),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitra),
						'one' => q({0} decilitër),
						'other' => q({0} decilitra),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drahma të lëngshme),
						'one' => q({0} drahmë i lëngshëm),
						'other' => q({0} drahma të lëngshme),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drahma të lëngshme),
						'one' => q({0} drahmë i lëngshëm),
						'other' => q({0} drahma të lëngshme),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(onsë të lëngshëm),
						'one' => q({0} ons i lëngshëm),
						'other' => q({0} onsë të lëngshëm),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(onsë të lëngshëm),
						'one' => q({0} ons i lëngshëm),
						'other' => q({0} onsë të lëngshëm),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(onsë të lëngshëm imperial),
						'one' => q({0} ons i lëngshëm imperial),
						'other' => q({0} onsë të lëngshëm imperial),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(onsë të lëngshëm imperial),
						'one' => q({0} ons i lëngshëm imperial),
						'other' => q({0} onsë të lëngshëm imperial),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallonë),
						'one' => q({0} gallon),
						'other' => q({0} gallonë),
						'per' => q({0}/gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallonë),
						'one' => q({0} gallon),
						'other' => q({0} gallonë),
						'per' => q({0}/gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gallonë imperial),
						'one' => q({0} gallon imperial),
						'other' => q({0} gallonë imperial),
						'per' => q({0} për gallon imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gallonë imperial),
						'one' => q({0} gallon imperial),
						'other' => q({0} gallonë imperial),
						'per' => q({0} për gallon imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitra),
						'one' => q({0} hektolitër),
						'other' => q({0} hektolitra),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitra),
						'one' => q({0} hektolitër),
						'other' => q({0} hektolitra),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litra),
						'one' => q({0} litër),
						'other' => q({0} litra),
						'per' => q({0}/litër),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litra),
						'one' => q({0} litër),
						'other' => q({0} litra),
						'per' => q({0}/litër),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitra),
						'one' => q({0} megalitër),
						'other' => q({0} megalitra),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitra),
						'one' => q({0} megalitër),
						'other' => q({0} megalitra),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitra),
						'one' => q({0} mililitër),
						'other' => q({0} mililitra),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitra),
						'one' => q({0} mililitër),
						'other' => q({0} mililitra),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinta),
						'one' => q({0} pintë),
						'other' => q({0} pinta),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinta),
						'one' => q({0} pintë),
						'other' => q({0} pinta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pinta metrike),
						'one' => q({0} pintë metrike),
						'other' => q({0} pinta metrike),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta metrike),
						'one' => q({0} pintë metrike),
						'other' => q({0} pinta metrike),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(çerekë),
						'one' => q({0} çerek),
						'other' => q({0} çerekë),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(çerekë),
						'one' => q({0} çerek),
						'other' => q({0} çerekë),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(lugë gjelle),
						'one' => q({0} lugë gjelle),
						'other' => q({0} lugë gjelle),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(lugë gjelle),
						'one' => q({0} lugë gjelle),
						'other' => q({0} lugë gjelle),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(lugë kafeje),
						'one' => q({0} lugë kafeje),
						'other' => q({0} lugë kafeje),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(lugë kafeje),
						'one' => q({0} lugë kafeje),
						'other' => q({0} lugë kafeje),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(drejtimi),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(drejtimi),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} g-forcë),
						'other' => q({0} g-forcë),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g-forcë),
						'other' => q({0} g-forcë),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(molë),
						'one' => q({0} mol),
						'other' => q({0} molë),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(molë),
						'one' => q({0} mol),
						'other' => q({0} molë),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} V),
						'south' => q({0} J),
						'west' => q({0} P),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} V),
						'south' => q({0} J),
						'west' => q({0} P),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pika),
						'one' => q({0} pikë),
						'other' => q({0} pika),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pika),
						'one' => q({0} pikë),
						'other' => q({0} pika),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
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
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inç Hg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inç Hg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/orë),
						'one' => q({0} km/orë),
						'other' => q({0} km/orë),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/orë),
						'one' => q({0} km/orë),
						'other' => q({0} km/orë),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(shinikë),
						'one' => q({0} shinik),
						'other' => q({0} shinikë),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(shinikë),
						'one' => q({0} shinik),
						'other' => q({0} shinikë),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(teke),
						'one' => q({0} teke),
						'other' => q({0} teke),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(teke),
						'one' => q({0} teke),
						'other' => q({0} teke),
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
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(piska),
						'one' => q({0} pisk),
						'other' => q({0} piska),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(piska),
						'one' => q({0} pisk),
						'other' => q({0} piska),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(drejtimi),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(drejtimi),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(hark-min.),
						'one' => q({0} hark-min.),
						'other' => q({0} hark-min.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(hark-min.),
						'one' => q({0} hark-min.),
						'other' => q({0} hark-min.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(hark-sek.),
						'one' => q({0} hark-sek.),
						'other' => q({0} hark-sek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(hark-sek.),
						'one' => q({0} hark-sek.),
						'other' => q({0} hark-sek.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rrot.),
						'one' => q({0} rrot.),
						'other' => q({0} rrot.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rrot.),
						'one' => q({0} rrot.),
						'other' => q({0} rrot.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dynymë),
						'one' => q({0} dynym),
						'other' => q({0} dynymë),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dynymë),
						'one' => q({0} dynym),
						'other' => q({0} dynymë),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(njësi),
						'one' => q({0} njësi),
						'other' => q({0} njësi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
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
						'name' => q(mi/gal Imp.),
						'one' => q({0} mi/gal Imp.),
						'other' => q({0} mi/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal Imp.),
						'one' => q({0} mi/gal Imp.),
						'other' => q({0} mi/gal Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} V),
						'south' => q({0} J),
						'west' => q({0} P),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} V),
						'south' => q({0} J),
						'west' => q({0} P),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GBajt),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBajt),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kBajt),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBajt),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MBajt),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBajt),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBajt),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBajt),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TBajt),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBajt),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(shek.),
						'one' => q({0} shek.),
						'other' => q({0} shek.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(shek.),
						'one' => q({0} shek.),
						'other' => q({0} shek.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
						'per' => q({0}/ditë),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ditë),
						'one' => q({0} ditë),
						'other' => q({0} ditë),
						'per' => q({0}/ditë),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekada),
						'one' => q({0} dekadë),
						'other' => q({0} dekada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekada),
						'one' => q({0} dekadë),
						'other' => q({0} dekada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
						'per' => q({0}/orë),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(orë),
						'one' => q({0} orë),
						'other' => q({0} orë),
						'per' => q({0}/orë),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisek.),
						'one' => q({0} milisek.),
						'other' => q({0} milisek.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisek.),
						'one' => q({0} milisek.),
						'other' => q({0} milisek.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
						'per' => q({0}/muaj),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(muaj),
						'one' => q({0} muaj),
						'other' => q({0} muaj),
						'per' => q({0}/muaj),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
						'per' => q({0}/javë),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(javë),
						'one' => q({0} javë),
						'other' => q({0} javë),
						'per' => q({0}/javë),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
						'per' => q({0}/vit),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vjet),
						'one' => q({0} vit),
						'other' => q({0} vjet),
						'per' => q({0}/vit),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
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
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(UStu),
						'one' => q(UStu),
						'other' => q({0} UStu),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(UStu),
						'one' => q(UStu),
						'other' => q({0} UStu),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(këmbë),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(këmbë),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inç),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inç),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(shkallë),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(shkallë),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granë),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granë),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
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
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/orë),
						'one' => q({0} km/orë),
						'other' => q({0} km/orë),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/orë),
						'one' => q({0} km/orë),
						'other' => q({0} km/orë),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradë C),
						'one' => q({0} gradë C),
						'other' => q({0} gradë C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradë C),
						'one' => q({0} gradë C),
						'other' => q({0} gradë C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushelë),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelë),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
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
						'name' => q(gallon),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal Imp.),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Imp.),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:po|p|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|j|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
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
					'one' => '0 mijë',
					'other' => '0 mijë',
				},
				'10000' => {
					'one' => '00 mijë',
					'other' => '00 mijë',
				},
				'100000' => {
					'one' => '000 mijë',
					'other' => '000 mijë',
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
					'one' => '0 bln',
					'other' => '0 bln',
				},
				'10000000000000' => {
					'one' => '00 bln',
					'other' => '00 bln',
				},
				'100000000000000' => {
					'one' => '000 bln',
					'other' => '000 bln',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 mijë',
					'other' => '0 mijë',
				},
				'10000' => {
					'one' => '00 mijë',
					'other' => '00 mijë',
				},
				'100000' => {
					'one' => '000 mijë',
					'other' => '000 mijë',
				},
				'1000000' => {
					'one' => '0 milion',
					'other' => '0 milion',
				},
				'10000000' => {
					'one' => '00 milion',
					'other' => '00 milion',
				},
				'100000000' => {
					'one' => '000 milion',
					'other' => '000 milion',
				},
				'1000000000' => {
					'one' => '0 miliard',
					'other' => '0 miliard',
				},
				'10000000000' => {
					'one' => '00 miliard',
					'other' => '00 miliard',
				},
				'100000000000' => {
					'one' => '000 miliard',
					'other' => '000 miliard',
				},
				'1000000000000' => {
					'one' => '0 bilion',
					'other' => '0 bilion',
				},
				'10000000000000' => {
					'one' => '00 bilion',
					'other' => '00 bilion',
				},
				'100000000000000' => {
					'one' => '000 bilion',
					'other' => '000 bilion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 mijë',
					'other' => '0 mijë',
				},
				'10000' => {
					'one' => '00 mijë',
					'other' => '00 mijë',
				},
				'100000' => {
					'one' => '000 mijë',
					'other' => '000 mijë',
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
					'one' => '0 bln',
					'other' => '0 bln',
				},
				'10000000000000' => {
					'one' => '00 bln',
					'other' => '00 bln',
				},
				'100000000000000' => {
					'one' => '000 bln',
					'other' => '000 bln',
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
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirhami i Emirateve të Bashkuara Arabe),
				'one' => q(dirham i Emirateve të Bashkuara Arabe),
				'other' => q(dirhamë të Emirateve të Bashkuara Arabe),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgani afgan),
				'one' => q(afgan afgan),
				'other' => q(afganë afgan),
			},
		},
		'ALL' => {
			symbol => 'Lekë',
			display_name => {
				'currency' => q(Leku shqiptar),
				'one' => q(lek shqiptar),
				'other' => q(lekë shqiptar),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dramia armene),
				'one' => q(drami armene),
				'other' => q(drami armene),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Gilderi antilian holandez),
				'one' => q(gilder antilian holandez),
				'other' => q(gilderë antilian holandez),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kuanza e Angolës),
				'one' => q(kuanzë angole),
				'other' => q(kuanza angole),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Pesoja argjentinase),
				'one' => q(peso argjentinase),
				'other' => q(peso argjentinase),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dollari australian),
				'one' => q(dollar australian),
				'other' => q(dollarë australian),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florini aruban),
				'one' => q(florin aruban),
				'other' => q(florinë aruban),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manata azerbajxhanase),
				'one' => q(manatë azerbajxhanase),
				'other' => q(manata azerbajxhanase),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Marka e Bosnjë-Hercegovinës [e shkëmbyeshme]),
				'one' => q(markë e Bosnjë-Hercegovinës [e shkëmbyeshme]),
				'other' => q(marka të Bosnjë-Hercegovinës [të shkëmbyeshme]),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dollari barbadian),
				'one' => q(dollar barbadian),
				'other' => q(dollarë barbadian),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka e Bangladeshit),
				'one' => q(takë bangladeshi),
				'other' => q(taka bangladeshi),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Leva bullgare),
				'one' => q(levë bullgare),
				'other' => q(leva bullgare),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinari i Bahreinit),
				'one' => q(dinar bahreini),
				'other' => q(dinarë bahreini),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franga burundiane),
				'one' => q(frangë burundiane),
				'other' => q(franga burundiane),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dollari i Bermudeve),
				'one' => q(dollar bermude),
				'other' => q(dollarë bermude),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dollari i Bruneit),
				'one' => q(dollar brunei),
				'other' => q(dollarë brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviani i Bolivisë),
				'one' => q(bolivian i Bolivisë),
				'other' => q(bolivianë të Bolivisë),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(Reali brazilian),
				'one' => q(real brazilian),
				'other' => q(realë brazilian),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dollari i Bahamasit),
				'one' => q(dollar bahamez),
				'other' => q(dollarë bahamez),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrumi butanez),
				'one' => q(ngultrum butanez),
				'other' => q(ngultrumë butanez),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula botsuane),
				'one' => q(pulë botsuane),
				'other' => q(pula botsuane),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rubla bjelloruse),
				'one' => q(rubël bjelloruse),
				'other' => q(rubla bjelloruse),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rubla bjelloruse \(2000–2016\)),
				'one' => q(rubël bjelloruse \(2000–2016\)),
				'other' => q(rubla bjelloruse \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dollari i Ishujve Belize),
				'one' => q(dollar belize),
				'other' => q(dollarë belize),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dollari kanadez),
				'one' => q(dollar kanadez),
				'other' => q(dollarë kanadez),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franga kongole),
				'one' => q(frangë kongole),
				'other' => q(franga kongole),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franga zvicerane),
				'one' => q(frangë zvicerane),
				'other' => q(franga zvicerane),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Pesoja kiliane),
				'one' => q(peso kiliane),
				'other' => q(peso kiliane),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Juani kinez \(për treg të jashtëm\)),
				'one' => q(juan kinez \(për treg të jashtëm\)),
				'other' => q(juanë kinez \(për treg të jashtëm\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Juani kinez),
				'one' => q(juan kinez),
				'other' => q(juanë kinez),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Pesoja kolumbiane),
				'one' => q(peso kolumbiane),
				'other' => q(peso kolumbiane),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Koloni kostarikan),
				'one' => q(kolon kostarikan),
				'other' => q(kolonë kostarikan),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Pesoja kubaneze e shkëmbyeshme),
				'one' => q(peso kubaneze e shkëmbyeshme),
				'other' => q(peso kubaneze e shkëmbyeshme),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Pesoja kubaneze),
				'one' => q(peso kubaneze),
				'other' => q(peso kubaneze),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Eskudoja e Kepit të Gjelbër),
				'one' => q(eskudo e Kepit të Gjelbër),
				'other' => q(eskudo të Kepit të Gjelbër),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Koruna e Çekisë),
				'one' => q(korunë çeke),
				'other' => q(koruna çeke),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franga xhibutiane),
				'one' => q(frangë xhibutiane),
				'other' => q(franga xhibutiane),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Korona daneze),
				'one' => q(koronë daneze),
				'other' => q(korona daneze),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Pesoja dominikane),
				'one' => q(peso dominikane),
				'other' => q(peso dominikane),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinari algjerian),
				'one' => q(dinar algjerian),
				'other' => q(dinarë algjerian),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Sterlina egjiptiane),
				'one' => q(sterlinë egjiptiane),
				'other' => q(sterlina egjiptiane),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa e Eritresë),
				'one' => q(nakfë eritreje),
				'other' => q(nakfa eritreje),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Bira etiopiane),
				'one' => q(birë etiopiane),
				'other' => q(bira etiopiane),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euroja),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dollari i Fixhit),
				'one' => q(dollar fixhi),
				'other' => q(dollarë fixhi),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Stërlina e Ishujve Falkland),
				'one' => q(stërlinë e Ishujve Falkland),
				'other' => q(stërlina të Ishujve Falkland),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Sterlina britanike),
				'one' => q(sterlinë britanike),
				'other' => q(sterlina britanike),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Laria gjeorgjiane),
				'one' => q(lari gjeorgjian),
				'other' => q(lari gjeorgjiane),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Sejda ganeze),
				'one' => q(sejdë ganeze),
				'other' => q(sejda ganeze),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Sterlina e Gjibraltarit),
				'one' => q(sterlinë gjibraltari),
				'other' => q(sterlina gjibraltari),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi gambian),
				'one' => q(dalas gambian),
				'other' => q(dalasë gambian),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Franga guinease),
				'one' => q(frangë guineje),
				'other' => q(franga guineje),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Kuecali i Guatemalës),
				'one' => q(kuecal guatemalas),
				'other' => q(kuecalë guatemalas),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dollari guajanez),
				'one' => q(dollar guajanez),
				'other' => q(dollarë guajanez),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dollari i Hong-Kongut),
				'one' => q(dollar hong-kongu),
				'other' => q(dollarë hong-kongu),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira hondurase),
				'one' => q(lempirë hondurase),
				'other' => q(lempira hondurase),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna kroate),
				'one' => q(kunë kroate),
				'other' => q(kuna kroate),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gurdi haitian),
				'one' => q(gurd haitian),
				'other' => q(gurdë haitian),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forinta hungareze),
				'one' => q(forintë hungareze),
				'other' => q(forinta hungareze),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupia indoneziane),
				'one' => q(rupi indoneziane),
				'other' => q(rupi indoneziane),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Shekeli izrealit),
				'one' => q(shekel izrealit),
				'other' => q(shekelë izrealit),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia indiane),
				'one' => q(rupi indiane),
				'other' => q(rupi indiane),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinari irakian),
				'one' => q(dinar irakian),
				'other' => q(dinarë irakian),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Riali iranian),
				'one' => q(rial iranian),
				'other' => q(rialë iranian),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Korona islandeze),
				'one' => q(koronë islandeze),
				'other' => q(korona islandeze),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dollari xhamajkan),
				'one' => q(dollar xhamajkan),
				'other' => q(dollarë xhamajkan),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinari jordanez),
				'one' => q(dinar jordanez),
				'other' => q(dinarë jordanez),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Jeni japonez),
				'one' => q(jen japonez),
				'other' => q(jenë japonez),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Shilinga keniane),
				'one' => q(shilingë keniane),
				'other' => q(shilinga keniane),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Soma kirgize),
				'one' => q(somë kirgize),
				'other' => q(soma kirgize),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riali kamboxhian),
				'one' => q(rial kamboxhian),
				'other' => q(rialë kamboxhian),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franga komore),
				'one' => q(frangë komore),
				'other' => q(franga komori),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Uoni koreano-verior),
				'one' => q(uon koreano-verior),
				'other' => q(uonë koreano-verior),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Uoni koreano-jugor),
				'one' => q(uon koreano-jugor),
				'other' => q(uonë koreano-jugor),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinari kuvajtian),
				'one' => q(dinar kuvajtian),
				'other' => q(dinarë kuvajtian),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dollari i Ishujve Kajman),
				'one' => q(dollar i Ishujve Kajman),
				'other' => q(dollarë të Ishujve Kajman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenga kazake),
				'one' => q(tengë kazake),
				'other' => q(tenga kazake),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kipa e Laosit),
				'one' => q(kipë laosi),
				'other' => q(kipa laosi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Sterlina libaneze),
				'one' => q(sterlinë libaneze),
				'other' => q(sterlina libaneze),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia e Sri-Lankës),
				'one' => q(rupi sri-lanke),
				'other' => q(rupi sri-lanke),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dollari liberian),
				'one' => q(dollar liberian),
				'other' => q(dollarë liberian),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lota lesotiane),
				'one' => q(lotë lesotiane),
				'other' => q(lota lesotiane),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Lita lituaneze),
				'one' => q(litë lituaneze),
				'other' => q(lita lituaneze),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lata letoneze),
				'one' => q(latë letoneze),
				'other' => q(lata letoneze),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinari libian),
				'one' => q(dinar libian),
				'other' => q(dinarë libian),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirhami maroken),
				'one' => q(dirham maroken),
				'other' => q(dirhamë maroken),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leuja moldave),
				'one' => q(leu moldave),
				'other' => q(leu moldave),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Arieri malagez),
				'one' => q(arier malagez),
				'other' => q(arierë malagez),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denari maqedonas),
				'one' => q(denar maqedonas),
				'other' => q(denarë maqedonas),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kiata e Mianmarit),
				'one' => q(kiatë mianmari),
				'other' => q(kiata mianmari),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrika mongole),
				'one' => q(tugrikë mongole),
				'other' => q(tugrika mongole),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataka e Makaos),
				'one' => q(patakë e Makaos),
				'other' => q(pataka të Makaos),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ugija mauritane \(1973–2017\)),
				'one' => q(ugijë mauritane \(1973–2017\)),
				'other' => q(ugija mauritane \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ugija mauritane),
				'one' => q(ugijë mauritane),
				'other' => q(ugija mauritane),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia mauritiane),
				'one' => q(rupi mauritiane),
				'other' => q(rupi mauritiane),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiu i Maldivit),
				'one' => q(rufi maldivi),
				'other' => q(rufi maldivi),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kuaça malaviane),
				'one' => q(kuaçë malaviane),
				'other' => q(kuaça malaviane),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Pesoja meksikane),
				'one' => q(peso meksikane),
				'other' => q(peso meksikane),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringiti malajzian),
				'one' => q(ringit malajzian),
				'other' => q(ringitë malajzian),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metikali i Mozambikut),
				'one' => q(metikal mozambiku),
				'other' => q(metikalë mozambiku),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dollari i Namibisë),
				'one' => q(dollar namibie),
				'other' => q(dollarë namibie),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira nigeriane),
				'one' => q(nairë nigeriane),
				'other' => q(naira nigeriane),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Kordoba nikaraguane),
				'one' => q(kordobë nikaraguane),
				'other' => q(kordoba nikaraguane),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Korona norvegjeze),
				'one' => q(koronë norvegjeze),
				'other' => q(korona norvegjeze),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia nepaleze),
				'one' => q(rupi nepaleze),
				'other' => q(rupi nepaleze),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dollari i Zelandës së Re),
				'one' => q(dollar i Zelandës së Re),
				'other' => q(dollarë të Zelandës së Re),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Riali i Omanit),
				'one' => q(rial omani),
				'other' => q(rialë omani),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa panameze),
				'one' => q(balboa panameze),
				'other' => q(balboa panameze),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sola peruane),
				'one' => q(solë peruane),
				'other' => q(sola peruane),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina e Guinesë së Re-Papua),
				'one' => q(kinë e Guinesë së Re-Papua),
				'other' => q(kina të Guinesë së Re-Papua),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Pesoja filipinase),
				'one' => q(peso filipinase),
				'other' => q(peso filipinase),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia pakistaneze),
				'one' => q(rupi pakistaneze),
				'other' => q(rupi pakistaneze),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zllota polake),
				'one' => q(zllotë polake),
				'other' => q(zllota polake),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani paraguaian),
				'one' => q(guaran paraguaian),
				'other' => q(guaranë paraguaian),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Riali i Katarit),
				'one' => q(rial katari),
				'other' => q(rialë katari),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leuja rumune),
				'one' => q(leu rumune),
				'other' => q(leu rumune),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinari serb),
				'one' => q(dinar serb),
				'other' => q(dinarë serb),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rubla ruse),
				'one' => q(rubël ruse),
				'other' => q(rubla ruse),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franga ruandeze),
				'one' => q(frangë ruandeze),
				'other' => q(franga ruandeze),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riali saudit),
				'one' => q(rial saudit),
				'other' => q(rialë saudit),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dollari i Ishujve Solomonë),
				'one' => q(dollar i Ishujve Solomonë),
				'other' => q(dollarë të Ishujve Solomonë),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia e Ishujve Sishelë),
				'one' => q(rupi e Ishujve Sishelë),
				'other' => q(rupi të Ishujve Sishelë),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sterlina sudaneze),
				'one' => q(sterlinë sudaneze),
				'other' => q(sterlina sudaneze),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Korona suedeze),
				'one' => q(koronë suedeze),
				'other' => q(korona suedeze),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dollari i Singaporit),
				'one' => q(dollar singapori),
				'other' => q(dollarë singapori),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Sterlina e Ishullit të Shën-Helenës),
				'one' => q(sterlinë e Ishullit të Shën-Helenës),
				'other' => q(sterlina e Ishullit të Shën-Helenës),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leoni i Sierra-Leones),
				'one' => q(leon i Sierra-Leones),
				'other' => q(leonë të Sierra-Leones),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Shilinga somaleze),
				'one' => q(shilingë somaleze),
				'other' => q(shilinga somaleze),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dollari surinamez),
				'one' => q(dollar surinamez),
				'other' => q(dollarë surinamez),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Sterlina sudanezo-jugore),
				'one' => q(sterlinë sudanezo-jugore),
				'other' => q(sterlina sudanezo-jugore),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra e Sao-Tomes dhe Prinsipes \(1977–2017\)),
				'one' => q(dobër e Sao-Tomes dhe Prinsipes \(1977–2017\)),
				'other' => q(dobra të Sao-Tomes dhe Prinsipes \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra e Sao-Tomes dhe Prinsipes),
				'one' => q(dobër e Sao-Tomes dhe Prinsipes),
				'other' => q(dobra të Sao-Tomes dhe Prinsipes),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Sterlina siriane),
				'one' => q(sterlinë siriane),
				'other' => q(sterlina siriane),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni i Suazilandës),
				'one' => q(lilangen suazilande),
				'other' => q(lilangenë suazilande),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Bata tajlandeze),
				'one' => q(batë tajlandeze),
				'other' => q(bata tajlandeze),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somona taxhike),
				'one' => q(somonë taxhike),
				'other' => q(somona taxhike),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manata turkmene),
				'one' => q(manatë turkmene),
				'other' => q(manata turkmene),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinari tunizian),
				'one' => q(dinar tunizian),
				'other' => q(dinarë tunizian),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Panga tongane),
				'one' => q(pangë tongane),
				'other' => q(panga tongane),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira turke),
				'one' => q(lirë turke),
				'other' => q(lira turke),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dollari i Trinidadit dhe Tobagos),
				'one' => q(dollar i Trinidadit dhe Tobagos),
				'other' => q(dollarë të Trinidadit dhe Tobagos),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dollari tajvanez),
				'one' => q(dollar tajvanez),
				'other' => q(dollarë tajvanez),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Shilinga e Tanzanisë),
				'one' => q(shilingë tanzanie),
				'other' => q(shilinga tanzanie),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Rivnia ukrainase),
				'one' => q(rivni ukrainase),
				'other' => q(rivni ukrainase),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilinga ugandeze),
				'one' => q(shilingë ugandeze),
				'other' => q(shilinga ugandeze),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dollari amerikan),
				'one' => q(dollar amerikan),
				'other' => q(dollarë amerikan),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Pesoja uruguaiane),
				'one' => q(peso uruguaiane),
				'other' => q(peso uruguaiane),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Soma uzbeke),
				'one' => q(somë uzbeke),
				'other' => q(soma uzbeke),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolivari venezuelian \(2008–2018\)),
				'one' => q(bolivar venezuelian \(2008–2018\)),
				'other' => q(bolivarë venezuelian \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolivari venezuelas),
				'one' => q(bolivar venezuelas),
				'other' => q(bolivarë venezuelas),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Donga vietnameze),
				'one' => q(dongë vietnameze),
				'other' => q(donga vietnameze),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatuja e Vanuatusë),
				'one' => q(vatu vanuatuje),
				'other' => q(vatu vanuatuje),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala samoane),
				'one' => q(talë samoane),
				'other' => q(tala samoane),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Franga kamerunase),
				'one' => q(frangë kamerunase),
				'other' => q(franga kamerunase),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dollari i Karaibeve Lindore),
				'one' => q(dollar i Karaibeve Lindore),
				'other' => q(dollarë të Karaibeve Lindore),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(Franga e Bregut të Fildishtë),
				'one' => q(frangë e Bregut të Fildishtë),
				'other' => q(franga të Bregut të Fildishtë),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Franga franceze e Polinezisë),
				'one' => q(frangë franceze e Polinezisë),
				'other' => q(franga franceze të Polinezisë),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Valutë e panjohur),
				'one' => q(\(njësi e panjohur valutore\)),
				'other' => q(\(njësi të panjohura valutore\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Riali i Jemenit),
				'one' => q(rial jemeni),
				'other' => q(rialë jemeni),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Randi afrikano-jugor),
				'one' => q(rand afrikano-jugor),
				'other' => q(randë afrikano-jugor),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kuaça e Zambikut),
				'one' => q(kuaçë zambiku),
				'other' => q(kuaça zambiku),
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
							'jan',
							'shk',
							'mar',
							'pri',
							'maj',
							'qer',
							'korr',
							'gush',
							'sht',
							'tet',
							'nën',
							'dhj'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'j',
							'sh',
							'm',
							'p',
							'm',
							'q',
							'k',
							'g',
							'sh',
							't',
							'n',
							'dh'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janar',
							'shkurt',
							'mars',
							'prill',
							'maj',
							'qershor',
							'korrik',
							'gusht',
							'shtator',
							'tetor',
							'nëntor',
							'dhjetor'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'shk',
							'mar',
							'pri',
							'maj',
							'qer',
							'korr',
							'gush',
							'sht',
							'tet',
							'nën',
							'dhj'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'j',
							'sh',
							'm',
							'p',
							'm',
							'q',
							'k',
							'g',
							'sh',
							't',
							'n',
							'dh'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janar',
							'shkurt',
							'mars',
							'prill',
							'maj',
							'qershor',
							'korrik',
							'gusht',
							'shtator',
							'tetor',
							'nëntor',
							'dhjetor'
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
						mon => 'Hën',
						tue => 'Mar',
						wed => 'Mër',
						thu => 'Enj',
						fri => 'Pre',
						sat => 'Sht',
						sun => 'Die'
					},
					narrow => {
						mon => 'h',
						tue => 'm',
						wed => 'm',
						thu => 'e',
						fri => 'p',
						sat => 'sh',
						sun => 'd'
					},
					short => {
						mon => 'hën',
						tue => 'mar',
						wed => 'mër',
						thu => 'enj',
						fri => 'pre',
						sat => 'sht',
						sun => 'die'
					},
					wide => {
						mon => 'e hënë',
						tue => 'e martë',
						wed => 'e mërkurë',
						thu => 'e enjte',
						fri => 'e premte',
						sat => 'e shtunë',
						sun => 'e diel'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'hën',
						tue => 'mar',
						wed => 'mër',
						thu => 'enj',
						fri => 'pre',
						sat => 'sht',
						sun => 'die'
					},
					narrow => {
						mon => 'h',
						tue => 'm',
						wed => 'm',
						thu => 'e',
						fri => 'p',
						sat => 'sh',
						sun => 'd'
					},
					short => {
						mon => 'hën',
						tue => 'mar',
						wed => 'mër',
						thu => 'enj',
						fri => 'pre',
						sat => 'sht',
						sun => 'die'
					},
					wide => {
						mon => 'e hënë',
						tue => 'e martë',
						wed => 'e mërkurë',
						thu => 'e enjte',
						fri => 'e premte',
						sat => 'e shtunë',
						sun => 'e diel'
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
					abbreviated => {0 => 'tremujori I',
						1 => 'tremujori II',
						2 => 'tremujori III',
						3 => 'tremujori IV'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'tremujori i parë',
						1 => 'tremujori i dytë',
						2 => 'tremujori i tretë',
						3 => 'tremujori i katërt'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Tremujori I',
						1 => 'Tremujori II',
						2 => 'Tremujori III',
						3 => 'Tremujori IV'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Tremujori i 1-rë',
						1 => 'Tremujori i 2-të',
						2 => 'Tremujori i 3-të',
						3 => 'Tremujori i 4-t'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
					'afternoon1' => q{e pasdites},
					'am' => q{p.d.},
					'evening1' => q{e mbrëmjes},
					'midnight' => q{e mesnatës},
					'morning1' => q{e mëngjesit},
					'morning2' => q{e paradites},
					'night1' => q{e natës},
					'noon' => q{e mesditës},
					'pm' => q{m.d.},
				},
				'narrow' => {
					'afternoon1' => q{e pasdites},
					'am' => q{p.d.},
					'evening1' => q{e mbrëmjes},
					'midnight' => q{e mesnatës},
					'morning1' => q{e mëngjesit},
					'morning2' => q{e paradites},
					'night1' => q{e natës},
					'noon' => q{e mesditës},
					'pm' => q{m.d.},
				},
				'wide' => {
					'afternoon1' => q{e pasdites},
					'am' => q{e paradites},
					'evening1' => q{e mbrëmjes},
					'midnight' => q{e mesnatës},
					'morning1' => q{e mëngjesit},
					'morning2' => q{e paradites},
					'night1' => q{e natës},
					'noon' => q{e mesditës},
					'pm' => q{e pasdites},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pasdite},
					'am' => q{p.d.},
					'evening1' => q{mbrëmje},
					'midnight' => q{mesnatë},
					'morning1' => q{mëngjes},
					'morning2' => q{paradite},
					'night1' => q{natë},
					'noon' => q{mesditë},
					'pm' => q{m.d.},
				},
				'narrow' => {
					'afternoon1' => q{pasdite},
					'am' => q{p.d.},
					'evening1' => q{mbrëmje},
					'midnight' => q{mesnatë},
					'morning1' => q{mëngjes},
					'morning2' => q{paradite},
					'night1' => q{natë},
					'noon' => q{mesditë},
					'pm' => q{m.d.},
				},
				'wide' => {
					'afternoon1' => q{pasdite},
					'am' => q{paradite},
					'evening1' => q{mbrëmje},
					'midnight' => q{mesnatë},
					'morning1' => q{mëngjes},
					'morning2' => q{paradite},
					'night1' => q{natë},
					'noon' => q{mesditë},
					'pm' => q{pasdite},
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
				'0' => 'p.K.',
				'1' => 'mb.K.'
			},
			narrow => {
				'0' => 'p.K.',
				'1' => 'mb.K.'
			},
			wide => {
				'0' => 'para Krishtit',
				'1' => 'mbas Krishtit'
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
			'full' => q{EEEE, d MMM y G},
			'long' => q{d MMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			'full' => q{h:mm:ss a, zzzz},
			'long' => q{h:mm:ss a, z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'në' {0}},
			'long' => q{{1} 'në' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'në' {0}},
			'long' => q{{1} 'në' {0}},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd.MM},
			Md => q{d.M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ, y G},
			yyyyQQQQ => q{QQQQ, y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y GGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss, v},
			Hmv => q{HH:mm, v},
			M => q{L},
			MEd => q{E, d.M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'java' W 'e' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{d.M},
			Md => q{d.M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a, v},
			hmv => q{h:mm a, v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ, y},
			yQQQQ => q{QQQQ, y},
			yw => q{'java' w 'e' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0}, {1}',
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
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y GGGGG – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, d.M – E, d.M},
				d => q{E, d.M – E, d.M},
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
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h.a – h.a},
				h => q{h.–h.a},
			},
			hm => {
				a => q{h.mm.a – h.mm.a},
				h => q{h.mm.–h.mm.a},
				m => q{h.mm.–h.mm.a},
			},
			hmv => {
				a => q{h.mm.a – h.mm.a v},
				h => q{h.mm.–h.mm.a v},
				m => q{h.mm.–h.mm.a v},
			},
			hv => {
				a => q{h.a – h.a v},
				h => q{h.–h.a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y GGGGG – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM y G – MMM y G},
				y => q{MMM y G – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm, v},
				m => q{HH:mm – HH:mm, v},
			},
			Hv => {
				H => q{HH – HH, v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d.M – E, d.M},
				d => q{E, d.M – E, d.M},
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
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
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
				a => q{h:mm a – h:mm a, v},
				h => q{h:mm – h:mm a, v},
				m => q{h:mm – h:mm a, v},
			},
			hv => {
				a => q{h a – h a, v},
				h => q{h – h a, v},
			},
			y => {
				y => q{y – y},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
		regionFormat => q(Ora: {0}),
		regionFormat => q(Ora verore: {0}),
		regionFormat => q(Ora standarde: {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Ora verore e Ejkrit [Ako]#,
				'generic' => q#Ora e Ejkrit [Ako]#,
				'standard' => q#Ora standarde e Ejkrit [Ako]#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Ora e Afganistanit#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abixhan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis-Ababë#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algjer#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmarë#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banxhul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantirë#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazavillë#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Buxhumburë#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kajro#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablankë#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Theuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar-es-Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Xhibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ajun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johanesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Xhuba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
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
			exemplarCity => q#Librevilë#,
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
			exemplarCity => q#Niamej#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagëdugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao-Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tuniz#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vint’huk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora e Afrikës Qendrore#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora e Afrikës Lindore#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora standarde e Afrikës Jugore#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora verore e Afrikës Perëndimore#,
				'generic' => q#Ora e Afrikës Perëndimore#,
				'standard' => q#Ora standarde e Afrikës Perëndimore#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora verore e Alaskës#,
				'generic' => q#Ora e Alaskës#,
				'standard' => q#Ora standarde e Alaskës#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Ora verore e Almatit#,
				'generic' => q#Ora e Almatit#,
				'standard' => q#Ora standarde e Almatit#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora verore e Amazonës#,
				'generic' => q#Ora e Amazonës#,
				'standard' => q#Ora standarde e Amazonës#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankorejxh#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilë#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguajana#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Galegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Saltë#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San-Huan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Shën-Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaja#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arubë#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia-Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belizë#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa-Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotë#,
		},
		'America/Boise' => {
			exemplarCity => q#Boizë#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos-Ajres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Gjiri i Kembrixhit#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo-Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajenë#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Çikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Çihahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta-Rikë#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kujaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Denmarkshavën#,
		},
		'America/Dawson' => {
			exemplarCity => q#Douson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Gjiri i Dousonit#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominikë#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Ejrunep#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort-Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Gjiri i Ngrirë#,
		},
		'America/Godthab' => {
			exemplarCity => q#Njuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gjiri i Patës#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Turku i Madh#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granadë#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadelupë#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemalë#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guajakuil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guajanë#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanë#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosijo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knoks, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petërsburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell-Siti, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevëj, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincenes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Uinamak, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Xhamajkë#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Huhui#,
		},
		'America/Juneau' => {
			exemplarCity => q#Xhunou#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montiçelo, Kentaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Limë#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Anxhelos#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luizvilë#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Louer-Prinsis-Kuortër#,
		},
		'America/Maceio' => {
			exemplarCity => q#Makejo#,
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
			exemplarCity => q#Martinikë#,
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
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Qyteti i Meksikës#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrej#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasao#,
		},
		'America/New_York' => {
			exemplarCity => q#Nju-Jork#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronja#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beula, Dakota e Veriut#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Qendër, Dakota e Veriut#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nju-Salem, Dakota e Veriut#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ohinaga#,
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
			exemplarCity => q#Feniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto-Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto-Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta-Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Lumi i Shirave#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Gryka Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Rexhina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio-Branko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa-Izabela#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo-Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao-Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itokorturmit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sen-Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Shën-Gjon#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Shën-Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Shën-Luçia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Shën-Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Shën-Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Rryma e Shpejtë#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Dhule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Gjiri i Bubullimës#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortolë#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Uajt’hors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Uinipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Jakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Jellounajf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora verore e SHBA-së Qendrore#,
				'generic' => q#Ora e SHBA-së Qendrore#,
				'standard' => q#Ora standarde e SHBA-së Qendrore#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora verore e SHBA-së Lindore#,
				'generic' => q#Ora e SHBA-së Lindore#,
				'standard' => q#Ora standarde e SHBA-së Lindore#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora verore e Territoreve Amerikane të Brezit Malor#,
				'generic' => q#Ora e Territoreve Amerikane të Brezit Malor#,
				'standard' => q#Ora standarde e Territoreve Amerikane të Brezit Malor#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora verore e Territoreve Amerikane të Bregut të Paqësorit#,
				'generic' => q#Ora e Territoreve Amerikane të Bregut të Paqësorit#,
				'standard' => q#Ora standarde e Territoreve Amerikane të Bregut të Paqësorit#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Ora verore e Anadirit#,
				'generic' => q#Ora e Anadirit#,
				'standard' => q#Ora standarde e Anadirit#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kejsi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dejvis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urvilë#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Mekuari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mauson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mekmurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rodherë#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Sjoua#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora verore e Apias#,
				'generic' => q#Ora e Apias#,
				'standard' => q#Ora standarde e Apias#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Ora verore e Aktaut#,
				'generic' => q#Ora e Aktaut#,
				'standard' => q#Ora standarde e Aktaut#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Ora verore e Aktobit#,
				'generic' => q#Ora e Aktobit#,
				'standard' => q#Ora standarde e Aktobit#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora verore arabe#,
				'generic' => q#Ora arabe#,
				'standard' => q#Ora standarde arabe#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Long’jëbjen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora verore e Argjentinës#,
				'generic' => q#Ora e Argjentinës#,
				'standard' => q#Ora standarde e Argjentinës#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora verore e Argjentinës Perëndimore#,
				'generic' => q#Ora e Argjentinës Perëndimore#,
				'standard' => q#Ora standarde e Argjentinës Perëndimore#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora verore e Armenisë#,
				'generic' => q#Ora e Armenisë#,
				'standard' => q#Ora standarde e Armenisë#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
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
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrejn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutë#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Çoibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
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
		'Asia/Famagusta' => {
			exemplarCity => q#Famagustë#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong-Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Xhakartë#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Xhajapurë#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamçatkë#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaçi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Kandigë#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuçing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manilë#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozia#,
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
			exemplarCity => q#Pnom-Pen#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Penian#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Çi-Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shangai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapor#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vjentianë#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora verore e Atlantikut#,
				'generic' => q#Ora e Atlantikut#,
				'standard' => q#Ora standarde e Atlantikut#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azore#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermude#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kepi i Gjelbër#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Xhorxha e Jugut#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Shën-Elenë#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelajde#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbejn#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Brokën-Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kuri#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindëmen#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord-Houi#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Përth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidnej#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora verore e Australisë Qendrore#,
				'generic' => q#Ora e Australisë Qendrore#,
				'standard' => q#Ora standarde e Australisë Qendrore#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora verore e Australisë Qendroro-Perëndimore#,
				'generic' => q#Ora e Australisë Qendroro-Perëndimore#,
				'standard' => q#Ora standarde e Australisë Qendroro-Perëndimore#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora verore e Australisë Lindore#,
				'generic' => q#Ora e Australisë Lindore#,
				'standard' => q#Ora standarde e Australisë Lindore#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora verore e Australisë Perëndimore#,
				'generic' => q#Ora e Australisë Perëndimore#,
				'standard' => q#Ora standarde e Australisë Perëndimore#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora verore e Azerbajxhanit#,
				'generic' => q#Ora e Azerbajxhanit#,
				'standard' => q#Ora standarde e Azerbajxhanit#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora verore e Azoreve#,
				'generic' => q#Ora e Azoreve#,
				'standard' => q#Ora standarde e Azoreve#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora verore e Bangladeshit#,
				'generic' => q#Ora e Bangladeshit#,
				'standard' => q#Ora standarde e Bangladeshit#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora e Butanit#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora e Bolivisë#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora verore e Brazilisë#,
				'generic' => q#Ora e Brazilisë#,
				'standard' => q#Ora standarde e Brazilisë#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora e Brunei-Durasalamit#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora verore e Kepit të Gjelbër#,
				'generic' => q#Ora e Kepit të Gjelbër#,
				'standard' => q#Ora standarde e Kepit të Gjelbër#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Ora e Kejsit#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora e Kamorros#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora verore e Katamit#,
				'generic' => q#Ora e Katamit#,
				'standard' => q#Ora standarde e Katamit#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora verore e Kilit#,
				'generic' => q#Ora e Kilit#,
				'standard' => q#Ora standarde e Kilit#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora verore e Kinës#,
				'generic' => q#Ora e Kinës#,
				'standard' => q#Ora standarde e Kinës#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Ora verore e Çoibalsanit#,
				'generic' => q#Ora e Çoibalsanit#,
				'standard' => q#Ora standarde e Çoibalsanit#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora e Ishullit të Krishtlindjeve#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora e Ishujve Kokos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora verore e Kolumbisë#,
				'generic' => q#Ora e Kolumbisë#,
				'standard' => q#Ora standarde e Kolumbisë#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora verore e Ishujve Kuk#,
				'generic' => q#Ora e Ishujve Kuk#,
				'standard' => q#Ora standarde e Ishujve Kuk#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora verore e Kubës#,
				'generic' => q#Ora e Kubës#,
				'standard' => q#Ora standarde e Kubës#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora e Dejvisit#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora e Dumont-d’Urvilës#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora e Timorit Lindor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora verore e Ishullit të Pashkës#,
				'generic' => q#Ora e Ishullit të Pashkës#,
				'standard' => q#Ora standarde e Ishullit të Pashkës#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora e Ekuadorit#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ora universale e koordinuar#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Qytet i panjohur#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorrë#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athinë#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislavë#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruksel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukuresht#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kishineu#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Ora strandarde e Irlandës#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gjibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernsej#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ishulli i Manit#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stamboll#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Xhersej#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbonë#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubjanë#,
		},
		'Europe/London' => {
			exemplarCity => q#Londër#,
			long => {
				'daylight' => q#Ora verore britanike#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Maltë#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskë#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgoricë#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Pragë#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rigë#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Romë#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San-Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevë#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Shkup#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofje#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiranë#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vjenë#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varshavë#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zyrih#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora verore e Evropës Qendrore#,
				'generic' => q#Ora e Evropës Qendrore#,
				'standard' => q#Ora standarde e Evropës Qendrore#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora verore e Evropës Lindore#,
				'generic' => q#Ora e Evropës Lindore#,
				'standard' => q#Ora standarde e Evropës Lindore#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora e Evropës së Largët Lindore#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora verore e Evropës Perëndimore#,
				'generic' => q#Ora e Evropës Perëndimore#,
				'standard' => q#Ora standarde e Evropës Perëndimore#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora verore e Ishujve Falkland#,
				'generic' => q#Ora e Ishujve Falkland#,
				'standard' => q#Ora standarde e Ishujve Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora verore e Fixhit#,
				'generic' => q#Ora e Fixhit#,
				'standard' => q#Ora standarde e Fixhit#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora e Guajanës Franceze#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora e Territoreve Jugore dhe Antarktike Franceze#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora e Grinuiçit#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora e Galapagosit#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora e Gambierit#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora verore e Gjeorgjisë#,
				'generic' => q#Ora e Gjeorgjisë#,
				'standard' => q#Ora standarde e Gjeorgjisë#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora e Ishujve Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora verore e Grenlandës Lindore#,
				'generic' => q#Ora e Grenlandës Lindore#,
				'standard' => q#Ora standarde e Grenlandës Lindore#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora verore e Grënlandës Perëndimore#,
				'generic' => q#Ora e Grënlandës Perëndimore#,
				'standard' => q#Ora standarde e Grënlandës Perëndimore#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Ora e Guamit#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora e Gjirit#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora e Guajanës#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora verore e Ishujve Hauai-Aleutian#,
				'generic' => q#Ora e Ishujve Hauai-Aleutian#,
				'standard' => q#Ora standarde e Ishujve Hauai-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora verore e Hong-Kongut#,
				'generic' => q#Ora e Hong-Kongut#,
				'standard' => q#Ora standarde e Hong-Kongut#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora verore e Hovdit#,
				'generic' => q#Ora e Hovdit#,
				'standard' => q#Ora standarde e Hovdit#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora standarde e Indisë#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Çagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krishtlindje#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komore#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Majotë#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora e Oqeanit Indian#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora e Indokinës#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora e Indonezisë Qendrore#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora e Indonezisë Lindore#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora e Indonezisë Perëndimore#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora verore e Iranit#,
				'generic' => q#Ora e Iranit#,
				'standard' => q#Ora standarde e Iranit#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora verore e Irkutskut#,
				'generic' => q#Ora e Irkutskut#,
				'standard' => q#Ora standarde e Irkutskut#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora verore e Izraelit#,
				'generic' => q#Ora e Izraelit#,
				'standard' => q#Ora standarde e Izraelit#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora verore e Japonisë#,
				'generic' => q#Ora e Japonisë#,
				'standard' => q#Ora standarde e Japonisë#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Ora verore e Petropavllovsk-Kamçatkës#,
				'generic' => q#Ora e Petropavllovsk-Kamçatkës#,
				'standard' => q#Ora standarde e Petropavllovsk-Kamçatkës#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora e Kazakistanit Lindor#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora e Kazakistanit Perëndimor#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora verore koreane#,
				'generic' => q#Ora koreane#,
				'standard' => q#Ora standarde koreane#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora e Kosrës#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora verore e Krasnojarskut#,
				'generic' => q#Ora e Krasnojarskut#,
				'standard' => q#Ora standarde e Krasnojarskut#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora e Kirgizisë#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Ora e Lankasë#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora e Ishujve Sporadikë Ekuatorialë#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora verore e Lord-Houit#,
				'generic' => q#Ora e Lord-Houit#,
				'standard' => q#Ora standarde e Lord-Houit#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Ora verore e Makaos#,
				'generic' => q#Ora e Makaos#,
				'standard' => q#Ora standarde e Makaos#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ora e Ishullit Makuari#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora verore e Magadanit#,
				'generic' => q#Ora e Magadanit#,
				'standard' => q#Ora standarde e Magadanit#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora e Malajzisë#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora e Maldiveve#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora e Ishujve Markezë#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ora e Ishujve Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora verore e Mauritiusit#,
				'generic' => q#Ora e Mauritiusit#,
				'standard' => q#Ora standarde e Mauritiusit#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora e Mausonit#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ora verore e Meksikës Veriperëndimore#,
				'generic' => q#Ora e Meksikës Veriperëndimore#,
				'standard' => q#Ora standarde e Meksikës Veriperëndimore#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora verore e Territoreve Meksikane të Bregut të Paqësorit#,
				'generic' => q#Ora e Territoreve Meksikane të Bregut të Paqësorit#,
				'standard' => q#Ora standarde e Territoreve Meksikane të Bregut të Paqësorit#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora verore e Ulan-Batorit#,
				'generic' => q#Ora e Ulan-Batorit#,
				'standard' => q#Ora standarde e Ulan-Batorit#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora verore e Moskës#,
				'generic' => q#Ora e Moskës#,
				'standard' => q#Ora standarde e Moskës#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora e Mianmarit#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora e Naurusë#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora e Nepalit#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora verore e Kaledonisë së Re#,
				'generic' => q#Ora e Kaledonisë së Re#,
				'standard' => q#Ora standarde e Kaledonisë së Re#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora verore e Zelandës së Re#,
				'generic' => q#Ora e Zelandës së Re#,
				'standard' => q#Ora standarde e Zelandës së Re#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora verore e Njufaundlendit [Tokës së Re]#,
				'generic' => q#Ora e Njufaundlendit [Tokës së Re]#,
				'standard' => q#Ora standarde e Njufaundlendit [Tokës së Re]#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora e Niuesë#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora verore e Ishullit Norfolk#,
				'generic' => q#Ora e Ishullit Norfolk#,
				'standard' => q#Ora standarde e Ishullit Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora verore e Fernando-de-Noronjës#,
				'generic' => q#Ora e Fernando-de-Noronjës#,
				'standard' => q#Ora standarde e Fernando-de-Noronjës#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Ora e Ishujve të Marianës së Veriut#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora verore e Novosibirskut#,
				'generic' => q#Ora e Novosibirskut#,
				'standard' => q#Ora standarde e Novosibirskut#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora verore e Omskut#,
				'generic' => q#Ora e Omskut#,
				'standard' => q#Ora standarde e Omskut#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Okland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bunganvilë#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Çatman#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pashkë#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbur#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fixhi#,
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
			exemplarCity => q#Guadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Xhonston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimat#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosre#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuaxhalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Mahuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markez#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Miduej#,
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
			exemplarCity => q#Pago-Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponapei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port-Moresbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotongë#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Taravë#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Çuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Uejk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uollis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora verore e Pakistanit#,
				'generic' => q#Ora e Pakistanit#,
				'standard' => q#Ora standarde e Pakistanit#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora e Palaut#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora e Guinesë së Re-Papua#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora Verore e Paraguait#,
				'generic' => q#Ora e Paraguait#,
				'standard' => q#Ora standarde e Paraguait#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora verore e Perusë#,
				'generic' => q#Ora e Perusë#,
				'standard' => q#Ora standarde e Perusë#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora verore e Filipineve#,
				'generic' => q#Ora e Filipineve#,
				'standard' => q#Ora standarde e Filipineve#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora e Ishujve Feniks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora verore e Shën-Pier dhe Mikelon#,
				'generic' => q#Ora e Shën-Pier dhe Mikelon#,
				'standard' => q#Ora standarde e Shën-Pier dhe Mikelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora e Pitkernit#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora e Ponapeit#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora e Penianit#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Ora verore e Kizilordit#,
				'generic' => q#Ora e Kizilordit#,
				'standard' => q#Ora standarde e Kizilordit#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora e Reunionit#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora e Rodherës#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora verore e Sakalinit#,
				'generic' => q#Ora e Sakalinit#,
				'standard' => q#Ora standarde e Sakalinit#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Ora verore e Samarës#,
				'generic' => q#Ora e Samarës#,
				'standard' => q#Ora standarde e Samarës#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora verore e Samoas#,
				'generic' => q#Ora e Samoas#,
				'standard' => q#Ora standarde e Samoas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora e Sejshelleve#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora e Singaporit#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora e Ishujve Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora e Xhorxhas të Jugut#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora e Surinamit#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora e Sjouit#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora e Tahitit#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora verore e Tajpeit#,
				'generic' => q#Ora e Tajpeit#,
				'standard' => q#Ora standarde e Tajpeit#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora e Taxhikistanit#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora e Tokelaut#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora verore e Tongës#,
				'generic' => q#Ora e Tongës#,
				'standard' => q#Ora standarde e Tongës#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora e Çukut#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora verore e Turkmenistanit#,
				'generic' => q#Ora e Turkmenistanit#,
				'standard' => q#Ora standarde e Turkmenistanit#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora e Tuvalusë#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora verore e Uruguait#,
				'generic' => q#Ora e Uruguait#,
				'standard' => q#Ora standarde e Uruguait#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora verore e Uzbekistanit#,
				'generic' => q#Ora e Uzbekistanit#,
				'standard' => q#Ora standarde e Uzbekistanit#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora verore e Vanuatusë#,
				'generic' => q#Ora e Vanuatusë#,
				'standard' => q#Ora standarde e Vanuatusë#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora e Venezuelës#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora verore e Vladivostokut#,
				'generic' => q#Ora e Vladivostokut#,
				'standard' => q#Ora standarde e Vladivostokut#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora verore e Volgogradit#,
				'generic' => q#Ora e Volgogradit#,
				'standard' => q#Ora standarde e Volgogradit#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora e Vostokut#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora e Ishullit Uejk#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora e Uollisit dhe Futunës#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora verore e Jakutskut#,
				'generic' => q#Ora e Jakutskut#,
				'standard' => q#Ora standarde e Jakutskut#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora verore e Ekaterinburgut#,
				'generic' => q#Ora e Ekaterinburgut#,
				'standard' => q#Ora standarde e Ekaterinburgut#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora e Jukonit#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
