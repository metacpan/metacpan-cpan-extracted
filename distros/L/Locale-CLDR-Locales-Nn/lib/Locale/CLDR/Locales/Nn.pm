=head1

Locale::CLDR::Locales::Nn - Package for language Norwegian Nynorsk

=cut

package Locale::CLDR::Locales::Nn;
# This file auto generated from Data\common\main\nn.xml
#	on Fri 13 Apr  7:24:08 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-reale' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eitt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-reale' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(éin),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(to),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fire),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fem),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seks),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sju),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åtte),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ni),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ti),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elleve),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretten),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjorten),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(femten),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(seksten),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sytten),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(atten),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nitten),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(søtti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundre[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusen[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(éin miljon[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(éin miljard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(éin biljon[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(éin biljard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljarder[ →→]),
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
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
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
					rule => q(←← hundre[ og →→]),
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
				'aa' => 'afar',
 				'ab' => 'abkhasisk',
 				'ace' => 'achinesisk',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adygeisk',
 				'ae' => 'avestisk',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadisk',
 				'ale' => 'aleutisk',
 				'alt' => 'sør-altaj',
 				'am' => 'amharisk',
 				'an' => 'aragonsk',
 				'ang' => 'gammalengelsk',
 				'anp' => 'angika',
 				'ar' => 'arabisk',
 				'ar_001' => 'moderne standardarabisk',
 				'arc' => 'arameisk',
 				'arn' => 'mapudungun',
 				'arp' => 'arapaho',
 				'arw' => 'arawak',
 				'as' => 'assamesisk',
 				'asa' => 'asu (Tanzania)',
 				'ast' => 'asturisk',
 				'av' => 'avarisk',
 				'awa' => 'avadhi',
 				'ay' => 'aymara',
 				'az' => 'aserbajdsjansk',
 				'ba' => 'basjkirsk',
 				'bal' => 'baluchi',
 				'ban' => 'balinesisk',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'be' => 'kviterussisk',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena (Tanzania)',
 				'bg' => 'bulgarsk',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetansk',
 				'br' => 'bretonsk',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosnisk',
 				'bss' => 'bakossi',
 				'bua' => 'burjatisk',
 				'bug' => 'buginesisk',
 				'byn' => 'blin',
 				'ca' => 'katalansk',
 				'cad' => 'caddo',
 				'car' => 'carib',
 				'cch' => 'atsam',
 				'ce' => 'tsjetsjensk',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'tsjagataisk',
 				'chk' => 'chuukesisk',
 				'chm' => 'mari',
 				'chn' => 'chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewiansk',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'sorani',
 				'co' => 'korsikansk',
 				'cop' => 'koptisk',
 				'cr' => 'cree',
 				'crh' => 'krimtatarisk',
 				'crs' => 'seselwa (fransk-kreolsk)',
 				'cs' => 'tsjekkisk',
 				'csb' => 'kasjubisk',
 				'cu' => 'kyrkjeslavisk',
 				'cv' => 'tsjuvansk',
 				'cy' => 'walisisk',
 				'da' => 'dansk',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tysk',
 				'del' => 'delaware',
 				'den' => 'slavej',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'lågsorbisk',
 				'dua' => 'duala',
 				'dum' => 'mellomnederlandsk',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'gammalegyptisk',
 				'eka' => 'ekajuk',
 				'el' => 'gresk',
 				'elx' => 'elamite',
 				'en' => 'engelsk',
 				'en_GB' => 'britisk engelsk',
 				'enm' => 'mellomengelsk',
 				'eo' => 'esperanto',
 				'es' => 'spansk',
 				'et' => 'estisk',
 				'eu' => 'baskisk',
 				'ewo' => 'ewondo',
 				'fa' => 'persisk',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulfulde',
 				'fi' => 'finsk',
 				'fil' => 'filippinsk',
 				'fj' => 'fijiansk',
 				'fo' => 'færøysk',
 				'fon' => 'fon',
 				'fr' => 'fransk',
 				'frm' => 'mellomfransk',
 				'fro' => 'gammalfransk',
 				'frr' => 'nordfrisisk',
 				'frs' => 'austfrisisk',
 				'fur' => 'friulisk',
 				'fy' => 'vestfrisisk',
 				'ga' => 'irsk',
 				'gaa' => 'ga',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'skotsk-gælisk',
 				'gez' => 'geez',
 				'gil' => 'gilbertese',
 				'gl' => 'galicisk',
 				'gmh' => 'mellomhøgtysk',
 				'gn' => 'guarani',
 				'goh' => 'gammalhøgtysk',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotisk',
 				'grb' => 'grebo',
 				'grc' => 'gammalgresk',
 				'gsw' => 'sveitsertysk',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'hawaiisk',
 				'he' => 'hebraisk',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hit' => 'hettittisk',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'kroatisk',
 				'hsb' => 'høgsorbisk',
 				'ht' => 'haitisk',
 				'hu' => 'ungarsk',
 				'hup' => 'hupa',
 				'hy' => 'armensk',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesisk',
 				'ie' => 'interlingue',
 				'ig' => 'ibo',
 				'ii' => 'sichuan-yi',
 				'ik' => 'inupiak',
 				'ilo' => 'iloko',
 				'inh' => 'ingusjisk',
 				'io' => 'ido',
 				'is' => 'islandsk',
 				'it' => 'italiensk',
 				'iu' => 'inuktitut',
 				'ja' => 'japansk',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'jødepersisk',
 				'jrb' => 'jødearabisk',
 				'jv' => 'javanesisk',
 				'ka' => 'georgisk',
 				'kaa' => 'karakalpakisk',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardisk',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kg' => 'kikongo',
 				'kha' => 'khasi',
 				'kho' => 'khotanesisk',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kasakhisk',
 				'kkj' => 'kako',
 				'kl' => 'grønlandsk (kalaallisut)',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreansk',
 				'kok' => 'konkani',
 				'kos' => 'kosraeansk',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'karelsk',
 				'kru' => 'kurukh',
 				'ks' => 'kasjmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kølnsk',
 				'ku' => 'kurdisk',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'kornisk',
 				'ky' => 'kirgisisk',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgsk',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgisk',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laotisk',
 				'lol' => 'mongo',
 				'loz' => 'lozi',
 				'lrc' => 'nord-lurisk',
 				'lt' => 'litauisk',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'olulujia',
 				'lv' => 'latvisk',
 				'mad' => 'maduresisk',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'madagassisk',
 				'mga' => 'mellomirsk',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallesisk',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonsk',
 				'ml' => 'malayalam',
 				'mn' => 'mongolsk',
 				'mnc' => 'mandsju',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malayisk',
 				'mt' => 'maltesisk',
 				'mua' => 'mundang',
 				'mul' => 'fleire språk',
 				'mus' => 'creek',
 				'mwl' => 'mirandesisk',
 				'mwr' => 'marwari',
 				'my' => 'burmesisk',
 				'myv' => 'erzia',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nap' => 'napolitansk',
 				'naq' => 'nama',
 				'nb' => 'bokmål',
 				'nd' => 'nord-ndebele',
 				'nds' => 'lågtysk',
 				'nds_NL' => 'lågsaksisk',
 				'ne' => 'nepalsk',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niuisk',
 				'nl' => 'nederlandsk',
 				'nl_BE' => 'flamsk',
 				'nmg' => 'kwasio',
 				'nn' => 'nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norsk',
 				'nog' => 'nogai',
 				'non' => 'gammalnorsk',
 				'nqo' => 'n’ko',
 				'nr' => 'sør-ndebele',
 				'nso' => 'nordsotho',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'klassisk newarisk',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitansk',
 				'oj' => 'ojibwa',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossetisk',
 				'osa' => 'osage',
 				'ota' => 'ottomansk tyrkisk',
 				'pa' => 'panjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauisk',
 				'pcm' => 'nigeriansk pidgin',
 				'peo' => 'gammalpersisk',
 				'phn' => 'fønikisk',
 				'pi' => 'pali',
 				'pl' => 'polsk',
 				'pon' => 'ponapisk',
 				'prg' => 'prøyssisk',
 				'pro' => 'gammalprovençalsk',
 				'ps' => 'pashto',
 				'pt' => 'portugisisk',
 				'qu' => 'quechua',
 				'quc' => 'k’iche',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongansk',
 				'rm' => 'retoromansk',
 				'rn' => 'rundi',
 				'ro' => 'rumensk',
 				'ro_MD' => 'moldavisk',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'rot',
 				'ru' => 'russisk',
 				'rup' => 'arumensk',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'sam' => 'samaritansk arameisk',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardinsk',
 				'scn' => 'siciliansk',
 				'sco' => 'skotsk',
 				'sd' => 'sindhi',
 				'se' => 'nordsamisk',
 				'seh' => 'sena',
 				'sel' => 'selkupisk',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'sango',
 				'sga' => 'gammalirsk',
 				'sh' => 'serbokroatisk',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'si' => 'singalesisk',
 				'sid' => 'sidamo',
 				'sk' => 'slovakisk',
 				'sl' => 'slovensk',
 				'sm' => 'samoansk',
 				'sma' => 'sørsamisk',
 				'smj' => 'lulesamisk',
 				'smn' => 'enaresamisk',
 				'sms' => 'skoltesamisk',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdisk',
 				'sq' => 'albansk',
 				'sr' => 'serbisk',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sørsotho',
 				'su' => 'sundanesisk',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerisk',
 				'sv' => 'svensk',
 				'sw' => 'swahili',
 				'swb' => 'shimaore',
 				'syc' => 'klassisk syrisk',
 				'syr' => 'syrisk',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadsjikisk',
 				'th' => 'thai',
 				'ti' => 'tigrinja',
 				'tig' => 'tigré',
 				'tiv' => 'tivi',
 				'tk' => 'turkmensk',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tmh' => 'tamasjek',
 				'tn' => 'tswana',
 				'to' => 'tongansk',
 				'tog' => 'tonga (Nyasa)',
 				'tpi' => 'tok pisin',
 				'tr' => 'tyrkisk',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatarisk',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitisk',
 				'tyv' => 'tuvinisk',
 				'tzm' => 'sentral-tamazight',
 				'udm' => 'udmurt',
 				'ug' => 'uigurisk',
 				'uga' => 'ugaritisk',
 				'uk' => 'ukrainsk',
 				'umb' => 'umbundu',
 				'und' => 'ukjent språk',
 				'ur' => 'urdu',
 				'uz' => 'usbekisk',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamesisk',
 				'vo' => 'volapyk',
 				'vot' => 'votisk',
 				'vun' => 'vunjo',
 				'wa' => 'vallonsk',
 				'wae' => 'walsertysk',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wo' => 'wolof',
 				'xal' => 'kalmykisk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapesisk',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddisk',
 				'yo' => 'joruba',
 				'yue' => 'kantonesisk',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymbol',
 				'zen' => 'zenaga',
 				'zgh' => 'standard marokkansk tamazight',
 				'zh' => 'kinesisk',
 				'zh_Hans' => 'forenkla kinesisk',
 				'zh_Hant' => 'tradisjonell kinesisk',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'utan språkleg innhald',
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
			'Arab' => 'arabisk',
 			'Armi' => 'armisk',
 			'Armn' => 'armensk',
 			'Avst' => 'avestisk',
 			'Bali' => 'balinesisk',
 			'Bamu' => 'bamun',
 			'Batk' => 'batak',
 			'Beng' => 'bengalsk',
 			'Blis' => 'blissymbol',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'punktskrift',
 			'Bugi' => 'buginesisk',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'felles kanadiske urspråksstavingar',
 			'Cari' => 'karisk',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'koptisk',
 			'Cprt' => 'kypriotisk',
 			'Cyrl' => 'kyrillisk',
 			'Cyrs' => 'kyrillisk (kyrkjeslavisk variant)',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Egyd' => 'egyptisk demotisk',
 			'Egyh' => 'egyptisk hieratisk',
 			'Egyp' => 'egyptiske hieroglyfar',
 			'Ethi' => 'etiopisk',
 			'Geok' => 'khutsuri (asomtavruli og nuskhuri)',
 			'Geor' => 'georgisk',
 			'Glag' => 'glagolittisk',
 			'Goth' => 'gotisk',
 			'Gran' => 'gammaltamilsk',
 			'Grek' => 'gresk',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han med bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'forenkla',
 			'Hans@alt=stand-alone' => 'forenkla han',
 			'Hant' => 'tradisjonell',
 			'Hant@alt=stand-alone' => 'tradisjonell han',
 			'Hebr' => 'hebraisk',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawk hmong',
 			'Hrkt' => 'japansk stavingsskrifter',
 			'Hung' => 'gammalungarsk',
 			'Inds' => 'indus',
 			'Ital' => 'gammalitalisk',
 			'Jamo' => 'jamo',
 			'Java' => 'javanesisk',
 			'Jpan' => 'japansk',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreansk',
 			'Kthi' => 'kaithisk',
 			'Lana' => 'lanna',
 			'Laoo' => 'laotisk',
 			'Latf' => 'latinsk (frakturvariant)',
 			'Latg' => 'latinsk (gælisk variant)',
 			'Latn' => 'latinsk',
 			'Lepc' => 'lepcha',
 			'Limb' => 'lumbu',
 			'Lina' => 'lineær A',
 			'Linb' => 'lineær B',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'lykisk',
 			'Lydi' => 'lydisk',
 			'Mand' => 'mandaisk',
 			'Mani' => 'manikeisk',
 			'Maya' => 'maya-hieroglyfar',
 			'Mero' => 'meroitisk',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolsk',
 			'Moon' => 'moon',
 			'Mtei' => 'meitei-mayek',
 			'Mymr' => 'burmesisk',
 			'Nkoo' => 'n’ko',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol-chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'odia',
 			'Osma' => 'osmanya',
 			'Perm' => 'gammalpermisk',
 			'Phag' => 'phags-pa',
 			'Phli' => 'inskripsjonspahlavi',
 			'Phlp' => 'salmepahlavi',
 			'Phlv' => 'pahlavi',
 			'Phnx' => 'fønikisk',
 			'Plrd' => 'pollard-fonetisk',
 			'Prti' => 'inskripsjonsparthisk',
 			'Rjng' => 'rejang',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runer',
 			'Samr' => 'samaritansk',
 			'Sara' => 'sarati',
 			'Sarb' => 'gammalsydarabisk',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'teiknskrift',
 			'Shaw' => 'shavisk',
 			'Sinh' => 'singalesisk',
 			'Sund' => 'sundanesisk',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syriakisk',
 			'Syre' => 'syriakisk (estrangelo-variant)',
 			'Syrj' => 'syriakisk (vestleg variant)',
 			'Syrn' => 'syriakisk (austleg variant)',
 			'Tagb' => 'tagbanwa',
 			'Tale' => 'tai le',
 			'Talu' => 'ny tai lue',
 			'Taml' => 'tamilsk',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thai',
 			'Tibt' => 'tibetansk',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaritisk',
 			'Vaii' => 'vai',
 			'Visp' => 'synleg tale',
 			'Xpeo' => 'gammalpersisk',
 			'Xsux' => 'sumero-akkadisk kileskrift',
 			'Yiii' => 'yi',
 			'Zinh' => 'nedarva',
 			'Zmth' => 'matematisk notasjon',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symbol',
 			'Zxxx' => 'språk utan skrift',
 			'Zyyy' => 'felles',
 			'Zzzz' => 'ukjend skrift',

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
			'001' => 'verda',
 			'002' => 'Afrika',
 			'003' => 'Nord-Amerika',
 			'005' => 'Sør-Amerika',
 			'009' => 'Oseania',
 			'011' => 'Vest-Afrika',
 			'013' => 'Sentral-Amerika',
 			'014' => 'Aust-Afrika',
 			'015' => 'Nord-Afrika',
 			'017' => 'Sentral-Afrika',
 			'018' => 'Sørlege Afrika',
 			'019' => 'Amerika',
 			'021' => 'nordlege Amerika',
 			'029' => 'Karibia',
 			'030' => 'Aust-Asia',
 			'034' => 'Sør-Asia',
 			'035' => 'Søraust-Asia',
 			'039' => 'Sør-Europa',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Sentral-Asia',
 			'145' => 'Vest-Asia',
 			'150' => 'Europa',
 			'151' => 'Aust-Europa',
 			'154' => 'Nord-Europa',
 			'155' => 'Vest-Europa',
 			'419' => 'Latin-Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Dei sameinte arabiske emirata',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua og Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikansk Samoa',
 			'AT' => 'Austerrike',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Aserbajdsjan',
 			'BA' => 'Bosnia-Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibisk Nederland',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetøya',
 			'BW' => 'Botswana',
 			'BY' => 'Kviterussland',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Kokosøyane',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Den demokratiske republikken Kongo',
 			'CF' => 'Den sentralafrikanske republikken',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Republikken Kongo',
 			'CH' => 'Sveits',
 			'CI' => 'Elfenbeinskysten',
 			'CK' => 'Cookøyane',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertonøya',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kapp Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmasøya',
 			'CY' => 'Kypros',
 			'CZ' => 'Tsjekkia',
 			'DE' => 'Tyskland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominica',
 			'DO' => 'Den dominikanske republikken',
 			'DZ' => 'Algerie',
 			'EA' => 'Ceuta og Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypt',
 			'EH' => 'Vest-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spania',
 			'ET' => 'Etiopia',
 			'EU' => 'EU',
 			'EZ' => 'eurosona',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsøyane',
 			'FK@alt=variant' => 'Falklandsøyane (Islas Malvinas)',
 			'FM' => 'Mikronesiaføderasjonen',
 			'FO' => 'Færøyane',
 			'FR' => 'Frankrike',
 			'GA' => 'Gabon',
 			'GB' => 'Storbritannia',
 			'GB@alt=short' => 'Storbritannia',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Fransk Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grønland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatorial-Guinea',
 			'GR' => 'Hellas',
 			'GS' => 'Sør-Georgia og Sør-Sandwichøyene',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong S.A.R. Kina',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardøya og McDonaldøyane',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanariøyane',
 			'ID' => 'Indonesia',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Man',
 			'IN' => 'India',
 			'IO' => 'Det britiske territoriet I Indiahavet',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodsja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorane',
 			'KN' => 'Saint Kitts og Nevis',
 			'KP' => 'Nord-Korea',
 			'KR' => 'Sør-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymanøyane',
 			'KZ' => 'Kasakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalløyane',
 			'MK' => 'Makedonia',
 			'MK@alt=variant' => 'Den tidlegare jugoslaviske republikken Makedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao S.A.R. Kina',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nord-Marianane',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivane',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Ny-Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkøya',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederland',
 			'NO' => 'Noreg',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransk Polynesia',
 			'PG' => 'Papua Ny-Guinea',
 			'PH' => 'Filippinane',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinsk territorium',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Ytre Oseania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi-Arabia',
 			'SB' => 'Salomonøyane',
 			'SC' => 'Seychellane',
 			'SD' => 'Sudan',
 			'SE' => 'Sverige',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard og Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sør-Sudan',
 			'ST' => 'São Tomé og Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicosøyane',
 			'TD' => 'Tsjad',
 			'TF' => 'Dei franske sørterritoria',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadsjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste (Aust-Timor)',
 			'TL@alt=variant' => 'Aust-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Tyrkia',
 			'TT' => 'Trinidad og Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'USAs ytre småøyar',
 			'UN' => 'SN',
 			'US' => 'USA',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstaten',
 			'VC' => 'St. Vincent og Grenadinane',
 			'VE' => 'Venezuela',
 			'VG' => 'Dei britiske Jomfruøyane',
 			'VI' => 'Dei amerikanske Jomfruøyane',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis og Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sør-Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'ukjent område',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'tradisjonell tysk ortografi',
 			'1994' => 'standardisert resisk ortografi',
 			'1996' => 'tysk ortografi frå 1996',
 			'1606NICT' => 'nyare mellomfransk til 1606',
 			'1694ACAD' => 'eldre nyfransk',
 			'AREVELA' => 'austarmensk',
 			'AREVMDA' => 'vestarmensk',
 			'BAKU1926' => 'samla tyrkisk-latinsk alfabet',
 			'BISKE' => 'san giorgio- og biladialekt',
 			'BOONT' => 'boontling',
 			'FONIPA' => 'det internasjonale fonetiske alfabetet (IPA)',
 			'FONUPA' => 'det uralske fonetiske alfabetet UPA',
 			'LIPAW' => 'resian, lipovazdialekt',
 			'MONOTON' => 'monotonisk rettskriving',
 			'NEDIS' => 'natisonedialekt',
 			'NJIVA' => 'gniva- og njivadialekt',
 			'OSOJS' => 'oseacco- og osojanedialekt',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonisk rettskriving',
 			'POSIX' => 'dataspråk',
 			'REVISED' => 'revidert rettskriving',
 			'ROZAJ' => 'resisk dialekt',
 			'SAAHO' => 'saaho-dialekt',
 			'SCOTLAND' => 'skotsk standard engelsk',
 			'SCOUSE' => 'scouse-dialekt',
 			'SOLBA' => 'stolvizza- og solbicadialekt',
 			'TARASK' => 'taraskievica-ortografi',
 			'VALENCIA' => 'valensisk dialekt',
 			'WADEGILE' => 'wade-giles',

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
 			'cf' => 'valutaformat',
 			'collation' => 'sorteringsrekkjefølgje',
 			'currency' => 'valuta',
 			'hc' => 'timesyklus (12 eller 24)',
 			'lb' => 'lineskiftstil',
 			'ms' => 'målesystem',
 			'numbers' => 'tal',

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
 				'buddhist' => q{buddhistisk kalender},
 				'chinese' => q{kinesisk kalender},
 				'dangi' => q{dangisk kalender},
 				'ethiopic' => q{etiopisk kalender},
 				'ethiopic-amete-alem' => q{etiopisk amete-alem-kalender},
 				'gregorian' => q{gregoriansk kalender},
 				'hebrew' => q{hebraisk kalender},
 				'indian' => q{indisk nasjonalkalender},
 				'islamic' => q{islamsk kalender},
 				'islamic-civil' => q{islamsk sivil kalender},
 				'iso8601' => q{ISO 8601-kalender},
 				'japanese' => q{japansk kalender},
 				'persian' => q{persisk kalender},
 				'roc' => q{kalender for Republikken Kina},
 			},
 			'cf' => {
 				'account' => q{valutaformat for rekneskapsføring},
 				'standard' => q{standard valutaformat},
 			},
 			'collation' => {
 				'big5han' => q{tradisjonell kinesisk sortering},
 				'ducet' => q{standard Unicode-sorteringsrekkjefølgje},
 				'eor' => q{sorteringsrekkefølge for flerspråklige europeiske dokumenter},
 				'gb2312han' => q{forenkla kinesisk sortering},
 				'phonebook' => q{telefonkatalogsortering},
 				'pinyin' => q{pinyin-sortering},
 				'search' => q{generelt søk},
 				'standard' => q{standard sorteringsrekkjefølgje},
 				'stroke' => q{streksortering},
 				'traditional' => q{tradisjonell sortering},
 			},
 			'hc' => {
 				'h11' => q{12-timesystem (0–11)},
 				'h12' => q{12-timesystem (1–12)},
 				'h23' => q{24-timesystem (0–23)},
 				'h24' => q{24-timesystem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{laus lineskiftstil},
 				'normal' => q{normal lineskiftstil},
 				'strict' => q{streng lineskiftstil},
 			},
 			'ms' => {
 				'metric' => q{metrisk system},
 				'uksystem' => q{britisk målesystem},
 				'ussystem' => q{amerikansk målesystem},
 			},
 			'numbers' => {
 				'arab' => q{arabisk-indiske siffer},
 				'arabext' => q{utvida arabisk-indiske siffer},
 				'armn' => q{armenske tal},
 				'armnlow' => q{små armenske tal},
 				'beng' => q{bengalske siffer},
 				'deva' => q{devanagari-siffer},
 				'ethi' => q{etiopiske tal},
 				'fullwide' => q{siffer med full breidd},
 				'geor' => q{georgiske tal},
 				'grek' => q{greske tal},
 				'greklow' => q{små greske tal},
 				'gujr' => q{gujarati-siffer},
 				'guru' => q{gurmukhi-siffer},
 				'hanidec' => q{kinesiske desimaltal},
 				'hans' => q{forenkla kinesiske tal},
 				'hansfin' => q{forenkla kinesiske finanstal},
 				'hant' => q{tradisjonelle kinesiske tal},
 				'hantfin' => q{tradisjonelle kinesiske finanstal},
 				'hebr' => q{hebraiske tal},
 				'java' => q{javanesiske siffer},
 				'jpan' => q{japanske tal},
 				'jpanfin' => q{japanske finanstal},
 				'khmr' => q{khmer-siffer},
 				'knda' => q{kannada-siffer},
 				'laoo' => q{laotiske siffer},
 				'latn' => q{vestlege siffer},
 				'mlym' => q{malayalam-siffer},
 				'mymr' => q{burmesiske siffer},
 				'orya' => q{odia-siffer},
 				'roman' => q{romartal},
 				'romanlow' => q{små romartal},
 				'taml' => q{tamilske tal},
 				'tamldec' => q{tamilske siffer},
 				'telu' => q{telugu-siffer},
 				'thai' => q{thailandske siffer},
 				'tibt' => q{tibetanske siffer},
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
			'metric' => q{metrisk},
 			'UK' => q{engelsk},
 			'US' => q{amerikansk},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Språk: {0}',
 			'script' => 'Skrift: {0}',
 			'region' => 'Område: {0}',

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
			auxiliary => qr{[á ǎ č ç đ è ê ń ñ ŋ š ŧ ü ž ä ö]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'],
			main => qr{[a à b c d e é f g h i j k l m n o ó ò ô p q r s t u v w x y z æ ø å]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'], };
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
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					'acre-foot' => {
						'name' => q(acre-fot),
						'one' => q({0} acre-fot),
						'other' => q({0} acre-fot),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(bogeminutt),
						'one' => q({0} bogeminutt),
						'other' => q({0} bogeminutt),
					},
					'arc-second' => {
						'name' => q(bogesekund),
						'one' => q({0} bogesekund),
						'other' => q({0} bogesekund),
					},
					'astronomical-unit' => {
						'name' => q(astronomiske einingar),
						'one' => q({0} astronomisk eining),
						'other' => q({0} astronomiske einingar),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(grader celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grader celsius),
					},
					'centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					'centimeter' => {
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					'century' => {
						'name' => q(hundreår),
						'one' => q({0} hundreår),
						'other' => q({0} hundreår),
					},
					'coordinate' => {
						'east' => q({0} aust),
						'north' => q({0} nord),
						'south' => q({0} sør),
						'west' => q({0} vest),
					},
					'cubic-centimeter' => {
						'name' => q(kubikkcentimeter),
						'one' => q({0} kubikkcentimeter),
						'other' => q({0} kubikkcentimeter),
						'per' => q({0} per kubikkcentimeter),
					},
					'cubic-foot' => {
						'name' => q(kubikkfot),
						'one' => q({0} kubikkfot),
						'other' => q({0} kubikkfot),
					},
					'cubic-inch' => {
						'name' => q(kubikktommar),
						'one' => q({0} kubikktomme),
						'other' => q({0} kubikktommar),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					'cubic-meter' => {
						'name' => q(kubikkmeter),
						'one' => q({0} kubikkmeter),
						'other' => q({0} kubikkmeter),
						'per' => q({0} per kubikkmeter),
					},
					'cubic-mile' => {
						'name' => q(engelske kubikkmil),
						'one' => q({0} engelske kubikkmil),
						'other' => q({0} engelske kubikkmil),
					},
					'cubic-yard' => {
						'name' => q(kubikkyard),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyard),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					'cup-metric' => {
						'name' => q(metriske koppar),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriske koppar),
					},
					'day' => {
						'name' => q(døgn),
						'one' => q({0} døgn),
						'other' => q({0} døgn),
						'per' => q({0}/døgn),
					},
					'deciliter' => {
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					'decimeter' => {
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					'degree' => {
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					'fahrenheit' => {
						'name' => q(grader fahrenheit),
						'one' => q({0} grad fahrenheit),
						'other' => q({0} grader fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(væskeunser),
						'one' => q({0} væskeunse),
						'other' => q({0} væskeunser),
					},
					'foodcalorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-kraft),
						'one' => q({0} g-kraft),
						'other' => q({0} g-krefter),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(britiske gallon),
						'one' => q({0} britisk gallon),
						'other' => q({0} britiske gallon),
						'per' => q({0} per britiske gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(hestekrefter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrefter),
					},
					'hour' => {
						'name' => q(timar),
						'one' => q({0} time),
						'other' => q({0} timar),
						'per' => q({0} per time),
					},
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(tommar kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommar kvikksølv),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					'kilocalorie' => {
						'name' => q(kilokaloriar),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloriar),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per time),
						'one' => q({0} kilometer per time),
						'other' => q({0} kilomeer per time),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowattimar),
						'one' => q({0} kilowattime),
						'other' => q({0} kilowattimar),
					},
					'knot' => {
						'name' => q(knop),
						'one' => q({0} knop),
						'other' => q({0} knop),
					},
					'light-year' => {
						'name' => q(lysår),
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					'meter-per-second-squared' => {
						'name' => q(meter per sekund²),
						'one' => q({0} meter per sekund²),
						'other' => q({0} meter per sekund²),
					},
					'metric-ton' => {
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometer),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(mikrosekund),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekund),
					},
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
					},
					'mile-per-gallon' => {
						'name' => q(engelske mil per gallon),
						'one' => q({0} engelsk mil per gallon),
						'other' => q({0} engelske mil per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(engelske mil per britiske gallon),
						'one' => q({0} engelsk mil per britiske gallon),
						'other' => q({0} engelske mil per britiske gallon),
					},
					'mile-per-hour' => {
						'name' => q(engelske mil per time),
						'one' => q({0} engelsk mil per time),
						'other' => q({0} engelske mil per time),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'milliampere' => {
						'name' => q(miliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeter kvikksølv),
						'one' => q({0} millimeter kvikksølv),
						'other' => q({0} millimeter kvikksølv),
					},
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					'millisecond' => {
						'name' => q(millisekund),
						'one' => q({0} millisekund),
						'other' => q({0} millisekund),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minutt),
						'one' => q({0} minutt),
						'other' => q({0} minutt),
						'per' => q({0} per minutt),
					},
					'month' => {
						'name' => q(månadar),
						'one' => q({0} månad),
						'other' => q({0} månadar),
						'per' => q({0} per månad),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosekund),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekund),
					},
					'nautical-mile' => {
						'name' => q(nautiske mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiske mil),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
						'per' => q({0} per unse),
					},
					'ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					'part-per-million' => {
						'name' => q(milliondelar),
						'one' => q({0} milliondel),
						'other' => q({0} milliondelar),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metriske pint),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriske pint),
					},
					'point' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} per pund),
					},
					'pound-per-square-inch' => {
						'name' => q(pund per kvadrattomme),
						'one' => q({0} pund per kvadrattomme),
						'other' => q({0} pund per kvadrattomme),
					},
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					'radian' => {
						'name' => q(radianar),
						'one' => q({0} radian),
						'other' => q({0} radianar),
					},
					'revolution' => {
						'name' => q(omdreiingar),
						'one' => q({0} omdreiing),
						'other' => q({0} omdreiingar),
					},
					'second' => {
						'name' => q(sekund),
						'one' => q({0} sekund),
						'other' => q({0} sekund),
						'per' => q({0} per sekund),
					},
					'square-centimeter' => {
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
						'per' => q({0} per kvadratcentimeter),
					},
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					'square-inch' => {
						'name' => q(kvadrattommar),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommar),
						'per' => q({0} per kvadrattomme),
					},
					'square-kilometer' => {
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					'square-meter' => {
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					'square-mile' => {
						'name' => q(engelske kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelske kvadratmil),
						'per' => q({0} per engelske kvadratmil),
					},
					'square-yard' => {
						'name' => q(kvadratyard),
						'one' => q({0} kvadratyard),
						'other' => q({0} kvadratyard),
					},
					'tablespoon' => {
						'name' => q(matskeier),
						'one' => q({0} matskei),
						'other' => q({0} matskeier),
					},
					'teaspoon' => {
						'name' => q(teskeier),
						'one' => q({0} teskei),
						'other' => q({0} teskeier),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					'ton' => {
						'name' => q(amerikanske tonn),
						'one' => q({0} amerikansk tonn),
						'other' => q({0} amerikanske tonn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(veker),
						'one' => q({0} veke),
						'other' => q({0} veker),
						'per' => q({0} per veke),
					},
					'yard' => {
						'name' => q(engelske yard),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} per år),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
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
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(hundreår),
						'one' => q({0} årh.),
						'other' => q({0} årh.),
					},
					'coordinate' => {
						'east' => q({0}Ø),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(døgn),
						'one' => q({0}d),
						'other' => q({0}d),
						'per' => q({0}/d),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
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
						'one' => q({0} fot),
						'other' => q({0} fot),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'horsepower' => {
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					'hour' => {
						'name' => q(timar),
						'one' => q({0}t),
						'other' => q({0}t),
						'per' => q({0}/h),
					},
					'inch' => {
						'one' => q({0} tomme),
						'other' => q({0} tommer),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0}km/t),
						'other' => q({0}km/t),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'light-year' => {
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'micrometer' => {
						'name' => q(µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0}mil),
						'other' => q({0}mil),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(millisekund),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(minutt),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(månad),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/mån),
					},
					'nanometer' => {
						'name' => q(nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pound' => {
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					'second' => {
						'name' => q(sekund),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(vk.),
						'one' => q({0}v),
						'other' => q({0}v),
						'per' => q({0}/u),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0}å),
						'other' => q({0}å),
						'per' => q({0}/år),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					'acre-foot' => {
						'name' => q(acre-fot),
						'one' => q({0} ac-fot),
						'other' => q({0} ac-fot),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(bogeminutt),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(bogesekund),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} c),
						'other' => q({0} c),
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
						'name' => q(hundreår),
						'one' => q({0} årh.),
						'other' => q({0} årh.),
					},
					'coordinate' => {
						'east' => q({0} Ø),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(fot³),
						'one' => q({0} fot³),
						'other' => q({0} fot³),
					},
					'cubic-inch' => {
						'name' => q(tommar³),
						'one' => q({0} tomme³),
						'other' => q({0} tommar³),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilometer),
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
						'name' => q(engelske mil³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yard³),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					'cup-metric' => {
						'name' => q(m. koppar),
						'one' => q({0} m. kopp),
						'other' => q({0} m. koppar),
					},
					'day' => {
						'name' => q(døgn),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
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
						'name' => q(grader),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'name' => q(væskeunse),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-kraft),
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
						'name' => q(brit. gal),
						'one' => q({0} brit. gal),
						'other' => q({0} brit. gal),
						'per' => q({0}/brit. gal),
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
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektar),
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
						'name' => q(hk),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					'hour' => {
						'name' => q(timar),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} kt),
						'other' => q({0} kt),
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
						'name' => q(kilojoule),
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
						'name' => q(km/time),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(lysår),
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					'liter' => {
						'name' => q(liter),
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
						'name' => q(lux),
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
						'name' => q(meter/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
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
						'name' => q(mikrosekund),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(eng. mil/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(eng. mil/brit. gal),
						'one' => q({0} mile/brit. gal),
						'other' => q({0} mile/brit. gal),
					},
					'mile-per-hour' => {
						'name' => q(engelske mil per time),
						'one' => q({0} mile/t),
						'other' => q({0} mile/t),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'milliampere' => {
						'name' => q(milliampere),
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
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(millisekund),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(minutt),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(månadar),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
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
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
						'per' => q({0}/unse),
					},
					'ounce-troy' => {
						'name' => q(oz tr),
						'one' => q({0} oz tr),
						'other' => q({0} oz tr),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radianar),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(omdr.),
						'one' => q({0} omdr.),
						'other' => q({0} omdr.),
					},
					'second' => {
						'name' => q(sekund),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} fot²),
						'other' => q({0} fot²),
					},
					'square-inch' => {
						'name' => q(tommar²),
						'one' => q({0} tomme²),
						'other' => q({0} tommar²),
						'per' => q({0}/tomme²),
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
						'name' => q(engelske mil²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					'teaspoon' => {
						'name' => q(ts),
						'one' => q({0} ts),
						'other' => q({0} ts),
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
						'name' => q(am. tonn),
						'one' => q({0} am. tonn),
						'other' => q({0} am. tonn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(veker),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					'yard' => {
						'name' => q(engelske yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0}/år),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei|n)$' }
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
					'one' => '0 tn',
					'other' => '0 tn',
				},
				'10000' => {
					'one' => '00 tn',
					'other' => '00 tn',
				},
				'100000' => {
					'one' => '000 tn',
					'other' => '000 tn',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 tusen',
					'other' => '0 tusen',
				},
				'10000' => {
					'one' => '00 tusen',
					'other' => '00 tusen',
				},
				'100000' => {
					'one' => '000 tusen',
					'other' => '000 tusen',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 millionar',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 millionar',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 millionar',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliardar',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliardar',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliardar',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billionar',
				},
				'10000000000000' => {
					'one' => '00 billion',
					'other' => '00 billionar',
				},
				'100000000000000' => {
					'one' => '000 billion',
					'other' => '000 billionar',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tn',
					'other' => '0 tn',
				},
				'10000' => {
					'one' => '00 tn',
					'other' => '00 tn',
				},
				'100000' => {
					'one' => '000 tn',
					'other' => '000 tn',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
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
				'currency' => q(andorranske peseta),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(emiratarabiske dirham),
				'one' => q(emiratarabisk dirham),
				'other' => q(emiratarabiske dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afghanske afghani),
				'one' => q(afghansk afghani),
				'other' => q(afghanske afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanske lek),
				'one' => q(albansk lek),
				'other' => q(albanske lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(armenske dram),
				'one' => q(armensk dram),
				'other' => q(armenske dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(nederlandske antillegylden),
				'one' => q(nederlandsk antillegylden),
				'other' => q(nederlandske antillegylden),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(angolanske kwanza),
				'one' => q(angolansk kwanza),
				'other' => q(angolanske kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolske kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolske nye kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolske kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentiske austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinske peso \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(argentinske pesos),
				'one' => q(argentinsk peso),
				'other' => q(argentinske pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(austerrikske schilling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(australske dollar),
				'one' => q(australsk dollar),
				'other' => q(australske dollar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(arubiske floriner),
				'one' => q(arubisk florin),
				'other' => q(arubiske floriner),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(aserbaijanske manat),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(aserbajdsjanske manat),
				'one' => q(aserbajdsjansk manat),
				'other' => q(aserbajdsjanske manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinske dinarar),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(bosnisk-hercegovinske konvertible mark),
				'one' => q(bosnisk-hercegovinsk konvertibel mark),
				'other' => q(bosnisk-hercegovinske konvertible mark),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadiske dollar),
				'one' => q(barbadisk dollar),
				'other' => q(barbadiske dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(bangladeshiske taka),
				'one' => q(bangladeshisk taka),
				'other' => q(bangladeshiske taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgiske franc \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgiske franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiske franc \(finansiell\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarsk hard lev),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bulgarske lev),
				'one' => q(bulgarsk lev),
				'other' => q(bulgarske lev),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahrainske dinarar),
				'one' => q(bahrainsk dinar),
				'other' => q(bahrainske dinarar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundiske franc),
				'one' => q(burundisk franc),
				'other' => q(burundiske franc),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudiske dollar),
				'one' => q(bermudisk dollar),
				'other' => q(bermudiske dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(bruneiske dollar),
				'one' => q(bruneisk dollar),
				'other' => q(bruneiske dollar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(bolivianske boliviano),
				'one' => q(boliviansk boliviano),
				'other' => q(bolivianske boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliviske peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliviske mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brasilianske cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brasilianske real),
				'one' => q(brasiliansk real),
				'other' => q(brasilianske real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brasilianske cruzado novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamanske dollar),
				'one' => q(bahamansk dollar),
				'other' => q(bahamanske dollar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(bhutanske ngultrum),
				'one' => q(bhutanske ngultrum),
				'other' => q(bhutanske ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmesisk kyat),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(botswanske pula),
				'one' => q(botswansk pula),
				'other' => q(botswanske pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(kviterussiske nye rublar \(1994–1999\)),
				'one' => q(kviterussisk ny rubel \(BYB\)),
				'other' => q(kviterussiske nye rublar \(BYB\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(kviterussiske rublar),
				'one' => q(kviterussisk rubel),
				'other' => q(kviterussiske rublar),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(kviterussiske rublar \(2000–2016\)),
				'one' => q(kviterussisk rubel \(2000–2016\)),
				'other' => q(kviterussiske rublar \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(beliziske dollar),
				'one' => q(belizisk dollar),
				'other' => q(beliziske dollar),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadiske dollar),
				'one' => q(kanadisk dollar),
				'other' => q(kanadiske dollar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(kongolesiske franc),
				'one' => q(kongolesisk franc),
				'other' => q(kongolesiske franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
				'one' => q(WIR euro),
				'other' => q(WIR euro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(sveitsiske franc),
				'one' => q(sveitsisk franc),
				'other' => q(sveitsiske franc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franc),
				'one' => q(WIR franc),
				'other' => q(WIR franc),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(chilenske unidades de fomento),
				'one' => q(chilensk unidades de fomento),
				'other' => q(chilenske unidades de fomento),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(chilenske pesos),
				'one' => q(chilensk peso),
				'other' => q(chilenske pesos),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kinesiske yuan),
				'one' => q(kinesisk yuan),
				'other' => q(kinesiske yuan),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(kolombianske pesos),
				'one' => q(kolombiansk peso),
				'other' => q(kolombianske pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidad de valor real),
				'one' => q(unidad de valor real),
				'other' => q(unidad de valor real),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(kostarikanske colón),
				'one' => q(kostarikansk colón),
				'other' => q(kostarikanske colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(gamle serbiske dinarer),
				'one' => q(gammal serbisk dinar),
				'other' => q(gamle serbiske dinarar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tsjekkoslovakiske koruna \(hard\)),
				'one' => q(tsjekkoslovakisk koruna \(hard\)),
				'other' => q(tsjekkoslovakiske koruna \(hard\)),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubanske konvertible pesos),
				'one' => q(kubansk konvertibel peso),
				'other' => q(kubanske konvertible pesos),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubanske pesos),
				'one' => q(kubansk peso),
				'other' => q(kubanske pesos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(kappverdiske escudo),
				'one' => q(kappverdisk escudo),
				'other' => q(kappverdiske escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(kypriotiske pund),
				'one' => q(kypriotisk pund),
				'other' => q(kypriotiske pund),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(tsjekkiske koruna),
				'one' => q(tsjekkisk koruna),
				'other' => q(tsjekkiske koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(austtyske mark),
				'one' => q(austtysk mark),
				'other' => q(austtyske mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(tyske mark),
				'one' => q(tysk mark),
				'other' => q(tyske mark),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(djiboutiske franc),
				'one' => q(djiboutisk franc),
				'other' => q(djiboutiske franc),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(danske kroner),
				'one' => q(dansk krone),
				'other' => q(danske kroner),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikanske pesos),
				'one' => q(dominikansk peso),
				'other' => q(dominikanske pesos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(algeriske dinarar),
				'one' => q(algerisk dinar),
				'other' => q(algeriske dinarar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ecuadorianske sucre),
				'one' => q(ecuadoriansk sucre),
				'other' => q(ecuadorianske sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ecuadorianske unidad de valor constante \(UVC\)),
				'one' => q(ecuadoriansk unidad de valor constante \(UVC\)),
				'other' => q(ecuadorianske unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estiske kroon),
				'one' => q(estisk kroon),
				'other' => q(estiske kroon),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(egyptiske pund),
				'one' => q(egyptisk pund),
				'other' => q(egyptiske pund),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(eritreiske nakfa),
				'one' => q(eritreisk nakfa),
				'other' => q(eritreiske nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spanske peseta \(A–konto\)),
				'one' => q(spansk peseta \(A–konto\)),
				'other' => q(spanske peseta \(A–konto\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spanske peseta \(konvertibel konto\)),
				'one' => q(spansk peseta \(konvertibel konto\)),
				'other' => q(spanske peseta \(konvertibel konto\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(spanske peseta),
				'one' => q(spansk peseta),
				'other' => q(spanske peseta),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiopiske birr),
				'one' => q(etiopisk birr),
				'other' => q(etiopiske birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finske mark),
				'one' => q(finsk mark),
				'other' => q(finske mark),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(fijianske dollar),
				'one' => q(fijiansk dollar),
				'other' => q(fijianske dollar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(falklandspund),
				'one' => q(falklandspund),
				'other' => q(falklandspund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franske franc),
				'one' => q(fransk franc),
				'other' => q(franske franc),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(britiske pund),
				'one' => q(britisk pund),
				'other' => q(britiske pund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(georgiske kupon larit),
				'one' => q(georgisk kupon larit),
				'other' => q(georgiske kupon larit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(georgiske lari),
				'one' => q(georgisk lari),
				'other' => q(georgiske lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanesiske cedi \(1979–2007\)),
				'one' => q(ghanesisk cedi \(GHC\)),
				'other' => q(ghanesiske cedi \(GHC\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ghanesiske cedi),
				'one' => q(ghanesisk cedi),
				'other' => q(ghanesiske cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltarske pund),
				'one' => q(gibraltarsk pund),
				'other' => q(gibraltarske pund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambiske dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiske dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(guineanske franc),
				'one' => q(guineansk franc),
				'other' => q(guineanske franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guineanske syli),
				'one' => q(guineansk syli),
				'other' => q(guineanske syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekvatorialguineanske ekwele guineana),
				'one' => q(ekvatorialguineansk ekwele),
				'other' => q(ekvatorialguineanske ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(greske drakme),
				'one' => q(gresk drakme),
				'other' => q(greske drakmer),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(guatemalanske quetzal),
				'one' => q(guatemalansk quetzal),
				'other' => q(guatemalanske quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(portugisiske guinea escudo),
				'one' => q(portugisisk guinea escudo),
				'other' => q(portugisiske guinea escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau-peso),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(guyanske dollar),
				'one' => q(guyansk dollar),
				'other' => q(guyanske dollar),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Hongkong-dollar),
				'one' => q(Hongkong-dollar),
				'other' => q(Hongkong-dollar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(honduranske lempira),
				'one' => q(honduransk lempira),
				'other' => q(honduranske lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatiske dinar),
				'one' => q(kroatisk dinar),
				'other' => q(kroatiske dinarar),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(kroatiske kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiske kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haitiske gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiske gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(ungarske forintar),
				'one' => q(ungarsk forint),
				'other' => q(ungarske forintar),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(indonesiske rupiar),
				'one' => q(indonesisk rupi),
				'other' => q(indonesiske rupiar),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(irske pund),
				'one' => q(irsk pund),
				'other' => q(irske pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israelske pund),
				'one' => q(israelsk pund),
				'other' => q(israelske pund),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(israelske nye sheklar),
				'one' => q(israelsk ny shekel),
				'other' => q(israelske nye sheklar),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indiske rupiar),
				'one' => q(indisk rupi),
				'other' => q(indiske rupiar),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(irakiske dinarar),
				'one' => q(irakisk dinar),
				'other' => q(irakiske dinarar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iranske rial),
				'one' => q(iransk rial),
				'other' => q(iranske rial),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(islandske kroner),
				'one' => q(islandsk krone),
				'other' => q(islandske kroner),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italienske lire),
				'one' => q(italiensk lire),
				'other' => q(italienske lire),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamaikanske dollar),
				'one' => q(jamaikansk dollar),
				'other' => q(jamaikanske dollar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(jordanske dinarar),
				'one' => q(jordansk dinar),
				'other' => q(jordanske dinarar),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japanske yen),
				'one' => q(japansk yen),
				'other' => q(japanske yen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(kenyanske shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanske shilling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgisiske som),
				'one' => q(kirgisisk som),
				'other' => q(kirgisiske som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambodsjanske riel),
				'one' => q(kambodsjansk riel),
				'other' => q(kambodsjanske riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komoriske franc),
				'one' => q(komorisk franc),
				'other' => q(komoriske franc),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(nordkoreanske won),
				'one' => q(nordkoreansk won),
				'other' => q(nordkoreanske won),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(sørkoreanske won),
				'one' => q(sørkoreansk won),
				'other' => q(sørkoreanske won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuwaitiske dinarar),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiske dinarar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(caymanske dollar),
				'one' => q(caymansk dollar),
				'other' => q(caymanske dollar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kasakhstanske tenge),
				'one' => q(kasakhstansk tenge),
				'other' => q(kasakhstanske tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laotiske kip),
				'one' => q(laotisk kip),
				'other' => q(laotiske kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanesiske pund),
				'one' => q(libanesisk pund),
				'other' => q(libanesiske pund),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(srilankiske rupiar),
				'one' => q(srilankisk rupi),
				'other' => q(srilankiske rupiar),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(liberiske dollar),
				'one' => q(liberisk dollar),
				'other' => q(liberiske dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothiske loti),
				'one' => q(lesothisk loti),
				'other' => q(lesothiske loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litauiske lita),
				'one' => q(litauisk lita),
				'other' => q(litauiske lita),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litauiske talona),
				'one' => q(litauisk talona),
				'other' => q(litauiske talona),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgske konvertibel franc),
				'one' => q(luxemburgsk konvertibel franc),
				'other' => q(luxemburgske konvertible franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luxemburgske franc),
				'one' => q(luxemburgsk franc),
				'other' => q(luxemburgske franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburgske finansielle franc),
				'one' => q(luxemburgsk finansiell franc),
				'other' => q(luxemburgske finansielle franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latviske lat),
				'one' => q(latvisk lat),
				'other' => q(latviske lat),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latviske rublar),
				'one' => q(latvisk rubel),
				'other' => q(latviske rublar),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(libyske dinarar),
				'one' => q(libysk dinar),
				'other' => q(libyske dinarar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(marokkanske dirham),
				'one' => q(marokkansk dirham),
				'other' => q(marokkanske dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marokkanske franc),
				'one' => q(marokkansk franc),
				'other' => q(marokkanske franc),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldovske leuar),
				'one' => q(moldovsk leu),
				'other' => q(moldovske leuar),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(madagassiske ariary),
				'one' => q(madagassisk ariary),
				'other' => q(madagassiske ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagassiske franc),
				'one' => q(madagassisk franc),
				'other' => q(madagassiske franc),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(makedonske denarar),
				'one' => q(makedonsk denar),
				'other' => q(makedonske denarar),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(maliske franc),
				'one' => q(malisk franc),
				'other' => q(maliske franc),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(myanmarske kyat),
				'one' => q(myanmarsk kyat),
				'other' => q(myanmarske kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolske tugrik),
				'one' => q(mongolsk tugrik),
				'other' => q(mongolske tugrik),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makaoiske pataca),
				'one' => q(macaoisk pataca),
				'other' => q(makaoiske pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mauritanske ouguiya),
				'one' => q(mauritansk ouguiya),
				'other' => q(mauritanske ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltesiske lira),
				'one' => q(maltesisk lira),
				'other' => q(maltesiske lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltesiske pund),
				'one' => q(maltesisk pund),
				'other' => q(maltesiske pund),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(mauritanske rupiar),
				'one' => q(mauritansk rupi),
				'other' => q(mauritanske rupiar),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldiviske rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviske rufiyaa),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malawiske kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiske kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(meksikanske pesos),
				'one' => q(meksikansk peso),
				'other' => q(meksikanske pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(meksikanske sølvpeso \(1861–1992\)),
				'one' => q(meksikansk sølvpeso \(MXP\)),
				'other' => q(meksikanske sølvpeso \(MXP\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(meksikanske unidad de inversion \(UDI\)),
				'one' => q(meksikansk unidad de inversion \(UDI\)),
				'other' => q(meksikanske unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(malaysiske ringgit),
				'one' => q(malaysisk ringgit),
				'other' => q(malaysiske ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mosambikiske escudo),
				'one' => q(mosambikisk escudo),
				'other' => q(mosambikiske escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(gamle mosambikiske metical),
				'one' => q(gammal mosambikisk metical),
				'other' => q(gamle mosambikiske metical),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(mosambikiske metical),
				'one' => q(mosambikisk metical),
				'other' => q(mosambikisk metical),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibiske dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiske dollar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(nigerianske naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianske naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nicaraguanske cordoba),
				'one' => q(nicaraguansk cordoba),
				'other' => q(nicaraguanske cordoba),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(nicaraguanske córdoba),
				'one' => q(nicaraguansk córdoba),
				'other' => q(nicaraguanske córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nederlandske gylden),
				'one' => q(nederlandsk gylden),
				'other' => q(nederlandske gylden),
			},
		},
		'NOK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(norske kroner),
				'one' => q(norsk krone),
				'other' => q(norske kroner),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(nepalske rupiar),
				'one' => q(nepalsk rupi),
				'other' => q(nepalske rupiar),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(nyzealandske dollar),
				'one' => q(nyzealandsk dollar),
				'other' => q(nyzealandske dollar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(omanske rial),
				'one' => q(omansk rial),
				'other' => q(omanske rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(panamanske balboa),
				'one' => q(panamansk balboa),
				'other' => q(panamanske balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruanske inti),
				'one' => q(peruansk inti),
				'other' => q(peruanske inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(peruanske sol),
				'one' => q(peruansk sol),
				'other' => q(peruanske sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruanske sol \(1863–1965\)),
				'one' => q(peruansk sol \(1863–1965\)),
				'other' => q(peruanske sol \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(papuanske kina),
				'one' => q(papuansk kina),
				'other' => q(papuanske kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filippinske pesos),
				'one' => q(filippinsk peso),
				'other' => q(filippinske peso),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistanske rupiar),
				'one' => q(pakistansk rupi),
				'other' => q(pakistanske rupiar),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(polske zloty),
				'one' => q(polsk zloty),
				'other' => q(polske zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polske zloty \(1950–1995\)),
				'one' => q(polsk zloty \(PLZ\)),
				'other' => q(polske zloty \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugisiske escudo),
				'one' => q(portugisisk escudo),
				'other' => q(portugisiske escudo),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(paraguayanske guaraní),
				'one' => q(ṕaraguayansk guaraní),
				'other' => q(paraguayanske guaraní),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(qatarske rial),
				'one' => q(qatarsk rial),
				'other' => q(qatarske rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesiske dollar),
				'one' => q(rhodesisk dollar),
				'other' => q(rhodesiske dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(gamle rumenske leu),
				'one' => q(gammal rumensk leu),
				'other' => q(gamle rumenske lei),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(rumenske leuar),
				'one' => q(rumensk leu),
				'other' => q(rumenske leuar),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(serbiske dinarar),
				'one' => q(serbisk dinar),
				'other' => q(serbiske dinarar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(russiske rublar),
				'one' => q(russisk rubel),
				'other' => q(russiske rublar),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(russiske rublar \(1991–1998\)),
				'one' => q(russisk rubel \(RUR\)),
				'other' => q(russiske rublar \(RUR\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(rwandiske franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiske franc),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saudiarabiske rial),
				'one' => q(saudiarabisk rial),
				'other' => q(saudiarabiske rial),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(salomonske dollar),
				'one' => q(salomonsk dollar),
				'other' => q(salomonske dollar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(seychelliske rupiar),
				'one' => q(seychellisk rupi),
				'other' => q(seychelliske rupiar),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(gamle sudanske dinarer),
				'one' => q(gammal sudansk dinar),
				'other' => q(gamle sudanske dinarar),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(sudanske pund),
				'one' => q(sudansk pund),
				'other' => q(sudanske pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(gamle sudanske pund),
				'one' => q(gammalt sudansk pund),
				'other' => q(gamle sudanske pund),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(svenske kroner),
				'one' => q(svensk krone),
				'other' => q(svenske kroner),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singaporske dollar),
				'one' => q(singaporsk dollar),
				'other' => q(singaporske dollar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(sankthelenske pund),
				'one' => q(sankthelensk pund),
				'other' => q(sankthelenske pund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovenske tolar),
				'one' => q(slovensk tolar),
				'other' => q(slovenske tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakiske koruna),
				'one' => q(slovakisk koruna),
				'other' => q(slovakiske koruna),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sierraleonske leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonske leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somaliske shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliske shilling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(surinamske dollar),
				'one' => q(surinamsk dollar),
				'other' => q(surinamske dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamske gylden),
				'one' => q(surinamsk gylden),
				'other' => q(surinamske gylden),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(sørsudanske pund),
				'one' => q(sørsudansk pund),
				'other' => q(sørsudanske pund),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(saotomesiske dobra),
				'one' => q(saotomesisk dobra),
				'other' => q(saotomesiske dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetiske rublar),
				'one' => q(sovjetisk rubel),
				'other' => q(sovjetiske rublar),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadoranske colon),
				'one' => q(salvadoransk colon),
				'other' => q(salvadoranske colon),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(syriske pund),
				'one' => q(syrisk pund),
				'other' => q(syriske pund),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(swazilandske lilangeni),
				'one' => q(swazilandsk lilangeni),
				'other' => q(swazilandske lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(thailandske baht),
				'one' => q(thailandsk baht),
				'other' => q(thailandske baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadsjikiske rublar),
				'one' => q(tadsjikisk rubel),
				'other' => q(tadsjikiske rublar),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(tadsjikiske somoni),
				'one' => q(tadsjikisk somoni),
				'other' => q(tadsjikiske somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenske manat \(1993–2009\)),
				'one' => q(turkmensk manat \(1993–2009\)),
				'other' => q(turkmenske manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkmenske manat),
				'one' => q(turkmensk manat),
				'other' => q(turkmenske manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tunisiske dinarar),
				'one' => q(tunisisk dinar),
				'other' => q(tunisiske dinarar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(tonganske paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganske paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timoresiske escudo),
				'one' => q(timoresisk escudo),
				'other' => q(timoresiske escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(gamle tyrkiske lire),
				'one' => q(gammal tyrkisk lire),
				'other' => q(gamle tyrkiske lire),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(tyrkiske lire),
				'one' => q(tyrkisk lire),
				'other' => q(tyrkiske lire),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(trinidadiske dollar),
				'one' => q(trinidadisk dollar),
				'other' => q(trinidadiske dollar),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nye taiwanske dollar),
				'one' => q(ny taiwansk dollar),
				'other' => q(nye taiwanske dollar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzanianske shilling),
				'one' => q(tanzaniansk shilling),
				'other' => q(tanzanianske shilling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(ukrainske hryvnia),
				'one' => q(ukrainsk hryvnia),
				'other' => q(ukrainske hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainske karbovanetz),
				'one' => q(ukrainsk karbovanetz),
				'other' => q(ukrainske karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandiske shilling \(1966–1987\)),
				'one' => q(ugandisk shilling \(UGS\)),
				'other' => q(ugandiske shilling \(UGS\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(ugandiske shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiske shilling),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(amerikanske dollar),
				'one' => q(amerikansk dollar),
				'other' => q(amerikanske dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(amerikanske dollar \(neste dag\)),
				'one' => q(amerikansk dollar \(neste dag\)),
				'other' => q(amerikanske dollar \(neste dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(amerikanske dollar \(same dag\)),
				'one' => q(amerikansk dollar \(same dag\)),
				'other' => q(amerikanske dollar \(same dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayanske peso en unidades indexadas),
				'one' => q(uruguayansk peso en unidades indexadas),
				'other' => q(uruguayanske peso en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayanske peso \(1975–1993\)),
				'one' => q(uruguayansk peso \(UYP\)),
				'other' => q(uruguayanske peso \(UYP\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(uruguayanske pesos),
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanske pesos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(usbekiske sum),
				'one' => q(usbekisk sum),
				'other' => q(usbekiske sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelanske bolivar \(1871–2008\)),
				'one' => q(venezuelansk bolivar \(1871–2008\)),
				'other' => q(venezuelanske bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(venezuelanske bolivar),
				'one' => q(venezuelansk bolivar),
				'other' => q(venezuelanske bolivar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnamesiske dong),
				'one' => q(vietnamesisk dong),
				'other' => q(vietnamesiske dong),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatuiske vatu),
				'one' => q(vanuatuisk vatu),
				'other' => q(vanuatuiske vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(samoanske tala),
				'one' => q(samoansk tala),
				'other' => q(samoanske tala),
			},
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(sentralafrikanske CFA-franc),
				'one' => q(sentralafrikansk CFA-franc),
				'other' => q(sentralafrikanske CFA-franc),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(sølv),
				'one' => q(sølv),
				'other' => q(sølv),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(gull),
				'one' => q(gull),
				'other' => q(gull),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europeiske samansette einingar),
				'one' => q(europeisk samansett eining),
				'other' => q(europeiske samansette einingar),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeiske monetære einingar),
				'one' => q(europeisk monetær eining),
				'other' => q(europeiske monetære einingar),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeiske kontoeiningar \(XBC\)),
				'one' => q(europeisk kontoeining \(XBC\)),
				'other' => q(europeiske kontoeiningar \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europeiske kontoeiningar \(XBD\)),
				'one' => q(europeisk kontoeining \(XBD\)),
				'other' => q(europeiske kontoeiningar \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(austkaribiske dollar),
				'one' => q(austkaribisk dollar),
				'other' => q(austkaribiske dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(spesielle trekkrettar),
				'one' => q(spesiell trekkrett),
				'other' => q(spesielle trekkrettar),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europeiske valutaeiningar),
				'one' => q(europeisk valutaeining),
				'other' => q(europeiske valutaeiningar),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franske gullfranc),
				'one' => q(fransk gullfranc),
				'other' => q(franske gullfranc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franske UIC-franc),
				'one' => q(fransk UIC-franc),
				'other' => q(franske UIC-franc),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(vestafrikanske CFA-franc),
				'one' => q(vestafrikansk CFA-franc),
				'other' => q(vestafrikanske CFA-franc),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'one' => q(palladium),
				'other' => q(palladium),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP-franc),
				'one' => q(CFP-franc),
				'other' => q(CFP-franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'one' => q(platina),
				'other' => q(platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fond),
				'one' => q(RINET-fond),
				'other' => q(RINET-fond),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(testvalutakode),
				'one' => q(testvalutakode),
				'other' => q(testvalutakode),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ukjend valuta),
				'one' => q(\(ukjend valuta\)),
				'other' => q(\(ukjend valuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenittiske dinarar),
				'one' => q(jemenittisk dinar),
				'other' => q(jemenittiske dinarar),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(jemenittiske rial),
				'one' => q(jemenittisk rial),
				'other' => q(jemenittiske rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslaviske dinarar \(hard\)),
				'one' => q(jugoslavisk dinar \(hard\)),
				'other' => q(jugoslaviske dinarar \(hard\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslaviske noviy-dinarar),
				'one' => q(jugoslavisk noviy-dinar),
				'other' => q(jugoslaviske noviy-dinarar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslaviske konvertibel dinarar),
				'one' => q(jugoslavisk konvertibel dinar),
				'other' => q(jugoslaviske konvertible dinarar),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(sørafrikanske rand \(finansiell\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(sørafrikanske rand),
				'one' => q(sørafrikansk rand),
				'other' => q(sørafrikanske rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambiske kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(zambiske kwacha),
				'one' => q(zambisk kwacha),
				'other' => q(zambiske kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairisk ny zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairisk zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwisk dollar),
			},
		},
		'ZWL' => {
			display_name => {
				'one' => q(Zimbabwe-dollar \(2009\)),
				'other' => q(Zimbabwe-dollar \(2009\)),
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
							'mars',
							'apr.',
							'mai',
							'juni',
							'juli',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'des.'
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
							'januar',
							'februar',
							'mars',
							'april',
							'mai',
							'juni',
							'juli',
							'august',
							'september',
							'oktober',
							'november',
							'desember'
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
							'mar',
							'apr',
							'mai',
							'jun',
							'jul',
							'aug',
							'sep',
							'okt',
							'nov',
							'des'
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
							'januar',
							'februar',
							'mars',
							'april',
							'mai',
							'juni',
							'juli',
							'august',
							'september',
							'oktober',
							'november',
							'desember'
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
						mon => 'må.',
						tue => 'ty.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'la.',
						sun => 'sø.'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'O',
						thu => 'T',
						fri => 'F',
						sat => 'L',
						sun => 'S'
					},
					short => {
						mon => 'må.',
						tue => 'ty.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'la.',
						sun => 'sø.'
					},
					wide => {
						mon => 'måndag',
						tue => 'tysdag',
						wed => 'onsdag',
						thu => 'torsdag',
						fri => 'fredag',
						sat => 'laurdag',
						sun => 'søndag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'mån',
						tue => 'tys',
						wed => 'ons',
						thu => 'tor',
						fri => 'fre',
						sat => 'lau',
						sun => 'søn'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'O',
						thu => 'T',
						fri => 'F',
						sat => 'L',
						sun => 'S'
					},
					short => {
						mon => 'må.',
						tue => 'ty.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'la.',
						sun => 'sø.'
					},
					wide => {
						mon => 'måndag',
						tue => 'tysdag',
						wed => 'onsdag',
						thu => 'torsdag',
						fri => 'fredag',
						sat => 'laurdag',
						sun => 'søndag'
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
				'wide' => {
					'am' => q{formiddag},
					'pm' => q{ettermiddag},
				},
				'narrow' => {
					'am' => q{f.m.},
					'pm' => q{e.m.},
				},
				'abbreviated' => {
					'pm' => q{e.m.},
					'am' => q{f.m.},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'pm' => q{e.m.},
					'am' => q{f.m.},
				},
				'wide' => {
					'am' => q{f.m.},
					'pm' => q{e.m.},
				},
				'abbreviated' => {
					'am' => q{f.m.},
					'pm' => q{e.m.},
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
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			narrow => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			wide => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
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
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.M.y G},
		},
		'gregorian' => {
			'full' => q{EEEE d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
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
			'full' => q{'kl'. HH:mm:ss zzzz},
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
			'long' => q{{1} 'kl'. {0}},
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
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L.},
			MEd => q{E d.M},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMW => q{'veke' W 'i' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E d.M.y},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'veke' w 'i' Y},
		},
		'generic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L.},
			MEd => q{E d.M},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E d.M.y G},
			yyyyMM => q{MM.y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
				M => q{M.–M.},
			},
			MEd => {
				M => q{E dd.MM.–E dd.MM.},
				d => q{E dd.MM.–E dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d.–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d.–d.},
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
				M => q{E dd.MM.y–E dd.MM.y},
				d => q{E dd.MM.y–E dd.MM.y},
				y => q{E dd.MM.y–E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM y},
				d => q{E d.–E d. MMM y},
				y => q{E d. MMM y–E d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y–MMMM y},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y–d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y},
				d => q{dd.MM.y–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
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
				M => q{M.–M.},
			},
			MEd => {
				M => q{E dd.MM.–E dd.MM.},
				d => q{E dd.MM.–E dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d.–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM.–dd.MM.},
				d => q{dd.MM.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
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
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y–MM.y G},
				y => q{MM.y–MM.y G},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y G},
				d => q{E dd.MM.y–E dd.MM.y G},
				y => q{E dd.MM.y–E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM y G},
				d => q{E d.–E d. MMM y G},
				y => q{E d. MMM y–E d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y–MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y G},
				d => q{dd.MM.y–dd.MM.y G},
				y => q{dd.MM.y–dd.MM.y G},
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
		regionFormat => q(tidssone for {0}),
		regionFormat => q(sumartid – {0}),
		regionFormat => q(normaltid – {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#afghansk tid#,
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
			exemplarCity => q#Alger#,
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
			exemplarCity => q#Dar-es-Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
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
			exemplarCity => q#Lomé#,
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
				'standard' => q#sentralafrikansk tid#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#austafrikansk tid#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#sørafrikansk tid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#vestafrikansk sommartid#,
				'generic' => q#vestafrikansk tid#,
				'standard' => q#vestafrikansk standardtid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskisk sumartid#,
				'generic' => q#alaskisk tid#,
				'standard' => q#alaskisk normaltid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#sumartid for Amazonas#,
				'generic' => q#tidssone for Amazonas#,
				'standard' => q#normaltid for Amazonas#,
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
			exemplarCity => q#Bahía Banderas#,
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
			exemplarCity => q#Caymanøyane#,
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
			exemplarCity => q#Cuiaba#,
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
			exemplarCity => q#Eirunepe#,
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
			exemplarCity => q#Mexico by#,
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
			exemplarCity => q#Beulah, Nord-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Nord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Nord-Dakota#,
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
				'daylight' => q#sumartid for sentrale Nord-Amerika#,
				'generic' => q#tidssone for sentrale Nord-Amerika#,
				'standard' => q#normaltid for sentrale Nord-Amerika#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#sumartid for den nordamerikansk austkysten#,
				'generic' => q#tidssone for den nordamerikansk austkysten#,
				'standard' => q#normaltid for den nordamerikansk austkysten#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#sumartid for Rocky Mountains (USA)#,
				'generic' => q#tidssone for Rocky Mountains (USA)#,
				'standard' => q#normaltid for Rocky Mountains (USA)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#sumartid for den nordamerikanske stillehavskysten#,
				'generic' => q#tidssone for den nordamerikanske stillehavskysten#,
				'standard' => q#normaltid for den nordamerikanske stillehavskysten#,
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
				'daylight' => q#sumartid for Apia#,
				'generic' => q#tidssone for Apia#,
				'standard' => q#normaltid for Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabisk sumartid#,
				'generic' => q#arabisk tid#,
				'standard' => q#arabisk normaltid#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinsk sumartid#,
				'generic' => q#argentinsk tid#,
				'standard' => q#argentinsk normaltid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#vestargentinsk sumartid#,
				'generic' => q#vestargentinsk tid#,
				'standard' => q#vestargentinsk normaltid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armensk sumartid#,
				'generic' => q#armensk tid#,
				'standard' => q#armensk normaltid#,
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
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
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
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tsjita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsjojbalsan#,
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
			exemplarCity => q#Dusjanbe#,
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
			exemplarCity => q#Khovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jajapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
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
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
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
			exemplarCity => q#Muskat#,
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
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangôn#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-byen#,
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
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
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
				'daylight' => q#sumartid for den nordamerikanske atlanterhavskysten#,
				'generic' => q#tidssone for den nordamerikanske atlanterhavskysten#,
				'standard' => q#normaltid for den nordamerikanske atlanterhavskysten#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asorane#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariøyane#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapp Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Færøyane#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sør-Georgia#,
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
				'daylight' => q#sentralaustralsk sommartid#,
				'generic' => q#sentralaustralsk tid#,
				'standard' => q#sentralaustralsk standardtid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#vest-sentralaustralsk sommartid#,
				'generic' => q#vest-sentralaustralsk tid#,
				'standard' => q#vest-sentralaustralsk standardtid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#austaustralsk sommartid#,
				'generic' => q#austaustralsk tid#,
				'standard' => q#austaustralsk standardtid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#vestaustralsk sommartid#,
				'generic' => q#vestaustralsk tid#,
				'standard' => q#vestaustralsk standardtid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#aserbajdsjansk sumartid#,
				'generic' => q#aserbajdsjansk tid#,
				'standard' => q#aserbajdsjansk normaltid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#asorisk sumartid#,
				'generic' => q#asorisk tid#,
				'standard' => q#asorisk normaltid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeshisk sumartid#,
				'generic' => q#bangladeshisk tid#,
				'standard' => q#bangladeshisk normaltid#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#bhutansk tid#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#boliviansk tid#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#sumartid for Brasilia#,
				'generic' => q#tidssone for Brasilia#,
				'standard' => q#normaltid for Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#tidssone for Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kappverdisk sumartid#,
				'generic' => q#kappverdisk tid#,
				'standard' => q#kappverdisk normaltid#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#tidssone for Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#sumartid for Chatham#,
				'generic' => q#tidssone for Chatham#,
				'standard' => q#normaltid for Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilensk sumartid#,
				'generic' => q#chilensk tid#,
				'standard' => q#chilensk normaltid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kinesisk sumartid#,
				'generic' => q#kinesisk tid#,
				'standard' => q#kinesisk normaltid#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#sumartid for Tsjojbalsan#,
				'generic' => q#tidssone for Tsjojbalsan#,
				'standard' => q#normaltid for Tsjojbalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#tidssone for Christmasøya#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#tidssone for Kokosøyane#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolombiansk sumartid#,
				'generic' => q#kolombiansk tid#,
				'standard' => q#kolombiansk normaltid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#sumartid for Cookøyane#,
				'generic' => q#tidssone for Cookøyane#,
				'standard' => q#normaltid for Cookøyane#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubansk sumartid#,
				'generic' => q#kubansk tid#,
				'standard' => q#kubansk normaltid#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#tidssone for Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#tidssone for Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#austtimoresisk tid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#sumartid for Påskeøya#,
				'generic' => q#tidssone for Påskeøya#,
				'standard' => q#normaltid for Påskeøya#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ecuadoriansk tid#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinert universaltid#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ukjend by#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#București#,
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
			exemplarCity => q#København#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#irsk sumartid#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsingfors#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man#,
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
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#britisk sumartid#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
			exemplarCity => q#Moskva#,
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
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
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
			exemplarCity => q#Uzjhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanstaten#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizjzja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#sentraleuropeisk sommartid#,
				'generic' => q#sentraleuropeisk tid#,
				'standard' => q#sentraleuropeisk standardtid#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#austeuropeisk sommartid#,
				'generic' => q#austeuropeisk tid#,
				'standard' => q#austeuropeisk standardtid#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#fjern-austeuropeisk tid#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#vesteuropeisk sommartid#,
				'generic' => q#vesteuropeisk tid#,
				'standard' => q#vesteuropeisk standardtid#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#sumartid for Falklandsøyane#,
				'generic' => q#tidssone for Falklandsøyane#,
				'standard' => q#normaltid for Falklandsøyane#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fijiansk sumartid#,
				'generic' => q#fijiansk tid#,
				'standard' => q#fijiansk normaltid#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#tidssone for Fransk Guyana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#tidssone for Dei franske sørterritoria#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich middeltid#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#tidssone for Galápagosøyane#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#tidssone for Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#georgisk sumartid#,
				'generic' => q#georgisk tid#,
				'standard' => q#georgisk normaltid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#tidssone for Gilbertøyane#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#austgrønlandsk sumartid#,
				'generic' => q#austgrønlandsk tid#,
				'standard' => q#austgrønlandsk normaltid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#vestgrønlandsk sumartid#,
				'generic' => q#vestgrønlandsk tid#,
				'standard' => q#vestgrønlandsk normaltid#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#tidssone for Persiabukta#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyansk tid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#sumartid for Hawaii og Aleutene#,
				'generic' => q#tidssone for Hawaii og Aleutene#,
				'standard' => q#normaltid for Hawaii og Aleutene#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkongkinesisk sumartid#,
				'generic' => q#hongkongkinesisk tid#,
				'standard' => q#hongkongkinesisk normaltid#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#sumartid for Khovd#,
				'generic' => q#tidssone for Khovd#,
				'standard' => q#normaltid for Khovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indisk tid#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmasøya#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosøyane#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorene#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivane#,
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
				'standard' => q#tidssone for Indiahavet#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indokinesisk tid#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#sentralindonesisk tid#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#austindonesisk tid#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#vestindonesisk tid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iransk sumartid#,
				'generic' => q#iransk tid#,
				'standard' => q#iransk normaltid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#sumartid for Irkutsk#,
				'generic' => q#tidssone for Irkutsk#,
				'standard' => q#normaltid for Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israelsk sumartid#,
				'generic' => q#israelsk tid#,
				'standard' => q#israelsk normaltid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japansk sumartid#,
				'generic' => q#japansk tid#,
				'standard' => q#japansk normaltid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#austkasakhstansk tid#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#vestkasakhstansk tid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koreansk sumartid#,
				'generic' => q#koreansk tid#,
				'standard' => q#koreansk normaltid#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#tidssone for Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#sumartid for Krasnojarsk#,
				'generic' => q#tidssone for Krasnojarsk#,
				'standard' => q#normaltid for Krasnojarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgisisk tid#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#tidssone for Lineøyane#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#sumartid for Lord Howe-øya#,
				'generic' => q#tidssone for Lord Howe-øya#,
				'standard' => q#normaltid for Lord Howe-øya#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#tidssone for Macquarieøya#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#sumartid for Magadan#,
				'generic' => q#tidssone for Magadan#,
				'standard' => q#normaltid for Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malaysisk tid#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldivisk tid#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#tidssone for Marquesasøyane#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#marshallesisk tid#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauritisk sumartid#,
				'generic' => q#mauritisk tid#,
				'standard' => q#mauritisk normaltid#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#tidssone for Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#sumartid for nordvestlege Mexico#,
				'generic' => q#tidssone for nordvestlege Mexico#,
				'standard' => q#normaltid for nordvestlege Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#sumartid for den meksikanske stillehavskysten#,
				'generic' => q#tidssone for den meksikanske stillehavskysten#,
				'standard' => q#normaltid for den meksikanske stillehavskysten#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#sumartid#,
				'generic' => q#tidssone for Ulan Bator#,
				'standard' => q#normaltid for Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#sumartid for Moskva#,
				'generic' => q#tidssone for Moskva#,
				'standard' => q#normaltid for Moskva#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#myanmarsk tid#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#naurisk tid#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepalsk tid#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#kaledonsk sumartid#,
				'generic' => q#kaledonsk tid#,
				'standard' => q#kaledonsk normaltid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#nyzealandsk sumartid#,
				'generic' => q#nyzealandsk tid#,
				'standard' => q#nyzealandsk normaltid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#sumartid for Newfoundland#,
				'generic' => q#tidssone for Newfoundland#,
				'standard' => q#normaltid for Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#tidssone for Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#tidssone for Norfolkøya#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#sumartid for Fernando de Noronha#,
				'generic' => q#tidssone for Fernando de Noronha#,
				'standard' => q#normaltid for Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#sumartid for Novosibirsk#,
				'generic' => q#tidssone for Novosibirsk#,
				'standard' => q#normaltid for Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#sumartid for Omsk#,
				'generic' => q#tidssone for Omsk#,
				'standard' => q#normaltid for Omsk#,
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
			exemplarCity => q#Påskeøya#,
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
			exemplarCity => q#Galápagosøyane#,
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
			exemplarCity => q#Norfolkøya#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
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
				'daylight' => q#pakistansk sumartid#,
				'generic' => q#pakistansk tid#,
				'standard' => q#pakistansk normaltid#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palauisk tid#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#papuansk tid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayansk sumartid#,
				'generic' => q#paraguayansk tid#,
				'standard' => q#paraguayansk normaltid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruansk sumartid#,
				'generic' => q#peruansk tid#,
				'standard' => q#peruansk normaltid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filippinsk sumartid#,
				'generic' => q#filippinsk tid#,
				'standard' => q#filippinsk normaltid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#tidssone for Phoenixøyane#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#sumartid for Saint-Pierre-et-Miquelon#,
				'generic' => q#tidssone for Saint-Pierre-et-Miquelon#,
				'standard' => q#normaltid for Saint-Pierre-et-Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#tidssone for Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#tidssone for Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#tidssone for Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#tidssone for Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#tidssone for Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sumartid for Sakhalin#,
				'generic' => q#tidssone for Sakhalin#,
				'standard' => q#normaltid for Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoansk sumartid#,
				'generic' => q#samoansk tid#,
				'standard' => q#samoansk normaltid#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychellisk tid#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singaporsk tid#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#salomonsk tid#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#tidssone for Sør-Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamsk tid#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#tidssone for Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitisk tid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#sumartid for Taipei#,
				'generic' => q#tidssone for Taipei#,
				'standard' => q#normaltid for Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tadsjikisk tid#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tidssone for Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tongansk sumartid#,
				'generic' => q#tongansk tid#,
				'standard' => q#tongansk normaltid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#tidssone for Chuukøyane#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmensk sumartid#,
				'generic' => q#turkmensk tid#,
				'standard' => q#turkmensk normaltid#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvalsk tid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayansk sumartid#,
				'generic' => q#uruguayansk tid#,
				'standard' => q#uruguayansk normaltid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#usbekisk sumartid#,
				'generic' => q#usbekisk tid#,
				'standard' => q#usbekisk normaltid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatisk sumartid#,
				'generic' => q#vanuatisk tid#,
				'standard' => q#vanuatisk normaltid#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelansk tid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#sumartid for Vladivostok#,
				'generic' => q#tidssone for Vladivostok#,
				'standard' => q#normaltid for Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#sumartid for Volgograd#,
				'generic' => q#tidssone for Volgograd#,
				'standard' => q#normaltid for Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#tidssone for Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#tidssone for Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#tidssone for Wallis- og Futunaøyane#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#sumartid for Jakutsk#,
				'generic' => q#tidssone for Jakutsk#,
				'standard' => q#normaltid for Jakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#sumartid for Jekaterinburg#,
				'generic' => q#tidssone for Jekaterinburg#,
				'standard' => q#normaltid for Jekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
